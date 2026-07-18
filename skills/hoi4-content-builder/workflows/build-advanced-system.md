# Build an advanced system

Use for cross-system mechanics, scripted GUI, map modes, AI pipelines, raids,
special projects, factions, compatibility layers, or save migrations.

1. Read `references/advanced-engineering.md`, the exact system references, and
   the base skill's `references/semantic-intent-audit.md`.
2. For existing content, map code IDs to actual names, descriptions, tooltips,
   scripted-localisation branches, and player-facing promises before defining
   the system. Do not infer proper names or roles from tokens.
3. Define the state machine, scope contracts, data owners, dependency graph,
   performance budget, compatibility matrix, and migration/reload behavior.
4. Verify every database field against installed documentation and a current
   vanilla or exact-dependency consumer. Do not infer unsupported objects from
   a plausible token name.
5. Build a minimal vertical slice with observable debug state. Then add AI,
   failure/cancel paths, GUI/assets, localization, and compatibility adapters.
6. Add deterministic scripts or templates only for repeated transformations;
   generate into staging, review all writes, and never overwrite silently.
7. Audit hot paths, scope fan-out, daily updates, GUI refresh, cleanup, and
   save migration. Test reload and dependency absence as applicable.
8. Rebuild the semantic map and reconcile all visible names, dates, costs,
   cooldowns, units, and failure handling with the final implementation.
9. Run static checks and the smallest matrix that covers distinct behavior.
10. Ask for runtime-test consent, follow `test-mod.md`, compare fresh logs, and
   iterate until acceptance tests pass or a concrete engine blocker is proven.
