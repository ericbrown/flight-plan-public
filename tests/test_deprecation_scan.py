"""Unit tests for scripts/deprecation_scan.py."""

import subprocess
from pathlib import Path

import deprecation_scan as ds


def _git(repo: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(repo), *args], check=True,
                   capture_output=True, text=True)


def _new_repo(tmp_path: Path) -> Path:
    repo = tmp_path / "proj"
    (repo / ".claude" / "memory").mkdir(parents=True)
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    _git(repo, "config", "user.email", "t@t")
    _git(repo, "config", "user.name", "t")
    (repo / "README.md").write_text("start\n")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "c0")
    return repo


ACTIVE = """# Deprecations

## 2026-06-01 — DEPRECATED: axios
Replaced by: native fetch
Why: extra dependency.
Status: ACTIVE
Ticket: PROJ-123
"""

RESOLVED = ACTIVE.replace("Status: ACTIVE", "Status: RESOLVED")


def test_parse_active_only(tmp_path):
    f = tmp_path / "deprecations.md"
    f.write_text(ACTIVE + "\n## 2026-06-02 — DEPRECATED: moment\nStatus: RESOLVED\n")
    entries = ds.parse_active_deprecations(f)
    assert len(entries) == 1
    assert entries[0]["name"] == "axios"
    assert entries[0]["replaced_by"] == "native fetch"
    assert entries[0]["ticket"] == "PROJ-123"


def test_parse_missing_file(tmp_path):
    assert ds.parse_active_deprecations(tmp_path / "nope.md") == []


def test_keywords_include_dotted_and_base(tmp_path):
    f = tmp_path / "deprecations.md"
    f.write_text("# Deprecations\n\n## d — DEPRECATED: passport.js auth\nStatus: ACTIVE\n")
    kw = ds.parse_active_deprecations(f)[0]["keywords"]
    assert "passport.js" in kw
    assert "passport" in kw  # base form without extension
    assert "auth" in kw


def test_find_hits_active(tmp_path):
    repo = _new_repo(tmp_path)
    (repo / ".claude" / "memory" / "deprecations.md").write_text(ACTIVE)
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "dep")
    (repo / "client.js").write_text('import axios from "axios";\n')
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "use axios")

    hits = ds.find_hits(str(repo), "HEAD~1")
    assert len(hits) == 1
    assert hits[0]["name"] == "axios"
    assert "axios" in hits[0]["matched_keywords"]


def test_find_hits_resolved_silent(tmp_path):
    repo = _new_repo(tmp_path)
    (repo / ".claude" / "memory" / "deprecations.md").write_text(RESOLVED)
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "dep")
    (repo / "client.js").write_text('import axios from "axios";\n')
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "use axios")

    assert ds.find_hits(str(repo), "HEAD~1") == []


def test_find_hits_no_match(tmp_path):
    repo = _new_repo(tmp_path)
    (repo / ".claude" / "memory" / "deprecations.md").write_text(ACTIVE)
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "dep")
    (repo / "client.js").write_text("const x = 1;\n")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-qm", "unrelated")

    assert ds.find_hits(str(repo), "HEAD~1") == []
