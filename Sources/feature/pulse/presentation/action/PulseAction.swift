import CoreElm
import FeaturePulseDomain
import Foundation

public enum PulseAction: ElmAction, Equatable {
    case lifecycle(Lifecycle)
    case connection(Connection)
    case controls(Controls)
    case autoTheme(AutoTheme)
    case system(System)

    public enum Lifecycle: Equatable {
        case started
    }

    public enum Connection: Equatable {
        case connectTapped
        case disconnectTapped
        case selectDevice(UUID)
    }

    public enum Controls: Equatable {
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

    public enum AutoTheme: Equatable {
        case toggleEnabled
        case setPlayingTheme(LEDTheme)
        case setIdleTheme(LEDTheme)
    }

    public enum System: Equatable {
        case repositoryEvent(PulseRepositoryEvent)
        case nowPlayingChanged(Bool)
        case dismissError
    }
}
