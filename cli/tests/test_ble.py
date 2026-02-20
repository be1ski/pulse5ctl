"""Tests for the pulse5.ble module.

All BLE hardware interaction is mocked via unittest.mock.
"""

from __future__ import annotations

import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from pulse5.ble import DiscoveredDevice, connect, scan, subscribe, write
from pulse5.protocol.constants import PulseConstants as C


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_ble_device(address: str, name: str | None = None) -> MagicMock:
    """Create a mock BLEDevice."""
    dev = MagicMock()
    dev.address = address
    dev.name = name
    return dev


def _make_adv_data(
    local_name: str | None = None,
    rssi: int | None = -60,
    service_uuids: list[str] | None = None,
) -> MagicMock:
    """Create a mock AdvertisementData."""
    adv = MagicMock()
    adv.local_name = local_name
    adv.rssi = rssi
    adv.service_uuids = service_uuids or []
    return adv


def _make_characteristic(uuid: str, properties: list[str] | None = None) -> MagicMock:
    """Create a mock BleakGATTCharacteristic."""
    char = MagicMock()
    char.uuid = uuid
    char.properties = properties or ["write-without-response"]
    return char


def _make_mock_client() -> MagicMock:
    """Create a mock BleakClient with a MagicMock services attribute.

    Using MagicMock (not AsyncMock) ensures that
    ``client.services.get_characteristic(uuid)`` returns a plain value
    instead of a coroutine.
    """
    client = AsyncMock()
    client.services = MagicMock()
    return client


def _fake_scanner_factory(callbacks_to_fire: list[tuple[MagicMock, MagicMock]] | None = None):
    """Return a FakeScanner class that fires detection callbacks during start().

    ``callbacks_to_fire`` is a list of ``(device, advertisement_data)`` tuples
    that will be passed to the detection callback when ``start()`` is called.
    """
    fired = callbacks_to_fire or []

    class FakeScanner:
        def __init__(self, detection_callback=None):
            self._callback = detection_callback
            self._backend = MagicMock()

        async def start(self):
            if self._callback:
                for device, adv in fired:
                    self._callback(device, adv)

        async def stop(self):
            pass

    return FakeScanner


# ---------------------------------------------------------------------------
# scan()
# ---------------------------------------------------------------------------


class TestScan:
    @pytest.mark.asyncio
    async def test_scan_discovers_device_by_service_uuid(self):
        """A device advertising the Pulse 5 service UUID should be discovered."""
        device = _make_ble_device("AA:BB:CC:DD:EE:FF", "JBL Pulse 5")
        adv = _make_adv_data(
            local_name="JBL Pulse 5",
            rssi=-45,
            service_uuids=[C.SERVICE_UUID],
        )
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].address == "AA:BB:CC:DD:EE:FF"
        assert result[0].name == "JBL Pulse 5"
        assert result[0].rssi == -45

    @pytest.mark.asyncio
    async def test_scan_discovers_device_by_name_prefix(self):
        """A device whose name starts with DEVICE_NAME_PREFIX should be discovered."""
        device = _make_ble_device("11:22:33:44:55:66", "JBL Pulse 5")
        adv = _make_adv_data(local_name="JBL Pulse 5", rssi=-50, service_uuids=[])
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].name == "JBL Pulse 5"

    @pytest.mark.asyncio
    async def test_scan_ignores_non_pulse_device(self):
        """Devices without the service UUID or name prefix should be ignored."""
        device = _make_ble_device("99:88:77:66:55:44", "SomeOtherDevice")
        adv = _make_adv_data(local_name="SomeOtherDevice", rssi=-70, service_uuids=[])
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert result == []

    @pytest.mark.asyncio
    async def test_scan_sorts_by_rssi_descending(self):
        """Returned devices should be sorted by RSSI, strongest first."""
        dev1 = _make_ble_device("AA:AA:AA:AA:AA:01")
        adv1 = _make_adv_data(local_name="JBL Pulse 5 Far", rssi=-80, service_uuids=[C.SERVICE_UUID])

        dev2 = _make_ble_device("AA:AA:AA:AA:AA:02")
        adv2 = _make_adv_data(local_name="JBL Pulse 5 Close", rssi=-30, service_uuids=[C.SERVICE_UUID])

        dev3 = _make_ble_device("AA:AA:AA:AA:AA:03")
        adv3 = _make_adv_data(local_name="JBL Pulse 5 Mid", rssi=-55, service_uuids=[C.SERVICE_UUID])

        Scanner = _fake_scanner_factory([(dev1, adv1), (dev2, adv2), (dev3, adv3)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 3
        assert result[0].rssi == -30
        assert result[1].rssi == -55
        assert result[2].rssi == -80

    @pytest.mark.asyncio
    async def test_scan_deduplicates_by_address(self):
        """If the same address is reported twice, only the latest entry is kept."""
        device = _make_ble_device("AA:BB:CC:DD:EE:FF")
        adv1 = _make_adv_data(local_name="JBL Pulse 5", rssi=-60, service_uuids=[C.SERVICE_UUID])
        adv2 = _make_adv_data(local_name="JBL Pulse 5", rssi=-40, service_uuids=[C.SERVICE_UUID])
        Scanner = _fake_scanner_factory([(device, adv1), (device, adv2)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].rssi == -40

    @pytest.mark.asyncio
    async def test_scan_null_rssi_defaults_to_minus_100(self):
        """If advertisement RSSI is None, it should default to -100."""
        device = _make_ble_device("AA:BB:CC:DD:EE:FF")
        adv = _make_adv_data(local_name="JBL Pulse 5", rssi=None, service_uuids=[C.SERVICE_UUID])
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].rssi == -100

    @pytest.mark.asyncio
    async def test_scan_no_devices_returns_empty(self):
        """When no Pulse 5 devices are found, an empty list is returned."""
        Scanner = _fake_scanner_factory([])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert result == []

    @pytest.mark.asyncio
    async def test_scan_missing_local_name_uses_device_name(self):
        """When local_name is None, fallback to device.name."""
        device = _make_ble_device("AA:BB:CC:DD:EE:FF", "JBL Pulse 5")
        adv = _make_adv_data(local_name=None, rssi=-50, service_uuids=[C.SERVICE_UUID])
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].name == "JBL Pulse 5"

    @pytest.mark.asyncio
    async def test_scan_no_name_at_all_uses_unknown(self):
        """When both local_name and device.name are falsy, name defaults to 'Unknown'."""
        device = _make_ble_device("AA:BB:CC:DD:EE:FF", None)
        device.name = None
        adv = _make_adv_data(local_name=None, rssi=-50, service_uuids=[C.SERVICE_UUID])
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].name == "Unknown"

    @pytest.mark.asyncio
    async def test_scan_includes_connected_peripherals(self):
        """Connected peripherals from _find_connected_peripherals should be included."""
        connected = [DiscoveredDevice(address="CONN:ADDR", name="Connected P5", rssi=0)]
        Scanner = _fake_scanner_factory([])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=connected), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1
        assert result[0].address == "CONN:ADDR"
        assert result[0].name == "Connected P5"

    @pytest.mark.asyncio
    async def test_scan_case_insensitive_service_uuid(self):
        """Service UUID matching should be case insensitive."""
        device = _make_ble_device("AA:BB:CC:DD:EE:FF")
        adv = _make_adv_data(
            local_name="SomeName",
            rssi=-50,
            service_uuids=[C.SERVICE_UUID.upper()],
        )
        Scanner = _fake_scanner_factory([(device, adv)])

        with patch("pulse5.ble.BleakScanner", Scanner), \
             patch("pulse5.ble._find_connected_peripherals", new_callable=AsyncMock, return_value=[]), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            result = await scan(timeout=0.0)

        assert len(result) == 1


# ---------------------------------------------------------------------------
# connect()
# ---------------------------------------------------------------------------


class TestConnect:
    @pytest.mark.asyncio
    async def test_connect_success(self):
        """Successful connection should yield a connected client."""
        mock_client = AsyncMock()
        mock_client.is_connected = True

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", return_value=mock_client):
            async with connect("AA:BB:CC") as client:
                assert client is mock_client

        mock_client.connect.assert_awaited_once()
        mock_client.disconnect.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_connect_disconnects_on_exit(self):
        """Client should be disconnected when exiting the context manager."""
        mock_client = AsyncMock()
        mock_client.is_connected = True

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", return_value=mock_client):
            async with connect("AA:BB:CC") as client:
                pass

        mock_client.disconnect.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_connect_skips_disconnect_when_not_connected(self):
        """If client is no longer connected at exit, skip disconnect."""
        mock_client = AsyncMock()
        mock_client.is_connected = False

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", return_value=mock_client):
            async with connect("AA:BB:CC") as client:
                pass

        mock_client.disconnect.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_connect_retry_on_failure(self):
        """Should retry on connection failure and succeed on second attempt."""
        failing_client = AsyncMock()
        failing_client.connect = AsyncMock(side_effect=ConnectionError("BLE failed"))

        success_client = AsyncMock()
        success_client.is_connected = True

        call_count = 0

        def make_client(device):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return failing_client
            return success_client

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", side_effect=make_client), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            async with connect("AA:BB:CC") as client:
                assert client is success_client

    @pytest.mark.asyncio
    async def test_connect_max_retries_exceeded(self):
        """Should raise ConnectionError after all retry attempts are exhausted."""
        mock_client = AsyncMock()
        mock_client.connect = AsyncMock(side_effect=ConnectionError("BLE failed"))

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", return_value=mock_client), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            with pytest.raises(ConnectionError, match="Failed to connect after"):
                async with connect("AA:BB:CC") as client:
                    pass

        assert mock_client.connect.await_count == C.MAX_RECONNECT_ATTEMPTS

    @pytest.mark.asyncio
    async def test_connect_retry_uses_exponential_backoff(self):
        """Retry delay should follow exponential backoff pattern."""
        mock_client = AsyncMock()
        mock_client.connect = AsyncMock(side_effect=ConnectionError("BLE failed"))

        sleep_calls: list[float] = []

        async def record_sleep(delay):
            sleep_calls.append(delay)

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", return_value=mock_client), \
             patch("pulse5.ble.asyncio.sleep", side_effect=record_sleep):
            with pytest.raises(ConnectionError):
                async with connect("AA:BB:CC") as client:
                    pass

        # With MAX_RECONNECT_ATTEMPTS=3, there are 2 retries with exponential backoff
        expected = [C.BASE_RECONNECT_DELAY * (2 ** i) for i in range(C.MAX_RECONNECT_ATTEMPTS - 1)]
        assert sleep_calls == expected

    @pytest.mark.asyncio
    async def test_connect_error_message_includes_last_error(self):
        """ConnectionError message should include the original error details."""
        mock_client = AsyncMock()
        mock_client.connect = AsyncMock(side_effect=OSError("Device unreachable"))

        with patch("pulse5.ble._resolve_device", new_callable=AsyncMock, return_value="AA:BB:CC"), \
             patch("pulse5.ble.BleakClient", return_value=mock_client), \
             patch("pulse5.ble.asyncio.sleep", new_callable=AsyncMock):
            with pytest.raises(ConnectionError, match="Device unreachable"):
                async with connect("AA:BB:CC") as client:
                    pass


# ---------------------------------------------------------------------------
# write()
# ---------------------------------------------------------------------------


class TestWrite:
    @pytest.mark.asyncio
    async def test_write_calls_write_gatt_char(self):
        """write() should find the characteristic and call write_gatt_char."""
        char = _make_characteristic(C.WRITE_CHAR_UUID, ["write-without-response"])
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = char

        data = b"\xAA\x8A\x03\x3C\x01\x01"
        await write(mock_client, data)

        mock_client.services.get_characteristic.assert_called_once_with(C.WRITE_CHAR_UUID)
        mock_client.write_gatt_char.assert_awaited_once_with(char, data, response=False)

    @pytest.mark.asyncio
    async def test_write_with_response_property(self):
        """If characteristic has 'write' property, response should be True."""
        char = _make_characteristic(C.WRITE_CHAR_UUID, ["write"])
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = char

        data = b"\xAA\x8A\x03\x3C\x01\x01"
        await write(mock_client, data)

        mock_client.write_gatt_char.assert_awaited_once_with(char, data, response=True)

    @pytest.mark.asyncio
    async def test_write_characteristic_not_found(self):
        """Should raise RuntimeError when write characteristic is missing."""
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = None

        with pytest.raises(RuntimeError, match="Write characteristic"):
            await write(mock_client, b"\xAA\x8A\x03\x3C\x01\x01")

    @pytest.mark.asyncio
    async def test_write_with_both_properties(self):
        """If 'write' is among multiple properties, response should be True."""
        char = _make_characteristic(C.WRITE_CHAR_UUID, ["write", "write-without-response"])
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = char

        await write(mock_client, b"\xAA\x90\x01\x02")

        mock_client.write_gatt_char.assert_awaited_once_with(
            char, b"\xAA\x90\x01\x02", response=True
        )


# ---------------------------------------------------------------------------
# subscribe()
# ---------------------------------------------------------------------------


class TestSubscribe:
    @pytest.mark.asyncio
    async def test_subscribe_starts_notify(self):
        """subscribe() should find the read characteristic and call start_notify."""
        char = _make_characteristic(C.READ_CHAR_UUID, ["notify"])
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = char

        callback = MagicMock()
        await subscribe(mock_client, callback)

        mock_client.services.get_characteristic.assert_called_once_with(C.READ_CHAR_UUID)
        mock_client.start_notify.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_subscribe_handler_invokes_callback(self):
        """The notification handler should forward data to the user callback."""
        char = _make_characteristic(C.READ_CHAR_UUID, ["notify"])
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = char

        received: list[bytearray] = []

        def user_callback(data: bytearray) -> None:
            received.append(data)

        # Capture the handler passed to start_notify and simulate a notification
        async def capture_start_notify(characteristic, handler):
            handler(0, bytearray(b"\xAA\x8C\x03\x32\x01\x01"))

        mock_client.start_notify = capture_start_notify

        await subscribe(mock_client, user_callback)

        assert len(received) == 1
        assert received[0] == bytearray(b"\xAA\x8C\x03\x32\x01\x01")

    @pytest.mark.asyncio
    async def test_subscribe_characteristic_not_found(self):
        """Should raise RuntimeError when read characteristic is missing."""
        mock_client = _make_mock_client()
        mock_client.services.get_characteristic.return_value = None

        with pytest.raises(RuntimeError, match="Read characteristic"):
            await subscribe(mock_client, MagicMock())


# ---------------------------------------------------------------------------
# DiscoveredDevice
# ---------------------------------------------------------------------------


class TestDiscoveredDevice:
    def test_dataclass_fields(self):
        """DiscoveredDevice should be a simple dataclass with expected fields."""
        dev = DiscoveredDevice(address="AA:BB:CC", name="Pulse 5", rssi=-50)
        assert dev.address == "AA:BB:CC"
        assert dev.name == "Pulse 5"
        assert dev.rssi == -50

    def test_equality(self):
        """Two DiscoveredDevice instances with the same fields should be equal."""
        d1 = DiscoveredDevice(address="AA:BB", name="P5", rssi=-42)
        d2 = DiscoveredDevice(address="AA:BB", name="P5", rssi=-42)
        assert d1 == d2

    def test_inequality(self):
        """DiscoveredDevice instances with different fields should not be equal."""
        d1 = DiscoveredDevice(address="AA:BB", name="P5", rssi=-42)
        d2 = DiscoveredDevice(address="CC:DD", name="P5", rssi=-42)
        assert d1 != d2
