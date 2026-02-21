import CoreLocalization

public enum LEDPattern: UInt8, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    // Nature
    case campfire = 0x01
    case northernLights = 0x02
    case seaWave = 0x03
    case universe = 0x04

    // Party
    case strobe = 0x05
    case equalizer = 0x06
    case geometry = 0x07
    case spin = 0x08
    case rainbow = 0x09

    // Spiritual
    case dynamicWave = 0x0A
    case lava = 0x0B
    case focus = 0x0C

    // Weather
    case skySunny = 0x0D
    case rain = 0x0E
    case snow = 0x0F
    case thunder = 0x10
    case cloud = 0x11

    // Cocktail
    case fruitGin = 0x13
    case mojito = 0x14
    case tequila = 0x15
    case cherry = 0x16

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .campfire: return L10n.patternCampfire
        case .northernLights: return L10n.patternNorthernLights
        case .seaWave: return L10n.patternSeaWave
        case .universe: return L10n.patternUniverse
        case .strobe: return L10n.patternStrobe
        case .equalizer: return L10n.patternEqualizer
        case .geometry: return L10n.patternGeometry
        case .spin: return L10n.patternSpin
        case .rainbow: return L10n.patternRainbow
        case .dynamicWave: return L10n.patternDynamicWave
        case .lava: return L10n.patternLava
        case .focus: return L10n.patternFocus
        case .skySunny: return L10n.patternSkySunny
        case .rain: return L10n.patternRain
        case .snow: return L10n.patternSnow
        case .thunder: return L10n.patternThunder
        case .cloud: return L10n.patternCloud
        case .fruitGin: return L10n.patternFruitGin
        case .mojito: return L10n.patternMojito
        case .tequila: return L10n.patternTequila
        case .cherry: return L10n.patternCherry
        }
    }

    public var sfSymbol: String {
        switch self {
        case .campfire: return "flame.fill"
        case .northernLights: return "sun.haze.fill"
        case .seaWave: return "water.waves"
        case .universe: return "sparkles"
        case .strobe: return "bolt.fill"
        case .equalizer: return "waveform"
        case .geometry: return "hexagon.fill"
        case .spin: return "arrow.triangle.2.circlepath"
        case .rainbow: return "rainbow"
        case .dynamicWave: return "wave.3.right"
        case .lava: return "mountain.2.fill"
        case .focus: return "scope"
        case .skySunny: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "snowflake"
        case .thunder: return "cloud.bolt.fill"
        case .cloud: return "cloud.fill"
        case .fruitGin: return "wineglass"
        case .mojito: return "leaf.fill"
        case .tequila: return "cup.and.saucer.fill"
        case .cherry: return "drop.fill"
        }
    }
}
