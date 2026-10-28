# Development documentation and comments

Update documentation when architecture, entry points, state/lifecycle, save
compatibility, usage, or a documented test procedure changes. Keep affected
contracts accurate in the same change. A wording fix or known template
correction does not require a new guide, handoff file, or obvious comments;
follow the [shared workflow boundaries](workflow-boundaries.md).

## Discover the canonical files

Read repository guidance first. Reuse the project's established technical
guide, handoff, architecture notes, and changelog rather than creating parallel
documents. If substantial work introduces a durable contract and none exists,
create only the needed sections, using the builder templates as a starting
point. Add a persistent handoff when unfinished or complex work needs it; a
completion message or existing development log is sufficient for a small change.

Do not put reusable PDX language tutorials or copied vanilla documentation into
the mod's technical guide. Link to authoritative references and record only the
project-specific contract needed by the next maintainer.

## Technical documentation: durable truth

Update the relevant sections when their contract changes; this is a menu,
not a requirement to write every section for every edit:

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

For substantial or unfinished work, record the evidence needed to resume:

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

Keep code, visible localisation, and any affected documentation/comments in
agreement. Review the documentation diff when one is needed; do not create
documentation changes solely to satisfy a completion checklist. User stopping
and bounded handoff take precedence over completion work.
