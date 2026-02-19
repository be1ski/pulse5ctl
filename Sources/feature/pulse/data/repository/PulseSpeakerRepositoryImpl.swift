import CoreBluetooth
import FeaturePulseDomain
import Foundation

public final class PulseSpeakerRepositoryImpl: NSObject, PulseSpeakerRepository {
    public private(set) var snapshot = PulseSpeakerSnapshot()
    public var events: AsyncStream<PulseRepositoryEvent> { eventStream }

    private let bluetoothManager = BluetoothManager()
    private var peripheralsByID: [UUID: CBPeripheral] = [:]
    private var discoveredDevicesByID: [UUID: DiscoveredDevice] = [:]

    private let eventStream: AsyncStream<PulseRepositoryEvent>
    private let eventContinuation: AsyncStream<PulseRepositoryEvent>.Continuation

    public override init() {
        var continuation: AsyncStream<PulseRepositoryEvent>.Continuation?
        eventStream = AsyncStream { inner in
            continuation = inner
        }
        eventContinuation = continuation!

        super.init()
        bluetoothManager.delegate = self
    }

    public func startScan() {
        discoveredDevicesByID.removeAll()
        peripheralsByID.removeAll()
        snapshot.connectionState = .scanning
        emit(.connectionChanged(.scanning))
        emit(.discoveredDevices([]))
        bluetoothManager.startScan()
    }

    public func stopScan() {
        bluetoothManager.stopScan()
    }

    public func connect(to deviceID: UUID) {
        guard let peripheral = peripheralsByID[deviceID] else {
            emit(.error(BluetoothError.unknownDevice.localizedDescription))
            return
        }

        snapshot.connectionState = .connecting
        emit(.connectionChanged(.connecting))
        bluetoothManager.connect(to: peripheral)
    }

    public func disconnect() {
        bluetoothManager.disconnect()
    }

    public func setTheme(_ theme: LEDTheme) {
        snapshot.selectedTheme = theme
        bluetoothManager.write(PulseProtocol.switchPackage(theme.rawValue))
        emit(.theme(theme))
    }

    public func setLight(enabled: Bool) {
        snapshot.lightOn = enabled
        bluetoothManager.write(PulseProtocol.setLightStatus(enabled))
    }

    public func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool) {
        snapshot.brightness = level
        snapshot.bodyLightOn = bodyLight
        snapshot.projectionOn = projection

        bluetoothManager.write(
            PulseProtocol.setLedBrightness(
                level: level,
                bodyLight: bodyLight,
                projection: projection
            )
        )
    }

    public func setSpeed(_ speed: UInt8) {
        snapshot.speed = speed
        bluetoothManager.write(PulseProtocol.setMovementSpeed(speed))
    }

    public func setLedPackage(theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern], colorEffect: ColorEffect, color: LEDColor) {
        snapshot.selectedTheme = theme
        bluetoothManager.write(
            PulseProtocol.setLedPackage(
                packageID: theme.rawValue,
                activePatterns: activePatterns.map(\.rawValue),
                allPatterns: allPatterns.map(\.rawValue),
                colorEffect: colorEffect.rawValue,
                red: color.red,
                green: color.green,
                blue: color.blue
            )
        )
        emit(.theme(theme))
    }

    public func requestCurrentState() {
        bluetoothManager.write(PulseProtocol.requestSpeakerInfo())

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.bluetoothManager.write(PulseProtocol.requestLightStatus())
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.bluetoothManager.write(PulseProtocol.requestLedBrightness())
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.bluetoothManager.write(PulseProtocol.requestMovementSpeed())
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.bluetoothManager.write(PulseProtocol.requestLedPackageInfo())
        }
    }

    private func emit(_ event: PulseRepositoryEvent) {
        eventContinuation.yield(event)
    }

    private func updateDiscoveredDevices() {
        let sorted = discoveredDevicesByID.values.sorted { $0.rssi > $1.rssi }
        emit(.discoveredDevices(sorted))
    }
}

extension PulseSpeakerRepositoryImpl: BluetoothManagerDelegate {
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            snapshot.connectionState = state
            emit(.connectionChanged(state))

            if state.isConnected {
                requestCurrentState()
            }
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didReceiveData data: Data) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if let lightOn = PulseProtocol.parseLightStatus(data) {
                snapshot.lightOn = lightOn
                emit(.lightStatus(lightOn))
            }

            if let brightness = PulseProtocol.parseBrightnessState(data) {
                snapshot.brightness = brightness.level
                snapshot.bodyLightOn = brightness.bodyLightOn
                snapshot.projectionOn = brightness.projectionOn
                emit(
                    .brightness(
                        level: brightness.level,
                        bodyLight: brightness.bodyLightOn,
                        projection: brightness.projectionOn
                    )
                )
            }

            if let speed = PulseProtocol.parseMovementSpeed(data) {
                snapshot.speed = speed
                emit(.speed(speed))
            }

            if let theme = PulseProtocol.parseSelectedTheme(data) {
                snapshot.selectedTheme = theme
                emit(.theme(theme))
            }
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didEncounterError error: BluetoothError) {
        DispatchQueue.main.async { [weak self] in
            self?.emit(.error(error.localizedDescription))
        }
    }

    func bluetoothManager(
        _ manager: BluetoothManager,
        didDiscoverDevice device: DiscoveredDevice,
        peripheral: CBPeripheral
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            peripheralsByID[device.id] = peripheral
            discoveredDevicesByID[device.id] = device
            updateDiscoveredDevices()
        }
    }
}
