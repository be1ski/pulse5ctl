import FeaturePulseDomain
import XCTest

final class LEDCustomizationTests: XCTestCase {

    // MARK: - activePatternsMap()

    func test_activePatternsMap_convertsRawToTyped() {
        let customization = LEDCustomization(
            activePatterns: [0x01: [0x01, 0x02]], // nature: [campfire, northernLights]
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF)
        )

        let map = customization.activePatternsMap()
        XCTAssertEqual(map[.nature], Set([.campfire, .northernLights]))
    }

    func test_activePatternsMap_invalidTheme_ignored() {
        let customization = LEDCustomization(
            activePatterns: [0xFF: [0x01]],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )
        XCTAssertTrue(customization.activePatternsMap().isEmpty)
    }

    func test_activePatternsMap_invalidPatterns_ignored() {
        let customization = LEDCustomization(
            activePatterns: [0x01: [0xFE, 0xFF]],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )
        XCTAssertTrue(customization.activePatternsMap().isEmpty)
    }

    func test_activePatternsMap_multipleThemes_allConverted() {
        let customization = LEDCustomization(
            activePatterns: [
                0x01: [0x01],            // nature: campfire
                0x02: [0x05, 0x06]       // party: strobe, equalizer
            ],
            colorEffect: .staticColor,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )
        let map = customization.activePatternsMap()
        XCTAssertEqual(map[.nature], Set([.campfire]))
        XCTAssertEqual(map[.party], Set([.strobe, .equalizer]))
    }

    // MARK: - from() roundtrip

    func test_from_roundtrip_matchesOriginal() {
        let activePatterns: [LEDTheme: Set<LEDPattern>] = [
            .nature: Set([.campfire, .seaWave]),
            .party: Set([.rainbow])
        ]
        let color = LEDColor(red: 128, green: 64, blue: 32)

        let customization = LEDCustomization.from(
            activePatterns: activePatterns,
            colorEffect: .staticColor,
            customColor: color
        )

        // Verify roundtrip
        let roundtripped = customization.activePatternsMap()
        XCTAssertEqual(roundtripped[.nature], Set([.campfire, .seaWave]))
        XCTAssertEqual(roundtripped[.party], Set([.rainbow]))
        XCTAssertEqual(customization.colorEffect, .staticColor)
        XCTAssertEqual(customization.customColor, color)
    }

    func test_from_storesPatternsSorted() {
        let customization = LEDCustomization.from(
            activePatterns: [.nature: Set([.universe, .campfire, .seaWave])],
            colorEffect: .colorLoop,
            customColor: LEDColor(red: 0, green: 0, blue: 0)
        )

        // Raw values should be sorted
        let rawPatterns = customization.activePatterns[LEDTheme.nature.rawValue]!
        XCTAssertEqual(rawPatterns, rawPatterns.sorted())
    }

    // MARK: - Default values

    func test_init_default_hasExpectedValues() {
        let customization = LEDCustomization()
        XCTAssertTrue(customization.activePatterns.isEmpty)
        XCTAssertEqual(customization.colorEffect, .colorLoop)
        XCTAssertEqual(customization.customColor, LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF))
    }

    // MARK: - Codable roundtrip

    func test_codable_roundtrip_preservesEquality() throws {
        let original = LEDCustomization.from(
            activePatterns: [.party: Set([.strobe, .equalizer])],
            colorEffect: .staticColor,
            customColor: LEDColor(red: 100, green: 200, blue: 50)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LEDCustomization.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
