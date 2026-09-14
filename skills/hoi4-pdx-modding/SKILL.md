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
   Key lines use exactly one leading ASCII space; the language header
   `l_<language>:` stays flush left. Tabs, extra spaces, and flush-left keys
   are errors because editors parse these files as YAML and mixed indent
   paints the buffer red.
5. Read the affected feature's names, descriptions, options, tooltips, scripted
   localisation, GUI text, and character descriptions before inferring its
   purpose. Build the code-to-visible-meaning map in
   [semantic-intent-audit.md](references/semantic-intent-audit.md); never infer
   proper names or gameplay intent from IDs, filenames, or variable names.
6. Base implementation on current installed vanilla code and the bundled
   templates/kits. Verify uncertain fields, scopes, tokens, and file layout
   with current consumers, generated documentation, and the exact dependency
   version. The Wiki is optional background reference only and may be long
   outdated; never require a Wiki lookup or use it to override these sources.
   Resolve template conflicts against current vanilla/runtime evidence and
   correct stale templates. If local evidence is missing, mark the detail
   unverified. See [source order](references/pdx-script.md#source-order).

Never require the user to know PDX syntax. Translate ordinary-language goals
into scopes, lifecycle, content objects, files, identifiers, visible behavior,
AI behavior, compatibility assumptions, and tests. Ask only questions whose
answers cannot be discovered or safely defaulted.

## Player-facing writing

Localisation values are written for players, not developers. Write character
prose, choices, requirements, costs, and outcomes in the mod's established
voice. Never paste prompts, authoring instructions, internal mod conventions,
or implementation notes into visible text; put those in comments or technical
documentation. Translate necessary gameplay explanations into player language.

Country-leader trait tooltips show the trait name and generated modifiers, not
an automatic `<trait>_desc`. Do not create or require unused trait descriptions;
put character background in the leader's actually referenced `desc` instead.
Do not apply this rule blindly to other trait types or custom GUI consumers.
See [localisation-deep-dive.md](references/localisation-deep-dive.md#player-facing-copy-and-visible-consumers).

## Select references

- [pdx-script.md](references/pdx-script.md): scopes, variables, arrays, loops,
  effects, triggers, identifiers, and source verification.
- [pdx-language.md](references/pdx-language.md): Clausewitz/P-language
  grammar, links (`var:`, `token:`, `mio:`, `sp:`), cardinality, and
  editor-versus-engine mismatches.
- [ide-extensions.md](references/ide-extensions.md): CWTools, HOI4 Mod
  Utilities, and HOI4 Modding Tools as editor aids, not engine authority.
- [project-structure-history.md](references/project-structure-history.md):
  descriptors, roots, `replace_path`, tags, characters, countries, states,
  provinces, and map/history risk.
- [content-objects.md](references/content-objects.md): events, decisions,
  focuses, ideas, MIOs, on_actions, buildings, BOP, operations, achievements,
  and dynamic modifiers.
- [ai-and-military-content.md](references/ai-and-military-content.md): AI
  strategies, reversed strategies, equipment designs, division templates,
  OOBs, modules, variants, tactics, and names.
- [aces-operatives.md](references/aces-operatives.md): named ace types,
  `add_ace`, custom operative traits, fixed portraits, icons, and runtime tests.
- [diplomacy-factions-assets.md](references/diplomacy-factions-assets.md):
  diplomacy, factions, peace conferences, entities, landmarks, music, sound.
- [gui-localisation.md](references/gui-localisation.md): GUI, GFX, scripted GUI,
  scripted localisation, sprites, tooltips, encodings, and localisation.
- [animated-textures.md](references/animated-textures.md): convert video or
  frame sequences into `frameAnimatedSpriteType` assets for icons, overlays,
  buttons, panels, backgrounds, and large synchronized-strip animations.
- [localisation-deep-dive.md](references/localisation-deep-dive.md): colours,
  icons, formatted variables, scope functions, nested and bound text,
  formatters, dynamic consumers, visible flag conditions, templates, and
  localisation diagnostics.
- [semantic-intent-audit.md](references/semantic-intent-audit.md): mandatory
  code-to-localisation mapping before existing-feature fixes, refactors,
  performance work, migration, or documentation.
- [performance-debugging.md](references/performance-debugging.md): hot paths,
  caching, log triage, debug mode, and runtime evidence.
- [algorithm-engineering.md](references/algorithm-engineering.md): design
  non-trivial PDX algorithms with deterministic state machines, incremental
  work, compact data flow, bounded execution, fault isolation, and
  consumer-aware presentation. Read it for simulations, minigames, large
  scripted systems, procedural GUI, or performance-sensitive orchestration.
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
   A `has_country_flag` condition exposed by `available`, `allow`, `bypass`, or
   another requirement tooltip needs a localisation key for every supported
   language; otherwise the UI displays the internal flag ID with a check or
   cross. If the internal flag name should not be player-facing, place the
   check inside `hidden_trigger` and provide an explicit localised tooltip.
6. Reuse the owning subsystem's existing file or registry for definitions with
   the same parser directory, load conditions, lifecycle, and consumer family.
   Do not create one tiny `.txt`, `.gfx`, `.gui`, or localisation file per
   object by default. Consolidate related definitions while keeping sections
   readable; split only for a real load-order or compatibility boundary,
   independent generated ownership, materially different lifecycle, or a file
   large enough that consolidation would hinder maintenance. HOI4 normally
   parses these files at startup rather than rereading them every animation
   frame, so fewer tiny files mainly reduce file-open/metadata work and project
   clutter; do not overstate this as continuous runtime disk I/O.
7. Preserve unrelated changes and stable flags/variables unless an explicit
   migration plan covers old saves. Prefer event-driven or batched updates to
   global daily scans when behavior permits.
8. Treat copied templates as parameterized skeletons. Replace every placeholder
   and revalidate against the target build and dependencies.
9. Update the mod's canonical technical documentation and current development
   handoff in the same change. Add readable comments at file/subsystem
   boundaries and around non-obvious scope, state, lifecycle, performance,
   compatibility, and engine-workaround logic.

## Place generated tools by audience

In a Git repository (including a worktree with a `.git` file), decide the
intended audience and lifetime before saving a generated helper:

- **Reusable by the whole team:** put it in the repository's existing shared,
  version-controlled tool directory, such as `tools/` or `scripts/`. Keep it
  discoverable and usable by other contributors; parameterize user-specific
  paths and keep personal configuration/output in ignored storage.
- **Only for the current user:** put the tool and its private support files in
  a directory covered by the repository's `.gitignore`, reusing an existing
  private workspace such as `.ai-private/`. Verify the actual file path with
  `git check-ignore -v -- <path>` before staging. If no such directory exists,
  add a narrowly scoped directory rule to `.gitignore` before creating it.
  Do not force-add private tools. Ignore rules do not untrack existing files;
  do not silently remove tracked files or rewrite history to hide them.
- **One-off helpers:** use a temporary or ignored working directory; do not
  add throwaway tools, logs, or intermediate output to Git history.

"Shared/public" means part of the team's repository, not an instruction to
create a folder literally named `public` or to publish/commit without user
authorization. Respect the project's existing layout and avoid extra folders.

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
