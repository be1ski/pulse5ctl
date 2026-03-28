@preconcurrency import CoreBluetooth

enum ReusablePeripheralChoice: Equatable {
    case connectedService
    case cached
    case none

    static func select(
        hasConnectedServicePeripheral: Bool,
        cachedPeripheralState: CBPeripheralState?,
        allowDisconnectedCached: Bool = false
    ) -> Self {
        if hasConnectedServicePeripheral {
            return .connectedService
        }

        switch cachedPeripheralState {
        case .connected:
            return .cached
        case .disconnected:
            return allowDisconnectedCached ? .cached : .none
        default:
            return .none
        }
    }
}
