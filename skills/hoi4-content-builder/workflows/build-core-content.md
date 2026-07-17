# Core content workflow

## Choose a starting resource

- One object only: copy the nearest file from `assets/templates/`.
- A focus that fires an event and grants an idea: copy
  `assets/kits/focus-event-idea/` while preserving its internal paths.
- A system not represented there: follow `verify-template.md` before adding a
  reusable skeleton.

## Build

1. Replace every `MOD`, `GER`, sample number, and sample localisation
   value. Search the copied files until no unintended placeholder remains.
2. Define databases before consumers: character or idea first, then events,
   decisions, focuses, history, on_actions, GUI, and localisation callers.
3. Keep one explicit caller for `is_triggered_only = yes` events. A triggered
   event may also contain a trigger as a defensive condition; those fields are
   not an either/or pair.
4. Put cheap immutable filters in decision `allowed`, visibility in `visible`,
   and current click conditions in `available`. Re-read the decision document
   before adding targeted decisions.
5. Use weekly or event-driven hooks when the intended cadence permits. Never
   migrate a daily invariant merely because a neighboring system is weekly.
6. Add every visible name and description. Use only `key: "Text"`, never
   `key:0 "Text"`; preserve the language identity, matching header, and UTF-8
   BOM.

## Verify

Run the base validator on all copied PDX/localisation files, search each new ID
across the repository, inspect `error.log`, and test the shortest complete path
from caller to visible result.
