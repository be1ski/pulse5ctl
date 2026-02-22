@testable import FeaturePulseData
import FeaturePulseDomain
import XCTest

final class PulseProtocolExtendedTests: XCTestCase {

    // MARK: - parse edge cases

    func test_parse_exactlyThreeBytes_returnsEmptyPayload() {
        let data = Data([0xAA, 0x11, 0x00])
        let response = PulseProtocol.parse(data)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.payload.count, 0)
    }

    func test_parse_lengthExceedsAvailableData_truncatesPayload() {
        let data = Data([0xAA, 0x11, 0x05, 0x01, 0x02])
        let response = PulseProtocol.parse(data)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.payload.count, 2)
    }

    func test_parse_emptyData_returnsNil() {
        XCTAssertNil(PulseProtocol.parse(Data()))
    }

    func test_parse_singleByte_returnsNil() {
        XCTAssertNil(PulseProtocol.parse(Data([0xAA])))
    }

    func test_parse_largePayload_parsesCorrectly() {
        let payload: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A]
        let data = Data([0xAA, 0x84, UInt8(payload.count)] + payload)
        let response = PulseProtocol.parse(data)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.commandID, 0x84)
        XCTAssertEqual(response?.payload, Data(payload))
        XCTAssertEqual(response?.payload.count, 10)
    }

    // MARK: - parseBrightnessState edge cases

    func test_parseBrightnessState_bodyLightOff_projectionOn_parsesCorrectly() {
        let data = Data([0xAA, 0x8C, 0x03, 40, 0, 1])
        let brightness = PulseProtocol.parseBrightnessState(data)
        XCTAssertNotNil(brightness)
        XCTAssertEqual(brightness?.level, 40)
        XCTAssertFalse(brightness!.bodyLightOn)
        XCTAssertTrue(brightness!.projectionOn)
    }

    func test_parseBrightnessState_allFlagsOn_parsesCorrectly() {
        let data = Data([0xAA, 0x8C, 0x03, 80, 1, 1])
        let brightness = PulseProtocol.parseBrightnessState(data)
        XCTAssertNotNil(brightness)
        XCTAssertEqual(brightness?.level, 80)
        XCTAssertTrue(brightness!.bodyLightOn)
        XCTAssertTrue(brightness!.projectionOn)
    }

    func test_parseBrightnessState_nonZeroValues_treatAsTrueForFlags() {
        let data = Data([0xAA, 0x8C, 0x03, 50, 0x02, 0xFF])
        let brightness = PulseProtocol.parseBrightnessState(data)
        XCTAssertNotNil(brightness)
        XCTAssertTrue(brightness!.bodyLightOn)
        XCTAssertTrue(brightness!.projectionOn)
    }

    func test_parseBrightnessState_invalidHeader_returnsNil() {
        let data = Data([0xBB, 0x8C, 0x03, 60, 1, 0])
        XCTAssertNil(PulseProtocol.parseBrightnessState(data))
    }

    // MARK: - parseSelectedTheme all themes

    func test_parseSelectedTheme_nature_returnsNature() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0x01])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .nature)
    }

    func test_parseSelectedTheme_party_returnsParty() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0x02])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .party)
    }

    func test_parseSelectedTheme_spiritual_returnsSpiritual() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0x03])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .spiritual)
    }

    func test_parseSelectedTheme_cocktail_returnsCocktail() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0x04])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .cocktail)
    }

    func test_parseSelectedTheme_weather_returnsWeather() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0x05])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .weather)
    }

    func test_parseSelectedTheme_canvas_returnsCanvas() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0xC1])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .canvas)
    }

    // MARK: - setLedPackage edge cases

    func test_setLedPackage_emptyPatterns_encodesCorrectly() {
        let data = PulseProtocol.setLedPackage(
            packageID: 0x01,
            activePatterns: [],
            allPatterns: [],
            colorEffect: 0,
            color: LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF)
        )
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdSetLedPackage)
        XCTAssertEqual(data[2], 7)
        XCTAssertEqual(data[3], 0x01)
        XCTAssertEqual(data[4], 0)
        XCTAssertEqual(data[5], 0)
        XCTAssertEqual(data[6], 0)
        XCTAssertEqual(data[7], 0xFF)
        XCTAssertEqual(data[8], 0xFF)
        XCTAssertEqual(data[9], 0xFF)
        XCTAssertEqual(data.count, 10)
    }

    func test_setLedPackage_singlePattern_encodesCorrectly() {
        let data = PulseProtocol.setLedPackage(
            packageID: 0x02,
            activePatterns: [0x05],
            allPatterns: [0x05],
            colorEffect: 1,
            color: LEDColor(red: 0x10, green: 0x20, blue: 0x30)
        )
        XCTAssertEqual(data[2], 8)
        XCTAssertEqual(data[3], 0x02)
        XCTAssertEqual(data[4], 1)
        XCTAssertEqual(data[5], 1)
        XCTAssertEqual(data[6], 0x05)
        XCTAssertEqual(data[7], 1)
        XCTAssertEqual(data[8], 0x10)
        XCTAssertEqual(data[9], 0x20)
        XCTAssertEqual(data[10], 0x30)
    }

    // MARK: - PulseConstants values

    func test_pulseConstants_header_isAA() {
        XCTAssertEqual(PulseConstants.header, 0xAA)
    }

    func test_pulseConstants_brightnessRange_20to80() {
        XCTAssertEqual(PulseConstants.minBrightness, 20)
        XCTAssertEqual(PulseConstants.maxBrightness, 80)
    }

    func test_pulseConstants_deviceName_isJBLPulse5() {
        XCTAssertEqual(PulseConstants.deviceName, "JBL Pulse 5")
    }

    func test_pulseConstants_maxReconnectAttempts_is3() {
        XCTAssertEqual(PulseConstants.maxReconnectAttempts, 3)
    }

    func test_pulseConstants_manufacturerID_is87() {
        XCTAssertEqual(PulseConstants.manufacturerID, 87)
    }

    // MARK: - Brightness clamping

    func test_setLedBrightness_atMinBoundary_keepsValue() {
        let data = PulseProtocol.setLedBrightness(level: 20, bodyLight: false, projection: false)
        XCTAssertEqual(data[3], 20)
    }

    func test_setLedBrightness_atMaxBoundary_keepsValue() {
        let data = PulseProtocol.setLedBrightness(level: 80, bodyLight: false, projection: false)
        XCTAssertEqual(data[3], 80)
    }

    func test_setLedBrightness_withinRange_keepsValue() {
        let data = PulseProtocol.setLedBrightness(level: 50, bodyLight: false, projection: false)
        XCTAssertEqual(data[3], 50)
    }
}
