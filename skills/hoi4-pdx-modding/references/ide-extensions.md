# Installed HOI4 editor extensions

Mined 2026-08-31 from the Cursor installs of:

- CWTools / Paradox Language Services `tboby.cwtools-vscode` 0.10.31 (MIT,
  Dayshine / cwtools), plus companion `tboby.paradox-syntax` 0.1.18
- HOI4 Mod Utilities `chaofan.hoi4modutilities` 0.17.2 (MIT, Chaofan Yang)
- HOI4 Modding Tools `uc-moddingutilities.hoi4-modding-tools` 2.5.5 (MIT,
  Olander)

The VS Code copies of the same versions were identical for Mod Utilities.
These extensions help a human in the editor. They are not a second engine and
not a substitute for installed vanilla documentation.

## What each tool is for

| Need | Use | Do not treat as |
| --- | --- | --- |
| P-language scopes, accepted fields, folder index, cheap diagnostics | CWTools + [pdx-language.md](pdx-language.md) | Engine authority; copyable `.cwt` |
| Preview focus / tech / event / MIO / GUI / world map / DDS / TGA | Mod Utilities | A writer of new PDX |
| Search, loc hover, log watcher, map ID checklist, loc colour palette | Modding Tools analysis panels | Its country/OOB/GUI generators or static wiki DB |

Route implementation through the existing templates and vanilla consumers.
Use the IDE for visual QA and to catch typos the validator scripts do not see.

## CWTools

Set `cwtools.cache.hoi4` to the installed game root and regenerate the vanilla
cache after a HOI4 update. Rules version `latest` is what this install used
(config revision `ab1fda2`, 2026-07-25).

Useful commands: cache vanilla, reload rules, output errors, generate
localisation stubs. After generating loc stubs, strip any `:0` suffix and
convert to this project's `key: "Text"` form before commit.

Limitations recorded by the config itself:

- `var:` / `temp_var:` / `token:` / `array^i` often show as false problems.
- Unclosed braces, `RGB`, and some `/\&` sequences break whole-file
  validation.
- Opening vanilla shows thousands of problems. Ignore them.
- Experimental mode is on by default in this extension build.

Language defaults insert tabs in PDX and UTF-8 BOM for YAML. The tab default
matches this skill's new-PDX preference. The loc stub default does **not**.

Do not vendor the 111 `.cwt` files into the mod or the skill. The distilled
grammar lives in `pdx-language.md`. If a field is missing from CWTools, look
in installed documentation and a vanilla consumer, then add a skill note
rather than editing the user's global rules folder from a task.

## HOI4 Mod Utilities

Preview-only for this workflow. It tokenizes PDX itself (comments, symbols,
`{=}<>`, quoted strings) and honors `replace_path` plus `integrated_dlc`.
Localisation indexing strips a trailing `:N` then parses YAML, so both
`key: "Text"` and vanilla `key:0 "Text"` are readable.

Use it to preview:

- national focus trees, including shared/joint focus;
- technology folders;
- event graphs (feature-flagged);
- MIO organisations;
- `.gui` windows;
- world map states/regions/provinces;
- `.gfx` sprites and `.dds`/`.tga` textures.

`enableSupplyArea` is a ≤1.10 compatibility switch. Leave it off on 1.19.2.
Scan References only injects event/localisation header comments for event
previews; it is not a general go-to-definition.

## HOI4 Modding Tools

Keep the analysis surface. Quarantine the generators.

Promoted after vanilla checks:

- Localisation colour codes match `interface/core.gfx` (`§R`/`§G`/`§B`/
  `§Y`/`§H`/`§C`/`§O`/`§L`/`§W`/`§T`/`§b`/`§g`/`§0`–`§9`/`§t`/`§!`).
- News event pictures in current vanilla are 397×153.
- Vanilla `map/provinces.bmp` is 5632×2048.
- Debug log search order (gamePath `logs/`, then
  `Documents/Paradox Interactive/Hearts of Iron IV/logs`) matches this
  project's log location.
- Map validator categories (definition.csv IDs, state↔province orphans,
  region coverage, buildings/supply/adjacencies) overlap the existing map
  audit script; use the script as the portable check.

Rejected or quarantined:

- README still advertises HOI4 1.14+.
- `hoi4loc` `firstLine` omits `l_simp_chinese`. Simplified Chinese files in
  this project remain valid; the highlighter may not attach.
- Default country-event picture size **250×135 is wrong for 1.19.2**.
  Current vanilla `gfx/event_pictures/report_event_*.dds` files are 210×176
  (some 209×176). News 397×153 is correct. Copy the vanilla report size, not
  the extension default.
- Country wizard emits `create_country_leader` and English `key:0` loc.
  Ignore it; use `assets/templates/character.txt` and the loc templates.
- Script library examples that put display strings in `set_party_name`, use
  `create_corps_commander`, or `TAG = { add_to_faction = ROOT }` are not
  current-safe.
- Static wiki/docs panels (~200 entries, many version-tagged 1.0/1.5) are
  incomplete for 1.19. Query installed `documentation/` instead.
- Performance "daily check" estimates (20k/50k, 200-country model) are
  heuristics. Keep the existing performance skill's cadence rules.
- Do not run Git revert, map MCP, or in-place map writers from an agent task
  unless the user explicitly asked and the work is staged.

## Operating rule

When the user already has these extensions, prefer:

1. Read vanilla + skill templates.
2. Optionally glance at CWTools diagnostics on the edited files as a cheap
   extra lint, then discard false positives listed above.
3. Ask for a Mod Utilities preview when a focus, tech, GUI, or map layout
   change is user-visible.
4. Never paste extension generator output into the mod without a full
   vanilla-shaped rewrite.
