import Foundation

enum BluetoothError: LocalizedError {
    case poweredOff
    case unauthorized
    case unsupported
    case serviceNotFound
    case characteristicNotFound
    case connectionFailed(String)
    case writeFailed(String)
    case disconnected
    case unknownDevice

    var errorDescription: String? {
        switch self {
        case .poweredOff:
            return "Bluetooth is powered off. Enable Bluetooth in System Settings."
        case .unauthorized:
            return "Bluetooth access is not authorized."
        case .unsupported:
            return "Bluetooth LE is not supported on this Mac."
        case .serviceNotFound:
            return "Pulse 5 BLE service not found on this device."
        case .characteristicNotFound:
            return "Pulse 5 BLE characteristics were not found."
        case let .connectionFailed(reason):
            return "Connection failed: \(reason)"
        case let .writeFailed(reason):
            return "Command write failed: \(reason)"
        case .disconnected:
            return "Speaker disconnected unexpectedly."
        case .unknownDevice:
            return "Device is no longer in discovery list."
        }
    }
}
