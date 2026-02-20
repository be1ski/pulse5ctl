"""Tests for the pulse5.cli module.

Uses click.testing.CliRunner and mocks to avoid real BLE hardware.
"""

from __future__ import annotations

from contextlib import asynccontextmanager
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from click.testing import CliRunner

from pulse5.ble import DiscoveredDevice
from pulse5.cli import _get_address, cli


@pytest.fixture
def runner():
    return CliRunner()


# ---------------------------------------------------------------------------
# version command
# ---------------------------------------------------------------------------


class TestVersionCommand:
    def test_version_displays_package_version(self, runner):
        """The version command should print the installed package version."""
        with patch("pulse5.cli.pkg_version", return_value="1.3.2"):
            result = runner.invoke(cli, ["version"])
        assert result.exit_code == 0
        assert "1.3.2" in result.output


# ---------------------------------------------------------------------------
# scan command
# ---------------------------------------------------------------------------


class TestScanCommand:
    def test_scan_finds_devices(self, runner):
        """scan should list discovered devices and save the best one."""
        devices = [
            DiscoveredDevice(address="AA:BB:CC:DD:EE:01", name="JBL Pulse 5", rssi=-30),
            DiscoveredDevice(address="AA:BB:CC:DD:EE:02", name="JBL Pulse 5 Far", rssi=-70),
        ]

        async def mock_scan(timeout=5.0):
            return devices

        with patch("pulse5.cli.ble.scan", side_effect=mock_scan), \
             patch("pulse5.cli.config.save_device") as mock_save:
            result = runner.invoke(cli, ["scan"])

        assert result.exit_code == 0
        assert "Found 2 device(s)" in result.output
        assert "JBL Pulse 5" in result.output
        assert "AA:BB:CC:DD:EE:01" in result.output
        assert "-30 dBm" in result.output
        mock_save.assert_called_once_with("AA:BB:CC:DD:EE:01", "JBL Pulse 5")

    def test_scan_no_devices(self, runner):
        """scan should display a message when no devices are found."""

        async def mock_scan(timeout=5.0):
            return []

        with patch("pulse5.cli.ble.scan", side_effect=mock_scan):
            result = runner.invoke(cli, ["scan"])

        assert result.exit_code == 0
        assert "No Pulse 5 speakers found" in result.output

    def test_scan_custom_timeout(self, runner):
        """scan should pass the --timeout value to ble.scan."""
        captured_timeout = None

        async def mock_scan(timeout=5.0):
            nonlocal captured_timeout
            captured_timeout = timeout
            return []

        with patch("pulse5.cli.ble.scan", side_effect=mock_scan):
            result = runner.invoke(cli, ["scan", "--timeout", "10"])

        assert result.exit_code == 0
        assert captured_timeout == 10.0

    def test_scan_saves_strongest_device(self, runner):
        """scan should save the first device (sorted by strongest RSSI)."""
        devices = [
            DiscoveredDevice(address="STRONG", name="P5 Close", rssi=-20),
            DiscoveredDevice(address="WEAK", name="P5 Far", rssi=-90),
        ]

        async def mock_scan(timeout=5.0):
            return devices

        with patch("pulse5.cli.ble.scan", side_effect=mock_scan), \
             patch("pulse5.cli.config.save_device") as mock_save:
            result = runner.invoke(cli, ["scan"])

        assert result.exit_code == 0
        mock_save.assert_called_once_with("STRONG", "P5 Close")
        assert "Saved" in result.output


# ---------------------------------------------------------------------------
# brightness command
# ---------------------------------------------------------------------------


class TestBrightnessCommand:
    def test_brightness_set(self, runner):
        """brightness command should connect and write the brightness packet."""
        written_data = []

        @asynccontextmanager
        async def mock_connect(address):
            yield MagicMock()

        async def mock_write(client, data):
            written_data.append(data)

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.config.get_saved_device", return_value=("AA:BB:CC", "Pulse 5")):
            result = runner.invoke(cli, ["brightness", "60"])

        assert result.exit_code == 0
        assert "Brightness set to 60" in result.output
        assert len(written_data) == 1

    def test_brightness_with_explicit_address(self, runner):
        """brightness should use the --address option when provided."""
        connected_address = None

        @asynccontextmanager
        async def mock_connect(address):
            nonlocal connected_address
            connected_address = address
            yield MagicMock()

        async def mock_write(client, data):
            pass

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.write", side_effect=mock_write):
            result = runner.invoke(cli, ["--address", "XX:YY:ZZ", "brightness", "50"])

        assert result.exit_code == 0
        assert connected_address == "XX:YY:ZZ"

    def test_brightness_out_of_range(self, runner):
        """brightness below 20 or above 80 should be rejected by Click."""
        result = runner.invoke(cli, ["brightness", "10"])
        assert result.exit_code != 0

        result = runner.invoke(cli, ["brightness", "100"])
        assert result.exit_code != 0

    def test_brightness_no_device(self, runner):
        """brightness without address or saved device should error."""
        with patch("pulse5.cli.config.get_saved_device", return_value=None):
            result = runner.invoke(cli, ["brightness", "50"])

        assert result.exit_code != 0


# ---------------------------------------------------------------------------
# theme command
# ---------------------------------------------------------------------------


class TestThemeCommand:
    def test_theme_set_nature(self, runner):
        """theme command should connect and write the theme switch packet."""
        written_data = []

        @asynccontextmanager
        async def mock_connect(address):
            yield MagicMock()

        async def mock_write(client, data):
            written_data.append(data)

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.config.get_saved_device", return_value=("AA:BB:CC", "Pulse 5")):
            result = runner.invoke(cli, ["theme", "nature"])

        assert result.exit_code == 0
        assert "Theme set to Nature" in result.output
        assert len(written_data) == 1

    def test_theme_set_party(self, runner):
        """theme party should work correctly."""
        @asynccontextmanager
        async def mock_connect(address):
            yield MagicMock()

        async def mock_write(client, data):
            pass

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.config.get_saved_device", return_value=("AA:BB:CC", "Pulse 5")):
            result = runner.invoke(cli, ["theme", "party"])

        assert result.exit_code == 0
        assert "Theme set to Party" in result.output

    def test_theme_invalid_name(self, runner):
        """An invalid theme name should be rejected by Click."""
        result = runner.invoke(cli, ["theme", "nonexistent"])
        assert result.exit_code != 0

    def test_theme_no_device(self, runner):
        """theme without address or saved device should error."""
        with patch("pulse5.cli.config.get_saved_device", return_value=None):
            result = runner.invoke(cli, ["theme", "nature"])

        assert result.exit_code != 0


# ---------------------------------------------------------------------------
# pattern command
# ---------------------------------------------------------------------------


class TestPatternCommand:
    def test_pattern_set_campfire(self, runner):
        """pattern command should connect and write the pattern packet."""
        written_data = []

        @asynccontextmanager
        async def mock_connect(address):
            yield MagicMock()

        async def mock_write(client, data):
            written_data.append(data)

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.config.get_saved_device", return_value=("AA:BB:CC", "Pulse 5")):
            result = runner.invoke(cli, ["pattern", "campfire"])

        assert result.exit_code == 0
        assert "Pattern set to Campfire" in result.output
        assert len(written_data) == 1

    def test_pattern_set_rainbow(self, runner):
        """pattern rainbow should work correctly."""
        @asynccontextmanager
        async def mock_connect(address):
            yield MagicMock()

        async def mock_write(client, data):
            pass

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.config.get_saved_device", return_value=("AA:BB:CC", "Pulse 5")):
            result = runner.invoke(cli, ["pattern", "rainbow"])

        assert result.exit_code == 0
        assert "Pattern set to Rainbow" in result.output

    def test_pattern_invalid_name(self, runner):
        """An invalid pattern name should be rejected by Click."""
        result = runner.invoke(cli, ["pattern", "invalid_pattern_name"])
        assert result.exit_code != 0

    def test_pattern_no_device(self, runner):
        """pattern without address or saved device should error."""
        with patch("pulse5.cli.config.get_saved_device", return_value=None):
            result = runner.invoke(cli, ["pattern", "campfire"])

        assert result.exit_code != 0


# ---------------------------------------------------------------------------
# status command
# ---------------------------------------------------------------------------


class TestStatusCommand:
    def test_status_displays_brightness_and_theme(self, runner):
        """status should display brightness level and theme name."""
        @asynccontextmanager
        async def mock_connect(address):
            yield MagicMock()

        async def mock_subscribe(client, callback):
            # Simulate notification responses
            # Brightness response
            callback(bytearray([0xAA, 0x8C, 0x03, 50, 1, 1]))
            # Theme response (Nature = 0x01)
            callback(bytearray([0xAA, 0x84, 0x02, 0x00, 0x01]))

        async def mock_write(client, data):
            pass

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.subscribe", side_effect=mock_subscribe), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.asyncio.sleep", new_callable=AsyncMock), \
             patch("pulse5.cli.config.get_saved_device", return_value=("AA:BB:CC", "Pulse 5")):
            result = runner.invoke(cli, ["status"])

        assert result.exit_code == 0
        assert "Speaker Status:" in result.output
        assert "Brightness: 50" in result.output
        assert "Nature" in result.output

    def test_status_no_device(self, runner):
        """status without address or saved device should error."""
        with patch("pulse5.cli.config.get_saved_device", return_value=None):
            result = runner.invoke(cli, ["status"])

        assert result.exit_code != 0

    def test_status_with_explicit_address(self, runner):
        """status should use the --address option when provided."""
        connected_address = None

        @asynccontextmanager
        async def mock_connect(address):
            nonlocal connected_address
            connected_address = address
            yield MagicMock()

        async def mock_subscribe(client, callback):
            pass

        async def mock_write(client, data):
            pass

        with patch("pulse5.cli.ble.connect", side_effect=mock_connect), \
             patch("pulse5.cli.ble.subscribe", side_effect=mock_subscribe), \
             patch("pulse5.cli.ble.write", side_effect=mock_write), \
             patch("pulse5.cli.asyncio.sleep", new_callable=AsyncMock), \
             patch("pulse5.cli.config.get_saved_device", return_value=None):
            result = runner.invoke(cli, ["--address", "XX:YY:ZZ", "status"])

        assert result.exit_code == 0
        assert connected_address == "XX:YY:ZZ"


# ---------------------------------------------------------------------------
# _get_address helper
# ---------------------------------------------------------------------------


class TestGetAddress:
    def test_returns_explicit_address(self):
        """When an address is provided, it should be returned as-is."""
        assert _get_address("AA:BB:CC") == "AA:BB:CC"

    def test_returns_saved_device(self):
        """When no address is provided, fall back to saved device."""
        with patch("pulse5.cli.config.get_saved_device", return_value=("SAVED:ADDR", "My Speaker")):
            assert _get_address(None) == "SAVED:ADDR"

    def test_exits_when_no_device(self):
        """When no address and no saved device, sys.exit(1) should be called."""
        with patch("pulse5.cli.config.get_saved_device", return_value=None):
            with pytest.raises(SystemExit) as exc_info:
                _get_address(None)
            assert exc_info.value.code == 1


# ---------------------------------------------------------------------------
# cli group
# ---------------------------------------------------------------------------


class TestCliGroup:
    def test_cli_help(self, runner):
        """The CLI group should show help text."""
        result = runner.invoke(cli, ["--help"])
        assert result.exit_code == 0
        assert "Control Pulse 5 speaker LEDs" in result.output

    def test_cli_unknown_command(self, runner):
        """An unknown command should produce a usage error."""
        result = runner.invoke(cli, ["nonexistent"])
        assert result.exit_code != 0
