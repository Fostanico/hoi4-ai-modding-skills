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
5. Add/update localisation, AI, assets, comments, technical documentation, and
   handoff content in the same batch.
6. Rerun the exact baseline checks after every batch and compare before/after.

## 5. Validate the player experience

Use `references/gameplay-balance-ux-review.md` for approved design work. Test
normal, boundary, exploit, AI, missing-DLC/dependency, save/reload, and old-save
paths proportionally. For GUI work include disabled reasons, stale data,
multiple resolutions, localisation expansion, close/reopen, and a full restart
after any hot refresh.

After static validation, separately ask for consent before controlling Steam or
launching HOI4. Follow the builder's `test-mod.md`; use only the target mod and
exact dependencies, `-debug`, a new game at the earliest bookmark, fresh logs,
and restoration of changed launcher settings.

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
