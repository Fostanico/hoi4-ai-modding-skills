# Build a complete mod from a plain-language idea

1. Read `references/natural-language-intake.md`; inspect the workspace and ask
   only blocking questions.
2. Discover the installed HOI4 build and create or locate the launcher `.mod`,
   mod root, and `descriptor.mod`. Decide standalone/submod/compatibility status
   and avoid `replace_path` unless the requested design requires replacement.
3. Write the content contract and architecture: IDs, databases, callers,
   lifecycle, AI, assets, localisation, compatibility, save behavior, tests.
   Start the canonical technical guide and development handoff from the bundled
   templates when the project has no established equivalents.
4. Create the smallest playable vertical slice from verified templates. Define
   objects before consumers and use project conventions for paths/encoding.
5. Complete the dependency graph: entry points, effects/triggers, UI/GFX,
   localisation in every requested player language, history, AI, assets,
   cleanup, and dependency gates. Translate values, not keys or scripted tokens.
6. Search for missing/stale IDs and placeholders; run validators, encoding and
   repository checks; inspect a fresh or baseline log if available.
7. Exercise boundary cases statically: unavailable DLC, missing dependency,
   invalid scope, cancellation, expiry, reload, AI, and old-save initialization.
8. Ask whether the user wants AI-assisted in-game testing. If yes, follow
   `test-mod.md`; if no, provide the smallest manual test plan without opening
   Steam or changing the playset.
9. Incorporate test evidence; reconcile code comments; update durable technical
   documentation and the change-specific handoff; then follow `release-mod.md`.

Done means the requested player experience works as a complete graph, not that
one central script file exists.
