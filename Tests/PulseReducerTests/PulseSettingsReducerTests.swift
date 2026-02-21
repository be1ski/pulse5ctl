@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

final class PulseSettingsReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.Settings,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseSettingsReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Set Language

    func test_setLanguage_updatesState() {
        let result = reduce(.setLanguage("de"))
        XCTAssertEqual(result.state.selectedLanguage, "de")
    }

    func test_setLanguage_nil_clearsState() {
        let state = PulseState(selectedLanguage: "de")
        let result = reduce(.setLanguage(nil), state: state)
        XCTAssertNil(result.state.selectedLanguage)
    }

    func test_setLanguage_emitsSaveLanguage() {
        let result = reduce(.setLanguage("fr"))
        XCTAssertEqual(result.effects.commands, [.saveLanguage("fr")])
    }

    func test_setLanguage_nil_emitsSaveLanguageNil() {
        let result = reduce(.setLanguage(nil))
        XCTAssertEqual(result.effects.commands, [.saveLanguage(nil)])
    }
}
