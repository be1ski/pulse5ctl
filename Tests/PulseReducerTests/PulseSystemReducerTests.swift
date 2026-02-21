@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

final class PulseSystemReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.System,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseSystemReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Error

    func test_repositoryError_setsErrorMessage() {
        let result = reduce(.repositoryEvent(.error("Something broke")))
        XCTAssertEqual(result.state.errorMessage, "Something broke")
    }

    func test_repositoryError_withExistingError_overwritesMessage() {
        let state = PulseState(errorMessage: "Old error")
        let result = reduce(.repositoryEvent(.error("New error")), state: state)
        XCTAssertEqual(result.state.errorMessage, "New error")
    }

    // MARK: - Error Cleared

    func test_errorCleared_removesErrorMessage() {
        let state = PulseState(errorMessage: "Bluetooth is powered off")
        let result = reduce(.repositoryEvent(.errorCleared), state: state)
        XCTAssertNil(result.state.errorMessage)
    }

    func test_errorCleared_withNoError_isNoop() {
        let state = PulseState(errorMessage: nil)
        let result = reduce(.repositoryEvent(.errorCleared), state: state)
        XCTAssertNil(result.state.errorMessage)
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    // MARK: - Dismiss Error

    func test_dismissError_clearsErrorMessage() {
        let state = PulseState(errorMessage: "Some error")
        let result = reduce(.dismissError, state: state)
        XCTAssertNil(result.state.errorMessage)
    }

    func test_dismissError_withNoError_isNoop() {
        let state = PulseState(errorMessage: nil)
        let result = reduce(.dismissError, state: state)
        XCTAssertNil(result.state.errorMessage)
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    // MARK: - Wake from sleep scenario

    func test_errorCleared_afterPoweredOff_clearsError() {
        let afterError = reduce(.repositoryEvent(.error("Bluetooth is powered off")))
        XCTAssertNotNil(afterError.state.errorMessage)

        let afterClear = reduce(.repositoryEvent(.errorCleared), state: afterError.state)
        XCTAssertNil(afterClear.state.errorMessage)
    }

    // MARK: - Connection Changed

    func test_connectionChanged_toDisconnected_clearsDeviceName() {
        let state = PulseState(
            connectionState: .connected,
            connectedDeviceName: "Pulse 5"
        )
        let result = reduce(.repositoryEvent(.connectionChanged(.disconnected)), state: state)
        XCTAssertEqual(result.state.connectionState, .disconnected)
        XCTAssertNil(result.state.connectedDeviceName)
    }

    func test_connectionChanged_toConnected_keepsDeviceName() {
        let state = PulseState(connectedDeviceName: "Pulse 5")
        let result = reduce(.repositoryEvent(.connectionChanged(.connected)), state: state)
        XCTAssertEqual(result.state.connectionState, .connected)
        XCTAssertEqual(result.state.connectedDeviceName, "Pulse 5")
    }

    func test_connectionChanged_toConnectedWithSchedule_emitsBrightness() {
        let state = PulseState(
            brightness: 50,
            bodyLightOn: true,
            projectionOn: false,
            lightScheduleSettings: LightScheduleSettings(enabled: true)
        )
        let result = reduce(.repositoryEvent(.connectionChanged(.connected)), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setBrightness(level: 50, bodyLight: true, projection: false) = $0 { return true }
            return false
        }))
    }

    func test_connectionChanged_toConnectedWithoutSchedule_noBrightness() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: false))
        let result = reduce(.repositoryEvent(.connectionChanged(.connected)), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setBrightness = $0 { return true }
            return false
        }))
    }

    // MARK: - Discovered Devices

    func test_discoveredDevices_updatesState() {
        let devices = [
            DiscoveredDevice(id: UUID(), name: "Pulse 5", rssi: -50, hasPulseService: true),
            DiscoveredDevice(id: UUID(), name: "Other", rssi: -80, hasPulseService: false)
        ]
        let result = reduce(.repositoryEvent(.discoveredDevices(devices)))
        XCTAssertEqual(result.state.discoveredDevices, devices)
    }

    // MARK: - Other repository events

    func test_brightnessEvent_updatesState() {
        let result = reduce(.repositoryEvent(.brightness(level: 60, bodyLight: true, projection: false)))
        XCTAssertEqual(result.state.brightness, 60)
        XCTAssertTrue(result.state.bodyLightOn)
        XCTAssertFalse(result.state.projectionOn)
    }

    func test_speedEvent_updatesState() {
        let result = reduce(.repositoryEvent(.speed(3)))
        XCTAssertEqual(result.state.speed, 3)
    }

    func test_themeEvent_updatesState() {
        let result = reduce(.repositoryEvent(.theme(.party)))
        XCTAssertEqual(result.state.selectedTheme, .party)
    }

    func test_themeEvent_nil_updatesState() {
        let state = PulseState(selectedTheme: .party)
        let result = reduce(.repositoryEvent(.theme(nil)), state: state)
        XCTAssertNil(result.state.selectedTheme)
    }

    func test_lightStatusEvent_updatesState() {
        let result = reduce(.repositoryEvent(.lightStatus(false)))
        XCTAssertFalse(result.state.lightOn)
    }

    // MARK: - Now Playing Changed

    func test_nowPlayingChanged_updatesState() {
        let result = reduce(.nowPlayingChanged(true))
        XCTAssertTrue(result.state.isMusicPlaying)
    }

    func test_nowPlayingChanged_withAutoThemeEnabled_setsPlayingTheme() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true, playingTheme: .party, idleTheme: .nature)
        )
        let result = reduce(.nowPlayingChanged(true), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setTheme(.party) = $0 { return true }
            return false
        }))
    }

    func test_nowPlayingStopped_withAutoThemeEnabled_setsIdleTheme() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true, playingTheme: .party, idleTheme: .nature),
            isMusicPlaying: true
        )
        let result = reduce(.nowPlayingChanged(false), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setTheme(.nature) = $0 { return true }
            return false
        }))
    }

    func test_nowPlayingChanged_withAutoThemeDisabled_noThemeChange() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: false)
        )
        let result = reduce(.nowPlayingChanged(true), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setTheme = $0 { return true }
            return false
        }))
    }

    func test_nowPlayingChanged_sameValue_isIgnored() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true, playingTheme: .party, idleTheme: .nature)
        )
        let result = reduce(.nowPlayingChanged(false), state: state)
        XCTAssertFalse(result.state.isMusicPlaying)
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    func test_nowPlayingChanged_whileDisconnected_noThemeChange() {
        let state = PulseState(
            connectionState: .disconnected,
            autoThemeSettings: AutoThemeSettings(enabled: true)
        )
        let result = reduce(.nowPlayingChanged(true), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setTheme = $0 { return true }
            return false
        }))
    }

    // MARK: - Light Schedule Changed

    func test_lightScheduleChanged_enteringOffWindow_savesAndDisablesLights() {
        let state = PulseState(bodyLightOn: true, projectionOn: true)
        let result = reduce(.lightScheduleChanged(true), state: state)
        XCTAssertTrue(result.state.lightScheduleActive)
        XCTAssertFalse(result.state.bodyLightOn)
        XCTAssertFalse(result.state.projectionOn)
        XCTAssertEqual(result.state.savedBodyLightOn, true)
        XCTAssertEqual(result.state.savedProjectionOn, true)
    }

    func test_lightScheduleChanged_enteringOffWindowConnected_emitsBrightness() {
        let state = PulseState(connectionState: .connected, brightness: 60, bodyLightOn: true, projectionOn: true)
        let result = reduce(.lightScheduleChanged(true), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setBrightness(level: 60, bodyLight: false, projection: false) = $0 { return true }
            return false
        }))
    }

    func test_lightScheduleChanged_enteringOffWindowDisconnected_noBrightness() {
        let state = PulseState(bodyLightOn: true, projectionOn: true)
        let result = reduce(.lightScheduleChanged(true), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setBrightness = $0 { return true }
            return false
        }))
    }

    func test_lightScheduleChanged_exitingOffWindow_restoresLights() {
        var state = PulseState(bodyLightOn: false, projectionOn: false)
        state.lightScheduleActive = true
        state.savedBodyLightOn = true
        state.savedProjectionOn = false

        let result = reduce(.lightScheduleChanged(false), state: state)
        XCTAssertFalse(result.state.lightScheduleActive)
        XCTAssertTrue(result.state.bodyLightOn)
        XCTAssertFalse(result.state.projectionOn)
        XCTAssertNil(result.state.savedBodyLightOn)
        XCTAssertNil(result.state.savedProjectionOn)
    }

    func test_lightScheduleChanged_exitingOffWindowConnected_emitsBrightness() {
        var state = PulseState(connectionState: .connected, brightness: 40, bodyLightOn: false, projectionOn: false)
        state.lightScheduleActive = true
        state.savedBodyLightOn = true
        state.savedProjectionOn = true

        let result = reduce(.lightScheduleChanged(false), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setBrightness(level: 40, bodyLight: true, projection: true) = $0 { return true }
            return false
        }))
    }

    func test_lightScheduleChanged_alreadyInOffWindow_isNoop() {
        var state = PulseState()
        state.lightScheduleActive = true
        let result = reduce(.lightScheduleChanged(true), state: state)
        // Already in off window — should not change anything
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    func test_lightScheduleChanged_alreadyOutOfOffWindow_isNoop() {
        let result = reduce(.lightScheduleChanged(false))
        // lightScheduleActive is false by default — should not change anything
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    func test_lightScheduleChanged_exitingWithNoSavedState_restoresDefaults() {
        var state = PulseState(bodyLightOn: false, projectionOn: false)
        state.lightScheduleActive = true
        // No savedBodyLightOn/savedProjectionOn

        let result = reduce(.lightScheduleChanged(false), state: state)
        XCTAssertTrue(result.state.bodyLightOn) // defaults to true
        XCTAssertTrue(result.state.projectionOn) // defaults to true
    }
}
