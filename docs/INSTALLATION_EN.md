# HOI4 AI Modding Skills — Installation and Sharing Guide

[简体中文](INSTALLATION.md) | English | [日本語](INSTALLATION_JA.md) | [Русский](INSTALLATION_RU.md) | [한국어](INSTALLATION_KO.md)

## What Is Inside

This package is **focused primarily on maintaining, debugging, refactoring, and evolving existing *Hearts of Iron IV* mods**, while retaining a full end-to-end workflow for **creating new features and complete mods from plain language**. It ships as three tightly coordinated Agent Skills:

- **`hoi4-review-debug`**: focuses on log triage, cross-file audits, version migration, performance optimization, and consent-gated in-game testing for existing mods;
- **`hoi4-pdx-modding`**: enforces PDX syntax, directory layout, target-build verification, and static validation;
- **`hoi4-content-builder`**: turns plain-language gameplay ideas into complete features or full mods with wired scripts, assets, UI, and multilingual localisation.

**Always install all three skills together.** They cross-reference each other's rules, templates, and handoff steps so design, implementation, and verification work as one continuous loop. You can describe gameplay, rules, and visuals directly without writing PDX script first; keep mod-specific variables, flags, dependencies, and encoding rules inside that mod's own technical guide so the shared skills stay portable and lean.

## Distributing and Publishing Releases

1. **Publish source code and versioned releases** rather than passing around untraceable archives.
2. **Make the combined three-skill bundle the default download**, noting the version, source commit, and archive size (add checksums when a distribution channel requires them or when investigating transfer corruption). For platforms that only accept one skill archive at a time, include three matching per-skill ZIPs from the same release and instruct users to install all three.
3. **Preserve complete metadata**: keep `LICENSE`, `ATTRIBUTION.md`, and each skill's full directory tree intact.
4. **Respect asset copyright boundaries**: never bundle Paradox vanilla files, Workshop tutorials, other mods' assets, or personal local paths. Vanilla and third-party files stay strictly on your machine for verification.
5. **Track major HOI4 updates**: after each major patch, re-verify the vanilla consumers listed in `references/template-catalog.md` and record the verified HOI4 build in the release notes.

## Client Setup

### ChatGPT

On a ChatGPT account with Personal Skills enabled, open your profile menu → **Skills** → **Create** → **Upload from your computer**, upload all three skill ZIPs from the same release, and verify that all three are enabled. From the Skills page you can share them with workspace members or generate share links. Plan availability and admin toggles follow [OpenAI's Skills documentation](https://help.openai.com/en/articles/20001066-skills-in-chatgpt); review scripts and provenance yourself before using any third-party archive.

### Codex

- **User-wide install**: copy all three skill folders into `$CODEX_HOME/skills/`.
- **Project-scoped install**: copy them into `<MOD_ROOT>/.agents/skills/` and version them alongside the mod, preserving this layout:

```text
.agents/skills/
  hoi4-content-builder/SKILL.md
  hoi4-pdx-modding/SKILL.md
  hoi4-review-debug/SKILL.md
```

Refresh or start a new task, then describe your HOI4 modding goal in plain language. Keep long-lived rules and doc links for a specific project in its root `AGENTS.md`.

#### Optional: Install the Codex Plugin with Read-Only Local Tools

The repository root is itself a complete Codex Plugin source bundling all three skills with the read-only local MCP server `hoi4_local`—ideal when you want local HOI4 installation discovery, identifier tracing, Git-change validation, log inspection, and media metadata checks. See [Local Plugin and Read-Only MCP Helper](LOCAL_MCP_PLUGIN_EN.md) for install commands and safety boundaries.

> **Note**: **Start a fresh Codex task** after installing or refreshing the plugin. Existing sessions freeze the tool list loaded at startup, so a new task is needed to pick up updated skills and MCP tools.

### Cursor

Cursor Agent automatically discovers project skills in `.agents/skills/<skill-name>/` or `.cursor/skills/<skill-name>/`, and user skills in `~/.agents/skills/<skill-name>/` or `~/.cursor/skills/<skill-name>/`. Copy all three directories from the same release into either location—project scope travels with the mod in Git, while user scope is shared across all your mods.

Reopen or refresh Agent to let Cursor match skills automatically, or type `/` in chat to search and invoke a skill by name. Skills pass through to whichever model you select; to use personal `~/.cursor/skills/` inside Cloud Agents, turn on Skills sync in Cursor settings. To add local read-only evidence or authorized live testing, register `hoi4_local` or `hoi4_desktop` in `.cursor/mcp.json`. See [Cursor Agent Skills documentation](https://cursor.com/docs/skills) for current paths and remote rules.

### Claude Code / claude.ai

- **Claude Code**: copy all three folders into `~/.claude/skills/<skill-name>/` (user scope) or `.claude/skills/<skill-name>/` (project scope). Claude loads matching skills automatically from `description` and also supports explicit invocation. See [Claude Code Skills documentation](https://code.claude.com/docs/en/slash-commands).
- **claude.ai**: upload custom skill ZIPs under **Settings → Features**; check plan, execution, and API/workspace rules in [Anthropic's Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).

### Gemini CLI / Google Antigravity

- **Gemini CLI**: discovers user skills in `~/.gemini/skills/` or `~/.agents/skills/`, and workspace skills in `.gemini/skills/` or `.agents/skills/`. Copy all three folders and run `/skills reload`, or use `/skills link <path> --scope user|workspace` and `gemini skills install <repository-url>`. See [Gemini CLI Skills documentation](https://geminicli.com/docs/cli/using-agent-skills/).
- **Google Antigravity**: bundle the three skills with `mcp-server/hoi4_mcp.py` as a read-only local plugin under `~/.gemini/config/plugins/`. When you want AI-assisted in-game testing on clients without built-in desktop computer use (Antigravity, Cursor, Claude Code, Gemini CLI), enable the standalone process-whitelisted desktop MCP `hoi4_desktop` on demand—see [Optional Desktop MCP Setup Guide](DESKTOP_MCP_SETUP_EN.md).

## Licensing

The entire skill suite uses **CC BY-SA 4.0** because its general engineering references adapt and summarize public Millennium Dawn material licensed under CC BY-SA 4.0, and ShareAlike keeps derivatives cleanly aligned. You may copy, adapt, and use the suite commercially as long as you preserve attribution, note your changes, and share adaptations under the same license.

Using one consistent CC BY-SA 4.0 license also spares contributors the friction of mixed doc/script licensing; if standalone tool scripts ever separate completely from ShareAlike material, MIT can be reconsidered for those scripts later. This license covers the published skill files in this repository, while Paradox Interactive, other mods, and third-party assets retain their original rights.
