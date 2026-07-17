# HOI4 localisation deep dive

## Contents

- Evidence hierarchy
- File and language contract
- Colours, line breaks, flags, and text icons
- Nested keys and internal parameters
- Formatted variables
- Scope objects and functions
- Dynamic-consumer boundaries
- Scripted, bound, and context-aware localisation
- Localisation formatters
- Four-language authoring workflow
- Validation and diagnostics

## Evidence hierarchy

Localisation is both data and executable presentation logic. Verify it in this
order:

1. Use the HOI4 Wiki to discover concepts and historical syntax.
2. Use the target installation's `documentation/loc_objects_documentation.md`
   for current scope-object promotions and properties.
3. Use `documentation/dynamic_variables_documentation.md` for current dynamic
   variable names and targets.
4. Use `documentation/loc_formatter_documentation.md` for the current
   formatter inventory, required localisation objects, and parameters.
5. Use `interface/core.gfx` for current colour definitions.
6. Find a current vanilla consumer of the same UI/content class.
7. Test the final string in that exact consumer and inspect fresh logs.

The Wiki's function table is useful but explicitly version-stale. Installed
generated documentation wins for current existence; a current consumer wins
for practical context support.

Verified snapshot for the examples below: Hearts of Iron IV Operation Postern
1.19.2.0 (d245), 2026-07-17.

Sources used for discovery and version history:

- [HOI4 localisation Wiki](https://hoi4.parawikis.com/wiki/%E6%9C%AC%E5%9C%B0%E5%8C%96)
- [Paradox Performance and Modding diary](https://store.steampowered.com/news/app/394360/view/6148070194801725069)
- [Official HOI4 Steam news](https://store.steampowered.com/news/app/394360)

Relevant official change history:

- The 2024-11-11 Performance and Modding diary introduced bound localisation,
  localisation formatters, and context-aware GUI localisation.
- The 2025-11-26/27 patches fixed Russian number-symbol handling, moved
  localisation hashing to 64 bits to reduce collisions, and fixed a
  multiplayer OOS involving Korean and other localisation groups.
- The 1.19.0 notes added Australia's democratic election system. Current
  1.19.2 vanilla now contains context-aware election GUI consumers, while the
  generated object document independently confirms `GetLastElection`. Do not
  infer that every function or consumer was introduced by the same patch.

## File and language contract

For new files, keep all four aligned:

```text
path:   localisation/simp_chinese/MOD_feature_l_simp_chinese.yml
suffix: _l_simp_chinese.yml
header: l_simp_chinese:
bytes:  UTF-8 with BOM
```

Supported target languages must use their own directories, suffixes, headers,
and translated values. Common examples:

| Language | Directory/suffix/header token |
| --- | --- |
| English | `english` |
| Simplified Chinese | `simp_chinese` |
| Russian | `russian` |
| Japanese | `japanese` |

Each entry normally has one leading space and a quoted value:

```yaml
l_english:
 MOD_example: "Example text"
```

Preserve the target project's key-version convention. Both `key: "Text"` and
legacy `key:0 "Text"` exist in the ecosystem; do not rewrite a whole project
solely to match a template.

To override a small number of vanilla/dependency keys deliberately, define
only those keys in `localisation/<language>/replace/`. Do not copy a complete
vanilla localisation file when a narrow replacement is sufficient.

## Colours, line breaks, flags, and text icons

### Current vanilla colours

Open colour with `§<code>` and always close it with `§!`:

```yaml
 MOD_colour_example: "§CInformation§! and §Rdanger§! return to normal text."
```

The generic `textcolors` block in current `interface/core.gfx` defines:

| Code | Generic colour | RGB |
| --- | --- | --- |
| `§C` | cyan | `35 206 255` |
| `§L` | lilac/orange-gray | `195 176 145` |
| `§W` | white | `255 255 255` |
| `§B` | blue | `0 0 255` |
| `§G` | green | `0 159 3` |
| `§R` | red | `255 50 50` |
| `§b` | black | `0 0 0` |
| `§g` | light gray | `176 176 176` |
| `§Y`, `§H` | yellow/header | `255 189 0` |
| `§T` | white/title | `255 255 255` |
| `§O` | orange | `255 112 25` |
| `§0` | purple | `203 0 203` |
| `§1` | lilac | `128 120 211` |
| `§2` | blue | `81 112 243` |
| `§3` | gray-blue | `81 143 220` |
| `§4` | light blue | `90 190 231` |
| `§5` | dull cyan | `63 181 194` |
| `§6` | turquoise | `119 204 186` |
| `§7` | light green | `153 209 153` |
| `§8` | orange-yellow | `204 163 51` |
| `§9` | white-orange | `252 169 125` |
| `§t` | vivid red | `255 76 77` |
| `§!` | reset formatting | n/a |

Font-specific `textcolors` blocks can override appearance. Custom colour keys
are one byte/character; a multi-character name is not a valid colour token.
Recheck `core.gfx` after updates.

Common failures:

- `Could not find coloring for character 'M'`: an invalid `§M` exists.
- A character-ID error can mean an invalid byte after `§`.
- Character ID `0` often means a bare `§` at the end of a value; search for
  `§"` and replace the intended close with `§!`.
- Missing `§!` can bleed formatting into later UI text.

### Newlines

Use `\n`; use `\n\n` for a blank line. Preserve intentional spacing from a
working consumer because some compact widgets clip long text.

### Flags

Prefer a scope function when dynamic localisation is supported:

```yaml
 MOD_country: "[ROOT.GetNameWithFlag]"
```

`@TAG` can display a static country flag in consumers that do not support
namespaces, but it cannot follow a dynamic scope.

### Text icons

`£name` resolves `GFX_name` from a loaded `.gfx` file:

```yaml
 MOD_cost: "£pol_power §Y50§!"
```

For a multi-frame text icon, `£name|1` selects a frame. The sprite definition
needs the correct frame count and current vanilla examples require
`legacy_lazy_load = no` for multi-frame text icons.

## Nested keys and internal parameters

### Reusing another localisation key

```yaml
 MOD_feature: "Feature name"
 MOD_feature_tt: "Unlocks §Y$MOD_feature$§!."
```

This legacy `$KEY$` form works in many consumers, but not every GUI tooltip.
If the dollar signs render literally, test scripted or bound localisation in
that consumer; use a direct key or inline fallback when the context cannot
support recursion.

To display a literal dollar sign, double it: `$$100`.

### Consumer-provided parameters

Some engine or bound-localisation consumers inject temporary parameters:

```yaml
 MOD_change: "Political power: $VAL|=+0$."
 MOD_bound_row: "§Y$LABEL$§!: $VALUE$"
```

`$VAL$`, `$LEFT$`, `$RIGHT$`, `$REASON$`, and similar names are not global
variables. They exist only when the owning effect, trigger, GUI widget, or
bound-localisation object supplies them. Pipe formatting after a `$PARAMETER$`
is consumer-specific; copy it from that consumer rather than assuming it has
the same rules as `[?variable|format]`.

## Formatted variables

### Base syntax and scope

```text
[?variable]
[?SCOPE.variable]
[?dynamic_variable@target|format]
[?variable_backed_scope.GetProperty]
```

Examples verified against installed docs and vanilla patterns:

```yaml
 MOD_counter: "Progress: [?MOD_progress|0]/100"
 MOD_party: "Support: [?party_popularity@democratic|%Y0]"
 MOD_modifier: "Modifier: [?modifier@MOD_example_modifier|.1%%+]"
 MOD_date: "Date: [?global.date.GetDateStringNoHourLong]"
 MOD_target: "Target: [?MOD_saved_country.GetNameWithFlag]"
```

The `?` distinguishes a variable or dynamic variable from an event target or
ordinary scope. Current vanilla also contains explicit forms such as
`[?var:SCOPE.variable]`; follow a working current consumer when `var:` is
required by that path.

Dynamic-variable targets are token-specific. Installed documentation confirms,
among others:

- `modifier@token` for a country/state modifier value;
- `leader_modifier@token` and `unit_modifier@token` in unit-leader scope;
- `party_popularity@ideology` or `@ruling_party`;
- `days_decision_timeout@decision_token`;
- `global.date`, localised through a `GetDateString*` property.

Never invent an `@target`. Find it in
`dynamic_variables_documentation.md` and verify the owning scope.

### Numeric format characters

Characters after `|` can be combined:

| Character | Effect |
| --- | --- |
| `*` or `^` | SI-style scaling such as `65.53K` or `1.50M` |
| `=` | show an explicit `+` or `-` sign |
| `0` to `3` | decimal places; the engine's fixed precision is at most 3 |
| `%` | multiply by 100 and append `%` |
| `%%` | append `%` without multiplying |
| `+` | good colouring: positive green, zero yellow, negative red |
| `-` | inverse colouring: positive red, zero yellow, negative green |
| colour code such as `Y`, `G`, `R` | static numeric colour |

The familiar example:

```text
[?modifier@my_modifier|.1%%+]
```

means one decimal place, append a percent sign without multiplying, and colour
positive values as good. The leading dot before `1` is a tolerated vanilla/Wiki
convention; the digit is the operative precision selector.

Important distinctions:

- Use `%` when the stored value is a ratio such as `0.15` and should display as
  `15%`.
- Use `%%` when the stored value is already `15` and should display as `15%`.
- Dynamic `+`/`-` colouring takes precedence over a static colour.
- If overlapping format rules are combined, the engine can prioritise the
  later or stronger rule. Keep combinations short and test negative, zero,
  positive, fractional, and large values.

## Scope objects and functions

Namespaces use square brackets and traverse a localisation scope object:

```yaml
 MOD_example: "[ROOT.GetNameDefCap] is led by [ROOT.GetLeader]."
```

`ROOT`, `THIS`, `FROM`, a country tag, state ID, saved event target, and a
variable-backed scope are not interchangeable. Trace the real caller.

### Current country properties

The installed `loc_objects_documentation.md` confirms these high-use country
properties in 1.19.2:

| Property | Meaning |
| --- | --- |
| `GetName`, `GetNameDef`, `GetNameDefCap` | current country name variants |
| `GetNameWithFlag`, `GetFlag` | name with flag, or flag only |
| `GetAdjective`, `GetAdjectiveCap` | adjective variants |
| `GetLeader` | current country leader name |
| `GetRulingParty`, `GetRulingPartyLong` | ruling party name variants |
| `GetRulingIdeology`, `GetRulingIdeologyNoun` | ideology adjective/noun |
| `GetPartySupport` | ruling-party support |
| `GetLastElection` | date of the country's last election |
| `GetFactionName` | current faction name |
| `GetAgency` | intelligence agency name |
| `GetPowerBalanceName`, `GetActiveRangeName` | balance-of-power names |
| `GetPowerBalanceModDesc`, `GetActiveRangeModDesc` | generated modifier text |

The user-facing pattern is valid when `ROOT` is a country and the consumer is
dynamic:

```yaml
 MOD_last_election: "Last election: [ROOT.GetLastElection]"
```

`GetLastElection` is present in the current installed object documentation even
though a direct current vanilla `.yml` consumer was not found in the audited
snapshot. Treat it as engine-supported but consumer-sensitive and perform an
in-game test in the target event, decision, focus, or context-aware GUI.

### Promotions and other objects

Promotions move to another object before reading a property:

```yaml
 MOD_capital: "Capital: [ROOT.Capital.GetName]"
 MOD_overlord: "Overlord: [ROOT.Overlord.GetNameWithFlag]"
 MOD_pronoun: "[ROOT.GetLeader.GetSheHeCap]"
```

Other current patterns include:

```yaml
 MOD_state: "State: [123.GetName]"
 MOD_character: "[ROOT.MOD_character.GetFullName]"
 MOD_mio: "[?MOD_mio_variable.GetName]"
 MOD_today: "[GetDateText]"
 MOD_saved_date: "[?MOD_saved_date.GetDateStringNoHour]"
```

Character ownership, saved targets, dynamic countries, civil wars, and nullable
objects can change which promotion is valid. Guard optional objects in script
or use a documented contextual fallback. Context-aware localisation may support
`[(OBJECT ? TRUE_CASE : FALSE_CASE)]`; this is localisation syntax, not a PDX
trigger, and only works where that context object exists.

## Dynamic-consumer boundaries

If a consumer does not support dynamic localisation, square-bracket expressions
can appear literally. Support is not a property of the key alone.

High-value rules:

- Event text, decision text, and many effect/trigger tooltips commonly provide
  a scope, but still verify the exact caller.
- Focus descriptions refresh dynamically. A focus title may require the
  current documented `dynamic` behavior to refresh after initial evaluation.
- Ideas and dynamic modifiers have their own version-specific support.
- A custom GUI needs the matching scripted-GUI attachment and `context_type`.
- `context_aware_text` and `context_aware_tooltip` need an owner that supplies
  a localisation context.
- Custom modifier tooltips are not equivalent to custom effect/trigger
  tooltips and may not support the same scripted localisation.
- A function that exists in object documentation can still be wrong when the
  current scope object is not of the required type.

## Scripted, bound, and context-aware localisation

### Scripted localisation

Use ordered branches with an unconditional fallback:

```pdx
defined_text = {
	name = MOD_status_text
	text = {
		trigger = { has_country_flag = MOD_status_ready }
		localization_key = MOD_status_ready
	}
	text = {
		localization_key = MOD_status_default
	}
}
```

Call it only from a consumer that supports dynamic localisation:

```yaml
 MOD_status_line: "Status: [MOD_status_text]"
```

The topmost true branch wins. Keep frequent triggers cheap and always provide a
fallback so missing state does not produce an empty or debug string.

### Bound localisation

Paradox introduced bound localisation so script can bind named parameters to a
key without adding hardcoded source-code replacements:

```pdx
bound_tooltip = {
	localization_key = MOD_bound_row
	LABEL = MOD_label
	VALUE = "25"
}
```

It is recursive in supported consumers:

```pdx
bound_tooltip = {
	localization_key = MOD_bound_row
	LABEL = MOD_label
	VALUE = {
		localization_key = MOD_coloured_value
		DATA = "25"
	}
}
```

Use `context_aware_tooltip` or `context_aware_text` when the owning GUI supplies
the required localisation objects. All GUI types may parse `bound_tooltip`, but
contextual functions still depend on source-provided context.

## Localisation formatters

Formatter syntax is `<formatter>|<token>`, optionally wrapped in a bound object
with parameters:

```pdx
custom_effect_tooltip = {
	localization_key = building_state_modifier|dam
	INDENT = " "
}
```

Current installed 1.19.2 documentation lists:

| Formatter | Result / requirements |
| --- | --- |
| `advisor_desc|character` | advisor description; country object required |
| `building_state_modifier|building` | state modifiers; supports `INDENT` |
| `character_name|character` | character name |
| `country_culture|token` | country-specific `TAG_token` fallback; country required |
| `country_leader_desc|character` | leader description; `IDEOLOGY` required, `INDENT` optional |
| `idea_desc|idea` | idea description; country required |
| `idea_name|idea` | idea name; country required |
| `tech_effect|technology` | technology effects; country required |

Do not invent formatters or parameters. Re-read the target installation's
formatter document after every game update and find a current consumer.

## Four-language authoring workflow

1. Define a stable key set before translation.
2. Create English, Simplified Chinese, Russian, and Japanese files with matching
   keys and language identity.
3. Translate prose only. Preserve identifiers and every dynamic token exactly.
4. Check fonts and layout for CJK and Cyrillic text; a semantically correct
   value can still clip in a narrow GUI.
5. Scan missing/extra keys by language and same-language collisions across all
   loaded mods.
6. Test values with negative, zero, positive, fractional, and large numbers;
   valid and missing scopes; long names; and each supported language.

Use the builder's `assets/templates/localisation-advanced/` files as copyable
examples. Replace every `MOD` placeholder and define every referenced modifier,
icon, bound parameter, and consumer.

## Validation and diagnostics

Run both the general validator and focused audit:

```powershell
& <PDX_SKILL>/scripts/validate-hoi4.ps1 -ModRoot <MOD_ROOT> -All
& <REVIEW_SKILL>/scripts/audit-localisation.ps1 -ModRoot <MOD_ROOT>
```

Then inspect fresh `text.log` and `error.log`. Search for:

- duplicate/overlapping localisation keys;
- missing or invalid colour characters;
- unresolved keys or debug strings;
- literal `$KEY$`, `[Scope.GetProperty]`, or `[?variable|format]` output;
- missing text-icon sprites;
- wrong headers, suffixes, directories, or UTF-8 BOM;
- invalid scope objects and missing scripted-localisation fallbacks.

Current console documentation includes `loc_check*` commands, but their exact
names and availability are build-sensitive. Use the target installation's
console documentation rather than relying on an old command list.

Static validation cannot prove rendering, refresh timing, scope availability,
line wrapping, font coverage, or GUI context. Test the actual consumer in-game
after obtaining user consent for AI-controlled runtime testing.
