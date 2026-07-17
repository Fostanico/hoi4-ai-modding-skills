# Build an advanced system

Use for cross-system mechanics, scripted GUI, map modes, AI pipelines, raids,
special projects, factions, compatibility layers, or save migrations.

1. Read `references/advanced-engineering.md` and the exact system references.
2. Define the state machine, scope contracts, data owners, dependency graph,
   performance budget, compatibility matrix, and migration/reload behavior.
3. Verify every database field against installed documentation and a current
   vanilla or exact-dependency consumer. Do not infer unsupported objects from
   a plausible token name.
4. Build a minimal vertical slice with observable debug state. Then add AI,
   failure/cancel paths, GUI/assets, localization, and compatibility adapters.
5. Add deterministic scripts or templates only for repeated transformations;
   generate into staging, review all writes, and never overwrite silently.
6. Audit hot paths, scope fan-out, daily updates, GUI refresh, cleanup, and
   save migration. Test reload and dependency absence as applicable.
7. Run static checks and the smallest matrix that covers distinct behavior.
8. Ask for runtime-test consent, follow `test-mod.md`, compare fresh logs, and
   iterate until acceptance tests pass or a concrete engine blocker is proven.
