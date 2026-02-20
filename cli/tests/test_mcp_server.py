"""Tests for the pulse5.mcp_server module.

Mocks asyncio.create_subprocess_exec to avoid real BLE hardware.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from pulse5.mcp_server import (
    _run_pulse5,
    pulse5_brightness,
    pulse5_pattern,
    pulse5_scan,
    pulse5_status,
    pulse5_theme,
)


# ---------------------------------------------------------------------------
# _run_pulse5 helper
# ---------------------------------------------------------------------------


def _make_proc(returncode: int = 0, stdout: bytes = b"", stderr: bytes = b""):
    proc = AsyncMock()
    proc.communicate.return_value = (stdout, stderr)
    proc.returncode = returncode
    return proc


class TestRunPulse5:
    @pytest.mark.asyncio
    async def test_success_returns_stdout(self):
        proc = _make_proc(stdout=b"ok output")
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc) as mock_exec:
            result = await _run_pulse5("scan", "--timeout", "5")

        assert result == "ok output"
        args = mock_exec.call_args[0]
        assert args[1:] == ("-m", "pulse5.cli", "scan", "--timeout", "5")

    @pytest.mark.asyncio
    async def test_success_empty_stdout_returns_done(self):
        proc = _make_proc(stdout=b"")
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc):
            result = await _run_pulse5("status")

        assert result == "Done."

    @pytest.mark.asyncio
    async def test_failure_returns_stderr(self):
        proc = _make_proc(returncode=1, stderr=b"connection failed")
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc):
            result = await _run_pulse5("brightness", "50")

        assert result == "Failed: connection failed"

    @pytest.mark.asyncio
    async def test_failure_falls_back_to_stdout(self):
        proc = _make_proc(returncode=1, stdout=b"stdout error", stderr=b"")
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc):
            result = await _run_pulse5("theme", "nature")

        assert result == "Failed: stdout error"

    @pytest.mark.asyncio
    async def test_failure_falls_back_to_exit_code(self):
        proc = _make_proc(returncode=42)
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc):
            result = await _run_pulse5("scan")

        assert result == "Failed: exit code 42"

    @pytest.mark.asyncio
    async def test_strips_whitespace(self):
        proc = _make_proc(stdout=b"  trimmed  \n")
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc):
            result = await _run_pulse5("status")

        assert result == "trimmed"

    @pytest.mark.asyncio
    async def test_stdin_devnull_and_new_session(self):
        """Subprocess should use DEVNULL stdin and start_new_session."""
        proc = _make_proc(stdout=b"ok")
        with patch("pulse5.mcp_server.asyncio.create_subprocess_exec", return_value=proc) as mock_exec:
            await _run_pulse5("scan")

        kwargs = mock_exec.call_args[1]
        assert kwargs["stdin"] is not None  # DEVNULL
        assert kwargs["start_new_session"] is True


# ---------------------------------------------------------------------------
# MCP tool functions
# ---------------------------------------------------------------------------


class TestMcpTools:
    @pytest.mark.asyncio
    async def test_scan_default_timeout(self):
        with patch("pulse5.mcp_server._run_pulse5", new_callable=AsyncMock, return_value="ok") as mock:
            result = await pulse5_scan()

        mock.assert_awaited_once_with("scan", "--timeout", "5")
        assert result == "ok"

    @pytest.mark.asyncio
    async def test_scan_custom_timeout(self):
        with patch("pulse5.mcp_server._run_pulse5", new_callable=AsyncMock, return_value="ok") as mock:
            result = await pulse5_scan(timeout=10)

        mock.assert_awaited_once_with("scan", "--timeout", "10")
        assert result == "ok"

    @pytest.mark.asyncio
    async def test_brightness(self):
        with patch("pulse5.mcp_server._run_pulse5", new_callable=AsyncMock, return_value="ok") as mock:
            result = await pulse5_brightness(level=60)

        mock.assert_awaited_once_with("brightness", "60")
        assert result == "ok"

    @pytest.mark.asyncio
    async def test_theme(self):
        with patch("pulse5.mcp_server._run_pulse5", new_callable=AsyncMock, return_value="ok") as mock:
            result = await pulse5_theme(name="party")

        mock.assert_awaited_once_with("theme", "party")
        assert result == "ok"

    @pytest.mark.asyncio
    async def test_pattern(self):
        with patch("pulse5.mcp_server._run_pulse5", new_callable=AsyncMock, return_value="ok") as mock:
            result = await pulse5_pattern(name="campfire")

        mock.assert_awaited_once_with("pattern", "campfire")
        assert result == "ok"

    @pytest.mark.asyncio
    async def test_status(self):
        with patch("pulse5.mcp_server._run_pulse5", new_callable=AsyncMock, return_value="ok") as mock:
            result = await pulse5_status()

        mock.assert_awaited_once_with("status")
        assert result == "ok"


# ---------------------------------------------------------------------------
# main entry point
# ---------------------------------------------------------------------------


class TestMain:
    def test_main_calls_mcp_run(self):
        with patch("pulse5.mcp_server.mcp") as mock_mcp:
            from pulse5.mcp_server import main
            main()

        mock_mcp.run.assert_called_once()
