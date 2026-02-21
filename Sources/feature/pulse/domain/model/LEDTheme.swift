import CoreLocalization

public enum LEDTheme: UInt8, CaseIterable, Identifiable, Codable, Sendable {
    case nature = 0x01
    case party = 0x02
    case spiritual = 0x03
    case cocktail = 0x04
    case weather = 0x05
    case canvas = 0xC1

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .nature:
            return L10n.themeNature
        case .party:
            return L10n.themeParty
        case .spiritual:
            return L10n.themeSpiritual
        case .cocktail:
            return L10n.themeCocktail
        case .weather:
            return L10n.themeWeather
        case .canvas:
            return L10n.themeCanvas
        }
    }

    public var patterns: [LEDPattern] {
        switch self {
        case .nature: return [.campfire, .northernLights, .seaWave, .universe]
        case .party: return [.strobe, .equalizer, .geometry, .spin, .rainbow]
        case .spiritual: return [.dynamicWave, .lava, .focus]
        case .cocktail: return [.fruitGin, .mojito, .tequila, .cherry]
        case .weather: return [.skySunny, .rain, .snow, .thunder, .cloud]
        case .canvas: return []
        }
    }

    public var sfSymbol: String {
        switch self {
        case .nature:
            return "leaf.fill"
        case .party:
            return "party.popper.fill"
        case .spiritual:
            return "sparkles"
        case .cocktail:
            return "wineglass.fill"
        case .weather:
            return "cloud.sun.fill"
        case .canvas:
            return "paintpalette.fill"
        }
    }
}
