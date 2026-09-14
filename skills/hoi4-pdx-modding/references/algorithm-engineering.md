# PDX algorithm engineering

Use this reference when a feature needs more than ordinary event/decision
wiring: simulations, minigames, large stateful systems, procedural GUI,
incremental analysis, schedulers, interpreters, or other hot-path logic. These
patterns are engineering choices, not proof that every token is accepted by
every consumer. Verify syntax and scope against the installed game and test the
actual lifecycle.

## Choose the smallest computational model

Start with the least powerful model that preserves the requested behavior:

1. A direct trigger/effect for a one-step result.
2. A finite state machine for phases, modes, and mutually exclusive states.
3. An event-driven cache for expensive derived state.
4. A bounded queue or incremental scan when work must be spread over time.
5. A data table or generated lookup when the domain is finite and stable.
6. A compact interpreter only when the content genuinely needs user-authored or
   data-driven programs.

A general virtual machine is a technical last resort. The DOOM-in-HOI4 project
demonstrates that arrays, dynamic indices, arithmetic, loops, scripted effects,
scripted GUI properties, and shaders can emulate a compiled program. It does
not make that architecture appropriate for normal mod systems. Prefer a
domain-specific state machine that represents only the states the feature can
actually reach.

## Model state, ownership, and transitions explicitly

Treat every non-trivial feature as a deterministic state machine:

```text
entry -> initialize -> idle/running -> completed/faulted -> cleanup or restart
```

- Give every persistent flag, variable, array, event target, cache, and dirty
  counter one owning scope and one documented lifetime.
- Separate lifecycle states that have different legal operations. Do not use
  one boolean to mean initialized, open, running, valid, and visible.
- Gate transitions on the current state and make restart/cleanup idempotent.
- For a global singleton, store both the owner and the execution host, validate
  them before every delayed call, and define what happens when either country
  disappears, changes control type, or leaves the game.
- Commit multi-field state only after all calculations succeed. Calculate into
  temporary variables or a staging array, validate invariants, then publish the
  new state and increment the GUI dirty counter. This prevents consumers from
  observing a half-updated state.
- Distinguish normal completion from faults. Preserve a stable numeric error or
  completion code that localisation and debug UI can interpret.

## Use deterministic logical time

Do not derive gameplay results from wall-clock time, rendering FPS, or how
quickly a player clicks. Advance a simulation by an explicit logical step:

```text
scheduled caller -> validate owner/state -> consume pending input -> step once
                 -> publish results -> mark dirty if output changed
```

- Store a tick counter and derive time from it when possible.
- For fractional units, use a quotient plus remainder accumulator instead of
  repeatedly adding a rounded decimal. This avoids long-run drift.
- Make cadence part of the content contract: hourly, daily, weekly, on-action,
  GUI click, or manual step are different semantics.
- Preserve deliberate cadence during optimization. Replacing a daily mechanic
  with a weekly batch changes gameplay unless the result is proven equivalent.
- Provide a manual step or debug effect for complex deterministic systems so a
  single transition can be inspected without waiting for game time.

## Make work incremental and bounded

Large scans and simulations should yield between calls rather than monopolize
one effect execution.

- Represent continuation state explicitly: current phase, array index, work
  budget, pending queue, and completion status.
- Process a fixed number of items per invocation. Persist the next index and
  resume from it later.
- Bound every `while_loop_effect` by both a semantic termination condition and
  an explicit iteration budget. Engine safety caps are fault containment, not
  an algorithm.
- For a queue, keep logical head/tail indices and a documented maximum size.
  Reject, coalesce, or overwrite input deliberately when full; never silently
  lose actions.
- Release or shrink temporary work arrays at lifecycle cleanup when the engine
  and save-compatibility contract permit it. Hiding a GUI does not free its
  persistent backing variables.
- If ordering is irrelevant, batch equivalent mutations. If ordering affects
  scopes, randomness, triggers, or visible messages, preserve it explicitly.

Incremental execution is especially useful for map-wide analysis, AI scoring,
path-like searches, procedural content, and large migrations. Ordinary small
decisions should remain direct and readable.

## Design data for the operations performed

PDX arrays are useful but not free. Choose layout from the hot operations:

- Prefer engine-maintained collections or narrow arrays over repeated global
  scans.
- Use a dense array when the key range is compact and lookup dominates.
- Use parallel arrays only when the ownership and shared index invariant are
  documented and validated together.
- Use numeric IDs for stable internal states, then map them to localisation at
  the presentation boundary. Do not shuttle dynamic strings through hot logic.
- Pack several tiny bounded fields into one integer only when it materially
  reduces crossings or storage and the base/range contract is documented.
  Provide named encode/decode scripted effects and boundary tests; do not leave
  unexplained arithmetic at every caller.
- Precompute lookup tables for finite expensive functions when table size,
  initialization cost, save impact, and approximation error beat repeated
  calculation. Prefer installed math functions for ordinary arithmetic.
- Record whether an index is a slot, state ID, province ID, database token, or
  scope handle. Never reuse one numeric domain as another by accident.

Binary payloads are a poor fit for PDX text. Packing three bytes into one
24-bit value proves arbitrary data can be represented, but textual expansion,
parser cost, array overhead, and save impact usually overwhelm the benefit.
Keep media and large immutable datasets in engine-native assets whenever a
consumer exists.

## Narrow the boundary between subsystems

Treat scripted effects, GUI, localisation, and any generated core as separate
components with a small interface:

- Export a few stable scripted effects for initialize, step, query, restart,
  and cleanup instead of exposing internal variables to every caller.
- Cross the boundary with bounded integers, booleans, scope references, or
  small arrays. Return message IDs and status codes; let localisation create
  player-facing text.
- Validate every argument before narrowing or indexing. Reject invalid values
  without partially mutating state.
- Prevent re-entrant execution with a busy state when callbacks can indirectly
  invoke the same subsystem.
- Batch hot operations into coarse scripted-effect kernels. An entire row,
  column, candidate batch, or memory range should be processed per call when
  doing so preserves semantics; avoid layers of one-effect-per-scalar calls.
- Keep compatibility adapters outside the standalone core. Translate exact
  dependency IDs at the boundary instead of contaminating the algorithm with
  multiple total-conversion assumptions.

In generated systems, namespace file names as well as identifiers. Generic
paths such as `initialize.txt`, `data_0.txt`, or `component_0.txt` can collide
with another mod even when every effect inside has a prefix. Put generated
outputs under a clearly owned, namespaced file family. Do not fragment ordinary
content into hundreds of tiny files; split generated output only for a real
parser, generator ownership, review, or file-size boundary.

## Make presentation reactive

Presentation should consume published state, not drive core correctness.

- Use a dirty counter that changes only when displayed output changes. A
  scripted GUI without `dirty` is evaluated every tick by default.
- Separate `initialized`, `running`, `open`, and `display_visible`; closing a
  panel should not accidentally advance, destroy, or duplicate the simulation.
- Map compact internal values to frames, colours, sprites, and localised strings
  at the GUI boundary.
- Indexed-colour rendering can represent small procedural displays efficiently:
  store one palette index per logical cell and use a small palette texture plus
  a shader or multi-frame sprite. Suitable uses include low-resolution radar,
  LEDs, terminal displays, heat maps, and status overlays.
- Budget the number of GUI elements and property bindings. A tiny palette uses
  little texture memory, but thousands of `iconType` elements can move the cost
  to CPU, GUI evaluation, draw submission, and save-backed state.
- Use native animated textures for ordinary art animation. Do not replace a
  smooth animated DDS background with thousands of scripted pixels unless the
  content specifically requires procedural per-cell output.

## Offer graceful performance tiers

For expensive optional systems, separate costs so players and developers can
identify the bottleneck:

- full simulation plus presentation;
- simulation with reduced or disabled rendering;
- static presentation or reduced update cadence;
- fully disabled, with cleanup where safe.

Mode switches must have explicit semantics. Disabling rendering should not
silently disable gameplay unless that is the named mode. Re-enabling a consumer
must publish a complete current snapshot rather than relying on missed dirty
events.

## Generate offline, execute narrowly

Offline generation is valuable for repetitive, deterministic definitions:

- Build lookup tables, GUI grids, repetitive handlers, or state-transition
  tables with an ignored/private one-off helper or a documented shared tool.
- Keep the generator, input, version, and invariants auditable. Generated files
  should identify their owner and regeneration route without embedding private
  absolute paths.
- Prefer partial evaluation: resolve immutable constants and finite mappings at
  build time so HOI4 performs only state-dependent work.
- Review generated output for namespace, file size, encoding, parser limits,
  deterministic ordering, and collisions.
- Do not ship build intermediates, source media, JSON manifests, or personal
  helpers unless runtime or team regeneration genuinely requires them.

Generated PDX is still executed by the Clausewitz script interpreter. Calling a
generated scripted effect a `native` or `host` function does not make it
machine code; only its granularity and algorithm can reduce interpreter work.

## Prove the optimization

Before replacing an existing algorithm, write its observable contract: outputs,
ordering, randomness, cadence, tooltips, AI behavior, and cleanup. Then verify:

1. **Equivalence:** compare old and new results at boundary, empty, singleton,
   duplicate, missing-scope, and maximum-size cases.
2. **Cost:** estimate `frequency x scopes x iterations x expensive operations`.
   Shorter text is not evidence of faster execution.
3. **Bounds:** prove queue capacity, array indices, loop progress, division
   guards, and numeric packing ranges.
4. **Lifecycle:** test initialize, open, run, stop, close, restart, completion,
   fault, tag/control changes, and owner disappearance where relevant.
5. **Persistence:** compare new save and representative old-save behavior;
   inspect save size when large persistent arrays or generated state are used.
6. **Presentation:** verify dirty refresh, reopen, mode switching, localisation,
   resolution, hitboxes, and input combinations.
7. **Runtime:** static validation cannot prove cadence, GUI cost, memory use, or
   multiplayer ownership. Measure the smallest relevant in-game scenario and
   compare it with a baseline.

Preserve the simpler implementation when the optimized form has no measurable
benefit or substantially increases compatibility, save, or maintenance risk.

## Patterns that are demonstrations, not defaults

The following are technically possible but require explicit justification and
runtime measurements:

- emulating a general CPU or Wasm machine in scripted effects;
- allocating millions of persistent array entries;
- encoding WAD, ROM, image, audio, or other binary payloads as text integers;
- creating thousands of GUI pixel elements or hidden shortcut buttons;
- using an AI country and scripted-GUI AI callbacks as a global high-frequency
  clock;
- expanding generated code into hundreds of separately loaded files.

For normal HOI4 content, a bounded state machine, event-driven cache, compact
lookup table, and native asset consumer will usually deliver the same player
value with far lower parser, CPU, memory, save, compatibility, and maintenance
cost.
