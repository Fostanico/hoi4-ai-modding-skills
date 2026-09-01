# Community tutorial library audit

Reviewed on 2026-07-16 through 2026-07-17, then re-mined on 2026-08-31 from
Steam Workshop item `3445449478`. This audit records provenance; the distributed
skills do not depend on a local Workshop cache.

The item identifies itself as 秋起图书馆 / 霜泽图书馆, a community HOI4 modding
tutorial and code collection. Its descriptor targets HOI4 `1.19.2.0`; its
changelog records material from multiple dates and older game versions,
including 2026-06-30, 2026-07-01, 2026-07-31, and 2026-08-22 refreshes that the
first pass did not absorb as copyable templates.

The 2026-08-31 pass read the `资料` tree (templates, tutorials, special cases,
adaptation guides, advanced GUI/defines/shader/variable material), extracted
DOCX/PDF text, and verified contested claims against installed Operation
Postern 1.19.2.0 (d245). Binary tools were not launched. RHoiScribe in the
library is a GitHub/Patreon redirect, not a skill payload.

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
- After the 2026-08-31 remine, independently reconstruct buildings, BOP,
  abilities, combat tactics, opinion modifiers, scripted diplomatic actions,
  diplomacy enable triggers, AI areas, reversed AI, equipment modules,
  equipment variants, map modes, custom achievements, laws, land OOB, land
  sub-units, operations, joint/continuous focuses, subdoctrines, MTTH values,
  missions, advisor-capable characters, unit-leader traits, intelligence-agency
  upgrades, focus inlays, and faction member upgrades from current vanilla
  consumers.

All adopted structures were rewritten and checked against installed vanilla
1.19.2 documentation and consumers. No community code is treated as engine
authority.

## Absorbed coverage map

The material library is now represented inside the skills rather than requiring
future reads from the Workshop tree:

| Material family | Skill-owned destination |
| --- | --- |
| PDX scopes, variables, arrays, collections, math, dynamic modifiers, scripted localisation, variable tooltips, MTTH values | base `pdx-script.md`; builder `advanced-patterns.md` and templates |
| Events, decisions, missions, focuses, joint/continuous focuses, ideas, laws, characters, scientists, on_actions | base `content-objects.md`; builder workflows, templates, and kits |
| Country/history, OOB land/air, state/province IDs, flags, dynamic naming, country-color saturation | base `project-structure-history.md`; builder map/history workflow and country scaffold |
| Equipment, modules, variants, technologies, MIOs, doctrines, subdoctrines, special projects, raids, operations, agency upgrades, combat tactics, abilities, BOP, buildings, unit-leader traits, AI templates/strategies/areas | base `content-objects.md`, `ai-and-military-content.md`, `aces-operatives.md`, and `vanilla-documentation-map.md` |
| GUI, GFX, focus inlays, map modes, sprites, music-station faceplates | base `gui-localisation.md`, `media-models-shaders.md`; modal/background kits, focus-inlay template, and GFX generator |
| Diplomacy enable triggers, scripted diplomatic actions, opinion modifiers, factions, member upgrades, peace conferences | base `diplomacy-factions-assets.md` |
| Custom achievements | base `content-objects.md`; builder `achievement.txt` |
| Music, sound, models, animations, shaders, textures | base `media-models-shaders.md`; music kit and model templates |
| Logs, performance, map integrity, version adaptation | base `performance-debugging.md` and `version-migration.md`; review scripts and workflows |
| Community-tutorial false claims | review `field-tested-pitfalls.md` |

This is a routing map for content already distilled into the skills, not an
instruction to query the external library during normal mod work.

## Rejected or quarantined

- old-version fragments and templates tied to total conversions or named mods;
- a country-history claim that `capital` takes a province ID; current vanilla
  uses a state ID. The library is internally inconsistent on this point;
- an event claim that `trigger` and `is_triggered_only` are always mutually
  exclusive;
- invented advisor slots `navy_command` / `air_command`;
- path typos `ideas_tag`, `MOD/scripted_localisation`, `allow_brunch`,
  `Reset_on_civilwarno`;
- an OOB `army_history` / `history_queue` block; current vanilla uses
  `add_history_entry`;
- a collection claim that elements cannot duplicate; collection semantics must
  follow the installed documentation and current consumers;
- a claim that military access cannot be blocked;
- Taylor-series arbitrary-base logarithms as a current default; use math `log`;
- `GetTokenKey` / `GetTokenLocalizedKey` as documented loc functions; they are
  absent from installed `loc_objects_documentation.md` and have no vanilla loc
  consumer in 1.19.2;
- swapped equipment glosses that call `hardness` 厚度 and `armor_value` 装甲率;
- invented combat-tactic phases; vanilla `phases` is a closed list in
  `common/combat_tactics.txt`;
- camera-define and country-color numbers copied from tutorials rather than
  `00_graphics.lua`;
- `DIPLOMACY_WAR_ENABLE_TRIGGER` presented as a shipped live vanilla trigger;
  the vanilla file only comments it;
- parliament, large decision-outlay, total-conversion GUI, TNO Admin_Title,
  TFR economy, CM/LRD super-event packages, Requiem shaders, and other
  packages that have not passed the template-verification workflow;
- recursive scripted-localisation array printing as a vanilla-consumer
  verified pattern; it is empirical and can crash in bare event `desc`/`title`;
- direct copies of tutorial modifier/define tables and complete shaders; their
  exact contents are version- and consumer-sensitive, so only the verified
  lookup and migration workflows were absorbed;
- direct in-place output from tools whose writes have not been staged and
  diffed;
- RHoiScribe: the library only contains GitHub/Patreon redirects, not a
  skill payload.

The Workshop item does not provide a single clear license covering every
contributed file. Therefore these skills retain provenance notes, copy no
community template verbatim, and promote only independently reconstructed
skeletons whose code shape is supported by current Paradox files.

See the sibling base skill's `references/community-tool-index.md` for the
binary families, observed behaviors, archive/source notes, and exact safe
replacement mapping.
