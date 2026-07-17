# Diplomacy, factions, and assets

## Scripted diplomatic actions

- Start from a current vanilla action with the same scope direction and UI
  behavior.
- Trace sender, recipient, acceptance, visibility, availability, AI desire,
  cost, cooldown, and effect scopes independently.
- Verify every token against current vanilla. Do not import Millennium Dawn
  diplomatic triggers, opinion modifiers, or economic checks.
- Test both directions, AI and player use, rejected/accepted paths, target
  disappearance, and save/reload.

## Factions

Current vanilla faction schemas are documented in
`common/factions/_documentation.md`. Use its exact singular token names,
including `joining_rule`, `war_declaration_rule`, `call_to_war_rule`,
`member_rules`, `change_leader_rules`, and `peace_conference_rules` where the
chosen object supports them.

- Separate faction rules, goals, and templates.
- `create_faction` is marked obsolete in current vanilla documentation. Use
  `create_faction_from_template` unless maintaining a proven legacy path.
- An empty faction-goal `completed` block means the goal never completes. An
  empty faction-template `visible` block means it does not appear for normal
  player selection, allowing script-only templates.
- Verify goal availability, completion, cancellation, membership changes, and
  leader changes.
- Do not copy Millennium Dawn rule IDs, UN integration, custom ideology
  restrictions, or modern diplomatic systems.

## Peace-conference scripting

- Scripted AI desires are additive; a final desire at or below zero prevents
  the AI from taking the action. Scripted cost modifiers multiply together and
  must remain above zero.
- The documented scope chain is negotiator `ROOT`, taker `FROM`, giver
  `FROM.FROM`, and action state `FROM.FROM.FROM` when the action has a state.
- Ownership, diplomatic relations, and other ordinary game state may not update
  until before or after the conference. Use `pc_*` triggers to inspect actions
  already taken during the current conference.
- Faction peace-conference rules can attach cost modifiers, but the modifier's
  normal `enable` trigger is not run; membership in the active rule controls it.

## Entities and landmarks

Trace each asset chain rather than guessing names:

```text
mesh/animation -> entity definition -> graphical culture or tag lookup
-> map or GUI consumer
```

- Search current vanilla for the same asset class and copy only its structure.
- Confirm paths, entity and animation names, graphical-culture fallback,
  state/province placement, and DLC ownership.
- Treat map dimensions, coordinate transforms, and height formulas from
  another mod as project-specific unless reproduced against the current map.

## Music and sound

Music needs both an audio asset definition and playlist/music entry that
selects it. Validate `.ogg` paths, names, conditions, weights, and fallback
behavior against current vanilla music files.

Sound effects need a real `sound`/`soundeffect` definition and a consumer.
Validate category, falloff, loop behavior, volume, and source-file format
against a working current vanilla example. Do not preserve unverified sample
rate or bit-depth prescriptions copied from another repository.

For both systems, use unique prefixed IDs, keep paths case-correct, search for
every consumer, inspect `error.log`, and test playback in the intended context.
