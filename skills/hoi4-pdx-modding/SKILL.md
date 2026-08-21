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
- [aces-operatives.md](references/aces-operatives.md): named ace types,
  `add_ace`, custom operative traits, fixed portraits, icons, and runtime tests.
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
- [media-optimization.md](references/media-optimization.md): consumer-aware
  format conversion, deduplication, rollback, and size verification.
- [vanilla-documentation-map.md](references/vanilla-documentation-map.md):
  choosing installed schema sources and debug commands.
- [review-checklist.md](references/review-checklist.md): reviews, renames,
  regression checks, encoding, and handoff.
- [development-documentation.md](references/development-documentation.md):
  mandatory technical documentation, change handoff, and readable code-comment
  contracts for every implementation or repair.
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
8. Update the mod's canonical technical documentation and current development
   handoff in the same change. Add readable comments at file/subsystem
   boundaries and around non-obvious scope, state, lifecycle, performance,
   compatibility, and engine-workaround logic.

## Validate proportionally

Match checking cost to the change. User AI quota, tool rounds, and log
scrapes are not free. A small edit is not permission to run the full
validator, Mod Doctor, localisation/map/override/media audits, `-All`, or
a fresh `error.log` pass.

Choose the cheapest sufficient lane before any script:

1. **Inspect-only.** Skip every validation script when a careful read of
   the diff can catch the failure mode. Typical cases: prose-only
   localisation where keys, tokens, colours, icons, and encoding are
   unchanged; comments; documentation wording; or a one-line cleanup
   already confirmed unique. Read the diff. Stop. Do not offer Steam or
   in-game testing unless the user asked.

2. **Changed-path scripts.** For ordinary PDX or localisation edits that
   can break encoding, braces, key style, or in-file references, run the
   bundled validator on the edited files only:

   ```powershell
   & <SKILL_ROOT>/scripts/validate-hoi4.ps1 -ModRoot <MOD_ROOT> -Paths <changed files>
   ```

   Add `git diff --check` on those paths when the repository uses it.
   Search stale IDs, missing links, or conflict markers only where this
   diff can create them. Do not launch sibling audits unless the change
   is in that audit's domain.

3. **Broader static suite.** Reserve `-All`, Mod Doctor, map/override/media
   audits, template-manifest validation, whole-mod stale-ID sweeps, and a
   fresh `error.log` comparison for new systems, identifier renames,
   GUI/GFX wiring, map/history, compatibility, release packaging, version
   migration, or template/kit edits.

Static checks cannot prove scope, timing, GUI interaction, AI choice,
history loading, or asset rendering. After lanes 2–3, use the sibling
runtime test workflow, which must ask the user before controlling Steam
or launching the game. Report static and in-game evidence separately.
Inspect-only work may record "scripts skipped; diff read" as completion
evidence.

After a game update, rebuild the installed documentation inventory with an
explicit game root:

```powershell
& <SKILL_ROOT>/scripts/index-vanilla-docs.ps1 -GameRoot <HOI4_GAME_ROOT>
```
