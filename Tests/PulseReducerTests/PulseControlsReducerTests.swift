@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

final class PulseControlsReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.Controls,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseControlsReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Toggle Light

    func test_toggleLight_whenOn_turnsOff() {
        let state = PulseState(lightOn: true)
        let result = reduce(.toggleLight, state: state)
        XCTAssertFalse(result.state.lightOn)
        XCTAssertEqual(result.effects.commands, [.setLight(false)])
    }

    func test_toggleLight_whenOff_turnsOn() {
        let state = PulseState(lightOn: false)
        let result = reduce(.toggleLight, state: state)
        XCTAssertTrue(result.state.lightOn)
        XCTAssertEqual(result.effects.commands, [.setLight(true)])
    }

    // MARK: - Select Theme

    func test_selectTheme_updatesState() {
        let result = reduce(.selectTheme(.party))
        XCTAssertEqual(result.state.selectedTheme, .party)
    }

    func test_selectTheme_emitsSetTheme() {
        let result = reduce(.selectTheme(.nature))
        XCTAssertEqual(result.effects.commands, [.setTheme(.nature)])
    }

    // MARK: - Set Brightness

    func test_setBrightness_updatesState() {
        let result = reduce(.setBrightness(60))
        XCTAssertEqual(result.state.brightness, 60)
    }

    func test_setBrightness_belowMin_clampsToMin() {
        let result = reduce(.setBrightness(5))
        XCTAssertEqual(result.state.brightness, 20)
    }

    func test_setBrightness_aboveMax_clampsToMax() {
        let result = reduce(.setBrightness(100))
        XCTAssertEqual(result.state.brightness, 80)
    }

    func test_setBrightness_fractionalValue_roundsToInt() {
        let result = reduce(.setBrightness(45.6))
        XCTAssertEqual(result.state.brightness, 46)
    }

    func test_setBrightness_emitsCommand() {
        let state = PulseState(bodyLightOn: true, projectionOn: false)
        let result = reduce(.setBrightness(50), state: state)
        XCTAssertEqual(result.effects.commands, [.setBrightness(level: 50, bodyLight: true, projection: false)])
    }

    // MARK: - Toggle Body Light

    func test_toggleBodyLight_updatesState() {
        let state = PulseState(bodyLightOn: true)
        let result = reduce(.toggleBodyLight, state: state)
        XCTAssertFalse(result.state.bodyLightOn)
    }

    func test_toggleBodyLight_emitsBrightness() {
        let state = PulseState(brightness: 50, bodyLightOn: true, projectionOn: true)
        let result = reduce(.toggleBodyLight, state: state)
        XCTAssertEqual(result.effects.commands, [.setBrightness(level: 50, bodyLight: false, projection: true)])
    }

    func test_toggleBodyLight_duringSchedule_isBlocked() {
        var state = PulseState(bodyLightOn: true)
        state.lightScheduleActive = true
        let result = reduce(.toggleBodyLight, state: state)
        XCTAssertTrue(result.state.bodyLightOn) // unchanged
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    // MARK: - Toggle Projection

    func test_toggleProjection_updatesState() {
        let state = PulseState(projectionOn: true)
        let result = reduce(.toggleProjection, state: state)
        XCTAssertFalse(result.state.projectionOn)
    }

    func test_toggleProjection_duringSchedule_isBlocked() {
        var state = PulseState(projectionOn: true)
        state.lightScheduleActive = true
        let result = reduce(.toggleProjection, state: state)
        XCTAssertTrue(result.state.projectionOn) // unchanged
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    // MARK: - Set Speed

    func test_setSpeed_updatesStateAndEmitsCommand() {
        let result = reduce(.setSpeed(5))
        XCTAssertEqual(result.state.speed, 5)
        XCTAssertEqual(result.effects.commands, [.setSpeed(5)])
    }

    // MARK: - Toggle Pattern

    func test_togglePattern_inactive_addsPattern() {
        let state = PulseState(activePatterns: [.nature: Set([.campfire])])
        let result = reduce(.togglePattern(.seaWave, .nature), state: state)
        XCTAssertEqual(result.state.activePatterns[.nature], Set([.campfire, .seaWave]))
    }

    func test_togglePattern_active_removesPattern() {
        let state = PulseState(activePatterns: [.nature: Set([.campfire, .seaWave])])
        let result = reduce(.togglePattern(.seaWave, .nature), state: state)
        XCTAssertEqual(result.state.activePatterns[.nature], Set([.campfire]))
    }

    func test_togglePattern_lastActive_cannotRemove() {
        let state = PulseState(activePatterns: [.nature: Set([.campfire])])
        let result = reduce(.togglePattern(.campfire, .nature), state: state)
        // Should not remove — still has campfire
        XCTAssertEqual(result.state.activePatterns[.nature], Set([.campfire]))
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    func test_togglePattern_emitsLedPackageAndSave() {
        let state = PulseState(activePatterns: [.nature: Set([.campfire])])
        let result = reduce(.togglePattern(.seaWave, .nature), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setLedPackage(theme: .nature, _, _, _, _) = $0 { return true }
            return false
        }))
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveLedCustomization = $0 { return true }
            return false
        }))
    }

    // MARK: - Solo Pattern

    func test_soloPattern_setsOnlyOnePattern() {
        let state = PulseState(activePatterns: [.nature: Set([.campfire, .seaWave, .universe])])
        let result = reduce(.soloPattern(.northernLights, .nature), state: state)
        XCTAssertEqual(result.state.activePatterns[.nature], Set([.northernLights]))
    }

    // MARK: - Set Custom Color

    func test_setCustomColor_updatesState() {
        let color = LEDColor(red: 128, green: 64, blue: 32)
        let result = reduce(.setCustomColor(color))
        XCTAssertEqual(result.state.customColor, color)
    }

    func test_setCustomColor_withThemeSelected_emitsLedPackage() {
        let state = PulseState(selectedTheme: .nature)
        let result = reduce(.setCustomColor(LEDColor(red: 0, green: 0, blue: 0)), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setLedPackage = $0 { return true }
            return false
        }))
    }

    func test_setCustomColor_withNoTheme_noLedPackage() {
        let result = reduce(.setCustomColor(LEDColor(red: 0, green: 0, blue: 0)))
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setLedPackage = $0 { return true }
            return false
        }))
    }

    func test_setCustomColor_alwaysSavesCustomization() {
        let result = reduce(.setCustomColor(LEDColor(red: 0, green: 0, blue: 0)))
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveLedCustomization = $0 { return true }
            return false
        }))
    }

    // MARK: - Set Color Effect

    func test_setColorEffect_updatesState() {
        let result = reduce(.setColorEffect(.staticColor))
        XCTAssertEqual(result.state.colorEffect, .staticColor)
    }

    func test_setColorEffect_withThemeSelected_emitsLedPackage() {
        let state = PulseState(selectedTheme: .party)
        let result = reduce(.setColorEffect(.staticColor), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setLedPackage = $0 { return true }
            return false
        }))
    }

    func test_setColorEffect_withNoTheme_noLedPackage() {
        let result = reduce(.setColorEffect(.staticColor))
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setLedPackage = $0 { return true }
            return false
        }))
    }
}
