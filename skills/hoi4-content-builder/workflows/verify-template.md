# Template verification workflow

Use this workflow before promoting a new or materially changed template into
`assets/`. A community tutorial is discovery evidence, not engine authority.

1. State the target HOI4 build, object type, caller, starting scope, and DLC or
   dependency assumptions.
2. Read the installed adjacent `_documentation.md` when one exists. Use the
   generated effect, trigger, modifier, and localisation documents for tokens.
3. Find at least one working consumer in the same installed vanilla build.
   Verify root object, nesting, required fields, scope, ID type, and file path.
4. Prefer a minimal base-game token. If only a DLC consumer exists, label the
   template or remove the DLC-only field.
5. Rewrite the skeleton with clearly replaceable `MOD_` identifiers. Do not copy
   tutorial prose, fictional IDs, dependency internals, or executable tools.
6. Record exact documentation and vanilla consumer paths in
   `references/template-catalog.md`, including the verification date/build.
7. Validate braces, localisation encoding, cross-file identifiers, and all
   existing repository rules. Run the base validator and `git diff --check`.
8. Treat GUI, map/history, event scope, MIO, dynamic modifier, and compatibility
   templates as statically checked until a minimal in-game test succeeds.

Re-verify a template after a game update, an object schema change, a new DLC
dependency, or a failure in `error.log`. A verified skeleton reduces routine
lookup; it does not make changed semantics version-independent.
