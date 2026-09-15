---
name: hoi4-review-debug
description: Review, diagnose, and test existing Hearts of Iron IV mods using source, logs, installed-game evidence, and optional isolated runtime runs. Use for audits, defect or crash triage, balance/UX/performance/lifecycle analysis, migration, or explicitly requested fixes; use hoi4-content-builder for new content and hoi4-pdx-modding for ordinary implementation without a review goal.
---

# HOI4 review and debug

## Set scope and choose one evidence lane

A request to review, explain, or diagnose authorizes read-only investigation,
not edits. Enter the fix lane only when the user asks to change the mod. Treat
balance, narrative, and visual taste as design choices unless project guidance
defines an objective contract; obtain approval before changing them.

Choose the cheapest lane that can answer the request. Read only that lane's
references; do not preload references from unrelated lanes. Lead review output
with concrete findings ordered by impact and supported by file/line evidence;
if no defect is established, say so and list the remaining test gaps.

For any lane that judges or changes an existing player-facing feature, also
build the code-to-visible-meaning map in
[semantic-intent-audit.md](../hoi4-pdx-modding/references/semantic-intent-audit.md).
For a broad review or applied refactor, additionally use the base
[review-checklist.md](../hoi4-pdx-modding/references/review-checklist.md).

- **One symptom, parser/scope bug, or log triage:** read the matching section of
  [review-workflows.md](references/review-workflows.md), reproduce the symptom,
  and trace its first failing caller. Search
  [field-tested-pitfalls.md](references/field-tested-pitfalls.md) only after the
  evidence identifies a matching failure class. CWTools squiggles are not
  evidence by themselves; see
  [pdx-language.md](../hoi4-pdx-modding/references/pdx-language.md).
- **Existing-feature review, refactor, or fix:** trace its caller, scope,
  player-visible promise, state lifecycle, AI path, and dependencies. Enter the
  edit loop only when the request authorizes a change.
- **Whole-mod health or improvement:** follow
  [improve-existing-mod.md](workflows/improve-existing-mod.md) and read
  [mod-doctor.md](references/mod-doctor.md) before running the baseline audit.
  Add [gameplay-balance-ux-review.md](references/gameplay-balance-ux-review.md)
  only when player experience, balance, or design is in scope.
- **Performance or lifecycle/save risk:** read
  [performance-debugging.md](../hoi4-pdx-modding/references/performance-debugging.md),
  then measure cadence, scope count, state creation, invalidation, cleanup, and
  save/reload behavior before proposing a change.
- **Localisation or dynamic text:** read
  [localisation-deep-dive.md](../hoi4-pdx-modding/references/localisation-deep-dive.md).
  Check visible values for leaked prompts, internal mod conventions, and
  developer-facing explanations; rewrite only when authorized, using the
  player's perspective. Do not flag a missing country-leader trait `_desc` as
  a defect: the native trait tooltip does not display it. Verify the leader's
  referenced description and preserve real custom consumers before cleanup.
  Search the localisation sections of `field-tested-pitfalls.md` only for a
  reproduced consumer-specific failure or a bulk cleanup.
- **GUI, GFX, or artwork:** use the base
  [GUI/localisation reference](../hoi4-pdx-modding/references/gui-localisation.md).
  Read [icon-audit.md](references/icon-audit.md) only for missing, default,
  mismatched, or dependency-bound artwork.
- **Map/history or version update:** use the matching section of
  `review-workflows.md`; for a game-version migration follow
  [version-migration.md](workflows/version-migration.md).
- **Template audit:** follow the builder's
  [verify-template.md](../hoi4-content-builder/workflows/verify-template.md) and
  verify the target build, placeholders, schema, current consumer, dependency
  chain, and runtime status separately.
- **Media footprint or conversion:** follow
  [optimize-media.md](workflows/optimize-media.md).
- **Native crash:** ask for the exact pre-crash action timeline and governing
  jurisdiction, then read
  [native-crash-reverse-engineering.md](references/native-crash-reverse-engineering.md)
  before native analysis. Never infer jurisdiction from language or broaden
  one authorization into tool installation, static decompilation, or live
  debugging.
- **Runtime test:** only after explicit consent, follow the builder's
  [test-mod.md](../hoi4-content-builder/workflows/test-mod.md). Isolate the
  playset, test the smallest scenario, inspect fresh logs, and restore settings.

When writing diagnostic or repair helpers in a Git repository, follow
[tool placement by audience](../hoi4-pdx-modding/SKILL.md#place-generated-tools-by-audience):
keep reusable team tools in shared version-controlled directories, personal
tools in a directory covered by `.gitignore`, and one-off helpers out of Git
history. A review request still does not authorize modifying the mod.

## Establish evidence

Inspect target guidance, version, dependencies, playset, `git status`, changed
files, definitions, callers, and the newest relevant log. Use installed schema
and current vanilla/dependency consumers for unfamiliar tokens. Distinguish
parser errors, semantic errors, runtime behavior, and optional-media warnings.

Judge implementation against current vanilla code and bundled templates/kits,
checking the exact dependency for overridden systems. The Wiki is optional
background reference only and may be long outdated; a Wiki disagreement alone
does not establish a defect. Do not require a Wiki lookup. Resolve template
conflicts against current vanilla/runtime evidence and mark unsupported details
unverified. Follow the sibling skill's
[source order](../hoi4-pdx-modding/references/pdx-script.md#source-order).

Before judging or optimizing a feature, read its names, descriptions, options,
tooltips, scripted-localisation branches, GUI labels, and character text. Map
each code ID to its visible meaning and player-facing promise. Never identify a
character or mechanic by transliterating an internal token. Treat any
code/localisation disagreement as a finding to resolve, not as permission to
ignore the localisation.

Select only the cheapest matching read-only tool:

- When the plugin's `hoi4_local` MCP server is available, use
  `read_hoi4_logs` for bounded current-log tails, `trace_hoi4_identifier` for
  cross-root source links, and `inspect_hoi4_media` for targeted metadata.
  MCP output is evidence collection, not diagnosis by itself. Fall back to the
  scripts below and ordinary local inspection when the server is unavailable.

- `scripts/audit-hoi4-mod.ps1`: build a cross-file health baseline covering
  event and scripted-object graphs, strong localisation/GFX/resource links,
  duplicate/orphan definitions, periodic hot-path heuristics, and comment
  coverage. It can resolve the active playset, compare changed files or a prior
  baseline, apply expiring suppressions, audit media, and emit JSON, Markdown,
  or SARIF. When `-GameRoot` is supplied it also target-scans installed DLC
  interface trees and distinguishes same-basename texture extension mismatches.
  Treat `lead` findings as investigation targets, not edit authority.
- `scripts/analyze-hoi4-log.ps1`: prioritize and compare logs.
- `scripts/audit-localisation.ps1`: inspect BOMs, headers, suffixes, duplicate
  keys, colour markers, nested tokens, dynamic variables, and functions.
- `../hoi4-pdx-modding/scripts/audit-visible-flag-localisation.ps1`: find
  `has_country_flag` requirements that would expose an unlocalised internal
  flag ID in generated check/cross tooltips; distinguish visible requirements,
  potential visibility paths, and `hidden_trigger` exclusions.
- `scripts/audit-hoi4-map.ps1`: check map IDs/colors and history membership.
- `scripts/audit-vanilla-overrides.ps1`: inventory overrides, `replace_path`,
  hashes, and migration gates.

Native crash tools and authorization stages are defined only in the native
crash reference. Do not import that workflow into ordinary script or log
diagnosis.

Fix the first parser failure in each file before cascades. For every finding,
state the triggering path, failure mechanism, user-visible effect, and smallest
remedy. Do not apply conventions from another mod or old version universally.

When reviewing generated content, search for `MOD`, sample tags, example IDs,
placeholder text, copied asset paths, unresolved localisation, and conflict
markers. Brace balance alone does not prove scopes, lifecycle, AI behavior,
history IDs, or GUI/GFX wiring.

## Verify and hand off

Follow the sibling `hoi4-pdx-modding` **Validate proportionally** lanes.
Do not run the full validator, Mod Doctor, focused audits, or a fresh-log
comparison because a small edit exists. User AI quota is not free.
Inspect-only diffs are complete after a careful read.

When scripts are warranted, run the cheapest matching check on the edited
paths. Broader audits and log comparison belong to whole-mod, rename,
GUI/map, compatibility, release, or migration work. Non-trivial static
work ends with a consent question: does the user want AI-assisted in-game
testing? Never open Steam, change launch options, alter a playset, or
start HOI4 without that consent. Do not offer a Steam prompt after
inspect-only work unless the user asked.

For every applied fix or refactor, update the canonical mod technical document,
current development handoff, and readable comments for affected contracts.
Review their accuracy alongside code and localisation before completion.

For a whole-mod improvement, fill the bundled
`assets/templates/mod-improvement-report.md` with the before/after baseline,
approved scope, evidence, deferred design choices, and remaining risks. Never
silently turn a balance preference or narrative taste into a defect.

For an approved test, use computer-use when available and follow the builder's
runtime workflow. Enable only the target mod, plus exact required dependencies
for a submod; use `-debug`; start a new game from the earliest available
bookmark; exercise the changed content; read the logs; improve and retest; then
restore any launch and playset settings changed for the test. Report confirmed
results, reasoned risks, and any interactions still requiring the user.
