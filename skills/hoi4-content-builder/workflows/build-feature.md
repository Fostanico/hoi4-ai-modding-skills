# Build one feature in an existing mod

1. Read repository guidance and inspect all definitions/callers around the
   requested behavior. Preserve unrelated work.
2. Translate the request into a content contract and acceptance tests. Infer
   PDX implementation details rather than asking the user to design them.
3. Choose the nearest verified template or working current consumer. Search
   the target mod for ID, localisation, and resource collisions.
4. Implement the smallest complete dependency chain, including lifecycle,
   cleanup, AI, localisation, and visible resources that the feature needs.
5. Trace caller scope through every nested trigger/effect and guard optional
   scopes. Preserve stable save state or add an idempotent migration.
6. Run targeted validator, stale-placeholder/link searches, encoding and diff
   checks, then compare a fresh log with baseline evidence.
7. Ask for AI-assisted runtime-test consent and follow `test-mod.md` only after
   approval. Record remaining manual interactions explicitly.
