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
    case setLedPackage(
        theme: LEDTheme, activePatterns: [LEDPattern], allPatterns: [LEDPattern],
        colorEffect: ColorEffect, color: LEDColor
    )
    case requestCurrentState
    case observeNowPlaying
    case saveAutoThemeSettings(AutoThemeSettings)
    case saveLedCustomization(LEDCustomization)
    case observeLightSchedule(LightScheduleSettings)
    case stopLightSchedule
    case saveLightScheduleSettings(LightScheduleSettings)
    case saveLanguage(String?)
}
