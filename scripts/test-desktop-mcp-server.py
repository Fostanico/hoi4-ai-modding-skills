#!/usr/bin/env python3
"""Smoke and safety-boundary tests for mcp-server/hoi4_desktop_mcp.py.

Runs without launching HOI4, Steam, or sending real mouse/keyboard input.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys
import zlib


ROOT = Path(__file__).resolve().parent.parent
SERVER = ROOT / "mcp-server" / "hoi4_desktop_mcp.py"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_module():
    spec = importlib.util.spec_from_file_location("hoi4_desktop_mcp", SERVER)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_unit_helpers() -> None:
    mod = load_module()

    # 1. Process whitelist enforcement
    for allowed in ("hoi4.exe", "HOI4.EXE", "C:\\Games\\dowser.exe", "Paradox Launcher.exe", "steam.exe", "steamwebhelper.exe"):
        require(mod.is_allowed_process(allowed), f"Expected allowed process: {allowed}")
    for blocked in ("chrome.exe", "explorer.exe", "notepad.exe", "cmd.exe", "powershell.exe", "WeChat.exe", "Code.exe"):
        require(not mod.is_allowed_process(blocked), f"Blocked process must not be allowed: {blocked}")

    # 2. Coordinate mapping & bounds rejection
    require(mod.validate_client_coords(0.5, 0.5, 1920, 1080, "normalized") == (960, 540), "Normalized midpoint mismatch")
    require(mod.validate_client_coords(100, 200, 1920, 1080, "client") == (100, 200), "Client pixel coord mismatch")
    ix, iy = mod.validate_client_coords(640, 360, 1920, 1080, "image", image_w=1280, image_h=720)
    require(958 <= ix <= 962 and 538 <= iy <= 542, f"Image coord scaling mismatch: {(ix, iy)}")

    for bad_args in [
        (-0.1, 0.5, 1920, 1080, "normalized", None, None),
        (1.01, 0.5, 1920, 1080, "normalized", None, None),
        (1920, 100, 1920, 1080, "client", None, None),
        (-1, 100, 1920, 1080, "client", None, None),
        (1280, 100, 1920, 1080, "image", 1280, 720),
    ]:
        raised = False
        try:
            mod.validate_client_coords(*bad_args)
        except mod.ToolInputError:
            raised = True
        require(raised, f"Out-of-bounds coords should be rejected: {bad_args}")

    # 3. Pure-Python BGRA -> RGB -> Downsample -> PNG roundtrip
    # 4x2 BGRA image: top row red (B=0,G=0,R=255,A=255), bottom row blue (B=255,G=0,R=0,A=255)
    bgra = (b"\x00\x00\xff\xff" * 4) + (b"\xff\x00\x00\xff" * 4)
    rgb = mod.bgra_to_rgb(bgra, 4, 2)
    require(rgb[:3] == b"\xff\x00\x00" and rgb[12:15] == b"\x00\x00\xff", "BGRA->RGB channel swap failed")
    require(not mod.is_uniform_black(rgb), "Colored frame misclassified as black")
    require(mod.is_uniform_black(b"\x00" * (4 * 2 * 3)), "Black frame not detected")

    scaled, sw, sh = mod.downsample_rgb(rgb, 4, 2, max_width=2)
    require((sw, sh) == (2, 1) and len(scaled) == 6, f"Downsample size mismatch: {(sw, sh)}")

    png = mod.encode_png_rgb(rgb, 4, 2)
    require(png.startswith(b"\x89PNG\r\n\x1a\n"), "PNG signature missing")
    ihdr_len, ihdr_tag = struct.unpack(">I4s", png[8:16])
    require(ihdr_len == 13 and ihdr_tag == b"IHDR", "PNG IHDR invalid")
    w, h, depth, ctype = struct.unpack(">IIBB", png[16:26])
    require((w, h, depth, ctype) == (4, 2, 8, 2), f"PNG IHDR fields wrong: {(w, h, depth, ctype)}")
    # Verify IDAT decompresses to expected scanlines
    idat_pos = png.index(b"IDAT")
    idat_len = struct.unpack(">I", png[idat_pos - 4 : idat_pos])[0]
    raw_scanlines = zlib.decompress(png[idat_pos + 4 : idat_pos + 4 + idat_len])
    require(len(raw_scanlines) == (4 * 3 + 1) * 2, "PNG IDAT scanline length mismatch")
    require(raw_scanlines[0] == 0 and raw_scanlines[1:4] == b"\xff\x00\x00", "PNG row 0 pixels mismatch")

    # 4. Null-safe optional argument helpers (clients may pass explicit JSON null)
    require(mod._opt_int({"max_width": None}, "max_width", 1280) == 1280, "_opt_int must fall back on None")
    require(mod._opt_int({"max_width": 960}, "max_width", 1280) == 960, "_opt_int must parse explicit int")
    require(mod._opt_float({"x": None}, "x", 0.5) == 0.5, "_opt_float must fall back on None")
    require(mod._opt_bool({"close_console": None}, "close_console", True) is True, "_opt_bool must fall back on None")
    require(mod._opt_bool({"close_console": False}, "close_console", True) is False, "_opt_bool must preserve False")

    # 5. Console command preflight advisory lint
    eff_warn = mod.inspect_console_command("effect set_country_flag = my_flag")
    require(
        any("eval_effect" in msg for msg in eff_warn.get("advisories", [])),
        f"Inline 'effect' misuse should advise eval_effect: {eff_warn}",
    )
    spawn_warn = mod.inspect_console_command("spawn infantry 6521 1")
    require(
        any("release build" in msg for msg in spawn_warn.get("advisories", [])),
        f"Dev-only 'spawn' should warn about release builds: {spawn_warn}",
    )
    ok_lint = mod.inspect_console_command("eval_effect set_country_flag = my_flag")
    require(ok_lint == {}, f"Valid eval_effect should emit no advisory: {ok_lint}")


def send(process: subprocess.Popen[str], payload: dict) -> dict:
    assert process.stdin is not None and process.stdout is not None
    process.stdin.write(json.dumps(payload, ensure_ascii=False) + "\n")
    process.stdin.flush()
    line = process.stdout.readline()
    if not line:
        stderr = process.stderr.read() if process.stderr else ""
        raise RuntimeError(f"Desktop MCP exited early: {stderr}")
    return json.loads(line)


def test_stdio_protocol() -> None:
    process = subprocess.Popen(
        [sys.executable, "-u", str(SERVER)],
        cwd=ROOT,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    try:
        init = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2025-11-25",
                    "capabilities": {},
                    "clientInfo": {"name": "desktop-smoke-test", "version": "1.0.0"},
                },
            },
        )
        require(init["result"]["protocolVersion"] == "2025-11-25", "Protocol negotiation failed")
        assert process.stdin is not None
        process.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
        process.stdin.flush()

        listed = send(process, {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
        tools = {t["name"]: t for t in listed["result"]["tools"]}
        expected_tools = {
            "list_hoi4_windows",
            "capture_hoi4_window",
            "focus_hoi4_window",
            "click_hoi4_window",
            "drag_hoi4_window",
            "scroll_hoi4_window",
            "send_hoi4_keys",
            "type_hoi4_text",
            "lookup_hoi4_console_commands",
            "run_hoi4_console_command",
            "launch_hoi4_steam",
        }
        require(set(tools.keys()) == expected_tools, f"Unexpected tool set: {sorted(tools.keys())}")
        require(tools["list_hoi4_windows"]["annotations"]["readOnlyHint"] is True, "list_hoi4_windows must be readOnly")
        require(tools["capture_hoi4_window"]["annotations"]["readOnlyHint"] is True, "capture_hoi4_window must be readOnly")
        require(tools["lookup_hoi4_console_commands"]["annotations"]["readOnlyHint"] is True, "lookup_hoi4_console_commands must be readOnly")
        require(tools["click_hoi4_window"]["annotations"]["readOnlyHint"] is False, "click_hoi4_window must not be readOnly")

        # Non-intrusive live whitelist listing on Windows
        if sys.platform == "win32":
            win_resp = send(
                process,
                {
                    "jsonrpc": "2.0",
                    "id": 3,
                    "method": "tools/call",
                    "params": {"name": "list_hoi4_windows", "arguments": {}},
                },
            )
            require(win_resp["result"]["isError"] is False, f"list_hoi4_windows failed: {win_resp}")
            allowed = set(win_resp["result"]["structuredContent"]["allowed_processes"])
            for w in win_resp["result"]["structuredContent"]["windows"]:
                require(w["process_name"] in allowed, f"Non-whitelisted process leaked: {w}")

        # Must refuse Steam launch without confirm_user_authorized=true
        launch_refused = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 4,
                "method": "tools/call",
                "params": {
                    "name": "launch_hoi4_steam",
                    "arguments": {"confirm_user_authorized": False},
                },
            },
        )
        require(launch_refused["result"]["isError"] is True, "launch_hoi4_steam must refuse when confirm_user_authorized=false")

        # Must refuse non-existent / non-whitelisted hwnd
        bad_hwnd = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 5,
                "method": "tools/call",
                "params": {
                    "name": "capture_hoi4_window",
                    "arguments": {"hwnd": 999999999},
                },
            },
        )
        require(bad_hwnd["result"]["isError"] is True, "capture_hoi4_window must reject invalid hwnd")

        # Console lookup works offline & supports aliases + Chinese intent
        lookup_resp = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 6,
                "method": "tools/call",
                "params": {
                    "name": "lookup_hoi4_console_commands",
                    "arguments": {"query": "tdebug", "limit": 5},
                },
            },
        )
        require(lookup_resp["result"]["isError"] is False, f"lookup_hoi4_console_commands failed: {lookup_resp}")
        require(
            lookup_resp["result"]["structuredContent"]["matches"][0]["name"] == "provtooltipdebug",
            "tdebug alias should resolve to provtooltipdebug",
        )

        zh_resp = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 7,
                "method": "tools/call",
                "params": {
                    "name": "lookup_hoi4_console_commands",
                    "arguments": {"query": "决议", "limit": 5},
                },
            },
        )
        require(zh_resp["result"]["isError"] is False and zh_resp["result"]["structuredContent"]["match_count"] >= 1, "Chinese intent lookup failed")

        print("Desktop MCP smoke & safety-boundary tests passed (11 tools verified, zero desktop side effects).")
    finally:
        if process.stdin:
            process.stdin.close()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


def main() -> int:
    test_unit_helpers()
    test_stdio_protocol()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
