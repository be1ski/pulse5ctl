import CoreElm
import FeaturePulseDomain
import Foundation

public enum PulseAction: ElmAction, Equatable, Sendable {
    case lifecycle(Lifecycle)
    case connection(Connection)
    case controls(Controls)
    case autoTheme(AutoTheme)
    case lightSchedule(LightSchedule)
    case settings(Settings)
    case system(System)

    public enum Lifecycle: Equatable, Sendable {
        case started
    }

    public enum Connection: Equatable, Sendable {
        case connectTapped
        case disconnectTapped
        case selectDevice(UUID)
    }

    public enum Controls: Equatable, Sendable {
        case toggleLight
        case selectTheme(LEDTheme)
        case setBrightness(Double)
        case toggleBodyLight
        case toggleProjection
        case setSpeed(UInt8)
        case togglePattern(LEDPattern, LEDTheme)
        case soloPattern(LEDPattern, LEDTheme)
        case setCustomColor(LEDColor)
        case setColorEffect(ColorEffect)
    }

    public enum AutoTheme: Equatable, Sendable {
        case toggleEnabled
        case setPlayingTheme(LEDTheme)
        case setIdleTheme(LEDTheme)
    }

    public enum LightSchedule: Equatable, Sendable {
        case toggleEnabled
        case setOffTime(hour: Int, minute: Int)
        case setOnTime(hour: Int, minute: Int)
    }

    public enum Settings: Equatable, Sendable {
        case setLanguage(String?)
    }

    public enum System: Equatable, Sendable {
        case repositoryEvent(PulseRepositoryEvent)
        case nowPlayingChanged(Bool)
        case lightScheduleChanged(Bool)
        case dismissError
    }
}
