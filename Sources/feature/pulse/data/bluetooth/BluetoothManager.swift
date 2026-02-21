import CoreBluetooth
import FeaturePulseDomain
import Foundation

final class BluetoothManager: NSObject {
    let stateUpdates: AsyncStream<ConnectionState>
    let discoveredDevices: AsyncStream<DiscoveredDevice>
    let receivedData: AsyncStream<Data>
    let errors: AsyncStream<BluetoothError?>

    private let stateContinuation: AsyncStream<ConnectionState>.Continuation
    private let deviceContinuation: AsyncStream<DiscoveredDevice>.Continuation
    private let dataContinuation: AsyncStream<Data>.Continuation
    private let errorContinuation: AsyncStream<BluetoothError?>.Continuation

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var readCharacteristic: CBCharacteristic?
    private let bleQueue = DispatchQueue(label: "pulse5ctl.ble", qos: .userInitiated)

    private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            stateContinuation.yield(connectionState)
        }
    }

    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var reconnectAttempt = 0
    private var shouldReconnect = false
    private var reconnectTask: Task<Void, Never>?

    override init() {
        var stateCont: AsyncStream<ConnectionState>.Continuation?
        stateUpdates = AsyncStream { stateCont = $0 }
        stateContinuation = stateCont!

        var deviceCont: AsyncStream<DiscoveredDevice>.Continuation?
        discoveredDevices = AsyncStream { deviceCont = $0 }
        deviceContinuation = deviceCont!

        var dataCont: AsyncStream<Data>.Continuation?
        receivedData = AsyncStream { dataCont = $0 }
        dataContinuation = dataCont!

        var errorCont: AsyncStream<BluetoothError?>.Continuation?
        errors = AsyncStream { errorCont = $0 }
        errorContinuation = errorCont!

        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            return
        }

        discoveredPeripherals.removeAll()
        connectionState = .scanning

        let connected = centralManager.retrieveConnectedPeripherals(withServices: [PulseConstants.serviceUUID])
        if let firstConnected = connected.first {
            connect(to: firstConnected)
            return
        }

        if let uuidString = UserDefaults.standard.string(forKey: PulseConstants.lastPeripheralUUIDKey),
           let uuid = UUID(uuidString: uuidString),
           let cached = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
            connect(to: cached)
            return
        }

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScan() {
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    func connect(toDeviceWithID id: UUID) {
        bleQueue.async {
            guard let peripheral = self.discoveredPeripherals[id] else {
                self.errorContinuation.yield(.unknownDevice)
                return
            }
            self.connectPeripheral(peripheral)
        }
    }

    func connect(to peripheral: CBPeripheral) {
        bleQueue.async {
            self.connectPeripheral(peripheral)
        }
    }

    /// Must be called on `bleQueue`.
    private func connectPeripheral(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        connectionState = .connecting
        shouldReconnect = true
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        bleQueue.async {
            self.performDisconnect()
        }
    }

    /// Must be called on `bleQueue`.
    private func performDisconnect() {
        shouldReconnect = false
        reconnectTask?.cancel()
        reconnectTask = nil

        if let peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        cleanup()
        connectionState = .disconnected
    }

    func write(_ data: Data) {
        guard let peripheral, let writeCharacteristic else {
            errorContinuation.yield(.characteristicNotFound)
            return
        }

        let writeType: CBCharacteristicWriteType =
            writeCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse

        peripheral.writeValue(data, for: writeCharacteristic, type: writeType)
    }

    private func cleanup() {
        writeCharacteristic = nil
        readCharacteristic = nil
        peripheral = nil
    }

    private func attemptReconnect() {
        guard shouldReconnect,
              reconnectAttempt < PulseConstants.maxReconnectAttempts,
              let peripheral else {
            if reconnectAttempt >= PulseConstants.maxReconnectAttempts {
                connectionState = .disconnected
                errorContinuation.yield(.disconnected)
            }
            return
        }

        reconnectAttempt += 1
        connectionState = .reconnecting(attempt: reconnectAttempt)

        let delay = PulseConstants.baseReconnectDelay * UInt64(1 << (reconnectAttempt - 1))
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            centralManager.connect(peripheral, options: nil)
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            reconnectAttempt = 0
            errorContinuation.yield(nil)
            if connectionState != .connected,
               let uuidString = UserDefaults.standard.string(forKey: PulseConstants.lastPeripheralUUIDKey),
               let uuid = UUID(uuidString: uuidString),
               let cached = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
                connect(to: cached)
            }
        case .poweredOff:
            errorContinuation.yield(.poweredOff)
            connectionState = .disconnected
        case .unauthorized:
            errorContinuation.yield(.unauthorized)
            connectionState = .disconnected
        case .unsupported:
            errorContinuation.yield(.unsupported)
            connectionState = .disconnected
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"

        let hasServiceUUID = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .contains(PulseConstants.serviceUUID) ?? false

        let isPulse = hasServiceUUID || name.hasPrefix(PulseConstants.deviceName)

        discoveredPeripherals[peripheral.identifier] = peripheral

        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            hasPulseService: isPulse
        )

        deviceContinuation.yield(device)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        reconnectAttempt = 0
        connectionState = .discoveringServices
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: PulseConstants.lastPeripheralUUIDKey)
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let reason = error?.localizedDescription ?? "Unknown reason"
        errorContinuation.yield(.connectionFailed(reason))
        attemptReconnect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        writeCharacteristic = nil
        readCharacteristic = nil

        if shouldReconnect {
            attemptReconnect()
        } else {
            connectionState = .disconnected
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == PulseConstants.serviceUUID }) else {
            errorContinuation.yield(.serviceNotFound)
            centralManager.cancelPeripheralConnection(peripheral)
            cleanup()
            connectionState = .disconnected
            return
        }

        peripheral.discoverCharacteristics(
            [PulseConstants.writeCharacteristicUUID, PulseConstants.readCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            errorContinuation.yield(.characteristicNotFound)
            performDisconnect()
            return
        }

        for characteristic in characteristics {
            if characteristic.uuid == PulseConstants.writeCharacteristicUUID {
                writeCharacteristic = characteristic
            }

            if characteristic.uuid == PulseConstants.readCharacteristicUUID {
                readCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }

        if writeCharacteristic != nil {
            connectionState = .connected
        } else {
            errorContinuation.yield(.characteristicNotFound)
            performDisconnect()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        dataContinuation.yield(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            errorContinuation.yield(.writeFailed(error.localizedDescription))
        }
    }
}
