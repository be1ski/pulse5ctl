import CoreElm
import FeaturePulseDomain
import Foundation

public final class PulseEffectHandler {
    private let observePulseEvents: ObservePulseEventsUseCase
    private let startPulseScan: StartPulseScanUseCase
    private let connectPulseSpeaker: ConnectPulseSpeakerUseCase
    private let disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase
    private let setPulseTheme: SetPulseThemeUseCase
    private let setPulseLightStatus: SetPulseLightStatusUseCase
    private let setPulseBrightness: SetPulseBrightnessUseCase
    private let setPulseSpeed: SetPulseSpeedUseCase
    private let requestPulseState: RequestPulseStateUseCase
    private let observeNowPlaying: ObserveNowPlayingUseCase
    private let saveAutoThemeSettings: (AutoThemeSettings) -> Void

    private var brightnessTask: Task<Void, Never>?

    public init(
        observePulseEvents: ObservePulseEventsUseCase,
        startPulseScan: StartPulseScanUseCase,
        connectPulseSpeaker: ConnectPulseSpeakerUseCase,
        disconnectPulseSpeaker: DisconnectPulseSpeakerUseCase,
        setPulseTheme: SetPulseThemeUseCase,
        setPulseLightStatus: SetPulseLightStatusUseCase,
        setPulseBrightness: SetPulseBrightnessUseCase,
        setPulseSpeed: SetPulseSpeedUseCase,
        requestPulseState: RequestPulseStateUseCase,
        observeNowPlaying: @escaping ObserveNowPlayingUseCase,
        saveAutoThemeSettings: @escaping (AutoThemeSettings) -> Void
    ) {
        self.observePulseEvents = observePulseEvents
        self.startPulseScan = startPulseScan
        self.connectPulseSpeaker = connectPulseSpeaker
        self.disconnectPulseSpeaker = disconnectPulseSpeaker
        self.setPulseTheme = setPulseTheme
        self.setPulseLightStatus = setPulseLightStatus
        self.setPulseBrightness = setPulseBrightness
        self.setPulseSpeed = setPulseSpeed
        self.requestPulseState = requestPulseState
        self.observeNowPlaying = observeNowPlaying
        self.saveAutoThemeSettings = saveAutoThemeSettings
    }

    public func handle(_ effect: PulseEffect) -> AsyncStream<PulseAction> {
        switch effect {
        case .observeRepository:
            return actions { continuation in
                for await event in self.observePulseEvents() {
                    continuation.yield(.system(.repositoryEvent(event)))
                }
            }

        case .startScan:
            return sideEffect {
                self.startPulseScan()
            }

        case .disconnect:
            return sideEffect {
                self.disconnectPulseSpeaker()
            }

        case let .connect(deviceID):
            return sideEffect {
                self.connectPulseSpeaker(deviceID: deviceID)
            }

        case let .setLight(isEnabled):
            return sideEffect {
                self.setPulseLightStatus(enabled: isEnabled)
            }

        case let .setTheme(theme):
            return sideEffect {
                self.setPulseTheme(theme: theme)
            }

        case let .setBrightness(level, bodyLight, projection):
            brightnessTask?.cancel()
            brightnessTask = Task { [setPulseBrightness] in
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
                setPulseBrightness(level: level, bodyLight: bodyLight, projection: projection)
            }
            return noActions()

        case let .setSpeed(speed):
            return sideEffect {
                self.setPulseSpeed(speed: speed)
            }

        case .requestCurrentState:
            return sideEffect {
                self.requestPulseState()
            }

        case .observeNowPlaying:
            return actions { continuation in
                for await isPlaying in self.observeNowPlaying() {
                    continuation.yield(.system(.nowPlayingChanged(isPlaying)))
                }
            }

        case let .saveAutoThemeSettings(settings):
            return sideEffect {
                self.saveAutoThemeSettings(settings)
            }
        }
    }
}
