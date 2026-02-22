import FeaturePulseDomain
import XCTest

final class LEDThemeTests: XCTestCase {

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
}
