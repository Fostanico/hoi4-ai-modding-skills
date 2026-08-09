#!/usr/bin/env python3
"""Lightweight repository validation that does not depend on Codex internals."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / "skills"
LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
PRIVATE_WINDOWS_HOME = re.compile(r"(?i)[a-z]:[\\/]users[\\/][0-9]{4,}[\\/]")
CONFLICT_MARKER = re.compile(r"(?m)^(?:<<<<<<< .+|={7}|>>>>>>> .+)$")


def main() -> int:
    errors: list[str] = []
    skill_dirs = sorted(path for path in SKILLS_ROOT.iterdir() if path.is_dir())
    expected = {"hoi4-content-builder", "hoi4-pdx-modding", "hoi4-review-debug"}
    if {path.name for path in skill_dirs} != expected:
        errors.append("skills/ must contain exactly the three public HOI4 skills")

    for skill_dir in skill_dirs:
        entry = skill_dir / "SKILL.md"
        if not entry.is_file():
            errors.append(f"{skill_dir.name}: missing SKILL.md")
            continue
        text = entry.read_text(encoding="utf-8-sig")
        match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
        if not match:
            errors.append(f"{entry.relative_to(ROOT)}: invalid frontmatter")
        else:
            frontmatter = match.group(1)
            name = re.search(r"(?m)^name:\s*(\S+)\s*$", frontmatter)
            description = re.search(r"(?m)^description:\s*(.+)$", frontmatter)
            if not name or name.group(1) != skill_dir.name:
                errors.append(f"{entry.relative_to(ROOT)}: name must match directory")
            if not description or len(description.group(1).strip()) < 40:
                errors.append(f"{entry.relative_to(ROOT)}: description is missing or too short")

        for file in skill_dir.rglob("*"):
            if not file.is_file() or file.suffix.lower() not in {".md", ".txt", ".gui", ".gfx", ".asset", ".yml", ".ps1", ".json"}:
                continue
            content = file.read_text(encoding="utf-8-sig")
            if CONFLICT_MARKER.search(content):
                errors.append(f"{file.relative_to(ROOT)}: merge conflict marker")
            if PRIVATE_WINDOWS_HOME.search(content):
                errors.append(f"{file.relative_to(ROOT)}: public skill contains a private numeric Windows home path")
            if file.suffix.lower() == ".md":
                for target in LINK.findall(content):
                    target = target.strip().strip("<>").split("#", 1)[0]
                    if not target or re.match(r"^[a-z]+://", target, re.I):
                        continue
                    resolved = (file.parent / target).resolve()
                    if not resolved.exists():
                        errors.append(f"{file.relative_to(ROOT)}: broken link {target}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Validated {len(skill_dirs)} skill trees and their local Markdown links.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
