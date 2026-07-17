# HOI4 content build workflows

## Event

1. Choose a unique namespace and event ID.
2. Decide event type and prove the caller's start scope and `FROM`.
3. Prefer `is_triggered_only = yes`; wire a focus, decision, on_action,
   scripted effect, or preceding event.
4. Add title, description, every option, and localisation.
5. Put shared post-option cleanup in event-level `after` only when it must run
   after every selected option; keep setup in `immediate`.
6. Guard delayed targets and bound recursion. Test every option, `after`, and
   timeout.

## Decision or mission

1. Create or reuse a category and decide whether it is targeted.
2. Put load-time eligibility in `allowed`; dynamic display in `visible`; action
   eligibility and cost in `available` and cost fields.
3. Narrow candidates with `target_root_trigger`, then evaluate each target with
   `target_trigger`. For state targets, set `state_target = yes` and use a
   narrow `target_array` when an appropriate state array exists. Current
   vanilla `common/decisions/AUS.txt` uses
   `target_array = ROOT.core_states`; older `state_trigger` tutorials are not
   the current template.
4. Define completion, timeout, removal, cancellation, cleanup, and AI behavior.
   If a war hook uses a scoped variable, prove it remains valid until the hook.
5. Wire icon/localisation and test the whole lifecycle plus save/reload.

## National focus

1. Choose tree and unique stable ID; map prerequisite, mutual-exclusion, and
   bypass graph before coding.
2. Place with coordinates or `relative_position_id` using a real anchor.
3. Add availability, cancel behavior, completion reward, AI weight, icon, and
   localisation.
4. Add `bypass_effect` only for the bypass branch; do not duplicate a reward
   that can then run through both paths.
5. Verify graph reachability and target existence. Test completion and every
   bypass branch.

## Character, idea, or MIO

- Character: define a stable ID, roles, availability, portrait, localisation,
  recruitment, retirement, and role changes using current vanilla examples.
- Idea: define category, picture, modifiers, restriction, and every
  add/remove/swap/expiry path.
- MIO: require `allowed`; define categories and initial trait; build the trait
  graph with verified parents, exclusions, positions, and bonuses.
- MIO include/policy: reload both files when an include crosses files; preserve
  the distinct trait-versus-policy bonus nesting; add every evaluated bonus to
  archetype-specific or default AI bonus weights.

## Doctrine, raid, or special project

- Doctrine: build folder, grand doctrine, track, subdoctrine/rewards, mastery,
  GFX, localisation, and activation effects as one graph. Use embedded
  equipment bonuses rather than an effect that would survive doctrine changes.
- Raid: define category, target/start points, preparation and equipment gates,
  success formulas, four outcomes, runtime scopes, UI resources, AI, and
  cooldown. Keep global/target visibility cheap.
- Special project: define matching specialization and facility building,
  project, generic/unique prototype rewards, scientist role/traits, GFX,
  localisation, AI, and DLC gates. Put mandatory completion behavior in
  country effects because script completion can lack a facility or scientist.

## AI strategy, design, or template

1. Decide whether behavior belongs in strategic desire, equipment design, or
   division template selection.
2. Use current vanilla documented tokens and real categories/roles.
3. Set country/DLC eligibility and explicit enable/abort lifecycle.
4. Avoid copied Millennium Dawn coverage tables or equipment taxonomies.
5. Observe the AI in-game; use AI ImGui panels where available.

## OOB, variant, or name list

1. Prove every sub-unit, archetype, technology, module, and DLC path.
2. Create variants before OOB consumers; match type, creator, name, and parent
   version exactly.
3. Separate stockpiles from deployed formations, wings, and ships.
4. For name lists, copy only current vanilla structure and localise consumers.
5. Load the exact scenario and inspect spawned content.

## Diplomatic action or faction

- Diplomatic action: trace sender/recipient scopes through visibility,
  availability, cost, acceptance, AI desire, cooldown, and effects.
- Faction: use current vanilla faction-rule fields; wire rules, goals, and
  templates separately; test membership, wars, leadership, peace, and goals.
- Peace conference: use the documented negotiator/taker/giver/state scope chain
  and `pc_*` triggers for state changed inside the active conference.

## Scripted GUI and localisation

Build the chain in order:

```text
texture -> sprite -> GUI element -> scripted GUI trigger/effect -> localisation
```

Match context and element names exactly. Keep visibility and dynamic text cheap.
Test reopening, changing scope, empty/populated lists, hit boxes, tooltips, and
every callback.

Use a meaningful scripted-GUI `dirty` variable unless every-tick reevaluation
is intentional. For scripted map modes, restrict render targets and prefer an
event-driven `force_update_map_mode` over daily rebuilding where semantics
permit it.

For a focus inlay, build `common/focus_inlay_windows`, the GUI container, and
the focus-tree `inlay_window` placement as one chain. Use bound or
context-aware text only when the current inlay context supports it; an inlay is
not automatically a scripted-GUI window. Wire scripted image, button, and
progressbar names to real GUI subcomponents.

## Entity, landmark, music, or sound

- Entity/landmark: start from the nearest current vanilla class; verify mesh,
  animation, entity, graphical-culture fallback, and map consumer.
- Music: provide the asset and playlist selection with conditions and weight.
- Sound: define the sound effect and consumer; verify format, category,
  falloff, looping, and volume from a current vanilla example.

Never copy another mod's coordinate formula, media specification, or asset
taxonomy without reproducing it in the target project.
