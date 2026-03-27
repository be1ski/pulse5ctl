@preconcurrency import CoreBluetooth
import FeaturePulseDomain
import Foundation
import os

private let log = Logger(subsystem: "com.pulse5ctl", category: "bluetooth")

final class BluetoothManager: NSObject, @unchecked Sendable {
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
            let old = String(describing: oldValue)
            let new = String(describing: self.connectionState)
            log.notice("\(old, privacy: .public) -> \(new, privacy: .public)")
            stateContinuation.yield(connectionState)
        }
    }

    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var reconnectionPolicy = ReconnectionPolicy()
    private var reconnectTask: Task<Void, Never>?
    private var connectionTimeoutTask: Task<Void, Never>?

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
            let state = self.centralManager.state.rawValue
            log.error("startScan() but central state is \(state, privacy: .public) — not poweredOn")
            return
        }

        log.notice("startScan() called, central state: poweredOn")

        discoveredPeripherals.removeAll()
        connectionState = .scanning

        let connected = centralManager.retrieveConnectedPeripherals(withServices: [PulseConstants.serviceUUID])
        if let firstConnected = connected.first {
            log.notice("startScan: found connected \(firstConnected.identifier, privacy: .public)")
            connect(to: firstConnected)
            return
        }

        if let uuidString = UserDefaults.standard.string(forKey: PulseConstants.lastPeripheralUUIDKey),
           let uuid = UUID(uuidString: uuidString),
           let cached = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
            log.notice("startScan: found cached \(uuid, privacy: .public), connecting")
            connect(to: cached)
            return
        }

        log.notice("startScan: no connected/cached peripheral, starting full BLE scan")
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
        log.notice("connectPeripheral(\(peripheral.identifier, privacy: .public))")
        self.peripheral = peripheral
        peripheral.delegate = self
        connectionState = .connecting
        reconnectionPolicy.connectionStarted()
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
        startConnectionTimeout()
    }

    private func startConnectionTimeout() {
        log.info("startConnectionTimeout()")
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: PulseConstants.connectionTimeout)
            guard !Task.isCancelled, let self else { return }
            self.bleQueue.async {
                let decision = self.reconnectionPolicy.timeoutAction(
                    hasPeripheral: self.peripheral != nil,
                    state: self.connectionState
                )
                let state = String(describing: self.connectionState)
                let action = String(describing: decision)
                log.notice("Connection timeout: \(state, privacy: .public) → \(action, privacy: .public)")
                switch decision {
                case .cancelConnection:
                    if let peripheral = self.peripheral {
                        self.centralManager.cancelPeripheralConnection(peripheral)
                    }
                case .reconnectDirectly:
                    self.attemptReconnect()
                case .ignore:
                    break
                }
            }
        }
    }

    private func cancelConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
    }

    func disconnect() {
        log.notice("disconnect() called")
        bleQueue.async {
            self.performDisconnect()
        }
    }

    /// Must be called on `bleQueue`.
    private func performDisconnect() {
        let id = self.peripheral?.identifier.uuidString ?? "nil"
        log.notice("performDisconnect(), peripheral: \(id, privacy: .public)")
        reconnectionPolicy.userDisconnected()
        cancelConnectionTimeout()
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
        let decision = reconnectionPolicy.nextAttempt(hasPeripheral: peripheral != nil)
        switch decision {
        case let .reconnect(delay, attempt):
            log.notice("attemptReconnect #\(attempt, privacy: .public)")
            connectionState = .reconnecting(attempt: attempt)
            reconnectTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled, let self else { return }
                guard let peripheral = self.peripheral else { return }
                self.centralManager.connect(peripheral, options: nil)
                self.startConnectionTimeout()
            }
        case .giveUp:
            log.notice("attemptReconnect: giving up after max attempts")
            connectionState = .disconnected
            errorContinuation.yield(.disconnected)
        case .skip:
            let peripheralID = peripheral?.identifier.uuidString ?? "nil"
            log.notice("attemptReconnect: skip (peer: \(peripheralID, privacy: .public))")
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let cachedUUID = UserDefaults.standard.string(forKey: PulseConstants.lastPeripheralUUIDKey)
        let peripheralID = self.peripheral?.identifier.uuidString ?? "nil"
        let cachedDisplay = cachedUUID ?? "nil"
        let msg = "didUpdateState: \(central.state.rawValue) peer: \(peripheralID) cached: \(cachedDisplay)"
        log.notice("\(msg, privacy: .public)")

        switch central.state {
        case .poweredOn:
            cancelConnectionTimeout()
            reconnectTask?.cancel()
            reconnectTask = nil
            reconnectionPolicy.reset()
            if let peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            cleanup()
            errorContinuation.yield(nil)
            if let uuidString = cachedUUID,
               let uuid = UUID(uuidString: uuidString),
               let cached = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
                log.notice("poweredOn: auto-connecting to \(uuid, privacy: .public)")
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

        let msg = "didDiscover: \(name) \(peripheral.identifier) pulse: \(isPulse) RSSI: \(RSSI)"
        log.info("\(msg, privacy: .public)")

        guard isPulse else { return }

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
        log.notice("didConnect: \(peripheral.identifier, privacy: .public)")
        cancelConnectionTimeout()
        reconnectionPolicy.connectionSucceeded()
        connectionState = .discoveringServices
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: PulseConstants.lastPeripheralUUIDKey)
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let reason = error?.localizedDescription ?? "Unknown reason"
        let msg = "didFailToConnect: \(peripheral.identifier) reason: \(reason)"
        log.error("\(msg, privacy: .public)")
        cancelConnectionTimeout()
        errorContinuation.yield(.connectionFailed(reason))
        attemptReconnect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let errorDesc = error?.localizedDescription ?? "nil"
        let retry = reconnectionPolicy.shouldReconnect
        let msg = "didDisconnect: \(peripheral.identifier) retry: \(retry) err: \(errorDesc)"
        log.notice("\(msg, privacy: .public)")
        writeCharacteristic = nil
        readCharacteristic = nil

        if reconnectionPolicy.shouldReconnect {
            attemptReconnect()
        } else {
            connectionState = .disconnected
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == PulseConstants.serviceUUID }) else {
            let uuids = peripheral.services?.map(\.uuid) ?? []
            log.error("didDiscoverServices: service not found: \(uuids, privacy: .public)")
            errorContinuation.yield(.serviceNotFound)
            centralManager.cancelPeripheralConnection(peripheral)
            cleanup()
            connectionState = .disconnected
            return
        }

        log.info("didDiscoverServices: found Pulse service")
        peripheral.discoverCharacteristics(
            [PulseConstants.writeCharacteristicUUID, PulseConstants.readCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            log.error("didDiscoverCharacteristics: no characteristics found")
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
            log.notice("didDiscoverCharacteristics: ready, write+read characteristics found")
            connectionState = .connected
        } else {
            log.error("didDiscoverCharacteristics: write characteristic not found")
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
