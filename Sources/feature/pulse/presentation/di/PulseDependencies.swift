import FeaturePulseDomain

public struct PulseDependencies {
    public let observePulseEvents: ObservePulseEventsUseCase
    public let startPulseScan: StartPulseScanUseCase
    public let connectPulseSpeaker: ConnectPulseSpeakerUseCase
    public let disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase
    public let setPulseTheme: SetPulseThemeUseCase
    public let setPulseLightStatus: SetPulseLightStatusUseCase
    public let setPulseBrightness: SetPulseBrightnessUseCase
    public let setPulseSpeed: SetPulseSpeedUseCase
    public let setPulseLedPackage: SetPulseLedPackageUseCase
    public let requestPulseState: RequestPulseStateUseCase
    public let observeNowPlaying: ObserveNowPlayingUseCase
    public let observeLightSchedule: ObserveLightScheduleUseCase
    public let loadAutoThemeSettings: @Sendable () -> AutoThemeSettings
    public let saveAutoThemeSettings: @Sendable (AutoThemeSettings) -> Void
    public let loadLedCustomization: @Sendable () -> LEDCustomization
    public let saveLedCustomization: @Sendable (LEDCustomization) -> Void
    public let loadLightScheduleSettings: @Sendable () -> LightScheduleSettings
    public let saveLightScheduleSettings: @Sendable (LightScheduleSettings) -> Void
    public let loadLanguage: @Sendable () -> String?
    public let saveLanguage: @Sendable (String?) -> Void

    public init(
        observePulseEvents: ObservePulseEventsUseCase,
        startPulseScan: StartPulseScanUseCase,
        connectPulseSpeaker: ConnectPulseSpeakerUseCase,
        disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase,
        setPulseTheme: SetPulseThemeUseCase,
        setPulseLightStatus: SetPulseLightStatusUseCase,
        setPulseBrightness: SetPulseBrightnessUseCase,
        setPulseSpeed: SetPulseSpeedUseCase,
        setPulseLedPackage: SetPulseLedPackageUseCase,
        requestPulseState: RequestPulseStateUseCase,
        observeNowPlaying: @escaping ObserveNowPlayingUseCase,
        observeLightSchedule: @escaping ObserveLightScheduleUseCase,
        loadAutoThemeSettings: @Sendable @escaping () -> AutoThemeSettings,
        saveAutoThemeSettings: @Sendable @escaping (AutoThemeSettings) -> Void,
        loadLedCustomization: @Sendable @escaping () -> LEDCustomization,
        saveLedCustomization: @Sendable @escaping (LEDCustomization) -> Void,
        loadLightScheduleSettings: @Sendable @escaping () -> LightScheduleSettings,
        saveLightScheduleSettings: @Sendable @escaping (LightScheduleSettings) -> Void,
        loadLanguage: @Sendable @escaping () -> String?,
        saveLanguage: @Sendable @escaping (String?) -> Void
    ) {
        self.observePulseEvents = observePulseEvents
        self.startPulseScan = startPulseScan
        self.connectPulseSpeaker = connectPulseSpeaker
        self.disconnectPulseSpeaker = disconnectPulseSpeaker
        self.setPulseTheme = setPulseTheme
        self.setPulseLightStatus = setPulseLightStatus
        self.setPulseBrightness = setPulseBrightness
        self.setPulseSpeed = setPulseSpeed
        self.setPulseLedPackage = setPulseLedPackage
        self.requestPulseState = requestPulseState
        self.observeNowPlaying = observeNowPlaying
        self.observeLightSchedule = observeLightSchedule
        self.loadAutoThemeSettings = loadAutoThemeSettings
        self.saveAutoThemeSettings = saveAutoThemeSettings
        self.loadLedCustomization = loadLedCustomization
        self.saveLedCustomization = saveLedCustomization
        self.loadLightScheduleSettings = loadLightScheduleSettings
        self.saveLightScheduleSettings = saveLightScheduleSettings
        self.loadLanguage = loadLanguage
        self.saveLanguage = saveLanguage
    }
}
