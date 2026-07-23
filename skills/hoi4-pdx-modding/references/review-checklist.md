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

## Semantic intent

- Build a code ID -> visible name -> player-facing promise map from actual
  localisation before interpreting or changing an existing feature.
- Read names, descriptions, options, tooltips, modifier text, scripted
  localisation, GUI labels, debug text, and character descriptions that belong
  to the affected path.
- Do not transliterate or expand an internal ID, abbreviation, filename, or
  variable name into a proper name or gameplay meaning.
- Reconcile displayed dates, costs, cooldowns, units, first-use behavior,
  failure handling, and manual choices with the implementation.
- Report code/localisation/documentation disagreement explicitly; after an
  intentional behavior change, update every affected visible consumer.

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
- For artwork audits, follow the review skill's
  [icon-audit.md](../../hoi4-review-debug/references/icon-audit.md): include
  game DLC roots and exact dependencies; distinguish broken GFX/assets from
  generic defaults, `none`/`nothing`, hidden objects, inheritance, and optional
  icons.
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

## Documentation and readability

- The canonical mod technical document was created or updated in the same
  change and records the affected architecture, entry points, IDs, state
  ownership, lifecycle, dependencies, compatibility, and test procedure.
- The current development handoff records changed files, design decisions,
  validation evidence, runtime status, remaining risks, and next actions.
- Durable technical truth and change-specific handoff are kept distinct, even
  when the project stores them as two sections in one file.
- New or changed code has readable comments for file/subsystem purpose and
  non-obvious scope, state, units, cadence, cleanup, save behavior, performance,
  compatibility, or engine-workaround decisions.
- Comments explain why and contracts rather than translating every token into
  prose. Stale comments, dead commented-out code, and claims contradicted by
  the implementation were removed or corrected.
- Project documentation links to identifiers and owned files instead of
  duplicating generic PDX language rules already maintained by the skill, Wiki,
  or installed game documentation.

## Adversarial questions

- What happens if the target country no longer exists?
- What happens on the empty-array, zero-value, maximum-value, and expired-timer
  boundaries?
- Can a delayed or weekly effect run twice or never run?
- Does a visible tooltip describe the effect actually applied?
- Did the review read that tooltip and the associated name/description before
  assigning a narrative or gameplay meaning to the code token?
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

- Canonical technical-document and development-handoff updates.
- Bundled static validator result.
- `git diff --check` result.
- Targeted stale-ID and duplicate-definition searches.
- Current `error.log` result from the intended playset, when available.
- Exact in-game scenarios tested and any remaining manual test steps.
