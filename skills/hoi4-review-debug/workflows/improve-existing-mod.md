# Improve an existing mod end to end

Use this workflow when the user asks to improve, modernize, review, stabilize,
balance, optimize, or continue an existing mod without limiting the task to one
known defect.

## 1. Establish the baseline

1. Read repository guidance, the canonical technical guide and handoff, current
   localisation, descriptors, dependencies, supported build, playset, and
   `git status`. Preserve unrelated work.
2. Ask what "better" means only when it is not discoverable: stability,
   performance, balance, AI competence, clarity, narrative quality,
   compatibility, maintainability, or a ranked combination.
3. Run `scripts/audit-hoi4-mod.ps1` before editing. Also run the focused log,
   localisation, map, and override tools when their systems are present.
4. Record a fresh-log timestamp and distinguish current evidence from old
   baseline logs. Static evidence is not runtime proof.

## 2. Build two maps

Build a technical map:

```text
entry points -> definitions -> state -> consumers -> cleanup -> save/migration
```

Build a player-experience map from names, descriptions, tooltips, choices,
scripted localisation, GUI labels, and visible outcomes:

```text
player promise -> action -> cost -> feedback -> reward/failure -> repeat loop
```

Do not infer characters, narrative roles, currencies, dates, or intended
balance from internal identifiers. Record code/text/documentation conflicts.

## 3. Triage before proposing edits

Classify every finding:

- **Objective defect:** parser/scope/reference failure, broken lifecycle,
  overflow, missing cleanup, tooltip contradiction, inaccessible content,
  confirmed regression, or reproducible crash.
- **Engineering risk:** unproven compatibility, costly hot path, fragile state,
  missing migration, weak comments/docs, or incomplete test evidence.
- **Design choice:** pacing, reward magnitude, difficulty, historical or
  narrative direction, visual style, or player preference with no objective
  contract violation.

Rank by player impact, reproducibility, save blast radius, dependency risk, and
effort. Present one consolidated improvement backlog. Ask for approval before
changing design choices or broadening the requested gameplay direction.

## 4. Improve in reviewable batches

1. Fix load/parser blockers before downstream symptoms.
2. Repair the smallest complete dependency graph, not one isolated token.
3. Keep a batch focused on one contract: correctness, lifecycle/save,
   performance, compatibility, or approved gameplay/UX behavior.
4. Preserve stable IDs and state unless an idempotent migration is included.
5. Update affected localisation, AI, assets, and documented contracts in the
   same batch. Keep comments and handoff proportional to the actual change.
6. Reuse the baseline and rerun only checks the batch can affect. Repeat a full
   baseline only for a new cross-system concern or an explicitly requested
   audit, following the [shared evidence policy](../../hoi4-pdx-modding/references/workflow-boundaries.md).

## 5. Validate the player experience

Use `references/gameplay-balance-ux-review.md` for approved design work. Test
normal, boundary, exploit, AI, missing-DLC/dependency, save/reload, and old-save
paths proportionally. For GUI work include disabled reasons, stale data,
multiple resolutions, localisation expansion, close/reopen, and a full restart
after any hot refresh.

After static validation, apply the builder's `test-mod.md` willingness,
capability, authorization, and quota decision before controlling Steam or
launching HOI4. Follow that workflow's choice of an existing session, relevant
test save, or new game, with the target mod and exact dependencies, relevant
fresh logs, and normal restoration. Its time budget and user-stop rules also
apply; a new game at the earliest bookmark is not a universal requirement.

## 6. Prove improvement and hand off

Fill `assets/templates/mod-improvement-report.md` with:

- baseline and target build/playset;
- objective findings fixed and evidence;
- approved design changes and their intended player effect;
- before/after performance, graph, log, and runtime results where available;
- deferred choices, unverified branches, save/compatibility risks, and next
  actions;
- canonical technical-document and comment updates.

Do not describe an audit as a completed improvement, a clean log as correct
gameplay, or a subjective preference as an objective repair.
