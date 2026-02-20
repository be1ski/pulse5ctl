from __future__ import annotations

from dataclasses import dataclass

from pulse5.protocol.constants import PulseConstants as C
from pulse5.protocol.models import LEDTheme


@dataclass
class Response:
    command_id: int
    payload: bytes


@dataclass
class BrightnessState:
    level: int
    body_light_on: bool
    projection_on: bool


class PulseCodec:

    @staticmethod
    def request_speaker_info() -> bytes:
        return bytes([C.HEADER, C.CMD_REQ_SPEAKER_INFO, 0x00])

    @staticmethod
    def switch_package(package_id: int) -> bytes:
        return bytes([C.HEADER, C.CMD_SWITCH_LED_PACKAGE, 0x01, package_id])

    @staticmethod
    def set_led_brightness(level: int, body_light: bool = True, projection: bool = True) -> bytes:
        clamped = min(max(level, C.MIN_BRIGHTNESS), C.MAX_BRIGHTNESS)
        return bytes([
            C.HEADER,
            C.CMD_SET_LED_BRIGHTNESS,
            0x03,
            clamped,
            1 if body_light else 0,
            1 if projection else 0,
        ])

    @staticmethod
    def request_led_brightness() -> bytes:
        return bytes([C.HEADER, C.CMD_REQ_LED_BRIGHTNESS, 0x00])

    @staticmethod
    def request_led_package_info() -> bytes:
        return bytes([C.HEADER, C.CMD_REQ_LED_PACKAGE_INFO, 0x00])

    @staticmethod
    def set_led_package(
        package_id: int,
        active_patterns: list[int],
        all_patterns: list[int],
        color_effect: int,
        red: int,
        green: int,
        blue: int,
    ) -> bytes:
        all_count = len(all_patterns)
        active_count = len(active_patterns)
        length = all_count + 7

        data = bytearray([
            C.HEADER,
            C.CMD_SET_LED_PACKAGE,
            length,
            package_id,
            active_count,
            all_count,
        ])
        data.extend(all_patterns)
        data.extend([color_effect, red, green, blue])
        return bytes(data)

    @staticmethod
    def parse(data: bytes | bytearray) -> Response | None:
        if len(data) < 3 or data[0] != C.HEADER:
            return None
        command_id = data[1]
        length = data[2]
        if len(data) < 3 + length:
            return None
        payload = bytes(data[3 : 3 + length])
        return Response(command_id=command_id, payload=payload)

    @staticmethod
    def parse_brightness_state(data: bytes | bytearray) -> BrightnessState | None:
        response = PulseCodec.parse(data)
        if response is None or response.command_id != C.CMD_RET_LED_BRIGHTNESS:
            return None
        if len(response.payload) < 3:
            return None
        return BrightnessState(
            level=response.payload[0],
            body_light_on=response.payload[1] != 0,
            projection_on=response.payload[2] != 0,
        )

    @staticmethod
    def parse_selected_theme(data: bytes | bytearray) -> LEDTheme | None:
        response = PulseCodec.parse(data)
        if response is None or response.command_id != C.CMD_RET_LED_PACKAGE_INFO:
            return None
        if len(response.payload) < 2:
            return None
        try:
            return LEDTheme(response.payload[1])
        except ValueError:
            return None
