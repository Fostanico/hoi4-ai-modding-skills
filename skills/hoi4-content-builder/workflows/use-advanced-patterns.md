# Use an advanced built-in pattern

1. Select the closest resource from `references/advanced-patterns.md`.
2. Copy it into the engine directory named in its header or preserve the kit's
   relative tree.
3. Replace every `MOD`, sample tag, numeric ID, localisation value, and
   placeholder path. Search the copied tree to prove none remain.
4. Write down the caller scope and each nested scope. For arrays, also record
   whether elements are scopes or numbers and who owns the array.
5. Preserve the provided performance boundary: especially `target_array`,
   event-driven calls, explicit cleanup, and dirty-variable refresh.
6. Search current vanilla for the evidence paths in the reference. If the game
   version or consumer shape changed, stop and re-verify the template.
7. Run `validate-hoi4.ps1`, stale-reference/conflict-marker searches, encoding
   checks, and `git diff --check`.
8. Perform the smallest in-game test for event-target lifetime, dynamic
   modifiers, targeted decisions, localisation scope, or GUI behavior, then
   inspect the fresh `error.log`.

For generated country scaffolds, generate into a new staging directory first:

```powershell
& .agents/skills/hoi4-content-builder/scripts/new-country-scaffold.ps1 `
  -Tag ABC -CapitalState 64 -CountryName 'Example Country' `
  -OutputPath "$env:TEMP/ABC-country"
```

Review the tree before moving it into a mod. The generator does not create
flags or map ownership and refuses a non-empty output directory unless
`-Force` is explicit.
