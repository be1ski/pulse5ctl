import CoreElm

func pulseConnectionReducer(
    _ action: PulseAction.Connection,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .connectTapped:
        context.state { current in
            var updated = current
            updated.connectionState = .scanning
            updated.errorMessage = nil
            return updated
        }
        context.command(.startScan)

    case .disconnectTapped:
        context.state { current in
            var updated = current
            updated.connectionState = .disconnected
            updated.connectedDeviceName = nil
            updated.discoveredDevices = []
            return updated
        }
        context.command(.disconnect)

    case let .selectDevice(deviceID):
        context.state { current in
            var updated = current
            updated.connectionState = .connecting
            updated.errorMessage = nil
            updated.connectedDeviceName = current.discoveredDevices.first(where: { $0.id == deviceID })?.name
            return updated
        }
        context.command(.connect(deviceID))
    }
}
