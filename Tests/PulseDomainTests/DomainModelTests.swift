import FeaturePulseDomain
import Foundation
import XCTest

final class DomainModelTests: XCTestCase {

    // MARK: - AutoThemeSettings

    func test_autoThemeSettings_defaultInit_hasExpectedDefaults() {
        let settings = AutoThemeSettings()
        XCTAssertFalse(settings.enabled)
        XCTAssertEqual(settings.playingTheme, .party)
        XCTAssertEqual(settings.idleTheme, .nature)
    }

    func test_autoThemeSettings_customInit_setsValues() {
        let settings = AutoThemeSettings(enabled: true, playingTheme: .spiritual, idleTheme: .cocktail)
        XCTAssertTrue(settings.enabled)
        XCTAssertEqual(settings.playingTheme, .spiritual)
        XCTAssertEqual(settings.idleTheme, .cocktail)
    }

    func test_autoThemeSettings_codable_roundtrip() throws {
        let original = AutoThemeSettings(enabled: true, playingTheme: .weather, idleTheme: .party)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AutoThemeSettings.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - LightScheduleSettings

    func test_lightScheduleSettings_defaultInit_hasExpectedDefaults() {
        let settings = LightScheduleSettings()
        XCTAssertFalse(settings.enabled)
        XCTAssertEqual(settings.offHour, 2)
        XCTAssertEqual(settings.offMinute, 0)
        XCTAssertEqual(settings.onHour, 10)
        XCTAssertEqual(settings.onMinute, 0)
    }

    func test_lightScheduleSettings_customInit_setsValues() {
        let settings = LightScheduleSettings(enabled: true, offHour: 23, offMinute: 30, onHour: 7, onMinute: 15)
        XCTAssertTrue(settings.enabled)
        XCTAssertEqual(settings.offHour, 23)
        XCTAssertEqual(settings.offMinute, 30)
        XCTAssertEqual(settings.onHour, 7)
        XCTAssertEqual(settings.onMinute, 15)
    }

    func test_lightScheduleSettings_codable_roundtrip() throws {
        let original = LightScheduleSettings(enabled: true, offHour: 22, offMinute: 45, onHour: 8, onMinute: 0)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LightScheduleSettings.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
