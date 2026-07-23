# Cross-file Mod Doctor

`scripts/audit-hoi4-mod.ps1` is a read-only first-pass indexer for an existing
mod. It complements the base validator; it is not a full Clausewitz parser and
does not prove runtime behavior.

## Usage

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-mod.ps1 `
  -ModRoot '<MOD_ROOT>'
```

Include exact dependencies and the installed game when unresolved external
events, localisation, sprites, or resources must be distinguished from real
missing references:

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-mod.ps1 `
  -ModRoot '<MOD_ROOT>' `
  -DependencyRoots '<DEPENDENCY_1>','<DEPENDENCY_2>' `
  -GameRoot '<HOI4_GAME_ROOT>' `
  -AsJson -OutputPath '<REPORT>.json'
```

Use `-FailOn Error` or `-FailOn Warning` for CI. Existing output files are not
overwritten without `-Force`. Use `-MaxFindings` to cap detailed findings;
aggregate counts remain in the JSON graph summary.

## What it indexes

- top-level event, scripted-effect, and scripted-trigger definitions and known
  callers;
- strong localisation consumers such as event titles/descriptions and tooltip
  keys;
- GFX tokens and quoted media paths;
- duplicate definitions and definitions with no detected mod caller;
- periodic hook counts, broad iterators, `dirty = 0`, loops, and large files
  with no comments;
- file, localisation-language, and cross-file graph summaries.

The target mod receives the full reference, structure, comment, and hot-path
scan. Dependencies provide effective definitions. A supplied game root uses a
lightweight definition index plus targeted localisation lookup. Its installed
`dlc/*` subdirectories are included automatically for interface/GFX and asset
resolution through targeted candidate scans, so DLC-owned sprites are not
misreported as absent from vanilla.
The Doctor does not perform a full quality audit of vanilla content.

When a referenced texture path is absent but the same basename exists as a
`.dds`, `.png`, or `.tga`, the Doctor emits `ASSET_EXTENSION_MISMATCH` instead
of treating it as a wholly absent asset. Use
[icon-audit.md](icon-audit.md) for class-specific fallback rules, reachability,
default icons, hidden objects, and player-visible prioritisation.

## Interpretation boundary

- "Unresolved" means not found in the supplied effective roots. Without the
  installed game and exact dependencies it is informational, not proof of a
  missing object.
- Bare icon tokens can receive class-specific prefixes, and omitted icon fields
  can use engine defaults. Mod Doctor's generic GFX scan is a baseline; apply
  the object rules in `icon-audit.md` before calling an icon broken.
- Large total-conversion dependency roots can make the general cross-file index
  expensive. For icon-only work, run the mod/game baseline first, then search
  unresolved GFX tokens directly in the exact dependency `interface/` tree.
- An orphan may be a public API, console/debug entry, dependency callback, or
  data-driven engine consumer. Search and read semantics before deleting it.
- Regex and brace-aware indexing can identify likely contracts but cannot prove
  scopes, event order, scripted GUI context, AI choice, save lifecycle, or
  gameplay quality.
- Performance findings identify frequency and fan-out risks; measure or perform
  the smallest runtime test before changing cadence.

Run focused localisation, map, override, log, and runtime workflows after this
baseline. Record accepted false positives in project guidance rather than
weakening global rules for one mod.
