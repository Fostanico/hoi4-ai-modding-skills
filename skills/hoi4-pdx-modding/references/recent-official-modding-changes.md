# Recent official HOI4 modding changes (1.14.1-1.19.4)

## Contents

- Purpose and evidence policy
- Current 1.19.4 source map
- 1.19.4 additions and evidence gaps
- Verified 1.19.3 additions
- Verified current patterns
- Migration and compatibility gates
- Official news audit

## Purpose and evidence policy

Use this reference when a task concerns a feature added, changed, deprecated, or
fixed since 1.14, or when the Wiki may lag the installed game. The audit covers
official Steam news from 2024-03-06 through the 1.19.4 QoL patch on 2026-10-27.
The 1.19.4 additions below were checked against installed text on 2026-10-28;
earlier sections retain their original version-specific evidence.

Official news is a change-discovery source, not a complete schema. Apply a
reported token only after finding it in the installed version's generated
documentation or a working current vanilla file. Patch notes sometimes describe
intent with a name that differs from the shipped documentation.

For the current local installation, `launcher-settings.json` reports:

```text
Operation Postern v1.19.4.0.48d6 (a783)
```

Do not treat this snapshot as permanent. Re-read `launcher-settings.json` and
the newest Steam patch notes after an update.

## Current 1.19.4 source map

Prefer the generated and database-adjacent documentation under the installed game:

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

The 1.19.4 Markdown inventory remains 50 files (11 under `documentation`, 39
under `common`); an unchanged file count does not imply unchanged contents.
The earlier 1.19.3 audit found engine registrations for
`is_deployed`, `state_deployed`, `province_deployed`, `is_core_of`,
`is_not_core_of`, and `is_fighting_in_strategic_region`; generated trigger,
dynamic-variable, and collection-operator documents omit some or all of those
entries. In that situation, combine the official patch note, current executable
token registration, and a current vanilla consumer. If no consumer exists,
mark the parameter shape as provisional. Resolve it only when a task actually
needs that feature, using the shared runtime-test necessity gate.

See `vanilla-documentation-map.md` for the complete 50-file inventory, source
limitations, exact lookup workflow, and the current high-value findings that
are broader than the Steam change log.

## 1.19.4 additions and evidence gaps

Official discovery source: [QoL patch 1.19.4, 2026-10-27](https://steamcommunity.com/ogg/394360/announcements/detail/684142629662760620),
also readable in the [official Steam announcement feed](https://store.steampowered.com/news/posts/?appids=394360&feed=steam_community_announcements).
The local build matches the announced checksum `a783`. No game was launched
for this documentation refresh, and no complete old vanilla tree was available
for a three-way diff; the comparisons below are against the prior skill snapshot.

| Change | Installed 1.19.4 evidence | Authoring decision |
| --- | --- | --- |
| Fuel conservation AI | `common/ai_strategy/_documentation.md`, `stockpile_fuel` section | Use percentage thresholds `start_below` / `stop_above`, not `value`. See the [fuel strategy contract](ai-and-military-content.md#fuel-conservation-in-1194). This is a documented example; no active vanilla strategy block was found. |
| Module-derived additive stats | `common/units/equipment/tank_chassis.txt`, `light_tank_chassis_0`, `_2`, `_3` | `module_add_stats_multiplier` belongs inside the equipment definition. Current values are signed adjustments such as `soft_attack = -0.05` and `0.05`, not literal `0.95` / `1.05` multipliers. |
| Reliability-scaled stats | `tank_chassis.txt`, `light_tank_chassis` and other chassis | `scaled_by_reliability = { max_strength = 0.5 }` is a current consumer. Keep reliability, reliability factor, carrier deck size and IC cost out of this block, as the release notes specify. Do not infer its entire numerical formula from the block alone. |
| Multiplicative module stats | `module_multiply_stats_multiplier` is announced, but absent from the searched `common`, `events`, `history` text and generated docs | Record the capability; do not publish a validated block or numeric convention without further evidence. |
| Subject border wars | Announced `overlord_fights`; shipped `start_border_war` entry still lacks it, with no current text consumer found | Intended opt-out of overlord substitution is known; exact nesting is unresolved. Do not invent whether it belongs at the root, attacker or defender level. |
| Immediate major-list update | Announced `set_major` argument `immediate_status_update = yes`; shipped entry only shows scalar `set_major = yes` | Keep the existing scalar form for ordinary use. The extended block's main value key is unverified; do not invent `value` or `major`. |
| State-variable math | Official fix for state-scoped variables being parsed as numbers | Preserve scoped-variable meaning; inspect old workarounds before carrying them forward. No new math function or alternate state syntax is implied. |
| Advisor tooltip visibility | Official `hidden_modifier` fix; current `common/country_leader/00_traits.txt` has trait-level consumers | Hidden display does not remove modifier effects. Do not duplicate the same bonus in a visible block to compensate for the old tooltip bug. Native rendering was not retested. |
| Exiled-leader trait diagnostics | Official logging fix | Treat old log evidence as version-bound; it does not introduce a new trait schema. |

The installed equipment schema document still omits the three new equipment
block names. Prefer the chassis consumer where one exists instead of rejecting
it solely because the schema index is stale. Preserve historical evidence dates
for other examples; do not relabel the whole template catalog as retested.

For full GUI replacements, use the [1.19.4 migration map](version-migration.md#operation-postern-1194).
The new native controls are not evidence of new scripted-GUI effects. For balance
work, re-read current chassis/modules, sub-units, technologies and doctrines
together. Current `common/defines/00_defines.lua` also sets
`NMilitary.MAX_CASUALTY_TRICKLEBACK = 0.95`; displayed modifier totals alone do
not establish the applied casualty recovery beyond that cap.

## Verified 1.19.3 additions

### Admiral combat callbacks and combatant-region trigger

Current vanilla registers both callbacks in `common/on_actions/00_on_actions.txt`
and consumes them in `14_sea_on_actions.txt`:

```pdx
on_navy_leader_won_combat = { }
on_navy_leader_lost_combat = { }
```

For both callbacks, `THIS` is the admiral, `FROM` is the admiral's owner
country, and `FROM.FROM` is the combatant. The combatant scope accepts:

```pdx
FROM.FROM = {
	is_fighting_in_strategic_region = 95
}
```

The strategic-region value is an ID, not an AI-area key. Keep combatant work
inside the callback's immediate scope chain; do not assume that a saved target
will remain meaningful after combat ends.

### Preserving subjects during autonomy changes

`set_autonomy` now accepts `keep_subjects = yes`. Current Australia content
uses it while changing AST's autonomy relationship:

```pdx
OVERLORD = {
	set_autonomy = {
		target = AST
		autonomy_state = autonomy_associated_dominion
		freedom_level = 0.5
		end_wars = no
		end_civil_wars = no
		keep_subjects = yes
	}
}
```

Use it when the target country must retain its existing subject hierarchy.
Audit subject ownership before and after the transition; omitting the flag can
release subjects in paths that previously relied on implicit behavior.

### Core-state collection filters and deployed Army HQ data

Patch 1.19.3 adds the collection-operator forms
`is_core_of = ScopedVariable` and `is_not_core_of = ScopedVariable`. Prefer
them over applying the equivalent trigger once per state when filtering a
large state collection. The current executable registers both operator names,
but shipped collection documentation and vanilla text contain no complete
consumer. Do not invent a reusable block from the patch-note shorthand: prove
the exact scoped-variable form in a focused test before production use.

The engine also registers the unit-leader trigger `is_deployed` and dynamic
variables `state_deployed` and `province_deployed` for Army HQ leaders. These
are absent from the current generated trigger and dynamic-variable documents
and have no current vanilla text consumer. Treat them as 1.19.3 engine
capabilities with an unresolved authoring example, not as a copy-ready
template. Test undeployed, deployed, moving, withdrawing, save/reload, and
non-HQ leaders before relying on them.

### Crash and balance implications

- 1.19.3 fixes a native crash caused by undersized text buffers in modded
  content. This does not remove layout limits: continue testing wrapping,
  clipping, localisation expansion, and very long bound text.
- Battalion adjusters now scale with a sub-unit's equipment and manpower
  status. Rebalance custom adjusters with understrength as well as fully
  equipped units; older results can overstate their real effect.
- Current vanilla adds or changes `essential = { ... }` blocks on several HQ,
  staff, flame-tank, and support units. Full-file unit overrides must be
  re-merged so they do not discard the new readiness contract.
- Facility construction costs and infrastructure interaction changed. Never
  preserve copied 1.19.2 facility numbers as engine defaults.

## Verified current patterns

### Bindable and contextual localisation

1.15 introduced bound localisation objects and localisation formatters. In
1.19.3, a bindable consumer accepts a plain key, formatted localisation, or a
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

Current generated 1.19.3 documentation lists these operations:

```text
add and atan atan2 clamp cos divide equals every_collection
greater_than_or_equals if lerp less_than_or_equals log max min mod
multiply not not_equals or pow root round sin subtract tan xor
```

Math expressions use fixed-point arithmetic. Boolean operations return `1.0`
or `0.0`; any non-zero input is true. A parse failure becomes runtime `0.0`.
Approximate functions can have rounding error; follow with `round = yes` only
when an integer result is intended.

Patch 1.19.1 said `sqrt` and `exp` were added, but the installed 1.19.3
`script_math_functions.md` lists neither. Use the documented square-root form
`root = 2`, and do not emit `exp` or `sqrt` until a later installed build
documents or demonstrates those exact tokens.

### Quantified any-object checks and collections

Patch 1.16 announced `count` for all `any_*` object triggers, including scoped
variables. Current generated 1.19.3 trigger documentation explicitly shows the
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
sqrt / exp                        # announced, but absent from local 1.19.3 math docs
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
| 2026-06-17 | [1.19.1](https://store.steampowered.com/news/app/394360/view/1835871199300348) | `impassable_ignored_links`; announced additional math functions, subject to the current documentation caveat above. |
| 2026-06-30 | [1.19.2](https://store.steampowered.com/news/app/394360/view/1836506165562428) | Updated math docs; logical math operations, `lerp`, `atan`, `atan2`; advisor `always_show_on_actions_tooltip`; raid `unit_animations`. |
| 2026-09-17 | [1.19.3](https://steamcommunity.com/games/394360/announcements/detail/712286322480383531) | Admiral combat on_actions; combatant strategic-region trigger; `set_autonomy.keep_subjects`; core-state collection operators; Army HQ deployment trigger and variables; safer modded text buffers. |
| 2026-10-27 | [1.19.4 QoL](https://steamcommunity.com/ogg/394360/announcements/detail/684142629662760620) | Fuel-saving thresholds; equipment stat scaling; state-variable math and advisor tooltip fixes; border-war/major-list options with incomplete local schema; native GUI controls requiring override review. |
