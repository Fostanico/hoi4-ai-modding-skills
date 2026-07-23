# HOI4 community tool and advanced-code skill update

## Scope

Reviewed the programs, bundled runtimes, archives, Python sources, tutorials,
and advanced PDX/GUI examples in Workshop item `3445449478`. The community
project is accepted as trusted; engine code was still checked against installed
Hearts of Iron IV 1.19.2 documentation and current consumers.

## Added

- read-only log classifier and baseline comparator;
- read-only cross-file map/state/strategic-region audit;
- deterministic GFX and focus-shine manifest generator;
- asset-independent player-context modal GUI kit;
- verified collection, array, event-target, dynamic-modifier,
  scripted-localisation, state-renaming, and targeted-state templates;
- complete targeted-state decision to saved-target event kit;
- staged country scaffold generator with overwrite refusal;
- skill-owned capability map, with the Workshop tree retained only as
  provenance and optional tool source.

## Verification baseline

- Defender custom scan: no threat reported, signature `1.455.168.0`;
- executable signatures: 40 unsigned, one valid Microsoft `createdump.exe`;
- archive traversal: none found across 19 archives;
- vanilla map audit: 13,414 provinces, 1,081 states, 304 strategic regions,
  zero audit issues;
- GFX shape: current `interface/goals.gfx` and `goals_shine.gfx`;
- scripted GUI: current `common/scripted_guis/_documentation.md`, project
  player-context consumers, and current vanilla sprite registrations.

Static validation does not prove GUI interaction. The modal kit still needs a
real caller and an in-game open/close test after its `YZK` placeholders are
renamed. The targeted-state event kit likewise needs an in-game selection and
both-options test after its placeholders are replaced.

## PyYAML dependency

Installed PyYAML 6.0.3 into the local Python 3.12 and 3.14 environments from
official PyPI Windows wheels. Both wheel SHA-256 values matched PyPI metadata,
archive paths were safe, metadata identified the expected package/version and
MIT license, and Microsoft Defender reported no new threats. Installation was
performed offline from the verified local wheels.

## Material-library continuation

The `资料` subtree was inventoried separately: 282 files and about 384 MB,
including 27 PDFs, 21 DOCX files, one legacy DOC, one XLSX workbook, seven ZIP
archives, and extensive PDX/GUI/GFX/media examples. LibreOffice 26.2.4.2 was
found at `C:/Program Files/LibreOffice/program/soffice.com`; that console entry
successfully converted the old DOC for extraction. Representative pages of all
four PDF adaptation guides were also rendered and visually checked.

Added from this pass after current-vanilla verification:

- a version-migration reference and executable workflow;
- a read-only exact vanilla override and `replace_path` auditor;
- selectable frontend-background and base-music-track kits;
- current bookmark, model-animation, and entity templates;
- media/model/shader validation guidance;
- corrections replacing stale targeted-decision `state_trigger` advice with
  current `state_target = yes` plus `target_array` consumers.

The 1.17.4 background guide, NCNS migration guide, 1.15 migration guide, and
Thunder at Our Gates guide were used as discovery maps. Exact code was checked
against installed 1.19.2 files. This caught two important drifts: current
bookmarks support `label_order`, and current regimental support consumers use
`allowed_battalion_groups`, regimental categories, and `divisional = no`
rather than a guessed `regimental = yes` flag.

The new override audit found 20 current exact-path overrides. Its only
high-risk row was `common/special_projects/project_tags/tags.txt`; a direct
comparison showed that it currently retains the complete 1.19.2 vanilla list
and adds only `YZ_sp_tag_artillery` and `yz_sp_tag_type90`. It is not a current
blocker, but it must be re-merged after a game update.
