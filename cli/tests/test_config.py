import json

from pulse5 import config


class TestConfig:
    def test_save_and_load(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "CONFIG_DIR", tmp_path)
        monkeypatch.setattr(config, "CONFIG_FILE", tmp_path / "config.json")

        config.save_device("AA:BB:CC:DD:EE:FF", "Pulse 5")
        result = config.get_saved_device()
        assert result == ("AA:BB:CC:DD:EE:FF", "Pulse 5")

    def test_no_saved_device(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "CONFIG_DIR", tmp_path)
        monkeypatch.setattr(config, "CONFIG_FILE", tmp_path / "config.json")

        assert config.get_saved_device() is None

    def test_clear_device(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "CONFIG_DIR", tmp_path)
        monkeypatch.setattr(config, "CONFIG_FILE", tmp_path / "config.json")

        config.save_device("AA:BB:CC:DD:EE:FF", "Pulse 5")
        config.clear_device()
        assert config.get_saved_device() is None

    def test_corrupt_config(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "CONFIG_DIR", tmp_path)
        monkeypatch.setattr(config, "CONFIG_FILE", tmp_path / "config.json")

        (tmp_path / "config.json").write_text("not json{{{")
        assert config.get_saved_device() is None

    def test_missing_name_defaults(self, tmp_path, monkeypatch):
        monkeypatch.setattr(config, "CONFIG_DIR", tmp_path)
        monkeypatch.setattr(config, "CONFIG_FILE", tmp_path / "config.json")

        (tmp_path / "config.json").write_text(json.dumps({"address": "AA:BB"}))
        result = config.get_saved_device()
        assert result == ("AA:BB", "Unknown")
