@preconcurrency import CoreBluetooth

enum PulseConstants {
    static let serviceUUID = CBUUID(string: "65786365-6c70-6f69-6e74-2e636f6d0000")
    static let writeCharacteristicUUID = CBUUID(string: "65786365-6c70-6f69-6e74-2e636f6d0002")
    static let readCharacteristicUUID = CBUUID(string: "65786365-6c70-6f69-6e74-2e636f6d0001")

    static let header: UInt8 = 0xAA

    static let cmdReqSpeakerInfo: UInt8 = 0x11

    static let cmdReqLightStatus: UInt8 = 0x71
    static let cmdRetLightStatus: UInt8 = 0x72
    static let cmdSetLightStatus: UInt8 = 0x73

    static let cmdReqLedPackageInfo: UInt8 = 0x83
    static let cmdRetLedPackageInfo: UInt8 = 0x84
    static let cmdSetLedPackage: UInt8 = 0x85
    static let cmdSetLedBrightness: UInt8 = 0x8A
    static let cmdReqLedBrightness: UInt8 = 0x8B
    static let cmdRetLedBrightness: UInt8 = 0x8C

    static let cmdSetLedMovementSpeed: UInt8 = 0x8D
    static let cmdReqLedMovementSpeed: UInt8 = 0x8E
    static let cmdRetLedMovementSpeed: UInt8 = 0x8F

    static let cmdSwitchLedPackage: UInt8 = 0x90
    static let cmdPreviewPattern: UInt8 = 0x91

    static let minBrightness: UInt8 = 20
    static let maxBrightness: UInt8 = 80

    static let deviceName = "JBL Pulse 5"

    static let maxReconnectAttempts = 3
    static let baseReconnectDelay: UInt64 = 1_000_000_000
    static let connectionTimeout: UInt64 = 10_000_000_000

    static let lastPeripheralUUIDKey = "lastPeripheralUUID"
}
