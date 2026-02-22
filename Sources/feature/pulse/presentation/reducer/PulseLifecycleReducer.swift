import CoreElm

func pulseLifecycleReducer(
    _ action: PulseAction.Lifecycle,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .started:
        guard !state.isObservingRepository else { return }

        context.state {
            $0.isObservingRepository = true
        }
        context.command(.observeRepository)
        context.command(.observeNowPlaying)
        if state.lightScheduleSettings.enabled {
            context.command(.observeLightSchedule(state.lightScheduleSettings))
        }
        if state.connectionState.isConnected {
            context.command(.requestCurrentState)
        }

    case .systemDidWake:
        guard state.isObservingRepository else { return }
        context.command(.disconnect)
        context.command(.startScan)
    }
}
