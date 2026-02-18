import FeaturePulseDomain
import Foundation

public enum PulseEffect: Equatable {
    case observeRepository
    case startScan
    case disconnect
    case connect(UUID)
    case setLight(Bool)
    case setTheme(LEDTheme)
    case setBrightness(level: UInt8, bodyLight: Bool, projection: Bool)
    case setSpeed(UInt8)
    case requestCurrentState
    case observeNowPlaying
    case saveAutoThemeSettings(AutoThemeSettings)
}
