# HOI4 review and debug workflows

## Bug diagnosis and fix

1. State the exact observed symptom and last known trigger.
2. Confirm playset, game version, DLCs, dependency versions, and newest log.
3. If the symptom began after an update, compare the official-news audit to
   installed generated documentation and search known removed/deprecated
   tokens before tracing content logic.
4. Locate the token and object type in the installed vanilla documentation map.
   Record supported scope/targets from generated docs and nesting/lifecycle
   from a current working consumer. Reject TODO/TBD design syntax.
5. Read the affected names, descriptions, options, tooltips, GUI labels,
   scripted-localisation branches, and character text. Record the code ID,
   visible meaning, player promise, lifecycle, and invariant. Do not infer a
   proper name or feature role from the token itself.
6. Trace runtime entry point to the failing object and every scope transition.
7. Bucket parser, invalid-token/scope, missing-ID, resource, and runtime-state
   errors. Fix the earliest parser error first.
8. Form one testable cause. If authorized to fix, make the smallest change and
   rerun the same reproduction before broad cleanup.

For a deterministic first pass over a current log:

```powershell
& .agents/skills/hoi4-review-debug/scripts/analyze-hoi4-log.ps1 `
  -Path "$HOME/Documents/Paradox Interactive/Hearts of Iron IV/logs/error.log"
```

Add `-BaselinePath old-error.log -AsJson` to separate new, unchanged, and
removed unique entries. The command is read-only unless `-OutputPath` is
explicit, and even then it refuses replacement without `-Force`.

## Windows crash dumps

When a crash package contains `minidump.dmp` or another `.dmp`, detect
`cdb.exe`, `WinDbgX.exe`, or the `Microsoft.WinDbg` AppX package. If WinDbg is
already installed, use it; do not stop at `exception.txt` or text-log
inspection. Do not install it without explicit user authorization. Prefer CDB
for a reproducible, unattended pass and preserve the original dump:

```powershell
$pkg = Get-AppxPackage -Name Microsoft.WinDbg
$cdb = Join-Path $pkg.InstallLocation 'amd64\cdb.exe'
& $cdb -z '<CRASH_DIR>\minidump.dmp' -logo '<CRASH_DIR>\windbg-analysis.txt' `
  -c '.symfix;.reload;!analyze -v;.ecxr;r;kv;lm;lmvm hoi4;q'
```

Record the exception operation (`read`, `write`, or `execute`), fault address,
register context, first trustworthy stack frame, failing module, process
uptime, loaded and unloaded third-party modules, and failure bucket. For an
indirect null call, disassemble the caller and inspect the target slot. RTTI,
nearby source-path strings, and object memory may identify the affected engine
class even when function symbols are absent.

Public HOI4 builds do not normally include Paradox private PDBs. Large offsets
from the nearest exported `PHYSFS_*` symbol are not function identities or
proof of a filesystem fault. A module being loaded is not proof that it caused
the crash. Correlate dump time, process uptime, active playset, reproduction
steps, fresh logs, and the affected engine class before assigning a mod file or
third-party DLL as the cause. If no debugger is available, analyze
`exception.txt` and fresh logs, but state that the native call site remains
unresolved.

## Code-quality and adversarial review

Build the semantic-intent map first, then check syntax, scopes, initialization,
identifiers, cross-file wiring, lifecycle, save compatibility, and performance.
Attack boundary cases only after the player-visible purpose is established:

- missing/dead target or changed controller;
- empty array, first/last index, denominator zero, and maximum values;
- duplicated on_action registration or event recursion;
- two runs in one tick/week and no run at a boundary;
- event option versus `after`, and focus completion versus `bypass_effect`;
- save/reload, old save, civil war/dynamic tag, DLC absent, dependency override;
- tooltip/localisation disagreement and same-key collisions.
- variable-scope `scope_exists` guards that never validate the stored object;
- inclusive `collection_size` boundaries mistaken for strict comparisons;
- recognized modifiers placed in a consumer that does not use them;
- special-project completion without a facility or scientist;
- decision/map/GUI work accidentally evaluated per frame, world scope, or tick.

Report only actionable findings. Use severity, file/line, evidence, effect, and
recommended correction. If no defect is found, list remaining test gaps.

## Performance analysis

For each suspect path record frequency, scope count, nested iterations,
scripted trigger calls, global searches, GUI redraws, and dynamic-modifier
refreshes. Prioritize roughly:

```text
daily/global nested scans > per-frame GUI work > repeated scripted lookups
> unnecessary refreshes > cold-path verbosity
```

Prefer engine arrays, event-driven updates, safe batching, invariant hoisting,
cached reused booleans, current collections, documented quantified checks,
math expressions with documented functions, and dirty counters changed only
with displayed state.

For runtime probing, prefer commands confirmed in the installed console docs:
`eval_trigger`, `eval_effect`, `effect`, `debug_tooltip`, event ID/dump tools,
`loc_check*`, `imgui`, and `aiview`. Do not require `ai_trace` or `ai_dump` on a
release build.

## Simplification

Good candidates include array lookup tables, parameterized scripted
localisation, shared effect tails, coherent `if/else`, merging identical
branches, looping over actual array contents, and folding single-use arithmetic
temporaries. Reject changes that alter scope, random distribution, tooltips,
set/clear lifecycle, saves, or dependency behavior.

## Localisation review

- Validate BOM, header, indent, quotes, and formatting tokens. Require
  `key: "Text"`; any numeric key-version suffix such as `key:0 "Text"` is an
  error.
- Run `scripts/audit-localisation.ps1 -ModRoot <MOD_ROOT>` and treat unknown
  colour markers, broken brackets, and same-file duplicate keys as errors.
- Search exact keys across loaded localisation.
- Auto-remove only exact key/value duplicates. Same-key/different-value entries
  require an explicit canonical choice.
- Check every visible consumer and scripted-localisation fallback.
- Test dynamic text in its actual UI context.
- Use the base skill's `localisation-deep-dive.md` for formatted variables,
  scope functions, icons, nesting, bound localisation, and formatter syntax.
- Use `field-tested-pitfalls.md` before a bulk cleanup or GUI-tooltip rewrite.

## Lifecycle audit

For each flag, variable, array entry, event target, timed modifier, decision, or
cached result, map:

```text
create/init | read | update | clear/expire | save/reload | old-save migration
```

Every read needs initialization, temporary state needs cleanup, cached state
needs invalidation, and renames need compatibility or migration.

## Test plan

Build tests from player-visible behavior: normal path, every branch, boundaries,
missing targets, AI/player ownership, DLC/load order, save/reload, old saves,
repeated execution, and performance. Record setup, action, expected result,
relevant log signal, and cleanup. Separate static, console-assisted, and true
gameplay tests.

For a complete map root, run:

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-hoi4-map.ps1 `
  -Root "<HOI4_GAME_ROOT>"
```

The audit is deliberately cross-file and read-only. A partial mod that relies
on vanilla map files should be assembled into a complete effective test root
before using it to judge undefined IDs.
