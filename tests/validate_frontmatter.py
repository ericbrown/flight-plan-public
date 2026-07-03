#!/usr/bin/env python3
"""Validate the frontmatter/structure of slash commands and skills.

- commands/*.md  — MUST open with a YAML frontmatter block (`---` ... `---`) that
  contains a non-empty `description:` field. Claude Code surfaces that description.
- skills/*.md    — must be non-empty and start with either a frontmatter block or a
  Markdown `#` heading. (Skills in this repo are a mix of frontmatter and prose docs.)

Exits non-zero and lists every problem found. Run from the repo root:
    python3 tests/validate_frontmatter.py
"""

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def parse_frontmatter(text: str):
    """Return the frontmatter block lines if the file opens with one, else None."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i]
    return None  # opened a block but never closed it


def check_commands(problems: list[str]) -> int:
    files = sorted((REPO / "commands").glob("*.md"))
    for f in files:
        fm = parse_frontmatter(f.read_text())
        rel = f.relative_to(REPO)
        if fm is None:
            problems.append(f"{rel}: missing or unterminated `---` frontmatter block")
            continue
        desc = next((ln for ln in fm if ln.strip().startswith("description:")), None)
        if desc is None:
            problems.append(f"{rel}: frontmatter has no `description:` field")
        elif not desc.split(":", 1)[1].strip():
            problems.append(f"{rel}: `description:` is empty")
    return len(files)


def check_skills(problems: list[str]) -> int:
    files = sorted((REPO / "skills").glob("*.md"))
    for f in files:
        text = f.read_text().lstrip()
        rel = f.relative_to(REPO)
        if not text:
            problems.append(f"{rel}: file is empty")
        elif not (text.startswith("---") or text.startswith("#")):
            problems.append(f"{rel}: must start with frontmatter or a `#` heading")
    return len(files)


def main() -> int:
    problems: list[str] = []
    n_cmd = check_commands(problems)
    n_skill = check_skills(problems)

    if problems:
        print("Frontmatter validation FAILED:")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"Frontmatter OK: {n_cmd} commands, {n_skill} skills.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
