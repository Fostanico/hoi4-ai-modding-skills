# Shared workflow boundaries

Use this contract across all three skills. Task-specific workflows supply the
technical steps; they do not extend the user's scope, testing budget, or stop
instruction. Apply repository guidance and the latest user direction first.

## Choose the cheapest sufficient evidence

1. **Inspect-only:** read the diff for wording, comments, documentation, or a
   known one-line cleanup whose failure mode is directly visible. Skip scripts
   and Steam prompts. Existing keys, tokens, encoding, and behavior must remain
   unchanged for a prose-only localisation edit to use this lane.
2. **Changed-path checks:** for PDX/localisation changes that can break syntax,
   encoding, or references, run the base validator on the edited paths only:

   ```powershell
   & <SKILL_ROOT>/scripts/validate-hoi4.ps1 -ModRoot <MOD_ROOT> -Paths <changed files>
   ```

   Add `git diff --check` when used by the repository, and inspect only the
   identifiers or consumers the change can affect.
3. **Broader checks:** new systems, renames, GUI wiring, map/history,
   compatibility, version migration, template changes, and releases may need
   wider coverage. Select the relevant checks; this lane does not require every
   validator, Mod Doctor audit, `-All`, or a fresh-log sweep.

Reuse evidence while its relevant files, dependencies, build, and assumptions
remain valid. After a local batch, rerun only affected checks. Repeat a whole
baseline only for a new cross-system concern or an explicitly requested audit.
Keep useful existing local checks; assertion count alone is not a reason to
discard them.

Before adding a test, state the current risk, the decision its result changes,
and why existing evidence is insufficient in one sentence. Do not create a
separate test-justification report or approval procedure.

Static checks do not prove runtime behavior. For a relevant native question,
follow [test-mod.md](../../hoi4-content-builder/workflows/test-mod.md), including
its GPT-specific necessity gate, existing-authorization decision, and capability
and cost checks. A declined test needs a concise evidence limitation; give
manual steps only when useful and expand them only on request.

## Bound the work

For a small task, default to 0-3 relevant acceptance observations and at most
one necessary, authorized native session. After an actual failure and a fix,
allow at most one targeted recheck within the existing time and launch budget;
a second launch needs authorization that covers it. These are ceilings, not
targets. A broader explicitly requested task may use its agreed scope.

For a short test, state a small elapsed-time budget before preparation, counting
launcher setup and cleanup. Use the shortest route that answers the question.
Stop at the budget or answered observations; a remaining failure is a handoff,
not permission to expand the matrix or keep trying until green.

## Stop and hand off

- **Stop now / 现在停:** start no new investigation, validation, review, fix,
  delegation, or retry. Cancel cancellable work and tell existing agents to
  stop. Finish only the minimum safe completion of a write already in progress.
- **Finish the current step / 做完当前就停 / 我要睡了收尾:** current means one
  already-running bounded command or local edit, not the task list. Finish that
  unit and hand off; if no unit is running, stop immediately.
- Do not extend stopping with exit checks, configuration inspection, log
  archiving, hash scans, launcher restoration, or new fixes. Report actual
  running and restoration state; do not promise background continuation.
- A stop handoff has at most five items: completed work, unfinished work,
  location, running/stopped state, and the next first step. Record new issues
  without fixing them. Passing every check is not a condition for stopping.

## Documentation proportional to the change

Update existing technical documentation when architecture, entry points,
state/lifecycle, save compatibility, usage, or a documented test procedure
changes. Follow [development-documentation.md](development-documentation.md)
for those updates. A small wording/template correction needs no new guide,
handoff file, or obvious code comments. Use a concise completion message or the
project's existing change log when that is sufficient.
