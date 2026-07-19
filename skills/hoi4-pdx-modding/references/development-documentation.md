# Development documentation and comments

Technical documentation, development handoff, and readable code comments are
required deliverables whenever an agent creates, extends, repairs, refactors,
or migrates a mod. Update them with the code, not as optional release cleanup.

## Discover the canonical files

Read repository guidance first. Reuse the project's established technical
guide, handoff, architecture notes, and changelog rather than creating parallel
documents. If none exist, create a stable technical guide and a current
development handoff from the builder templates. A small project may keep both
as clearly separated sections in one file.

Do not put reusable PDX language tutorials or copied vanilla documentation into
the mod's technical guide. Link to authoritative references and record only the
project-specific contract needed by the next maintainer.

## Technical documentation: durable truth

Keep these sections current for every affected system:

- player-facing purpose and acceptance behavior;
- supported game build, DLCs, dependencies, load order, and overrides;
- architecture, entry points, owned files, and cross-file call graph;
- stable IDs, flags, variables, arrays, event targets, localisation keys, GUI
  elements, sprites, and their owners/consumers;
- scope contracts, units, lifecycle, cadence, cleanup, and performance budget;
- save compatibility, migrations, dependency adapters, and known engine
  workarounds;
- focused validation and reproduction procedure.

Update or remove stale statements when behavior changes. Documentation that
describes an old implementation is a defect, not harmless history.

## Development handoff: current change state

Record enough evidence for a different developer or AI to resume safely:

- goal, status, affected systems, and changed files;
- design decisions, rejected alternatives when material, and assumptions;
- identifiers or contracts added, changed, preserved, or deprecated;
- commands/checks run and their results;
- exact in-game scenarios tested, game build/playset, and fresh-log status;
- unverified behavior, remaining risks, blockers, and concrete next actions.

Do not claim runtime success from static validation. Keep the handoff concise
and replace obsolete current-state notes instead of accumulating contradictions.

## Code-comment contract

Comments must let a maintainer understand the local contract without reverse
engineering the entire call graph. Add them where applicable for:

- file or subsystem responsibility and real entry point;
- scripted effect/trigger caller scope, parameters, outputs, and side effects;
- persistent state owner, unit, initialization, mutation, cleanup, and save
  lifetime;
- unusual cadence, hot-path constraints, caches, and invalidation rules;
- compatibility gates, migration flags, and exact dependency assumptions;
- engine limitations, counterintuitive syntax, and verified workarounds;
- non-obvious GUI refresh, event-order, or scope-transition behavior.

Prefer short comments immediately above the contract they explain. Use clear
terms rather than unexplained abbreviations. Do not comment obvious assignments,
leave large blocks of disabled code, or preserve a comment after its claim is
no longer true. Re-read comments during review just as code and localisation
are re-read.

## Completion gate

A change is not complete until code, visible localisation, technical
documentation, handoff, and comments agree. Review the documentation diff and
comment accuracy before reporting completion or preparing a release.
