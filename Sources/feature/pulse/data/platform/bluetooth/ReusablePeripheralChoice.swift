@preconcurrency import CoreBluetooth

enum ReusablePeripheralChoice: Equatable {
    case connectedService
    case cached
    case none

    static func select(
        hasConnectedServicePeripheral: Bool,
        cachedPeripheralState: CBPeripheralState?
    ) -> Self {
        if hasConnectedServicePeripheral {
            return .connectedService
        }

        switch cachedPeripheralState {
        case .connected, .disconnected:
            return .cached
        default:
            return .none
        }
    }
}
