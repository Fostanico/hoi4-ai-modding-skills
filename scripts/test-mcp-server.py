#!/usr/bin/env python3
"""Smoke-test the local HOI4 MCP server without launching Codex or HOI4."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SERVER = ROOT / "mcp-server" / "hoi4_mcp.py"


def send(process: subprocess.Popen[str], payload: dict) -> dict:
    assert process.stdin is not None
    assert process.stdout is not None
    process.stdin.write(json.dumps(payload, ensure_ascii=False) + "\n")
    process.stdin.flush()
    line = process.stdout.readline()
    if not line:
        stderr = process.stderr.read() if process.stderr else ""
        raise RuntimeError(f"MCP server exited before responding: {stderr}")
    return json.loads(line)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    process = subprocess.Popen(
        [sys.executable, str(SERVER)],
        cwd=ROOT,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    try:
        initialized = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2025-06-18",
                    "capabilities": {},
                    "clientInfo": {"name": "smoke-test", "version": "1.0.0"},
                },
            },
        )
        require(initialized["result"]["protocolVersion"] == "2025-06-18", "protocol negotiation failed")
        assert process.stdin is not None
        process.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
        process.stdin.flush()

        listed = send(process, {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
        names = [entry["name"] for entry in listed["result"]["tools"]]
        require(
            names
            == [
                "detect_hoi4_environment",
                "trace_hoi4_identifier",
                "validate_hoi4_changes",
                "read_hoi4_logs",
                "inspect_hoi4_media",
            ],
            f"unexpected tool list: {names}",
        )

        detected = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {
                    "name": "detect_hoi4_environment",
                    "arguments": {"workspace_root": str(ROOT)},
                },
            },
        )
        require(detected["result"]["isError"] is False, "environment detection failed")
        require(detected["result"]["structuredContent"]["read_only"] is True, "read-only marker missing")

        traced = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 4,
                "method": "tools/call",
                "params": {
                    "name": "trace_hoi4_identifier",
                    "arguments": {
                        "identifier": "hoi4-pdx-modding",
                        "mod_root": str(ROOT),
                        "max_results": 5,
                    },
                },
            },
        )
        require(traced["result"]["structuredContent"]["match_count"] > 0, "identifier trace returned no matches")

        validated = send(
            process,
            {
                "jsonrpc": "2.0",
                "id": 5,
                "method": "tools/call",
                "params": {
                    "name": "validate_hoi4_changes",
                    "arguments": {
                        "mod_root": str(ROOT),
                        "paths": [
                            ".validation-fixture/mod-doctor/events/FIX_events.txt",
                            ".validation-fixture/mod-doctor/interface/FIX.gfx",
                        ],
                    },
                },
            },
        )
        require(validated["result"]["isError"] is False, "validator tool failed")
        require(validated["result"]["structuredContent"]["passed"] is True, "fixture validation did not pass")

        with tempfile.TemporaryDirectory(prefix="hoi4-mcp-test-") as temporary:
            fixture = Path(temporary)
            (fixture / "logs").mkdir()
            (fixture / "logs" / "error.log").write_text(
                "[10:00:00][no_game_date][parser.cpp:1]: sample error\n"
                "[10:00:01][no_game_date][parser.cpp:1]: sample error\n",
                encoding="utf-8",
            )
            media_root = fixture / "mod"
            media_root.mkdir()
            (media_root / "sample.png").write_bytes(
                b"\x89PNG\r\n\x1a\n" + b"\x00\x00\x00\rIHDR" + b"\x00\x00\x00\x02\x00\x00\x00\x03"
            )

            logs = send(
                process,
                {
                    "jsonrpc": "2.0",
                    "id": 6,
                    "method": "tools/call",
                    "params": {
                        "name": "read_hoi4_logs",
                        "arguments": {
                            "user_data_root": str(fixture),
                            "logs": ["error"],
                            "tail_lines": 20,
                        },
                    },
                },
            )
            require(logs["result"]["isError"] is False, "log reader failed")
            require(logs["result"]["structuredContent"]["logs"][0]["exists"] is True, "test log missing")

            media = send(
                process,
                {
                    "jsonrpc": "2.0",
                    "id": 7,
                    "method": "tools/call",
                    "params": {
                        "name": "inspect_hoi4_media",
                        "arguments": {
                            "mod_root": str(media_root),
                            "paths": ["sample.png"],
                        },
                    },
                },
            )
            require(media["result"]["isError"] is False, "media inspector failed")
            media_info = media["result"]["structuredContent"]["files"][0]
            require((media_info["width"], media_info["height"]) == (2, 3), "PNG dimensions were not parsed")

        print("MCP smoke test passed: handshake and all 5 read-only tools.")
        return 0
    finally:
        if process.stdin:
            process.stdin.close()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
