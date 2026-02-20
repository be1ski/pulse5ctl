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

```sh
# Claude Code
claude mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp

# Codex
codex mcp add pulse5 -- uvx --from pulse5ctl pulse5-mcp
```
