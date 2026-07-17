# Verified advanced patterns

These resources absorb reusable parts of the Workshop tutorial library into
the skill itself. They target installed HOI4 1.19.2.0 (d245); copy the file,
replace every `MOD` marker, and re-run the verification workflow after a
game update.

| Need | Built-in resource | Current vanilla proof |
| --- | --- | --- |
| Iterate a filtered faction collection | `assets/templates/collection-effect.txt` | `common/collections/generic_collections.txt`; `common/factions/goals/faction_goals_short_term.txt` |
| Store scopes, iterate them, then clear the array | `assets/templates/array-effects.txt` | `documentation/effects_documentation.md`; `common/decisions/SWI.txt` |
| Pass a selected scope into an event | `assets/templates/event-target-caller.txt` | effect docs; `common/decisions/POL.txt`; WTT border-conflict decisions |
| Variable-backed dynamic modifier | `assets/templates/dynamic-modifier.txt` | `common/dynamic_modifiers/0_dynamic_modifiers.txt`; variable-backed consumers in `wuw_dynamic_modifiers.txt` |
| Conditional dynamic text | `assets/templates/scripted-localisation.txt` | `common/scripted_localisation/00_scripted_localisation.txt` |
| Rename a state and a province | `assets/templates/state-name-effect.txt` | `common/national_focus/china_communist_sea.txt` |
| Bounded targeted-state decision | `assets/templates/targeted-state-decision.txt` | `common/decisions/_documentation.md`; `common/decisions/AUS.txt` |
| Complete targeted decision to saved-target event chain | `assets/kits/targeted-state-event/` | rows above plus current event/localisation consumers |
| Generate a staged country skeleton | `scripts/new-country-scaffold.ps1` | `common/country_tags/00_countries.txt`, `common/countries/Germany.txt`, `history/countries/GER - Germany.txt`, current character files |

## Scope contracts

- Collection and array elements must be the scope type consumed by the child
  effects. A scope array is not a numeric array.
- `for_each_scope_loop` changes scope; `for_each_loop` keeps the caller scope
  and exposes temporary value/index variables.
- A saved event target is contextual and should be created immediately before
  its consumer unless persistence across delayed calls is deliberately tested.
- In a targeted state decision, the acting country is `ROOT` and the selected
  state is `FROM` in the current vanilla patterns used here.
- `target_array` prevents a daily scan over every state. Keep it semantically
  narrow and retain final correctness checks in `target_trigger`.
- Dynamic modifiers update daily. `force_update_dynamic_modifier = yes` is for
  the owning scope when same-day refresh is genuinely required.

## Not promoted as current-proof templates

The Workshop dynamic-list GUI, 200-entry decision slider, shader packages, and
named-mod super events remain design references. Current scripted-GUI docs
describe `dynamic_lists`, but no current vanilla consumer was found in this
installed build. Use them only through `workflows/verify-template.md` and plan
an in-game test; do not label them vanilla-consumer verified.
