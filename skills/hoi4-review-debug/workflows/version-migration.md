# Version migration workflow

1. Capture the current playset, game build, DLCs, dependencies, launcher `.mod`,
   `descriptor.mod`, baseline `error.log`, and a clean list of intentional mod
   changes.
2. Inventory full replacements:

```powershell
& .agents/skills/hoi4-review-debug/scripts/audit-vanilla-overrides.ps1 `
  -ModRoot . `
  -VanillaRoot '<HOI4_GAME_ROOT>'
```

3. Review every `replace_path` and each high-risk exact override. Diff old
   vanilla, new vanilla, and mod versions when the old game tree is available;
   otherwise reconstruct the mod's intended delta before merging new defaults.
4. Use the base skill's `version-migration.md` gates. Verify every changed token
   in installed documentation and every object shape in a current vanilla
   consumer.
5. Run the base validator, stale-ID and conflict-marker searches,
   `git diff --check`, and the relevant read-only audit tools.
6. Launch the exact playset, inspect the new log, and test start/load plus the
   smallest affected gameplay or UI path. Record static and runtime evidence
   separately.
