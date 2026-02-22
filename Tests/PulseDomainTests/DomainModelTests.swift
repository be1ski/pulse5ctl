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

    func test_autoThemeSettings_equatable_equalInstances() {
        let lhs = AutoThemeSettings(enabled: true, playingTheme: .nature, idleTheme: .nature)
        let rhs = AutoThemeSettings(enabled: true, playingTheme: .nature, idleTheme: .nature)
        XCTAssertEqual(lhs, rhs)
    }

    func test_autoThemeSettings_equatable_differentInstances() {
        let lhs = AutoThemeSettings(enabled: true, playingTheme: .party, idleTheme: .nature)
        let rhs = AutoThemeSettings(enabled: false, playingTheme: .party, idleTheme: .nature)
        XCTAssertNotEqual(lhs, rhs)
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

    // MARK: - DiscoveredDevice

    func test_discoveredDevice_init_setsAllProperties() {
        let id = UUID()
        let device = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -55, hasPulseService: true)
        XCTAssertEqual(device.id, id)
        XCTAssertEqual(device.name, "Pulse 5")
        XCTAssertEqual(device.rssi, -55)
        XCTAssertTrue(device.hasPulseService)
    }

    func test_discoveredDevice_id_matchesUUID() {
        let id = UUID()
        let device = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -70, hasPulseService: false)
        XCTAssertEqual(device.id, id)
    }

    func test_discoveredDevice_equatable_sameID_areEqual() {
        let id = UUID()
        let lhs = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -60, hasPulseService: true)
        let rhs = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -60, hasPulseService: true)
        XCTAssertEqual(lhs, rhs)
    }

    func test_discoveredDevice_equatable_differentID_areNotEqual() {
        let lhs = DiscoveredDevice(id: UUID(), name: "Pulse 5", rssi: -60, hasPulseService: true)
        let rhs = DiscoveredDevice(id: UUID(), name: "Pulse 5", rssi: -60, hasPulseService: true)
        XCTAssertNotEqual(lhs, rhs)
    }

    // MARK: - LEDColor

    func test_ledColor_init_setsRGB() {
        let color = LEDColor(red: 10, green: 20, blue: 30)
        XCTAssertEqual(color.red, 10)
        XCTAssertEqual(color.green, 20)
        XCTAssertEqual(color.blue, 30)
    }

    func test_ledColor_equatable_sameValues_areEqual() {
        let lhs = LEDColor(red: 128, green: 64, blue: 32)
        let rhs = LEDColor(red: 128, green: 64, blue: 32)
        XCTAssertEqual(lhs, rhs)
    }

    func test_ledColor_equatable_differentValues_areNotEqual() {
        let lhs = LEDColor(red: 255, green: 0, blue: 0)
        let rhs = LEDColor(red: 0, green: 255, blue: 0)
        XCTAssertNotEqual(lhs, rhs)
    }

    func test_ledColor_codable_roundtrip() throws {
        let original = LEDColor(red: 100, green: 150, blue: 200)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LEDColor.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - ColorEffect

    func test_colorEffect_staticColor_rawValue_isZero() {
        XCTAssertEqual(ColorEffect.staticColor.rawValue, 0)
    }

    func test_colorEffect_colorLoop_rawValue_isOne() {
        XCTAssertEqual(ColorEffect.colorLoop.rawValue, 1)
    }

    func test_colorEffect_codable_roundtrip() throws {
        let original = ColorEffect.staticColor
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ColorEffect.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - ConnectionState

    func test_connectionState_displayText_disconnected_nonEmpty() {
        XCTAssertFalse(ConnectionState.disconnected.displayText.isEmpty)
    }

    func test_connectionState_displayText_allBasicCases_nonEmpty() {
        let cases: [ConnectionState] = [.disconnected, .scanning, .connecting, .discoveringServices, .connected]
        for state in cases {
            XCTAssertFalse(state.displayText.isEmpty, "displayText was empty for \(state)")
        }
    }

    func test_connectionState_displayText_reconnecting_containsAttempt() {
        let text = ConnectionState.reconnecting(attempt: 3).displayText
        XCTAssertTrue(text.contains("3"))
    }

    // MARK: - LEDTheme

    func test_ledTheme_displayName_allCases_nonEmpty() {
        for theme in LEDTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty, "displayName was empty for \(theme)")
        }
    }

    func test_ledTheme_sfSymbol_nature_isLeafFill() {
        XCTAssertEqual(LEDTheme.nature.sfSymbol, "leaf.fill")
    }

    func test_ledTheme_sfSymbol_allCases_nonEmpty() {
        for theme in LEDTheme.allCases {
            XCTAssertFalse(theme.sfSymbol.isEmpty, "sfSymbol was empty for \(theme)")
        }
    }

    func test_ledTheme_patterns_canvas_isEmpty() {
        XCTAssertTrue(LEDTheme.canvas.patterns.isEmpty)
    }

    func test_ledTheme_patterns_nature_hasFourPatterns() {
        XCTAssertEqual(LEDTheme.nature.patterns.count, 4)
    }

    // MARK: - LEDCustomization

    func test_ledCustomization_defaultInit_hasExpectedDefaults() {
        let customization = LEDCustomization()
        XCTAssertTrue(customization.activePatterns.isEmpty)
        XCTAssertEqual(customization.colorEffect, .colorLoop)
        XCTAssertEqual(customization.customColor, LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF))
    }

    func test_ledCustomization_activePatternsMap_validData_returnsCorrectMap() {
        let customization = LEDCustomization(
            activePatterns: [0x01: [0x01, 0x02]],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )
        let map = customization.activePatternsMap()
        XCTAssertEqual(map[.nature], Set([.campfire, .northernLights]))
    }

    func test_ledCustomization_activePatternsMap_invalidThemeRaw_isSkipped() {
        let customization = LEDCustomization(
            activePatterns: [0xFF: [0x01]],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )
        XCTAssertTrue(customization.activePatternsMap().isEmpty)
    }

    func test_ledCustomization_activePatternsMap_invalidPatternRaw_isSkipped() {
        let customization = LEDCustomization(
            activePatterns: [0x01: [0xFF]],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )
        XCTAssertTrue(customization.activePatternsMap().isEmpty)
    }

    func test_ledCustomization_from_roundtrip() {
        let activePatterns: [LEDTheme: Set<LEDPattern>] = [
            .nature: Set([.campfire, .seaWave]),
            .party: Set([.rainbow])
        ]
        let customization = LEDCustomization.from(
            activePatterns: activePatterns,
            colorEffect: .staticColor,
            customColor: LEDColor(red: 10, green: 20, blue: 30)
        )
        let map = customization.activePatternsMap()
        XCTAssertEqual(map[.nature], Set([.campfire, .seaWave]))
        XCTAssertEqual(map[.party], Set([.rainbow]))
    }

    func test_ledCustomization_codable_roundtrip() throws {
        let original = LEDCustomization.from(
            activePatterns: [.spiritual: Set([.lava, .focus])],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 50, green: 100, blue: 200)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LEDCustomization.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
