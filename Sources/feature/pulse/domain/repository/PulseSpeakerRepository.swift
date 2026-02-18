import Foundation

public protocol PulseSpeakerRepository: AnyObject {
    var events: AsyncStream<PulseRepositoryEvent> { get }
    var snapshot: PulseSpeakerSnapshot { get }

    func startScan()
    func stopScan()
    func connect(to deviceID: UUID)
    func disconnect()

    func setTheme(_ theme: LEDTheme)
    func setLight(enabled: Bool)
    func setBrightness(level: UInt8, bodyLight: Bool, projection: Bool)
    func setSpeed(_ speed: UInt8)

    func requestCurrentState()
}
