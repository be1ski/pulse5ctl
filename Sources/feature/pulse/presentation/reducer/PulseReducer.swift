import CoreElm

// swiftlint:disable:next line_length
nonisolated(unsafe) public let pulseReducer: Reducer<PulseAction, PulseState, PulseEffect, Never> = reducer { action, state, context in
    switch action {
    case let .lifecycle(lifecycleAction):
        pulseLifecycleReducer(lifecycleAction, state, context)

    case let .connection(connectionAction):
        pulseConnectionReducer(connectionAction, state, context)

    case let .controls(controlsAction):
        pulseControlsReducer(controlsAction, state, context)

    case let .autoTheme(autoThemeAction):
        pulseAutoThemeReducer(autoThemeAction, state, context)

    case let .lightSchedule(lightScheduleAction):
        pulseLightScheduleReducer(lightScheduleAction, state, context)

    case let .settings(settingsAction):
        pulseSettingsReducer(settingsAction, state, context)

    case let .system(systemAction):
        pulseSystemReducer(systemAction, state, context)
    }
}
