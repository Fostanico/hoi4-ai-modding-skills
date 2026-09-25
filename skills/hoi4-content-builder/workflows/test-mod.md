# Test a mod in HOI4

Static validation comes first. Before using computer-use, establish capability,
authorization, and billing impact in that order:

- If computer-use is unavailable, do not ask about the user's subscription.
  Use the detailed manual-test handoff below.
- When the runtime exposes read-only account or usage-limit metadata, inspect it
  before asking the user. In Codex this may include `planType`, whether ordinary
  usage is allowed, usage windows, credits, and spend-control state. Use only
  what is needed for this decision; do not repeat account identifiers, balances,
  or unrelated usage data to the user.
- Do not ask a user to identify a plan that reliable runtime metadata already
  identifies. Conversely, absence of account metadata alone does not prove API
  billing because portable skills may run in clients that do not expose it.
  Treat a session as API-billed only when the runtime or authentication mode
  explicitly establishes API-key billing.
- A general request to edit or validate a mod is not consent to open Steam,
  change launch options, alter a playset, or start the game. Ask: **Do you want
  the AI to control Steam and test this mod in-game?**
- For API-billed sessions and limited personal plans such as Free, Go, or Plus,
  explicitly ask whether the user accepts the likely cost or quota consumption.
  Do this even when they already requested an autonomous computer-use test. A
  yes/no cost check is enough; do not ask for account details.
- For ChatGPT Pro, Claude Max, or another runtime-confirmed or user-stated
  high-quota plan, an explicit request for autonomous testing needs no redundant
  quota question. If runtime metadata says usage is unavailable or a spend
  control has been reached, stop and use the manual-test handoff.
- If billing mode and quota class remain unknown, ask only whether the user
  accepts the likely quota or cost consumption. Do not require them to name the
  plan. When neither authorization nor cost tolerance is known, combine both in
  one concise question.

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
