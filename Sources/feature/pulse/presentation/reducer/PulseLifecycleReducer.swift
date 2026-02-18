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
        context.commands(.observeRepository, .requestCurrentState, .observeNowPlaying)
    }
}
