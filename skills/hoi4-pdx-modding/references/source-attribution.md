# Source attribution and selection

This Codex skill set is an adapted, reduced version of general HOI4 development
guidance found in the Millennium Dawn repository's `.claude` directory. The
review covered every file under `.claude/rules`, `.claude/docs`,
`.claude/agents`, and `.claude/skills` in the local snapshot.

- Source project: [Millennium Dawn: A Modern Day Mod](https://github.com/MillenniumDawn/Millennium-Dawn)
- Source authors: Millennium Dawn Development Team and repository contributors
- Source license: [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/)
- Source snapshot: a locally reviewed checkout of the linked repository.
- Adaptation date: 2026-07-12
- Changes: converted Claude-specific routing to Codex `AGENTS.md` and agent-skill
  structure; condensed duplicated material; rewrote repository paths and
  workflows; removed Millennium Dawn-only systems, CI tooling, economy, UN,
  modern equipment, and project governance rules; added portable vanilla-based
  verification, templates, runtime testing, and release workflows.

## Coverage decisions

Adapted and generalized:

- PDX scopes, variables, arrays, math, events, decisions, focuses, ideas, MIOs,
  on_actions, scripted GUI/localisation, performance, refactoring, and reviews;
- event/focus construction, bug diagnosis, localisation review, lifecycle
  checks, adversarial review, simplification, and test planning workflows;
- AI strategy/equipment/templates, OOB/variants, name lists, diplomatic
  actions, factions, entities/landmarks, music, and sound after vanilla-based
  rewriting.

Deliberately excluded:

- Millennium Dawn economy and additional-income systems, energy balance, UN,
  custom modifiers, search-filter taxonomy, equipment/AI role inventories,
  country coverage tables, and modern-era data;
- Millennium Dawn profiling tools, repository CI/pre-commit commands, issue/PR
  and changelog automation, development-diary publishing, and Claude settings;
- numeric formulas or media-format rules that could not be reproduced from the
  current installed vanilla game.

The adapted material in this skill is provided under CC BY-SA 4.0. No claim is
made that the original Millennium Dawn team endorses this adaptation.

Conceptual claims should be checked against the community-maintained
[Hearts of Iron IV Wiki](https://hoi4.paradoxwikis.com/Modding), then verified
against the currently installed game's files because the wiki and source
snapshot can become outdated.

## Current official-source supplement

The 2026-07-13 update added a separate, original summary of Paradox's official
Steam news for Hearts of Iron IV from 2024-03-06 through 2026-07-07. See
`recent-official-modding-changes.md` for the entry-by-entry links and the
current-version verification status.

- Official feed: [Hearts of Iron IV Steam news](https://store.steampowered.com/news/app/394360)
- Local vanilla snapshot verified: Operation Postern 1.19.2.0 (d245)
- Local generated sources: installed `documentation/*.md` and
  `common/**/_documentation.md`
- Verification date: 2026-07-13

Steam news is used to discover additions, removals, deprecations, engine fixes,
and changed semantics. The installed generated documentation and working
vanilla files remain the authority for exact emitted tokens and nesting.
Paradox's patch-note text and code examples are paraphrased or reduced rather
than copied wholesale.

## Installed Markdown audit supplement

On 2026-07-13, the installed 1.19.2 tree contained 50 Markdown documents: 11
generated references under `documentation` and 39 database-adjacent documents
under `common`. They were inventoried and routed in
`vanilla-documentation-map.md`; exact high-value entries were checked against
current vanilla examples before being promoted into templates.

The audit also records documentation limitations instead of hiding them:
stale internal filenames, older “updated” dates, generated typos, modifiers
that are recognized but not necessarily consumed, release-only command
limitations, and a special-project design document containing explicit
TODO/TBD material. The installed files are Paradox source material; this skill
contains an original reduced map and paraphrased operational guidance, not a
copy of those manuals.

## Community skill review supplement

On 2026-07-16, three downloaded community skill snapshots were security-
checked and reviewed as untrusted references before any content was adapted:

- [Kon-on/hoi4-modding-skill](https://github.com/Kon-on/hoi4-modding-skill),
  `master`, MIT, local archive `hoi4-modding-skill-master.zip`;
- [postigodev/hoi4-agent-skill](https://github.com/postigodev/hoi4-agent-skill),
  `v0.2.0`, MIT, local archive `hoi4-agent-skill-0.2.0.zip`;
- [zhangxiaoyu66666/hoi4skill](https://github.com/zhangxiaoyu66666/hoi4skill),
  `v0.30.1`, GPL-3.0-only, local archive `hoi4skill-0.30.1.zip`.

Each local archive matched the SHA-256 of the corresponding GitHub branch or
tag archive. The first two archives contained documentation and small PDX
examples. The third contained a large Rust CLI source tree with local process,
PowerShell UI automation, screenshot, Git, and file-removal capabilities. It
was not installed, compiled, or executed, and no Rust source or GPL text was
copied into this skill.

The review contributed only generalized, independently rewritten workflow
ideas: resolve the actual mod root, limit edits to requested systems, require
local evidence for country/resource IDs, distinguish start-date history from
runtime effects, and treat `replace_path` and map/history work as high risk.
Every engine claim was rechecked against portable target-project rules and installed
vanilla 1.19.2 files.

Version-locked or conflicting claims were deliberately excluded. In
particular, the first snapshot targets 1.18.2 and uses localisation conventions
that conflict with current vanilla. Both the first and third snapshots describe
country-history `capital` as a province ID; current vanilla 1.19.2 demonstrates
that it is a state ID, while state `victory_points` use province IDs. The third
snapshot's CLI-only generation contracts were also not imported because this
project uses its existing Codex skills and validator.

## Community tutorial library supplement

On 2026-07-16, Steam Workshop item `3445449478` was reviewed from the local
Workshop cache. The item identifies itself as a community HOI4 modding tutorial
library and targets `1.19.2.0`, but it also contains older examples, material
for named total-conversion mods, third-party programs, and packaged runtimes.

A Microsoft Defender custom scan of the 2.47 GB tree reported no threats with
signature version `1.455.168.0`. No target executable, macro, DLL, or installer
was launched. Archives and PyInstaller content were inspected statically in a
temporary directory. The library did not expose one unambiguous
license covering every contributed file, so no community template or prose was
copied verbatim.

The review led to an independently reconstructed set of copyable templates,
one multi-file kit, and explicit verification workflows in the sibling
`hoi4-content-builder` skill. Each promoted skeleton was checked against the
installed Operation Postern 1.19.2.0 documentation and a current vanilla
consumer. See that skill's `references/community-library-audit.md` and
`references/template-catalog.md` for the precise safety, provenance, evidence,
and rejection record.

One source subdirectory, `HoI4ModdingPythonScripts-master`, declares the MIT
license and Copyright 2017 Antoni Baum (Yard1). It was reviewed for algorithms
only; its old Python, localisation forms, naive brace insertion, and direct
overwrite operations were not copied. The new PowerShell utilities are
independent implementations.

The GPL-3.0-only
[`pyinstxtractor-ng`](https://github.com/pyinstxtractor/pyinstxtractor-ng)
project was downloaded from PyPI into a temporary analysis directory and used
solely to statically unpack one PyInstaller executable. Neither that extractor
nor extracted third-party bytecode is distributed with these skills.
