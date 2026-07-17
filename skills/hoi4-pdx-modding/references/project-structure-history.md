# Project structure, countries, and history

## Contents

- Resolve the loaded project
- Bound the requested change
- Prove country and character references
- Distinguish state and province IDs
- Edit history and map data safely
- Validate the dependency chain

## Resolve the loaded project

Treat the folder containing `descriptor.mod` as the content root, but also
inspect the launcher-side `.mod` file and the active playset. The launcher file
can point somewhere other than the current checkout, while `descriptor.mod`
can describe dependencies without proving they were active in the last run.

Before editing:

1. Resolve the user-provided path and locate `descriptor.mod`.
2. Find the corresponding launcher `.mod` entry and verify its `path`.
3. Inspect `dlc_load.json` when dependencies or load order affect identifiers.
4. Read every `replace_path` in the target and enabled dependencies.

`replace_path` removes the lower-priority database path from the effective load
set. Treat it as a broad compatibility boundary, not a convenient way to make
one file win. Never add or widen it without inventorying the complete replaced
path and testing the intended playset.

Never edit the installed vanilla tree. Read it as evidence and write only to
the intended mod root.

## Bound the requested change

Turn the literal request into an authorized-system list and exact file plan
before writing. A new mod folder does not automatically authorize country
definitions, state history, initial units, characters, technologies, GUI, or
extra localisation languages.

For every planned file, record:

- why the requested feature needs it;
- the runtime caller or loader that reaches it;
- the entry scope and any `ROOT`/`FROM` contract;
- referenced IDs, localisation keys, sprites, and assets;
- whether the file adds content or overrides an existing database object.

Do not create empty placeholders. If a new file becomes necessary after work
starts, prove the runtime dependency before adding it.

## Prove country and character references

Resolve a country TAG from local data, not from display text or a feature
prefix. Search the target, enabled dependencies, and current vanilla in this
order:

```text
localisation/*/<language files>
common/country_tags/
common/countries/
history/countries/
```

Reusing an existing TAG for new focuses, decisions, events, or ideas does not
require redefining the country. Create or override country registration and
history only when the request actually changes country setup.

For current-style leaders and advisors, verify the character definition under
`common/characters` and the real recruitment path, commonly
`recruit_character` in country history or a scripted lifecycle effect. Follow
the enabled dependency's working style when it replaces these databases.

## Distinguish state and province IDs

State IDs and province IDs are different namespaces.

- `history/states/*.txt` declares `state = { id = <state_id> ... }`.
- The state's `provinces = { ... }` list contains province IDs.
- `victory_points = { <province_id> <value> }` uses a province ID.
- Province-scoped building entries inside a state use a province ID as the key.
- In current vanilla country history, `capital = <state_id>` uses a state ID.

Do not infer either ID from a place name, translated localisation, a focus
title, or memory. Verify the state file and, for province facts, the state's
province list or `map/definition.csv`. A matching integer in both namespaces is
not evidence that the intended object was selected.

## Edit history and map data safely

Country and state history affect start-date setup and have a wider compatibility
surface than runtime focuses, events, or decisions.

- Search the whole load set for the TAG or state ID before overriding it.
- Preserve date blocks and DLC branches that are unrelated to the request.
- Verify owner, controller, cores, claims, buildings, resources, victory points,
  OOB references, and recruited characters across their real definitions.
- Avoid copying a complete vanilla state file merely to grant a runtime reward.
  Prefer a state-scoped effect when the design is a gameplay-time change.
- Edit `history/states` directly only for verified start-date or map setup work.
- Treat `map/definition.csv`, province bitmaps, strategic regions, supply data,
  and state province lists as one coupled map system. A partial edit can cause a
  load failure or CTD even when PDX braces are balanced.

## Validate the dependency chain

For country/history/map changes, add these checks to the normal validator:

1. Confirm the launcher path, mod root, active playset, and `replace_path` set.
2. Search for duplicate TAG registrations, state IDs, character IDs, and
   competing history overrides.
3. Prove every capital state ID, victory-point province ID, OOB, character,
   idea, technology, sprite, and texture against the effective load set.
4. Check localisation and flags without claiming absent assets exist.
5. Inspect the newest `error.log` from the intended playset.
6. Test the relevant bookmark/start date, country selection, ownership, capital,
   recruited characters, and save/reload behavior in game.

Static evidence can prove ID wiring and file shape. It cannot prove that the
intended playset loads the same override winner or that map/history state is
correct at runtime.
