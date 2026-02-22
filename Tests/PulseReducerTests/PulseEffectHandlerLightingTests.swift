import FeaturePulseDomain
@testable import FeaturePulsePresentation
import Foundation
import XCTest

// MARK: - Mock

private final class MockLightingRepository: PulseSpeakerRepository, @unchecked Sendable {

    struct BrightnessCall {
        let level: UInt8
        let bodyLight: Bool
        let projection: Bool
    }

    let events: AsyncStream<PulseRepositoryEvent> = { AsyncStream { $0.finish() } }()

    var setThemeCalledWith: LEDTheme?
    var setLightCalledWith: Bool?
    var setBrightnessCalledWith: BrightnessCall?
    var setSpeedCalledWith: UInt8?
    var setLedPackageCalled = false

    func startScan() {}
    func stopScan() {}
    func connect(to deviceID: UUID) {}
    func disconnect() {}
    func requestCurrentState() {}

    func setTheme(_ theme: LEDTheme) {
        setThemeCalledWith = theme
    }

    func setLight(enabled: Bool) {
        setLightCalledWith = enabled
    }

    func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool) {
        setBrightnessCalledWith = BrightnessCall(level: level, bodyLight: bodyLight, projection: projection)
    }

    func setSpeed(_ speed: UInt8) {
        setSpeedCalledWith = speed
    }

    func setLedPackage(
        theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern],
        colorEffect: ColorEffect, color: LEDColor
    ) {
        setLedPackageCalled = true
    }
}

// MARK: - Tests

final class PulseEffectHandlerLightingTests: XCTestCase {

    // MARK: - Helpers

    private func makeHandler(
        mock: MockLightingRepository,
        savedAutoTheme: (@Sendable (AutoThemeSettings) -> Void)? = nil,
        savedLedCustomization: (@Sendable (LEDCustomization) -> Void)? = nil,
        savedLightSchedule: (@Sendable (LightScheduleSettings) -> Void)? = nil,
        savedLanguage: (@Sendable (String?) -> Void)? = nil
    ) -> PulseEffectHandler {
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
            saveAutoThemeSettings: savedAutoTheme ?? { _ in },
            saveLedCustomization: savedLedCustomization ?? { _ in },
            saveLightScheduleSettings: savedLightSchedule ?? { _ in },
            saveLanguage: savedLanguage ?? { _ in }
        )
    }

    private func collectLightingActions(from stream: AsyncStream<PulseAction>) async -> [PulseAction] {
        var result: [PulseAction] = []
        for await action in stream {
            result.append(action)
        }
        return result
    }

    private func drainLighting(_ stream: AsyncStream<PulseAction>) async {
        for await _ in stream {}
    }

    // MARK: - setLight

    func test_setLight_enabled_callsRepository() async {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        await drainLighting(handler.handle(.setLight(true)))

        XCTAssertEqual(mock.setLightCalledWith, true)
    }

    func test_setLight_disabled_callsRepository() async {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        await drainLighting(handler.handle(.setLight(false)))

        XCTAssertEqual(mock.setLightCalledWith, false)
    }

    // MARK: - setTheme

    func test_setTheme_callsRepositoryWithTheme() async {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        await drainLighting(handler.handle(.setTheme(.party)))

        XCTAssertEqual(mock.setThemeCalledWith, .party)
    }

    func test_setTheme_returnsNoActions() async {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        let actions = await collectLightingActions(from: handler.handle(.setTheme(.nature)))

        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - setBrightness

    func test_setBrightness_afterDebounce_callsRepository() async throws {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        _ = handler.handle(.setBrightness(level: 50, bodyLight: true, projection: false))
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertEqual(mock.setBrightnessCalledWith?.level, 50)
        XCTAssertEqual(mock.setBrightnessCalledWith?.bodyLight, true)
        XCTAssertEqual(mock.setBrightnessCalledWith?.projection, false)
    }

    func test_setBrightness_cancelled_doesNotCallRepository() async throws {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        // First call — will be cancelled by the second
        _ = handler.handle(.setBrightness(level: 30, bodyLight: true, projection: true))
        // Second call — supersedes the first
        _ = handler.handle(.setBrightness(level: 60, bodyLight: false, projection: true))
        try await Task.sleep(for: .milliseconds(300))

        // Only the second call's values should appear
        XCTAssertEqual(mock.setBrightnessCalledWith?.level, 60)
        XCTAssertEqual(mock.setBrightnessCalledWith?.bodyLight, false)
    }

    // MARK: - setLedPackage

    func test_setLedPackage_afterDebounce_callsRepository() async throws {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        _ = handler.handle(.setLedPackage(
            theme: .nature,
            activePatterns: [.campfire],
            allPatterns: LEDTheme.nature.patterns,
            colorEffect: .colorLoop,
            color: LEDColor(red: 255, green: 255, blue: 255)
        ))
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertTrue(mock.setLedPackageCalled)
    }

    func test_setLedPackage_cancelledBySetTheme_doesNotCall() async throws {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        // Schedule a led package call — will be cancelled by setTheme
        _ = handler.handle(.setLedPackage(
            theme: .nature,
            activePatterns: [.campfire],
            allPatterns: LEDTheme.nature.patterns,
            colorEffect: .colorLoop,
            color: LEDColor(red: 255, green: 255, blue: 255)
        ))
        // setTheme cancels the pending ledPackageTask
        await drainLighting(handler.handle(.setTheme(.party)))
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertFalse(mock.setLedPackageCalled)
    }

    // MARK: - setSpeed

    func test_setSpeed_callsRepository() async {
        let mock = MockLightingRepository()
        let handler = makeHandler(mock: mock)

        await drainLighting(handler.handle(.setSpeed(7)))

        XCTAssertEqual(mock.setSpeedCalledWith, 7)
    }

    // MARK: - Persistence

    func test_saveLightScheduleSettings_callsClosure() async {
        let mock = MockLightingRepository()
        let settings = LightScheduleSettings(enabled: true, offHour: 22, offMinute: 30, onHour: 8, onMinute: 0)
        nonisolated(unsafe) var captured: LightScheduleSettings?
        let handler = makeHandler(mock: mock, savedLightSchedule: { captured = $0 })

        await drainLighting(handler.handle(.saveLightScheduleSettings(settings)))

        XCTAssertEqual(captured, settings)
    }

    func test_saveAutoThemeSettings_callsClosure() async {
        let mock = MockLightingRepository()
        let settings = AutoThemeSettings(enabled: true, playingTheme: .party, idleTheme: .nature)
        nonisolated(unsafe) var captured: AutoThemeSettings?
        let handler = makeHandler(mock: mock, savedAutoTheme: { captured = $0 })

        await drainLighting(handler.handle(.saveAutoThemeSettings(settings)))

        XCTAssertEqual(captured, settings)
    }

    func test_saveLedCustomization_callsClosure() async {
        let mock = MockLightingRepository()
        let customization = LEDCustomization(
            activePatterns: [0x01: [0x01, 0x02]],
            colorEffect: .staticColor,
            customColor: LEDColor(red: 128, green: 64, blue: 32)
        )
        nonisolated(unsafe) var captured: LEDCustomization?
        let handler = makeHandler(mock: mock, savedLedCustomization: { captured = $0 })

        await drainLighting(handler.handle(.saveLedCustomization(customization)))

        XCTAssertEqual(captured, customization)
    }

    func test_saveLanguage_withLocale_callsClosure() async {
        let mock = MockLightingRepository()
        nonisolated(unsafe) var captured: String? = "not-called"
        let handler = makeHandler(mock: mock, savedLanguage: { captured = $0 })

        await drainLighting(handler.handle(.saveLanguage("fr")))

        XCTAssertEqual(captured, "fr")
    }

    func test_saveLanguage_withNil_callsClosure() async {
        let mock = MockLightingRepository()
        nonisolated(unsafe) var captured: String? = "not-called"
        let handler = makeHandler(mock: mock, savedLanguage: { captured = $0 })

        await drainLighting(handler.handle(.saveLanguage(nil)))

        XCTAssertNil(captured)
    }
}
