public enum LEDPattern: UInt8, CaseIterable, Identifiable, Hashable, Codable {
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
        case .campfire: return "Campfire"
        case .northernLights: return "Northern Lights"
        case .seaWave: return "Sea Wave"
        case .universe: return "Universe"
        case .strobe: return "Strobe"
        case .equalizer: return "Equalizer"
        case .geometry: return "Geometry"
        case .spin: return "Spin"
        case .rainbow: return "Rainbow"
        case .dynamicWave: return "Dynamic Wave"
        case .lava: return "Lava"
        case .focus: return "Focus"
        case .skySunny: return "Sky Sunny"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunder: return "Thunder"
        case .cloud: return "Cloud"
        case .fruitGin: return "Fruit Gin"
        case .mojito: return "Mojito"
        case .tequila: return "Tequila"
        case .cherry: return "Cherry"
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
