from __future__ import annotations

import asyncio
import platform
from contextlib import asynccontextmanager
from dataclasses import dataclass
from typing import AsyncIterator, Callable

from bleak import BleakClient, BleakScanner
from bleak.backends.device import BLEDevice
from bleak.backends.scanner import AdvertisementData

from pulse5.protocol.constants import PulseConstants as C


@dataclass
class DiscoveredDevice:
    address: str
    name: str
    rssi: int


async def _find_connected_peripherals(scanner: BleakScanner) -> list[DiscoveredDevice]:
    if platform.system() != "Darwin":
        return []
    try:
        import CoreBluetooth

        cbmgr = scanner._backend._manager
        service = CoreBluetooth.CBUUID.UUIDWithString_(C.SERVICE_UUID)
        peripherals = cbmgr.central_manager.retrieveConnectedPeripheralsWithServices_(
            [service]
        )
        results = []
        for p in peripherals:
            name = str(p.name()) if p.name() else "Pulse 5"
            uuid = str(p.identifier())
            results.append(DiscoveredDevice(address=uuid, name=name, rssi=0))
        return results
    except Exception:
        return []


async def scan(timeout: float = 5.0) -> list[DiscoveredDevice]:
    devices: dict[str, DiscoveredDevice] = {}

    def callback(device: BLEDevice, adv: AdvertisementData) -> None:
        name = adv.local_name or device.name or ""
        has_service = C.SERVICE_UUID.lower() in [s.lower() for s in (adv.service_uuids or [])]
        is_pulse = has_service or name.startswith(C.DEVICE_NAME_PREFIX)
        if is_pulse:
            devices[device.address] = DiscoveredDevice(
                address=device.address,
                name=name or "Unknown",
                rssi=adv.rssi if adv.rssi is not None else -100,
            )

    scanner = BleakScanner(detection_callback=callback)
    await scanner.start()

    for dev in await _find_connected_peripherals(scanner):
        devices[dev.address] = dev

    await asyncio.sleep(timeout)
    await scanner.stop()

    return sorted(devices.values(), key=lambda d: d.rssi, reverse=True)


async def _resolve_device(address: str) -> BLEDevice | str:
    if platform.system() != "Darwin":
        return address
    try:
        from Foundation import NSUUID

        scanner = BleakScanner(service_uuids=[C.SERVICE_UUID])
        await scanner.start()
        await asyncio.sleep(0.5)

        cbmgr = scanner._backend._manager
        cm = cbmgr.central_manager

        ns_uuid = NSUUID.alloc().initWithUUIDString_(address)
        peripherals = cm.retrievePeripheralsWithIdentifiers_([ns_uuid])

        await scanner.stop()

        if peripherals and len(peripherals) > 0:
            peripheral = peripherals[0]
            return BLEDevice(
                address=str(peripheral.identifier()),
                name=str(peripheral.name()) if peripheral.name() else "Pulse 5",
                details=(peripheral, cbmgr),
            )
    except Exception:
        pass
    return address


@asynccontextmanager
async def connect(address: str) -> AsyncIterator[BleakClient]:
    last_error: Exception | None = None
    device = await _resolve_device(address)

    for attempt in range(C.MAX_RECONNECT_ATTEMPTS):
        try:
            client = BleakClient(device)
            await client.connect()
            try:
                yield client
            finally:
                if client.is_connected:
                    await client.disconnect()
            return
        except Exception as e:
            last_error = e
            if attempt < C.MAX_RECONNECT_ATTEMPTS - 1:
                delay = C.BASE_RECONNECT_DELAY * (2 ** attempt)
                await asyncio.sleep(delay)

    raise ConnectionError(
        f"Failed to connect after {C.MAX_RECONNECT_ATTEMPTS} attempts: {last_error}"
    )


async def write(client: BleakClient, data: bytes) -> None:
    char = client.services.get_characteristic(C.WRITE_CHAR_UUID)
    if char is None:
        raise RuntimeError(f"Write characteristic {C.WRITE_CHAR_UUID} not found")
    response = "write" in char.properties
    await client.write_gatt_char(char, data, response=response)


async def subscribe(client: BleakClient, callback: Callable[[bytearray], None]) -> None:
    char = client.services.get_characteristic(C.READ_CHAR_UUID)
    if char is None:
        raise RuntimeError(f"Read characteristic {C.READ_CHAR_UUID} not found")

    def handler(_sender: int, data: bytearray) -> None:
        callback(data)

    await client.start_notify(char, handler)
