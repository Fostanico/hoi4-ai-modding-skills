# Installed vanilla documentation map (1.19.2)

## Contents

- Authority and limitations
- Fast lookup workflow
- High-value engine rules
- Database documentation inventory
- Generated documentation inventory
- Refresh procedure

## Authority and limitations

This snapshot covers all 50 Markdown files found on 2026-07-13 in an installed
`Operation Postern v1.19.2.0.a729 (d245)` build. Discover the user's current
game root and version before relying on the inventory.

Use an installed Markdown document as the exact token, supported-scope, and
parameter-shape authority for that build, then verify nesting and caller
context in a working current vanilla definition. The documents are not equally
reliable:

- generated `documentation/*_documentation.md` files are exhaustive lookup
  tables, but some internal links refer to old filenames and prose can contain
  typos;
- database-adjacent `_documentation.md` files often provide the best lifecycle
  and performance notes for their object type;
- a document shipped in the current build can still describe an older system
  snapshot (`on_actions` says updated 2024-11 and `ai_templates` says 2024-08);
- `common/special_projects/special_projects_documentation.md` contains visible
  design-stage comments and TBD syntax. Prefer the implemented documents under
  `common/special_projects/projects`, `prototype_rewards`, and
  `specialization`, plus current vanilla definitions;
- `modifiers_documentation.md` explicitly says a listed modifier is recognized
  by the game but not necessarily consumed in every context. A listed modifier
  is not proof that a specific idea, trait, MIO, doctrine, or dynamic modifier
  accepts it.

Never turn a comment containing `TODO`, `TBD`, “syntax just for reference”, or
an unresolved question into a reusable production template without a current
working vanilla example.

## Fast lookup workflow

Rebuild the inventory after a game update:

```powershell
& <SKILL_ROOT>/scripts/index-vanilla-docs.ps1 -GameRoot <HOI4_GAME_ROOT>
```

Find an exact generated entry rather than reading an 8,000-line file linearly:

```powershell
rg -n '^## any_collection_element$' `
  '<HOI4_GAME_ROOT>/documentation/triggers_documentation.md'
rg -n '^## set_variable$' `
  '<HOI4_GAME_ROOT>/documentation/effects_documentation.md'
rg -n '^## political_power_gain$' `
  '<HOI4_GAME_ROOT>/documentation/modifiers_documentation.md'
```

Then search current vanilla for the exact token and read the whole containing
object. A generated entry proves the token and supported scopes; a current
object proves the consumer, nesting, lifecycle, and surrounding scope.

## High-value engine rules

### Collections and comparisons

- Collections can be cheaper and clearer than manual arrays, but expansion
  does not guarantee unique elements.
- `common/collections/_documentation.md` gives named-collection scope rules:
  inside `limit`, the element is the current scope, `PREV` is the caller,
  `ROOT = PREV.ROOT`, and `FROM = PREV.FROM`.
- The generated `collection_size` trigger uses inclusive comparisons:
  `value > 3` means at least 3, and `value < 3` means at most 3. Do not read
  these as ordinary strict mathematical operators.
- `count_in_collection` is country-scoped and its `unit`, `buildings`, and
  `manpower` modes are mutually exclusive. Current 1.19 also documents
  `equipment_ratio`, `unit_category`, and `stockpile` filters.

### Variables, constants, and scope existence

- Dynamic variables are read-only and are valid only in consumers that accept
  variables. Check their documented scope and `@target` form.
- `scope_exists` checks whether a scope object is present, not whether a
  country exists. Variable scopes are always considered valid, so
  `var:target = { scope_exists = yes }` does not prove that the stored value is
  a live country or character.
- Script constants have no runtime performance cost but work only in consumers
  that explicitly support them. All scoped variables accept a fixed-point
  constant through `constant:<category>.<key>`.
- Hot reload requires reloading the constants database and then every database
  that consumed the constants; reloading constants alone does not reinject
  values into already loaded objects.

### Decisions and frequently evaluated UI

- Decision `allowed` is checked at game start/save load. Use it to eliminate
  impossible country instances, especially targeted decisions.
- `visible` and `available` are checked when the decision UI refreshes and can
  run every frame.
- `target_root_trigger` is a daily acting-country prefilter;
  `target_trigger` is checked daily per candidate target.
- Current targeted state decisions use `state_target = yes`; prefer a narrow
  `target_array` such as the current vanilla
  `target_array = ROOT.core_states` consumer over a world-state scan. Older
  `state_trigger` token tables are not the current decision template.
- Scripted GUIs update every tick by default. Set `dirty = <variable>` and
  change that variable only when displayed state changes.

### GUI, localisation, and map modes

- The current formatter file is
  `documentation/loc_formatter_documentation.md`; do not follow the stale
  `localization_formatter.md` link embedded in another generated document.
- Contextual localisation supports null-aware expressions of the form
  `[(OBJECT ? TRUE_CASE : FALSE_CASE)]`. Use them only where the consumer
  supplies that localisation object.
- Focus inlays support `scripted_images`, `scripted_buttons`, and
  `scripted_progressbars`. Names must match GUI subcomponents; button effects
  run in the focus-tree country scope.
- Scripted map modes can restrict rendering with targeted-decision-style
  `targets`. Prefer this to evaluating every scope. Use
  `force_update_map_mode` for event-driven refresh instead of `update_daily`
  when daily refresh is unnecessary.

### MIO, equipment, and AI

- MIO `allowed` is mandatory and is evaluated for every country at startup.
  `visible` and `available` run in MIO scope with `FROM = country` when the UI
  is displayed.
- MIO `include` has no file load-order requirement, but cross-file hot reload
  requires saving/reloading both the included and including definitions.
- Policy equipment/production bonuses name the equipment group/category/type
  around the stat block; trait bonuses do not use the same nesting.
- Every MIO bonus used by AI needs an archetype-specific or `default` entry in
  `ai_bonus_weights`; otherwise the game logs an error.
- AI template entries must use exactly one of `blocked_for` and
  `available_for`. The vanilla document calls behavior undefined when neither
  or both define selection ambiguously. Ties in target-template priority are
  order-sensitive, and the AI creates modified copies rather than editing a
  template in place.
- Goal-based naval AI scores objectives within a goal's `[min_priority,
  max_priority]` range from a normalized importance value. Inspect it with
  `imgui show ai_navy`.

### Special projects, raids, factions, and peace conferences

- Current special-project `allowed` is a startup country trigger restricted to
  tag/original-tag/DLC-style checks. Runtime `visible`/`available` use project
  scope with `FROM = country`.
- Project output `facility_state_effects` and `scientist_effects` are skipped
  when script completion has no facility or scientist. Put mandatory country
  work in `country_effects`.
- Specialization tokens and facility-building `specialization` fields must
  match exactly.
- Raid `show_target` and `visible` should remain cheap. `essential_equipment`
  gates raid creation; additional equipment is collected later, and the two
  amounts use their maximum rather than being added.
- Raid actor and victim outcome blocks both run in raid-instance scope; the
  split controls UI presentation. Country/state targets are exposed through
  `var:actor_country`, `var:victim_country`, `var:target_state`, and
  `var:target_province`.
- `create_faction` is marked obsolete; use `create_faction_from_template` for
  the current faction system. An empty faction-goal `completed` block never
  completes the goal.
- During a peace conference, ordinary ownership and diplomatic state may not
  update until before or after the conference. Use `pc_*` triggers for changes
  occurring inside it. The documented scope chain is negotiator `ROOT`, taker
  `FROM`, giver `FROM.FROM`, and state `FROM.FROM.FROM`.

### Debugging commands

The current generated console documentation confirms:

```text
help <command>                 show current command help
helplog                        write command help to game.log
eval_trigger                   evaluate an inline trigger on selected scope
eval_effect                    run an inline effect on selected scope
effect / e <tag> <effect>      run a scripted effect on selected scope
debug_tooltip                  toggle debug tooltips
debug_show_event_ID            show event IDs
debug_events / debug_dumpevents count and dump event data
loc_check*                     check missing localisation by content type
imgui                          inspect available ImGui panels
aiview                         enable AI debug information
```

`ai_trace` and `ai_dump` are documented as unavailable in release builds. Do
not make them required test steps for a normal retail installation.

## Database documentation inventory

Read the document adjacent to the object being changed:

- Core content: `common/characters/_documentation.md`,
  `common/decisions/_documentation.md`, `common/on_actions/_documentation.md`,
  `common/collections/_documentation.md`, and
  `common/script_constants/documentation.md`.
- AI: `common/ai_strategy/_documentation.md`,
  `common/ai_equipment/_documentation.md`,
  `common/ai_templates/_documentation.md`,
  `common/ai_faction_theaters/_documentation.md`,
  `common/ai_navy/_documentation.md`, and
  `common/ai_navy/taskforce/_documentation.md`.
- Military databases: `common/units/equipment/_documentation.md`,
  `common/equipment_groups/_documentation.md`,
  `common/resources/_documentation.md`, and all five doctrine documents under
  `common/doctrines` (`_documentation.md`, plus `folders`, `grand_doctrines`,
  `tracks`, and `subdoctrines`).
- MIO: the `organizations`, `policies`, and `ai_bonus_weights`
  `_documentation.md` files under `common/military_industrial_organization`.
- Special projects: `common/special_projects/projects/documentation.md`,
  `prototype_rewards/documentation.md`, `specialization/documentation.md`,
  the design-stage `special_projects_documentation.md`, plus
  `common/scientist_traits/_documentation.md`.
- Intelligence operations: `common/operations/_documentation.md`,
  `common/operation_phases/_documentation.md`,
  `common/operation_tokens/_documentation.md`, and
  `common/intelligence_agency_upgrades/_documentation.md`.
- Diplomacy and factions: `common/factions/_documentation.md` and the
  `ai_peace` and `cost_modifiers` documents under `common/peace_conference`.
- GUI/map/assets: `common/scripted_guis/_documentation.md`,
  `common/focus_inlay_windows/documentation.md`,
  `common/map_modes/documentation.md`,
  `common/strategic_locations/documentation.md`, and
  `common/raids/_documentation.md`.

## Generated documentation inventory

The installed `documentation` directory contains 11 Markdown references:

- `effects_documentation.md`: exact effect scopes, targets, parameters, and
  examples.
- `triggers_documentation.md`: exact trigger scopes, targets, parameters, and
  comparison semantics.
- `modifiers_documentation.md`: recognized modifier tokens grouped by scope;
  consumer support still needs proof.
- `dynamic_variables_documentation.md`: read-only dynamic variables grouped by
  scope.
- `script_concept_documentation.md`, `script_math_functions.md`,
  `script_collection_input.md`, and `script_collection_operator.md`: bound and
  contextual localisation, collections, math, and constants.
- `loc_objects_documentation.md` and `loc_formatter_documentation.md`:
  localisation object promotions/properties and formatter requirements.
- `console_commands_documentation.md`: commands present in this build and
  release-build availability notes.

## Refresh procedure

After a patch:

1. Re-read `launcher-settings.json` and run `index-vanilla-docs.ps1`.
2. Diff the path/headings inventory against this map; inspect added, removed,
   and renamed documents first.
3. Re-query exact entries used by project templates in effects, triggers,
   modifiers, dynamic variables, math, and console docs.
4. Compare database-adjacent prose with current vanilla objects. Record stale
   dates, TODO/TBD text, broken links, and patch-note discrepancies rather than
   silently treating them as production syntax.
5. Update this map, affected topic references, the canonical technical guide,
   and validation steps together.
