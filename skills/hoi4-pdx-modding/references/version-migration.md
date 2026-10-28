# Version migration

Current migration targets were checked against installed Operation Postern
1.19.4.0.48d6 (a783) and official patch notes on 2026-10-28. Earlier sections
retain their historical evidence. Community adaptation guides are discovery material;
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
5. Validate only the affected paths. Use the shared
   [runtime-test necessity gate](../../hoi4-content-builder/workflows/test-mod.md)
   before a launch; a source-only skill refresh does not require one. When a
   native test is warranted and authorized, inspect its fresh log and the
   smallest affected path. A clean parser does not prove runtime behavior.

## Current high-risk gates

### Operation Postern 1.19.4

Start from the [evidence-qualified change map](recent-official-modding-changes.md#1194-additions-and-evidence-gaps).
For 1.19.3-to-1.19.4 migrations, prioritize full GUI overrides containing these
current native names (paths are relative to the game root):

| Vanilla file | Controls that an old override can omit |
| --- | --- |
| `interface/nationalfocusview.gui` | `mini_map_clip`, `mini_map`, `minimap_border`; the inset is read by native code |
| `interface/countrytradeview.gui` | `auto_import_checkbox`, budget/slider controls, `auto_import_priority_window` |
| `interface/countryconstructionsview.gui` | `repair_order_window`, `repair_order_reset_queue_button` |
| `interface/countryintelligenceagencyview.gui` | queued-upgrade `queue_badge`, `queue_badge_text` |
| `interface/countrydiplomacyview.gui` | `edit_auto_response`, `recall_volunteers` |
| `interface/command_character_view.gui` | `command_character_view_filter_button`, advisor category sprite |

Merge the owning containers and referenced GFX from current vanilla, preserving
the mod's intended layout. A copied button name alone does not reproduce native
behavior. Do not infer a generic PDX API for automatic trade, volunteer recall,
or queueing from the presence of a GUI control.

For equipment, compare `tank_chassis.txt`, modules, affected battalions,
technologies and doctrine rewards together. Preserve equipment-level
`module_add_stats_multiplier` and `scaled_by_reliability` when merging a full
override. The new maximum casualty trickleback is defined in
`common/defines/00_defines.lua`; a large displayed bonus need not bypass it.
Do not retune a mod by copying selected patch-note numbers without its consumers.

Audit state-variable math workarounds and hidden advisor modifier text against
the corresponding engine fixes. Newly announced `overlord_fights`,
`set_major.immediate_status_update` and `module_multiply_stats_multiplier` lack
complete current text consumers in this audit; keep their unresolved shape
explicit rather than teaching an invented template. Descriptor version changes
alone do not establish compatibility.

### Operation Postern 1.19.3

For a 1.19.2-to-1.19.3 migration, audit these paths before broad testing:

- Full overrides of `common/on_actions/00_on_actions.txt` must retain
  `on_navy_leader_won_combat` and `on_navy_leader_lost_combat`. Both use
  `THIS = admiral`, `FROM = owner country`, and `FROM.FROM = combatant`.
- Naval-combat content can use
  `is_fighting_in_strategic_region = <strategic region ID>` only from a
  combatant scope. Do not substitute an AI-area token.
- `set_autonomy` paths that should preserve a target country's existing
  subjects need `keep_subjects = yes`; test both subject ownership and war
  state after the transition.
- New collection operators `is_core_of` and `is_not_core_of`, and Army HQ
  tokens `is_deployed`, `state_deployed`, and `province_deployed`, are present
  in the 1.19.3 engine but missing from the shipped generated Markdown. With no
  complete current vanilla consumer, require a focused runtime test before
  promoting their exact block shape into a template.
- Full unit-file overrides must be compared against current `essential`
  blocks. Rebalance battalion adjusters at partial equipment/manpower,
  because 1.19.3 scales their effect with sub-unit readiness.
- Recheck custom facility construction costs and infrastructure interaction;
  do not carry 1.19.2 numeric defaults forward by memory.

Patch 1.19.3 also fixes one native crash path for undersized modded text
buffers. It does not prove that long localisation fits: keep multilingual
wrap, clipping, and overflow tests.

### Selectable frontend backgrounds

Current `common/frontend/backgrounds/base_backgrounds.txt` defines one key per
`gfx/loadingscreens/<key>.dds`. A scalable thumbnail also requires
`GFX_<key>_small`, normally pointing to
`gfx/loadingscreens/<key>_small.dds`. Optional fields are `dlc_allowed`,
`locale`, and `gfx`. The current vanilla `load_1.dds` and
`load_1_small.dds` are 1920x1440 and 192x144 respectively; match those current
consumer dimensions unless a verified custom `gfx` path intentionally changes
the full-size behavior.

Treat DDS as mandatory in `gfx/loadingscreens`. A 1.19.2 runtime test converted
21 working uncompressed RGBA DDS loading screens to pixel-identical RGBA PNGs
and updated every known `.gfx` path; the engine failed to load them. Restoring
the original DDS files and registrations restored the supported contract.
Ordinary GFX sprites accepting PNG does not imply that the loading-screen
database accepts PNG.

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
- Consumer goods still combine `consumer_goods_expected_value` with
  `(1 - consumer_goods_factor)`. Keep both tokens.
- Custom achievements belong in `common/achievements/` with `unique_id`, not
  in `common/achievements.txt`.

## Evidence paths

- `common/frontend/backgrounds/base_backgrounds.txt`
- `interface/frontendmainview.gui`
- `interface/small_background.gfx`
- `common/bookmarks/the_gathering_storm.txt`
- `common/units/fire_support.txt`
- `common/units/artillery.txt`
- `history/general/taog_hq_template.txt`
