# Absorbed community capabilities and provenance

Audited 2026-07-16 through 2026-07-17 from Steam Workshop item `3445449478`.
The source tree
contains 41 executables, packaged DLL/PYD runtimes, 19 archives, source scripts,
and advanced PDX examples. The community project is treated as a trusted input
library; current vanilla remains the authority for engine code.

During the initial audit, target executables were inspected without launching
them and archives were extracted only after path-traversal checks. Tools may be
run in later tasks when they materially help, after the specific executable and
its inputs/outputs receive the normal source/hash, Defender, and behavior check.

The temporary extractor was
[`pyinstxtractor-ng`](https://github.com/pyinstxtractor/pyinstxtractor-ng)
`2026.4.7`; its downloaded wheel SHA-256 was
`DF23D7E6231645A128650B418C27630E3B6AFBC73B3EF6292C68963683E421FE`.
It is GPL-3.0-only and is not included in these skills.

## Absorbed capability map

Routine work should start from the skill-owned resource in the last column.
The Workshop item is provenance, not a runtime lookup dependency.

| Need | Community source idea | Skill-owned implementation |
| --- | --- | --- |
| Compare `error.log` runs | Aenyrag log analyzer set comparison | `hoi4-review-debug/scripts/analyze-hoi4-log.ps1` |
| Audit map IDs and ownership | MapGen, HOI4MapMaker, state/region utilities | `hoi4-review-debug/scripts/audit-hoi4-map.ps1` |
| Generate GFX registrations | icon/GFX utilities and Python scripts | `hoi4-content-builder/scripts/generate-gfx-manifest.ps1` |
| Generate a country skeleton | country and character generators | `hoi4-content-builder/scripts/new-country-scaffold.ps1` |
| Create focus, event, and idea content | zero-code editors and event generators | verified templates and `kits/focus-event-idea` |
| Pass a target state into an event | event-target and targeted-decision tutorials | `kits/targeted-state-event` and `event-target-caller.txt` |
| Use arrays and collections | variable/array/collection tutorials | `array-effects.txt` and `collection-effect.txt` |
| Use variable modifiers and dynamic text | variable and scripted-localisation tutorials | `dynamic-modifier.txt` and `scripted-localisation.txt` |
| Rename states/provinces | dynamic-renaming examples | `state-name-effect.txt` |
| Build a custom modal GUI | KR welcome window and super-event examples | `kits/scripted-gui-modal` |
| Convert flags or media | flag creators, MP4-to-OGG, stitchers | run the checked tool in staging; validate dimensions/codec before import |
| Edit shaders or dynamic-list GUI | shader editor and advanced GUI packages | current-version research path; requires exact consumer verification and in-game test |

## Binary families

| Family | Representative executables | Disposition |
| --- | --- | --- |
| Logs and generic text | `HOI4日志分析工具.exe`, zero-code localisation/event/formatter tools, folder comparer | static reference only; use safe replacements |
| Map | MapGen 2.2, HOI4MapMaker, continent split, province deployment/sort, victory-point localisation, strategic-region creation | do not run in-place; audit a complete copy first |
| Focus and GFX | zero-code focus tree tools, focus editor, icon registration, goals-to-shine, FTAT | generator output must be staged and diffed |
| Countries and people | country creation, flag tools, character generator, general generator, idea/ideology tools | verify every tag, state ID, character field, sprite and localisation key |
| GUI and advanced media | parliament GUI generator, interface registration, rainbow stitcher, MP4-to-OGG | quarantine executable; reconstruct only the needed output contract |
| Installers/runtime helpers | two Photoshop DDS installers, VulcanFlagCreator runtime, Microsoft `createdump.exe` | `createdump.exe` is the only valid Authenticode-signed executable; this does not endorse its parent package |

## Static behavior evidence

The PyInstaller log analyzer imports Tk/customtkinter, threads, filesystem,
subprocess, and platform modules. Its useful algorithm is set comparison:
`new - baseline`, `baseline - new`, and intersection. It also contains
recursive directory clearing, file deletion, `os.startfile`, and VS Code
launch paths. The replacement script keeps the comparison and priority
classification but removes deletion and process launch.

Extracted manpower and resource editors use regular expressions to replace or
insert root fields and overwrite the selected files. Building scripts count
braces or insert after the first matching token, which is not sufficient for
arbitrary nested PDX. The map audit therefore parses named brace blocks and
never writes source files.

`HoI4ModdingPythonScripts-master` is an MIT-licensed 2017 Python 2.7/3.5
collection. Its transfer-tech, localisation, GFX, formatter, election,
newspaper, and state-map algorithms are useful historical references, but its
localisation and object shapes are old and some scripts append, rename, or
overwrite directly. None is copied into the skill.

The parliamentary generator is UPX-packed Go; MapGen uses Qt/OpenCV; many
other tools are PyInstaller bundles with Python, Qt, NumPy, SciPy, or OpenCV
runtimes. These implementation fingerprints explain the DLL/PYD volume but do
not independently prove safety.

## Advanced-code quarantine

- The decision-outlay GUI implements a large decision engine with dynamic
  characters, variables, scripted effects/triggers/localisation, and a
  200-entry slider. It is an architectural study, not a drop-in template.
- The LRD/TFR super-event package depends on named-mod GFX, fonts, paths, and
  localisation conventions.
- The KR welcome-window pattern supports the idea of a player-context modal,
  but its code and assets were not copied. The local modal kit was independently
  rebuilt from current scripted-GUI documentation, working target-mod
  player-context GUI, and current vanilla sprites.
- No shader, parliament, total-conversion GUI, or direct map writer is promoted
  until its exact output is verified against current vanilla and tested in game.

## Operating rule

Use community tools when they save real work. For every newly downloaded
artifact, record source and SHA-256, check archive paths and signatures where
applicable, scan it, identify its write/launch behavior, and run it against a
staging copy first. Diff generated output, validate PDX/encoding/resource
links, and cross-check engine code against current vanilla before absorbing it.
