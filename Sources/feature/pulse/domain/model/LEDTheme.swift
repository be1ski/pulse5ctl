public enum LEDTheme: UInt8, CaseIterable, Identifiable, Codable {
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
            return "Nature"
        case .party:
            return "Party"
        case .spiritual:
            return "Spiritual"
        case .cocktail:
            return "Cocktail"
        case .weather:
            return "Weather"
        case .canvas:
            return "Canvas"
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
