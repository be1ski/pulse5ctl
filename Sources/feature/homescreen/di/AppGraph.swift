import FeaturePulseData
import FeaturePulseDomain
import FeaturePulsePresentation
import Foundation

@MainActor
public final class AppGraph {
    public static let shared = AppGraph()

    public let appDependencies: AppDependencies

    private static let autoThemeKey = "autoThemeSettings"
    private static let ledCustomizationKey = "ledCustomization"
    private static let lightScheduleKey = "lightScheduleSettings"
    private static let languageKey = "selectedLanguage"

    private init() {
        let repository = PulseSpeakerRepositoryImpl()
        let nowPlayingMonitor = NowPlayingMonitor()
        let lightScheduleMonitor = LightScheduleMonitor()

        let pulseDependencies = PulseDependencies(
            observePulseEvents: ObservePulseEventsUseCase(repository: repository),
            startPulseScan: StartPulseScanUseCase(repository: repository),
            connectPulseSpeaker: ConnectPulseSpeakerUseCase(repository: repository),
            disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase(repository: repository),
            setPulseTheme: SetPulseThemeUseCase(repository: repository),
            setPulseLightStatus: SetPulseLightStatusUseCase(repository: repository),
            setPulseBrightness: SetPulseBrightnessUseCase(repository: repository),
            setPulseSpeed: SetPulseSpeedUseCase(repository: repository),
            setPulseLedPackage: SetPulseLedPackageUseCase(repository: repository),
            requestPulseState: RequestPulseStateUseCase(repository: repository),
            observeNowPlaying: { nowPlayingMonitor.observe() },
            observeLightSchedule: { settings in lightScheduleMonitor.observe(settings: settings) },
            loadAutoThemeSettings: { Self.load(forKey: Self.autoThemeKey) ?? AutoThemeSettings() },
            saveAutoThemeSettings: { Self.save($0, forKey: Self.autoThemeKey) },
            loadLedCustomization: { Self.load(forKey: Self.ledCustomizationKey) ?? LEDCustomization() },
            saveLedCustomization: { Self.save($0, forKey: Self.ledCustomizationKey) },
            loadLightScheduleSettings: { Self.load(forKey: Self.lightScheduleKey) ?? LightScheduleSettings() },
            saveLightScheduleSettings: { Self.save($0, forKey: Self.lightScheduleKey) },
            loadLanguage: { UserDefaults.standard.string(forKey: Self.languageKey) },
            saveLanguage: { locale in
                if let locale {
                    UserDefaults.standard.set(locale, forKey: Self.languageKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: Self.languageKey)
                }
            }
        )

        let pulseFeature = PulseFeatureFactory.create(dependencies: pulseDependencies)
        appDependencies = AppDependencies(pulseFeature: pulseFeature)
    }

    private static func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
