# General Guide to HOI4 Mod Development

[简体中文](hoi4-modding-guide.zh-CN.md) | English | [日本語](hoi4-modding-guide.ja.md) | [Русский](hoi4-modding-guide.ru.md) | [한국어](hoi4-modding-guide.ko.md)

This guide is for authors and maintainers developing Hearts of Iron IV mods with AI. Describe gameplay in ordinary language or specify scripts, interfaces, and defects directly. The workflow applies to historical, alternate-history, character-focused, gameplay, and overhaul mods without depending on one fictional setting, country, or author's computer paths.

These are reusable development methods. Examples describe requests; they do not certify behavior in your game build, dependency combination, or save. Internal technical references for the three skills are mostly in English. This user guide has complete editions in five languages.

## 1. Getting started

Install all three skills together and preserve their relative directories. See the [installation and sharing instructions](../../../../docs/INSTALLATION.md) for client setup. Open the target mod and let the AI read project guidance and relevant code. A small change does not require scanning the entire project.

| Task | Primary skill | Expected result |
|---|---|---|
| Turn an idea into new content or a complete system | `hoi4-content-builder` | An accessible, usable feature with scripts, assets, and text |
| Edit scripts, localisation, interfaces, or compatibility logic | `hoi4-pdx-modding` | An implementation consistent with the target build and project |
| Diagnose defects, review performance, or investigate migration issues | `hoi4-review-debug` | Evidence-based findings and repairs within the agreed scope |

Compatible clients may select a skill automatically; you can also name it explicitly. Skills supply methods and references. File access, commands, network access, and game control depend on the client. The optional local MCP tools provide read-only evidence; they do not launch the game or modify the mod.

A first request might be:

> Add an “Industrial Assistance” decision to the current mod. The player pays 50 political power for a production bonus lasting 30 days. It cannot be bought again while active, but becomes available after expiry. The AI should consider it only during war. Preserve existing dependencies and cover the project's supported languages. Read relevant project guidance and vanilla examples, implement the feature, and perform necessary static checks. Do not launch the game or commit yet.

The numbers and restrictions are examples. Replace them with your design; the AI should determine the appropriate implementation.

## 2. Describe behavior that can be checked

A short request is usually sufficient. For larger work, add the information below where it is not already discoverable in the project.

| Information | What to establish |
|---|---|
| Goal | New mod, existing feature change, feasibility study, or read-only review |
| Environment | Project location, target game build, relevant DLCs, dependencies, and actual load order |
| Player path | Entry point, visible content, actions and outcomes, and exit path |
| Rules | Costs, conditions, effects, duration, failure, cancellation, and repeated actions |
| State scope | Owning country or object; behavior on closing, loading a save, and starting a campaign |
| AI and compatibility | Whether and when AI uses it; requirements for existing saves or multiplayer |
| Assets and languages | Available originals, permission to use them, visual requirements, and supported languages |
| Work boundaries | Files that may change, game-testing permission, and commit or publication scope |

State boundaries directly: “analyze first, do not implement,” “fix only this issue,” or “do not add more tests.” When asked to stop, the AI should stop starting checks and repairs and report the current state. “Finish the current step” means the one bounded operation already in progress.

## 3. Establish the project and sources

For existing work, read technical guidance, affected player-facing text, and callers first. Variable names do not explain gameplay, and filenames do not establish a feature's actual purpose.

Verify syntax and interfaces against the target installation: current vanilla files and shipped documentation, skill templates and kits, and the dependencies actually enabled. Correct a template when it conflicts with current consumer evidence. Wikis and community material can provide leads, but old examples must not override the target build's behavior.

Inspect relevant `descriptor.mod` settings, `replace_path`, load order, and competing definitions. A compatibility patch needs the exact dependency version and its real identifiers. State what remains unverified when installation files or runtime evidence are unavailable.

## 4. Complete one working feature chain

Build the smallest feature that works from entry to outcome, then expand its content. A decision might require:

```text
Category and entry → visibility/availability → cost and effect → state/modifier → feedback
                                         ↘ localisation, icon, AI usage rules
```

Events, focuses, technologies, equipment, MIOs, characters, GUI, and music each have their own consumers and resource chains. A definition file alone is incomplete if its entry point, icon, text, or actual effect is missing.

When changing existing behavior, trace the real call chain through `ROOT`, `FROM`, country, state, character, and other scopes. Identify whose state each effect reads or writes. Add guards where a caller can actually be absent or the save lifecycle requires them; silent fallbacks can hide broken connections.

Complex systems can start with an offline rules model and a small native example, but the example must retain the mechanisms the design needs. A multi-entity system should model creation, lookup, deletion, and slot reuse; one hardcoded object cannot establish the full design. For feasibility-only requests, deliver limits, options, and a validation path, then wait for implementation instructions.

## 5. Design state, saves, and time

Every persistent variable, flag, array, or event target needs an owner, purpose, and lifetime. Answer practical questions before selecting a data structure:

- When does initialization occur? Can new content initialize in an existing save? Can repeated initialization grant rewards again?
- Does reopening a window continue progress, reset it, or only refresh the display? Are failure, cancellation, and restart separate paths?
- What survives loading a save, switching countries, or losing the host? Which multiplayer state is shared, and which belongs to individual players?
- What defines “first completion”? “Once per game and difficulty in each save” requires separate game and difficulty records, rather than one global first-win flag.

Preserve persistent IDs and existing save state. Renaming them or changing their meaning needs a migration design. Renaming a file usually does not migrate identifiers stored in saves.

Separate animation time from gameplay time. Days, hours, clicks, and explicit logical steps have different semantics; account for pause and game speed. Use state machines, event-driven updates, or bounded batches for the complexity actually needed. Ordinary features rarely need a general-purpose interpreter.

## 6. GUI, visual effects, and assets

Specify layout, clickable areas, refresh conditions, closing behavior, and rule feedback together. Inspect affected long text, target resolution, scaling, occlusion, layer order, and reopening behavior.

A shader does not automatically receive script state, exact pointer coordinates, or a clock that resets whenever a window opens. Verify tilted visuals and their hitboxes, decorative globes and playable maps, and loops and one-time reveals as separate interface questions. Browser previews and standalone shader compilation do not establish native parsing or interaction.

Process media from original sources and retain provenance and usage permissions. Confirm dimensions, format, alpha, mipmaps, cropping, and padding against the actual consumer; one image's settings are not universal. Lossy DDS re-encoding can damage line art. A smaller file is not necessarily better for image quality or GPU memory.

For frame animations, specify frame count, playback rate, looping, and atlas layout; consider texture limits and memory for large images. For music, distinguish main-menu and in-game-player registration, formats, and triggers. When renaming or renumbering assets, inspect explicit references and engine naming conventions while preserving other assets' contents.

Keep originals, extracted frames, previews, and temporary conversions in the project's agreed asset or build locations. Release packages should contain runtime requirements. Preserving originals does not mean committing every intermediate file.

## 7. Plan localisation with the feature

Every supported language should cover the same features and keys. Establish terminology, names, and gameplay concepts before translating. Preserve identifiers, variables, icon markers, color codes, and dynamic placeholders. Keep authoring instructions out of player-facing prose.

Check language filenames, headers, encoding, and indentation, following project conventions and skill templates for key syntax. Text existing in a file does not prove that the intended interface consumes it: names, descriptions, generated modifier text, and custom tooltips can work differently.

Check wrapping, button width, and glyph rendering for new or changed long strings. Translations must communicate the same costs, conditions, failures, and rewards. Update language selectors, user guides, and public descriptions together so no language is left with headings only or outdated instructions.

## 8. Performance and file consolidation

Find actual costs before choosing an optimization. Examine frequent `on_actions`, global scans, nested loops, repeatedly evaluated display conditions, and large animated textures. Event-driven updates or caching may help when results change only with state; define cache invalidation explicitly.

Do not silently turn a daily mechanic into a weekly one to reduce execution frequency. Batched work needs progress tracking and limits while preserving intended outcomes and feedback.

Consolidate fragments by feature ownership when they share parser directories, loading rules, and lifecycles. Retain splits justified by load order, compatibility, generated ownership, or maintenance boundaries. Fewer files primarily improve maintenance and startup file access; they do not establish sustained FPS gains.

During merges, compare definitions, namespaces, order, duplicate keys, and resource references. Identical keys with different values require a semantic decision. Update generators so the next build does not recreate old paths. Outputs should be reproducible, and manual corrections should reach their authoritative sources.

## 9. Diagnose from reproduction and evidence

Record the build, enabled mods, action taken, expected behavior, and actual result. Read logs for the relevant time window, group repeated messages by cause, and prioritize parse or reference errors that can prevent later content from loading. The last log entry, stale logs after exit, and a single guess do not establish a crash cause.

Trace cross-file problems through definitions and consumers, then examine scopes, state, dependencies, and assets. Separate definite defects, heuristic leads, design preferences, and unverified hypotheses. Keep repairs focused on the identified cause.

Use native debugging or dump analysis when the problem needs it, tools are available, and authorization covers the operation; protect private data. Routine log investigation should not automatically escalate to process attachment, tool installation, or full-memory capture.

## 10. Validate with sufficient evidence

| Change or evidence | Appropriate check | What it does not establish |
|---|---|---|
| Small prose, comment, or known-template edit | Read the diff and preserve formatting and placeholders | That all gameplay was tested |
| Scripts, references, encoding, or asset wiring | Affected-file static checks and reference tracing | Correct native scope, timing, or interface behavior |
| Offline model, web, or image preview | Rules, layout, pixels, or media-format checks | Native input, rendering, or save behavior |
| In-game operation | Observation in a specified build, playset, and scenario | Coverage of other versions, saves, multiplayer, and every branch |

Choose the smallest sufficient check for the failure risk and reuse evidence that still applies. A small task usually needs 0–3 relevant observations. If native testing is necessary, use the shortest authorized route through an existing session, test save, or new campaign, including preparation and cleanup in the time budget. After a repair, rerun only the necessary targeted check.

A game launch should answer something static checks cannot. If native control is unavailable or testing is declined, report “runtime unverified” and provide a useful manual entry point when needed. Old testing records do not prove new changes.

## 11. Documentation, Git, and delivery

Technical guidance records current structure, entry points, state, compatibility, and build contracts. A development log records changes and evidence. Small edits can update existing documentation without creating another document set.

Inspect the worktree and staged diff before committing, preserving other contributors' unfinished changes. Deliver asset renames, generators, and references together. Committing, pushing, creating a release, and uploading to Workshop are separate actions; follow the user's request and existing authorization, using the configured remote and branch.

Report what is complete, the validation scope, unverified behavior, and Git status. Public documentation should use generic examples and placeholder paths, without private directories, project characters, bespoke rules, or unverifiable individual acceptance claims. Keep provenance and licenses in appropriate locations.

## 12. Requests you can adapt

**Feasibility only**

> Assess whether this mod can support a management panel with saved progress. Explain input interfaces, state ownership, loading and pause behavior, performance limits, and the smallest validation plan. Do not edit files or launch the game yet.

**Repair existing behavior**

> This event grants its reward again when opened a second time. Trace the entry point, player-facing text, and state lifecycle. Fix repeat claims while preserving progress in existing saves. Check only related branches and leave other reward values unchanged.

**Consolidate files**

> Consolidate recently added fragments by feature, preserving IDs, load order, and compatibility boundaries. Update generators and references. Provide a before/after path mapping and necessary content-equivalence checks without changing gameplay.

**Replace media and translate**

> Replace this interface background with the supplied original. Fit it proportionally to the existing consumer's dimensions, use the design's padding method, and preserve the original. Update instructions in all supported languages and check the longest text and new asset paths. Report the output format and checks.

**Prepare delivery**

> Summarize the completed fixes in release notes, distinguishing tested behavior from unverified areas. Inspect the staged scope, then commit and push to this project's configured target branch while preserving unrelated local changes. Do not publish a release or upload to Workshop in this task.

## 13. Technical references on demand

These references are for implementation. Select those relevant to the current problem instead of loading all of them.

- [Build a feature](../../../hoi4-content-builder/workflows/build-feature.md) and [template catalog](../../../hoi4-content-builder/references/template-catalog.md)
- [Player-facing meaning and existing code](../../references/semantic-intent-audit.md), [state and algorithms](../../references/algorithm-engineering.md)
- [GUI and localisation](../../references/gui-localisation.md), [localisation details](../../references/localisation-deep-dive.md)
- [Frame animation](../../references/animated-textures.md), [GUI shaders](../../references/gui-shader-effects.md), [media processing](../../references/media-optimization.md)
- [Performance diagnosis](../../references/performance-debugging.md) and [version migration](../../references/version-migration.md)
- [Proportionate checks and stopping](../../references/workflow-boundaries.md), [native testing](../../../hoi4-content-builder/workflows/test-mod.md), [technical documentation](../../references/development-documentation.md)
