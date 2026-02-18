import FeaturePulseDomain

public struct PulseDependencies {
    public let observePulseEvents: ObservePulseEventsUseCase
    public let loadPulseSnapshot: LoadPulseSnapshotUseCase
    public let startPulseScan: StartPulseScanUseCase
    public let connectPulseSpeaker: ConnectPulseSpeakerUseCase
    public let disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase
    public let setPulseTheme: SetPulseThemeUseCase
    public let setPulseLightStatus: SetPulseLightStatusUseCase
    public let setPulseBrightness: SetPulseBrightnessUseCase
    public let setPulseSpeed: SetPulseSpeedUseCase
    public let requestPulseState: RequestPulseStateUseCase
    public let observeNowPlaying: ObserveNowPlayingUseCase
    public let loadAutoThemeSettings: () -> AutoThemeSettings
    public let saveAutoThemeSettings: (AutoThemeSettings) -> Void

    public init(
        observePulseEvents: ObservePulseEventsUseCase,
        loadPulseSnapshot: LoadPulseSnapshotUseCase,
        startPulseScan: StartPulseScanUseCase,
        connectPulseSpeaker: ConnectPulseSpeakerUseCase,
        disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase,
        setPulseTheme: SetPulseThemeUseCase,
        setPulseLightStatus: SetPulseLightStatusUseCase,
        setPulseBrightness: SetPulseBrightnessUseCase,
        setPulseSpeed: SetPulseSpeedUseCase,
        requestPulseState: RequestPulseStateUseCase,
        observeNowPlaying: @escaping ObserveNowPlayingUseCase,
        loadAutoThemeSettings: @escaping () -> AutoThemeSettings,
        saveAutoThemeSettings: @escaping (AutoThemeSettings) -> Void
    ) {
        self.observePulseEvents = observePulseEvents
        self.loadPulseSnapshot = loadPulseSnapshot
        self.startPulseScan = startPulseScan
        self.connectPulseSpeaker = connectPulseSpeaker
        self.disconnectPulseSpeaker = disconnectPulseSpeaker
        self.setPulseTheme = setPulseTheme
        self.setPulseLightStatus = setPulseLightStatus
        self.setPulseBrightness = setPulseBrightness
        self.setPulseSpeed = setPulseSpeed
        self.requestPulseState = requestPulseState
        self.observeNowPlaying = observeNowPlaying
        self.loadAutoThemeSettings = loadAutoThemeSettings
        self.saveAutoThemeSettings = saveAutoThemeSettings
    }
}
