# pulse5ctl

Control JBL Pulse 5 LED lights over BLE.

<img src=".github/preview.png" width="360">

## macOS App

```sh
swift build && .build/debug/pulse5ctl
```

## CLI

```sh
pipx install pulse5ctl
pulse5 scan
pulse5 theme party
pulse5 pattern rainbow
pulse5 brightness 60
```

## MCP

```sh
claude mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp
```
