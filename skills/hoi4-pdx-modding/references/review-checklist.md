# Review and refactor checklist

## Before editing

- Inspect `git status` and preserve unrelated work.
- Identify the canonical project documentation and runtime entry points.
- Search every definition and reference of affected identifiers.
- Confirm game version, DLC, playset, and exact dependency version.
- Rebuild or inspect the installed Markdown inventory and use the database-
  adjacent document for the object type. Flag stale update dates, broken links,
  TODO/TBD syntax, and generated prose that conflicts with current examples.
- For a post-update regression, inspect the official-news audit, then verify
  every reported migration against installed generated documentation and a
  current vanilla example.

## PDX structure

- Braces balance and blocks are nested under valid parents.
- IDs are unique and case-correct.
- Scopes are correct at every caller boundary.
- Optional tags/scopes and denominators are guarded.
- Variable-backed scope guards test the stored object; `scope_exists` alone is
  not accepted because variable scopes always pass it.
- Variables are initialized on every path before use.
- Array indices carry the semantic type expected by the callee.
- Exclusive branches use coherent `if`/`else_if`/`else` logic.
- Loops terminate and use the narrowest practical scope set.
- Collection size/count logic accounts for possible duplicate elements.
- Math functions and comparison helpers exist under their exact installed
  names; patch-note wording is not treated as syntax.
- Collection-size comparison semantics are preserved despite its documented
  inclusive `<`/`>` operators.
- Modifier recognition and support by the actual consumer are both proven.

## Cross-file wiring

- Event namespace, IDs, callers, options, and localisation agree.
- Decision category, ID, icon, cost, targets, effects, and localisation agree.
- Focus prerequisites, positions, mutual exclusions, icons, rewards, and
  localisation agree.
- Idea/MIO add/remove/unlock paths and sprites agree.
- GUI window/element names, GFX sprite names, texture paths, scripted GUI
  callbacks, and localisation keys agree.
- Scripted GUI refresh uses a meaningful dirty value or has an explicit reason
  to remain tick-updated; map modes restrict render targets where possible.
- On_action and scripted effect/trigger callers were included in searches.
- Event `immediate`/option/`after` and focus completion/bypass paths were
  reviewed as separate lifecycle branches.
- Bound/context-aware localisation is used only by a consumer that supplies
  the required support and context.

## Rename or migration

Search the entire repository, not only changed files, for:

- old and new flags and variables;
- event/decision/focus/idea/MIO IDs;
- scripted effect, trigger, GUI, and localisation tokens;
- GUI window and element names;
- GFX sprites and texture paths;
- opinion modifiers, equipment IDs, and technology IDs.

Preserve save compatibility or provide explicit initialization/migration for old
saves. After bulk replacement, inspect surrounding identifiers for partial or
doubled replacements.

## Adversarial questions

- What happens if the target country no longer exists?
- What happens on the empty-array, zero-value, maximum-value, and expired-timer
  boundaries?
- Can a delayed or weekly effect run twice or never run?
- Does a visible tooltip describe the effect actually applied?
- Can an event or callback call itself indefinitely?
- Does a dependency override this definition or use a different token version?
- Was the token removed, deprecated, or renamed by a recent official patch?
- Does a patch note claim a token that the installed generated docs omit or
  name differently?
- Could load order choose a different duplicate localisation definition?
- Does the implementation still work after save/reload and with an old save?
- Did a template come from an implemented current document, or from a shipped
  design draft containing TODO/TBD and “syntax for reference” comments?

## Handoff evidence

- Bundled static validator result.
- `git diff --check` result.
- Targeted stale-ID and duplicate-definition searches.
- Current `error.log` result from the intended playset, when available.
- Exact in-game scenarios tested and any remaining manual test steps.
