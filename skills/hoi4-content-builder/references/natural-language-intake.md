# Natural-language intake

The user is responsible for the desired experience, not for knowing PDX script.
Translate ordinary language into a technical contract before editing.

## Discover before asking

Inspect the target mod, descriptors, repository guidance, current implementation,
installed game build, DLCs, dependency descriptors, and active playset. Infer:

- whether the request extends an existing system or creates a new one;
- country, state, character, unit, or player scope from existing callers;
- project prefix, localisation languages, encoding, and file ownership;
- existing flags, variables, IDs, assets, and compatibility conventions;
- the smallest existing vanilla/dependency example that matches the behavior.

Ask only blocking product questions, such as mutually exclusive gameplay rules,
an unknown target dependency, required art the user has not supplied, or a
destructive map/history choice. Offer one recommended default in plain language.

## Content contract

Record this compactly for the agent's own execution:

```text
Player experience:
Entry point and actor:
Eligibility and cost:
Immediate and delayed effects:
Failure/cancel/cleanup behavior:
AI behavior:
Save and migration behavior:
DLC/dependency/load-order assumptions:
Player-visible text and assets:
Acceptance tests:
```

Map each line to concrete definitions, callers, resources, and tests. Do not
make the user approve internal filenames unless those names affect compatibility
or public APIs.

## Defaults

- Extend established repository patterns and prefixes.
- Add only the requested language unless project guidance requires more.
- Infer player-facing languages from the user's request, conversation language,
  and existing project. For a new standalone mod with no stated language,
  include the user's language and offer English as a fallback; do not require
  the user to translate PDX keys or formatting tokens.
- Prefer non-destructive additions over full-file overrides or `replace_path`.
- Prefer event-driven/batched logic over daily global polling.
- Preserve stable flags, variables, event IDs, and save-visible state.
- Gate dependency-only content on the exact dependency; never guess IDs from UI
  text or another release.
- Build one runnable path before optional branches.

Before implementation, summarize any assumption that changes gameplay,
compatibility, save behavior, map/history, or asset ownership. Routine syntax
and file placement are the agent's responsibility.
