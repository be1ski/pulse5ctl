import CoreElm

public let pulseReducer: Reducer<PulseAction, PulseState, PulseEffect, Never> = reducer { action, state, context in
    switch action {
    case let .lifecycle(lifecycleAction):
        pulseLifecycleReducer(lifecycleAction, state, context)

    case let .connection(connectionAction):
        pulseConnectionReducer(connectionAction, state, context)

    case let .controls(controlsAction):
        pulseControlsReducer(controlsAction, state, context)

    case let .autoTheme(autoThemeAction):
        pulseAutoThemeReducer(autoThemeAction, state, context)

    case let .system(systemAction):
        pulseSystemReducer(systemAction, state, context)
    }
}
