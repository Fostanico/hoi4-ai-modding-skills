# Icon and artwork audit

Use this workflow when the user asks which ideas, decisions, traits, units,
technologies, projects, MIOs, equipment, or other objects lack icons. The goal
is to distinguish broken artwork from intentional defaults and dependency
content, not to count every absent `icon` or `picture` field as a defect.

## Contents

- Effective resource tree
- Audit passes
- Object rules
- Reachability and severity
- Required report shape
- Runtime boundary

## Effective resource tree

Build the same resource view that the game will load:

1. Target mod.
2. Exact enabled dependency versions in load order, inspected selectively for
   candidate tokens unless a full dependency audit is required.
3. Installed game root for the target build.
4. Every installed `GAME_ROOT/dlc/*` directory, because DLC interface and GFX
   files are ordinary subtrees and are not necessarily present under the base
   `interface/` directory.

Run Mod Doctor with the mod and matching game before a focused icon pass. Its
game scan includes targeted checks of installed DLC interface trees:

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-mod.ps1 `
  -ModRoot '<MOD_ROOT>' `
  -GameRoot '<HOI4_GAME_ROOT>' `
  -AsJson -OutputPath '<REPORT>.json'
```

For unresolved candidate tokens, search only the exact dependency's
`interface/` tree first:

```powershell
rg -n -F -e 'GFX_missing_token' '<DEPENDENCY_ROOT>/interface'
```

Use Mod Doctor's `-DependencyRoots` only when a full cross-file dependency
baseline is actually needed. Very large total-conversion dependencies can make
the general-purpose index expensive; icon-only work should prefer targeted
token and asset-path lookup over loading the entire dependency graph.

Do not treat a descriptor's dependency list as proof that the dependency is
enabled or that the installed version supplies a token. Check the active
playset when practical. If an exact dependency cannot be inspected, label the
reference dependency-bound or unresolved rather than broken.

## Audit passes

Perform these passes in order:

1. Index `name = GFX_*` definitions in loaded `.gfx` and `.gui` files.
2. Resolve each definition's `texturefile` against every effective root.
3. Require the exact path, case, and extension. If the requested path is
   absent, search the same directory for the same basename with `.dds`, `.png`,
   or `.tga`; report this separately as an extension mismatch.
4. Parse objects by brace depth so nested effects are not mistaken for object
   definitions.
5. Apply the object-specific naming and fallback rules below.
6. Search callers and grants to separate reachable content from definition-only
   or debug content.
7. Read localisation for player-visible meaning before describing the affected
   feature. Do not infer a character or mechanic from its token alone.
8. Compare a fresh `error.log` only as supporting evidence. Many artwork errors
   are logged only after the relevant screen or object is opened.

Never infer that a GFX object works merely because the `.gfx` name exists. Its
texture path must also resolve. Conversely, do not infer that a bare token is
broken until the engine's class-specific prefix has been applied.

## Object rules

### Ideas

- `picture = GFX_x` uses `GFX_x` exactly.
- `picture = foo` conventionally resolves as `GFX_idea_foo`.
- `picture = idea_foo` resolves as `GFX_idea_foo`, not
  `GFX_idea_idea_foo`.
- With no `picture`, test the conventional `GFX_idea_<idea_id>` fallback.
- `picture = nothing`, an empty placeholder sprite, or a comment such as
  "not finished" means missing custom artwork, not a parser failure.
- Rank visible `country` ideas above `hidden_ideas`. Hidden ideas may
  intentionally carry modifiers without player-facing artwork.

### Decisions and categories

- A decision `icon = GFX_x` uses the exact GFX object.
- A bare decision token such as `icon = generic_construction` conventionally
  resolves as `GFX_decision_generic_construction`.
- `icon = none` is an intentional no-art choice. Report it only when the user
  asks for all non-custom icons.
- A decision with no `icon` normally receives the engine's generic/default
  presentation. Classify it as default art, not a broken icon.
- A category bare token conventionally resolves as
  `GFX_decision_category_<token>`.
- Audit a category's `picture` separately from its small category `icon`; one
  may work while the other is missing.
- Reject malformed placeholders such as `icon = GFX` as broken explicit
  references.

### Leader traits, abilities, and scientist traits

- Unit-leader traits conventionally use `GFX_trait_<trait_id>`. Confirm the
  convention against current vanilla and loaded overrides.
- Country-leader and advisor traits commonly have no independent trait icon.
  Do not bulk-report them without a current consumer proving that an icon is
  expected.
- An ability with no `icon` is a missing custom icon only if the ability is
  reachable through `enable_ability`, a trait, or another live grant path.
- A scientist trait uses its explicit `icon`; otherwise it falls back to
  `GFX_<scientist_trait_id>`.
- Search for near-match artwork. A file or GFX name that resembles a trait but
  does not match the trait's actual ID is a wiring mismatch, not proof that the
  trait has an icon.

### Special projects and dynamic modifiers

- A special project uses its explicit `icon`; otherwise it falls back to
  `GFX_<project_id>`.
- A dynamic modifier's icon is optional and only affects GUIs that render it.
  Classify an omitted icon as optional presentation unless a visible consumer
  requires it.

### Units, templates, and counters

- A division template does not own a simple decision-style icon field. Trace
  its battalions and support companies instead.
- Do not confuse a sub-unit's `sprite` or `map_icon_category` with a complete
  custom counter-icon chain. Verify the current vanilla consumer and the
  conventional `GFX_unit_<sub_unit_id>_icon_medium`, `_medium_white`, and
  `_small` objects when the mod supplies custom counters.
- Reusing a valid vanilla `sprite` is not missing artwork.
- If `.gfx` asks for `unit_x.png` while the repository contains `unit_x.dds`,
  report an exact extension mismatch and the affected sub-unit family.

### Technologies, equipment, and MIOs

- Script-only technologies with no tree folder/path can be intentionally
  hidden and granted by effects. Do not require a technology-tree icon unless
  the technology is actually rendered.
- Equipment versions commonly inherit artwork through their `archetype` or
  parent. Audit the inheritance chain before reporting child equipment.
- Resolve MIO icons against the exact enabled dependency and DLC version.
  Dependency-provided MIO sprites are not standalone-mod defects when the
  corresponding content is correctly gated.

## Reachability and severity

Classify every finding into one of these buckets:

1. **Confirmed broken**: a reachable object explicitly or conventionally
   resolves to a missing GFX object, or the GFX object's asset path is absent.
2. **Extension/path mismatch**: a near-match file exists but the registered
   path, case, or extension differs.
3. **Missing custom artwork**: `none`, `nothing`, or no field intentionally
   produces default/blank presentation.
4. **Dependency-bound**: valid only with a named, verified dependency version.
5. **Hidden or definition-only**: currently not player-visible or has no live
   grant/caller.
6. **Optional presentation**: the engine permits omission, such as many dynamic
   modifier icons.
7. **Unresolved**: the effective playset or current consumer was not available.

Do not merge these buckets into one total. A useful audit reports both object
instances and distinct missing GFX/asset resources, because one missing sprite
may affect many decisions or traits.

## Required report shape

Lead with confirmed player-visible breakage. For each group include:

- object type and count;
- IDs and localised names where useful;
- definition file and line;
- expected GFX token;
- missing or mismatched asset path;
- reachability evidence;
- dependency/DLC assumption;
- smallest repair, without applying it unless authorized.

Then list default, hidden, optional, and dependency-bound content separately.
State the roots inspected and whether the newest log predates the audit.

## Runtime boundary

A static audit cannot prove rendering, frame selection, alpha, scaling, or
which fallback the current UI ultimately displays. After approved repairs, ask
whether the user wants an isolated `-debug` test. Open each affected screen,
exercise reachable abilities/projects, inspect counters on the map and in the
designer, then compare the fresh log. Do not launch Steam or the game without
the user's consent.
