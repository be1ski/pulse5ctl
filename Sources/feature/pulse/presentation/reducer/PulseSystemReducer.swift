import CoreElm

func pulseSystemReducer(
    _ action: PulseAction.System,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case let .repositoryEvent(event):
        switch event {
        case let .connectionChanged(connectionState):
            context.state { current in
                var updated = current
                updated.connectionState = connectionState
                if connectionState == .disconnected {
                    updated.connectedDeviceName = nil
                }
                return updated
            }

        case let .discoveredDevices(devices):
            context.state { current in
                var updated = current
                updated.discoveredDevices = devices
                return updated
            }

        case let .lightStatus(lightOn):
            context.state { current in
                var updated = current
                updated.lightOn = lightOn
                return updated
            }

        case let .brightness(level, bodyLight, projection):
            context.state { current in
                var updated = current
                updated.brightness = level
                updated.bodyLightOn = bodyLight
                updated.projectionOn = projection
                return updated
            }

        case let .speed(speed):
            context.state { current in
                var updated = current
                updated.speed = speed
                return updated
            }

        case let .theme(theme):
            context.state { current in
                var updated = current
                updated.selectedTheme = theme
                return updated
            }

        case let .error(message):
            context.state { current in
                var updated = current
                updated.errorMessage = message
                return updated
            }
        }

    case let .nowPlayingChanged(isPlaying):
        context.state { current in
            var updated = current
            updated.isMusicPlaying = isPlaying
            return updated
        }
        if state.autoThemeSettings.enabled && state.connectionState.isConnected {
            let theme = isPlaying
                ? state.autoThemeSettings.playingTheme
                : state.autoThemeSettings.idleTheme
            context.command(.setTheme(theme))
        }

    case .dismissError:
        guard state.errorMessage != nil else { return }
        context.state { current in
            var updated = current
            updated.errorMessage = nil
            return updated
        }
    }
}
