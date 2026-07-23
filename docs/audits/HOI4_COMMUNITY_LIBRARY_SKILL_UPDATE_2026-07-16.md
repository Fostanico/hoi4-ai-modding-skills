# HOI4 community library skill update - 2026-07-16

## Scope

Reviewed Steam Workshop item `3445449478` at:

`D:/SteamLibrary/steamapps/workshop/content/394360/3445449478`

The library contains 3,318 files in 427 directories and is approximately
2.47 GB. It combines community tutorials, PDX examples, templates, documents,
archives, and bundled third-party programs/runtimes.

## Safety result

- Microsoft Defender was enabled with real-time protection enabled.
- Security intelligence version: `1.455.168.0`, updated 2026-07-16 11:20:43.
- A custom scan of the complete Workshop item reported no threats.
- No `.exe`, `.dll`, `.pyd`, `.py`, `.pyc`, macro, installer, or bundled tool
  was executed or imported.

The scan result lowers immediate concern but does not certify every bundled
program. The project adopted documentation concepts only, through independent
rewriting and current-vanilla verification.

## Review result

Useful material covered events, decisions, focuses, characters, history,
scripted triggers/effects, on_actions, GUI/map modes, collections, diplomacy,
factions, equipment, doctrines, MIOs, and multi-file packages. The collection
also contains old-version fragments and named-mod-specific code.

Rejected claims include:

- country-history `capital` as a province ID; current vanilla uses a state ID;
- `trigger` and `is_triggered_only` as an unconditional either/or choice;
- collection elements as inherently non-duplicating;
- any advanced package not yet verified against installed documentation and a
  current 1.19.2 consumer.

## Added resources

- 13 copyable single-file skeletons in
  `.agents/skills/hoi4-content-builder/assets/templates/`;
- a focus -> event -> national spirit package in
  `.agents/skills/hoi4-content-builder/assets/kits/focus-event-idea/`;
- workflows for core content, map/history, and template promotion;
- a template catalog mapping every skeleton to installed documentation and a
  current vanilla consumer;
- a community-library audit recording safety, provenance, adopted structure,
  and rejected material.

## Vanilla verification baseline

Verified against installed Hearts of Iron IV Operation Postern 1.19.2.0 (d245)
on 2026-07-16. Representative sources include:

- `events/AAT_Generic_Events.txt`;
- `common/decisions/_documentation.md`, `common/decisions/AFG.txt`, and
  `common/decisions/categories/AFG_decision_categories.txt`;
- `common/national_focus/afghanistan.txt`;
- `common/ideas/afghanistan.txt`;
- `common/characters/_documentation.md` and `common/characters/AFG.txt`;
- `common/on_actions/_documentation.md` and `common/on_actions/00_on_actions.txt`;
- `common/scripted_effects/00_scripted_effects.txt` and
  `common/scripted_triggers/00_diplo_action_valid_triggers.txt`;
- `history/countries/GER - Germany.txt` and
  `history/states/64-Brandenburg.txt`;
- `interface/goals.gfx`, `interface/decisions.gfx`, and
  `interface/eventpictures.gfx`.

The new resources are structurally and statically checked starting points.
They are not runtime proof for content copied into a real mod, especially for
map/history, scopes, GUI/GFX, DLC-gated consumers, and global update cadence.
