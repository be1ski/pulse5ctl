@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import Foundation
import XCTest

final class PulseReducerRoutingTests: XCTestCase {

    // MARK: - Routing

    func test_lifecycle_started_setsObservingFlag() {
        let result = pulseReducer(.lifecycle(.started), PulseState())
        XCTAssertTrue(result.state.isObservingRepository)
    }

    func test_connection_connectTapped_emitsStartScan() {
        let result = pulseReducer(.connection(.connectTapped), PulseState())
        XCTAssertTrue(result.effects.commands.contains(.startScan))
    }

    func test_connection_disconnectTapped_emitsDisconnect() {
        let state = PulseState(connectionState: .connected)
        let result = pulseReducer(.connection(.disconnectTapped), state)
        XCTAssertTrue(result.effects.commands.contains(.disconnect))
    }

    func test_connection_selectDevice_emitsConnect() {
        let uuid = UUID()
        let result = pulseReducer(.connection(.selectDevice(uuid)), PulseState())
        XCTAssertTrue(result.effects.commands.contains(.connect(uuid)))
    }

    func test_controls_toggleLight_emitsSetLight() {
        let state = PulseState(connectionState: .connected, lightOn: true)
        let result = pulseReducer(.controls(.toggleLight), state)
        XCTAssertTrue(result.effects.commands.contains(.setLight(false)))
    }

    func test_controls_selectTheme_emitsSetTheme() {
        let state = PulseState(connectionState: .connected)
        let result = pulseReducer(.controls(.selectTheme(.party)), state)
        XCTAssertTrue(result.effects.commands.contains(.setTheme(.party)))
    }

    func test_autoTheme_toggleEnabled_updatesState() {
        let state = PulseState(autoThemeSettings: AutoThemeSettings(enabled: false))
        let result = pulseReducer(.autoTheme(.toggleEnabled), state)
        XCTAssertTrue(result.state.autoThemeSettings.enabled)
    }

    func test_lightSchedule_toggleEnabled_updatesState() {
        let state = PulseState(lightScheduleSettings: LightScheduleSettings(enabled: false))
        let result = pulseReducer(.lightSchedule(.toggleEnabled), state)
        XCTAssertTrue(result.state.lightScheduleSettings.enabled)
    }

    func test_settings_setLanguage_updatesState() {
        let result = pulseReducer(.settings(.setLanguage("fr")), PulseState())
        XCTAssertEqual(result.state.selectedLanguage, "fr")
    }

    func test_system_repositoryError_setsErrorMessage() {
        let result = pulseReducer(.system(.repositoryEvent(.error("Something broke"))), PulseState())
        XCTAssertEqual(result.state.errorMessage, "Something broke")
    }

    // MARK: - PulseState Computed Properties

    func test_canShowControls_connected_returnsTrue() {
        let state = PulseState(connectionState: .connected)
        XCTAssertTrue(state.canShowControls)
    }

    func test_canShowControls_disconnected_returnsFalse() {
        XCTAssertFalse(PulseState().canShowControls)
    }

    func test_activePatternsForTheme_noCustom_returnsDefaults() {
        let state = PulseState()
        XCTAssertEqual(state.activePatternsForTheme(.nature), Set(LEDTheme.nature.patterns))
    }

    func test_activePatternsForTheme_withCustom_returnsCustom() {
        let custom: Set<LEDPattern> = [.campfire, .seaWave]
        let state = PulseState(activePatterns: [.nature: custom])
        XCTAssertEqual(state.activePatternsForTheme(.nature), custom)
    }
}
