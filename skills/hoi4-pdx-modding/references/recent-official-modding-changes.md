# Recent official HOI4 modding changes (1.14.1-1.19.2)

## Contents

- Purpose and evidence policy
- Current 1.19.2 source map
- Verified current patterns
- Migration and compatibility gates
- Official news audit

## Purpose and evidence policy

Use this reference when a task concerns a feature added, changed, deprecated, or
fixed since 1.14, or when the Wiki may lag the installed game. The audit covers
official Steam news from 2024-03-06 through 2026-07-07. The last article in that
window with a dedicated modding section is patch 1.19.2 on 2026-06-30.

Official news is a change-discovery source, not a complete schema. Apply a
reported token only after finding it in the installed version's generated
documentation or a working current vanilla file. Patch notes sometimes describe
intent with a name that differs from the shipped documentation.

For the current local installation, `launcher-settings.json` reports:

```text
Operation Postern v1.19.2.0.a729 (d245)
```

Do not treat this snapshot as permanent. Re-read `launcher-settings.json` and
the newest Steam patch notes after an update.

## Current 1.19.2 source map

Prefer the generated 1.19.2 documentation under the installed game:

```text
documentation/script_concept_documentation.md
documentation/script_math_functions.md
documentation/effects_documentation.md
documentation/triggers_documentation.md
documentation/loc_formatter_documentation.md
documentation/loc_objects_documentation.md
documentation/script_collection_input.md
documentation/script_collection_operator.md
common/decisions/_documentation.md
common/characters/_documentation.md
common/collections/_documentation.md
common/doctrines/*/_documentation.md
common/raids/_documentation.md
common/ai_strategy/_documentation.md
common/ai_templates/_documentation.md
common/ai_equipment/_documentation.md
common/scripted_guis/_documentation.md
common/special_projects/projects/documentation.md
common/special_projects/prototype_rewards/documentation.md
common/military_industrial_organization/policies/_documentation.md
```

Generated documents establish supported scopes and parameter shapes. Current
vanilla definitions establish the exact nesting and caller context. Check both
when either source is incomplete.

See `vanilla-documentation-map.md` for the complete 50-file inventory, source
limitations, exact lookup workflow, and the current high-value findings that
are broader than the Steam change log.

## Verified current patterns

### Bindable and contextual localisation

1.15 introduced bound localisation objects and localisation formatters. In
1.19.2, a bindable consumer accepts a plain key, formatted localisation, or a
recursive object:

```pdx
custom_effect_tooltip = {
	localization_key = MOD_EXAMPLE_TOOLTIP
	AMOUNT = "25"
	REASON = {
		localization_key = MOD_EXAMPLE_REASON
	}
}
```

All GUI types can use `bound_tooltip`. Use `context_aware_tooltip` or
`context_aware_text` only where the GUI consumer provides a localisation
context. Context support is consumer-specific and recursive; verify it in a
current example from the same window class.

Do not confuse bound localisation with legacy `$KEY$` nesting. If the latter
renders literally in an existing project GUI, either keep the proven inline
fallback or migrate that exact consumer to a verified bound/context-aware form
and test it in-game.

### Focus inlay windows

The current three-part chain is:

```text
common/focus_inlay_windows/<definition>.txt
interface/<window>.gui
common/national_focus/<tree>.txt: inlay_window = { ... }
```

The definition names a GUI container and can provide `visible`, `internal`, and
`scripted_images`; the focus tree places it with `id` and `position`. Current
vanilla examples include `ger_inner_circle_inlay_window.txt` and
`GER_inner_circle_scripted_gui.gui`. This is not a normal scripted-GUI window;
do not add a `common/scripted_guis` object unless the design separately needs
one.

### Math expressions

Current generated 1.19.2 documentation lists these operations:

```text
add and atan atan2 clamp cos divide equals every_collection
greater_than_or_equals if lerp less_than_or_equals log max min mod
multiply not not_equals or pow root round sin subtract tan xor
```

Math expressions use fixed-point arithmetic. Boolean operations return `1.0`
or `0.0`; any non-zero input is true. A parse failure becomes runtime `0.0`.
Approximate functions can have rounding error; follow with `round = yes` only
when an integer result is intended.

Patch 1.19.1 said `sqrt` and `exp` were added, but the installed 1.19.2
`script_math_functions.md` lists neither. Use the documented square-root form
`root = 2`, and do not emit `exp` or `sqrt` until a later installed build
documents or demonstrates those exact tokens.

### Quantified any-object checks and collections

Patch 1.16 announced `count` for all `any_*` object triggers, including scoped
variables. Current generated 1.19.2 trigger documentation explicitly shows the
shape on `any_collection_element`: the result is true when at least `count`
elements match. For other `any_*` triggers, the generated descriptions are not
uniformly updated, so require a current exact example or a focused runtime test
instead of treating the announcement as a complete schema.

Collections can replace manual global loops and counters. They may contain
duplicates after expansion, so prove whether uniqueness matters before using
`collection_size`, `any_collection_element`, or collection iterators.

### Event and focus lifecycle

- Event-level `after = { ... }` runs shared post-option work; use it for a tail
  that must occur after the selected option, not as a substitute for
  `immediate` setup.
- `bypass_effect = { ... }` runs when a focus is bypassed manually or
  automatically. Treat it as a separate lifecycle branch and test both bypass
  and completion.
- `load_focus_tree` supports `copy_completed_from = <country>` in current
  generated effect documentation.
- Decision `war_with_on_remove`, `war_with_on_timeout`, and
  `war_with_on_complete` accept scoped variables as of 1.19. Verify that the
  scope-valued variable still exists when the lifecycle hook executes.

### AI, military, doctrines, and raids

- `front_role_override` is a current AI division-template field; current
  vanilla uses values such as `offence`. Copy only a value proved in the
  current templates.
- AI equipment designs can specify a `design_team` MIO token. The MIO must be
  available to the country and valid for the design.
- `naval_invasion_support_priority` uses strategic-region IDs in current
  vanilla AI strategies. `naval_dominance` accepts an AI-area key or strategic
  region ID in current documentation.
- Current subdoctrines support a list in `track`,
  `allow_in_multiple_tracks = yes`, and cross-track `xor = { ... }`.
  Grand doctrines support `max_track_rows` and `max_track_columns`; doctrine
  tracks support an `active` trigger.
- Current raid types document `unit_animations`, `ai_min_success_chance`, and
  `max_distance`. Preserve the documented `0.0-1.0` unit for success chance.
- `add_temporary_buff_to_units` was removed in 1.19. Use the current
  `unit_modifiers` schema from the exact owning object type.

## Migration and compatibility gates

Search for these before declaring a 1.19 migration complete:

```text
on_ruling_party_change_immediate  # deprecated unsafe compatibility hook
add_temporary_buff_to_units       # removed; use current unit_modifiers schema
cl_tech                           # removed in 1.17; migrated to ca_tech
sqrt / exp                        # announced, but absent from local 1.19.2 math docs
```

Also audit:

- event target localisation order: contextual V1, saved event targets, then
  contextual V2 since 1.15.4;
- `on_leave_faction` and `on_become_faction_member` now fire on every leave or
  join, while `on_send_volunteers` does not fire when volunteers return;
- state-history province building blocks now receive duplicate-block error
  checking, so merge repeated province blocks instead of relying on override;
- normalized triggers and stability comparisons: use the unit documented by
  current generated trigger docs and heed 1.17.4+ range warnings.

## Official news audit

The following entries were inspected from the official Steam app news feed.
Repeated open-beta/live entries are consolidated with the final patch where
they report the same change.

| Date | Official entry | Modding changes relevant to code |
|---|---|---|
| 2024-03-06 | [1.14.1 BOLIVAR](https://store.steampowered.com/news/app/394360/view/5679673637649096241) | `research_weight_factor`; deployed manpower variables; sub-ideology colours; equipment `is_frame`; war-length triggers; faction/volunteer on_action semantics; MIO/AI fixes. |
| 2024-03-13 | [1.14.2](https://store.steampowered.com/news/app/394360/view/5686429670867588092) | Negative stats no longer disable `create_equipment_variant` or AI equipment creation. |
| 2024-03-21 | [1.14.3](https://store.steampowered.com/news/app/394360/view/5686430301718087167) | Correct old ideology token for `on_ruling_party_changed`; deprecated unsafe `on_ruling_party_change_immediate` compatibility hook. |
| 2024-06-10 | [1.14.6](https://store.steampowered.com/news/app/394360/view/5746109972563430519) | Equipment `is_frame` now auto-obsoletes. |
| 2024-08-29 | [1.14.8](https://store.steampowered.com/news/app/394360/view/6240387642454310038) | Invalid intelligence-agency unlock without La Resistance now produces a useful error. |
| 2024-11-11 | [Performance and Modding](https://store.steampowered.com/news/app/394360/view/6148070194801725069) | Bound and formatted localisation, contextual GUI text/tooltips, country-prefixed state/province names, focus navigation, focus inlay windows, and equipment-variant performance work. |
| 2024-11-13 | [1.15.0 Götterdämmerung](https://store.steampowered.com/news/app/394360/view/1783238125180862) | `divisional_commander_xp`; MIO category equipment-group bonuses; resource factor modifiers; AI template redesign; archetype factory strategy; division name lists; continent/naval-invasion triggers; force-concentration strategies; building animation control. |
| 2024-11-21 | [1.15.1](https://store.steampowered.com/news/app/394360/view/1783872411985145) | Added `has_truce_with`. |
| 2024-12-05 | [1.15.2](https://store.steampowered.com/news/app/394360/view/1784506359237381) | AI equipment `design_team`; pre-peace-conference on_action; multiple `same_support_type` support brigades. |
| 2025-01-21 | [1.15.4](https://store.steampowered.com/news/app/394360/view/1789039014498817) | Fixed saved event target localisation evaluation order relative to contextual localisation V1/V2. |
| 2025-03-03 | [1.16 release notes](https://store.steampowered.com/news/app/394360/view/1792751526143057) | Artillery/cavalry/unit-type ratio triggers now include support units. |
| 2025-03-12 | [Operation HEAD](https://store.steampowered.com/news/app/394360/view/1794014851391211) | Added `count` to all `any_object` triggers, including scoped-variable counts. |
| 2025-03-20 | [Operation KNEE](https://store.steampowered.com/news/app/394360/view/1794102528303441) | Added focus `bypass_effect`. |
| 2025-03-27 | [1.16.3 Operation SHOULDER](https://store.steampowered.com/news/app/394360/view/1795283637820747) | Duplicate province-building diagnostics; AI template `front_role_override`; `load_focus_tree.copy_completed_from`; resistance-target removal fix. |
| 2025-04-09 | [1.16.5 open beta](https://store.steampowered.com/news/app/394360/view/1796551539183934) | Fixed missing-state scope crashes and dynamic scopes in `fighting_army_strength_ratio`. |
| 2025-06-16 | [1.16.9](https://store.steampowered.com/news/app/394360/view/1802354289690956) | Added event `after` effect block. |
| 2025-11-20 | [1.17.0 NCNS](https://store.steampowered.com/news/app/394360/view/1816849002009911) | New modifiers and resource-collection trigger; raid range factor; GUI `fade_delay`; buttons with scripted effects in focus inlays; `language=` normalization; removal of `cl_tech`. |
| 2025-11-26 | [1.17.1](https://store.steampowered.com/news/app/394360/view/1817483467033172) | Doctrine grid dimensions; scripted GUI country-switch fix; AI-template weight debug; `naval_dominance` accepts AI areas. |
| 2025-12-04 | [1.17.2](https://store.steampowered.com/news/app/394360/view/1818118366172856) | Doctrine mastery modifiers; track `active`; `has_any_grand_doctrine`; energy modifier; AI faction-theatre ImGui. |
| 2025-12-10 | [1.17.3](https://store.steampowered.com/news/app/394360/view/1818752592120678) | `count_in_collection` equipment ratios, sub-unit categories/definitions, and stockpile checks. |
| 2026-02-19 | [1.17.4](https://store.steampowered.com/news/app/394360/view/1825093633185039) | Safer state triggers; country `energy_ratio`; `only_imported` resource check; normalized-range warnings. |
| 2026-03-16 | [1.17.5](https://store.steampowered.com/news/app/394360/view/1826992588601565) | Console command chains with `&&`; designer icon-weight debug; SubUnitDefinition-based equipment icon pools. |
| 2026-04-21 | [1.18 Peace for Our Time](https://store.steampowered.com/news/app/394360/view/1830163047268442) | Advisor-targeted `pp_spend_priority`; normalized stability error checking. |
| 2026-06-04 | [HOI IV-X update](https://store.steampowered.com/news/app/394360/view/1834602721187475) | `naval_invasion_support_priority`; blocked naval regions respected by AI objectives; equipment-role raw-score debug. |
| 2026-06-10 | [1.19.0 Thunder at our Gates](https://store.steampowered.com/news/app/394360/view/1835236783557496) | Multi-track subdoctrines and `xor`; scoped decision war hooks; `unlock_subunit`; medal/HQ changes; removal of temporary unit buff effect; raid/leader/entrenchment additions; AI-template debug weights. |
| 2026-06-17 | [1.19.1](https://store.steampowered.com/news/app/394360/view/1835871199300348) | `impassable_ignored_links`; announced additional math functions, subject to the 1.19.2 documentation caveat above. |
| 2026-06-30 | [1.19.2](https://store.steampowered.com/news/app/394360/view/1836506165562428) | Updated math docs; logical math operations, `lerp`, `atan`, `atan2`; advisor `always_show_on_actions_tooltip`; raid `unit_animations`. |
