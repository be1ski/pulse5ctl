from __future__ import annotations

import json
import os
from pathlib import Path


def _config_dir() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME")
    base = Path(xdg) if xdg else Path.home() / ".config"
    return base / "pulse5"


def _config_file() -> Path:
    return _config_dir() / "config.json"


def _load() -> dict:
    cfg = _config_file()
    if cfg.exists():
        try:
            return json.loads(cfg.read_text())
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def _save(data: dict) -> None:
    cfg_dir = _config_dir()
    cfg_dir.mkdir(parents=True, exist_ok=True)
    (_config_file()).write_text(json.dumps(data, indent=2) + "\n")


def get_saved_device() -> tuple[str, str] | None:
    data = _load()
    addr = data.get("address")
    name = data.get("name")
    if addr:
        return (addr, name or "Unknown")
    return None


def save_device(address: str, name: str) -> None:
    data = _load()
    data["address"] = address
    data["name"] = name
    _save(data)


def clear_device() -> None:
    data = _load()
    data.pop("address", None)
    data.pop("name", None)
    _save(data)
