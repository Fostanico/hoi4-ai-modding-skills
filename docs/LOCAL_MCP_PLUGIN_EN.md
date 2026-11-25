# HOI4 Local Plugin and Read-Only MCP Helper (`hoi4_local`)

[简体中文](LOCAL_MCP_PLUGIN.md) | English | [日本語](LOCAL_MCP_PLUGIN_JA.md) | [Русский](LOCAL_MCP_PLUGIN_RU.md) | [한국어](LOCAL_MCP_PLUGIN_KO.md)

## Architecture and Role

This plugin bundles **three Agent Skills** with a **read-only local MCP server (`hoi4_local`)**:
- **The Skills** define the methodology—feature design, version verification, evidence grading, editing boundaries, and clean handoffs.
- **`hoi4_local` MCP** handles fast local fact-gathering by exposing common read-only inspections as structured, bounded tools.
- **The Codex Plugin manifest** packages both into one installable unit so they stay in sync.

`hoi4_local` delivers objective local facts quickly; syntax and runtime conclusions still come from cross-checking against the target build's vanilla consumers, active dependencies, and in-game observations. On clients without MCP support, the repository's PowerShell, Python, `rg`, and Git scripts cover the full workflow as well.

## Five Read-Only Tools

| Tool | What it does | Usage notes |
| --- | --- | --- |
| `detect_hoi4_environment` | Locates mod workspaces, HOI4 installation paths, user data, logs, and Workshop folders | Maps local directories; confirm currently enabled mods against your playset or `dlc_load.json` |
| `trace_hoi4_identifier` | Searches for IDs, flags, localisation keys, and GFX names across your mod, vanilla, and specified dependencies | Returns exact text hits; follow up by confirming the caller actually consumes the identifier |
| `validate_hoi4_changes` | Runs lightweight PDX and localisation static checks on explicit paths or Git changes | Scoped to changed files and strictly read-only; use Mod Doctor for full-repository audits |
| `read_hoi4_logs` | Reads bounded tails of `error.log`, `game.log`, and registered HOI4 logs while collapsing duplicates | Leaves logs untouched; check file timestamps first to confirm they match your latest run |
| `inspect_hoi4_media` | Reads DDS/PNG/JPEG/GIF dimensions and format metadata, plus audio/video streams when `ffprobe` is installed | Reports objective file specs; verify rendering requirements against the target GUI/GFX consumer |

All five tools are **100% read-only**: they never launch Steam or HOI4, never modify playsets, never edit or delete mod files, and never touch running game processes. Whenever you need interactive window capture and input for live testing, use the completely separate opt-in server `hoi4_desktop` below.

## Transport and Runtime Model

- **Local stdio transport**: launched on demand by the host client, exchanging single-line UTF-8 JSON-RPC messages over stdin/stdout. Process lifetime is managed by the client with zero network sockets.
- **Zero dependencies, zero network**: built solely on the Python 3 standard library, needing neither a cloud HOI4 corpus nor an OpenAI API key. If `ffprobe` is already on `PATH`, the media tool automatically adds stream details; if missing, it reports that clearly without downloading anything.

## Installation and Updates

The repository root is itself the plugin source, with `.codex-plugin/plugin.json` pointing to the single `skills/` tree and `.mcp.json`. Developer self-checks:

```powershell
python scripts/test-mcp-server.py
python <plugin-creator>/scripts/validate_plugin.py <repository-root>
```

On Windows, run from the repository root to install or refresh in one step:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

The script maintains a dedicated `hoi4-local-modding` marketplace under your user local app-data folder, stamps a refresh cachebuster, and registers the plugin through the Codex CLI—no manual JSON editing required. **Start a fresh Codex task** after installing or updating so the new session loads the refreshed skills and tools. Public releases should ship both the full plugin ZIP and the three standalone skill ZIPs for non-plugin clients.

## Safety Guards and Troubleshooting

- **Clean stdio channel**: stdout carries strictly one UTF-8 JSON-RPC message per line; diagnostics go to stderr.
- **Bounded scanning**: cross-file search checks only whitelisted text extensions, skips `.git`, `node_modules`, and `dist`, and caps file size and match counts.
- **Workspace confinement**: validation and media inspection stay strictly inside `mod_root`, rejecting `..` path traversal and capping per-call file counts.
- **Log whitelist**: `read_hoi4_logs` reads only pre-registered HOI4 log names, preventing arbitrary file reads.
- **If MCP tools do not appear**: confirm `python` or `py -3` is on `PATH`, open a fresh task/conversation, and run `python scripts/test-mcp-server.py` to diagnose.

## Optional Companion: Standalone Desktop Test MCP (`hoi4_desktop`)

To keep `hoi4_local` strictly read-only at all times, all screenshot and mouse/keyboard capabilities live in a separate, **disabled-by-default** local server: `mcp-server/hoi4_desktop_mcp.py` (`hoi4_desktop`):

- Built for clients without native Windows desktop computer use (**Google Antigravity, Cursor, Claude Code, Gemini CLI**, and similar MCP hosts);
- Pure Python 3 standard library + native Windows Win32 APIs, zero external dependencies, zero network access;
- Hardcoded process whitelist locked to `hoi4.exe`, `Paradox Launcher`, `dowser.exe`, and `Steam`—browsers, chat apps, and IDEs stay completely unreachable;
- Enforces the full authorization, short-test budget, and configuration-restoration rules in `hoi4-content-builder/workflows/test-mod.md`.

See [Optional Desktop MCP Setup Guide](DESKTOP_MCP_SETUP_EN.md) for client configs, safety boundaries, and offline self-checks (`python scripts/test-desktop-mcp-server.py`).

Future roadmap items include active playset parsing, descriptor load-order graphs, and finer-grained log root-cause attribution.
