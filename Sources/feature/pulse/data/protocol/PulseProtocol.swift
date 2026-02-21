import FeaturePulseDomain
import Foundation

enum PulseProtocol {
    static func requestSpeakerInfo() -> Data {
        Data([PulseConstants.header, PulseConstants.cmdReqSpeakerInfo, 0x00])
    }

    static func setLightStatus(_ enabled: Bool) -> Data {
        Data([PulseConstants.header, PulseConstants.cmdSetLightStatus, 0x01, enabled ? 1 : 0])
    }

    static func requestLightStatus() -> Data {
        Data([PulseConstants.header, PulseConstants.cmdReqLightStatus, 0x00])
    }

    static func switchPackage(_ packageID: UInt8) -> Data {
        Data([PulseConstants.header, PulseConstants.cmdSwitchLedPackage, 0x01, packageID])
    }

    static func setLedBrightness(level: UInt8, bodyLight: Bool, projection: Bool) -> Data {
        let clamped = min(max(level, PulseConstants.minBrightness), PulseConstants.maxBrightness)
        return Data([
            PulseConstants.header,
            PulseConstants.cmdSetLedBrightness,
            0x03,
            clamped,
            bodyLight ? 1 : 0,
            projection ? 1 : 0
        ])
    }

    static func requestLedBrightness() -> Data {
        Data([PulseConstants.header, PulseConstants.cmdReqLedBrightness, 0x00])
    }

    static func setMovementSpeed(_ speed: UInt8) -> Data {
        Data([PulseConstants.header, PulseConstants.cmdSetLedMovementSpeed, 0x01, speed])
    }

    static func requestMovementSpeed() -> Data {
        Data([PulseConstants.header, PulseConstants.cmdReqLedMovementSpeed, 0x00])
    }

    static func requestLedPackageInfo() -> Data {
        Data([PulseConstants.header, PulseConstants.cmdReqLedPackageInfo, 0x00])
    }

    static func setLedPackage(
        packageID: UInt8,
        activePatterns: [UInt8],
        allPatterns: [UInt8],
        colorEffect: UInt8,
        color: LEDColor
    ) -> Data {
        let allCount = UInt8(allPatterns.count)
        let activeCount = UInt8(activePatterns.count)
        let length = allCount + 7

        var bytes: [UInt8] = [
            PulseConstants.header,
            PulseConstants.cmdSetLedPackage,
            length,
            packageID,
            activeCount,
            allCount
        ]
        bytes.append(contentsOf: allPatterns)
        bytes.append(contentsOf: [colorEffect, color.red, color.green, color.blue])
        return Data(bytes)
    }

    static func previewPattern(packageID: UInt8, patternID: UInt8) -> Data {
        Data([PulseConstants.header, PulseConstants.cmdPreviewPattern, 0x02, packageID, patternID])
    }

    struct Response {
        let commandID: UInt8
        let payload: Data
    }

    static func parse(_ data: Data) -> Response? {
        guard data.count >= 3, data[0] == PulseConstants.header else { return nil }
        let commandID = data[1]
        let length = Int(data[2])
        let payload = data.count > 3 ? data.suffix(from: 3).prefix(length) : Data()
        return Response(commandID: commandID, payload: Data(payload))
    }

    struct BrightnessState {
        let level: UInt8
        let bodyLightOn: Bool
        let projectionOn: Bool
    }

    static func parseBrightnessState(_ data: Data) -> BrightnessState? {
        guard let response = parse(data),
              response.commandID == PulseConstants.cmdRetLedBrightness,
              response.payload.count >= 3 else {
            return nil
        }

        return BrightnessState(
            level: response.payload[0],
            bodyLightOn: response.payload[1] != 0,
            projectionOn: response.payload[2] != 0
        )
    }

    static func parseLightStatus(_ data: Data) -> Bool? {
        guard let response = parse(data),
              response.commandID == PulseConstants.cmdRetLightStatus,
              response.payload.count >= 1 else {
            return nil
        }

        return response.payload[0] != 0
    }

    static func parseMovementSpeed(_ data: Data) -> UInt8? {
        guard let response = parse(data),
              response.commandID == PulseConstants.cmdRetLedMovementSpeed,
              response.payload.count >= 1 else {
            return nil
        }

        return response.payload[0]
    }

    static func parseSelectedTheme(_ data: Data) -> LEDTheme? {
        guard let response = parse(data),
              response.commandID == PulseConstants.cmdRetLedPackageInfo,
              response.payload.count >= 2 else {
            return nil
        }

        return LEDTheme(rawValue: response.payload[1])
    }
}
