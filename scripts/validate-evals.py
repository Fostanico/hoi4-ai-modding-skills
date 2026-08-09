#!/usr/bin/env python3
"""Validate the public, anonymized real-dialogue regression dataset."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "evals" / "real-dialogue-regression.json"
SKILLS = {
    "hoi4-content-builder",
    "hoi4-pdx-modding",
    "hoi4-review-debug",
}
WINDOWS_PATH = re.compile(r"(?:[A-Za-z]:\\|\\\\)[^\s\"']+")
SESSION_ID = re.compile(r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b", re.I)
RAW_COMMIT = re.compile(r"\b[0-9a-f]{40}\b", re.I)
SHA256 = re.compile(r"^[0-9a-f]{64}$")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def main() -> int:
    errors: list[str] = []
    try:
        data = json.loads(DATASET.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot read {DATASET}: {exc}", file=sys.stderr)
        return 1

    if data.get("schema_version") != 1:
        fail(errors, "schema_version must be 1")
    privacy = data.get("privacy", {})
    for key in ("contains_raw_private_prompts", "contains_session_identifiers", "source_locator_published"):
        if privacy.get(key) is not False:
            fail(errors, f"privacy.{key} must be false")

    cases = data.get("cases")
    if not isinstance(cases, list) or len(cases) < 15:
        fail(errors, "cases must contain at least 15 real-dialogue regressions")
        cases = cases if isinstance(cases, list) else []

    seen_ids: set[str] = set()
    seen_fingerprints: set[str] = set()
    for index, case in enumerate(cases):
        label = case.get("id", f"index {index}")
        case_id = case.get("id")
        if not isinstance(case_id, str) or not re.fullmatch(r"RD-\d{3}", case_id):
            fail(errors, f"{label}: invalid id")
        elif case_id in seen_ids:
            fail(errors, f"{label}: duplicate id")
        else:
            seen_ids.add(case_id)

        if case.get("source_kind") != "anonymized_real_dialogue":
            fail(errors, f"{label}: source_kind must be anonymized_real_dialogue")
        fingerprint = case.get("source_fingerprint_sha256", "")
        if not isinstance(fingerprint, str) or not SHA256.fullmatch(fingerprint):
            fail(errors, f"{label}: invalid source fingerprint")
        elif fingerprint in seen_fingerprints:
            fail(errors, f"{label}: duplicate source fingerprint")
        else:
            seen_fingerprints.add(fingerprint)

        primary = case.get("primary_skill")
        supporting = case.get("supporting_skills")
        if primary not in SKILLS:
            fail(errors, f"{label}: unknown primary skill {primary!r}")
        if not isinstance(supporting, list) or any(skill not in SKILLS for skill in supporting):
            fail(errors, f"{label}: invalid supporting_skills")
        if isinstance(supporting, list) and primary in supporting:
            fail(errors, f"{label}: primary skill repeated as supporting skill")

        prompt = case.get("prompt")
        if not isinstance(prompt, str) or len(prompt.strip()) < 20:
            fail(errors, f"{label}: prompt is missing or too short")
            prompt = ""
        if WINDOWS_PATH.search(prompt):
            fail(errors, f"{label}: prompt leaks an absolute Windows path")
        if SESSION_ID.search(prompt):
            fail(errors, f"{label}: prompt leaks a session identifier")
        if RAW_COMMIT.search(prompt):
            fail(errors, f"{label}: prompt leaks a raw commit hash")
        if any(marker in prompt for marker in ("<environment_context>", "<recommended_plugins>", "AppData\\Local\\Temp")):
            fail(errors, f"{label}: prompt contains injected or private context")

        for field in ("required_behaviors", "forbidden_behaviors"):
            values = case.get(field)
            if not isinstance(values, list) or not values or any(not isinstance(value, str) or not value.strip() for value in values):
                fail(errors, f"{label}: {field} must be a non-empty string list")
        if not isinstance(case.get("runtime_evidence"), str) or not case["runtime_evidence"].strip():
            fail(errors, f"{label}: runtime_evidence is required")

    canonical = json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    digest = hashlib.sha256(canonical).hexdigest()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Validated {len(cases)} real-dialogue cases; canonical SHA-256 {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
