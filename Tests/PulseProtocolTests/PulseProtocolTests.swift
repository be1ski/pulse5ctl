@testable import FeaturePulseData
import FeaturePulseDomain
import XCTest

final class PulseProtocolTests: XCTestCase {

    // MARK: - Request Encoding

    func test_requestSpeakerInfo_correctFormat() {
        let data = PulseProtocol.requestSpeakerInfo()
        XCTAssertEqual(data.count, 3)
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdReqSpeakerInfo)
        XCTAssertEqual(data[2], 0x00)
    }

    func test_setLightStatus_on_encodesCorrectByte() {
        let data = PulseProtocol.setLightStatus(true)
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdSetLightStatus)
        XCTAssertEqual(data[2], 0x01) // length
        XCTAssertEqual(data[3], 1)    // on
    }

    func test_setLightStatus_off_encodesZeroByte() {
        let data = PulseProtocol.setLightStatus(false)
        XCTAssertEqual(data[3], 0) // off
    }

    func test_requestLightStatus_correctFormat() {
        let data = PulseProtocol.requestLightStatus()
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdReqLightStatus)
        XCTAssertEqual(data[2], 0x00)
    }

    func test_switchPackage_correctFormat() {
        let data = PulseProtocol.switchPackage(0x02)
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdSwitchLedPackage)
        XCTAssertEqual(data[2], 0x01)
        XCTAssertEqual(data[3], 0x02)
    }

    func test_setLedBrightness_correctFormat() {
        let data = PulseProtocol.setLedBrightness(level: 50, bodyLight: true, projection: false)
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdSetLedBrightness)
        XCTAssertEqual(data[2], 0x03) // length
        XCTAssertEqual(data[3], 50)   // level
        XCTAssertEqual(data[4], 1)    // bodyLight
        XCTAssertEqual(data[5], 0)    // projection
    }

    func test_setLedBrightness_belowMin_clampsToMin() {
        let data = PulseProtocol.setLedBrightness(level: 5, bodyLight: true, projection: true)
        XCTAssertEqual(data[3], PulseConstants.minBrightness) // clamped to 20
    }

    func test_setLedBrightness_aboveMax_clampsToMax() {
        let data = PulseProtocol.setLedBrightness(level: 100, bodyLight: true, projection: true)
        XCTAssertEqual(data[3], PulseConstants.maxBrightness) // clamped to 80
    }

    func test_requestLedBrightness_correctFormat() {
        let data = PulseProtocol.requestLedBrightness()
        XCTAssertEqual(data[1], PulseConstants.cmdReqLedBrightness)
        XCTAssertEqual(data[2], 0x00)
    }

    func test_setMovementSpeed_correctFormat() {
        let data = PulseProtocol.setMovementSpeed(3)
        XCTAssertEqual(data[1], PulseConstants.cmdSetLedMovementSpeed)
        XCTAssertEqual(data[2], 0x01)
        XCTAssertEqual(data[3], 3)
    }

    func test_requestMovementSpeed_correctFormat() {
        let data = PulseProtocol.requestMovementSpeed()
        XCTAssertEqual(data[1], PulseConstants.cmdReqLedMovementSpeed)
        XCTAssertEqual(data[2], 0x00)
    }

    func test_requestLedPackageInfo_correctFormat() {
        let data = PulseProtocol.requestLedPackageInfo()
        XCTAssertEqual(data[1], PulseConstants.cmdReqLedPackageInfo)
        XCTAssertEqual(data[2], 0x00)
    }

    func test_previewPattern_correctFormat() {
        let data = PulseProtocol.previewPattern(packageID: 0x01, patternID: 0x02)
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdPreviewPattern)
        XCTAssertEqual(data[2], 0x02) // length
        XCTAssertEqual(data[3], 0x01) // packageID
        XCTAssertEqual(data[4], 0x02) // patternID
    }

    // MARK: - setLedPackage Encoding

    func test_setLedPackage_correctFormat() {
        let data = PulseProtocol.setLedPackage(
            packageID: 0x01,
            activePatterns: [0x01, 0x02],
            allPatterns: [0x01, 0x02, 0x03, 0x04],
            colorEffect: 1,
            color: LEDColor(red: 0xFF, green: 0x00, blue: 0x80)
        )
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], PulseConstants.cmdSetLedPackage)
        XCTAssertEqual(data[2], 11)   // allCount(4) + 7
        XCTAssertEqual(data[3], 0x01) // packageID
        XCTAssertEqual(data[4], 2)    // activeCount
        XCTAssertEqual(data[5], 4)    // allCount
        // allPatterns
        XCTAssertEqual(data[6], 0x01)
        XCTAssertEqual(data[7], 0x02)
        XCTAssertEqual(data[8], 0x03)
        XCTAssertEqual(data[9], 0x04)
        // color effect + RGB
        XCTAssertEqual(data[10], 1)
        XCTAssertEqual(data[11], 0xFF)
        XCTAssertEqual(data[12], 0x00)
        XCTAssertEqual(data[13], 0x80)
    }

    // MARK: - Response Parsing

    func test_parse_validResponse_returnsCommandAndPayload() {
        let data = Data([0xAA, 0x72, 0x01, 0x01])
        let response = PulseProtocol.parse(data)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.commandID, 0x72)
        XCTAssertEqual(response?.payload, Data([0x01]))
    }

    func test_parse_invalidHeader_returnsNil() {
        let data = Data([0xBB, 0x72, 0x01, 0x01])
        XCTAssertNil(PulseProtocol.parse(data))
    }

    func test_parse_tooShortData_returnsNil() {
        let data = Data([0xAA, 0x72])
        XCTAssertNil(PulseProtocol.parse(data))
    }

    func test_parse_emptyPayload_returnsEmptyData() {
        let data = Data([0xAA, 0x11, 0x00])
        let response = PulseProtocol.parse(data)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.payload, Data())
    }

    func test_parse_extraBytesAfterLength_truncatesToLength() {
        // length says 1 but more bytes follow
        let data = Data([0xAA, 0x72, 0x01, 0x01, 0xFF, 0xFF])
        let response = PulseProtocol.parse(data)
        XCTAssertEqual(response?.payload.count, 1)
    }

    // MARK: - parseBrightnessState

    func test_parseBrightnessState_validData_returnsState() {
        let data = Data([0xAA, PulseConstants.cmdRetLedBrightness, 0x03, 60, 1, 0])
        let brightness = PulseProtocol.parseBrightnessState(data)
        XCTAssertNotNil(brightness)
        XCTAssertEqual(brightness?.level, 60)
        XCTAssertTrue(brightness!.bodyLightOn)
        XCTAssertFalse(brightness!.projectionOn)
    }

    func test_parseBrightnessState_wrongCommand_returnsNil() {
        let data = Data([0xAA, 0x72, 0x03, 60, 1, 0])
        XCTAssertNil(PulseProtocol.parseBrightnessState(data))
    }

    func test_parseBrightnessState_tooShortPayload_returnsNil() {
        let data = Data([0xAA, PulseConstants.cmdRetLedBrightness, 0x02, 60, 1])
        XCTAssertNil(PulseProtocol.parseBrightnessState(data))
    }

    // MARK: - parseLightStatus

    func test_parseLightStatus_on_returnsTrue() {
        let data = Data([0xAA, PulseConstants.cmdRetLightStatus, 0x01, 0x01])
        XCTAssertEqual(PulseProtocol.parseLightStatus(data), true)
    }

    func test_parseLightStatus_off_returnsFalse() {
        let data = Data([0xAA, PulseConstants.cmdRetLightStatus, 0x01, 0x00])
        XCTAssertEqual(PulseProtocol.parseLightStatus(data), false)
    }

    func test_parseLightStatus_wrongCommand_returnsNil() {
        let data = Data([0xAA, 0x11, 0x01, 0x01])
        XCTAssertNil(PulseProtocol.parseLightStatus(data))
    }

    func test_parseLightStatus_emptyPayload_returnsNil() {
        let data = Data([0xAA, PulseConstants.cmdRetLightStatus, 0x00])
        XCTAssertNil(PulseProtocol.parseLightStatus(data))
    }

    // MARK: - parseMovementSpeed

    func test_parseMovementSpeed_validData_returnsValue() {
        let data = Data([0xAA, PulseConstants.cmdRetLedMovementSpeed, 0x01, 5])
        XCTAssertEqual(PulseProtocol.parseMovementSpeed(data), 5)
    }

    func test_parseMovementSpeed_wrongCommand_returnsNil() {
        let data = Data([0xAA, 0x72, 0x01, 5])
        XCTAssertNil(PulseProtocol.parseMovementSpeed(data))
    }

    // MARK: - parseSelectedTheme

    func test_parseSelectedTheme_validData_returnsTheme() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0x02])
        XCTAssertEqual(PulseProtocol.parseSelectedTheme(data), .party)
    }

    func test_parseSelectedTheme_unknownRawValue_returnsNil() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x02, 0x00, 0xFF])
        XCTAssertNil(PulseProtocol.parseSelectedTheme(data))
    }

    func test_parseSelectedTheme_tooShortPayload_returnsNil() {
        let data = Data([0xAA, PulseConstants.cmdRetLedPackageInfo, 0x01, 0x00])
        XCTAssertNil(PulseProtocol.parseSelectedTheme(data))
    }

    func test_parseSelectedTheme_wrongCommand_returnsNil() {
        let data = Data([0xAA, 0x11, 0x02, 0x00, 0x02])
        XCTAssertNil(PulseProtocol.parseSelectedTheme(data))
    }

    // MARK: - All header bytes use the constant

    func test_allEncodedMessages_startWithHeaderByte() {
        let messages: [Data] = [
            PulseProtocol.requestSpeakerInfo(),
            PulseProtocol.setLightStatus(true),
            PulseProtocol.requestLightStatus(),
            PulseProtocol.switchPackage(1),
            PulseProtocol.setLedBrightness(level: 50, bodyLight: true, projection: true),
            PulseProtocol.requestLedBrightness(),
            PulseProtocol.setMovementSpeed(2),
            PulseProtocol.requestMovementSpeed(),
            PulseProtocol.requestLedPackageInfo(),
            PulseProtocol.previewPattern(packageID: 1, patternID: 1)
        ]
        for msg in messages {
            XCTAssertEqual(msg[0], 0xAA, "Message should start with header byte")
        }
    }
}
