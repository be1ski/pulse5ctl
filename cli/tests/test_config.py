import json

from pulse5 import config


class TestConfig:
    def test_save_and_load(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "_config_dir", lambda: tmp_path)
        monkeypatch.setattr(config, "_config_file", lambda: tmp_path / "config.json")

        config.save_device("AA:BB:CC:DD:EE:FF", "Pulse 5")
        result = config.get_saved_device()
        assert result == ("AA:BB:CC:DD:EE:FF", "Pulse 5")

    def test_no_saved_device(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "_config_dir", lambda: tmp_path)
        monkeypatch.setattr(config, "_config_file", lambda: tmp_path / "config.json")

        assert config.get_saved_device() is None

    def test_clear_device(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "_config_dir", lambda: tmp_path)
        monkeypatch.setattr(config, "_config_file", lambda: tmp_path / "config.json")

        config.save_device("AA:BB:CC:DD:EE:FF", "Pulse 5")
        config.clear_device()
        assert config.get_saved_device() is None

    def test_corrupt_config(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "_config_dir", lambda: tmp_path)
        monkeypatch.setattr(config, "_config_file", lambda: tmp_path / "config.json")

        (tmp_path / "config.json").write_text("not json{{{")
        assert config.get_saved_device() is None

    def test_missing_name_defaults(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "_config_dir", lambda: tmp_path)
        monkeypatch.setattr(config, "_config_file", lambda: tmp_path / "config.json")

        (tmp_path / "config.json").write_text(json.dumps({"address": "AA:BB"}))
        result = config.get_saved_device()
        assert result == ("AA:BB", "Unknown")

    def test_xdg_config_home(self, tmp_path, monkeypatch):
        """When XDG_CONFIG_HOME is set, config dir should be under it."""
        monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path))
        assert config._config_dir() == tmp_path / "pulse5"
        assert config._config_file() == tmp_path / "pulse5" / "config.json"

    def test_xdg_config_home_fallback(self, tmp_path, monkeypatch):
        """When XDG_CONFIG_HOME is unset, fall back to ~/.config."""
        monkeypatch.delenv("XDG_CONFIG_HOME", raising=False)
        monkeypatch.setattr("pathlib.Path.home", staticmethod(lambda: tmp_path))
        assert config._config_dir() == tmp_path / ".config" / "pulse5"
