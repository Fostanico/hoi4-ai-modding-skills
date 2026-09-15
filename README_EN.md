# HOI4 AI Modding Skills

[简体中文](README.md) | English

This repository contains three Agent Skills for maintaining, diagnosing,
improving, and building Hearts of Iron IV mods with Codex, ChatGPT, Claude
Code, and Gemini CLI.

The current emphasis is existing-mod work: understanding an unfamiliar codebase,
finding cross-file failures, reviewing performance and compatibility, and
turning crash evidence into an actionable repair plan. The skills also retain a
complete path from a plain-language idea to playable PDX script for people who
do not already know the HOI4 scripting language.

The repository can also be used as a **Codex Plugin**. The three Skills remain
the procedure and judgment layer, while a local read-only MCP helper discovers
the exact HOI4 installation, traces identifiers, validates Git changes, reads
logs, and inspects media metadata. It needs neither a cloud-hosted HOI4 corpus
nor an OpenAI API key, and it cannot launch the game or modify a mod. See
[Local plugin and MCP helper](docs/LOCAL_MCP_PLUGIN.md) for the tool and safety
contract.

## Included Skills

| Skill | Main job |
| --- | --- |
| `hoi4-review-debug` | Existing-mod improvement, cross-file Mod Doctor, logs and crashes, performance, compatibility, balance, UX, icons, and asset audits |
| `hoi4-pdx-modding` | PDX script, scopes, lifecycle, cross-file contracts, localisation, migration, technical documentation, comments, and static validation |
| `hoi4-content-builder` | Events, decisions, focuses, characters, ideas, MIOs, GUI, AI, OOBs, maps, music, models, and complete systems from plain-language requirements |

**Install all three skills together.** They share validation rules, workflows,
and sibling references: `content-builder` turns requirements into complete
content, `pdx-modding` supplies language and version verification, and
`review-debug` handles maintenance, regression, and runtime evidence. A single
skill can still load, but it loses sibling references and cannot provide the
package's full workflow.

## Install in Codex

### Recommended: Skills plus local tools

On Windows, clone or extract this repository and run the following command from
its root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

The script installs the complete plugin under the current user's local
application-data directory and registers it through the Codex CLI. It does not
modify HOI4, launch the game, or upload local files. Start a new Codex task when
installation finishes. Rerun the same command after updating the repository to
refresh the plugin.

Requirements: Windows, Python 3, and the Codex CLI. `ffprobe` is optional and
only adds audio/video stream metadata. See
[Local plugin and MCP helper](docs/LOCAL_MCP_PLUGIN.md) for tools, safety
boundaries, and troubleshooting.

### Skills only

Download a complete package from
[Releases](https://github.com/Fostanico/hoi4-ai-modding-skills/releases), or
clone this repository. Copy the three directories under `skills/` into either:

- `<MOD_ROOT>/.agents/skills/` for a repository-scoped installation;
- `$HOME/.agents/skills/` for a user-scoped installation shared by multiple mods.

Keep each skill's `SKILL.md`, `references/`, `workflows/`, `assets/`, `scripts/`,
and `agents/` directories together. Codex normally detects changes automatically;
restart it if an installed skill does not appear.

Clients without plugin support can continue to install the three Skills this
way. This does not install the local MCP tools.

In Codex CLI or the IDE extension, use `/skills` to inspect available skills and
type a name such as `$hoi4-review-debug` to invoke one explicitly. In the
ChatGPT desktop app, installed skills are visible from the Skills page in the
sidebar. See the current
[OpenAI skills documentation](https://learn.chatgpt.com/docs/build-skills) for
Codex discovery paths and invocation behavior.

See [Installation and sharing](docs/INSTALLATION.md) for other clients and
release-package details.

## Use in Codex

Start an existing-mod review without changing files:

> `$hoi4-review-debug` Review this mod. Read its technical documentation and
> relevant player-facing localisation first, then inspect cross-file references,
> variable lifecycle, periodic performance, icons, localisation, and dependency
> compatibility. Report evidence and a repair plan before editing anything.

For logs, provide the mod path, target game version, enabled dependencies, and
the newest `error.log` when possible:

> Analyze this `error.log`. Separate errors caused by this mod, dependencies,
> vanilla, and optional media. Group repeated messages by root cause and give
> the smallest viable repair for each group.

For new content, describe the intended gameplay and constraints:

> `$hoi4-content-builder` Build a repeatable decision set for HOI4 1.19 with AI
> weights and English, Simplified Chinese, Russian, and Japanese localisation.
> Verify the current vanilla syntax before implementation and run static checks.

Explicit invocation is optional. Codex can select a skill when the request
matches its `SKILL.md` description; naming the skill is useful when you want a
specific review or diagnosis workflow.

## Core Workflows

### Improve an Existing Mod

1. Read the project's technical guide, handoff notes, and relevant player-facing localisation.
2. Map events, decisions, effects, triggers, variables, flags, localisation, GUI, and GFX across files.
3. Separate confirmed defects, compatibility risks, performance problems, and design choices that require author approval.
4. Present evidence and a staged plan before editing when approval is required.
5. Apply only the approved scope. Scale static checks to the diff: inspect-only
   for tiny edits, changed-path scripts for ordinary files, and the full suite
   only for large or cross-file work. Do not spend AI quota on validation
   theater. State what still requires an in-game test.

### Diagnose Logs and Crashes

1. Group `error.log` messages by root cause and prioritize parser, scope, equipment, ideology, and localisation failures.
2. Correlate timestamps, the active playset, and the player's last actions with actual code paths.
3. Analyze Windows minidumps when needed, with explicit confidence levels and missing evidence.
4. Require staged user consent before WinDbg, Ghidra, full user dumps, process attachment, or hardware data breakpoints.

### Build New Content

1. Convert plain-language requirements into scope, state, resources, AI behavior, compatibility rules, and acceptance criteria.
2. Verify syntax and tokens against the target installation, current vanilla consumers, and exact enabled dependencies.
3. Build script, GFX, assets, and localisation from verified templates without leaving orphaned definitions.
4. Check encoding, cross-file references, comments, technical documentation, logs, and the runtime test plan.

## Coverage

- PDX syntax, scope chains, event targets, variables, and flag lifecycle
- Events, decisions, focuses, ideas, characters, MIOs, equipment, technology, AI, and OOBs
- `on_actions` hot paths, global scans, cadence, and event-driven alternatives
- Localisation encoding, duplicate keys, colors, icons, formatted variables, scope functions, and multilingual templates
- GUI/GFX registration, idea/decision/trait icons, texture paths, audio, and dependency assets
- Loading-screen DDS constraints, named ace pilots, and custom operative traits, icons, and fixed portraits
- Compatibility branches for vanilla and major total conversions, version migration, and save lifecycle risks
- Gameplay loops, numerical balance, AI usability, feedback, counterplay, and player experience
- Technical guides, handoff notes, readable comments, validation records, and release checks
- `error.log`, crash dumps, WinDbg, and consent-based advanced native diagnosis

## Engineering Features

- A real-dialogue regression set in `evals/real-dialogue-regression.json`.
  Prompts are anonymized, source prompts are represented only by SHA-256
  fingerprints, and private session or project identifiers are not published.
- Mod Doctor 2 can resolve the active playset, focus on Git changes, compare a
  prior baseline, apply expiring suppressions, separate confirmed findings from
  heuristic leads, and emit Text, JSON, Markdown, or SARIF.
- Multi-file kits cover established content chains plus technology-to-equipment
  unlocks and game-rule startup initialization.
- `assets/template-manifest.json` records the target build, source consumers,
  verification dates, and required checks. Its validator ensures every template
  and kit file is registered exactly once.
- The media workflow inventories DDS metadata, literal consumers, exact
  duplicates, and measured conversion candidates without treating every DDS as
  a PNG opportunity.

## Boundaries

The skills instruct the agent to verify claims against the target game version,
installed documentation, actual enabled dependencies, and player-facing
localisation. Wikis and community tutorials are useful leads, but they do not
replace current-version evidence.

Static checks do not prove that GUI, MIO, event scope, or compatibility behavior
works at runtime. Starting Steam, controlling the game, installing diagnostic
tools, reverse engineering, attaching to a process, or collecting full memory
requires a clear explanation of purpose and scope plus the user's consent.

## Other Clients

- Claude Code: `~/.claude/skills/` or a project's `.claude/skills/`.
- Gemini CLI: `~/.gemini/skills/`, `~/.agents/skills/`, or a supported workspace path.
- Clients that accept uploaded custom skills: install all three skill ZIP files
  from the same release. Single-skill installation is for advanced users who
  explicitly accept the missing sibling workflows.

Discovery paths can change. Check the current documentation for the client you
are installing into.

## License

This project is licensed under [CC BY-SA 4.0](LICENSE). Keep attribution and
[ATTRIBUTION.md](ATTRIBUTION.md), identify modifications, and distribute adapted
material under the same license. This license does not grant rights to Paradox
Interactive, third-party mods, or third-party assets.

## Acknowledgements

- [Millennium Dawn](https://github.com/MillenniumDawn/Millennium-Dawn), whose public development material informed compatibility, project structure, and advanced workflows.
- Qiuqi Library (秋起图书馆, Steam Workshop item `3445449478`), whose community tutorials and tool references helped improve the verification system.

See [ATTRIBUTION.md](ATTRIBUTION.md) for detailed provenance and adaptation notes.
