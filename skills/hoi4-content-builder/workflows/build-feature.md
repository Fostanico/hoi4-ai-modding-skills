# Build one feature in an existing mod

1. Read repository guidance and inspect all definitions/callers around the
   requested behavior. Preserve unrelated work.
2. Follow the base skill's `references/semantic-intent-audit.md`: read the
   feature's names, descriptions, options, tooltips, scripted localisation,
   GUI labels, and character text; map code IDs to visible meaning and the
   player-facing promise. Never derive proper names or intent from IDs alone.
3. Translate the request and semantic map into a content contract and
   acceptance tests. Infer
   PDX implementation details rather than asking the user to design them.
4. Choose the nearest verified template or working current consumer. Search
   the target mod for ID, localisation, and resource collisions.
5. Implement the smallest complete dependency chain, including lifecycle,
   cleanup, AI, localisation, and visible resources that the feature needs.
6. Trace caller scope through every nested trigger/effect and guard optional
   scopes. Preserve stable save state or add an idempotent migration.
7. Rebuild the semantic map after editing and reconcile every changed date,
   cost, cooldown, unit, failure path, and visible name.
8. Run targeted validator, stale-placeholder/link searches, encoding and diff
   checks, then compare a fresh log with baseline evidence.
9. Ask for AI-assisted runtime-test consent and follow `test-mod.md` only after
   approval. Record remaining manual interactions explicitly.
