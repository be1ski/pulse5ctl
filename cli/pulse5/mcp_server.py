from __future__ import annotations

import asyncio
import sys

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("pulse5")


async def _run_pulse5(*args: str) -> str:
    proc = await asyncio.create_subprocess_exec(
        sys.executable, "-m", "pulse5.cli", *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        stdin=asyncio.subprocess.DEVNULL,
        start_new_session=True,
    )
    stdout, stderr = await proc.communicate()
    output = stdout.decode().strip()
    if proc.returncode != 0:
        err = stderr.decode().strip()
        return f"Failed: {err or output or f'exit code {proc.returncode}'}"
    return output or "Done."


@mcp.tool()
async def pulse5_scan(timeout: float = 5) -> str:
    """Discover nearby JBL Pulse 5 speakers via BLE."""
    return await _run_pulse5("scan", "--timeout", str(timeout))


@mcp.tool()
async def pulse5_brightness(level: int) -> str:
    """Set speaker LED brightness (20-80)."""
    return await _run_pulse5("brightness", str(level))


@mcp.tool()
async def pulse5_theme(name: str) -> str:
    """Set LED theme. Options: nature, party, spiritual, cocktail, weather."""
    return await _run_pulse5("theme", name)


@mcp.tool()
async def pulse5_pattern(name: str) -> str:
    """Set LED pattern. Options: campfire, northern lights, sea wave, universe, strobe, equalizer, geometry, spin, rainbow, dynamic wave, lava, focus, sky sunny, rain, snow, thunder, cloud, fruit gin, mojito, tequila, cherry."""
    return await _run_pulse5("pattern", name)


@mcp.tool()
async def pulse5_status() -> str:
    """Query current speaker state (brightness, theme)."""
    return await _run_pulse5("status")


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
