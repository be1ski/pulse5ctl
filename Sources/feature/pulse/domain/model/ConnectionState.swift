import CoreLocalization

public enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case discoveringServices
    case connected
    case reconnecting(attempt: Int)

    public var displayText: String {
        switch self {
        case .disconnected:
            return L10n.stateDisconnected
        case .scanning:
            return L10n.stateScanning
        case .connecting:
            return L10n.stateConnecting
        case .discoveringServices:
            return L10n.stateDiscoveringServices
        case .connected:
            return L10n.stateConnected
        case let .reconnecting(attempt):
            return L10n.stateReconnecting(attempt)
        }
    }

    public var isConnected: Bool {
        self == .connected
    }

    public var isActive: Bool {
        switch self {
        case .scanning, .connecting, .discoveringServices, .reconnecting:
            return true
        case .disconnected, .connected:
            return false
        }
    }
}
