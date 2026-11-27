#!/usr/bin/env python3
"""Offline + live-merged Hearts of Iron IV console command lookup catalog.

Zero external dependencies (Python 3 stdlib only). Shared by both the read-only
`hoi4_local` MCP server (`hoi4_mcp.py`) and the optional `hoi4_desktop` MCP
server (`hoi4_desktop_mcp.py`).
"""

from __future__ import annotations

import difflib
import json
import re
from pathlib import Path
from typing import Any


CATALOG_FILENAME = "hoi4_console_commands.json"

CATEGORIES: dict[str, str] = {
    "script_eval": "Inline/scripted effects, triggers, flags, variables, and modifiers",
    "events_decisions": "Events, decisions, timed missions, and national spirits/ideas",
    "focus_tech": "National focuses, technologies, and doctrines",
    "resources_economy": "PP, CP, XP, manpower, fuel, stability, war support, equipment, and market",
    "military_units": "Units, armies, fleets, air, nukes, raids, combat, and supply",
    "diplomacy_map": "Tags, annexation, puppets, wars, states, provinces, cores, and occupation",
    "factions_bop": "Factions, Balance of Power (BOP), and politics/ideologies",
    "mio_sp_agency": "MIOs, Special Projects, scientists, and Intelligence Agency / operatives",
    "gui_reload_debug": "Hot reload, GUI/GFX/loc checks, tooltips, windows, and visual debug",
    "logging_profiling": "Logs, AI diagnostics, timers, profilers, checksums, and docs",
    "time_camera_session": "Game speed, pause, fast forward, save, camera, weather, and session",
    "tweakables": "Engine tweakable boolean/numeric variables (prefer explicit 1 / 0)",
}

# Lightweight categorization fallback for live-parsed commands from future HOI4 builds.
def infer_category(name: str, kind: str, description: str) -> str:
    low = name.lower()
    desc = description.lower()
    if kind == "tweakable":
        if low.startswith(("decision.",)):
            return "events_decisions"
        if low.startswith(("focus.",)):
            return "focus_tech"
        if low.startswith(("agency.", "operation.", "intelnetwork.", "counterintelligence.")):
            return "mio_sp_agency"
        if low in {"guibounds"} or low.startswith(("gui.", "draw.", "mesh.", "particle.", "posteffect")):
            return "gui_reload_debug"
        return "tweakables"
    if low in {
        "eval_effect", "eval_trigger", "effect", "trigger",
        "set_country_flag", "get_country_flag", "set_global_flag",
        "set_flag", "get_flag", "list_flags", "set_var", "get_var", "list_vars",
        "list_modifiers", "list_leader_modifiers",
    }:
        return "script_eval"
    if low in {
        "event", "testevent", "instantevents", "debug_events", "debug_dumpevents",
        "debug_show_event_id", "easy_decisions", "finish_decision",
        "add_ideas", "remove_ideas", "list_ideas", "allowideas",
    }:
        return "events_decisions"
    if low in {
        "freefocuses", "show_focuses", "list_hidden_focuses", "focus_count",
        "research", "research_fast", "research_on_icon_click", "add_tech", "clear_tech",
        "toggle_hidden_techs", "mastery",
    }:
        return "focus_tech"
    if low in {
        "pp", "cp", "xp", "show_xp_gain", "manpower", "fuel", "fuel_gain",
        "empty_fuel_tanks", "add_stability", "add_war_support",
        "add_equipment", "add_latest_equipment", "add_cic_bank", "energy_ratio",
        "add_subsidies", "add_subsidies_second", "prices", "traderoutes",
    } or low.startswith("internationalmarket."):
        return "resources_economy"
    if low.startswith(("bop_", "faction_")) or low in {
        "set_ruling_party", "add_party_popularity", "retire_country_leader",
        "add_legitimacy", "add_exile_manpower",
    }:
        return "factions_bop"
    if low.startswith(("sp_", "operation_", "agency.")) or low in {
        "addfunds", "addsize", "addtaskcapacity",
        "add_intel", "clear_intel_pools", "grow_intel_network", "print_intel_network",
        "print_intel_values", "print_radar_intel", "print_operation_tokens",
        "allowoperations", "force_operative_detection", "prevent_operative_detection",
        "emulate_ai_operative_assignment", "add_fake_armies", "collaboration",
    }:
        return "mio_sp_agency"
    if low.startswith(("loc_check", "reload", "update", "debug_", "dbg_")) or low in {
        "guibounds", "provtooltipdebug", "window", "imgui", "cityreload",
        "rebuildlayers", "gbreload", "gbpaint", "nudge", "province_ids",
        "mapmode", "mapnames", "nomapicons", "nopausetext", "railroads",
        "fronts", "fow", "collision", "bloom", "hdr", "hdr_debug", "srgb",
        "3dstats", "rendertype", "fullscreen", "flagsoutput", "dump_equipment_loc",
        "createlean", "hsv", "tag_color", "spawnactor", "spawn_3d_models",
        "show_medal", "show_all_medals", "show_ribbon", "show_all_ribbons",
        "forget_medals_and_ribbons", "audio.playeffect", "combatsound",
    }:
        return "gui_reload_debug"
    if low.startswith(("ai", "timer", "profile", "dump_", "scenario_testing.", "pathfind_", "oos")) or low in {
        "help", "helphelp", "helplog", "error", "trigger_docs", "version",
        "gamestate_timer", "ct", "metrics", "history_logger", "test_log",
        "test_save_mode", "testrtti", "testtool", "test", "log_advisor_trait_errors",
        "compare_to_last_checksum", "printsynchstuff", "setrandomcount", "random_seed",
        "randomlog", "savecheck", "listincorrectcenterofregions", "force_tamper",
        "crashreporter.deletecrashdata", "crashreporter.simulatecrash",
        "track_unit_controller_weights", "disable_ai", "enable_ai", "human_ai",
    }:
        return "logging_profiling"
    if low in {
        "tag", "observe", "annex", "puppet", "release", "whitepeace", "civilwar",
        "allowdiplo", "no_wargoal", "instant_wargoal", "add_diplo",
        "add_opinion", "reduce_opinion", "add_autonomy", "threat",
        "setowner", "setcontroller", "add_core", "remove_core",
        "occupationpaint", "compliance", "resistance", "set_cosmetic_tag",
        "drop_cosmetic_tag", "get_capital", "war_relations", "build_war_blobs",
        "massconquer", "prep_for_war", "morehumans", "morehumanswithcountries",
        "print_controllers",
    }:
        return "diplomacy_map"
    if low in {
        "gamespeed", "fast_forward", "pause_in_hours", "pause_on_trigger",
        "auto_unpause", "time", "sleep", "run", "savegame", "resign", "exit",
        "restart", "ironman", "deironman", "lobby_id", "goto_province",
        "goto_state", "goto_region", "cameraclamp", "deltat", "weather",
        "enable_weather", "disable_weather", "set_weather", "add_rain",
        "add_snow", "set_mud", "night",
    }:
        return "time_camera_session"
    if any(
        tok in low or tok in desc
        for tok in (
            "unit", "army", "armies", "ship", "naval", "air", "nuke", "raid",
            "combat", "supply", "front", "theatre", "theater", "teleport",
            "training", "construction", "invasion", "mines", "leader", "commander",
            "trait", "ability", "acclimatization", "railwaygun", "encirclement",
            "building_health", "armageddon", "capture_commander",
        )
    ):
        return "military_units"
    return "gui_reload_debug"


def parse_console_docs_markdown(path: Path) -> list[dict[str, Any]]:
    """Parse HOI4's installed documentation/console_commands_documentation.md."""
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    parts = text.split("## All Tweakable Variables")
    cmd_part = parts[0]
    var_part = parts[1] if len(parts) > 1 else ""

    def _parse(section: str, kind: str) -> list[dict[str, Any]]:
        out: list[dict[str, Any]] = []
        for block in re.split(r"(?m)^## ", section)[1:]:
            lines = block.splitlines()
            name = lines[0].strip()
            if not name or name in {"Table of Content", "All Console Commands"}:
                continue
            aliases: list[str] = []
            arguments = ""
            var_type = ""
            release_available = True
            desc_lines: list[str] = []
            for raw in lines[1:]:
                stripped = raw.strip()
                if stripped.startswith("* Aliases:"):
                    aliases = [a.strip() for a in stripped.split(":", 1)[1].split(",") if a.strip()]
                elif stripped.startswith("* Arguments:"):
                    arguments = stripped.split(":", 1)[1].strip()
                elif stripped.startswith("* Type:"):
                    var_type = stripped.split(":", 1)[1].strip()
                elif stripped == "* Not available in release build":
                    release_available = False
                elif stripped:
                    desc_lines.append(stripped)
            description = " ".join(desc_lines).strip()
            if len(description) >= 2 and description.startswith('"') and description.endswith('"'):
                description = description[1:-1].strip()
            out.append(
                {
                    "name": name,
                    "kind": kind,
                    "category": infer_category(name, kind, description),
                    "aliases": aliases,
                    "arguments": arguments,
                    "value_type": var_type,
                    "release_available": release_available,
                    "affects_ai": False,
                    "description": description,
                    "examples": [],
                    "notes": "",
                    "keywords": [],
                }
            )
        return out

    merged: dict[str, dict[str, Any]] = {}
    for entry in _parse(cmd_part, "command") + _parse(var_part, "tweakable"):
        key = entry["name"].casefold()
        if key in merged:
            existing = merged[key]
            if not existing.get("value_type") and entry.get("value_type"):
                existing["value_type"] = entry["value_type"]
            if not existing.get("description") and entry.get("description"):
                existing["description"] = entry["description"]
            existing["aliases"] = list(dict.fromkeys(existing["aliases"] + entry["aliases"]))
            continue
        merged[key] = entry
    return list(merged.values())


def _bundled_catalog_path() -> Path:
    return Path(__file__).resolve().parent / CATALOG_FILENAME


def load_catalog(game_root: Path | None = None) -> dict[str, Any]:
    """Load the bundled console catalog and optionally merge live installed docs."""
    bundled_path = _bundled_catalog_path()
    if bundled_path.is_file():
        data = json.loads(bundled_path.read_text(encoding="utf-8-sig"))
    else:
        data = {
            "schema_version": 1,
            "game_version": "unknown",
            "source": "live-only",
            "commands": [],
        }

    entries_by_key: dict[str, dict[str, Any]] = {
        item["name"].casefold(): dict(item) for item in data.get("commands", [])
    }
    sources = [f"bundled:{data.get('game_version', 'unknown')}"]

    live_doc: Path | None = None
    if game_root is not None:
        candidate = game_root / "documentation" / "console_commands_documentation.md"
        if candidate.is_file():
            live_doc = candidate

    if live_doc is not None:
        live_entries = parse_console_docs_markdown(live_doc)
        added = 0
        for item in live_entries:
            key = item["name"].casefold()
            if key not in entries_by_key:
                entries_by_key[key] = item
                added += 1
            else:
                # Trust the live install for release-build availability and new aliases.
                existing = entries_by_key[key]
                existing["release_available"] = item["release_available"]
                if item["aliases"]:
                    existing["aliases"] = list(dict.fromkeys(existing.get("aliases", []) + item["aliases"]))
                if not existing.get("description") and item.get("description"):
                    existing["description"] = item["description"]
                if not existing.get("arguments") and item.get("arguments"):
                    existing["arguments"] = item["arguments"]
        sources.append(f"installed_doc:{live_doc} (+{added} new)")

    commands = sorted(entries_by_key.values(), key=lambda c: c["name"].casefold())
    return {
        "schema_version": data.get("schema_version", 1),
        "game_version": data.get("game_version", "unknown"),
        "sources": sources,
        "total_commands": len(commands),
        "release_commands": sum(1 for c in commands if c.get("release_available", True)),
        "commands": commands,
    }


def _score_entry(entry: dict[str, Any], query: str, tokens: list[str]) -> int:
    q = query.casefold()
    name = entry["name"].casefold()
    aliases = [a.casefold() for a in entry.get("aliases", [])]
    keywords = [k.casefold() for k in entry.get("keywords", [])]
    desc = (entry.get("description") or "").casefold()
    notes = (entry.get("notes") or "").casefold()
    args = (entry.get("arguments") or "").casefold()
    examples = " ".join(entry.get("examples", [])).casefold()
    category = (entry.get("category") or "").casefold()

    score = 0
    if q == name:
        score += 1000
    elif q in aliases:
        score += 950
    elif name.startswith(q):
        score += 700
    elif any(a.startswith(q) for a in aliases):
        score += 650
    elif q in keywords:
        score += 600
    elif q in name:
        score += 500
    elif any(q in a for a in aliases):
        score += 450
    elif any(q in k for k in keywords):
        score += 420
    elif q in desc or q in notes:
        score += 300
    elif q in args or q in examples or q in category:
        score += 220

    if len(tokens) > 1:
        haystack = " ".join([name, " ".join(aliases), " ".join(keywords), desc, notes, args, examples, category])
        matched = sum(1 for tok in tokens if tok in haystack)
        if matched == len(tokens):
            score += 320 + 25 * matched
        elif matched > 0:
            score += 60 * matched
    elif len(tokens) == 1 and score == 0:
        tok = tokens[0]
        haystack = " ".join([name, " ".join(aliases), " ".join(keywords), desc, notes, args, examples, category])
        if tok in haystack:
            score += 180

    # Small priority boost for curated high-frequency commands and release builds.
    if score > 0:
        if entry.get("examples") or entry.get("notes"):
            score += 15
        if entry.get("release_available", True):
            score += 10
    return score


def lookup_console_commands(
    query: str = "",
    category: str = "all",
    release_only: bool = True,
    limit: int = 20,
    game_root: Path | None = None,
) -> dict[str, Any]:
    """Search HOI4 console commands by name, alias, category, or Chinese/English intent."""
    cat = (category or "all").strip().lower()
    if cat != "all" and cat not in CATEGORIES:
        raise ValueError(
            f"Unsupported category '{category}'. Choose 'all' or one of: {', '.join(sorted(CATEGORIES))}."
        )
    bounded_limit = max(1, min(100, int(limit)))
    catalog = load_catalog(game_root=game_root)
    commands = catalog["commands"]

    if cat != "all":
        commands = [c for c in commands if c.get("category") == cat]

    q = (query or "").strip()
    tokens = [t for t in re.split(r"[\s,;/|]+", q.casefold()) if t]

    dev_only_warnings: list[dict[str, Any]] = []
    if not q:
        pool = [c for c in commands if (c.get("release_available", True) or not release_only)]
        # When browsing without a query, show curated high-value entries first.
        pool.sort(
            key=lambda c: (
                0 if (c.get("examples") or c.get("notes")) else 1,
                c["name"].casefold(),
            )
        )
        matched = pool[:bounded_limit]
        total_matches = len(pool)
    else:
        scored_release: list[tuple[int, dict[str, Any]]] = []
        scored_dev: list[tuple[int, dict[str, Any]]] = []
        for entry in commands:
            sc = _score_entry(entry, q, tokens)
            if sc <= 0:
                continue
            if entry.get("release_available", True):
                scored_release.append((sc, entry))
            else:
                scored_dev.append((sc, entry))

        scored_release.sort(key=lambda pair: (-pair[0], pair[1]["name"].casefold()))
        scored_dev.sort(key=lambda pair: (-pair[0], pair[1]["name"].casefold()))

        if release_only:
            matched = [item for _, item in scored_release[:bounded_limit]]
            total_matches = len(scored_release)
            # Surface exact/prefix dev-only hits so AI immediately knows why e.g. 'spawn' or 'exit' won't work in retail HOI4.
            for sc, item in scored_dev[:5]:
                if sc >= 500:
                    dev_only_warnings.append(
                        {
                            "name": item["name"],
                            "aliases": item.get("aliases", []),
                            "reason": "Marked 'Not available in release build' in official HOI4 documentation; unavailable on retail Steam builds.",
                            "notes": item.get("notes", ""),
                        }
                    )
        else:
            combined = sorted(scored_release + scored_dev, key=lambda pair: (-pair[0], pair[1]["name"].casefold()))
            matched = [item for _, item in combined[:bounded_limit]]
            total_matches = len(combined)

    result: dict[str, Any] = {
        "read_only": True,
        "game_version": catalog["game_version"],
        "sources": catalog["sources"],
        "query": q,
        "category": cat,
        "release_only": release_only,
        "total_catalog_commands": catalog["total_commands"],
        "release_catalog_commands": catalog["release_commands"],
        "match_count": len(matched),
        "total_matches": total_matches,
        "categories": CATEGORIES,
        "matches": [
            {
                k: v
                for k, v in item.items()
                if k != "keywords" and v not in ("", [], None)
            }
            for item in matched
        ],
    }
    if dev_only_warnings:
        result["dev_only_warnings"] = dev_only_warnings
    if q and not matched and not dev_only_warnings:
        all_names = [c["name"] for c in catalog["commands"] if c.get("release_available", True) or not release_only]
        suggestions = difflib.get_close_matches(q, all_names, n=5, cutoff=0.45)
        if suggestions:
            result["did_you_mean"] = suggestions
    return result


def inspect_console_command(command: str, game_root: Path | None = None) -> dict[str, Any]:
    """Non-blocking preflight lint for a single console command string before/after execution."""
    stripped = (command or "").strip()
    if not stripped:
        return {}
    parts = stripped.split(None, 1)
    head = parts[0]
    rest = parts[1] if len(parts) > 1 else ""
    head_low = head.casefold()

    catalog = load_catalog(game_root=game_root)
    by_token: dict[str, dict[str, Any]] = {}
    for entry in catalog["commands"]:
        by_token[entry["name"].casefold()] = entry
        for alias in entry.get("aliases", []):
            by_token[alias.casefold()] = entry

    advisories: list[str] = []
    entry = by_token.get(head_low)

    # Catch the #1 real-world AI console blunder: 'effect set_country_flag = foo' instead of 'eval_effect ...'
    if head_low in {"effect", "e"} and ("=" in rest or "{" in rest):
        advisories.append(
            "Syntax warning: 'effect' (alias 'e') runs a named scripted_effect (<tag> <scripted_effect_name>). "
            "For inline PDX effect code containing '=' or '{ }', use 'eval_effect " + rest + "' instead."
        )
    elif head_low in {"trigger", "t"} and ("=" in rest or "{" in rest):
        advisories.append(
            "Syntax warning: 'trigger' (alias 't') runs a named scripted_trigger (<tag> <scripted_trigger_name>). "
            "For inline PDX trigger code containing '=' or '{ }', use 'eval_trigger " + rest + "' instead."
        )

    if entry is not None:
        if not entry.get("release_available", True):
            advisories.append(
                f"Release-build warning: '{entry['name']}' is marked 'Not available in release build' "
                "in HOI4 documentation and is unavailable on retail Steam builds."
            )
        if entry.get("affects_ai"):
            advisories.append(
                f"AI-scope note: '{entry['name']}' also affects AI countries while enabled; pause first or disable after testing."
            )
        if entry.get("kind") == "tweakable" and entry.get("value_type") == "Boolean" and not rest:
            advisories.append(
                f"Idempotency tip: '{entry['name']}' is a boolean tweakable; pass '1' to force-enable or '0' to force-disable instead of blind toggling."
            )
    else:
        close = difflib.get_close_matches(head_low, list(by_token.keys()), n=3, cutoff=0.6)
        if close:
            canonical = list(dict.fromkeys(by_token[tok]["name"] for tok in close))
            advisories.append(
                f"Unrecognized command '{head}' in HOI4 {catalog['game_version']} catalog. "
                f"Did you mean: {', '.join(canonical)}? Call lookup_hoi4_console_commands to verify."
            )

    if not advisories:
        return {}
    return {
        "matched_command": entry["name"] if entry else None,
        "advisories": advisories,
    }
