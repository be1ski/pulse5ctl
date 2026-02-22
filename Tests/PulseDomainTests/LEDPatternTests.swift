import FeaturePulseDomain
import XCTest

final class LEDPatternTests: XCTestCase {

    // MARK: - CaseIterable

    func test_allCases_count_is21() {
        XCTAssertEqual(LEDPattern.allCases.count, 21)
    }

    // MARK: - Identifiable

    func test_id_equalsRawValue() {
        for pattern in LEDPattern.allCases {
            XCTAssertEqual(pattern.id, pattern.rawValue)
        }
    }

    // MARK: - displayName

    func test_displayName_allCases_nonEmpty() {
        for pattern in LEDPattern.allCases {
            XCTAssertFalse(pattern.displayName.isEmpty)
        }
    }

    func test_displayName_campfire_returnsExpected() {
        XCTAssertFalse(LEDPattern.campfire.displayName.isEmpty)
    }

    // MARK: - sfSymbol

    func test_sfSymbol_allCases_nonEmpty() {
        for pattern in LEDPattern.allCases {
            XCTAssertFalse(pattern.sfSymbol.isEmpty)
        }
    }

    func test_sfSymbol_campfire_returnsFlame() {
        XCTAssertEqual(LEDPattern.campfire.sfSymbol, "flame.fill")
    }

    func test_sfSymbol_northernLights_returnsSunHaze() {
        XCTAssertEqual(LEDPattern.northernLights.sfSymbol, "sun.haze.fill")
    }

    func test_sfSymbol_seaWave_returnsWaterWaves() {
        XCTAssertEqual(LEDPattern.seaWave.sfSymbol, "water.waves")
    }

    func test_sfSymbol_rainbow_returnsRainbow() {
        XCTAssertEqual(LEDPattern.rainbow.sfSymbol, "rainbow")
    }

    func test_sfSymbol_snow_returnsSnowflake() {
        XCTAssertEqual(LEDPattern.snow.sfSymbol, "snowflake")
    }

    func test_sfSymbol_cherry_returnsDropFill() {
        XCTAssertEqual(LEDPattern.cherry.sfSymbol, "drop.fill")
    }

    // MARK: - Raw Value Roundtrip

    func test_rawValue_roundtrip_allCases() {
        for pattern in LEDPattern.allCases {
            XCTAssertEqual(LEDPattern(rawValue: pattern.rawValue), pattern)
        }
    }

    func test_rawValue_invalid_returnsNil() {
        XCTAssertNil(LEDPattern(rawValue: 0x00))
        XCTAssertNil(LEDPattern(rawValue: 0x12))
        XCTAssertNil(LEDPattern(rawValue: 0xFF))
    }

    // MARK: - Codable

    func test_codable_roundtrip() throws {
        let original = LEDPattern.mojito
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LEDPattern.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Hashable

    func test_hashable_sameCases_haveEqualHashes() {
        let lhs = LEDPattern.lava
        let rhs = LEDPattern.lava
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
    }
}
