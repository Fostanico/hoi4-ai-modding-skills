# AI and military content

## AI strategy

Use `common/ai_strategy/_documentation.md` from the installed game as the token
authority. A strategy block normally separates lifecycle from the strategy
payload: `allowed` controls loading eligibility, `enable` activation, `abort`
permanent removal, and `abort_when_not_enabled` temporary removal behavior.

- Copy strategy type names only from the current vanilla documentation.
- Treat values as additive weights, not universal percentages.
- Check interaction between broad strategies and specific strategies. Avoiding
  wars can coexist with a strong target-specific conquest weight.
- Keep expensive values cached if recalculated frequently.
- Never copy Millennium Dawn role names, equipment groups, caps, or country
  coverage into a vanilla-derived project.
- Current `naval_invasion_support_priority` examples use strategic-region IDs.
  Current `naval_dominance` accepts either an AI-area key or a strategic-region
  ID. Do not interchange those ID spaces without a matching current example.
- AI objectives now respect blocked naval regions; test whether a strategy is
  ineffective because the region is blocked before increasing its weight.

## AI equipment and division templates

Current vanilla separates equipment design logic from division-template logic.

- AI equipment design groups use real equipment categories, `blocked_for` or
  `available_for`, roles, and priority. Designs use module slots, requirements,
  allowed modules, target variants, enable conditions, and priority.
- AI equipment designs can request a `design_team` MIO. Verify that the
  organization exists, is allowed for the country, and supports the design's
  equipment before adding it.
- AI template entries are role-based. Use either `blocked_for` or
  `available_for`, not both. The installed documentation calls behavior
  undefined if selection is ambiguous. Avoid competing entries for the same
  country and role unless current vanilla proves the intended selection rule.
- `front_role_override` can force the front assignment class. Copy only values
  present in current vanilla templates, and test that the override does not
  starve defensive or reserve roles.
- Validate `target_template`, `replace_at_match`, `replace_with`,
  `target_min_match`, and `upgrade_prio` against current documentation.
- Target-template selection is deterministic; equal priority prefers the first
  definition, so file order can be semantic. AI upgrades by copying the best
  matching template and modifying the copy, not by editing it in place.
- Inspect runtime selection with `imgui show ai_templates` and
  `imgui show ai_division_production` when available. Current 1.19 adds
  template weighting to the AI-template view and raw matching scores to the
  equipment-role debug view.

## OOB and variants

Trace the entire chain before writing an OOB reference:

```text
technology unlock -> equipment archetype/type -> module-valid variant
-> produced or stockpiled equipment -> OOB battalion/wing/ship reference
```

- `type`, creator/producer, and `variant_name` must match the created variant
  and OOB reference exactly.
- Verify module slots, prerequisites, parent version, DLC branch, and the real
  loaded archetype or sub-unit name.
- Distinguish stockpiles from deployed divisions, air wings, and ships.
- Use explicit DLC/fallback branches where required. Another mod's number of
  airframes, equipment groups, or module taxonomy is not an engine invariant.

## Goal-based naval AI and faction theatres

- Naval goals define an objective type, country allow/block lists, and a
  minimum/maximum priority range. Each concrete objective supplies normalized
  importance from `0` to `1`; the score interpolates within the goal range.
- Current documented objective types include invasion support/defense, mine
  sweeping, coast defense, convoy protection, and convoy raiding. Verify new
  types against the installed file rather than extrapolating names.
- Inspect goal selection with `imgui show ai_navy`. Treat the task-force
  composition document's unresolved comments as documentation gaps, not
  guaranteed semantics.
- AI faction-theatre regions must form a connected area. `can_skip_first_region`
  permits creation when another listed region is available; it does not waive
  the connectivity requirement.

## Name lists

Use current vanilla name-list files as the structural template and current
loaded sub-unit/ship/equipment IDs as the vocabulary.

- Keep keys unique and localisation complete.
- Match list type to the consumer that reads it.
- Preserve encoding and exact punctuation in tokens.
- Do not import Millennium Dawn's modern ship classes, unit groups, tags, or
  list-count expectations unless the project explicitly depends on them.

## Verification sources

Check current installed copies of `common/ai_strategy/_documentation.md`,
`common/ai_equipment/_documentation.md`,
`common/ai_templates/_documentation.md`, and
`common/units/equipment/_documentation.md`, plus working files in
`history/units`, `common/units`, and `common/technologies`.

The Wiki explains the systems, but installed documentation and working vanilla
files decide exact current-version tokens. Re-read `launcher-settings.json`
before retaining the `1.19.2` assumptions in this reference.
