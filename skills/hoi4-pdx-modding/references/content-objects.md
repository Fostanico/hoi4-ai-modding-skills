# HOI4 content objects

## Contents

- Events and on_actions
- Decisions
- National focuses
- Ideas and dynamic modifiers
- Military industrial organizations

## Events and on_actions

- Add and use a unique namespace consistently.
- Prefer `is_triggered_only = yes` and fire the event from a focus, decision,
  on_action, scripted effect, or another event. Avoid global mean-time polling
  unless the design truly requires it.
- Confirm the receiving scope and `FROM` at every call site, including delayed
  events. Guard a target that may cease to exist before a delayed event fires.
- Give title, description, and every visible option matching localisation.
- Ensure an option does not recursively fire its own event without an explicit
  bounded design.
- Use country-, state-, or tag-specific on_action hooks when available instead
  of adding a global daily scan.
- Use event-level `after = { ... }` for shared work that must run after the
  selected option. Keep pre-option setup in `immediate`, and test every option
  because moving option-specific work into `after` changes lifecycle semantics.

Minimal pattern:

```pdx
add_namespace = mod_example

country_event = {
	id = mod_example.1
	title = mod_example.1.t
	desc = mod_example.1.d
	is_triggered_only = yes

	option = {
		name = mod_example.1.a
		add_political_power = 25
	}
}
```

## Decisions

- Separate category visibility from decision visibility and availability.
- For targeted decisions, trace `ROOT`, `FROM`, `THIS`, and target arrays from
  an existing current-game example. Use the narrowest applicable target array.
- Keep expensive or global checks out of frequently evaluated `visible` blocks;
  cache eligibility through on_actions when appropriate.
- Pair missions and timed decisions with correct timeout, removal, and cleanup
  effects.
- `war_with_on_remove`, `war_with_on_timeout`, and `war_with_on_complete` can
  accept scoped variables in current 1.19. Ensure the variable still resolves
  to a live country at every lifecycle boundary.
- Verify category IDs, decision IDs, icons, localisation, state highlighting,
  and activation cost tokens across files.
- At the root of `ai_will_do`, use syntax demonstrated in current vanilla. Do
  not transplant a repository-specific AI convention without verification.
- `allowed` is evaluated when the game starts or a save loads; it is not a
  dynamic visibility check. Use it to discard impossible country instances,
  especially for targeted decisions. `visible` and `available` run when the
  decision UI refreshes and can be evaluated every frame.
- For targeted decisions, use `target_root_trigger` as a narrow root prefilter
  and `target_trigger` for each target. Both are cached daily: the former once
  for the acting country, the latter for every candidate target. Keep the final
  `visible`/`available` correct because the daily prefilters can be stale within
  the current day.
- Current targeted state decisions use `state_target = yes`. Prefer a narrow
  engine-maintained or explicitly maintained `target_array` over a world scan;
  current vanilla `common/decisions/AUS.txt` uses
  `target_array = ROOT.core_states`. Treat older `state_trigger =
  any_owned_state` examples as migration evidence, not current template code.

## National focuses

- Use unique stable IDs and `relative_position_id` when layout depends on
  another focus.
- Avoid empty `available` or `mutually_exclusive` blocks.
- Ensure prerequisite and mutually-exclusive graphs are reachable and do not
  create cycles.
- A permanently unavailable focus plus an unreachable bypass is a hard lock.
- Use `bypass_effect` only for effects that must run when the focus is manually
  or automatically bypassed. It is a separate branch from
  `completion_reward`; test both and avoid accidental double application.
- Check that completion rewards act on intended scopes and that foreign targets
  still exist.
- Verify icon, localisation, coordinates, search filters if used, AI weights,
  and every referenced event/idea/decision.

## Ideas and dynamic modifiers

- Define the correct category and use a real sprite token; a missing picture
  commonly produces a blank icon rather than an obvious parser failure.
- Use `original_tag` in a nation-restricted `allowed` block when civil-war tags
  should retain access.
- Verify add, remove, swap, cancel, and timed-expiry paths. A `swap_ideas` where
  old and new are identical is normally a copy/paste error.
- For variable-backed dynamic modifiers, initialize backing variables before
  the modifier is displayed and refresh only when values change.
- Tooltips must distinguish adding a modifier from changing an existing one;
  use project-defined localisation keys rather than assuming another mod's
  tooltip framework exists.

## Military industrial organizations

- Verify the MIO schema against current vanilla files and the enabled DLC.
- Use unique organization and trait tokens. Restrict country-specific MIOs with
  the scope pattern proven in current vanilla, normally `original_tag`.
- Validate every parent, `any_parent`, mutual exclusion, relative position,
  icon, equipment type/category, research category, and modifier key.
- `relative_position_id` accepts one positioning anchor; model multi-parent
  unlocks in the parent block rather than writing multiple anchors.
- Keep `organization_modifier` and equipment bonuses inside the intended trait
  block. Detect duplicate keys inside a bonus block; later tokens may stop
  parsing even when braces balance.
- Do not mix archetype IDs from different dependency versions to simulate
  compatibility. Branch by actual loaded version or target one supported
  version explicitly.
- Current vanilla requires an `allowed` block on an organization. Verify
  equipment and research categories, initial trait, parent/`any_parent`/
  `all_parents`, mutual exclusion, position, visibility, availability, and the
  placement of equipment, production, and organization bonuses.
- MIO `include` does not require the included file to load first, but hot reload
  across two files requires reloading/saving both definitions. Use
  `delete_included_values`, `add_trait`, `remove_trait`, and `override_trait`
  exactly as the current MIO documentation demonstrates.
- A MIO policy's `equipment_bonus` and `production_bonus` wrap stats under an
  equipment group/category/type (or `same_as_mio`); trait bonus blocks use a
  different nesting. Do not copy one schema into the other.
- Every MIO bonus that AI can evaluate needs an archetype-specific or `default`
  entry in `common/military_industrial_organization/ai_bonus_weights` or the
  game logs an error.

## Grand doctrines and subdoctrines

- A subdoctrine can list multiple `track` tokens. Set
  `allow_in_multiple_tracks = yes` only when simultaneous assignment is
  intended.
- Cross-track exclusion uses `xor = { other_subdoctrine ... }`; it does not
  prohibit replacement on the same track.
- Grand doctrines can cap layout with `max_track_rows` and
  `max_track_columns`; tracks can gate selection and mastery with `active`.
- Validate folder, grand doctrine, track, subdoctrine, mastery, GFX, and
  localisation as one dependency chain.

## Raids and unit modifiers

- Current raid types can define staged `unit_animations`, an
  `ai_min_success_chance` ratio from `0.0` to `1.0`, and a `max_distance` path
  cap. Copy the full nesting from `common/raids/_documentation.md`.
- `captured_army_leader` is a current raid target type, but requires the
  correct leader lifecycle and scope.
- Do not use removed `add_temporary_buff_to_units`. Use the current
  `unit_modifiers` schema belonging to the relevant medal, ability, or HQ
  object, rather than transplanting one object's nesting into another.
- Keep raid `visible` and `show_target` cheap. `essential_equipment` gates raid
  creation while additional equipment is collected after creation; when the
  same item appears in both, the engine takes the maximum rather than adding
  the amounts.
- Actor and victim outcome effect blocks both begin in raid-instance scope.
  Access runtime objects through the documented variables
  `actor_country`, `victim_country`, `target_state`, and `target_province`.

## Special projects and scientists

- Prefer `common/special_projects/projects/documentation.md`,
  `prototype_rewards/documentation.md`, and
  `specialization/documentation.md`. The root
  `special_projects_documentation.md` contains early design comments and
  syntax explicitly marked TBD or “for reference”.
- Project `allowed` is evaluated at startup in country scope and should contain
  only the documented tag/original-tag/DLC gates. Runtime `visible` and
  `available` use project scope with `FROM = country`.
- A project needs at least one non-zero `prototype_time`. A zero `complexity`
  logs an error and falls back to the defined default.
- Put mandatory completion work in `country_effects`. If a project is completed
  by script without a facility or scientist, `facility_state_effects` or
  `scientist_effects` is skipped.
- Match every project specialization to a facility building whose
  `specialization` field uses the same token. Validate project, reward,
  scientist trait, building, GFX, localisation, and DLC gates together.
