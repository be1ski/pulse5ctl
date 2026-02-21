@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

final class PulseAutoThemeReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.AutoTheme,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseAutoThemeReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Toggle Enabled

    func test_toggleEnabled_whenOff_turnsOn() {
        let state = PulseState(autoThemeSettings: AutoThemeSettings(enabled: false))
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertTrue(result.state.autoThemeSettings.enabled)
    }

    func test_toggleEnabled_whenOn_turnsOff() {
        let state = PulseState(autoThemeSettings: AutoThemeSettings(enabled: true))
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertFalse(result.state.autoThemeSettings.enabled)
    }

    func test_toggleEnabled_savesSettings() {
        let result = reduce(.toggleEnabled)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveAutoThemeSettings = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_whileConnectedAndIdle_setsIdleTheme() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: false, idleTheme: .spiritual),
            isMusicPlaying: false
        )
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setTheme(.spiritual) = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_whileConnectedAndPlaying_setsPlayingTheme() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: false, playingTheme: .cocktail),
            isMusicPlaying: true
        )
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setTheme(.cocktail) = $0 { return true }
            return false
        }))
    }

    func test_toggleEnabled_whileDisconnected_doesNotSetTheme() {
        let state = PulseState(
            connectionState: .disconnected,
            autoThemeSettings: AutoThemeSettings(enabled: false)
        )
        let result = reduce(.toggleEnabled, state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setTheme = $0 { return true }
            return false
        }))
    }

    // MARK: - Set Playing Theme

    func test_setPlayingTheme_updatesState() {
        let result = reduce(.setPlayingTheme(.cocktail))
        XCTAssertEqual(result.state.autoThemeSettings.playingTheme, .cocktail)
    }

    func test_setPlayingTheme_savesSettings() {
        let result = reduce(.setPlayingTheme(.cocktail))
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .saveAutoThemeSettings = $0 { return true }
            return false
        }))
    }

    func test_setPlayingTheme_whenEnabledAndPlaying_appliesTheme() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true),
            isMusicPlaying: true
        )
        let result = reduce(.setPlayingTheme(.weather), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setTheme(.weather) = $0 { return true }
            return false
        }))
    }

    func test_setPlayingTheme_whenNotPlaying_doesNotApply() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true),
            isMusicPlaying: false
        )
        let result = reduce(.setPlayingTheme(.weather), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setTheme = $0 { return true }
            return false
        }))
    }

    func test_setPlayingTheme_whenDisabled_doesNotApply() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: false),
            isMusicPlaying: true
        )
        let result = reduce(.setPlayingTheme(.weather), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setTheme = $0 { return true }
            return false
        }))
    }

    // MARK: - Set Idle Theme

    func test_setIdleTheme_updatesState() {
        let result = reduce(.setIdleTheme(.spiritual))
        XCTAssertEqual(result.state.autoThemeSettings.idleTheme, .spiritual)
    }

    func test_setIdleTheme_whenEnabledAndIdle_appliesTheme() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true),
            isMusicPlaying: false
        )
        let result = reduce(.setIdleTheme(.spiritual), state: state)
        XCTAssertTrue(result.effects.commands.contains(where: {
            if case .setTheme(.spiritual) = $0 { return true }
            return false
        }))
    }

    func test_setIdleTheme_whenPlaying_doesNotApply() {
        let state = PulseState(
            connectionState: .connected,
            autoThemeSettings: AutoThemeSettings(enabled: true),
            isMusicPlaying: true
        )
        let result = reduce(.setIdleTheme(.spiritual), state: state)
        XCTAssertFalse(result.effects.commands.contains(where: {
            if case .setTheme = $0 { return true }
            return false
        }))
    }
}
