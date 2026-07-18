---
name: hoi4-pdx-modding
description: Implement, explain, refactor, and validate portable Hearts of Iron IV mods written in Paradox/PDX script. Use for descriptors, scopes, variables, arrays, events, decisions, focuses, ideas, characters, history, on_actions, GUI/GFX, localisation, AI, performance, compatibility, version migration, logs, encoding, or cross-file identifiers. Works from natural-language requests and verifies version-sensitive syntax against the target installation.
---

# HOI4 PDX modding

## Establish the target

1. Locate the actual mod root, launcher-side `.mod` file, `descriptor.mod`, and
   repository guidance such as `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or a
   project technical handoff. Project guidance overrides generic examples.
2. Record the target HOI4 build, DLCs, dependencies, load order, and whether the
   work is a standalone mod, submod, compatibility patch, or vanilla override.
3. Inspect `replace_path` and the active playset before assuming vanilla or a
   dependency supplies a database.
4. Search definitions and callers across the target mod before editing. Treat
   identifiers, paths, sprite names, equipment archetypes, and localisation
   keys as case-sensitive. Localisation entries must use `key: "Text"`;
   `key:0 "Text"` and every other numeric key-version suffix are errors.
5. Read the affected feature's names, descriptions, options, tooltips, scripted
   localisation, GUI text, and character descriptions before inferring its
   purpose. Build the code-to-visible-meaning map in
   [semantic-intent-audit.md](references/semantic-intent-audit.md); never infer
   proper names or gameplay intent from IDs, filenames, or variable names.
6. Use the Wiki to understand concepts. Prove uncertain fields, scopes, tokens,
   and file layout with the installed build's generated documentation, current
   vanilla consumers, and exact dependency version.

Never require the user to know PDX syntax. Translate ordinary-language goals
into scopes, lifecycle, content objects, files, identifiers, visible behavior,
AI behavior, compatibility assumptions, and tests. Ask only questions whose
answers cannot be discovered or safely defaulted.

## Select references

- [pdx-script.md](references/pdx-script.md): scopes, variables, arrays, loops,
  effects, triggers, identifiers, and source verification.
- [project-structure-history.md](references/project-structure-history.md):
  descriptors, roots, `replace_path`, tags, characters, countries, states,
  provinces, and map/history risk.
- [content-objects.md](references/content-objects.md): events, decisions,
  focuses, ideas, MIOs, on_actions, and dynamic modifiers.
- [ai-and-military-content.md](references/ai-and-military-content.md): AI
  strategies, equipment designs, division templates, OOBs, variants, and names.
- [diplomacy-factions-assets.md](references/diplomacy-factions-assets.md):
  diplomacy, factions, peace conferences, entities, landmarks, music, sound.
- [gui-localisation.md](references/gui-localisation.md): GUI, GFX, scripted GUI,
  scripted localisation, sprites, tooltips, encodings, and localisation.
- [localisation-deep-dive.md](references/localisation-deep-dive.md): colours,
  icons, formatted variables, scope functions, nested and bound text,
  formatters, dynamic consumers, templates, and localisation diagnostics.
- [semantic-intent-audit.md](references/semantic-intent-audit.md): mandatory
  code-to-localisation mapping before existing-feature fixes, refactors,
  performance work, migration, or documentation.
- [performance-debugging.md](references/performance-debugging.md): hot paths,
  caching, log triage, debug mode, and runtime evidence.
- [version-migration.md](references/version-migration.md): game updates and
  full-file vanilla overrides.
- [media-models-shaders.md](references/media-models-shaders.md): textures,
  entities, animations, models, audio, and shaders.
- [vanilla-documentation-map.md](references/vanilla-documentation-map.md):
  choosing installed schema sources and debug commands.
- [review-checklist.md](references/review-checklist.md): reviews, renames,
  regression checks, encoding, and handoff.
- [source-attribution.md](references/source-attribution.md): provenance and
  licensing when maintaining or redistributing these skills.

Use sibling `hoi4-content-builder` for end-to-end construction and templates.
Use sibling `hoi4-review-debug` for diagnosis, adversarial review, migration,
performance analysis, and runtime testing.

## Implement safely

1. Convert the request into a content contract: caller, starting scope,
   visible result, AI behavior, lifecycle, DLC/dependency gates, IDs, assets,
   save impact, and acceptance tests.
2. For existing content, derive the visible result from the actual
   localisation and scripted-localisation consumers. Reconcile their promised
   names, dates, costs, cooldowns, and failure behavior with project guidance
   and code before editing.
3. Trace scope from each real caller through scripted effects, triggers,
   events, decisions, on_actions, and GUI callbacks. Guard optional scopes.
4. Reuse tokens proven in the current target. A generated modifier proves
   engine recognition, not that every consumer accepts it; require a working
   consumer for database-specific fields.
5. Create definitions before consumers and wire the complete dependency chain,
   including localisation, GUI/GFX, assets, history, AI, and lifecycle cleanup.
6. Preserve unrelated changes and stable flags/variables unless an explicit
   migration plan covers old saves. Prefer event-driven or batched updates to
   global daily scans when behavior permits.
7. Treat copied templates as parameterized skeletons. Replace every placeholder
   and revalidate against the target build and dependencies.

## Validate proportionally

Run the bundled validator against the target mod or explicit changed paths:

```powershell
& <SKILL_ROOT>/scripts/validate-hoi4.ps1 -ModRoot <MOD_ROOT>
```

Then search for stale/sample IDs, duplicate definitions, missing localisation
or GFX links, descriptor/load-root mistakes, conflict markers, and encoding
violations. Run the repository's diff/format checks when available. Inspect a
fresh `error.log`; fix the earliest parser error in each file before cascades.

Static checks cannot prove scope, timing, GUI interaction, AI choice, history
loading, or asset rendering. After static validation, use the sibling runtime
test workflow, which must ask the user before controlling Steam or launching
the game. Report static and in-game evidence separately.

After a game update, rebuild the installed documentation inventory with an
explicit game root:

```powershell
& <SKILL_ROOT>/scripts/index-vanilla-docs.ps1 -GameRoot <HOI4_GAME_ROOT>
```
