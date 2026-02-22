import Foundation
@testable import FeaturePulseDomain
import XCTest

private struct CapturedBrightness {
    let level: UInt8
    let bodyLight: Bool
    let projection: Bool
}

private struct CapturedLedPackage {
    let theme: LEDTheme
    let activePatterns: [LEDPattern]
    let allPatterns: [LEDPattern]
    let colorEffect: ColorEffect
    let color: LEDColor
}

private final class MockPulseSpeakerRepository: PulseSpeakerRepository, @unchecked Sendable {
    var startScanCalled = false
    var stopScanCalled = false
    var connectCalledWith: UUID?
    var disconnectCalled = false
    var setThemeCalledWith: LEDTheme?
    var setLightCalledWith: Bool?
    var setBrightnessCalledWith: CapturedBrightness?
    var setSpeedCalledWith: UInt8?
    var setLedPackageCalledWith: CapturedLedPackage?
    var requestCurrentStateCalled = false

    let events: AsyncStream<PulseRepositoryEvent>
    private let continuation: AsyncStream<PulseRepositoryEvent>.Continuation

    init() {
        let (stream, cont) = AsyncStream<PulseRepositoryEvent>.makeStream()
        self.events = stream
        self.continuation = cont
    }

    func startScan() { startScanCalled = true }
    func stopScan() { stopScanCalled = true }
    func connect(to deviceID: UUID) { connectCalledWith = deviceID }
    func disconnect() { disconnectCalled = true }
    func setTheme(_ theme: LEDTheme) { setThemeCalledWith = theme }
    func setLight(enabled: Bool) { setLightCalledWith = enabled }
    func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool) {
        setBrightnessCalledWith = CapturedBrightness(
            level: level, bodyLight: bodyLight, projection: projection
        )
    }
    func setSpeed(_ speed: UInt8) { setSpeedCalledWith = speed }
    func setLedPackage(
        theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern],
        colorEffect: ColorEffect, color: LEDColor
    ) {
        setLedPackageCalledWith = CapturedLedPackage(
            theme: theme, activePatterns: activePatterns,
            allPatterns: allPatterns, colorEffect: colorEffect,
            color: color
        )
    }
    func requestCurrentState() { requestCurrentStateCalled = true }
}

final class PulseUseCasesTests: XCTestCase {

    func test_observePulseEvents_returnsRepositoryEvents() {
        let mock = MockPulseSpeakerRepository()
        let useCase = ObservePulseEventsUseCase(repository: mock)
        let stream = useCase()
        XCTAssertNotNil(stream)
    }

    func test_startPulseScan_callsRepository() {
        let mock = MockPulseSpeakerRepository()
        let useCase = StartPulseScanUseCase(repository: mock)
        useCase()
        XCTAssertTrue(mock.startScanCalled)
    }

    func test_connectPulseSpeaker_callsRepositoryWithDeviceID() {
        let mock = MockPulseSpeakerRepository()
        let useCase = ConnectPulseSpeakerUseCase(repository: mock)
        let id = UUID()
        useCase(deviceID: id)
        XCTAssertEqual(mock.connectCalledWith, id)
    }

    func test_disconnectPulseSpeaker_callsRepository() {
        let mock = MockPulseSpeakerRepository()
        let useCase = DisconnectPulseSpeakerUseCase(repository: mock)
        useCase()
        XCTAssertTrue(mock.disconnectCalled)
    }

    func test_setPulseTheme_callsRepositoryWithTheme() {
        let mock = MockPulseSpeakerRepository()
        let useCase = SetPulseThemeUseCase(repository: mock)
        useCase(theme: .party)
        XCTAssertEqual(mock.setThemeCalledWith, .party)
    }

    func test_setPulseLightStatus_enabled_callsRepository() {
        let mock = MockPulseSpeakerRepository()
        let useCase = SetPulseLightStatusUseCase(repository: mock)
        useCase(enabled: true)
        XCTAssertEqual(mock.setLightCalledWith, true)
    }

    func test_setPulseLightStatus_disabled_callsRepository() {
        let mock = MockPulseSpeakerRepository()
        let useCase = SetPulseLightStatusUseCase(repository: mock)
        useCase(enabled: false)
        XCTAssertEqual(mock.setLightCalledWith, false)
    }

    func test_setPulseBrightness_callsRepositoryWithParams() {
        let mock = MockPulseSpeakerRepository()
        let useCase = SetPulseBrightnessUseCase(repository: mock)
        useCase(level: 50, bodyLight: true, projection: false)
        XCTAssertEqual(mock.setBrightnessCalledWith?.level, 50)
        XCTAssertEqual(mock.setBrightnessCalledWith?.bodyLight, true)
        XCTAssertEqual(mock.setBrightnessCalledWith?.projection, false)
    }

    func test_setPulseSpeed_callsRepositoryWithSpeed() {
        let mock = MockPulseSpeakerRepository()
        let useCase = SetPulseSpeedUseCase(repository: mock)
        useCase(speed: 3)
        XCTAssertEqual(mock.setSpeedCalledWith, 3)
    }

    func test_setPulseLedPackage_callsRepositoryWithAllParams() {
        let mock = MockPulseSpeakerRepository()
        let useCase = SetPulseLedPackageUseCase(repository: mock)
        let color = LEDColor(red: 255, green: 0, blue: 128)
        useCase(
            theme: .nature,
            activePatterns: [.campfire, .seaWave],
            allPatterns: [.campfire, .northernLights, .seaWave, .universe],
            colorEffect: .staticColor,
            color: color
        )
        XCTAssertEqual(mock.setLedPackageCalledWith?.theme, .nature)
        XCTAssertEqual(mock.setLedPackageCalledWith?.activePatterns, [.campfire, .seaWave])
        XCTAssertEqual(mock.setLedPackageCalledWith?.allPatterns, [.campfire, .northernLights, .seaWave, .universe])
        XCTAssertEqual(mock.setLedPackageCalledWith?.colorEffect, .staticColor)
        XCTAssertEqual(mock.setLedPackageCalledWith?.color, color)
    }

    func test_requestPulseState_callsRepository() {
        let mock = MockPulseSpeakerRepository()
        let useCase = RequestPulseStateUseCase(repository: mock)
        useCase()
        XCTAssertTrue(mock.requestCurrentStateCalled)
    }
}
