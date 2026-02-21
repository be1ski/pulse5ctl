@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

final class PulseLifecycleReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.Lifecycle,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseLifecycleReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Started

    func test_started_setsObservingRepository() {
        let result = reduce(.started)
        XCTAssertTrue(result.state.isObservingRepository)
    }

    func test_started_emitsObserveRepository() {
        let result = reduce(.started)
        XCTAssertTrue(result.effects.commands.contains(.observeRepository))
    }

    func test_started_emitsObserveNowPlaying() {
        let result = reduce(.started)
        XCTAssertTrue(result.effects.commands.contains(.observeNowPlaying))
    }

    func test_started_withLightScheduleEnabled_emitsObserveLightSchedule() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: true))
        let result = reduce(.started, state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }

    func test_started_withLightScheduleDisabled_noObserveLightSchedule() {
        let result = reduce(.started)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }

    func test_started_whenConnected_emitsRequestCurrentState() {
        let state = PulseState(connectionState: .connected)
        let result = reduce(.started, state: state)
        XCTAssertTrue(result.effects.commands.contains(.requestCurrentState))
    }

    func test_started_whenDisconnected_doesNotRequestCurrentState() {
        let result = reduce(.started)
        XCTAssertFalse(result.effects.commands.contains(.requestCurrentState))
    }

    func test_started_whenAlreadyObserving_isIdempotent() {
        let state = PulseState(isObservingRepository: true)
        let result = reduce(.started, state: state)
        // Should not change anything — guard prevents re-registration
        XCTAssertTrue(result.effects.commands.isEmpty)
    }
}
