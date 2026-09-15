#!/usr/bin/env python3
"""Dependency-free, read-only MCP helpers for local Hearts of Iron IV modding.

The server deliberately exposes no write, delete, process-control, Steam, or
game-launch operation.  Standard output is reserved for newline-delimited MCP
JSON-RPC messages; diagnostic text goes to standard error.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


SERVER_NAME = "hoi4-local-modding"
SERVER_VERSION = "1.6.0"
LATEST_PROTOCOL = "2025-11-25"
SUPPORTED_PROTOCOLS = {
    "2024-11-05",
    "2025-03-26",
    "2025-06-18",
    "2025-11-25",
}
MAX_MESSAGE_BYTES = 4 * 1024 * 1024
MAX_TEXT_FILE_BYTES = 16 * 1024 * 1024

TEXT_EXTENSIONS = {
    ".txt",
    ".gui",
    ".gfx",
    ".asset",
    ".yml",
    ".yaml",
    ".json",
    ".csv",
    ".mod",
    ".md",
    ".lua",
    ".shader",
    ".effect",
}
MEDIA_EXTENSIONS = {
    ".dds",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".tga",
    ".bmp",
    ".ogg",
    ".wav",
    ".mp3",
    ".flac",
    ".mp4",
    ".webm",
    ".mov",
}
EXCLUDED_DIRS = {
    ".git",
    ".svn",
    ".hg",
    ".idea",
    ".vscode",
    "node_modules",
    "dist",
    "__pycache__",
}
LOG_FILES = {
    "error": "logs/error.log",
    "game": "logs/game.log",
    "system": "logs/system.log",
    "setup": "logs/setup.log",
    "executed_commands": "logs/executed_commands.log",
}

# MCP stdio is UTF-8 regardless of the Windows console code page.  Without
# this, a Chinese path or localisation line may be emitted as GBK and corrupt
# the protocol stream for a UTF-8 client.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="strict", newline="\n")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace", newline="\n")


class ToolInputError(ValueError):
    """An actionable tool-input or local-environment error."""


def tool(
    name: str,
    title: str,
    description: str,
    properties: dict[str, Any],
    required: list[str] | None = None,
) -> dict[str, Any]:
    schema: dict[str, Any] = {
        "type": "object",
        "properties": properties,
        "additionalProperties": False,
    }
    if required:
        schema["required"] = required
    return {
        "name": name,
        "title": title,
        "description": description,
        "inputSchema": schema,
        "annotations": {
            "readOnlyHint": True,
            "destructiveHint": False,
            "idempotentHint": True,
            "openWorldHint": False,
        },
    }


TOOLS = [
    tool(
        "detect_hoi4_environment",
        "Detect HOI4 environment",
        "Locate and describe a local HOI4 game install, user-data directory, Workshop root, and current mod workspace. Performs read-only checks only.",
        {
            "workspace_root": {
                "type": "string",
                "description": "Optional absolute path to the current mod or repository.",
            },
            "game_root": {
                "type": "string",
                "description": "Optional absolute path to the installed Hearts of Iron IV directory.",
            },
            "user_data_root": {
                "type": "string",
                "description": "Optional absolute path to Documents/Paradox Interactive/Hearts of Iron IV.",
            },
            "workshop_root": {
                "type": "string",
                "description": "Optional absolute path to steamapps/workshop/content/394360.",
            },
        },
    ),
    tool(
        "trace_hoi4_identifier",
        "Trace HOI4 identifier",
        "Search an exact identifier across a mod, installed vanilla, and explicitly supplied dependency roots. Results distinguish likely definitions, localisation keys, and consumers.",
        {
            "identifier": {
                "type": "string",
                "minLength": 1,
                "maxLength": 256,
                "description": "Exact case-sensitive token, localisation key, sprite name, event ID, flag, or variable to trace.",
            },
            "mod_root": {
                "type": "string",
                "description": "Absolute path to the target mod root.",
            },
            "game_root": {
                "type": "string",
                "description": "Optional absolute path to installed vanilla.",
            },
            "dependency_roots": {
                "type": "array",
                "items": {"type": "string"},
                "maxItems": 12,
                "description": "Optional exact roots of enabled dependency mods.",
            },
            "case_sensitive": {
                "type": "boolean",
                "default": True,
            },
            "max_results": {
                "type": "integer",
                "minimum": 1,
                "maximum": 500,
                "default": 200,
            },
        },
        ["identifier", "mod_root"],
    ),
    tool(
        "validate_hoi4_changes",
        "Validate changed HOI4 files",
        "Run the bundled lightweight validator on explicitly listed or Git-changed PDX/localisation files only. It never edits the mod and never launches the game.",
        {
            "mod_root": {
                "type": "string",
                "description": "Absolute path to the target mod Git worktree.",
            },
            "paths": {
                "type": "array",
                "items": {"type": "string"},
                "maxItems": 200,
                "description": "Optional paths inside mod_root. When omitted, tracked and untracked Git changes are used.",
            },
        },
        ["mod_root"],
    ),
    tool(
        "read_hoi4_logs",
        "Read recent HOI4 logs",
        "Read bounded tails of selected HOI4 logs and summarize repeated messages. This does not clear logs, start the game, or inspect arbitrary files.",
        {
            "user_data_root": {
                "type": "string",
                "description": "Optional absolute HOI4 user-data root. The normal Documents path is auto-detected when omitted.",
            },
            "logs": {
                "type": "array",
                "items": {
                    "type": "string",
                    "enum": sorted(LOG_FILES),
                },
                "maxItems": 5,
                "default": ["error", "game"],
            },
            "tail_lines": {
                "type": "integer",
                "minimum": 1,
                "maximum": 1000,
                "default": 200,
            },
        },
    ),
    tool(
        "inspect_hoi4_media",
        "Inspect HOI4 media",
        "Inspect bounded media files inside a mod, including file size, image dimensions and DDS format, or ffprobe audio/video stream metadata when available.",
        {
            "mod_root": {
                "type": "string",
                "description": "Absolute path to the target mod root.",
            },
            "paths": {
                "type": "array",
                "items": {"type": "string"},
                "maxItems": 100,
                "description": "Media files inside mod_root. When omitted, changed media files from Git are inspected.",
            },
            "include_sha256": {
                "type": "boolean",
                "default": False,
            },
        },
        ["mod_root"],
    ),
]

TOOL_BY_NAME = {entry["name"]: entry for entry in TOOLS}


def emit(payload: dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n")
    sys.stdout.flush()


def rpc_result(request_id: Any, result: dict[str, Any]) -> None:
    emit({"jsonrpc": "2.0", "id": request_id, "result": result})


def rpc_error(request_id: Any, code: int, message: str) -> None:
    emit({"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}})


def as_tool_result(data: dict[str, Any], is_error: bool = False) -> dict[str, Any]:
    rendered = json.dumps(data, ensure_ascii=False, indent=2)
    return {
        "content": [{"type": "text", "text": rendered}],
        "structuredContent": data,
        "isError": is_error,
    }


def resolve_directory(value: str | None, label: str, required: bool = True) -> Path | None:
    if value is None or not str(value).strip():
        if required:
            raise ToolInputError(f"{label} is required")
        return None
    path = Path(os.path.expandvars(os.path.expanduser(str(value)))).resolve()
    if not path.is_dir():
        raise ToolInputError(f"{label} is not an existing directory: {path}")
    return path


def ensure_inside(root: Path, value: str, label: str) -> Path:
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = root / candidate
    candidate = candidate.resolve()
    try:
        candidate.relative_to(root)
    except ValueError as exc:
        raise ToolInputError(f"{label} must stay inside mod_root: {candidate}") from exc
    return candidate


def first_existing(candidates: Iterable[Path]) -> Path | None:
    seen: set[str] = set()
    for candidate in candidates:
        try:
            resolved = candidate.resolve()
        except OSError:
            continue
        key = str(resolved).casefold()
        if key in seen:
            continue
        seen.add(key)
        if resolved.is_dir():
            return resolved
    return None


def steam_library_roots() -> list[Path]:
    candidates: list[Path] = []
    for variable in ("PROGRAMFILES(X86)", "PROGRAMFILES"):
        value = os.environ.get(variable)
        if value:
            candidates.append(Path(value) / "Steam")
    candidates.extend([Path("C:/Steam"), Path("D:/SteamLibrary"), Path("E:/SteamLibrary")])

    libraries: list[Path] = []
    for steam_root in candidates:
        if steam_root.is_dir():
            libraries.append(steam_root)
            vdf = steam_root / "steamapps" / "libraryfolders.vdf"
            if vdf.is_file():
                try:
                    text = vdf.read_text(encoding="utf-8", errors="replace")
                except OSError:
                    continue
                for match in re.finditer(r'"path"\s+"([^"]+)"', text):
                    libraries.append(Path(match.group(1).replace("\\\\", "\\")))
    unique: list[Path] = []
    seen: set[str] = set()
    for item in libraries:
        key = str(item.resolve()).casefold()
        if key not in seen:
            seen.add(key)
            unique.append(item.resolve())
    return unique


def default_user_data_candidates() -> list[Path]:
    env_path = os.environ.get("HOI4_USER_DATA_ROOT")
    items: list[Path] = []
    if env_path:
        items.append(Path(env_path))
    profile = Path(os.environ.get("USERPROFILE", str(Path.home())))
    items.extend(
        [
            profile / "Documents" / "Paradox Interactive" / "Hearts of Iron IV",
            profile / "OneDrive" / "Documents" / "Paradox Interactive" / "Hearts of Iron IV",
        ]
    )
    return items


def discover_game_root(explicit: str | None) -> Path | None:
    candidates: list[Path] = []
    for value in (explicit, os.environ.get("HOI4_GAME_ROOT")):
        if value:
            candidates.append(Path(os.path.expandvars(os.path.expanduser(value))))
    for library in steam_library_roots():
        candidates.append(library / "steamapps" / "common" / "Hearts of Iron IV")
    root = first_existing(candidates)
    if root and (root / "hoi4.exe").is_file():
        return root
    return root


def discover_workshop_root(explicit: str | None, game_root: Path | None) -> Path | None:
    candidates: list[Path] = []
    for value in (explicit, os.environ.get("HOI4_WORKSHOP_ROOT")):
        if value:
            candidates.append(Path(os.path.expandvars(os.path.expanduser(value))))
    if game_root:
        try:
            steamapps = game_root.parents[1]
            candidates.append(steamapps / "workshop" / "content" / "394360")
        except IndexError:
            pass
    for library in steam_library_roots():
        candidates.append(library / "steamapps" / "workshop" / "content" / "394360")
    return first_existing(candidates)


def git_root(path: Path) -> str | None:
    git = shutil.which("git")
    if not git:
        return None
    try:
        result = subprocess.run(
            [git, "-C", str(path), "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=10,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def tool_detect_environment(args: dict[str, Any]) -> dict[str, Any]:
    workspace = resolve_directory(args.get("workspace_root"), "workspace_root", required=False)
    game = discover_game_root(args.get("game_root"))
    user_data = first_existing(
        [Path(args["user_data_root"])] if args.get("user_data_root") else default_user_data_candidates()
    )
    workshop = discover_workshop_root(args.get("workshop_root"), game)

    launcher: dict[str, Any] | None = None
    if game and (game / "launcher-settings.json").is_file():
        try:
            raw = json.loads((game / "launcher-settings.json").read_text(encoding="utf-8-sig"))
            launcher = {
                key: raw.get(key)
                for key in ("gameId", "displayName", "version", "rawVersion", "distPlatform")
            }
        except (OSError, json.JSONDecodeError):
            launcher = {"error": "launcher-settings.json could not be parsed"}

    mod_markers: list[str] = []
    if workspace:
        for name in ("descriptor.mod", "AGENTS.md", "YZ_MOD_TECHNICAL_GUIDE.md"):
            if (workspace / name).exists():
                mod_markers.append(name)
        mod_markers.extend(path.name for path in sorted(workspace.glob("*.mod"))[:10])
        mod_markers = list(dict.fromkeys(mod_markers))

    return {
        "read_only": True,
        "workspace": {
            "path": str(workspace) if workspace else None,
            "git_root": git_root(workspace) if workspace else None,
            "mod_markers": mod_markers,
        },
        "game": {
            "path": str(game) if game else None,
            "hoi4_exe_present": bool(game and (game / "hoi4.exe").is_file()),
            "launcher": launcher,
        },
        "user_data": {
            "path": str(user_data) if user_data else None,
            "logs_present": bool(user_data and (user_data / "logs").is_dir()),
            "crashes_present": bool(user_data and (user_data / "crashes").is_dir()),
        },
        "workshop": {
            "path": str(workshop) if workshop else None,
            "installed_item_directories": (
                sum(1 for path in workshop.iterdir() if path.is_dir()) if workshop else 0
            ),
        },
        "notes": [
            "Detection does not prove which playset is active.",
            "No process was started and no file was changed.",
        ],
    }


def iter_text_files(root: Path) -> Iterable[Path]:
    for current, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name not in EXCLUDED_DIRS]
        base = Path(current)
        for filename in filenames:
            path = base / filename
            if path.suffix.lower() in TEXT_EXTENSIONS:
                try:
                    if path.stat().st_size <= MAX_TEXT_FILE_BYTES:
                        yield path
                except OSError:
                    continue


def classify_match(identifier: str, line: str, suffix: str) -> str:
    stripped = line.strip()
    escaped = re.escape(identifier)
    if suffix in {".yml", ".yaml"} and re.match(rf"^{escaped}\s*:", stripped):
        return "localisation_definition"
    if re.match(rf"^{escaped}\s*=", stripped):
        return "definition"
    if re.search(rf"\b(id|name|token|spriteType|picture)\s*=\s*\"?{escaped}\"?\b", stripped):
        return "named_reference"
    return "consumer"


def search_root(
    root: Path,
    label: str,
    identifier: str,
    case_sensitive: bool,
    remaining: int,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    needle = identifier if case_sensitive else identifier.casefold()
    for path in iter_text_files(root):
        try:
            with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
                for line_number, line in enumerate(handle, start=1):
                    haystack = line if case_sensitive else line.casefold()
                    column = haystack.find(needle)
                    if column < 0:
                        continue
                    results.append(
                        {
                            "root": label,
                            "file": str(path.relative_to(root)).replace("\\", "/"),
                            "line": line_number,
                            "column": column + 1,
                            "kind": classify_match(identifier, line, path.suffix.lower()),
                            "text": line.strip()[:500],
                        }
                    )
                    if len(results) >= remaining:
                        return results
        except (OSError, UnicodeError):
            continue
    return results


def tool_trace_identifier(args: dict[str, Any]) -> dict[str, Any]:
    identifier = str(args.get("identifier", ""))
    if not identifier or len(identifier) > 256 or "\n" in identifier or "\r" in identifier:
        raise ToolInputError("identifier must be one non-empty line of at most 256 characters")
    mod_root = resolve_directory(args.get("mod_root"), "mod_root")
    game_root = resolve_directory(args.get("game_root"), "game_root", required=False)
    dependency_values = args.get("dependency_roots") or []
    if not isinstance(dependency_values, list) or len(dependency_values) > 12:
        raise ToolInputError("dependency_roots must be an array with at most 12 directories")
    dependencies = [resolve_directory(value, "dependency_root") for value in dependency_values]
    max_results = int(args.get("max_results", 200))
    if not 1 <= max_results <= 500:
        raise ToolInputError("max_results must be between 1 and 500")
    case_sensitive = bool(args.get("case_sensitive", True))

    roots: list[tuple[str, Path]] = [("mod", mod_root)]
    if game_root:
        roots.append(("vanilla", game_root))
    roots.extend((f"dependency_{index}", path) for index, path in enumerate(dependencies, start=1))

    matches: list[dict[str, Any]] = []
    for label, root in roots:
        if len(matches) >= max_results:
            break
        matches.extend(
            search_root(root, label, identifier, case_sensitive, max_results - len(matches))
        )

    counts = Counter(match["kind"] for match in matches)
    return {
        "identifier": identifier,
        "case_sensitive": case_sensitive,
        "searched_roots": [{"label": label, "path": str(root)} for label, root in roots],
        "match_count": len(matches),
        "truncated": len(matches) >= max_results,
        "counts_by_kind": dict(sorted(counts.items())),
        "matches": matches,
    }


def git_changed_paths(root: Path) -> list[str]:
    git = shutil.which("git")
    if not git:
        raise ToolInputError("Git is not available; pass paths explicitly")
    commands = [
        [git, "-C", str(root), "diff", "--name-only", "--diff-filter=ACMR", "HEAD", "--"],
        [git, "-C", str(root), "ls-files", "--others", "--exclude-standard"],
    ]
    paths: list[str] = []
    for command in commands:
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=20,
                check=False,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise ToolInputError(f"Git changed-path discovery failed: {exc}") from exc
        if result.returncode != 0:
            raise ToolInputError(result.stderr.strip() or "Git changed-path discovery failed")
        paths.extend(line.strip() for line in result.stdout.splitlines() if line.strip())
    return list(dict.fromkeys(paths))


def tool_validate_changes(args: dict[str, Any]) -> dict[str, Any]:
    mod_root = resolve_directory(args.get("mod_root"), "mod_root")
    raw_paths = args.get("paths")
    if raw_paths is None:
        raw_paths = git_changed_paths(mod_root)
    if not isinstance(raw_paths, list) or len(raw_paths) > 200:
        raise ToolInputError("paths must be an array with at most 200 entries")

    eligible_suffixes = {".txt", ".gui", ".gfx", ".yml"}
    selected: list[str] = []
    skipped: list[str] = []
    for value in raw_paths:
        candidate = ensure_inside(mod_root, str(value), "path")
        if not candidate.is_file() or candidate.suffix.lower() not in eligible_suffixes:
            skipped.append(str(value))
            continue
        selected.append(str(candidate))

    selected = list(dict.fromkeys(selected))
    if not selected:
        return {
            "read_only": True,
            "passed": True,
            "exit_code": 0,
            "validated_paths": [],
            "skipped_paths": skipped,
            "stdout": "No changed HOI4 script or localisation files required validation.",
            "stderr": "",
        }

    plugin_root = Path(__file__).resolve().parent.parent
    validator = plugin_root / "skills" / "hoi4-pdx-modding" / "scripts" / "validate-hoi4.ps1"
    if not validator.is_file():
        raise ToolInputError(f"Bundled validator is missing: {validator}")
    powershell = shutil.which("pwsh") or shutil.which("powershell") or shutil.which("powershell.exe")
    if not powershell:
        raise ToolInputError("PowerShell is required for the bundled HOI4 validator")
    command = [
        powershell,
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        (
            "$mcpPaths = ConvertFrom-Json -InputObject $env:HOI4_MCP_PATHS_JSON; "
            "& $env:HOI4_MCP_VALIDATOR -ModRoot $env:HOI4_MCP_MOD_ROOT -Paths $mcpPaths"
        ),
    ]
    process_env = os.environ.copy()
    process_env["HOI4_MCP_VALIDATOR"] = str(validator)
    process_env["HOI4_MCP_MOD_ROOT"] = str(mod_root)
    process_env["HOI4_MCP_PATHS_JSON"] = json.dumps(selected, ensure_ascii=False)
    try:
        result = subprocess.run(
            command,
            env=process_env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=120,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ToolInputError("Changed-path validation exceeded 120 seconds") from exc
    return {
        "read_only": True,
        "passed": result.returncode == 0,
        "exit_code": result.returncode,
        "validated_paths": [str(Path(path).relative_to(mod_root)).replace("\\", "/") for path in selected],
        "skipped_paths": skipped,
        "stdout": result.stdout[-30000:],
        "stderr": result.stderr[-10000:],
    }


def tail_text(path: Path, line_count: int) -> tuple[list[str], bool]:
    size = path.stat().st_size
    read_size = min(size, 2 * 1024 * 1024)
    with path.open("rb") as handle:
        if size > read_size:
            handle.seek(-read_size, os.SEEK_END)
        raw = handle.read(read_size)
    text = raw.decode("utf-8-sig", errors="replace")
    lines = text.splitlines()
    partial = size > read_size
    if partial and lines:
        lines = lines[1:]
    return lines[-line_count:], partial or len(lines) > line_count


def normalize_log_line(line: str) -> str:
    value = re.sub(r"^(?:\[[^\]]+\])+\s*", "", line.strip())
    value = re.sub(r"\bline\s+\d+\b", "line N", value, flags=re.IGNORECASE)
    return value[:500]


def tool_read_logs(args: dict[str, Any]) -> dict[str, Any]:
    explicit = args.get("user_data_root")
    user_data = (
        resolve_directory(explicit, "user_data_root")
        if explicit
        else first_existing(default_user_data_candidates())
    )
    if not user_data:
        raise ToolInputError("HOI4 user-data directory was not found; pass user_data_root")
    names = args.get("logs") or ["error", "game"]
    if not isinstance(names, list) or len(names) > 5:
        raise ToolInputError("logs must be an array with at most 5 entries")
    invalid = [name for name in names if name not in LOG_FILES]
    if invalid:
        raise ToolInputError(f"Unsupported log names: {', '.join(map(str, invalid))}")
    tail_lines = int(args.get("tail_lines", 200))
    if not 1 <= tail_lines <= 1000:
        raise ToolInputError("tail_lines must be between 1 and 1000")

    records: list[dict[str, Any]] = []
    for name in names:
        path = user_data / LOG_FILES[name]
        if not path.is_file():
            records.append({"name": name, "path": str(path), "exists": False})
            continue
        lines, truncated = tail_text(path, tail_lines)
        counts = Counter(normalize_log_line(line) for line in lines if line.strip())
        records.append(
            {
                "name": name,
                "path": str(path),
                "exists": True,
                "bytes": path.stat().st_size,
                "modified_unix_seconds": path.stat().st_mtime,
                "tail_truncated": truncated,
                "repeated_messages": [
                    {"count": count, "message": message}
                    for message, count in counts.most_common(12)
                    if count > 1
                ],
                "lines": lines,
            }
        )
    return {
        "read_only": True,
        "user_data_root": str(user_data),
        "logs": records,
        "notes": ["Existing log timestamps do not prove that they belong to the latest test run."],
    }


def png_info(data: bytes) -> dict[str, Any]:
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ToolInputError("Invalid PNG header")
    width, height = struct.unpack(">II", data[16:24])
    return {"container": "PNG", "width": width, "height": height}


def gif_info(data: bytes) -> dict[str, Any]:
    if len(data) < 10 or data[:6] not in {b"GIF87a", b"GIF89a"}:
        raise ToolInputError("Invalid GIF header")
    width, height = struct.unpack("<HH", data[6:10])
    return {"container": data[:6].decode("ascii"), "width": width, "height": height}


def jpeg_info(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if not data.startswith(b"\xff\xd8"):
        raise ToolInputError("Invalid JPEG header")
    index = 2
    sof_markers = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}
    while index + 9 <= len(data):
        if data[index] != 0xFF:
            index += 1
            continue
        marker = data[index + 1]
        index += 2
        if marker in {0xD8, 0xD9}:
            continue
        if index + 2 > len(data):
            break
        length = struct.unpack(">H", data[index:index + 2])[0]
        if marker in sof_markers and index + 7 <= len(data):
            height, width = struct.unpack(">HH", data[index + 3:index + 7])
            return {"container": "JPEG", "width": width, "height": height}
        index += max(length, 2)
    raise ToolInputError("JPEG dimensions were not found")


def dds_info(data: bytes) -> dict[str, Any]:
    if len(data) < 128 or data[:4] != b"DDS ":
        raise ToolInputError("Invalid DDS header")
    height, width = struct.unpack("<II", data[12:20])
    mipmaps = struct.unpack("<I", data[28:32])[0] or 1
    fourcc = data[84:88].decode("ascii", errors="replace").rstrip("\x00")
    rgb_bits = struct.unpack("<I", data[88:92])[0]
    pixel_format = fourcc or (f"RGB{rgb_bits}" if rgb_bits else "unclassified")
    if fourcc == "DX10" and len(data) >= 148:
        dxgi = struct.unpack("<I", data[128:132])[0]
        pixel_format = f"DX10/DXGI_{dxgi}"
    return {
        "container": "DDS",
        "width": width,
        "height": height,
        "mipmaps": mipmaps,
        "pixel_format": pixel_format,
    }


def ffprobe_info(path: Path) -> dict[str, Any]:
    ffprobe = shutil.which("ffprobe") or shutil.which("ffprobe.exe")
    if not ffprobe:
        return {"ffprobe_available": False}
    try:
        result = subprocess.run(
            [
                ffprobe,
                "-v",
                "error",
                "-show_entries",
                "format=format_name,duration,bit_rate:stream=index,codec_type,codec_name,width,height,sample_rate,channels,pix_fmt",
                "-of",
                "json",
                str(path),
            ],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=20,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"ffprobe_available": True, "error": "ffprobe timed out"}
    if result.returncode != 0:
        return {"ffprobe_available": True, "error": result.stderr.strip()[:1000]}
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"ffprobe_available": True, "error": "ffprobe returned invalid JSON"}
    payload["ffprobe_available"] = True
    return payload


def inspect_media_file(path: Path, root: Path, include_sha256: bool) -> dict[str, Any]:
    suffix = path.suffix.lower()
    record: dict[str, Any] = {
        "path": str(path.relative_to(root)).replace("\\", "/"),
        "bytes": path.stat().st_size,
        "extension": suffix,
    }
    try:
        with path.open("rb") as handle:
            header = handle.read(256)
        if suffix == ".png":
            record.update(png_info(header))
        elif suffix == ".gif":
            record.update(gif_info(header))
        elif suffix in {".jpg", ".jpeg"}:
            record.update(jpeg_info(path))
        elif suffix == ".dds":
            record.update(dds_info(header))
        else:
            record.update(ffprobe_info(path))
        if include_sha256:
            digest = hashlib.sha256()
            with path.open("rb") as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                    digest.update(chunk)
            record["sha256"] = digest.hexdigest()
    except (OSError, ToolInputError) as exc:
        record["error"] = str(exc)
    return record


def tool_inspect_media(args: dict[str, Any]) -> dict[str, Any]:
    mod_root = resolve_directory(args.get("mod_root"), "mod_root")
    raw_paths = args.get("paths")
    if raw_paths is None:
        raw_paths = [path for path in git_changed_paths(mod_root) if Path(path).suffix.lower() in MEDIA_EXTENSIONS]
    if not isinstance(raw_paths, list) or len(raw_paths) > 100:
        raise ToolInputError("paths must be an array with at most 100 entries")
    include_sha256 = bool(args.get("include_sha256", False))

    selected: list[Path] = []
    skipped: list[str] = []
    for value in raw_paths:
        candidate = ensure_inside(mod_root, str(value), "path")
        if not candidate.is_file() or candidate.suffix.lower() not in MEDIA_EXTENSIONS:
            skipped.append(str(value))
            continue
        selected.append(candidate)
    selected = list(dict.fromkeys(selected))
    return {
        "read_only": True,
        "mod_root": str(mod_root),
        "inspected_count": len(selected),
        "skipped_paths": skipped,
        "files": [inspect_media_file(path, mod_root, include_sha256) for path in selected],
        "notes": [
            "Disk size is not GPU memory use.",
            "Image dimensions and container metadata do not prove that a particular HOI4 consumer accepts the file.",
        ],
    }


TOOL_HANDLERS = {
    "detect_hoi4_environment": tool_detect_environment,
    "trace_hoi4_identifier": tool_trace_identifier,
    "validate_hoi4_changes": tool_validate_changes,
    "read_hoi4_logs": tool_read_logs,
    "inspect_hoi4_media": tool_inspect_media,
}


def handle_request(message: dict[str, Any]) -> None:
    method = message.get("method")
    request_id = message.get("id")
    if request_id is None:
        return
    if method == "initialize":
        requested = str((message.get("params") or {}).get("protocolVersion") or "")
        protocol = requested if requested in SUPPORTED_PROTOCOLS else LATEST_PROTOCOL
        rpc_result(
            request_id,
            {
                "protocolVersion": protocol,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                "instructions": "Local-first HOI4 evidence tools. All exposed operations are read-only and never launch the game.",
            },
        )
        return
    if method == "ping":
        rpc_result(request_id, {})
        return
    if method == "tools/list":
        rpc_result(request_id, {"tools": TOOLS})
        return
    if method == "tools/call":
        params = message.get("params") or {}
        name = params.get("name")
        if name not in TOOL_HANDLERS:
            rpc_error(request_id, -32602, f"Unknown tool: {name}")
            return
        arguments = params.get("arguments") or {}
        if not isinstance(arguments, dict):
            rpc_error(request_id, -32602, "Tool arguments must be an object")
            return
        try:
            result = TOOL_HANDLERS[name](arguments)
        except ToolInputError as exc:
            rpc_result(request_id, as_tool_result({"error": str(exc)}, is_error=True))
        except Exception as exc:  # keep local failures actionable without killing the server
            print(f"{name} failed: {type(exc).__name__}: {exc}", file=sys.stderr)
            rpc_result(
                request_id,
                as_tool_result(
                    {"error": f"{name} failed locally: {type(exc).__name__}: {exc}"},
                    is_error=True,
                ),
            )
        else:
            rpc_result(request_id, as_tool_result(result))
        return
    rpc_error(request_id, -32601, f"Method not found: {method}")


def main() -> int:
    for raw in sys.stdin.buffer:
        if len(raw) > MAX_MESSAGE_BYTES:
            print("Rejected oversized MCP message", file=sys.stderr)
            return 65
        if not raw.strip():
            continue
        try:
            message = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            rpc_error(None, -32700, f"Parse error: {exc}")
            continue
        if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
            rpc_error(message.get("id") if isinstance(message, dict) else None, -32600, "Invalid JSON-RPC request")
            continue
        handle_request(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
