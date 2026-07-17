# Field-tested HOI4 pitfalls

These are portable failure patterns reproduced while maintaining a large live
mod. Project names and identifiers are intentionally omitted. Reconfirm each
fix against the target build, consumer, dependency set, and current log.

## Localisation

### Duplicate keys are two different problems

- Same key and same value is an exact duplicate. It can normally be removed
  after choosing the intended canonical file.
- Same key and different value is a content conflict. Do not guess which text
  wins; report every file and value and obtain an explicit canonical choice.
- Load order is not a durable conflict-resolution strategy. Use a deliberate
  `localisation/<language>/replace/` entry only when overriding vanilla or a
  dependency is the actual design.
- Preserve a user- or project-designated canonical file. File size and number
  of entries are weak heuristics, not authority.
- A bulk dedupe must not compact whitespace or rewrite unrelated values. Review
  the diff and run `git diff --check` afterward.

### Nested text support is consumer-specific

A shared `$OTHER_KEY$` rendered literally, including the dollar signs, in one
real GUI tooltip path. The reliable production fix was to inline the sentence
in each affected tooltip after the failure was reproduced in-game.

Do not conclude that nested localisation is globally broken. It works in many
vanilla consumers, and bound localisation is recursive in supported consumers.
Instead:

1. identify the actual GUI/event/focus/decision consumer;
2. confirm whether it supplies dynamic or contextual localisation;
3. test `$KEY$`, scripted localisation, or bound localisation there;
4. keep a direct-key or inline fallback when the richer form renders literally.

The Wiki separately warns that legacy `pdx_tooltip` does not reliably expand
nested `$KEY$`. That is a consumer limitation, not a language-wide rule.

### Formatting markers can fail far from their source

- Every opened colour such as `§C` needs a following `§!`, even at the end of a
  value. Missing resets can bleed into later UI text.
- `§M`, `§ `, or a string ending in bare `§` produces colour errors whose log
  line may not name the source file. Search all loaded `.yml` files.
- A `£text_icon` requires a matching `GFX_text_icon` sprite. For multi-frame
  icons, verify both `£name|N` and `legacy_lazy_load = no`.
- Preserve formatting tokens while translating. Translators should change
  prose, not `$PARAMETERS$`, `[Scope.GetFunction]`, `[?variables|format]`,
  `§...§!`, or `£icons` unless the change deliberately targets them.

### Encoding and language identity form one contract

The file must have a UTF-8 BOM, the first content line must be the correct
`l_<language>:` header, the filename should end in `_l_<language>.yml`, and the
file should live in the matching `localisation/<language>/` directory. A valid
sentence in a mismatched file can silently disappear or pollute another
language's collision set.

Use only `key: "Text"`. Never use `key:0 "Text"` or another numeric key-version
suffix, even when an old mod or tutorial uses it. Migrate the entry by removing
the suffix before it enters a template or production file.

### Dynamic text needs a real context

Square-bracket functions and `[?variables]` can render literally when the
consumer does not localise dynamically or lacks the requested scope. A focus
title may need its documented dynamic setting; a custom GUI needs the correct
scripted-GUI `context_type`; `context_aware_text` requires a context-aware
owner. Copy a current consumer of the same UI class and test it.

### Template keys collide when kits are combined unchanged

Independent examples commonly reuse `MOD.1.t`, `MOD.1.desc`, and `MOD.1.a`.
That is acceptable inside separate template demonstrations but not after they
are copied into one mod. Allocate a namespace and event-ID range before merging
kits, then rescan all languages for collisions.

## Script, GUI, and lifecycle

### The first parser error creates misleading cascades

One malformed quote, slash, brace, or token can produce dozens of later scope,
trigger, GUI, or localisation errors. Fix the earliest parser error in each
file, relaunch, and compare a fresh log before treating downstream lines as
independent defects.

### Old logs are baseline evidence, not post-fix proof

Record log modification time and game build. Static validation can prove
encoding, braces, references, and known tokens; it cannot prove that a GUI
clicked, a scope existed, or a dynamic value refreshed. Only a fresh run after
the edit can do that.

### Nearby performance work must preserve cadence

Merging repeated weekly scans does not authorize moving an unrelated daily
counter to weekly execution. Record each mechanic's cadence and player-visible
units before refactoring. If cadence intentionally changes, preserve old
variable/flag names for save compatibility unless a migration covers them.

### Search consumers before deleting or renaming state

Flags, variables, event targets, localisation keys, sprite names, and scripted
GUI element names frequently have distant consumers. Search the full effective
mod and enabled dependencies before changing them. A name that looks temporary
can still be part of save data, GUI binding, or another file's lifecycle.

### Recognised tokens are not universally accepted

A generated modifier or localisation function proves engine recognition. It
does not prove that every database or UI consumer accepts it. Require both a
current installed definition and a working consumer of the same class.

### Triage hard failures before optional media

Prioritise parser, scope/trigger, invalid ideology, equipment/MIO, missing
required IDs, and localisation collisions. Missing optional textures, audio,
or icons matter, but chasing them first hides the errors that can stop content
from loading at all.

## Reusable review sequence

1. Read project guidance and identify the current build and playset.
2. Preserve unrelated changes and inspect the actual newest logs.
3. Search definitions and consumers before editing identifiers.
4. Fix the earliest root cause in each error bucket.
5. Run the base validator and the focused localisation/map/override audits.
6. Run stale-ID searches, encoding checks, and `git diff --check`.
7. Ask before launching Steam or HOI4; report static and runtime evidence
   separately.
