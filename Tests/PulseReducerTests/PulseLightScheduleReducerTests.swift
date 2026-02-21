@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

final class PulseLightScheduleReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.LightSchedule,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseLightScheduleReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Toggle Enabled

    func test_toggleEnabled_whenOff_turnsOn() {
        let result = reduce(.toggleEnabled)
        XCTAssertTrue(result.state.lightScheduleSettings.enabled)
    }

    func test_toggleEnabled_whenOn_turnsOff() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: true))
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertFalse(result.state.lightScheduleSettings.enabled)
    }

    func test_toggleEnabled_whenTurningOn_emitsObserveLightSchedule() {
        let result = reduce(.toggleEnabled)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_whenTurningOff_emitsStopLightSchedule() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: true))
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .stopLightSchedule = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_savesSettings() {
        let result = reduce(.toggleEnabled)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveLightScheduleSettings = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_offWhileInOffWindow_restoresLights() {
        var state = PulseState(
            brightness: 50,
            bodyLightOn: false,
            projectionOn: false,
            lightScheduleSettings: LightScheduleSettings(enabled: true)
        )
        state.lightScheduleActive = true
        state.savedBodyLightOn = true
        state.savedProjectionOn = true

        let result = reduce(.toggleEnabled, state: state)
        XCTAssertFalse(result.state.lightScheduleActive)
        XCTAssertTrue(result.state.bodyLightOn)
        XCTAssertTrue(result.state.projectionOn)
        XCTAssertNil(result.state.savedBodyLightOn)
        XCTAssertNil(result.state.savedProjectionOn)
    }

    func test_toggleEnabled_offWhileInOffWindowConnected_emitsBrightness() {
        var state = PulseState(
            connectionState: .connected,
            brightness: 50,
            bodyLightOn: false,
            projectionOn: false,
            lightScheduleSettings: LightScheduleSettings(enabled: true)
        )
        state.lightScheduleActive = true
        state.savedBodyLightOn = true
        state.savedProjectionOn = false

        let result = reduce(.toggleEnabled, state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setBrightness(level: 50, bodyLight: true, projection: false) = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_offWhileNotInOffWindow_noRestore() {
        let state = PulseState(
            bodyLightOn: true,
            projectionOn: true,
            lightScheduleSettings: LightScheduleSettings(enabled: true)
        )
        // lightScheduleActive is false by default
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setBrightness = $0 { return true }
            return false
        }))
    }

    // MARK: - Set Off Time

    func test_setOffTime_updatesState() {
        let result = reduce(.setOffTime(hour: 23, minute: 30))
        XCTAssertEqual(result.state.lightScheduleSettings.offHour, 23)
        XCTAssertEqual(result.state.lightScheduleSettings.offMinute, 30)
    }

    func test_setOffTime_savesSettings() {
        let result = reduce(.setOffTime(hour: 23, minute: 30))
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveLightScheduleSettings = $0 { return true }
            return false
        }))
    }

    func test_setOffTime_whenEnabled_restartsMonitor() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: true))
        let result = reduce(.setOffTime(hour: 23, minute: 30), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }

    func test_setOffTime_whenDisabled_doesNotRestartMonitor() {
        let result = reduce(.setOffTime(hour: 23, minute: 30))
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }

    // MARK: - Set On Time

    func test_setOnTime_updatesState() {
        let result = reduce(.setOnTime(hour: 8, minute: 15))
        XCTAssertEqual(result.state.lightScheduleSettings.onHour, 8)
        XCTAssertEqual(result.state.lightScheduleSettings.onMinute, 15)
    }

    func test_setOnTime_savesSettings() {
        let result = reduce(.setOnTime(hour: 8, minute: 15))
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveLightScheduleSettings = $0 { return true }
            return false
        }))
    }

    func test_setOnTime_whenEnabled_restartsMonitor() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: true))
        let result = reduce(.setOnTime(hour: 8, minute: 0), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }

    func test_setOnTime_whenDisabled_doesNotRestartMonitor() {
        let result = reduce(.setOnTime(hour: 8, minute: 0))
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .observeLightSchedule = $0 { return true }
            return false
        }))
    }
}
