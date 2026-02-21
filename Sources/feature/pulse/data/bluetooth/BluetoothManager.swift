import CoreBluetooth
import FeaturePulseDomain
import Foundation

protocol BluetoothManagerDelegate: AnyObject {
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: ConnectionState)
    func bluetoothManager(_ manager: BluetoothManager, didReceiveData data: Data)
    func bluetoothManager(_ manager: BluetoothManager, didEncounterError error: BluetoothError)
    func bluetoothManager(
        _ manager: BluetoothManager,
        didDiscoverDevice device: DiscoveredDevice,
        peripheral: CBPeripheral
    )
}

final class BluetoothManager: NSObject {
    weak var delegate: BluetoothManagerDelegate?

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var readCharacteristic: CBCharacteristic?
    private let bleQueue = DispatchQueue(label: "pulse5ctl.ble", qos: .userInitiated)

    private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            delegate?.bluetoothManager(self, didUpdateState: connectionState)
        }
    }

    private var reconnectAttempt = 0
    private var shouldReconnect = false
    private var reconnectTask: Task<Void, Never>?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            return
        }

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

    func connect(to peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        connectionState = .connecting
        shouldReconnect = true
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
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
            delegate?.bluetoothManager(self, didEncounterError: .characteristicNotFound)
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
                delegate?.bluetoothManager(self, didEncounterError: .disconnected)
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
            if connectionState != .connected,
               let uuidString = UserDefaults.standard.string(forKey: PulseConstants.lastPeripheralUUIDKey),
               let uuid = UUID(uuidString: uuidString),
               let cached = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
                connect(to: cached)
            }
        case .poweredOff:
            delegate?.bluetoothManager(self, didEncounterError: .poweredOff)
            connectionState = .disconnected
        case .unauthorized:
            delegate?.bluetoothManager(self, didEncounterError: .unauthorized)
            connectionState = .disconnected
        case .unsupported:
            delegate?.bluetoothManager(self, didEncounterError: .unsupported)
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

        let isPulse = hasServiceUUID || name.hasPrefix(PulseConstants.deviceNamePrefix)

        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            hasPulseService: isPulse
        )

        delegate?.bluetoothManager(self, didDiscoverDevice: device, peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        reconnectAttempt = 0
        connectionState = .discoveringServices
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: PulseConstants.lastPeripheralUUIDKey)
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let reason = error?.localizedDescription ?? "Unknown reason"
        delegate?.bluetoothManager(self, didEncounterError: .connectionFailed(reason))
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
            delegate?.bluetoothManager(self, didEncounterError: .serviceNotFound)
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
            delegate?.bluetoothManager(self, didEncounterError: .characteristicNotFound)
            disconnect()
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
            delegate?.bluetoothManager(self, didEncounterError: .characteristicNotFound)
            disconnect()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        delegate?.bluetoothManager(self, didReceiveData: data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            delegate?.bluetoothManager(self, didEncounterError: .writeFailed(error.localizedDescription))
        }
    }
}
