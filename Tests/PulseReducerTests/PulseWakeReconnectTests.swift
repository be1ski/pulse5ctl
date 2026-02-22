@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import XCTest

private final class SpyPulseSpeakerRepository: PulseSpeakerRepository, @unchecked Sendable {
    private var _callLog: [Call] = []
    private let lock = NSLock()

    var callLog: [Call] {
        lock.lock()
        defer { lock.unlock() }
        return _callLog
    }

    let events: AsyncStream<PulseRepositoryEvent>
    private let continuation: AsyncStream<PulseRepositoryEvent>.Continuation

    enum Call: Equatable {
        case startScan
        case disconnect
        case connect(UUID)
        case requestCurrentState
    }

    init() {
        var cont: AsyncStream<PulseRepositoryEvent>.Continuation!
        events = AsyncStream { cont = $0 }
        continuation = cont
    }

    func clearLog() {
        lock.lock()
        _callLog.removeAll()
        lock.unlock()
    }

    private func log(_ call: Call) {
        lock.lock()
        _callLog.append(call)
        lock.unlock()
    }

    func pushEvent(_ event: PulseRepositoryEvent) {
        continuation.yield(event)
    }

    func finishEvents() {
        continuation.finish()
    }

    func startScan() { log(.startScan) }
    func stopScan() {}
    func connect(to deviceID: UUID) { log(.connect(deviceID)) }
    func disconnect() { log(.disconnect) }
    func setTheme(_ theme: LEDTheme) {}
    func setLight(enabled: Bool) {}
    func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool) {}
    func setSpeed(_ speed: UInt8) {}
    func setLedPackage(
        theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern],
        colorEffect: ColorEffect, color: LEDColor
    ) {}
    func requestCurrentState() { log(.requestCurrentState) }
}

final class PulseWakeReconnectTests: XCTestCase {

    // MARK: - Helpers

    @MainActor
    private func makeFeatureAndSpy() -> (PulseFeature, SpyPulseSpeakerRepository) {
        let spy = SpyPulseSpeakerRepository()
        let handler = PulseEffectHandler(
            observePulseEvents: ObservePulseEventsUseCase(repository: spy),
            startPulseScan: StartPulseScanUseCase(repository: spy),
            connectPulseSpeaker: ConnectPulseSpeakerUseCase(repository: spy),
            disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase(repository: spy),
            setPulseTheme: SetPulseThemeUseCase(repository: spy),
            setPulseLightStatus: SetPulseLightStatusUseCase(repository: spy),
            setPulseBrightness: SetPulseBrightnessUseCase(repository: spy),
            setPulseSpeed: SetPulseSpeedUseCase(repository: spy),
            setPulseLedPackage: SetPulseLedPackageUseCase(repository: spy),
            requestPulseState: RequestPulseStateUseCase(repository: spy),
            observeNowPlaying: { AsyncStream { $0.finish() } },
            observeLightSchedule: { _ in AsyncStream { $0.finish() } },
            saveAutoThemeSettings: { _ in },
            saveLedCustomization: { _ in },
            saveLightScheduleSettings: { _ in },
            saveLanguage: { _ in }
        )
        let feature = PulseFeature(
            initialState: PulseState(),
            reducer: pulseReducer,
            effectHandler: handler.handle
        )
        return (feature, spy)
    }

    // MARK: - Wake reconnection flow

    @MainActor
    func test_systemDidWake_whenObserving_callsDisconnectAndStartScan() async throws {
        let (feature, spy) = makeFeatureAndSpy()

        // Bootstrap: mark as observing
        feature.send(.lifecycle(.started))
        try await Task.sleep(for: .milliseconds(50))
        spy.clearLog()

        // Simulate wake
        feature.send(.lifecycle(.systemDidWake))
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(spy.callLog.contains(.disconnect))
        XCTAssertTrue(spy.callLog.contains(.startScan))
    }

    @MainActor
    func test_systemDidWake_whenObserving_disconnectBeforeStartScan() async throws {
        let (feature, spy) = makeFeatureAndSpy()

        feature.send(.lifecycle(.started))
        try await Task.sleep(for: .milliseconds(50))
        spy.clearLog()

        feature.send(.lifecycle(.systemDidWake))
        try await Task.sleep(for: .milliseconds(50))

        guard let disconnectIndex = spy.callLog.firstIndex(of: .disconnect),
              let scanIndex = spy.callLog.firstIndex(of: .startScan) else {
            XCTFail("Expected both disconnect and startScan calls")
            return
        }

        XCTAssertLessThan(disconnectIndex, scanIndex, "disconnect must be called before startScan")
    }

    @MainActor
    func test_systemDidWake_whenNotObserving_doesNotCallRepository() async throws {
        let (feature, spy) = makeFeatureAndSpy()

        feature.send(.lifecycle(.systemDidWake))
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertFalse(spy.callLog.contains(.disconnect))
        XCTAssertFalse(spy.callLog.contains(.startScan))
    }

    @MainActor
    func test_systemDidWake_doesNotMutateState() async throws {
        let (feature, _) = makeFeatureAndSpy()

        feature.send(.lifecycle(.started))
        try await Task.sleep(for: .milliseconds(50))
        let stateBefore = feature.state

        feature.send(.lifecycle(.systemDidWake))

        XCTAssertEqual(feature.state.isObservingRepository, stateBefore.isObservingRepository)
        XCTAssertEqual(feature.state.connectionState, stateBefore.connectionState)
    }

    @MainActor
    func test_systemDidWake_afterReconnect_stateBecomesConnected() async throws {
        let (feature, spy) = makeFeatureAndSpy()

        feature.send(.lifecycle(.started))
        try await Task.sleep(for: .milliseconds(50))

        // Simulate connected state
        spy.pushEvent(.connectionChanged(.connected))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(feature.state.connectionState, .connected)

        // Simulate wake
        feature.send(.lifecycle(.systemDidWake))
        try await Task.sleep(for: .milliseconds(50))

        // Simulate BLE stack: disconnect event followed by reconnect
        spy.pushEvent(.connectionChanged(.disconnected))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(feature.state.connectionState, .disconnected)

        spy.pushEvent(.connectionChanged(.connecting))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(feature.state.connectionState, .connecting)

        spy.pushEvent(.connectionChanged(.connected))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(feature.state.connectionState, .connected)
    }

    @MainActor
    func test_multipleWakes_eachTriggersDisconnectAndScan() async throws {
        let (feature, spy) = makeFeatureAndSpy()

        feature.send(.lifecycle(.started))
        try await Task.sleep(for: .milliseconds(50))
        spy.clearLog()

        feature.send(.lifecycle(.systemDidWake))
        try await Task.sleep(for: .milliseconds(50))

        feature.send(.lifecycle(.systemDidWake))
        try await Task.sleep(for: .milliseconds(50))

        let disconnectCount = spy.callLog.filter { $0 == .disconnect }.count
        let scanCount = spy.callLog.filter { $0 == .startScan }.count

        XCTAssertEqual(disconnectCount, 2)
        XCTAssertEqual(scanCount, 2)
    }
}
