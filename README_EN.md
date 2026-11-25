# HOI4 AI Modding Skills

[简体中文](README.md) | English | [日本語](README_JA.md) | [Русский](README_RU.md) | [한국어](README_KO.md)

A composable suite of three Agent Skills for *Hearts of Iron IV* modding across **Codex, Google Antigravity, Cursor, Claude Code, Gemini CLI, and ChatGPT**.

The suite is **focused primarily on maintaining, auditing, and improving existing mods**—unraveling unfamiliar codebases, fixing cross-file bugs, tuning performance, guarding compatibility, and triaging crashes—while retaining a complete workflow for **creating new features and full mods from plain English** without writing PDX script by hand.

For an end-to-end handbook on working with AI across requests, scripts, saves, GUI, shaders, media, localisation, diagnosis, and Git delivery, see the General Modding Guide:
[English](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.en.md) |
[简体中文](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.zh-CN.md) |
[日本語](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.ja.md) |
[Русский](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.ru.md) |
[한국어](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.ko.md).
The guide is written for human readers and delivered on demand—the skills keep only the delivery rule in their entrypoints so ordinary coding turns stay lean.

The repository also ships two **physically separated**, zero-dependency local MCP servers:
- **Read-only evidence server (`hoi4_local`)**, bundled with the Codex Plugin: discovers your local HOI4 installation, traces identifiers across files, validates Git changes, reads logs, and inspects media metadata—entirely offline, read-only, and free of any API-key requirement. See [Local Plugin and MCP Helper](docs/LOCAL_MCP_PLUGIN_EN.md).
- **Optional live-test control server (`hoi4_desktop`)**, disabled by default and enabled only on request: brings process-whitelisted Windows screenshot and input control (`hoi4.exe`, Paradox Launcher, and Steam only) to clients without built-in desktop computer use, such as Google Antigravity, Cursor, Claude Code, and Gemini CLI. See [Desktop MCP Setup Guide](docs/DESKTOP_MCP_SETUP_EN.md).

## The Three Skills

| Skill | Focus |
| --- | --- |
| `hoi4-review-debug` | Existing-mod audits, cross-file Mod Doctor, log and crash triage, performance tuning, compatibility checks, gameplay balance, UX, and asset reviews |
| `hoi4-pdx-modding` | PDX syntax and scopes, variable and save lifecycle, cross-file contracts, localisation, version migration, technical docs, comments, and static validation |
| `hoi4-content-builder` | End-to-end events, decisions, focuses, characters, ideas, MIOs, GUI, AI, OOBs, maps, music, models, and complete systems from plain-language ideas |

**Install all three skills together.** They work as one workshop: `content-builder` turns ideas into wired features, `pdx-modding` enforces target-version syntax and contracts, and `review-debug` handles audits, regressions, and runtime evidence. Installing the full trio keeps every cross-skill reference and handoff intact.

## Installation

### Codex: Skills + Read-Only Local MCP Plugin (Recommended)

On Windows, clone or extract this repository and run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

The script installs the plugin into your user local app-data folder and registers it via the Codex CLI—touching neither HOI4 nor Steam, and sending nothing over the network. **Start a fresh Codex task** once installation finishes to load all three skills and the five read-only MCP tools. Rerun the same command after pulling updates.

Requirements: Windows, Python 3, and the Codex CLI (`ffprobe` is optional for extra audio/video stream metadata). See [Local Plugin and MCP Helper](docs/LOCAL_MCP_PLUGIN_EN.md) for details and troubleshooting.

### Skills Only (Works Across Clients)

Download a release package from [Releases](https://github.com/Fostanico/hoi4-ai-modding-skills/releases) or clone the repository, then copy all three directories under `skills/` into:

- **Project scope** (versioned with one mod): `<MOD_ROOT>/.agents/skills/`
- **User scope** (shared across mods): `$HOME/.agents/skills/`

Keep `SKILL.md`, `references/`, `workflows/`, `assets/`, `scripts/`, and `agents/` intact inside each skill folder.

- **Codex & ChatGPT**: Codex picks up updates automatically (restart if needed). Run `/skills` to inspect installed skills or invoke one directly with `$hoi4-review-debug`; ChatGPT desktop lists uploaded skills on the sidebar Skills page. See [OpenAI's Skills documentation](https://learn.chatgpt.com/docs/build-skills).
- **Cursor**: Discovers `.agents/skills/` and `.cursor/skills/` at both project and user levels (`~/`). Reopen or refresh Agent to load them, or type `/` in chat to invoke a skill explicitly. Skills work with whichever model you select; enable Skills sync in Cursor settings to share `~/.cursor/skills/` with Cloud Agents. See [Cursor Agent Skills documentation](https://cursor.com/docs/skills).
- **Google Antigravity, Claude Code & Gemini CLI**: Install the three skills into the client's skills directory, and optionally wire up `hoi4_local` and `hoi4_desktop` MCP servers.

Full per-client instructions and distribution rules live in [Installation and Sharing](docs/INSTALLATION_EN.md).

## Example Prompts

**Audit an existing mod before changing a line:**

> `$hoi4-review-debug` Review this mod. Start with the project's technical guide and relevant player-facing localisation, then check cross-file references, variable lifecycles, periodic performance, icons, localisation, and dependency compatibility. Share an evidence-backed report and staged repair plan before editing anything.

**Triage `error.log` cleanly:**

> Analyze this `error.log`. Separate issues caused by this mod, dependencies, vanilla, and optional media. Group repeated entries by root cause and propose the smallest clean fix for each group.

**Build new content from plain English:**

> `$hoi4-content-builder` Build a repeatable decision set for HOI4 1.20 with AI weights and English, Simplified Chinese, Russian, Japanese, and Korean localisation. Verify syntax against the current vanilla build first, then run changed-file static checks.

You can let compatible agents auto-select a skill from your request, or name one explicitly whenever you want a structured audit or diagnostic run.

## Core Workflows

All three skills follow [shared workflow boundaries](skills/hoi4-pdx-modding/references/workflow-boundaries.md): reuse valid evidence, recheck only affected paths after local edits, update docs when real contracts change, keep short in-game test budgets inclusive of setup and cleanup, and stop promptly with a concise handoff whenever you say stop.

### 1. Improve an Existing Mod

1. Read the project's technical guide, handoff notes, and player-facing localisation to understand the intended design.
2. Map real call chains across events, decisions, effects, triggers, variables, flags, localisation, GUI, and GFX.
3. Separate confirmed defects, compatibility hazards, performance bottlenecks, and gameplay trade-offs that need author sign-off.
4. Present evidence and a staged plan before editing whenever approval is required.
5. Apply only the agreed scope, scale static verification to the size of the diff (read-only diff review for tiny tweaks, changed-file scripts for normal edits, broader checks for cross-file refactors), and state what still calls for an in-game look.

### 2. Diagnose Logs and Crashes

1. Group `error.log` by root cause, tackling parser, scope, equipment, ideology, and localisation failures first.
2. Match timestamps, active playset, and the player's last actions to real code paths instead of blaming the final log line.
3. Inspect Windows minidumps when warranted, reporting confidence levels alongside any missing evidence.
4. Gate deeper native steps—WinDbg, Ghidra, full memory dumps, process attachment, and hardware data breakpoints—behind explicit staged consent.

### 3. Build New Content

1. Turn plain-language ideas into clear scope, state ownership, assets, AI rules, compatibility expectations, and acceptance criteria.
2. Check syntax and tokens directly against the target build's vanilla files, generated docs, and enabled dependencies.
3. Assemble scripts, GFX, assets, and localisation from verified templates and kits with every entry point connected.
4. Verify encoding, cross-file references, and affected docs in proportion to the change, and honor test authorization and time budgets whenever runtime proof is needed.

## Coverage

- **Script & state**: PDX syntax, scope chains, event targets, variables, and flag lifecycles
- **Core gameplay**: events, decisions, focuses, ideas, characters, MIOs, equipment, technology, AI, and OOBs
- **Performance**: high-frequency `on_actions`, global scans, cadence design, and event-driven or batched updates
- **Localisation**: UTF-8 BOM encoding, duplicate keys, color/icon codes, formatted variables, scope functions, and multilingual templates
- **UI & media**: GUI/GFX registration, idea/decision/trait icons, texture paths, audio, loading-screen DDS rules, named aces, and custom operative traits/portraits
- **Compatibility & migration**: vanilla and total-conversion compatibility branches, major-version upgrades, and save-safe state evolution
- **Player experience & docs**: gameplay loops, balance, AI usability, feedback, counterplay, technical guides, readable comments, and release checklists
- **Native diagnostics**: `error.log` triage, crash dumps, WinDbg, and consent-gated deeper native analysis

## Engineering Highlights

- **Real-dialogue regression suite**: `evals/real-dialogue-regression.json` captures anonymized real modding tasks traced via SHA-256 prompt fingerprints, keeping private chats and project identifiers out of the repo.
- **Mod Doctor 2**: resolves the active playset, scopes audits to Git changes, diffs against prior baselines, honors expiring suppression rules, separates confirmed defects from heuristic leads, and outputs Text, JSON, Markdown, or SARIF.
- **Multi-file kits**: cover established content chains plus technology-to-equipment unlocks and game-rule startup initialization.
- **Template manifest**: `assets/template-manifest.json` tracks target build, vanilla source consumers, verification dates, and required checks, enforced by a manifest validator.
- **Consumer-aware media audits**: inspect DDS metadata, explicit references, and real conversion candidates, computing hashes only for explicit duplicate or content checks while respecting loading-screen, mipmap, cubemap, and model-material constraints.

## Evidence and Safety Principles

- **Verify against the live build**: skills direct the agent to check the target installation's vanilla files, shipped documentation, enabled dependencies, and player-facing text. Wikis and community guides are helpful starting points; your installed build has the final say.
- **Pair static checks with runtime checks**: static checks catch syntax, references, encoding, and wiring; GUI rendering, MIO interactions, complex scopes, and cross-mod compatibility belong in an in-game run.
- **Explicit consent for elevated actions**: launching Steam, controlling game windows, installing diagnostic tools, reverse engineering, attaching to processes, or capturing full memory always starts with a clear explanation of purpose, scope, and risk—and waits for your go-ahead.

## License and Acknowledgements

Licensed under [CC BY-SA 4.0](LICENSE). Keep attribution and [ATTRIBUTION.md](ATTRIBUTION.md), note your changes, and share adaptations under the same license. This license covers the published skills in this repository; Paradox Interactive, other mods, and third-party assets remain under their respective rights holders.

Acknowledgements:
- [Millennium Dawn](https://github.com/MillenniumDawn/Millennium-Dawn), whose open development docs shaped compatibility practices, project structure, and advanced workflows.
- Qiuqi Library (秋起图书馆, Steam Workshop item `3445449478`), whose community tutorials and tooling references enriched the verification and reference system.

Full provenance and adaptation notes appear in [ATTRIBUTION.md](ATTRIBUTION.md).
