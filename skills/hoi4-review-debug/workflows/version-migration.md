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
   For 1.19.4, start with its [GUI and equipment override map](../../hoi4-pdx-modding/references/version-migration.md#operation-postern-1194).
   Separate documented fuel thresholds, observed chassis blocks and native
   control names from announced parameters with unresolved shape. A shipped
   schema can lag the patch; neither absence from it nor patch-note prose alone
   proves the final block syntax.
5. Run the base validator, stale-ID and conflict-marker searches,
   `git diff --check`, and the relevant read-only audit tools.
6. Apply the [runtime-test necessity gate](../../hoi4-content-builder/workflows/test-mod.md).
   A source-only refresh does not require starting the game. When a native test
   is needed and authorized, reuse the user's playset, enable only required mods,
   and inspect its fresh log and the smallest affected path. Use console shortcuts
   for a requested short test, and honor explicit no-launch/stop instructions.
   Record static and runtime evidence separately.
