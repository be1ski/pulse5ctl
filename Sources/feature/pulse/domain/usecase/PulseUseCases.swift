import Foundation

public struct ObservePulseEventsUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction() -> AsyncStream<PulseRepositoryEvent> {
        repository.events
    }
}

public struct LoadPulseSnapshotUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction() -> PulseSpeakerSnapshot {
        repository.snapshot
    }
}

public struct StartPulseScanUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction() {
        repository.startScan()
    }
}

public struct ConnectPulseSpeakerUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction(deviceID: UUID) {
        repository.connect(to: deviceID)
    }
}

public struct DisconnectPulseSpeakerUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction() {
        repository.disconnect()
    }
}

public struct SetPulseThemeUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction(theme: LEDTheme) {
        repository.setTheme(theme)
    }
}

public struct SetPulseLightStatusUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction(enabled: Bool) {
        repository.setLight(enabled: enabled)
    }
}

public struct SetPulseBrightnessUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction(level: UInt8, bodyLight: Bool, projection: Bool) {
        repository.setBrightness(level: level, bodyLight: bodyLight, projection: projection)
    }
}

public struct SetPulseSpeedUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction(speed: UInt8) {
        repository.setSpeed(speed)
    }
}

public typealias ObserveNowPlayingUseCase = () -> AsyncStream<Bool>

public struct RequestPulseStateUseCase {
    private let repository: any PulseSpeakerRepository

    public init(repository: any PulseSpeakerRepository) {
        self.repository = repository
    }

    public func callAsFunction() {
        repository.requestCurrentState()
    }
}
