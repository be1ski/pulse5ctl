# pulse5ctl

[![PyPI](https://img.shields.io/pypi/v/pulse5ctl)](https://pypi.org/project/pulse5ctl/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Control JBL Pulse 5 speaker LED lights over BLE.

<img src=".github/preview.png" width="360">

## Features

- **Themes & patterns** -- switch between 5 LED themes and 21 individual patterns
- **Brightness control** -- adjust LED brightness (20-80)
- **BLE scanning** -- discover nearby speakers with auto-save of last device
- **Status queries** -- read current brightness and active theme
- **Three interfaces** -- macOS menu bar app, CLI, and MCP server

## Installation

### CLI (recommended)

```sh
pipx install pulse5ctl
```

Requires Python 3.10+. Uses [Bleak](https://github.com/hbldh/bleak) for cross-platform BLE.

### macOS App

```sh
swift build
.build/debug/pulse5ctl
```

Requires Swift 5.10+ and macOS 14+. The app lives in the menu bar.

## Usage

### CLI

```sh
pulse5 scan                  # discover nearby speakers
pulse5 theme party           # set LED theme
pulse5 pattern rainbow       # set LED pattern
pulse5 brightness 60         # set brightness (20-80)
pulse5 status                # query current state
pulse5 version               # show installed version
```

Use `--address` / `-a` to target a specific device. Otherwise the last scanned device is used automatically.

### Themes & Patterns

| Theme | Patterns |
|-------|----------|
| Nature | Campfire, Northern Lights, Sea Wave, Universe |
| Party | Strobe, Equalizer, Geometry, Spin, Rainbow |
| Spiritual | Dynamic Wave, Lava, Focus |
| Cocktail | Fruit Gin, Mojito, Tequila, Cherry |
| Weather | Sky Sunny, Rain, Snow, Thunder, Cloud |

### MCP Server

Register as an MCP tool server for AI assistants:

```sh
# Claude Code
claude mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp

# Codex
codex mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp
```

Exposes tools: `pulse5_scan`, `pulse5_theme`, `pulse5_pattern`, `pulse5_brightness`, `pulse5_status`.

## Architecture

```
Sources/               Swift macOS menu bar app
  core/elm/            Elm-inspired state management (Reducer, Effects, EffectHandler)
  core/platform/       App environment abstractions
  feature/pulse/       BLE protocol, domain models, and presentation reducers
  app/macos/           Menu bar entry point and popover UI

cli/pulse5/            Python CLI & MCP server
  cli.py               Click-based CLI commands
  mcp_server.py        FastMCP tool server (wraps the CLI)
  ble.py               BLE scanning and connection via Bleak
  protocol/            Shared BLE protocol: constants, codec, models
```

The Swift app uses an **Elm architecture** -- unidirectional data flow with pure reducers, side effects as commands, and async effect handlers. The Python CLI shares the same BLE protocol implementation (service UUIDs, command bytes, packet codec).

## Development

### Swift

```sh
swift build            # build
swift run              # build & run menu bar app
```

### Python

```sh
cd cli
pip install -e ".[dev]"
pytest                 # run tests
```

## License

[MIT](LICENSE)
