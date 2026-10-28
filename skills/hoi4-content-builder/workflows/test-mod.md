# Test a mod in HOI4

Apply the [shared workflow boundaries](../../hoi4-pdx-modding/references/workflow-boundaries.md)
first, including evidence reuse, session/time limits, and immediate stopping.
Choose proportionate static evidence before considering a native run. For a
needed run, establish capability, authorization, and billing impact:

- Inspect the tools actually exposed in the current session. For an HOI4 test,
  browser automation alone is insufficient: the tool must be able to operate
  native Steam, launcher, and game windows on the target computer. Do not infer
  this capability from the agent's brand. Codex can expose native computer-use,
  while other clients or API integrations may expose browser or desktop control.
- If suitable computer-use is unavailable, do not inspect or ask about the
  user's subscription. Mark runtime unverified and offer a manual-test handoff
  only when useful; do not press a user who already declined testing.
- In Codex, prefer its read-only usage-limit metadata when available. Inspect
  only the fields needed for this decision, such as `planType`, whether ordinary
  usage is allowed, usage windows, credits, and spend-control state. If the
  runtime or authentication status explicitly shows an API key, treat the
  session as API-billed. A missing `planType` or unavailable usage tool alone
  does not prove API billing.
- In another runtime that exposes suitable computer-use, use its trusted
  read-only plan, quota, or authentication metadata when available. Otherwise
  ask only whether the user accepts the likely quota or monetary cost; do not
  ask them to identify a plan whose name is not needed for the decision.
- Do not ask a user to identify a plan that reliable runtime metadata already
  identifies. Use only what is needed for this gate; do not repeat account
  identifiers, balances, or unrelated usage data to the user.
- A general request to edit or validate a mod is not by itself authorization
  to open Steam, change launch options, alter a playset, or start the game.
  Apply the user-intent decision below before asking or acting.
- Treat the plan name as one signal rather than the decision itself. Combine the
  actual tool capability, expected test cost, available quota or spend headroom,
  and the user's existing authorization or budget preference.
- If billing mode and quota class remain unknown, ask only whether the user
  accepts the likely quota or cost consumption. Do not require them to name the
  plan. When neither authorization nor cost tolerance is known, combine both in
  one concise question.

## GPT-series models: question the test before launching

Apply this gate when the working model is a GPT-series model, including a
Codex session whose underlying model is GPT, and especially when it is
GPT-6astra or GPT-6.1sol. Other model families do not take this extra step.
If the model family cannot be identified, do not assume it is GPT.

Before asking for a launch, and again before each extra in-game pass, decide
whether the run answers a question static evidence cannot settle and whether
that question belongs to this change. Launch only for an open engine or
player-visible result the edit can actually break: scope, timing, GUI
interaction, AI choice, history loading, asset rendering, or a failure
already seen at runtime. An explicit user request to test this change is
enough; do not talk the user out of a test they just asked for.

Skip the launch when the run would only reassure the model. That includes a
comment, wording, or unique one-line cleanup; a file the changed-path
validator already covers; a second country, resolution, reload, or system
the change does not affect; and any pass added only because a test might
feel safer. Say that the test is unnecessary, keep the static result, and
do not open Steam or ask the user to approve that launch. Mark runtime not
applicable for this change.

Defensive programming is harmful here to both the developer and the player.
Do not answer an uncertain or skipped test by adding speculative guards,
silent fallback branches, extra existence checks, clamps, or unused
triggers. Those paths hide the broken contract from the person maintaining
the mod, and they spend performance, interface clarity, or gameplay on
behavior nobody asked for. Still guard a scope the real caller can lack,
keep a triggered event's real trigger, and initialize missing save state
once so migration stays idempotent. Those are engine and save contracts,
not a license to wrap working content in safety code.

## Summarize testing willingness and decide once

Reach this section only when the test still has a reason to run. A GPT-series
model that already marked the launch unnecessary stops here and does not ask
for authorization.

Before an AI-run game test, privately summarize the evidence in a few lines:
latest direct choice for this task, earlier comparable test choices, any still
applicable standing authorization or budget, the intended test scope, available
native-control capability, and reliable remaining quota or spend headroom.
Label unknowns as unknown. The latest direct choice wins: a current "do not
test" ends the AI-run test path even when earlier conversations favored it.
Do not treat old approvals for a different scenario as blanket permission.

If a decision is still needed, send at most one concise request for the whole
task, covering both native control and meaningful cost. Do not send reminders,
rephrase the same question in another channel, or poll for an answer. Continue
independent static work. If the user remains silent for a sustained period
(e.g. ten minutes during ongoing work), make one decision from the summary and
fresh quota metadata; do not idle merely to reach that interval. Silence is no
new authorization. Run a bounded test only when the current request or a clear,
still-applicable standing authorization already permits native testing and the
available quota covers the estimated scope. Otherwise finish with runtime
unverified and a concise manual-test handoff. If there is no suitable native
computer-use tool, skip the request, mark runtime unverified, and offer manual steps only when useful.

## Resource-aware autonomy

Estimate the computer-use scope before deciding whether to ask about cost. Do
not invent an exact token, credit, or currency estimate when the runtime does
not provide one.

- **Negligible:** inspect one already-open screen or perform a few bounded UI
  actions without launching or restarting the game. When the user explicitly
  requested autonomous testing and usable quota remains, proceed without a
  separate cost question, including on a limited plan.
- **Bounded:** launch or restart once and verify one narrow path with a clear
  stopping condition. For API billing or a limited plan, ask once if this could
  make a noticeable difference to cost or remaining quota. A confirmed
  high-quota plan plus an explicit autonomous-test request normally needs no
  redundant cost question.
- **Expensive:** repeated launches, multiple gameplay routes, resolutions,
  compatibility combinations, long observation periods, or broad visual
  regression passes. State the proposed coverage and stopping condition, then
  obtain a cost/quota confirmation unless an existing user-set budget clearly
  covers it, regardless of the plan label.

Honor an explicit standing preference such as a maximum number of launches,
maximum elapsed test time, monetary ceiling, quota percentage, or "ask only
above this scope" for the session or project where the user set it. Do not ask
again while the requested work stays inside that boundary. Do not create a
persistent preference outside the current context unless the user asks to save
one.

If reliable metadata shows insufficient quota, disabled usage, or a reached
spend control, stop before launching and use the manual-test handoff. During an
approved test, stop at the agreed scope instead of silently expanding coverage;
report the next highest-value test separately.

## Short or simple tests

Use the shared small-task observation, session, and time limits. State the
elapsed-time budget before launcher preparation; setup and cleanup count.

Use the console early and flexibly to reach the required state: verified
event/effect IDs, resources, flags, variables, or existing debug fixtures can
skip unrelated recruitment, story, focus, waiting, and gameplay prerequisites.
Do not require a complete normal playthrough before using the console. If an
entry button is itself under test, prepare its prerequisites with the console
and exercise that button once. If victory or reward dispatch is under test,
prepare a near-complete state and perform the real final action; directly
granting the expected reward does not verify its dispatch.

If console input or setup cannot be made to work promptly, report that narrow
blocker instead of replacing the shortcut with a long manual progression.
Stop when the agreed observations are answered, the time budget is reached,
or the user stops the test. Do not add full matches, other branches, reloads,
extra launches, or repeated complete flows to a short test.

## When testing is authorized

1. Confirm computer-use capability is available and read its runtime guidance
   and confirmation rules. If unavailable, give the manual procedure instead.
2. Select the shortest relevant starting state: a suitable already-running
   session, an existing test save, or a new game at the relevant bookmark/date.
   Use the affected save for a save-specific regression without overwriting
   the user's original. Require a cold launch when the question concerns
   startup, parsing, or assets that need it; a hot refresh is not that evidence.
3. For a launch or configuration change, snapshot the launch options, playset,
   enabled mods, load order, and settings that will change. Include `-debug`
   when fresh debug diagnostics are needed, preserving unrelated user
   options. Prefer the user's existing playset, including the current playset
   when suitable. Do not create a new playset unless a concrete test need
   requires it; testing alone is not a reason to create one.
4. When configuring a launch, enable only the target mod in that playset and
   disable unrelated mods. For a submod or compatibility mod, also enable its exact required
   dependencies in the documented order. Preserve the original enabled list
   and load order for restoration.
5. When a launch is needed, start HOI4 through Steam and the launcher and use
   the starting state chosen above. An existing session must already have the
   required build, mod files, and dependencies loaded; changing the launcher
   selection does not change a running session.
6. Select a country and the shortest route that exercises the agreed
   observations. Use console/debug preparation from the outset, especially
   for a short or simple test. Exercise only the relevant real interaction;
   broader branches, cancellation, expiry, AI, and reload paths belong in the
   run only when explicitly included in its scope.
7. Observe the feature, screenshots or UI state, and game behavior. Read the
   relevant fresh entries under the user's HOI4 logs directory, prioritizing
   `error.log`. Do not expand a short test into an unrelated log audit.
8. Compare with the pre-test log or known baseline. Fix the earliest new root
   cause when correction is within scope. Any retest must stay within the
   authorized time and launch limits; one authorized session does not permit
   an extra launch. Otherwise report the failure and stop.
9. At normal completion, close only a game/launcher session opened for this
   test unless the user wants it left open. Restore launch options,
   playset, enabled-mod list, and load order changed for the test unless the user
   explicitly asks to keep them or takes over restoration. If the user says
   they will restore the playset, stop operating it and report its actual
   restoration status. Plan this restoration inside the time budget. If the
   budget expires or the user stops, follow the shared stop procedure and
   report what remains unrestored.

## When the user declines, remains unresponsive without applicable authorization, or automation is unavailable

Do not open Steam. Clearly mark runtime behavior as unverified. If the user
explicitly says not to test, acknowledge that choice once and do not send an
unsolicited long checklist. When a manual test is useful, give a concise path
from a relevant session/save/bookmark to the real action and expected result.
Expand only on request, selecting the setup, state checks, reload, and evidence
that the question actually needs. Declining because of cost does not itself
request a detailed checklist.

## Handoff

Report target build/playset, elapsed time including preparation and cleanup,
console-prepared state versus interactions actually exercised, static results,
fresh-log results, fixes made during testing, actual restored settings, and any branch
that still needs human judgment. A clean log alone is not proof of gameplay.
