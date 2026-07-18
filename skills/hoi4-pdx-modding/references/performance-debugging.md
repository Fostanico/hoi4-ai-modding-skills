# Performance and debugging

## Contents

- Hot-path rules
- Log triage
- Minimal runtime tests
- Common silent failures

## Hot-path rules

- Read the affected localisation and build a code-to-visible-behavior map
  before changing cadence, caching, failure handling, or manual/automatic
  boundaries. Identifier names do not establish feature intent.
- Prefer event-driven updates and narrow on_actions.
- Batch low-urgency state changes weekly or monthly when gameplay semantics
  permit it.
- Replace `every_country`/`every_state` scans with engine-maintained arrays or
  cached eligible-scope arrays. Consider current collections when their input
  and operator chain represent the same set without manual mutation.
- Hoist scope lookups, scripted trigger calls, and invariant arithmetic out of
  loops.
- Compute a complex boolean once into a temp variable inside a hot loop when it
  is reused multiple times.
- Avoid forcing dynamic modifier refreshes when backing values did not change.
- Avoid per-tick GUI redraws. Dirty counters should change only on relevant
  state changes.
- Optimize after identifying frequency and scope count. Shorter syntax is not
  automatically faster.
- Current documentation states math expressions are expected to outperform
  equivalent temporary-variable calculation chains. Use them only when the
  installed function list supports the operation and the fixed-point/rounding
  behavior is acceptable.
- A documented quantified check such as
  `any_collection_element = { count = N ... }` can replace a manual counter
  loop. For other `any_*` triggers, verify the exact current consumer before
  relying on the 1.16 announcement. Confirm that duplicate objects or a global
  candidate set do not change semantics or erase the performance benefit.
- Treat decision evaluation frequency as part of the schema: `allowed` at
  startup/load, target prefilters daily, and `visible`/`available` on UI
  refresh. Move acting-country and candidate-target filters into their
  documented lower-frequency blocks without weakening the final UI condition.
- For current targeted state decisions, use `state_target = yes` and a
  precomputed `target_array` when the candidate set is naturally available as
  a state array. Current vanilla `common/decisions/AUS.txt` uses
  `target_array = ROOT.core_states`; do not revive older tutorial-only
  `state_trigger = any_owned_state` examples without a current consumer.
- Remember that `collection_size` comparisons are inclusive in the current
  generated trigger documentation; a performance rewrite that keeps the text
  `> N` can still be off by one if the old counter used strict arithmetic.

## Log triage

Use the newest `Documents/Paradox Interactive/Hearts of Iron IV/logs/error.log`
from a run with the intended playset. Group findings in this order:

1. Parser and unexpected-token errors.
2. Invalid scopes, triggers, effects, and math expressions.
3. Invalid ideology, database object, or scripted object IDs.
4. Equipment archetype, MIO category/modifier, and technology references.
5. Duplicate localisation keys and broken GUI/GFX wiring.
6. Missing optional textures, audio, or cosmetic resources.

Fix the earliest parser error in a file first and rerun. Later errors may be
cascades caused by one malformed block.

For update regressions, also search the official migration gates:
`on_ruling_party_change_immediate`, `add_temporary_buff_to_units`, `cl_tech`,
and patch-note-only math names that are absent from installed documentation.

Confirm the active playset through `dlc_load.json` when dependency versions can
change identifiers or override files. A descriptor dependency list describes
relationships and ordering; it does not prove which mods were loaded in the
last run.

Useful commands confirmed by the installed console documentation include
`help`, `helplog`, `eval_trigger`, `eval_effect`, `effect`, `debug_tooltip`,
`debug_show_event_ID`, `debug_events`, `debug_dumpevents`, the `loc_check*`
family, `imgui`, and `aiview`. `ai_trace` and `ai_dump` are marked unavailable
in release builds, so do not make them mandatory steps for retail testing.

## Minimal runtime tests

Choose the smallest test that exercises the changed path:

- Event: fire its real caller or console-trigger the event and test each option.
- Decision: test visibility, availability, cost, completion, timeout, removal,
  target selection, and AI conditions.
- Focus: test prerequisites, bypass, mutual exclusion, completion reward, and
  target-existence edge cases.
- GUI: open, close, reopen, switch tabs/lists, click all affected controls, and
  inspect dynamic values and hit boxes.
- MIO/equipment: verify organization availability, tree layout, every parent,
  trait acquisition, and production-line equipment filters.
- Timed/weekly mechanics: test boundary values, expiry, save/reload, old-save
  initialization, and the end-of-cycle refresh.

## Common silent failures

- Wrong identifier case.
- A variable read before initialization defaults to an unintended value.
- `scope_exists` is used on a variable scope as a validity guard; variable
  scopes always pass it even when their stored object is not the live target
  the effect expects.
- A stale reference remains outside the edited directory.
- A GUI name mismatch renders the control but disconnects the callback.
- A malformed math expression evaluates to zero.
- A collection expansion duplicates objects and inflates a count.
- A bindable localisation object is passed to a consumer that accepts only a
  plain localisation key, or a context-aware field has no source context.
- A country target dies before a delayed effect.
- A dynamic array index means a database ID at the caller but a slot position at
  the callee.
- A same-key localisation collision selects a different definition by load
  order.
- A valid token belongs to another game or mod version.
- A modifier is recognized by the engine but ignored by the selected consumer.
- A shipped Markdown document contains design-stage TODO/TBD syntax rather than
  the implemented schema.
