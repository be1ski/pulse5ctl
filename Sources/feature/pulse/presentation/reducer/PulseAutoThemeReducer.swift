import CoreElm
import FeaturePulseDomain

func pulseAutoThemeReducer(
    _ action: PulseAction.AutoTheme,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .toggleEnabled:
        let newEnabled = !state.autoThemeSettings.enabled
        context.state { current in
            var updated = current
            updated.autoThemeSettings.enabled = newEnabled
            return updated
        }
        context.command(.saveAutoThemeSettings(state.autoThemeSettings.with(enabled: newEnabled)))
        if newEnabled && state.connectionState.isConnected {
            let theme = state.isMusicPlaying
                ? state.autoThemeSettings.playingTheme
                : state.autoThemeSettings.idleTheme
            context.command(.setTheme(theme))
        }

    case let .setPlayingTheme(theme):
        context.state { current in
            var updated = current
            updated.autoThemeSettings.playingTheme = theme
            return updated
        }
        context.command(.saveAutoThemeSettings(state.autoThemeSettings.with(playingTheme: theme)))
        if state.autoThemeSettings.enabled && state.isMusicPlaying && state.connectionState.isConnected {
            context.command(.setTheme(theme))
        }

    case let .setIdleTheme(theme):
        context.state { current in
            var updated = current
            updated.autoThemeSettings.idleTheme = theme
            return updated
        }
        context.command(.saveAutoThemeSettings(state.autoThemeSettings.with(idleTheme: theme)))
        if state.autoThemeSettings.enabled && !state.isMusicPlaying && state.connectionState.isConnected {
            context.command(.setTheme(theme))
        }
    }
}

private extension AutoThemeSettings {
    func with(
        enabled: Bool? = nil,
        playingTheme: LEDTheme? = nil,
        idleTheme: LEDTheme? = nil
    ) -> AutoThemeSettings {
        AutoThemeSettings(
            enabled: enabled ?? self.enabled,
            playingTheme: playingTheme ?? self.playingTheme,
            idleTheme: idleTheme ?? self.idleTheme
        )
    }
}
