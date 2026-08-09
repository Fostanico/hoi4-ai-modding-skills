# Real-dialogue regression set

This directory contains model-independent regression cases for the three HOI4
skills. The prompts are anonymized from real Codex conversations. They are not
synthetic examples and are not copied from the public skill text.

Each case keeps only the task shape that matters for evaluation:

- `prompt`: a redacted user request;
- `source_fingerprint_sha256`: SHA-256 of the unredacted source prompt;
- `primary_skill` and `supporting_skills`: expected routing;
- `required_behaviors`: facts or actions an acceptable answer must cover;
- `forbidden_behaviors`: mistakes or boundary violations that fail the case;
- `runtime_evidence`: whether static inspection, a supplied log, or an actual
  game run is needed to close the task.

The repository deliberately does not contain the original private prompts,
session identifiers, local paths, project names, character names, or a mapping
from fingerprints back to a user. A fingerprint proves that the maintainers
used a stable source prompt without publishing it.

Run the structural and privacy checks with:

```powershell
python scripts/validate-evals.py
```

These checks do not score a model response. A future runner may execute the
prompts against any agent and judge the response against the behavior lists.
Human review remains appropriate for design, balance, localisation quality,
and evidence-strength claims.
