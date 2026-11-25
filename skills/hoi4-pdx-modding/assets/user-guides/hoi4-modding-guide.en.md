# General Guide to HOI4 Mod Development

[简体中文](hoi4-modding-guide.zh-CN.md) | English | [日本語](hoi4-modding-guide.ja.md) | [Русский](hoi4-modding-guide.ru.md) | [한국어](hoi4-modding-guide.ko.md)

A practical playbook for authors and maintainers building *Hearts of Iron IV* mods with AI. Describe gameplay in plain language or point straight at scripts, interfaces, and bugs. The practices below fit historical tweaks, alternate-history overhauls, character mods, and gameplay expansions alike, free of any single setting or machine-specific paths.

Treat the sample requests as patterns you can adapt to your own build, dependency stack, and saves. The internal technical references for the three skills are primarily in English, while this user handbook ships in five complete languages.

## 1. Set Up Your Workbench

Install all three skills together and keep their relative folder layout intact; see [Installation and Sharing](../../../../docs/INSTALLATION_EN.md) for per-client paths. Open your target mod and let the AI read the project guide plus the directly relevant files—small edits start locally rather than scanning the entire repo.

| What you want to do | Primary skill | Expected deliverable |
| --- | --- | --- |
| Turn an idea into a new feature or system | `hoi4-content-builder` | A playable, reachable feature with wired scripts, assets, and text |
| Edit scripts, localisation, UI, or compatibility code | `hoi4-pdx-modding` | Clean changes aligned with the target build and project conventions |
| Audit defects, tune performance, or migrate versions | `hoi4-review-debug` | Evidence-backed root causes and tightly scoped repairs |

Compatible clients can pick the right skill automatically, or you can name one directly when you want a fixed workflow. Skills supply the engineering discipline and references; file edits, shell commands, network access, and live game control come from your client and any enabled MCP server (`hoi4_local` for read-only local evidence, and optional `hoi4_desktop` when you want authorized in-game testing).

A solid first prompt looks like this:

> Add an “Industrial Assistance” decision to the current mod: the player spends 50 political power for a 30-day production bonus. Hide repeat purchases while active, and unlock it again once it expires. The AI should consider it only at war. Preserve existing dependencies and cover every language the project supports. Read the relevant project docs and vanilla examples first, implement the feature, and run static checks on changed files. Hold off on launching the game or committing.

Swap the numbers and rules for your own design; let the AI verify the exact PDX implementation against your installed build.

## 2. Describe Checkable Behavior

A few clear sentences cover most requests. For larger systems, fill in any details the AI cannot infer from the codebase:

| Dimension | Helpful details to specify |
| --- | --- |
| Goal | New mod, existing-feature edit, feasibility study, or read-only review |
| Environment | Mod path, target game build, relevant DLCs, dependencies, and actual load order |
| Player journey | Entry point, what appears on screen, interactions and outcomes, exit path |
| Rules | Costs, prerequisites, effects, duration, plus failure, cancellation, and repeat behavior |
| State ownership | Owning country or entity; what happens on window close, save reload, or a new campaign |
| AI & compatibility | When AI uses it; existing-save or multiplayer expectations |
| Media & languages | Source originals, usage permissions, visual direction, and target languages |
| Working boundaries | Editable scope, permission to launch HOI4, and commit/release expectations |

Be blunt about boundaries: “analyze first, hold off on edits,” “fix only this bug,” or “stop adding tests.” When you ask the AI to stop, it halts new checks and repairs immediately and hands off the current state. “Finish the current step” refers solely to the single bounded action already underway.

## 3. Ground Yourself in the Project and Target Build

Before touching existing code, read the technical guide, the player-facing text, and the real call chain. Player prose and actual callers tell you what a feature truly does far more reliably than guessing from filenames or variable names.

Verify syntax and interfaces directly against your target installation: vanilla files, shipped engine docs, verified skill templates, and the exact enabled dependencies. Whenever a template disagrees with live vanilla consumers, trust the live consumer and update the template. Wikis and community posts are handy pointers; confirm every detail against your installed build before shipping.

Check `descriptor.mod`, `replace_path`, load order, and competing definitions touching your change. Write compatibility patches against the real dependency version and its actual identifiers—never guess internal IDs from translated UI text. If installation files or runtime access are missing, note clearly what stays unverified.

## 4. Wire One Complete End-to-End Slice First

Get the smallest playable slice working from entry to feedback before scaling content volume. For a decision, that complete chain looks like:

```text
Category & entry → visibility/availability → cost & effect → state/modifier → player feedback
                                         ↘ localisation, icon & AI rules
```

Events, focuses, technologies, equipment, MIOs, characters, GUI, and music each have their own registration and consumer chain. A feature is ready when its entry point, icon, text, and effect all connect cleanly.

When modifying existing code, trace `ROOT`, `FROM`, country, state, and character scopes along the real call path so you know whose state every effect reads or mutates. Add guards only where a caller can genuinely be absent or save migration demands them; let broken wiring surface cleanly instead of masking it behind silent fallbacks.

For ambitious systems, an offline rules model or tiny native prototype is a great first step—just keep the core mechanics your real design relies on. Multi-entity systems should exercise creation, lookup, deletion, and slot reuse rather than a single hardcoded object. When you ask for feasibility only, expect limits, trade-offs, and a concrete validation plan before any code is written.

## 5. Design State, Saves, and Time Deliberately

Give every persistent variable, flag, array, or event target a clear owner, purpose, and lifetime. Answer four questions before choosing a structure:

- **Initialization**: When does setup run? Can existing saves initialize the new feature safely without re-granting one-time rewards?
- **Re-entry & branches**: Does reopening a window resume progress, reset it, or simply refresh the display? Do failure, cancellation, and restart follow distinct paths?
- **Persistence & multiplayer**: What survives reloading a save, tag switching, or losing a host? Which state is global and which belongs per player?
- **Granularity of “first time”**: “Once per mode and difficulty in each save” calls for separate mode and difficulty tracking rather than a single global flag.

Keep persistent save identifiers stable; changing an ID or its meaning requires an explicit migration path. Saves bind to scripted IDs, so renaming a file leaves save data untouched.

Separate UI animation clocks from gameplay clocks. Game days, hours, clicks, and explicit logical steps each behave differently under pause and speed changes. Reach for state machines, event-driven updates, or bounded batches when the mechanic genuinely calls for them; straightforward features belong in straightforward script.

## 6. GUI, Shaders, and Assets

Pair visual layout with hitboxes, refresh rules, close paths, and gameplay feedback. Inspect long translations, target resolutions, UI scaling, z-order occlusion, and close-and-reopen behavior.

Before relying on a GUI shader for logic, check what uniforms and inputs the engine actually passes—script state, cursor coordinates, and per-open clocks each need verification against the engine interface. Treat tilted art versus clickable bounds, decorative globes versus interactive maps, and looping versus one-shot animations as distinct interface questions. Browser previews and offline shader compiles speed up visual iteration, while native parsing and click behavior are verified inside HOI4.

Always process media from clean originals and track provenance and rights. Match dimensions, pixel format, alpha, mipmaps, cropping, and padding to the exact consumer rather than applying one preset everywhere. Repeated lossy DDS compression degrades crisp line art; choose formats for visual fidelity, VRAM budget, and consumer requirements rather than chasing the smallest file size.

Define frame count, frame rate, looping, and atlas layout up front for animated textures, watching GPU texture limits on large sheets. For music, keep main-menu and in-game-player registration, formats, and triggers distinct. When renaming or renumbering assets, check both explicit references and engine naming conventions without disturbing unrelated files.

Store originals, extracted frames, previews, and scratch conversions in agreed build or asset folders, and ship only runtime files in release packages.

## 7. Build Localisation Alongside the Feature

Keep every supported language aligned on features and keys. Lock down terminology, character names, and gameplay terms before translating, preserving all IDs, variables, icon tags, color codes, and dynamic placeholders—and keep authoring notes out of player prose.

Check filenames, language headers, UTF-8 BOM encoding, indentation, and key syntax against project conventions and skill templates. Once strings are written, confirm the target UI actually reads them: titles, descriptions, engine-generated modifier lines, and custom tooltips often pull from different keys.

Inspect wrapping, button widths, and font glyph coverage on new or longer text. Make sure costs, prerequisites, failures, and rewards convey the exact same rules in every language, and update language switchers, guides, and public descriptions together.

## 8. Performance Tuning and File Consolidation

Measure or locate real bottlenecks before optimizing: high-frequency `on_actions`, global scans, nested loops, repeatedly evaluated visibility triggers, and oversized animated textures. Replace polling with event-driven updates or caching wherever outputs change only on state transitions, defining explicit invalidation rules.

Preserve intended gameplay cadence when trimming overhead—never quietly turn a daily mechanic into a weekly one just to lower tick counts. Batched work should track progress, cap per-tick volume, and keep player feedback faithful to the design.

Consolidate tiny fragments by feature ownership when they share parser folders, loading rules, and lifecycles, while preserving splits needed for load order, compatibility, generators, or ownership boundaries. Fewer files chiefly improve maintainability and startup I/O; treat runtime FPS gains as something to confirm by profiling.

When merging files, verify definitions, namespaces, order, duplicate keys, and asset links, resolving same-key/different-value clashes by intent. Update any generator scripts alongside the merge so future builds stay reproducible and edits always flow from authoritative sources.

## 9. Diagnose from Reproduction and Solid Evidence

Anchor every bug report in five facts: game build, enabled mods, action taken, expected outcome, and actual behavior. Inspect logs from the matching run window, group repeated messages by root cause, and clear parse or reference errors that block downstream loading first. Trace the full trail rather than pinning blame on the final log line, a stale log from an earlier run, or a quick guess.

Follow cross-file failures from definition to consumer, then check scopes, state, dependencies, and assets. Keep confirmed defects, heuristic leads, design preferences, and open hypotheses clearly separated, focusing edits on verified root causes.

Reserve native debugging and dump analysis for problems that genuinely call for them—when tools are available and your consent covers that scope—handling private data with care. Routine `error.log` work stays lightweight unless you ask to go deeper.

## 10. Right-Sized Verification

| Change or evidence | Right-sized check | Remaining blind spots |
| --- | --- | --- |
| Small prose, comment, or familiar-template tweak | Read the diff; verify formatting and placeholders | Runtime logic untouched |
| Script, reference, encoding, or asset wiring | Changed-file static checks and reference tracing | In-game scope, timing, and UI interaction |
| Offline model, web mockup, or static image preview | Rules math, layout, pixels, and media format | Native input, shader rendering, and save behavior |
| In-game run | Direct observation on a named build, playset, and scenario | Other builds, existing saves, multiplayer, and unvisited branches |

Match verification depth to failure risk and reuse still-valid evidence. Small tasks typically need 0–3 targeted checks. When an in-game launch is warranted, take the shortest authorized path—an open session, a test save, or a fresh bookmark—and budget setup and cleanup inside the window. After a fix, recheck only what changed.

Launch the game to answer questions static checks leave open. If desktop control is unavailable or you prefer to skip live runs, mark runtime behavior unverified and keep a concise manual check path handy. Always pair new edits with fresh evidence.

## 11. Documentation, Git, and Delivery

- **Keep docs sharp and proportionate**: technical guides hold current architecture, entry points, state, compatibility, and build contracts; development logs capture what changed and how it was verified. Small changes belong in existing sections rather than brand-new documents.
- **Keep Git actions clean and explicit**: inspect working tree and staged diffs before committing, preserve unrelated changes from other work, and deliver asset renames, generators, and references together. Committing, pushing, cutting a release, and uploading to Workshop are separate steps executed only on your say-so against the configured remote and branch.
- **Hand off transparently**: summarize what shipped, what was verified, what remains unverified, and current Git status. Keep public docs generic with placeholder paths—never leak private directories, bespoke project characters, or unverifiable private test claims—and retain provenance and licenses in place.

## 12. Ready-to-Adapt Prompt Templates

**Feasibility study only**

> Assess whether this mod can support a management panel with saved progress. Outline input interfaces, state ownership, reload and pause behavior, performance limits, and the smallest validation plan. Share the analysis first—hold off on editing files or launching the game.

**Fix a concrete bug**

> This event grants its reward again the second time it opens. Trace the entry point, player-facing text, and state lifecycle, then prevent repeat claims while preserving progress in existing saves. Verify only the affected branches and leave other reward numbers untouched.

**Consolidate fragmented files**

> Consolidate the recently added fragment files by feature while keeping IDs, load order, and compatibility boundaries intact. Update generators and references, provide a before/after path map with content-equivalence checks, and keep gameplay identical.

**Swap art and sync translations**

> Replace this UI background with the provided original, scaling proportionally to the consumer's exact dimensions, matching the existing padding style, and keeping the original untouched. Update descriptions across every supported language, check the longest strings and new paths, and summarize output formats and checks.

**Prepare a clean delivery**

> Write release notes for the completed fixes, clearly separating tested behavior from unverified areas. Inspect staged changes, then commit and push to this project's target branch while leaving unrelated local edits untouched. Skip publishing a release or Workshop upload this round.

## 13. Technical References on Demand

Pull in only the references relevant to the task at hand:

- [Build a feature](../../../hoi4-content-builder/workflows/build-feature.md) and [template catalog](../../../hoi4-content-builder/references/template-catalog.md)
- [Player-facing meaning and existing code](../../references/semantic-intent-audit.md), [state and algorithms](../../references/algorithm-engineering.md)
- [GUI and localisation](../../references/gui-localisation.md), [localisation details](../../references/localisation-deep-dive.md)
- [Frame animation](../../references/animated-textures.md), [GUI shaders](../../references/gui-shader-effects.md), [media processing](../../references/media-optimization.md)
- [Performance diagnosis](../../references/performance-debugging.md) and [version migration](../../references/version-migration.md)
- [Proportionate checks and stopping](../../references/workflow-boundaries.md), [native testing](../../../hoi4-content-builder/workflows/test-mod.md), [technical documentation](../../references/development-documentation.md)
