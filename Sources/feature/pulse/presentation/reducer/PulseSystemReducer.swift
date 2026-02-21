import CoreElm
import FeaturePulseDomain

func pulseSystemReducer(
    _ action: PulseAction.System,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case let .repositoryEvent(event):
        handleRepositoryEvent(event, state, context)
    case let .nowPlayingChanged(isPlaying):
        handleNowPlayingChanged(isPlaying, state, context)
    case let .lightScheduleChanged(isInOffWindow):
        handleLightScheduleChanged(isInOffWindow, state, context)
    case .dismissError:
        handleDismissError(state, context)
    }
}

private func handleRepositoryEvent(
    _ event: PulseRepositoryEvent,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch event {
    case let .connectionChanged(connectionState):
        handleConnectionChanged(connectionState, state, context)
    case let .discoveredDevices(devices):
        context.state {
            $0.discoveredDevices = devices
        }
    case let .lightStatus(lightOn):
        context.state {
            $0.lightOn = lightOn
        }
    case let .brightness(level, bodyLight, projection):
        context.state {
            $0.brightness = level
            $0.bodyLightOn = bodyLight
            $0.projectionOn = projection
        }
    case let .speed(speed):
        context.state {
            $0.speed = speed
        }
    case let .theme(theme):
        context.state {
            $0.selectedTheme = theme
        }
    case let .error(message):
        context.state {
            $0.errorMessage = message
        }
    case .errorCleared:
        handleErrorCleared(state, context)
    }
}

private func handleConnectionChanged(
    _ connectionState: ConnectionState,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    context.state {
        $0.connectionState = connectionState
        if connectionState == .disconnected {
            $0.connectedDeviceName = nil
        }
    }
    if connectionState == .connected && state.lightScheduleSettings.enabled {
        context.command(.setBrightness(
            level: state.brightness,
            bodyLight: state.bodyLightOn,
            projection: state.projectionOn
        ))
    }
}

private func handleErrorCleared(
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    guard state.errorMessage != nil else { return }
    context.state {
        $0.errorMessage = nil
    }
}

private func handleNowPlayingChanged(
    _ isPlaying: Bool,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    guard isPlaying != state.isMusicPlaying else { return }
    context.state {
        $0.isMusicPlaying = isPlaying
    }
    if state.autoThemeSettings.enabled && state.connectionState.isConnected {
        let theme = isPlaying
            ? state.autoThemeSettings.playingTheme
            : state.autoThemeSettings.idleTheme
        context.command(.setTheme(theme))
    }
}

private func handleLightScheduleChanged(
    _ isInOffWindow: Bool,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    if isInOffWindow && !state.lightScheduleActive {
        // Entering off-window: save state and turn off lights
        context.state {
            $0.savedBodyLightOn = state.bodyLightOn
            $0.savedProjectionOn = state.projectionOn
            $0.lightScheduleActive = true
            $0.bodyLightOn = false
            $0.projectionOn = false
        }
        if state.connectionState.isConnected {
            context.command(.setBrightness(
                level: state.brightness,
                bodyLight: false,
                projection: false
            ))
        }
    } else if !isInOffWindow && state.lightScheduleActive {
        // Exiting off-window: restore saved state
        let bodyLight = state.savedBodyLightOn ?? true
        let projection = state.savedProjectionOn ?? true
        context.state {
            $0.lightScheduleActive = false
            $0.bodyLightOn = bodyLight
            $0.projectionOn = projection
            $0.savedBodyLightOn = nil
            $0.savedProjectionOn = nil
        }
        if state.connectionState.isConnected {
            context.command(.setBrightness(
                level: state.brightness,
                bodyLight: bodyLight,
                projection: projection
            ))
        }
    }
}

private func handleDismissError(
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    guard state.errorMessage != nil else { return }
    context.state {
        $0.errorMessage = nil
    }
}
