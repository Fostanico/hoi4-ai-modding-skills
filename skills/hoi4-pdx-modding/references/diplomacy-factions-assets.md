# Diplomacy, factions, and assets

## Diplomacy enable triggers

Vanilla `common/scripted_triggers/diplomacy_scripted_triggers.txt` documents
`DIPLOMACY_<ACTION>_ENABLE_TRIGGER` with ROOT as initiator and FROM as target.
Prefer `if` plus `custom_trigger_tooltip` inside the enable trigger.

Military access is gateable. Current vanilla ships
`DIPLOMACY_MILACC_ENABLE_TRIGGER` and `DIPLOMACY_OFFER_MILACC_ENABLE_TRIGGER`.
A community claim that military access cannot be blocked is false in current
1.19.3 vanilla.

## Autonomy transitions

In 1.19.3, `set_autonomy` accepts `keep_subjects = yes`. Use it when the target
country must retain its existing subjects during the autonomy transition.
Current vanilla places the effect in the overlord country scope and supplies
the changed country through `target = <country>`. Verify the caller, target,
new autonomy state, freedom level, war-ending flags, subject ownership, and
save/reload together; do not assume subject preservation is the default.

`DIPLOMACY_WAR_ENABLE_TRIGGER` appears in the vanilla comment example but is not
a live shipped trigger. A mod may define it to add a war lock. Same-name
scripted triggers override, so do not copy a GER/SOV example into production.

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
- Faction member upgrades are a group plus numbered bonus objects. Keep
  `upgrade_type` on a code-supported token such as
  `faction_member_upgrade_manpower`. Current vanilla lives under
  `common/factions/member_upgrades/`.

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
