# System coverage and routing

Use this map to turn any requested feature into the right workflow and proof.

| Area | Typical objects | Primary references/resources | Minimum runtime proof |
| --- | --- | --- | --- |
| Mod foundation | `.mod`, `descriptor.mod`, roots, dependencies | base `project-structure-history.md`, descriptor template | launcher loads exact mod |
| Countries and map | tags, definitions, history, states, OOB, bookmarks | country scaffold, map workflow | earliest bookmark loads and ownership is correct |
| Narrative | events, decisions, focuses, ideas, characters | core templates and focus-event-idea kit | entry, choice, effect, expiry |
| Economy/military | equipment, variants, OOB, MIOs, doctrines, names | base content and military references | content spawns and AI can use it |
| Advanced projects | scientists, facilities, special projects, raids | advanced workflow and verified templates | full prepare/start/outcome lifecycle |
| AI | strategy plans, equipment designs, division templates | AI reference and templates | observer/debug evidence of selection |
| Diplomacy/factions | actions, rules, goals, templates, peace logic | diplomacy reference and templates | sender/recipient/war/peace branches |
| UI and map modes | GUI/GFX, scripted GUI, focus inlays, map modes | GUI reference, modal kit, advanced workflow | callbacks, refresh, reload, resolutions |
| Localisation/media | text, sprites, textures, models, music, sound | GUI/media references and asset templates | no missing links; visible/audible result |
| Compatibility | dependency gates, exact overrides, `replace_path` | advanced engineering, version migration | isolated target dependency matrix |
| Quality/release | logs, performance, encoding, packaging | review skill, test and release workflows | clean targeted test and reproducible archive |

## Progression

Beginner work uses a verified template, one clear caller, and one acceptance
path. Intermediate work spans several object types and adds AI, lifecycle, and
compatibility. Advanced work defines explicit state machines, save migration,
performance budgets, dependency matrices, version gates, and automated audits.

Complexity never relaxes evidence requirements. Advanced developers may replace
the provided architecture, but must preserve scope contracts, current-build
proof, cross-file wiring, and reproducible tests.
