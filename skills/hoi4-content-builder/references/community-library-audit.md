# Community tutorial library audit

Reviewed on 2026-07-16 through 2026-07-17 from Steam Workshop item
`3445449478`. This audit records provenance; the distributed skills do not
depend on a local Workshop cache.

The item identifies itself as 秋起图书馆 / 霜泽图书馆, a community HOI4 modding
tutorial and code collection. Its descriptor targets HOI4 `1.19.2.0`; its
changelog records material from multiple dates and older game versions.

The `资料` subtree contains 282 files (about 384 MB): 152 under `基础代码`,
121 under `高级代码`, six adaptation-guide files, and three network-link
records. Its readable corpus includes 27 PDFs, 21 DOCX files, one legacy DOC,
one XLSX workbook, PDX/GUI/GFX/localisation examples, and seven archives.
The readable documents, archives, scripts, and representative adaptation-guide
pages were inspected during the audit.

## Safety boundary

The 2.47 GB tree contains tutorials and examples alongside packaged third-party
tools and runtimes, including `.exe`, `.dll`, `.pyd`, `.py`, `.pyc`, and archive
files. Microsoft Defender custom scanning reported no threats with signature
version `1.455.168.0`. The community project is accepted as a trusted source;
the per-artifact download check still applies before execution. In the initial
audit, all 19 archives were checked for absolute/parent-traversal paths and the
log analyzer was statically extracted and disassembled. Tools may be executed
in staging when a concrete task benefits from their functionality.

## Adopted as independently rewritten guidance

- organize frequently used skeletons separately from conceptual references;
- provide copyable multi-file packages for common dependency chains;
- make event, decision, focus, idea, character, history, trigger/effect,
  on_action, GFX, and localisation starting points easy to discover;
- explain identifier-type hazards and lifecycle/performance checks beside the
  workflow that needs them.
- provide read-only log comparison and cross-file map auditing instead of
  direct source rewriting;
- generate GFX manifests deterministically into a new output file;
- provide a current, asset-independent player-context modal GUI kit.
- provide verified collection, array, event-target, dynamic-modifier,
  scripted-localisation, state-renaming, and targeted-decision templates;
- provide a complete targeted-state event kit and staged country generator.
- provide a version-migration workflow and a read-only exact-override audit;
- provide current bookmark, selectable frontend-background, base-station music,
  model animation, and entity skeletons;
- route shader/model/media work through current consumers and runtime gates
  rather than presenting old tutorial programs as universal templates.
- guard optional dual scopes to prevent repeated `invalid event target` log
  noise, while treating ownerless/controllerless states as map defects.

All adopted structures were rewritten and checked against installed vanilla
1.19.2 documentation and consumers. No community code is treated as engine
authority.

## Absorbed coverage map

The material library is now represented inside the skills rather than requiring
future reads from the Workshop tree:

| Material family | Skill-owned destination |
| --- | --- |
| PDX scopes, variables, arrays, collections, math, dynamic modifiers, scripted localisation | base `pdx-script.md`; builder `advanced-patterns.md` and templates |
| Events, decisions, focuses, ideas, characters, scientists, on_actions | base `content-objects.md`; builder workflows, templates, and kits |
| Country/history, OOB, state/province IDs, flags, dynamic naming | base `project-structure-history.md`; builder map/history workflow and country scaffold |
| Equipment, technologies, MIOs, doctrines, special projects, raids, AI templates and strategies | base `content-objects.md`, `ai-and-military-content.md`, and `vanilla-documentation-map.md` |
| GUI, GFX, focus inlays, map modes, sprites | base `gui-localisation.md`; modal/background kits and GFX generator |
| Diplomacy, factions, peace conferences | base `diplomacy-factions-assets.md` |
| Music, sound, models, animations, shaders, textures | base `media-models-shaders.md`; music kit and model templates |
| Logs, performance, map integrity, version adaptation | base `performance-debugging.md` and `version-migration.md`; review scripts and workflows |

This is a routing map for content already distilled into the skills, not an
instruction to query the external library during normal mod work.

## Rejected or quarantined

- old-version fragments and templates tied to total conversions or named mods;
- a country-history claim that `capital` takes a province ID; current vanilla
  uses a state ID;
- an event claim that `trigger` and `is_triggered_only` are always mutually
  exclusive;
- a collection claim that elements cannot duplicate; collection semantics must
  follow the installed documentation and current consumers;
- parliament, large decision-outlay, total-conversion GUI, diplomacy,
  faction, equipment, doctrine, MIO, and other packages that have not passed
  the template-verification workflow;
- direct copies of tutorial modifier/define tables and complete shaders; their
  exact contents are version- and consumer-sensitive, so only the verified
  lookup and migration workflows were absorbed;
- direct in-place output from tools whose writes have not been staged and
  diffed.

The Workshop item does not provide a single clear license covering every
contributed file. Therefore these skills retain provenance notes, copy no
community template verbatim, and promote only independently reconstructed
skeletons whose code shape is supported by current Paradox files.

See the sibling base skill's `references/community-tool-index.md` for the
binary families, observed behaviors, archive/source notes, and exact safe
replacement mapping.
