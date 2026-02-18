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
            return "Disconnected"
        case .scanning:
            return "Scanning..."
        case .connecting:
            return "Connecting..."
        case .discoveringServices:
            return "Discovering services..."
        case .connected:
            return "Connected"
        case let .reconnecting(attempt):
            return "Reconnecting (\(attempt)/3)..."
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
