import FeaturePulseDomain
import XCTest

final class LEDThemeTests: XCTestCase {

    // MARK: - Raw Values

    func test_rawValue_nature_isCorrect() { XCTAssertEqual(LEDTheme.nature.rawValue, 0x01) }
    func test_rawValue_party_isCorrect() { XCTAssertEqual(LEDTheme.party.rawValue, 0x02) }
    func test_rawValue_spiritual_isCorrect() { XCTAssertEqual(LEDTheme.spiritual.rawValue, 0x03) }
    func test_rawValue_cocktail_isCorrect() { XCTAssertEqual(LEDTheme.cocktail.rawValue, 0x04) }
    func test_rawValue_weather_isCorrect() { XCTAssertEqual(LEDTheme.weather.rawValue, 0x05) }
    func test_rawValue_canvas_isCorrect() { XCTAssertEqual(LEDTheme.canvas.rawValue, 0xC1) }

    // MARK: - Raw Value Roundtrip

    func test_rawValue_allCases_roundtrip() {
        for theme in LEDTheme.allCases {
            XCTAssertEqual(LEDTheme(rawValue: theme.rawValue), theme)
        }
    }

    func test_init_invalidRawValue_returnsNil() {
        XCTAssertNil(LEDTheme(rawValue: 0xFF))
    }

    // MARK: - Patterns

    func test_patterns_nature_isCorrect() {
        XCTAssertEqual(LEDTheme.nature.patterns, [.campfire, .northernLights, .seaWave, .universe])
    }

    func test_patterns_party_isCorrect() {
        XCTAssertEqual(LEDTheme.party.patterns, [.strobe, .equalizer, .geometry, .spin, .rainbow])
    }

    func test_patterns_spiritual_isCorrect() {
        XCTAssertEqual(LEDTheme.spiritual.patterns, [.dynamicWave, .lava, .focus])
    }

    func test_patterns_cocktail_isCorrect() {
        XCTAssertEqual(LEDTheme.cocktail.patterns, [.fruitGin, .mojito, .tequila, .cherry])
    }

    func test_patterns_weather_isCorrect() {
        XCTAssertEqual(LEDTheme.weather.patterns, [.skySunny, .rain, .snow, .thunder, .cloud])
    }

    func test_patterns_canvas_isEmpty() {
        XCTAssertTrue(LEDTheme.canvas.patterns.isEmpty)
    }

    // MARK: - Identifiable

    func test_id_matchesRawValue() {
        for theme in LEDTheme.allCases {
            XCTAssertEqual(theme.id, theme.rawValue)
        }
    }

    // MARK: - CaseIterable

    func test_allCases_correctCount() {
        XCTAssertEqual(LEDTheme.allCases.count, 6)
    }
}
