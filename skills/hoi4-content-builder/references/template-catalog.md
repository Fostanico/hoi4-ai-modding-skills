# Verified template catalog

Verified against installed Hearts of Iron IV Operation Postern 1.19.2.0 (d245)
on 2026-07-16 through 2026-07-17. Paths below are relative to the installed
game root.

| Resource | Intended use | Installed documentation | Current vanilla consumer |
| --- | --- | --- | --- |
| `country-event.txt` | Triggered country event | `documentation/effects_documentation.md` | `events/AAT_Generic_Events.txt` |
| `decision-category.txt` | Decision category | `common/decisions/_documentation.md` | `common/decisions/categories/AFG_decision_categories.txt` |
| `decision.txt` | Non-targeted instant decision | `common/decisions/_documentation.md` | `common/decisions/AFG.txt` |
| `national-focus-tree.txt` | One-focus country tree | effect/trigger docs plus consumer | `common/national_focus/afghanistan.txt` |
| `idea.txt` | Country national spirit | modifier docs plus consumer | `common/ideas/afghanistan.txt` |
| `character.txt` | Country leader character | `common/characters/_documentation.md` | `common/characters/AFG.txt` |
| `country-history.txt` | Start-date country setup | consumer; no adjacent schema | `history/countries/GER - Germany.txt` |
| `state-history.txt` | Start-date state setup | consumer; no adjacent schema | `history/states/64-Brandenburg.txt` |
| `scripted-effect.txt` | Reusable country effect | `documentation/effects_documentation.md` | `common/scripted_effects/00_scripted_effects.txt` |
| `scripted-trigger.txt` | Reusable country trigger | `documentation/triggers_documentation.md` | `common/scripted_triggers/00_diplo_action_valid_triggers.txt` |
| `on-action.txt` | Weekly hook | `common/on_actions/_documentation.md` | `common/on_actions/00_on_actions.txt` |
| `sprite.gfx` | One DDS sprite registration | consumer; no adjacent schema | `interface/goals.gfx` |
| `localisation_l_english.yml` | English player-facing localisation skeleton | current localisation consumers | `localisation/english/*.yml` |
| `localisation_l_simp_chinese.yml` | Simplified Chinese player-facing localisation skeleton | current localisation consumers | `localisation/simp_chinese/*.yml` |
| `localisation_l_russian.yml` | Russian player-facing localisation skeleton | current localisation consumers | `localisation/russian/*.yml` |
| `localisation_l_japanese.yml` | Japanese player-facing localisation skeleton | current localisation consumers | `localisation/japanese/*.yml` |
| `localisation-advanced/*` | Four-language colours, icons, formatted variables, scope functions, nested text, and bound-localisation examples | `documentation/loc_objects_documentation.md`, `documentation/dynamic_variables_documentation.md` | `interface/core.gfx`, current `localisation/*/*.yml`, current bound/context-aware GUI consumers |
| `collection-effect.txt` | Filtered collection iteration in a scripted effect | `common/collections/_documentation.md` | `common/factions/goals/faction_goals_short_term.txt` |
| `array-effects.txt` | Scope-array add, iterate, and cleanup effects | `documentation/effects_documentation.md` | `common/decisions/SWI.txt` |
| `event-target-caller.txt` | Save a state target and immediately fire an event | `documentation/effects_documentation.md` | `common/decisions/POL.txt`, `WTT_border_conflicts.txt` |
| `dynamic-modifier.txt` | Variable-backed country dynamic modifier | current dynamic-modifier header | `common/dynamic_modifiers/wuw_dynamic_modifiers.txt` |
| `scripted-localisation.txt` | Ordered conditional text with fallback | consumer; no generated schema | `common/scripted_localisation/00_scripted_localisation.txt` |
| `state-name-effect.txt` | State and province renaming effect | effect docs | `common/national_focus/china_communist_sea.txt` |
| `targeted-state-decision.txt` | Core-state-bounded targeted decision | `common/decisions/_documentation.md` | `common/decisions/AUS.txt` |
| `bookmark.txt` | Label-filtered bookmark with deterministic label order | current consumer comments | `common/bookmarks/the_gathering_storm.txt` |
| `model-animation.asset` | One animation registration | consumer; no adjacent schema | `gfx/models/animations_test.asset` |
| `model-entity.asset` | One mesh-backed entity registration | consumer; no adjacent schema | `gfx/models/buildings/bridge_railway.asset` |
| `descriptor.mod` | Portable launcher/mod metadata starting point | launcher format plus current mod descriptors | installed and local working descriptors |
| `country-tag.txt` | Tag-to-country-definition registration | current consumers | `common/country_tags/00_countries.txt` |
| `country-definition.txt` | Country color and graphical cultures | current consumers | `common/countries/Germany.txt` |
| `scientist-character.txt` | Character with a scientist role | `common/characters/_documentation.md` | `common/characters/CAN.txt` |
| `mio-organization.txt` | Country-gated MIO including a generic organization | MIO organization documentation | `common/military_industrial_organization/organizations/SLO_organization.txt` |
| `special-project.txt` | Project definition and country output | project/specialization/reward docs | `common/special_projects/projects/radar_projects.txt` |
| `raid-category.txt` | Raid UI/intelligence category | `common/raids/_documentation.md` | `common/raids/categories/raid_categories.txt` |
| `raid-type.txt` | Land raid lifecycle with four outcomes | `common/raids/_documentation.md` | `common/raids/land_infiltration_raids.txt` |
| `ai-strategy-plan.txt` | Enabled/aborted strategic AI desire | `common/ai_strategy/_documentation.md` | `common/ai_strategy/ARG.txt` |
| `ai-equipment-design.txt` | AI equipment role and target variant | `common/ai_equipment/_documentation.md` | `common/ai_equipment/SOV_planes.txt` |
| `ai-division-template.txt` | AI division role and target battalions | `common/ai_templates/_documentation.md` | `common/ai_templates/templates_INS.txt`, `generic.txt` |
| `oob-air-wing.txt` | Start-date air wing | current history consumers | `history/units/AFG_1939_air_legacy.txt` |
| `faction-rule.txt` | Faction member-rule trigger | `common/factions/_documentation.md` | `common/factions/rules/faction_set_goal_rules.txt` |
| `faction-template.txt` | Faction manifest, icon, goals, and rules | `common/factions/_documentation.md` | `common/factions/templates/government_of_national_defense.txt` |
| `faction-goal.txt` | Short-term faction goal lifecycle | `common/factions/_documentation.md` | `common/factions/goals/faction_goals_short_term.txt` |
| `unit-name-list.txt` | Country equipment/name pool skeleton | current consumers | `common/units/names/00_FRA_names.txt` |
| `kits/focus-event-idea` | Focus to event to idea chain | rows above | rows above |
| `kits/scripted-gui-modal` | Player-context modal with dirty refresh and close callback | `common/scripted_guis/_documentation.md` | vanilla scripted-GUI and sprite consumers |
| `kits/targeted-state-event` | Targeted decision to saved-state event chain | decision/effect docs | `common/decisions/AUS.txt`, `POL.txt`, current event consumers |
| `kits/frontend-background` | Selectable main-menu background and thumbnail registration | current database comments | `common/frontend/backgrounds/base_backgrounds.txt`, `interface/small_background.gfx` |
| `kits/music-track` | OGG track added to the base music station | consumer; no adjacent schema | `music/music.asset`, `music/_songs.txt` |
| `scripts/generate-gfx-manifest.ps1` | Deterministic sprite and optional focus-shine manifest | consumer; no adjacent schema | `interface/goals.gfx`, `interface/goals_shine.gfx` |
| `scripts/new-country-scaffold.ps1` | Staged country/tag/history/character/localisation generator | current consumers | `country_tags/00_countries.txt`, `countries/Germany.txt`, `history/countries/GER - Germany.txt` |

## Project engineering templates

These templates describe the mod being built rather than HOI4 database syntax:

| Resource | Intended use |
| --- | --- |
| `mod-technical-guide.md` | Durable architecture, identifiers, lifecycle, compatibility, and test contract |
| `development-handoff.md` | Current change state, evidence, risks, and concrete next actions |

## Boundaries

- These are structural skeletons, not globally correct gameplay defaults.
- Reuse an established project guide or handoff instead of creating duplicate
  documentation. The engineering templates are starting points only.
- The four localisation templates intentionally share the same keys. Copy each
  requested language into its matching `localisation/<language>/` directory,
  translate values only, and preserve scripted tokens, variables, icons, and
  color codes exactly. The skill instructions remain English; these files are
  player-facing output templates.
- Advanced localisation templates are demonstrations, not a single drop-in
  feature. Replace `MOD`, define `MOD_example_modifier`, and copy only entries
  whose real consumer provides the required country scope or bound parameters.
  A token being documented does not make every GUI textbox context-aware.
- `GER`, state `64`, state `999`, province `1`, and every `MOD`
  identifier are deliberate replacement markers.
- The state template is not a complete map-change kit. Follow the map/history
  workflow and verify every numeric ID.
- The on_action template uses the verified country-specific `on_weekly_TAG`
  form. Prefer an event-driven caller when the real design allows it, and never
  migrate a daily invariant merely because a weekly skeleton exists.
- Recheck this table after a HOI4 update. Current vanilla consumers are the
  practical authority when generated documentation and runtime behavior differ.
- The modal kit is statically verified but still requires an in-game click test
  after it is copied, renamed, and wired to a real caller.
- The targeted-state kit is statically verified but still needs an in-game
  target-selection and both-event-options test after identifiers are replaced.
- The country generator deliberately omits flags, state ownership, OOB, focus,
  ideas, and AI. Its output is a staging scaffold, not a playable country by
  itself.
- The bookmark template's tag, labels, idea, focus, localisation, date, and
  picture are placeholders. Include only filters the intended selection UI
  needs.
- The model templates register exported resources; they do not create a mesh,
  animation rig, material, entity consumer, or graphical-culture fallback.
- Descriptor path handling differs between the launcher-side `.mod` file and a
  Workshop `descriptor.mod`; discover the real target and do not copy a local
  absolute path into a distributed descriptor.
- MIO includes, scientist traits/specializations, project tags/rewards, raid
  targets/resources, AI roles/modules, OOB IDs, faction manifests/goals/rules,
  and unit categories are version-sensitive placeholders. Replace them only
  with tokens proven in the target build and dependencies.
- The frontend kit requires full and thumbnail DDS files named exactly after
  the database/GFX registrations. Current vanilla examples are 1920x1440 and
  192x144 respectively. The kit deliberately does not override
  `frontendmainview.gui`.
- The music kit requires `music/MOD_track.ogg`. It adds a track to
  `base_music`; a custom station needs additional GUI and station resources.
