from __future__ import annotations

import json
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "pulse5"
CONFIG_FILE = CONFIG_DIR / "config.json"


def _load() -> dict:
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text())
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def _save(data: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(data, indent=2) + "\n")


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
