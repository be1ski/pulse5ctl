import FeaturePulseDomain
import Foundation
import os

private let log = Logger(subsystem: "com.pulse5ctl", category: "repository")

public final class PulseSpeakerRepositoryImpl: PulseSpeakerRepository, @unchecked Sendable {
    public var events: AsyncStream<PulseRepositoryEvent> { eventStream }

    private let bluetoothManager = BluetoothManager()
    private var discoveredDevicesByID: [UUID: DiscoveredDevice] = [:]
    private var stateReadTask: Task<Void, Never>?

    private let eventStream: AsyncStream<PulseRepositoryEvent>
    private let eventContinuation: AsyncStream<PulseRepositoryEvent>.Continuation

    public init() {
        var continuation: AsyncStream<PulseRepositoryEvent>.Continuation?
        eventStream = AsyncStream { inner in
            continuation = inner
        }
        eventContinuation = continuation!

        subscribeToStreams()
    }

    public func startScan() {
        log.notice("startScan()")
        discoveredDevicesByID.removeAll()
        emit(.connectionChanged(.scanning))
        emit(.discoveredDevices([]))
        bluetoothManager.startScan()
    }

    public func stopScan() {
        bluetoothManager.stopScan()
    }

    public func connect(to deviceID: UUID) {
        log.notice("connect(to: \(deviceID, privacy: .public))")
        bluetoothManager.connect(toDeviceWithID: deviceID)
    }

    public func disconnect() {
        log.notice("disconnect()")
        stateReadTask?.cancel()
        stateReadTask = nil
        bluetoothManager.disconnect()
    }

    public func setTheme(_ theme: LEDTheme) {
        bluetoothManager.write(PulseProtocol.switchPackage(theme.rawValue))
        emit(.theme(theme))
    }

    public func setLight(enabled: Bool) {
        bluetoothManager.write(PulseProtocol.setLightStatus(enabled))
    }

    public func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool) {
        bluetoothManager.write(
            PulseProtocol.setLedBrightness(
                level: level,
                bodyLight: bodyLight,
                projection: projection
            )
        )
    }

    public func setSpeed(_ speed: UInt8) {
        bluetoothManager.write(PulseProtocol.setMovementSpeed(speed))
    }

    public func setLedPackage(
        theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern],
        colorEffect: ColorEffect, color: LEDColor
    ) {
        bluetoothManager.write(
            PulseProtocol.setLedPackage(
                packageID: theme.rawValue,
                activePatterns: activePatterns.map(\.rawValue),
                allPatterns: allPatterns.map(\.rawValue),
                colorEffect: colorEffect.rawValue,
                color: color
            )
        )
        emit(.theme(theme))
    }

    public func requestCurrentState() {
        stateReadTask?.cancel()
        stateReadTask = Task { [weak self] in
            self?.bluetoothManager.write(PulseProtocol.requestSpeakerInfo())

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.bluetoothManager.write(PulseProtocol.requestLightStatus())

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.bluetoothManager.write(PulseProtocol.requestLedBrightness())

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.bluetoothManager.write(PulseProtocol.requestMovementSpeed())

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
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

    private func subscribeToStreams() {
        subscribeToStateUpdates()
        subscribeToDiscoveredDevices()
        subscribeToReceivedData()
        subscribeToErrors()
    }

    private func subscribeToStateUpdates() {
        Task { [weak self] in
            guard let self else { return }
            for await state in bluetoothManager.stateUpdates {
                let desc = String(describing: state)
                log.notice("state event: \(desc, privacy: .public)")
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    emit(.connectionChanged(state))
                    if state.isConnected {
                        requestCurrentState()
                    }
                }
            }
        }
    }

    private func subscribeToDiscoveredDevices() {
        Task { [weak self] in
            guard let self else { return }
            for await device in bluetoothManager.discoveredDevices {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    discoveredDevicesByID[device.id] = device
                    updateDiscoveredDevices()
                }
            }
        }
    }

    private func subscribeToReceivedData() {
        Task { [weak self] in
            guard let self else { return }
            for await data in bluetoothManager.receivedData {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    handleReceivedData(data)
                }
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
        if let lightOn = PulseProtocol.parseLightStatus(data) {
            emit(.lightStatus(lightOn))
        }

        if let brightness = PulseProtocol.parseBrightnessState(data) {
            emit(
                .brightness(
                    level: brightness.level,
                    bodyLight: brightness.bodyLightOn,
                    projection: brightness.projectionOn
                )
            )
        }

        if let speed = PulseProtocol.parseMovementSpeed(data) {
            emit(.speed(speed))
        }

        if let theme = PulseProtocol.parseSelectedTheme(data) {
            emit(.theme(theme))
        }
    }

    private func subscribeToErrors() {
        Task { [weak self] in
            guard let self else { return }
            for await error in bluetoothManager.errors {
                let desc = error?.localizedDescription ?? "cleared"
                log.notice("error event: \(desc, privacy: .public)")
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if let error {
                        emit(.error(error.localizedDescription))
                    } else {
                        emit(.errorCleared)
                    }
                }
            }
        }
    }
}
