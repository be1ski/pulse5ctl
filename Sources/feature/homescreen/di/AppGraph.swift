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
    private static let languageKey = "selectedLanguage"

    private init() {
        let repository = PulseSpeakerRepositoryImpl()
        let nowPlayingMonitor = NowPlayingMonitor()

        let pulseDependencies = PulseDependencies(
            observePulseEvents: ObservePulseEventsUseCase(repository: repository),
            loadPulseSnapshot: LoadPulseSnapshotUseCase(repository: repository),
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
            loadAutoThemeSettings: {
                guard let data = UserDefaults.standard.data(forKey: AppGraph.autoThemeKey),
                      let settings = try? JSONDecoder().decode(AutoThemeSettings.self, from: data) else {
                    return AutoThemeSettings()
                }
                return settings
            },
            saveAutoThemeSettings: { settings in
                if let data = try? JSONEncoder().encode(settings) {
                    UserDefaults.standard.set(data, forKey: AppGraph.autoThemeKey)
                }
            },
            loadLedCustomization: {
                guard let data = UserDefaults.standard.data(forKey: AppGraph.ledCustomizationKey),
                      let customization = try? JSONDecoder().decode(LEDCustomization.self, from: data) else {
                    return LEDCustomization()
                }
                return customization
            },
            saveLedCustomization: { customization in
                if let data = try? JSONEncoder().encode(customization) {
                    UserDefaults.standard.set(data, forKey: AppGraph.ledCustomizationKey)
                }
            },
            loadLanguage: {
                UserDefaults.standard.string(forKey: AppGraph.languageKey)
            },
            saveLanguage: { locale in
                if let locale {
                    UserDefaults.standard.set(locale, forKey: AppGraph.languageKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: AppGraph.languageKey)
                }
            }
        )

        let pulseFeature = PulseFeatureFactory.create(dependencies: pulseDependencies)
        appDependencies = AppDependencies(pulseFeature: pulseFeature)
    }
}
