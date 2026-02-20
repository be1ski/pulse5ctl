# pulse5ctl

[![PyPI](https://img.shields.io/pypi/v/pulse5ctl)](https://pypi.org/project/pulse5ctl/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Control Pulse 5 speaker LED lights over BLE.

<img src=".github/preview.png" width="360">

## macOS App

```sh
swift build && .build/debug/pulse5ctl
```

## CLI

```sh
pipx install pulse5ctl
pulse5 scan                  # discover nearby speakers
pulse5 theme party           # set LED theme
pulse5 pattern rainbow       # set LED pattern
pulse5 brightness 60         # set brightness (20-80)
pulse5 status                # query current state
pulse5 version               # show installed version
```

## MCP

```sh
# Claude Code
claude mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp

# Codex
codex mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp
```

## Development

```sh
swift build                            # build macOS app
cd cli && pip install -e . && pytest   # run Python tests
```
