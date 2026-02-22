@testable import CoreLocalization
import XCTest

final class L10nTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        L10n.overrideLocale = nil
    }

    // MARK: - Supported Locales

    func test_supportedLocales_containsEnglish() {
        XCTAssertTrue(L10n.supportedLocales.contains("en"))
    }

    func test_supportedLocales_count_is20() {
        XCTAssertEqual(L10n.supportedLocales.count, 20)
    }

    func test_supportedLocales_containsAllExpected() {
        let expected = ["ru", "de", "fr", "ja", "zh-Hans"]
        for locale in expected {
            XCTAssertTrue(L10n.supportedLocales.contains(locale), "Missing locale: \(locale)")
        }
    }

    // MARK: - Override Locale

    func test_overrideLocale_validLocale_changesStrings() {
        L10n.overrideLocale = "ru"
        XCTAssertNotEqual(L10n.generalCancel, "Cancel")
    }

    func test_overrideLocale_nil_restoresDefault() {
        L10n.overrideLocale = "ru"
        L10n.overrideLocale = nil
        let value = L10n.generalCancel
        XCTAssertFalse(value.isEmpty)
    }

    func test_overrideLocale_invalidLocale_fallsBackToDefault() {
        L10n.overrideLocale = "xx-INVALID"
        XCTAssertFalse(L10n.generalCancel.isEmpty)
    }

    // MARK: - String Accessors Non-Empty

    func test_generalStrings_nonEmpty() {
        XCTAssertFalse(L10n.generalCancel.isEmpty)
        XCTAssertFalse(L10n.generalConnect.isEmpty)
        XCTAssertFalse(L10n.generalConnected.isEmpty)
        XCTAssertFalse(L10n.generalDisconnect.isEmpty)
        XCTAssertFalse(L10n.generalQuit.isEmpty)
        XCTAssertFalse(L10n.generalDismiss.isEmpty)
    }

    func test_heroStrings_nonEmpty() {
        XCTAssertFalse(L10n.heroTitle.isEmpty)
        XCTAssertFalse(L10n.heroSubtitle.isEmpty)
        XCTAssertFalse(L10n.heroScanButton.isEmpty)
        XCTAssertFalse(L10n.heroSearching.isEmpty)
    }

    func test_controlsStrings_nonEmpty() {
        XCTAssertFalse(L10n.controlsThemes.isEmpty)
        XCTAssertFalse(L10n.controlsPatterns.isEmpty)
        XCTAssertFalse(L10n.controlsColor.isEmpty)
        XCTAssertFalse(L10n.controlsCustom.isEmpty)
        XCTAssertFalse(L10n.controlsColorLoop.isEmpty)
        XCTAssertFalse(L10n.controlsBrightness.isEmpty)
        XCTAssertFalse(L10n.controlsBody.isEmpty)
        XCTAssertFalse(L10n.controlsProjection.isEmpty)
        XCTAssertFalse(L10n.controlsAnimationSpeed.isEmpty)
        XCTAssertFalse(L10n.controlsSpeed.isEmpty)
        XCTAssertFalse(L10n.controlsSpeedLow.isEmpty)
        XCTAssertFalse(L10n.controlsSpeedMid.isEmpty)
        XCTAssertFalse(L10n.controlsSpeedHigh.isEmpty)
        XCTAssertFalse(L10n.controlsScheduleActive.isEmpty)
    }

    func test_settingsStrings_nonEmpty() {
        XCTAssertFalse(L10n.settingsTitle.isEmpty)
        XCTAssertFalse(L10n.settingsAutoTheme.isEmpty)
        XCTAssertFalse(L10n.settingsWhenMusicPlays.isEmpty)
        XCTAssertFalse(L10n.settingsPlayingTheme.isEmpty)
        XCTAssertFalse(L10n.settingsWhenIdle.isEmpty)
        XCTAssertFalse(L10n.settingsIdleTheme.isEmpty)
        XCTAssertFalse(L10n.settingsLightSchedule.isEmpty)
        XCTAssertFalse(L10n.settingsLightsOffAt.isEmpty)
        XCTAssertFalse(L10n.settingsLightsOnAt.isEmpty)
        XCTAssertFalse(L10n.settingsLanguage.isEmpty)
        XCTAssertFalse(L10n.settingsLanguageSystem.isEmpty)
    }

    func test_colorStrings_nonEmpty() {
        XCTAssertFalse(L10n.colorRed.isEmpty)
        XCTAssertFalse(L10n.colorOrange.isEmpty)
        XCTAssertFalse(L10n.colorYellow.isEmpty)
        XCTAssertFalse(L10n.colorGreen.isEmpty)
        XCTAssertFalse(L10n.colorCyan.isEmpty)
        XCTAssertFalse(L10n.colorBlue.isEmpty)
        XCTAssertFalse(L10n.colorPurple.isEmpty)
        XCTAssertFalse(L10n.colorPink.isEmpty)
        XCTAssertFalse(L10n.colorWhite.isEmpty)
    }

    func test_themeStrings_nonEmpty() {
        XCTAssertFalse(L10n.themeNature.isEmpty)
        XCTAssertFalse(L10n.themeParty.isEmpty)
        XCTAssertFalse(L10n.themeSpiritual.isEmpty)
        XCTAssertFalse(L10n.themeCocktail.isEmpty)
        XCTAssertFalse(L10n.themeWeather.isEmpty)
        XCTAssertFalse(L10n.themeCanvas.isEmpty)
    }

    func test_stateStrings_nonEmpty() {
        XCTAssertFalse(L10n.stateDisconnected.isEmpty)
        XCTAssertFalse(L10n.stateScanning.isEmpty)
        XCTAssertFalse(L10n.stateConnecting.isEmpty)
        XCTAssertFalse(L10n.stateDiscoveringServices.isEmpty)
        XCTAssertFalse(L10n.stateConnected.isEmpty)
    }

    func test_errorStrings_nonEmpty() {
        XCTAssertFalse(L10n.errorPoweredOff.isEmpty)
        XCTAssertFalse(L10n.errorUnauthorized.isEmpty)
        XCTAssertFalse(L10n.errorUnsupported.isEmpty)
        XCTAssertFalse(L10n.errorServiceNotFound.isEmpty)
        XCTAssertFalse(L10n.errorCharacteristicNotFound.isEmpty)
        XCTAssertFalse(L10n.errorDisconnected.isEmpty)
        XCTAssertFalse(L10n.errorUnknownDevice.isEmpty)
    }

    // MARK: - Format Functions

    func test_stateReconnecting_containsAttemptNumber() {
        XCTAssertTrue(L10n.stateReconnecting(3).contains("3"))
    }

    func test_errorConnectionFailed_containsReason() {
        XCTAssertTrue(L10n.errorConnectionFailed("timeout").contains("timeout"))
    }

    func test_errorWriteFailed_containsReason() {
        XCTAssertTrue(L10n.errorWriteFailed("write error").contains("write error"))
    }

    func test_formatRSSI_containsValue() {
        XCTAssertTrue(L10n.formatRSSI(-50).contains("-50"))
    }
}
