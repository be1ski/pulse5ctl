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
    private let setPulseLedPackage: SetPulseLedPackageUseCase
    private let requestPulseState: RequestPulseStateUseCase
    private let observeNowPlaying: ObserveNowPlayingUseCase
    private let observeLightSchedule: ObserveLightScheduleUseCase
    private let saveAutoThemeSettings: (AutoThemeSettings) -> Void
    private let saveLedCustomization: (LEDCustomization) -> Void
    private let saveLightScheduleSettings: (LightScheduleSettings) -> Void
    private let saveLanguage: (String?) -> Void

    private var brightnessTask: Task<Void, Never>?
    private var ledPackageTask: Task<Void, Never>?
    private var lightScheduleTask: Task<Void, Never>?

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
        saveAutoThemeSettings: @escaping (AutoThemeSettings) -> Void,
        saveLedCustomization: @escaping (LEDCustomization) -> Void,
        saveLightScheduleSettings: @escaping (LightScheduleSettings) -> Void,
        saveLanguage: @escaping (String?) -> Void
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
        self.saveAutoThemeSettings = saveAutoThemeSettings
        self.saveLedCustomization = saveLedCustomization
        self.saveLightScheduleSettings = saveLightScheduleSettings
        self.saveLanguage = saveLanguage
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
            ledPackageTask?.cancel()
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

        case let .setLedPackage(theme, activePatterns, allPatterns, colorEffect, color):
            ledPackageTask?.cancel()
            ledPackageTask = Task { [setPulseLedPackage] in
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
                setPulseLedPackage(theme: theme, activePatterns: activePatterns, allPatterns: allPatterns, colorEffect: colorEffect, color: color)
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

        case let .observeLightSchedule(settings):
            lightScheduleTask?.cancel()
            nonisolated(unsafe) var task: Task<Void, Never>?
            let stream = AsyncStream<PulseAction> { [observeLightSchedule] continuation in
                task = Task {
                    for await isInOffWindow in observeLightSchedule(settings) {
                        guard !Task.isCancelled else { break }
                        continuation.yield(.system(.lightScheduleChanged(isInOffWindow)))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in
                    task?.cancel()
                }
            }
            lightScheduleTask = task
            return stream

        case .stopLightSchedule:
            lightScheduleTask?.cancel()
            lightScheduleTask = nil
            return noActions()

        case let .saveLightScheduleSettings(settings):
            return sideEffect {
                self.saveLightScheduleSettings(settings)
            }

        case let .saveAutoThemeSettings(settings):
            return sideEffect {
                self.saveAutoThemeSettings(settings)
            }

        case let .saveLedCustomization(customization):
            return sideEffect {
                self.saveLedCustomization(customization)
            }

        case let .saveLanguage(locale):
            return sideEffect {
                self.saveLanguage(locale)
            }
        }
    }
}
