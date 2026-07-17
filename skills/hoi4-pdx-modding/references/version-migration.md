# Version migration

Verified against installed Hearts of Iron IV Operation Postern 1.19.2.0
(d245) on 2026-07-17. Community adaptation guides are discovery material;
installed documentation and current vanilla consumers decide the emitted code.

## Migration order

1. Record old and new game versions, DLC assumptions, dependencies, playset,
   launcher `.mod`, `descriptor.mod`, and every `replace_path`.
2. Run the sibling review skill's `audit-vanilla-overrides.ps1`. Exact-path
   overrides are forks of vanilla files: compare the complete new vanilla file,
   not only the block the mod originally changed.
3. Classify each change as parser/schema, lifecycle, scope, database content,
   GUI/GFX, map/history, AI, media, or balance. Patch notes locate likely
   changes; generated documentation and a current consumer prove syntax.
4. Merge new vanilla containers, callbacks, defaults, fallbacks, and DLC gates
   into retained overrides. Remove an override when an additive file can express
   the same mod behavior.
5. Validate, inspect a fresh log, then test the smallest runtime path for each
   affected class. A clean parser does not prove GUI callbacks, AI selection,
   audio playback, shader compilation, or save migration.

## Current high-risk gates

### Selectable frontend backgrounds

Current `common/frontend/backgrounds/base_backgrounds.txt` defines one key per
`gfx/loadingscreens/<key>.dds`. A scalable thumbnail also requires
`GFX_<key>_small`, normally pointing to
`gfx/loadingscreens/<key>_small.dds`. Optional fields are `dlc_allowed`,
`locale`, and `gfx`. The current vanilla `load_1.dds` and
`load_1_small.dds` are 1920x1440 and 192x144 respectively; match those current
consumer dimensions unless a verified custom `gfx` path intentionally changes
the full-size behavior.

Current `interface/frontendmainview.gui` contains the `change_background`,
`background_selection`, and `available_background` containers. A mod that
retains an older full-file override without these containers removes current UI
behavior and may destabilize the frontend. Prefer additive background/GFX files
and keep vanilla `frontendmainview.gui` unless the mod truly changes the layout.

### Bookmarks

Current `common/bookmarks/the_gathering_storm.txt` documents `filters = {
label }`, per-country `label = { ... }`, deterministic `label_order`,
`sort_unplayed_first`, `include_majors_in_minor_list`,
`apply_filter_to_majors`, `apply_filter_to_other_country`, and
`scrollable_country_list`. Older guidance claiming that label order cannot be
controlled is obsolete. Use the content-builder `bookmark.txt` skeleton.

### Regimental and divisional support

Current `common/units/fire_support.txt` uses
`allowed_battalion_groups = { ... }`, category
`category_regimental_support_battalions`, and `divisional = no` for regimental
support. Current divisional-support consumers such as `artillery.txt` use
`regimental = no`. Do not invent `regimental = yes`; copy the current consumer
matching the intended slot and DLC.

### Army headquarters

Current `history/general/taog_hq_template.txt` runs inside
`every_possible_country`, gates on `has_dlc = "Thunder at Our Gates"`, and
includes a generic fallback `division_template` with `is_army_hq = yes`.
Country-specific additions must preserve a working fallback. A full override of
this file must be re-merged after updates so newly added countries and fallback
logic are not lost.

## Tables and advanced systems

- Modifier and define lists from an old guide are search seeds only. Rebuild
  modifier facts from current `documentation/modifiers_documentation.md`, then
  find a current consumer of the same object type. Read current define files
  directly and never carry numeric balance defaults forward by memory.
- Collections, doctrines, factions, raids, special projects, scientists,
  focus inlays, math expressions, MIOs, and AI templates already have routed
  installed documentation in `vanilla-documentation-map.md`. Recheck the exact
  database document and a current consumer before promoting a tutorial snippet.
- Map and history migrations require complete ID-domain checks. GUI, GFX,
  models, music, and shaders require resource-chain checks plus runtime tests.

## Evidence paths

- `common/frontend/backgrounds/base_backgrounds.txt`
- `interface/frontendmainview.gui`
- `interface/small_background.gfx`
- `common/bookmarks/the_gathering_storm.txt`
- `common/units/fire_support.txt`
- `common/units/artillery.txt`
- `history/general/taog_hq_template.txt`
