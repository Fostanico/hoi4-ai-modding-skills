# Advanced engineering

## Model the system

Write the feature as a state machine: entry, state storage, transitions,
consumers, cleanup, reload behavior, and migration. Assign each flag, variable,
array, event target, dynamic modifier, and GUI dirty variable one owner and one
clear lifetime. Use saved event targets only as briefly as the caller requires.

Separate definition databases from orchestration and presentation:

```text
definitions -> scripted triggers/effects -> callers/on_actions -> AI/GUI -> localisation/assets
```

Keep dependency-specific adapters separate from the standalone core. For a
submod, verify exact dependency IDs and version rather than copying translated
names or an older branch.

## Performance budget

Estimate `frequency x scopes x work per scope`. Move invariant lookups outside
loops, cache expensive conditions only with a reliable invalidation path, bound
target arrays/collections, and prefer weekly, event-driven, or dirty-variable
refreshes to daily global scans. Preserve intentional daily behavior.

## Save and version migration

- Preserve public IDs and stable state when possible.
- If renaming, provide a one-time migration gated by a version flag.
- Initialize missing state defensively and make migration idempotent.
- Clear obsolete arrays/targets/modifiers only after their consumers migrate.
- Audit exact vanilla overrides after every supported game update.
- Test both a new save and a representative old save when migration matters.

## Advanced validation

Build a matrix across bookmarks, countries, DLCs, dependency versions, AI/player
control, reload, and resolution only where the feature varies across them. Use
console or debug UI to reach states, but still exercise the real caller at least
once. Compare fresh logs against a baseline so inherited warnings do not hide
new errors.

Promote a pattern into `assets/templates/` only after checking the installed
schema, a current vanilla consumer, the complete resource chain, placeholders,
static validation, and a minimal in-game run. Record those sources in the
template catalog.
