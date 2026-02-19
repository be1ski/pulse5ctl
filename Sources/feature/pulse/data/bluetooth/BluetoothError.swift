import CoreLocalization
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
            return L10n.errorPoweredOff
        case .unauthorized:
            return L10n.errorUnauthorized
        case .unsupported:
            return L10n.errorUnsupported
        case .serviceNotFound:
            return L10n.errorServiceNotFound
        case .characteristicNotFound:
            return L10n.errorCharacteristicNotFound
        case let .connectionFailed(reason):
            return L10n.errorConnectionFailed(reason)
        case let .writeFailed(reason):
            return L10n.errorWriteFailed(reason)
        case .disconnected:
            return L10n.errorDisconnected
        case .unknownDevice:
            return L10n.errorUnknownDevice
        }
    }
}
