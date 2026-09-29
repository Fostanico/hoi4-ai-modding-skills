# Test a mod in HOI4

Static validation comes first. Before using computer-use, establish capability,
authorization, and billing impact in that order:

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

## Summarize testing willingness and decide once

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

## When testing is authorized

1. Confirm computer-use capability is available and read its runtime guidance
   and confirmation rules. If unavailable, give the manual procedure instead.
2. Snapshot the current Steam HOI4 launch options, launcher playset, enabled
   mods, load order, and any settings that the test will change.
3. Set HOI4 launch options to include `-debug` while preserving unrelated user
   options. Create or select an isolated test playset.
4. Enable only the target mod. For a submod or compatibility mod, also enable
   only its exact required dependencies in the documented order. Do not include
   unrelated mods.
5. Start HOI4 through Steam and the launcher. Start a **new game** using the
   earliest available bookmark/date in that target setup.
6. Select a country and route that can exercise the feature. Perform the real
   entry action, all material choices/outcomes, cancellation/expiry paths, AI
   or GUI interactions, reload behavior, and dependency-specific path required
   by the content contract. Use debug/console acceleration only after the real
   entry path is proven.
7. Observe the feature, screenshots or UI state, and game behavior. Read the
   fresh logs under the user's HOI4 logs directory, prioritizing `error.log`
   and relevant parser, scope, trigger, localisation, graphics, and AI logs.
8. Compare with the pre-test log or known baseline. Fix the earliest new root
   cause, rerun static checks, relaunch as needed, and repeat the smallest
   failing scenario.
9. Close the game/launcher when testing is complete. Restore launch options,
   playset, enabled-mod list, and load order changed for the test unless the user
   explicitly asks to keep them.

## When the user declines, remains unresponsive without applicable authorization, or automation is unavailable

Do not open Steam. Clearly mark runtime behavior as unverified. If the user
explicitly says not to test, acknowledge that choice once and do not send an
unsolicited long checklist. When a manual test is useful, give a concise path;
expand it into a feature-specific checklist with the isolated playset, `-debug`,
earliest bookmark, country, entry and branch actions, expected results,
save/reload, state checks, and logs/screenshots when the user requests it or
declines AI testing because of quota or cost.

## Handoff

Report target build/playset, paths tested, exact scenarios, static results,
fresh-log results, fixes made during testing, restored settings, and any branch
that still needs human judgment. A clean log alone is not proof of gameplay.
