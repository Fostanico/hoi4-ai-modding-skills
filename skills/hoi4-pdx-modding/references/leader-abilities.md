# Leader abilities: parser cascades and safe extension

Read this reference when adding or changing `common/abilities/*.txt`, or when
several leader abilities disappear together.

## Contain the effect of a new definition

Prefer appending a new ability after the stable definitions in its existing
owner file. Put it **inside** the owning `ability = { ... }` block, immediately
before that block's closing brace. Do not paste a second ability ID outside the
root block. Preserve existing IDs and ordering; do not reorder old abilities
as a substitute for fixing the error. Keep a separate owner file only when the
project already has a real subsystem, load-order, or compatibility boundary.

A malformed ability definition can interrupt the parser and leave later
definitions in the same file unloaded. This was observed with an effect block
placed directly among an ability's data fields: later valid abilities produced
`Unexpected token` errors and their trait unlocks reported `not a valid ability`.
It does not establish that every typo stops every ability file. Appending new
definitions reduces the number of established abilities after a possible
failure; the new ability still requires full validation of its own contract.

## Keep data fields and activation effects separate

The installed consumers `common/abilities/generic_leader_abilities.txt` and
`common/abilities/RAJ_abilities.txt` put activation effects in
`one_time_effect`. Recheck the target installation before copying syntax.
An effect wrapper belongs within that effect context, for example:

```text
one_time_effect = {
    hidden_effect = {
        # Add verified activation effects here; check their starting scope.
    }
}
```

Do not put `hidden_effect`, effect scope switches such as `OWNER` or `FROM`,
or effects such as `set_portraits` directly at the ability-definition level.
Their validity inside `allowed`, `ai_will_do`, or an effect block is a separate
consumer/scope question. An event's `immediate` is not an ability activation
field. Do not assume all effect blocks begin in country scope: trace the leader
and owner through the actual ability consumer and any delayed event.

Modifier names must also match the actual database consumer. Current vanilla
army-leader abilities use `unit_modifiers = { breakthrough_factor = ... }`;
the observed `army_breakthrough_factor` spelling was rejected there. Do not
invent prefixes or transplant a country modifier into `unit_modifiers` merely
because its description sounds suitable. Preserve the intended numeric value
when correcting a spelling or nesting error unless balancing is requested.

## Validate the affected ability contract

1. Review the diff and owning block structure. Check unique, case-correct IDs,
   valid parent blocks, cost/duration/cooldown fields, and the new definition's
   position. Balanced braces alone cannot detect a valid effect in the wrong
   database context.
2. Check new or changed fields, modifiers, and activation scopes against the
   current installed documentation and a working ability consumer. Use the
   changed-path PDX validator for encoding/braces, plus a project ability
   validator if one exists. A generic validator pass is not schema proof.
3. Trace the grant path, including `enable_ability`, to the exact definition and
   its `allowed`/`has_ability` gates. A trait still containing the correct ID
   does not prove that the engine registered the definition.
4. Trace names/descriptions, icon sprite IDs, textures, and any active-state
   sprite requested by the consumer, such as `<icon>_animated`. For temporary
   portraits or other timed effects, check the actual leader, event ID, delay,
   and restoration target; do not reuse another ability's restoration event
   just because it has a matching delay.
5. For an observed parser cascade, identify every affected definition after
   the first failure and check its existing unlock/resource links too. Fix the
   first malformed block before interpreting downstream errors as independent
   defects. Keep unrelated traits, effects, and balance unchanged.

Keep this checking bounded to the ability file and affected consumers. Do not
turn a one-ability edit into a whole-mod audit. When maintaining a project
validator, a useful regression is a brace-balanced definition with a misplaced
root-level `hidden_effect`, followed by a valid ability; it should flag the
misplaced effect without rejecting the correctly nested `one_time_effect`.

## Close with the available evidence

When an in-game test is authorized and native control is available, use the
smallest cold-start check: confirm the new ability and an affected established
ability are loaded, exercise the changed activation path, and inspect the first
errors in that run's fresh log. Startup database parsing is not proven by a
hot reload or by logs from before the edit.

Follow [test-mod.md](../../hoi4-content-builder/workflows/test-mod.md) for the
existing authorization and testing preferences. If the user will test, declines
testing, or native control is unavailable, finish static checks and give a brief
manual check for the new and affected abilities. Report source/static evidence
and game evidence separately; do not claim that static checks proved loading.
