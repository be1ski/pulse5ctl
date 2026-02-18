from enum import IntEnum


class LEDTheme(IntEnum):
    NATURE = 0x01
    PARTY = 0x02
    SPIRITUAL = 0x03
    COCKTAIL = 0x04
    WEATHER = 0x05
    CANVAS = 0xC1

    @property
    def display_name(self) -> str:
        return _THEME_NAMES[self]

    @property
    def patterns(self) -> list["LEDPattern"]:
        return list(_THEME_PATTERNS[self])


class LEDPattern(IntEnum):
    CAMPFIRE = 0x01
    NORTHERN_LIGHTS = 0x02
    SEA_WAVE = 0x03
    UNIVERSE = 0x04
    STROBE = 0x05
    EQUALIZER = 0x06
    GEOMETRY = 0x07
    SPIN = 0x08
    RAINBOW = 0x09
    DYNAMIC_WAVE = 0x0A
    LAVA = 0x0B
    FOCUS = 0x0C
    SKY_SUNNY = 0x0D
    RAIN = 0x0E
    SNOW = 0x0F
    THUNDER = 0x10
    CLOUD = 0x11
    FRUIT_GIN = 0x13
    MOJITO = 0x14
    TEQUILA = 0x15
    CHERRY = 0x16

    @property
    def display_name(self) -> str:
        return _PATTERN_NAMES[self]

    @property
    def theme(self) -> LEDTheme:
        return _PATTERN_TO_THEME[self]


class ColorEffect(IntEnum):
    STATIC = 0
    COLOR_LOOP = 1


_THEME_NAMES: dict[LEDTheme, str] = {
    LEDTheme.NATURE: "Nature",
    LEDTheme.PARTY: "Party",
    LEDTheme.SPIRITUAL: "Spiritual",
    LEDTheme.COCKTAIL: "Cocktail",
    LEDTheme.WEATHER: "Weather",
    LEDTheme.CANVAS: "Canvas",
}

_PATTERN_NAMES: dict[LEDPattern, str] = {
    LEDPattern.CAMPFIRE: "Campfire",
    LEDPattern.NORTHERN_LIGHTS: "Northern Lights",
    LEDPattern.SEA_WAVE: "Sea Wave",
    LEDPattern.UNIVERSE: "Universe",
    LEDPattern.STROBE: "Strobe",
    LEDPattern.EQUALIZER: "Equalizer",
    LEDPattern.GEOMETRY: "Geometry",
    LEDPattern.SPIN: "Spin",
    LEDPattern.RAINBOW: "Rainbow",
    LEDPattern.DYNAMIC_WAVE: "Dynamic Wave",
    LEDPattern.LAVA: "Lava",
    LEDPattern.FOCUS: "Focus",
    LEDPattern.SKY_SUNNY: "Sky Sunny",
    LEDPattern.RAIN: "Rain",
    LEDPattern.SNOW: "Snow",
    LEDPattern.THUNDER: "Thunder",
    LEDPattern.CLOUD: "Cloud",
    LEDPattern.FRUIT_GIN: "Fruit Gin",
    LEDPattern.MOJITO: "Mojito",
    LEDPattern.TEQUILA: "Tequila",
    LEDPattern.CHERRY: "Cherry",
}

_THEME_PATTERNS: dict[LEDTheme, tuple[LEDPattern, ...]] = {
    LEDTheme.NATURE: (
        LEDPattern.CAMPFIRE,
        LEDPattern.NORTHERN_LIGHTS,
        LEDPattern.SEA_WAVE,
        LEDPattern.UNIVERSE,
    ),
    LEDTheme.PARTY: (
        LEDPattern.STROBE,
        LEDPattern.EQUALIZER,
        LEDPattern.GEOMETRY,
        LEDPattern.SPIN,
        LEDPattern.RAINBOW,
    ),
    LEDTheme.SPIRITUAL: (
        LEDPattern.DYNAMIC_WAVE,
        LEDPattern.LAVA,
        LEDPattern.FOCUS,
    ),
    LEDTheme.COCKTAIL: (
        LEDPattern.FRUIT_GIN,
        LEDPattern.MOJITO,
        LEDPattern.TEQUILA,
        LEDPattern.CHERRY,
    ),
    LEDTheme.WEATHER: (
        LEDPattern.SKY_SUNNY,
        LEDPattern.RAIN,
        LEDPattern.SNOW,
        LEDPattern.THUNDER,
        LEDPattern.CLOUD,
    ),
    LEDTheme.CANVAS: (),
}

_PATTERN_TO_THEME: dict[LEDPattern, LEDTheme] = {
    pattern: theme
    for theme, patterns in _THEME_PATTERNS.items()
    for pattern in patterns
}

THEME_BY_NAME: dict[str, LEDTheme] = {
    t.display_name.lower(): t for t in LEDTheme if t != LEDTheme.CANVAS
}

PATTERN_BY_NAME: dict[str, LEDPattern] = {
    p.display_name.lower(): p for p in LEDPattern
}
