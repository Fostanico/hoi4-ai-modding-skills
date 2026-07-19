# PDX script foundations

## Contents

- Source order
- Encoding and layout
- Scopes
- Variables and arrays
- Loops and conditions
- Verification rules

## Source order

Use sources in this order:

1. Project guidance and established working examples.
2. The current [HOI4 Wiki](https://hoi4.paradoxwikis.com/Modding) for concepts.
3. Official Steam patch notes and developer diaries to discover recent engine
   changes.
4. The installed game's generated `documentation/*.md`, database-specific
   `_documentation.md`, and current vanilla files for exact syntax and tokens.
5. Files from the exact enabled dependency version for overridden systems.

Use [vanilla-documentation-map.md](vanilla-documentation-map.md) to route a
task to the correct installed document. Query exact `## <token>` entries in the
large generated files, then read a complete current vanilla consumer.

Wiki pages are community-maintained and can lag game updates. A copied example
from another mod proves only that the author wrote it, not that the current
engine accepts it. Patch notes can also use a descriptive or stale token name;
the installed generated documentation and current examples decide what to emit.

## Encoding and layout

- Keep PDX `.txt`, `.gui`, and `.gfx` files UTF-8 without BOM unless an existing
  target file demonstrably requires something else.
- Preserve the target file's indentation. Prefer tabs for new PDX blocks when
  the target repository has no established style.
- Put `{` on the declaration line and the matching `}` at the outer indent.
- Comment every file or subsystem sufficiently for another maintainer to find
  its purpose and entry point. Explain invariants, scope contracts, state
  ownership/lifetime, cadence and units, save/compatibility constraints, and
  engine workarounds where they are not obvious. Keep comments readable and
  close to the affected block; do not mechanically restate each line.
- Balanced braces are a minimum check, not proof of valid field nesting.

## Scopes

- `ROOT` is the original scope at the start of the current scripted block.
- `FROM` is supplied by the caller, commonly an event sender or targeted
  decision target. It can fall back unexpectedly when the caller supplies no
  separate source; trace the caller.
- `PREV` is the previous scope in a scope chain; repeated `PREV.PREV` is fragile
  and should be documented or replaced with saved event targets when practical.
- `OWNER` and `CONTROLLER` require a state-derived context. Do not use
  `CONTROLLER` as though it were a country-scope keyword.
- Use `original_tag` when restricting a country object that must remain usable
  after civil wars or dynamic tag changes. Use runtime `tag` only when the
  current tag is intentionally significant.
- Guard optional tags and variable-stored scopes with `country_exists`,
  `exists = yes`, or a proven equivalent before applying effects.
- Dual scopes can be structurally valid yet have no target in the current
  context. Guard `overlord` with `is_subject = yes` and `faction_leader` with
  `is_in_faction = yes`; validate a saved event target or scope-valued variable
  before entering it. Otherwise the block is skipped and repeated evaluation
  can flood the log with `invalid event target`.
- An ownerless or controllerless state is a broken map/history condition, not
  a normal optional-scope branch. Ensure every playable state has valid
  ownership/control at the tested date instead of wrapping all `owner` or
  `controller` access in cosmetic guards.

## Variables and arrays

Persistent variables live on a scope and survive saves:

```pdx
set_variable = { var = MOD_example value = 5 }
add_to_variable = { var = MOD_example value = 1 }
```

Temporary variables live only for the current execution chain:

```pdx
set_temp_variable = { var = MOD_cost value = 10 }
```

Global variables are read with the global scope:

```pdx
set_global_variable = { var = MOD_global_example value = 1 }
check_variable = { global.MOD_global_example > 0 }
```

Dynamic variables are read-only engine values. They can be used only where the
consumer accepts variables, and their scope and optional `@target` syntax must
match `documentation/dynamic_variables_documentation.md`. Do not attempt to
initialize, clear, or migrate a dynamic variable as though it were stored mod
state.

Array indices use `^` and are zero-based. Trace whether an index represents an
array slot, database ID, state ID, or another lookup key; these are not
interchangeable.

```pdx
MOD_array^0
MOD_array^i
var:MOD_array^i = { exists = yes }
```

Inside `for_each_loop`, the value variable is the element itself, not another
array. `var:v = { ... }` can scope into a scope-valued element; `var:v^i` is not
an array lookup.

Use inline math expressions only with syntax proven in the current engine.
Wrap multi-step arithmetic inside `value = { ... }`; sibling `add` or
`multiply` fields beside `value = X` can silently evaluate incorrectly.

```pdx
set_temp_variable = {
	var = MOD_total
	value = {
		value = MOD_base
		multiply = 2
		add = MOD_bonus
	}
}
```

Guard division against zero or near-zero denominators. Do not assume malformed
math will throw a visible error; check `error.log` for `script_math` messages.

## Loops and conditions

- Prefer engine-maintained narrow arrays such as subjects, faction members, or
  owned states over `every_country` or `every_state` plus a filter.
- Hoist invariant calculations and scope lookups outside loops.
- Ensure every `while_loop_effect` advances toward termination. The engine has
  an iteration safety cap; do not rely on it as control flow.
- Use `if`/`else_if`/`else` for exclusive effects. Two complementary `if`
  blocks repeat condition evaluation and can diverge after later edits.
- Check empty-array behavior explicitly for `any_of`, `all_of`, and random
  array operations.

Conditions are implicit AND within a trigger block; an `AND = {}` wrapper is
normally redundant. HOI4 does not provide a general `NOR = {}` operator. Also
remember that `NOT = { A B }` means `NOT (A AND B)`, not `NOT A AND NOT B`.
Write separate `NOT` blocks or negate an explicit `OR` when that is the intent.

Inline `check_variable` comparisons support the operators demonstrated by
current vanilla (`=`, `>`, and `<`). Express inclusive bounds with an explicit
combination instead of inventing `>=` or `<=` syntax.

Values such as `threat` commonly use a decimal fraction (`0` to `1`), not a
whole-number percent. Confirm the unit of every unfamiliar value in current
vanilla examples.

The generated `collection_size` comparison syntax is exceptional and
inclusive: `value > N` means at least `N`, while `value < N` means at most `N`.
Do not silently translate it using ordinary strict-comparison semantics.

## Scope existence and constants

- `scope_exists` asks whether the current scope object exists; it does not ask
  whether a scoped country is alive. Variable scopes always pass
  `scope_exists`, so it cannot validate the object stored in a variable.
- Use `country_exists` for a country target and a current object-specific
  existence/role trigger for characters, projects, MIOs, and other scopes.
- Script constants work only in explicitly supported consumers. Fixed-point
  constants are available to scoped variables as
  `constant:<category>.<key>`; the `@` macro remains file-local.
- Reload the constants database and then every consuming database after a
  constant changes. Reloading constants alone leaves already loaded consumers
  with their prior injected values.

## Script values and localisation objects

- A malformed math/script-value expression can resolve to zero and cause
  downstream behavior rather than a clear hard failure. Inspect math errors.
- Current 1.19.2 math expressions use fixed-point arithmetic. Boolean operators
  return `1.0` or `0.0`, and every non-zero input is true.
- Use only functions listed by the installed
  `documentation/script_math_functions.md`; do not assume every normal trigger
  is legal inside a math expression. In local 1.19.2 use `root = 2` for a
  square root; do not copy the announced but undocumented `sqrt` or `exp` names.
- Current documented math-only comparisons include
  `greater_than_or_equals` and `less_than_or_equals`. This does not make `>=`
  or `<=` valid in ordinary `check_variable` syntax.
- Script variables and array mutations do not create automatic effect
  tooltips. Add explicit custom tooltips when the player needs feedback.
- Distinguish formatted/bound localisation and localisation objects from plain
  localisation keys. Verify the consumer supports the chosen form.

## Collections and quantified checks

Collections can transform engine-owned scope sets without manually creating an
array. Prefer them when current documentation provides the needed input and
operator chain. A collection is not guaranteed to contain unique objects, so
deduplicate by design or avoid size-based logic when duplicate expansion is
possible.

Inside a named collection's `limit`, the element is the current scope, `PREV`
is the scope from the collection consumer, `ROOT = PREV.ROOT`, and
`FROM = PREV.FROM`. Re-prove this chain if an anonymous operator pipeline adds
another scope transition.

Patch 1.16 announced `count` for all `any_*` object triggers, including a
scoped-variable count. Current generated 1.19.2 documentation explicitly shows
it on `any_collection_element`, where it means at least that many children must
match. For another `any_*`, require generated documentation, a current exact
example, or a focused runtime test before relying on `count`.

## Verification rules

- Search current vanilla and dependency files for unfamiliar constructs.
- Trace the first load error in a file before investigating later errors; one
  malformed block can shift parsing and create misleading cascades.
- Search old and new identifiers across the whole repository after renames.
- Verify dynamic modifier keys, equipment archetypes, MIO categories, GFX
  tokens, and scripted GUI element names against definitions, not display text.
- Treat `modifiers_documentation.md` as an engine-recognition list. Confirm the
  exact idea, trait, doctrine, MIO, dynamic-modifier, or equipment consumer in
  current vanilla before emitting a listed modifier.
