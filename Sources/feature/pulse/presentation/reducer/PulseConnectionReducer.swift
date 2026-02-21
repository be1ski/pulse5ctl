import CoreElm

func pulseConnectionReducer(
    _ action: PulseAction.Connection,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .connectTapped:
        context.state {
            $0.connectionState = .scanning
            $0.errorMessage = nil
        }
        context.command(.startScan)

    case .disconnectTapped:
        context.state {
            $0.connectionState = .disconnected
            $0.connectedDeviceName = nil
            $0.discoveredDevices = []
        }
        context.command(.disconnect)

    case let .selectDevice(deviceID):
        context.state {
            $0.connectionState = .connecting
            $0.errorMessage = nil
            $0.connectedDeviceName = $0.discoveredDevices.first(where: { $0.id == deviceID })?.name
        }
        context.command(.connect(deviceID))
    }
}
