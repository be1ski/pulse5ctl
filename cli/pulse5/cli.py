from __future__ import annotations

import asyncio
import sys

import click

from pulse5 import ble, config
from pulse5.protocol.codec import PulseCodec
from pulse5.protocol.models import PATTERN_BY_NAME, THEME_BY_NAME, ColorEffect


def _run(coro):
    return asyncio.run(coro)


def _get_address(address: str | None) -> str:
    if address:
        return address
    saved = config.get_saved_device()
    if saved:
        return saved[0]
    click.echo("Error: No device specified. Run 'pulse5 scan' first or pass --address.", err=True)
    sys.exit(1)


@click.group()
@click.option("--address", "-a", default=None, help="Device BLE address.")
@click.pass_context
def cli(ctx: click.Context, address: str | None) -> None:
    """Control JBL Pulse 5 speaker LEDs over Bluetooth."""
    ctx.ensure_object(dict)
    ctx.obj["address"] = address


@cli.command()
@click.option("--timeout", "-t", default=5.0, help="Scan duration in seconds.")
def scan(timeout: float) -> None:
    """Discover nearby JBL Pulse 5 speakers."""

    async def _scan():
        click.echo(f"Scanning for {timeout}s...")
        devices = await ble.scan(timeout=timeout)
        if not devices:
            click.echo("No JBL Pulse 5 speakers found.")
            return
        click.echo(f"Found {len(devices)} device(s):\n")
        for d in devices:
            click.echo(f"  {d.name}")
            click.echo(f"    Address: {d.address}")
            click.echo(f"    RSSI:    {d.rssi} dBm")
            click.echo()
        best = devices[0]
        config.save_device(best.address, best.name)
        click.echo(f"Saved '{best.name}' ({best.address}) as default device.")

    _run(_scan())


@cli.command()
@click.argument("level", type=click.IntRange(20, 80))
@click.pass_context
def brightness(ctx: click.Context, level: int) -> None:
    """Set brightness level (20-80)."""
    address = _get_address(ctx.obj["address"])

    async def _cmd():
        async with ble.connect(address) as client:
            await ble.write(client, PulseCodec.set_led_brightness(level))
            click.echo(f"Brightness set to {level}.")

    _run(_cmd())


@cli.command()
@click.argument("name", type=click.Choice(list(THEME_BY_NAME.keys()), case_sensitive=False))
@click.pass_context
def theme(ctx: click.Context, name: str) -> None:
    """Set LED theme."""
    address = _get_address(ctx.obj["address"])
    t = THEME_BY_NAME[name.lower()]

    async def _cmd():
        async with ble.connect(address) as client:
            await ble.write(client, PulseCodec.switch_package(t.value))
            click.echo(f"Theme set to {t.display_name}.")

    _run(_cmd())


@cli.command()
@click.argument("name", type=click.Choice(list(PATTERN_BY_NAME.keys()), case_sensitive=False))
@click.pass_context
def pattern(ctx: click.Context, name: str) -> None:
    """Set an LED pattern."""
    address = _get_address(ctx.obj["address"])
    p = PATTERN_BY_NAME[name.lower()]
    t = p.theme
    all_pats = [pat.value for pat in t.patterns]
    ordered = [p.value] + [v for v in all_pats if v != p.value]

    async def _cmd():
        async with ble.connect(address) as client:
            await ble.write(client, PulseCodec.set_led_package(
                package_id=t.value,
                active_patterns=[p.value],
                all_patterns=ordered,
                color_effect=ColorEffect.COLOR_LOOP.value,
                red=0xFF, green=0xFF, blue=0xFF,
            ))
            click.echo(f"Pattern set to {p.display_name}.")

    _run(_cmd())


@cli.command()
@click.pass_context
def status(ctx: click.Context) -> None:
    """Query current speaker state."""
    address = _get_address(ctx.obj["address"])

    async def _cmd():
        results: dict[str, object] = {}

        def on_notify(data: bytearray) -> None:
            brt = PulseCodec.parse_brightness_state(data)
            if brt is not None:
                results["brightness"] = brt
            thm = PulseCodec.parse_selected_theme(data)
            if thm is not None:
                results["theme"] = thm

        async with ble.connect(address) as client:
            await ble.subscribe(client, on_notify)
            await ble.write(client, PulseCodec.request_led_brightness())
            await asyncio.sleep(0.5)
            await ble.write(client, PulseCodec.request_led_package_info())
            await asyncio.sleep(0.5)

        click.echo("Speaker Status:")
        if "brightness" in results:
            brt = results["brightness"]
            click.echo(f"  Brightness: {brt.level}")
        if "theme" in results:
            click.echo(f"  Theme:      {results['theme'].display_name}")

    _run(_cmd())


def main() -> None:
    cli()


if __name__ == "__main__":
    main()
