import CoreElm

func pulseLifecycleReducer(
    _ action: PulseAction.Lifecycle,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .started:
        guard !state.isObservingRepository else { return }

        context.state { current in
            var updated = current
            updated.isObservingRepository = true
            return updated
        }
        context.command(.observeRepository)
        context.command(.observeNowPlaying)
        if state.lightScheduleSettings.enabled {
            context.command(.observeLightSchedule(state.lightScheduleSettings))
        }
        if state.connectionState.isConnected {
            context.command(.requestCurrentState)
        }
    }
}
