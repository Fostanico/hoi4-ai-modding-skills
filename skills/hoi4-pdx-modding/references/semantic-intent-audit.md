# Semantic intent audit

Use this workflow before fixing, refactoring, optimizing, migrating, or
documenting an existing feature. Code identifies execution; localisation
identifies what the feature means to players. Neither source may be ignored.

## Build the evidence map

1. List the changed objects, IDs, flags, variables, scripted effects, GUI
   callbacks, and on_action entries.
2. Follow every player-facing object to its localisation keys: names,
   descriptions, option text, decision tooltips, custom/effect tooltips,
   modifier text, character descriptions, GUI labels, and debug text.
3. Resolve scripted localisation and nested/dynamic consumers to their leaf
   keys. Inspect the language actually maintained by the target project; check
   other supported languages when the canonical text is ambiguous.
4. Read character definitions, project handoff documentation, and visible
   assets where they disambiguate a proper name or narrative role.
5. Record a compact map before judging behavior:

```text
code ID | visible name | player-facing promise | actual lifecycle | invariant
```

## Evidence rules

- Never infer a character, place, organization, resource, policy, or mechanic
  solely from an ASCII token, transliteration, abbreviation, filename, or
  variable name. A token such as `sana` is an identifier, not proof of the
  displayed proper name.
- Treat localisation as semantic evidence, not decorative text added after the
  implementation. Descriptions and tooltips often encode dates, costs,
  cooldowns, first-use behavior, failure handling, and the intended audience.
- Treat code as execution evidence, not automatic proof of design intent.
  Existing code may be stale, broken, or only one branch of the feature.
- If code, localisation, project documentation, and runtime behavior disagree,
  report the conflict explicitly. Determine the canonical behavior from the
  user's request, maintained project documentation, current visible design,
  and runtime evidence; do not silently choose whichever source is convenient.
- When a refactor intentionally changes behavior, update every affected
  localisation consumer and project handoff entry in the same change.

## Refactor audit

Before editing, compare the proposed implementation with the evidence map:

- cadence and calendar meaning;
- first use, repeat use, cooldown, expiry, and cancellation;
- displayed cost versus actual cost;
- visible totals, components, signs, units, and formatting;
- character identity and relationships;
- AI/player restrictions and target scope;
- success, failure, insufficient-resource, and old-save behavior;
- manual choices that automation must not overwrite.

After editing, rebuild the map from the changed files and search for stale
names, descriptions, tooltips, scripted-localisation branches, and technical
documentation. Static syntax validation does not prove semantic equivalence;
exercise the player-visible promises in the runtime test plan.
