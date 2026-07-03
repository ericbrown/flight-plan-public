"""Warn when recently-changed code uses a pattern you formally deprecated.

Called by the SessionStart hook (hooks/session-scan.sh):
    python3 deprecation_scan.py <project_dir> [<diff_base>]

Reads ACTIVE entries from <project_dir>/.claude/memory/deprecations.md, scans the
project's recent git diff (since <diff_base>, default HEAD~1) for the deprecated
patterns, and prints a warning block for any hit. Silent when the file is missing,
there are no ACTIVE entries, or the diff is clean.

Adapted from an internal deprecation-check tool (team/wip logic removed).
"""

import re
import subprocess
import sys
from pathlib import Path


def parse_active_deprecations(filepath: Path) -> list[dict]:
    """Return {name, replaced_by, why, status, ticket, keywords} for each ACTIVE entry."""
    if not filepath.exists():
        return []
    text = filepath.read_text()
    results = []
    for section in text.split("\n## ")[1:]:
        if "Status:" not in section:
            continue
        status_m = re.search(r"Status:\s*(.+)", section)
        if not status_m:
            continue
        status_val = status_m.group(1).strip()
        if not status_val.upper().startswith("ACTIVE"):
            continue

        # Header line, e.g. "2026-06-12 — DEPRECATED: passport.js auth middleware"
        header = section.splitlines()[0]
        name_m = re.search(r"DEPRECATED:\s*(.+)", header, re.IGNORECASE)
        name = name_m.group(1).strip() if name_m else header.strip()

        replaced_by = ""
        r_m = re.search(r"Replaced by:\s*(.+)", section)
        if r_m:
            replaced_by = r_m.group(1).strip()

        why = ""
        w_m = re.search(r"Why:\s*(.+)", section)
        if w_m:
            why = w_m.group(1).strip()

        ticket = ""
        t_m = re.search(r"Ticket:\s*(\S+)", section)
        if t_m:
            ticket = t_m.group(1).strip()

        # Build a keyword set from the deprecated name.
        # "passport.js auth middleware" -> {passport.js, passport, auth, middleware}
        keywords: set[str] = set()
        for token in re.findall(r"[\w./-]+", name.lower()):
            if len(token) >= 3:
                keywords.add(token)
                base = re.sub(r"\.\w+$", "", token)
                if base and len(base) >= 3 and base != token:
                    keywords.add(base)

        results.append({
            "name": name,
            "replaced_by": replaced_by,
            "why": why,
            "status": status_val,
            "ticket": ticket,
            "keywords": keywords,
        })
    return results


def project_diff(project_dir: str, diff_base: str) -> str:
    """Return the lowercased git diff of the project since diff_base."""
    result = subprocess.run(
        ["git", "diff", diff_base, "--unified=0"],
        cwd=project_dir,
        capture_output=True,
        text=True,
    )
    return (result.stdout or "").lower()


def find_hits(project_dir: str, diff_base: str = "HEAD~1") -> list[dict]:
    """Return deprecations whose keywords appear in the recent project diff."""
    depfile = Path(project_dir) / ".claude" / "memory" / "deprecations.md"
    deprecations = parse_active_deprecations(depfile)
    if not deprecations:
        return []

    context = project_diff(project_dir, diff_base)
    if not context.strip():
        return []

    hits = []
    for dep in deprecations:
        matched = [
            kw for kw in dep["keywords"]
            if re.search(r"\b" + re.escape(kw) + r"\b", context)
        ]
        if matched:
            hits.append({**dep, "matched_keywords": sorted(matched)[:5]})
    return hits


def print_hits(hits: list[dict]) -> None:
    if not hits:
        return
    print("### [DEPRECATED PATTERN DETECTED] — do not use these in new code")
    print("")
    for h in hits:
        print(f"  {h['name']}")
        if h["replaced_by"]:
            print(f"  Replaced by: {h['replaced_by']}")
        if h["why"]:
            print(f"  Why: {h['why']}")
        print(f"  Status: {h['status']}")
        if h["ticket"]:
            print(f"  Ticket: {h['ticket']}")
        print(f"  Matched on: {', '.join(h['matched_keywords'])}")
        print("")
    print("Do NOT use these patterns in new code. See .claude/memory/deprecations.md for the full list.")
    print("")
    print("---")
    print("")


def main() -> None:
    if len(sys.argv) < 2:
        return  # silently exit — hook calls this opportunistically
    project_dir = sys.argv[1]
    diff_base = sys.argv[2] if len(sys.argv) > 2 else "HEAD~1"
    print_hits(find_hits(project_dir, diff_base))


if __name__ == "__main__":
    main()
