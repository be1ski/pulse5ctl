# pulse5ctl

Control Pulse 5 speaker LED lights over BLE.

<img src=".github/preview.png" width="360">

## macOS App

```sh
swift build && .build/debug/pulse5ctl
```

## CLI

```sh
pipx install pulse5ctl
```

<pre>
Usage: pulse5 [OPTIONS] COMMAND [ARGS]...

  Control Pulse 5 speaker LEDs over Bluetooth.

Options:
  -a, --address TEXT  Device BLE address.
  --help              Show this message and exit.

Commands:
  brightness  Set brightness level (20-80).
  pattern     Set an LED pattern.
  scan        Discover nearby Pulse 5 speakers.
  status      Query current speaker state.
  theme       Set LED theme.
  version     Show installed version.
</pre>

## MCP

Add the MCP server so your AI coding agent can control the speaker directly:

```sh
# Claude Code
claude mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp

# Codex
codex mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp
```

Or add it manually to your MCP config JSON:

```json
{
  "pulse5": {
    "command": "uvx",
    "args": ["--from", "pulse5ctl", "pulse5-mcp"]
  }
}
```

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `pulse5_scan` | Discover nearby Pulse 5 speakers via BLE | `timeout` (number, default `5`) -- scan duration in seconds |
| `pulse5_brightness` | Set speaker LED brightness | `level` (integer, **required**) -- value between 20 and 80 |
| `pulse5_theme` | Set LED theme | `name` (string, **required**) -- one of `nature`, `party`, `spiritual`, `cocktail`, `weather` |
| `pulse5_pattern` | Set LED pattern | `name` (string, **required**) -- e.g. `campfire`, `northern lights`, `rainbow`, `lava`, `rain` ([full list](#patterns)) |
| `pulse5_status` | Query current speaker state (brightness, theme) | *none* |

<details id="patterns">
<summary>All available patterns</summary>

campfire, northern lights, sea wave, universe, strobe, equalizer, geometry, spin, rainbow, dynamic wave, lava, focus, sky sunny, rain, snow, thunder, cloud, fruit gin, mojito, tequila, cherry
</details>
