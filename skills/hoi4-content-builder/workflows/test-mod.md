# Test a mod in HOI4

Static validation comes first. Before using computer-use, establish capability,
authorization, and billing impact in that order:

- Inspect the tools actually exposed in the current session. For an HOI4 test,
  browser automation alone is insufficient: the tool must be able to operate
  native Steam, launcher, and game windows on the target computer. Do not infer
  this capability from the agent's brand. Codex can expose native computer-use,
  while other clients or API integrations may expose browser or desktop control.
- If suitable computer-use is unavailable, do not inspect or ask about the
  user's subscription. Use the detailed manual-test handoff below.
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
- A general request to edit or validate a mod is not consent to open Steam,
  change launch options, alter a playset, or start the game. Ask: **Do you want
  the AI to control Steam and test this mod in-game?**
- Treat the plan name as one signal rather than the decision itself. Combine the
  actual tool capability, expected test cost, available quota or spend headroom,
  and the user's existing authorization or budget preference.
- If billing mode and quota class remain unknown, ask only whether the user
  accepts the likely quota or cost consumption. Do not require them to name the
  plan. When neither authorization nor cost tolerance is known, combine both in
  one concise question.

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

## When the user agrees

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

## When the user declines or automation is unavailable

Do not open Steam. Provide a detailed, feature-specific checklist containing
the exact isolated playset, `-debug`, earliest bookmark, country, every entry
path and material branch, expected result after each action, save/reload and
reopen coverage, reward/state checks, and the exact logs or screenshots to
return. Clearly mark runtime behavior as unverified. This detailed handoff is
mandatory when the user declines because of quota or cost.

## Handoff

Report target build/playset, paths tested, exact scenarios, static results,
fresh-log results, fixes made during testing, restored settings, and any branch
that still needs human judgment. A clean log alone is not proof of gameplay.
