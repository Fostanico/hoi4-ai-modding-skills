---
name: hoi4-content-builder
description: Turn plain-language ideas into complete, playable Hearts of Iron IV mods and advanced systems. Use when a user describes a mod without knowing PDX script, or requests events, decisions, focuses, countries, characters, ideas, MIOs, doctrines, raids, special projects, AI, OOBs, factions, diplomacy, GUI, map modes, localisation, models, music, or release packaging. Includes verified templates, multi-file kits, full workflows, and runtime-test handoff.
---

# HOI4 content builder

## Start from the user's idea

The user may describe only the desired fantasy or gameplay result. Do not ask
them to design scopes, files, triggers, or syntax. Read
[natural-language-intake.md](references/natural-language-intake.md), infer safe
defaults, and produce a concise content contract covering visible behavior,
rules, AI, lifecycle, compatibility, assets, save impact, and acceptance tests.

Read target-repository guidance and sibling `hoi4-pdx-modding` references for
every affected system. Discover the game, mod, dependency, and playset paths;
never assume the paths or conventions from the machine that authored this
skill. Verify version-sensitive syntax in installed documentation and current
vanilla or dependency consumers.

When extending or repairing existing content, first read all affected visible
localisation and scripted-localisation consumers. Follow the sibling skill's
[semantic-intent-audit.md](../hoi4-pdx-modding/references/semantic-intent-audit.md)
before translating IDs into a content contract. Identifiers are not evidence
for character names, narrative roles, costs, dates, or player-facing behavior.

## Choose a workflow

- New mod from an idea: [build-complete-mod.md](workflows/build-complete-mod.md)
- One feature in an existing mod: [build-feature.md](workflows/build-feature.md)
- Advanced or cross-system feature: [build-advanced-system.md](workflows/build-advanced-system.md)
- Country/state/map history: [build-map-history.md](workflows/build-map-history.md)
- Collections, arrays, event targets, dynamic modifiers, or dynamic text:
  [use-advanced-patterns.md](workflows/use-advanced-patterns.md)
- Static-to-runtime validation: [test-mod.md](workflows/test-mod.md)
- Versioned distribution: [release-mod.md](workflows/release-mod.md)

Use [system-coverage.md](references/system-coverage.md) to route any beginner or
advanced feature and [advanced-engineering.md](references/advanced-engineering.md)
for architecture, performance, compatibility, save migration, and tooling.

## Reuse verified resources

Start from `assets/templates/` for one object and `assets/kits/` for a proven
multi-file dependency chain. Read [template-catalog.md](references/template-catalog.md)
before copying. Replace every `MOD`, sample numeric ID, path, asset, and text.
Templates are not permission to skip target-build verification.

Use `scripts/new-country-scaffold.ps1` to generate a staged country tree and
`scripts/generate-gfx-manifest.ps1` for deterministic sprite registration.
Generate into an empty staging directory, review the diff, then merge only the
required files into the target mod. Never let a helper silently overwrite the
target tree.

If no verified resource fits, follow [verify-template.md](workflows/verify-template.md):
check installed schema, at least one current working consumer, caller scopes,
all dependent resources, and a minimal runtime test before promoting it.

## Build the complete graph

1. Establish stable IDs and file ownership.
2. Map IDs to visible names, descriptions, tooltips, and promised behavior.
3. Create definitions before consumers.
4. Wire callers, lifecycle updates, cleanup, AI, and compatibility gates.
5. Add or update localisation and visible assets for every player-facing path.
6. Search the whole target mod for definitions, callers, stale IDs, and
   collisions. Preserve unrelated work and project encoding conventions.
7. Keep a minimal runnable path first; add branches and optimization only after
   the core path validates.

Do not stop after writing the central object. A focus needs effects and text; a
GUI needs sprites, callbacks, and localisation; a project needs facilities,
scientists, rewards, AI, and DLC gates; a country needs tag, definition,
history, character, flags, and ownership planning.

## Finish with evidence

Run the sibling validator and target-repository checks, inspect cross-file links
and a fresh log, and separate static proof from runtime proof. After static
checks, explicitly ask whether the user wants AI-assisted in-game testing. If
they agree and computer-use is available, follow `workflows/test-mod.md` exactly.
If they decline, provide the smallest manual test plan and do not open Steam.
