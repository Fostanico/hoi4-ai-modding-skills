# Clausewitz / PDX script (P language)

Hearts of Iron IV content is written in Clausewitz script, commonly called
PDX script or P language. Editors treat it as a custom language, not C++ or
Java. AI models do not ship a native P-language parser. Use this page for
grammar and scope wiring; prove tokens against installed vanilla.

Discovery order for uncertain syntax:

1. Target-mod project rules.
2. Installed `documentation/*.md` and `common/**/_documentation.md`.
3. A current vanilla consumer of the same object type.
4. CWTools HOI4 `.cwt` rules as a schema hint (scopes, accepted forms,
   cardinality, folder mapping). CWTools is MIT-licensed static analysis, not
   the engine. Its warnings can be false; its TODOs are not production syntax.
5. IDE highlighters and snippet libraries last. They lag and invent.

Do not copy `.cwt` files, TextMate grammars, or extension snippet DBs into a
mod. Distill the rule, then emit vanilla-shaped PDX.

## Tokens and layout

- Line comments start with `#` and run to end of line.
- Blocks are `key = { ... }` or `key = value`. `{` belongs on the declaration
  line.
- Unquoted values are symbols: tags, identifiers, numbers, dates, `yes` /
  `no`, paths, and operators such as `var:`, `token:`, `@`, `^`.
- Quoted strings are `"..."` with `\"` and `\\`. Localisation values are always
  quoted YAML strings, not PDX blocks.
- Comparison operators in script are `=`, `<`, `>`, `!=` where the consumer
  documents them. Ordinary `check_variable` in 1.19.2 uses `=`, `>`, `<`.
  Inclusive bounds need an explicit combination. Math expressions may use
  `greater_than_or_equals` / `less_than_or_equals`; that does not make `>=`
  legal in `check_variable`.
- HOI4 has `AND` / `OR` / `NOT`. There is no general `NAND`. `NOR` is Norway's
  country tag; do not emit `NOR = { }` as a logical operator.
- `NOT = { A B }` means not (A and B). Write separate `NOT` blocks or negate an
  explicit `OR` when the intent is not-A and not-B.
- Unclosed braces, a raw `RGB` token, and some `/\&` sequences can make a
  whole file fail static validation even when later blocks are fine. Fix the
  first parse break before chasing later diagnostics.

New PDX `.txt` / `.gui` / `.gfx` files in this project stay UTF-8 without BOM.
Prefer tabs when the target file has no other established indent.

## Cardinality and optionality

CWTools annotates fields as `0..1`, `1..1`, `0..inf`, or `1..inf`. That is a
schema hint for editors, not a guarantee the engine will reject a missing
optional. Treat:

- `0..1` as optional single;
- `1..1` as required in that object type when a current vanilla consumer also
  has it;
- `0..inf` as repeatable.

A missing cardinality annotation is not "required". When CWTools and vanilla
disagree, vanilla wins.

## Scopes and links

P script is scope-oriented. `THIS` is the current object, `ROOT` is the
original scope of the block, `FROM` is the caller-supplied counterpart,
`PREV` is the previous scope in the chain.

CWTools models links that change scope. Verified against current vanilla
consumers:

| Link | Typical input | Result |
| --- | --- | --- |
| `owner` | state, character, unit leader, combat, MIO, project | country |
| `controller` | state | country |
| `capital_scope` | country | capital state |
| `country` / `state` / `character` | data form `country:TAG`, `state:64` | that object |
| `var:` / `temp_var:` | stored variable | number or scoped object |
| `event_target:` | saved target name | saved scope |
| `token:` | ideology, idea, tech, equipment, module, trait, operation | token-valued value |
| `mio:` | country | MIO organization |
| `sp:` | country | special project |

Current vanilla uses `mio:AST_gloster_aircraft_organization` and
`sp:sp_air_radar`. Prefixes are not cosmetic; they select a typed lookup.

`## replace_scope` in CWTools records the implicit frame of nested fields
(focus `available` resets THIS/ROOT to country; targeted decisions can set
FROM to the target country or state). Always trace the real caller. Do not
assume every CWTools-listed chain is legal in every consumer.

Character and operation blocks can nest country-shaped effects; still enter
them from a proven caller.

## Variables, arrays, and tokens

- Persistent: `set_variable` / `add_to_variable` on a scope.
- Temporary: `set_temp_variable` for the current execution chain.
- Global: `global.` / `set_global_variable`.
- Arrays: `array^0` is the first slot (zero-based). `^` is an index, not a
  tag separator.
- Typed lookups: `var:name`, `temp_var:name`, `event_target:name`,
  `token:civilian_economy`, `mio:org_id`, `sp:project_id`.
- Dynamic engine values (`manpower_k`, `date`, `threat`, …) are read-only.
  `documentation/dynamic_variables_documentation.md` marks `manpower`,
  `max_available_manpower`, and `max_manpower` as deprecated because they may
  overflow. Prefer the `_k` forms.

CWTools often flags `^` and `:` variable forms as errors. That is a known
false positive. Do not "fix" a working `var:array^i` or `token:` usage just to
silence the editor.

## Events, focuses, and delayed effects

- Event kinds: `country_event`, `news_event`, `state_event`,
  `unit_leader_event`, `operative_leader_event`. Hidden events omit player
  chrome; they still need a valid `id`.
- `trigger` and `is_triggered_only` can coexist. The trigger is a fire-time
  safety check.
- Delayed event fire supports `hours`, `days`, `months`, `random_hours`, and
  `random_days`. Installed effect docs keep `random = N` as a
  backwards-compatible alias of `random_hours`. Prefer `random_hours`.
  `random = { chance = ... }` is a different effect (chance group).
- Focus `cost` is in weeks; the engine stores days and truncates fractional
  weeks toward whole days. Prove the intended duration in-game if the design
  is not a whole week.
- `delete_unit` / `delete_unit_template_and_units` take
  `division_template = <name>` in current effect docs. Do not emit a bare
  `template =` field from older editor snippets.

## Folders versus `replace_path`

CWTools scans `common`, `events`, `gfx`, `history`, `interface`,
`localisation`, `portraits`, `map`, `sound`, `music`, `dlc`, and
`integrated_dlc`. That list is the editor index, not a `descriptor.mod`
`replace_path`. A mod still has to declare `replace_path` when it intends to
drop vanilla files in that folder.

Some types are one-definition-per-file in the schema (country history).
Others skip a wrapper key (`focus_tree`, `on_actions`, `guiTypes`,
`spriteTypes`). Copy that wrapper from a current vanilla file of the same
class.

## Static analysis versus the engine

CWTools, highlighters, and snippet panels are useful cheap checks. They are
not a test plan.

Known editor/engine mismatches:

- CWTools default generated localisation uses `:0 "REPLACE_ME"`. This
  project forbids numeric key versions. Always emit `key: "Text"`.
- CWTools reports thousands of "errors" in vanilla. Expected. Do not copy
  those diagnostics into a mod review as defects.
- CWTools config files for factions, doctrines, and some NCNS tokens still
  contain TODOs. Incomplete schema ≠ missing engine feature.
- `ideas` `do_effect` is marked unreliable in CWTools. Do not build a feature
  on it without a current vanilla consumer.
- IDE country wizards may still emit `create_country_leader` and English
  `key:0` files. Use `characters` + `recruit_character` and this project's
  localisation contract instead.

When an editor warning and vanilla documentation disagree, keep the vanilla
shape, note the false positive, and move on.
