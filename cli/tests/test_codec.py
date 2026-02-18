from pulse5.protocol.codec import PulseCodec, BrightnessState
from pulse5.protocol.constants import PulseConstants as C
from pulse5.protocol.models import LEDTheme


class TestEncoding:
    def test_set_led_brightness(self):
        assert PulseCodec.set_led_brightness(60) == bytes([0xAA, 0x8A, 0x03, 60, 1, 1])

    def test_set_led_brightness_clamps_low(self):
        assert PulseCodec.set_led_brightness(0)[3] == C.MIN_BRIGHTNESS

    def test_set_led_brightness_clamps_high(self):
        assert PulseCodec.set_led_brightness(255)[3] == C.MAX_BRIGHTNESS

    def test_set_led_brightness_body_off(self):
        assert PulseCodec.set_led_brightness(50, body_light=False) == bytes([0xAA, 0x8A, 0x03, 50, 0, 1])

    def test_set_led_brightness_projection_off(self):
        assert PulseCodec.set_led_brightness(50, projection=False) == bytes([0xAA, 0x8A, 0x03, 50, 1, 0])

    def test_request_speaker_info(self):
        assert PulseCodec.request_speaker_info() == bytes([0xAA, 0x11, 0x00])

    def test_request_led_brightness(self):
        assert PulseCodec.request_led_brightness() == bytes([0xAA, 0x8B, 0x00])

    def test_request_led_package_info(self):
        assert PulseCodec.request_led_package_info() == bytes([0xAA, 0x83, 0x00])

    def test_switch_package(self):
        assert PulseCodec.switch_package(0x02) == bytes([0xAA, 0x90, 0x01, 0x02])

    def test_set_led_package_static_color(self):
        result = PulseCodec.set_led_package(
            package_id=0xC1, active_patterns=[], all_patterns=[],
            color_effect=0, red=255, green=0, blue=0,
        )
        assert result == bytes([0xAA, 0x85, 0x07, 0xC1, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00])

    def test_set_led_package_with_patterns(self):
        result = PulseCodec.set_led_package(
            package_id=0x01, active_patterns=[0x01, 0x02], all_patterns=[0x01, 0x02, 0x03, 0x04],
            color_effect=1, red=0xFF, green=0xFF, blue=0xFF,
        )
        assert result == bytes([
            0xAA, 0x85, 0x0B, 0x01, 0x02, 0x04,
            0x01, 0x02, 0x03, 0x04,
            0x01, 0xFF, 0xFF, 0xFF,
        ])


class TestDecoding:
    def test_parse_valid(self):
        resp = PulseCodec.parse(bytes([0xAA, 0x72, 0x01, 0x01]))
        assert resp is not None
        assert resp.command_id == 0x72
        assert resp.payload == bytes([0x01])

    def test_parse_bad_header(self):
        assert PulseCodec.parse(bytes([0xBB, 0x72, 0x01])) is None

    def test_parse_too_short(self):
        assert PulseCodec.parse(bytes([0xAA, 0x72])) is None

    def test_parse_empty_payload(self):
        resp = PulseCodec.parse(bytes([0xAA, 0x11, 0x00]))
        assert resp is not None
        assert resp.payload == b""

    def test_parse_brightness_state(self):
        brt = PulseCodec.parse_brightness_state(bytes([0xAA, 0x8C, 0x03, 50, 1, 1]))
        assert brt == BrightnessState(level=50, body_light_on=True, projection_on=True)

    def test_parse_brightness_state_lights_off(self):
        brt = PulseCodec.parse_brightness_state(bytes([0xAA, 0x8C, 0x03, 30, 0, 0]))
        assert brt == BrightnessState(level=30, body_light_on=False, projection_on=False)

    def test_parse_brightness_wrong_cmd(self):
        assert PulseCodec.parse_brightness_state(bytes([0xAA, 0x72, 0x03, 50, 1, 1])) is None

    def test_parse_brightness_short_payload(self):
        assert PulseCodec.parse_brightness_state(bytes([0xAA, 0x8C, 0x02, 50, 1])) is None

    def test_parse_selected_theme_party(self):
        assert PulseCodec.parse_selected_theme(bytes([0xAA, 0x84, 0x02, 0x00, 0x02])) == LEDTheme.PARTY

    def test_parse_selected_theme_nature(self):
        assert PulseCodec.parse_selected_theme(bytes([0xAA, 0x84, 0x02, 0x00, 0x01])) == LEDTheme.NATURE

    def test_parse_selected_theme_wrong_cmd(self):
        assert PulseCodec.parse_selected_theme(bytes([0xAA, 0x72, 0x02, 0x00, 0x02])) is None

    def test_parse_selected_theme_short_payload(self):
        assert PulseCodec.parse_selected_theme(bytes([0xAA, 0x84, 0x01, 0x00])) is None

    def test_parse_selected_theme_unknown_value(self):
        assert PulseCodec.parse_selected_theme(bytes([0xAA, 0x84, 0x02, 0x00, 0xFF])) is None

    def test_parse_bytearray(self):
        resp = PulseCodec.parse(bytearray([0xAA, 0x72, 0x01, 0x01]))
        assert resp is not None
        assert resp.command_id == 0x72
