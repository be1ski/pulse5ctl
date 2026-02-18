from pulse5.protocol.models import (
    PATTERN_BY_NAME,
    THEME_BY_NAME,
    ColorEffect,
    LEDPattern,
    LEDTheme,
)


class TestLEDTheme:
    def test_values(self):
        assert LEDTheme.NATURE == 0x01
        assert LEDTheme.PARTY == 0x02
        assert LEDTheme.SPIRITUAL == 0x03
        assert LEDTheme.COCKTAIL == 0x04
        assert LEDTheme.WEATHER == 0x05
        assert LEDTheme.CANVAS == 0xC1

    def test_display_names(self):
        assert LEDTheme.NATURE.display_name == "Nature"
        assert LEDTheme.CANVAS.display_name == "Canvas"

    def test_nature_patterns(self):
        patterns = LEDTheme.NATURE.patterns
        assert len(patterns) == 4
        assert LEDPattern.CAMPFIRE in patterns
        assert LEDPattern.NORTHERN_LIGHTS in patterns
        assert LEDPattern.SEA_WAVE in patterns
        assert LEDPattern.UNIVERSE in patterns

    def test_party_patterns(self):
        assert len(LEDTheme.PARTY.patterns) == 5
        assert LEDPattern.RAINBOW in LEDTheme.PARTY.patterns

    def test_spiritual_patterns(self):
        assert len(LEDTheme.SPIRITUAL.patterns) == 3

    def test_cocktail_patterns(self):
        assert len(LEDTheme.COCKTAIL.patterns) == 4

    def test_weather_patterns(self):
        assert len(LEDTheme.WEATHER.patterns) == 5

    def test_canvas_empty(self):
        assert LEDTheme.CANVAS.patterns == []

    def test_all_patterns_assigned(self):
        all_patterns = []
        for theme in LEDTheme:
            all_patterns.extend(theme.patterns)
        assert len(all_patterns) == len(LEDPattern)


class TestLEDPattern:
    def test_campfire_value(self):
        assert LEDPattern.CAMPFIRE == 0x01

    def test_cherry_value(self):
        assert LEDPattern.CHERRY == 0x16

    def test_display_name(self):
        assert LEDPattern.NORTHERN_LIGHTS.display_name == "Northern Lights"
        assert LEDPattern.FRUIT_GIN.display_name == "Fruit Gin"

    def test_theme_mapping(self):
        assert LEDPattern.CAMPFIRE.theme == LEDTheme.NATURE
        assert LEDPattern.RAINBOW.theme == LEDTheme.PARTY
        assert LEDPattern.LAVA.theme == LEDTheme.SPIRITUAL
        assert LEDPattern.MOJITO.theme == LEDTheme.COCKTAIL
        assert LEDPattern.THUNDER.theme == LEDTheme.WEATHER

    def test_all_patterns_have_theme(self):
        for pattern in LEDPattern:
            assert pattern.theme is not None


class TestColorEffect:
    def test_values(self):
        assert ColorEffect.STATIC == 0
        assert ColorEffect.COLOR_LOOP == 1


class TestLookups:
    def test_theme_by_name(self):
        assert THEME_BY_NAME["nature"] == LEDTheme.NATURE
        assert THEME_BY_NAME["party"] == LEDTheme.PARTY
        assert "canvas" not in THEME_BY_NAME

    def test_pattern_by_name(self):
        assert PATTERN_BY_NAME["campfire"] == LEDPattern.CAMPFIRE
        assert PATTERN_BY_NAME["northern lights"] == LEDPattern.NORTHERN_LIGHTS

    def test_all_themes_in_lookup(self):
        # Canvas excluded
        assert len(THEME_BY_NAME) == 5

    def test_all_patterns_in_lookup(self):
        assert len(PATTERN_BY_NAME) == len(LEDPattern)
