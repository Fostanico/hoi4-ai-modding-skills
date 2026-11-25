# Optional Local Desktop Test MCP (`hoi4_desktop`) Setup Guide

[简体中文](DESKTOP_MCP_SETUP.md) | English | [日本語](DESKTOP_MCP_SETUP_JA.md) | [Русский](DESKTOP_MCP_SETUP_RU.md) | [한국어](DESKTOP_MCP_SETUP_KO.md)

`hoi4_desktop` (`mcp-server/hoi4_desktop_mcp.py`) is a **standard, client-agnostic local MCP server** built for **non-Codex clients** without built-in Windows desktop computer use (**Google Antigravity, Cursor, Claude Code, Gemini CLI, Windsurf, Cline**, and similar MCP hosts). It stays disabled by default and is turned on only when you want AI assistance for authorized live testing under [test-mod.md](../skills/hoi4-content-builder/workflows/test-mod.md).

It is **physically separated** from the read-only evidence server `hoi4_local` (`mcp-server/hoi4_mcp.py`): everyday development, audits, and static checks use only `hoi4_local`, and you can toggle `hoi4_desktop` off as soon as a test run wraps up.

## Design Highlights and Safety Guards

- **Standard, zero-dependency, offline**: speaks standard MCP stdio JSON-RPC 2.0 using only the Python 3 standard library, native Windows Win32 APIs (`user32`/`gdi32`/`kernel32`/`shell32`), and a pure-Python PNG encoder—no `pip install` and no network sockets.
- **Hardcoded process whitelist**: discovers, captures, and interacts strictly with five HOI4-related processes; browsers, chat apps, IDEs, and all other desktop windows remain invisible and unreachable:
  - `hoi4.exe`
  - `paradox launcher.exe`, `dowser.exe`
  - `steam.exe`, `steamwebhelper.exe`
- **Client-area-only capture and strict bounds**: captures only the verified client area of a whitelisted window (`PrintWindow(PW_RENDERFULLCONTENT)` first, falling back to foreground-clipped `BitBlt` only when the verified target holds foreground); clicks, drags, and scrolls use window-relative coordinates and reject anything out of bounds.
- **Live foreground checks and emergency failsafe**: re-verifies foreground ownership before every input, blocks `Alt+Tab` and `Alt+F4`, and halts immediately whenever you move the mouse to the top-left corner (`x <= 4, y <= 4`).
- **Tuned specifically for HOI4 live testing**:
  - Per-Monitor V2 DPI awareness and multi-monitor virtual desktop coordinate mapping;
  - DirectX hardware scancodes for hotkeys (`~`/`grave` console toggle, `Space`, `Esc`);
  - `KEYEVENTF_UNICODE` UTF-16 injection for text typing, bypassing Chinese/Japanese/Korean IMEs cleanly so commands like `cp 100` or `pp 500` are never hijacked into IME candidates or stripped of spaces;
  - Isolated-desktop self-check: `list_hoi4_windows` returns `desktop_name` and warns immediately if a host runs the server inside a non-`Default` isolated desktop;
  - Hardcoded Steam URI (`steam://rungameid/394360`) gated on `confirm_user_authorized: true`, paired with the full authorization and config-restoration rules of `test-mod.md`.

## Prerequisites

1. **Windows 10 / 11 + Python 3** (`py -3` or `python` on `PATH`).
2. **Borderless Fullscreen or Windowed mode recommended**: some GPU drivers block GDI/`PrintWindow` capture in exclusive fullscreen.
3. **Matching privilege level**: run `hoi4.exe` as a normal user (not elevated as Administrator) so a standard-privilege MCP host can deliver input via `SendInput`.

## Exposed Tools (10)

| Tool | Kind | Purpose |
| --- | --- | --- |
| `list_hoi4_windows` | Read-only | Lists visible whitelisted windows (handle, process name, title, client size, foreground state, and desktop name) |
| `capture_hoi4_window` | Read-only | Captures only the target window's client area as PNG, returning coordinate metadata, a temp file path, and an inline MCP image block |
| `focus_hoi4_window` | Interactive | Restores (if minimized) and focuses a verified whitelisted window (with background focus handoff) |
| `click_hoi4_window` | Interactive | Clicks inside a verified window using normalized (`0.0–1.0`), client-pixel, or image-pixel coordinates, with optional post-click screenshot |
| `drag_hoi4_window` | Interactive | Smoothly drags inside a verified window (map panning, scrollbars, draggable panels) |
| `scroll_hoi4_window` | Interactive | Scrolls the mouse wheel at a target point (map zoom, decision/focus lists) |
| `send_hoi4_keys` | Interactive | Sends DirectX hardware-scancode keys or combos (`Alt+Tab` / `Alt+F4` blocked) |
| `type_hoi4_text` | Interactive | Types short text (up to 500 chars) via IME-safe Unicode injection |
| `run_hoi4_console_command` | Interactive | **`hoi4.exe` only**: opens the console (`` ` ``), types one single-line command, presses Enter, and optionally closes the console and captures a screenshot |
| `launch_hoi4_steam` | Interactive | Opens `steam://rungameid/394360` after explicit user consent (`confirm_user_authorized: true` required) |

## Client Configuration Examples

Replace `<REPO_ROOT>` with your local absolute path to this repository (or plugin). Keep the server disabled during normal editing and enable it only when running live checks.

### 1. Google Antigravity (Recommended: Standalone Toggleable Plugin)

Place `plugin.json`, `mcp_config.json`, and `mcp-server/hoi4_desktop_mcp.py` under `~/.gemini/config/plugins/hoi4-desktop-control/`, with `mcp_config.json`:

```json
{
  "mcpServers": {
    "hoi4_desktop": {
      "command": "py",
      "args": [
        "-3",
        "-u",
        "C:\\Users\\<YOUR_USER>\\.gemini\\config\\plugins\\hoi4-desktop-control\\mcp-server\\hoi4_desktop_mcp.py"
      ],
      "cwd": "C:\\Users\\<YOUR_USER>\\.gemini\\config\\plugins\\hoi4-desktop-control"
    }
  }
}
```

Once configured, toggle the plugin on or off anytime in Antigravity's **Plugins Manager** without affecting read-only `hoi4_local` or the three skills.

### 2. Cursor / Claude Code / Gemini CLI / Windsurf / Cline

Add the following entry under `mcpServers` in your client's MCP config (`.cursor/mcp.json`, `.mcp.json`, `~/.claude.json`, or `~/.gemini/settings.json`):

```json
{
  "mcpServers": {
    "hoi4_desktop": {
      "command": "cmd.exe",
      "args": [
        "/d",
        "/s",
        "/c",
        "call",
        "<REPO_ROOT>\\mcp-server\\launch_desktop.cmd"
      ]
    }
  }
}
```

You can also copy directly from the bundled template [mcp-server/hoi4_desktop.mcp.example.json](../mcp-server/hoi4_desktop.mcp.example.json).

### 3. Codex

Codex desktop already includes native computer use, so the default `.mcp.json` registers only read-only `hoi4_local`.

## Offline Self-Check (Zero Desktop Side Effects)

Run from the repository root:

```powershell
python scripts/test-desktop-mcp-server.py
```

The smoke suite verifies process-whitelist rejection, out-of-bounds coordinate rejection, pure-Python PNG encoding/decoding, null-argument fallback handling, JSON-RPC handshake, all 10 tool schemas, and unauthorized `launch_hoi4_steam` refusal—without launching Steam or touching any desktop window.
