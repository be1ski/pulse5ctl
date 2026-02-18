import FeaturePulseData
import FeaturePulseDomain
import FeaturePulsePresentation
import Foundation

@MainActor
public final class AppGraph {
    public static let shared = AppGraph()

    public let appDependencies: AppDependencies

    private static let autoThemeKey = "autoThemeSettings"

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
            }
        )

        let pulseFeature = PulseFeatureFactory.create(dependencies: pulseDependencies)
        appDependencies = AppDependencies(pulseFeature: pulseFeature)
    }
}
