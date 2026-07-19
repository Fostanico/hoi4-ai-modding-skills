---
name: hoi4-review-debug
description: Diagnose, review, optimize, migrate, and test Hearts of Iron IV mods from source through an isolated in-game run. Use for error.log triage, Windows crash dumps/minidumps, parser or scope bugs, broken GUI/assets/localisation, AI behavior, performance, save/lifecycle risks, compatibility, version updates, template audits, regression plans, or user-approved Steam and game testing.
---

# HOI4 review and debug

## Choose the evidence lane

- Diagnosis: reproduce and trace one symptom before changing code.
- Fix: identify the earliest root cause, repair the smallest coherent graph,
  and rerun the reproduction.
- Review: report concrete findings ordered by impact with file/line evidence.
- Performance: determine execution frequency and scope count before optimizing.
- Lifecycle/save audit: enumerate create, update, consume, clear, reload,
  migration, and dependency paths.
- Template audit: verify target build, placeholders, schema, current consumer,
  dependency chain, and runtime status.
- Native crash diagnosis: ask for the exact pre-crash action timeline, obtain
  explicit consent before reverse engineering, and keep any lawful analysis
  read-only and limited to the compatibility question.
- Runtime test: ask for consent, isolate the playset, launch with `-debug`, run
  the smallest scenario, inspect fresh logs, iterate, and restore user settings.

Read [review-workflows.md](references/review-workflows.md),
[field-tested-pitfalls.md](references/field-tested-pitfalls.md), the sibling
base skill's `performance-debugging.md`, `review-checklist.md`, and
`localisation-deep-dive.md`. For every existing-feature review, also follow
[semantic-intent-audit.md](../hoi4-pdx-modding/references/semantic-intent-audit.md)
before accepting an inferred feature meaning. Use the builder's
[test-mod.md](../hoi4-content-builder/workflows/test-mod.md) for runtime work.

## Establish evidence

Inspect target guidance, version, dependencies, playset, `git status`, changed
files, definitions, callers, and the newest relevant log. Use installed schema
and current vanilla/dependency consumers for unfamiliar tokens. Distinguish
parser errors, semantic errors, runtime behavior, and optional-media warnings.

For a crash, ask what the player did immediately before it before assigning a
cause. Record the window, tab, or control used; pause and speed state; date
advance; save/load; console and debug commands; GUI debug or hot refresh;
in-session file edits; overlays; and whether a clean restart reproduces it.

Before judging or optimizing a feature, read its names, descriptions, options,
tooltips, scripted-localisation branches, GUI labels, and character text. Map
each code ID to its visible meaning and player-facing promise. Never identify a
character or mechanic by transliterating an internal token. Treat any
code/localisation disagreement as a finding to resolve, not as permission to
ignore the localisation.

Use the read-only tools when applicable:

- `scripts/analyze-hoi4-log.ps1`: prioritize and compare logs.
- Installed WinDbg/CDB: when a Windows crash package contains a `.dmp`, use the
  debugger read-only before judging the crash; follow the minidump workflow in
  `review-workflows.md`. Obtain explicit consent before reverse-engineering a
  native call path, and do not install a debugger without user authorization.
- `scripts/audit-localisation.ps1`: inspect BOMs, headers, suffixes, duplicate
  keys, colour markers, nested tokens, dynamic variables, and functions.
- `scripts/audit-hoi4-map.ps1`: check map IDs/colors and history membership.
- `scripts/audit-vanilla-overrides.ps1`: inventory overrides, `replace_path`,
  hashes, and migration gates.

Fix the first parser failure in each file before cascades. For every finding,
state the triggering path, failure mechanism, user-visible effect, and smallest
remedy. Do not apply conventions from another mod or old version universally.

When reviewing generated content, search for `MOD`, sample tags, example IDs,
placeholder text, copied asset paths, unresolved localisation, and conflict
markers. Brace balance alone does not prove scopes, lifecycle, AI behavior,
history IDs, or GUI/GFX wiring.

## Verify and hand off

Run the base validator, repository checks, stale-reference searches, encoding
checks, and a fresh-log comparison. Static work ends with a consent question:
does the user want AI-assisted in-game testing? Never open Steam, change launch
options, alter a playset, or start HOI4 without that consent.

For an approved test, use computer-use when available and follow the builder's
runtime workflow. Enable only the target mod, plus exact required dependencies
for a submod; use `-debug`; start a new game from the earliest available
bookmark; exercise the changed content; read the logs; improve and retest; then
restore any launch and playset settings changed for the test. Report confirmed
results, reasoned risks, and any interactions still requiring the user.
