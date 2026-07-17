# Test a mod in HOI4

Static validation comes first. Then explicitly ask: **Do you want the AI to
control Steam and test this mod in-game?** A general request to edit or validate
a mod is not consent to open Steam, change launch options, alter a playset, or
start the game.

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

Do not open Steam. Provide a minimal checklist containing the exact isolated
playset, `-debug`, earliest bookmark, country, actions, expected results, and
logs to return. Clearly mark runtime behavior as unverified.

## Handoff

Report target build/playset, paths tested, exact scenarios, static results,
fresh-log results, fixes made during testing, restored settings, and any branch
that still needs human judgment. A clean log alone is not proof of gameplay.
