# Cross-file Mod Doctor

`scripts/audit-hoi4-mod.ps1` is a read-only first pass over an existing mod. It
indexes cross-file contracts, separates confirmed static findings from
heuristic leads, and can produce a review baseline for later changes. It is not
a Clausewitz parser and does not prove runtime behavior.

## Basic use

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-mod.ps1 `
  -ModRoot '<MOD_ROOT>' `
  -GameRoot '<HOI4_GAME_ROOT>' `
  -Format Markdown `
  -OutputPath '<REPORT>.md'
```

Supply exact dependency roots when possible. On Windows, `-AutoResolvePlayset`
reads `dlc_load.json` from the HOI4 user-data directory, resolves every enabled
`.mod` descriptor in load order, and adds all enabled mods except the target as
effective dependency roots:

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-mod.ps1 `
  -ModRoot '<MOD_ROOT>' `
  -GameRoot '<HOI4_GAME_ROOT>' `
  -AutoResolvePlayset `
  -Format Json `
  -OutputPath '<BASELINE>.json'
```

Use `-UserDataRoot` when Documents has been redirected. Playset discovery is
evidence about the current launcher state, not permission to change it.

## Review modes

- `-ChangedOnly -GitBase <REF>` returns findings attached to changed or
  untracked files. It is useful for a pull request, but it cannot prove that an
  unchanged caller is unaffected.
- `-BaselinePath <REPORT>.json` removes findings whose stable fingerprint
  (`code + normalized file + message`) already exists in a prior Doctor JSON
  report. Line-number movement does not turn old debt into a new issue.
- `-SuppressionsPath <POLICY>.json` applies narrow, documented, expiring
  exceptions. Start from
  `assets/templates/mod-doctor-suppressions.json`. Expired entries do not
  suppress and emit `EXPIRED_SUPPRESSION`.
- `-AuditMedia` inventories media, byte-identical duplicates, potential
  deduplication savings, and files with no explicit indexed reference. The
  unreferenced list is heuristic because some assets are discovered by naming
  convention or generated consumer paths.

The modes compose. A CI job can compare only changed files against an accepted
baseline while retaining a small suppression policy:

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-mod.ps1 `
  -ModRoot '<MOD_ROOT>' `
  -ChangedOnly -GitBase origin/main `
  -BaselinePath '<BASELINE>.json' `
  -SuppressionsPath '<SUPPRESSIONS>.json' `
  -Format Sarif -OutputPath '<REPORT>.sarif' `
  -FailOn Error
```

## Output

`-Format` accepts `Text`, `Json`, `Markdown`, or `Sarif`. `-AsJson` remains as
a backwards-compatible alias for `-Format Json`. JSON schema version 2 adds:

- run mode and effective roots, including resolved playset descriptors;
- confirmed and heuristic-lead counts;
- separate baseline, policy, and output-cap suppression counts;
- optional media inventory;
- `certainty` on every finding.

SARIF 2.1.0 maps errors, warnings, and info to `error`, `warning`, and `note`,
and keeps certainty and evidence in result properties. Use `-FailOn Error` or
`-FailOn Warning` for CI. Existing output files are not overwritten without
`-Force`; `-MaxFindings` caps details without changing aggregate counts.

## What it indexes

- top-level event, scripted-effect, and scripted-trigger definitions and known
  callers;
- strong localisation consumers such as event titles, descriptions, and
  tooltip keys;
- GFX tokens and quoted media paths;
- duplicate definitions and definitions with no detected mod caller;
- periodic hook counts, broad iterators, `dirty = 0`, loops, and large files
  with no comments;
- exact media duplicates and explicit-reference coverage when requested;
- file, language, performance, and cross-file graph summaries.

The target mod receives the full scan. Dependencies contribute effective
definitions. A supplied game root uses a lighter definition index; installed
`dlc/*` roots are included for targeted GFX and asset resolution.

## Interpretation boundary

- A `confirmed` result means the static condition was observed. It does not
  automatically prove the user-visible symptom or authorize an edit.
- A `lead` needs semantic reading or runtime evidence. Orphans may be public
  APIs, console entries, dependency callbacks, or engine consumers.
- Unresolved means absent from the supplied effective roots. Without the exact
  game build and enabled dependencies it is not proof that the object is
  missing at runtime.
- Bare icon tokens can receive class-specific prefixes, and omitted icon fields
  may use engine defaults. Apply `icon-audit.md` before declaring an icon
  broken.
- Static media references miss engine-discovered flags, achievements, naming
  conventions, generated GUI names, and indirect scripted paths. Never delete
  an unreferenced candidate without a consumer audit and a rollback point.
- Performance findings identify frequency and fan-out risks. Preserve the
  feature invariant and measure before changing cadence.

Run focused localisation, map, override, media, log, and runtime workflows after
this baseline. Keep project-specific accepted debt in a reviewed suppression
file rather than weakening the shared rules.
