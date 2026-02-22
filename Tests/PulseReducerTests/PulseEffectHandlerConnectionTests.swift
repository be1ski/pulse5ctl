import FeaturePulseDomain
@testable import FeaturePulsePresentation
import Foundation
import XCTest

private func collectActions(_ stream: AsyncStream<PulseAction>) async -> [PulseAction] {
    var result: [PulseAction] = []
    for await action in stream {
        result.append(action)
    }
    return result
}

private final class MockPulseSpeakerRepository: PulseSpeakerRepository, @unchecked Sendable {
    var startScanCalled = false
    var disconnectCalled = false
    var connectCalledWith: UUID?
    var requestCurrentStateCalled = false

    let events: AsyncStream<PulseRepositoryEvent>
    private let continuation: AsyncStream<PulseRepositoryEvent>.Continuation

    init() {
        var cont: AsyncStream<PulseRepositoryEvent>.Continuation!
        events = AsyncStream { cont = $0 }
        continuation = cont
    }

    func pushEvent(_ event: PulseRepositoryEvent) {
        continuation.yield(event)
    }

    func finishEvents() {
        continuation.finish()
    }

    func startScan() { startScanCalled = true }
    func stopScan() {}
    func connect(to deviceID: UUID) { connectCalledWith = deviceID }
    func disconnect() { disconnectCalled = true }
    func setTheme(_ theme: LEDTheme) {}
    func setLight(enabled: Bool) {}
    func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool) {}
    func setSpeed(_ speed: UInt8) {}
    func setLedPackage(
        theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern],
        colorEffect: ColorEffect, color: LEDColor
    ) {}
    func requestCurrentState() { requestCurrentStateCalled = true }
}

final class PulseEffectHandlerConnectionTests: XCTestCase {

    // MARK: - Helpers

    private func makeHandler(mock: MockPulseSpeakerRepository) -> PulseEffectHandler {
        PulseEffectHandler(
            observePulseEvents: ObservePulseEventsUseCase(repository: mock),
            startPulseScan: StartPulseScanUseCase(repository: mock),
            connectPulseSpeaker: ConnectPulseSpeakerUseCase(repository: mock),
            disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase(repository: mock),
            setPulseTheme: SetPulseThemeUseCase(repository: mock),
            setPulseLightStatus: SetPulseLightStatusUseCase(repository: mock),
            setPulseBrightness: SetPulseBrightnessUseCase(repository: mock),
            setPulseSpeed: SetPulseSpeedUseCase(repository: mock),
            setPulseLedPackage: SetPulseLedPackageUseCase(repository: mock),
            requestPulseState: RequestPulseStateUseCase(repository: mock),
            observeNowPlaying: { AsyncStream { $0.finish() } },
            observeLightSchedule: { _ in AsyncStream { $0.finish() } },
            saveAutoThemeSettings: { _ in },
            saveLedCustomization: { _ in },
            saveLightScheduleSettings: { _ in },
            saveLanguage: { _ in }
        )
    }

    // MARK: - observeRepository

    func test_observeRepository_yieldsRepositoryEvents() async {
        let mock = MockPulseSpeakerRepository()
        let handler = makeHandler(mock: mock)

        let stream = handler.handle(.observeRepository)

        let event1 = PulseRepositoryEvent.connectionChanged(.connected)
        let event2 = PulseRepositoryEvent.error("boom")

        let task = Task {
            await collectActions(stream)
        }

        await Task.yield()
        mock.pushEvent(event1)
        mock.pushEvent(event2)
        mock.finishEvents()

        let actions = await task.value
        XCTAssertEqual(actions, [
            .system(.repositoryEvent(event1)),
            .system(.repositoryEvent(event2))
        ])
    }

    // MARK: - startScan

    func test_startScan_callsRepository() async {
        let mock = MockPulseSpeakerRepository()
        let handler = makeHandler(mock: mock)

        let actions = await collectActions(handler.handle(.startScan))

        XCTAssertTrue(mock.startScanCalled)
        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - disconnect

    func test_disconnect_callsRepository() async {
        let mock = MockPulseSpeakerRepository()
        let handler = makeHandler(mock: mock)

        let actions = await collectActions(handler.handle(.disconnect))

        XCTAssertTrue(mock.disconnectCalled)
        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - connect

    func test_connect_callsRepositoryWithDeviceID() async {
        let mock = MockPulseSpeakerRepository()
        let handler = makeHandler(mock: mock)
        let deviceID = UUID()

        let actions = await collectActions(handler.handle(.connect(deviceID)))

        XCTAssertEqual(mock.connectCalledWith, deviceID)
        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - requestCurrentState

    func test_requestCurrentState_callsRepository() async {
        let mock = MockPulseSpeakerRepository()
        let handler = makeHandler(mock: mock)

        let actions = await collectActions(handler.handle(.requestCurrentState))

        XCTAssertTrue(mock.requestCurrentStateCalled)
        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - observeNowPlaying

    func test_observeNowPlaying_yieldsNowPlayingActions() async {
        let mock = MockPulseSpeakerRepository()
        let handler = PulseEffectHandler(
            observePulseEvents: ObservePulseEventsUseCase(repository: mock),
            startPulseScan: StartPulseScanUseCase(repository: mock),
            connectPulseSpeaker: ConnectPulseSpeakerUseCase(repository: mock),
            disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase(repository: mock),
            setPulseTheme: SetPulseThemeUseCase(repository: mock),
            setPulseLightStatus: SetPulseLightStatusUseCase(repository: mock),
            setPulseBrightness: SetPulseBrightnessUseCase(repository: mock),
            setPulseSpeed: SetPulseSpeedUseCase(repository: mock),
            setPulseLedPackage: SetPulseLedPackageUseCase(repository: mock),
            requestPulseState: RequestPulseStateUseCase(repository: mock),
            observeNowPlaying: {
                AsyncStream { continuation in
                    continuation.yield(true)
                    continuation.yield(false)
                    continuation.finish()
                }
            },
            observeLightSchedule: { _ in AsyncStream { $0.finish() } },
            saveAutoThemeSettings: { _ in },
            saveLedCustomization: { _ in },
            saveLightScheduleSettings: { _ in },
            saveLanguage: { _ in }
        )

        let actions = await collectActions(handler.handle(.observeNowPlaying))

        XCTAssertEqual(actions, [
            .system(.nowPlayingChanged(true)),
            .system(.nowPlayingChanged(false))
        ])
    }

    // MARK: - observeLightSchedule

    func test_observeLightSchedule_yieldsLightScheduleActions() async {
        let mock = MockPulseSpeakerRepository()
        let handler = PulseEffectHandler(
            observePulseEvents: ObservePulseEventsUseCase(repository: mock),
            startPulseScan: StartPulseScanUseCase(repository: mock),
            connectPulseSpeaker: ConnectPulseSpeakerUseCase(repository: mock),
            disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase(repository: mock),
            setPulseTheme: SetPulseThemeUseCase(repository: mock),
            setPulseLightStatus: SetPulseLightStatusUseCase(repository: mock),
            setPulseBrightness: SetPulseBrightnessUseCase(repository: mock),
            setPulseSpeed: SetPulseSpeedUseCase(repository: mock),
            setPulseLedPackage: SetPulseLedPackageUseCase(repository: mock),
            requestPulseState: RequestPulseStateUseCase(repository: mock),
            observeNowPlaying: { AsyncStream { $0.finish() } },
            observeLightSchedule: { _ in
                AsyncStream { continuation in
                    continuation.yield(true)
                    continuation.yield(false)
                    continuation.finish()
                }
            },
            saveAutoThemeSettings: { _ in },
            saveLedCustomization: { _ in },
            saveLightScheduleSettings: { _ in },
            saveLanguage: { _ in }
        )

        let settings = LightScheduleSettings(enabled: true)
        let actions = await collectActions(handler.handle(.observeLightSchedule(settings)))

        XCTAssertEqual(actions, [
            .system(.lightScheduleChanged(true)),
            .system(.lightScheduleChanged(false))
        ])
    }

    // MARK: - stopLightSchedule

    func test_stopLightSchedule_returnsEmptyStream() async {
        let mock = MockPulseSpeakerRepository()
        let handler = makeHandler(mock: mock)

        let actions = await collectActions(handler.handle(.stopLightSchedule))

        XCTAssertTrue(actions.isEmpty)
    }
}
