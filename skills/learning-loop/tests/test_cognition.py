"""Tests for the Learning Loop cognition store."""
import importlib.util
import sqlite3
from pathlib import Path

_SPEC = importlib.util.spec_from_file_location(
    "cognition", Path(__file__).resolve().parent.parent / "scripts" / "cognition.py")
cog = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(cog)


def _conn(tmp_path):
    return cog.connect(str(tmp_path / "cognition.db"))


def test_new_correction_logs(tmp_path):
    conn = _conn(tmp_path)
    msg = cog.record(conn, "test subject", "did X", "do Y",
                     target=str(tmp_path / "conventions.md"))
    assert "new correction" in msg
    assert conn.execute("SELECT COUNT(*) FROM corrections").fetchone()[0] == 1


def test_dedup_and_promote_at_three(tmp_path):
    conn = _conn(tmp_path)
    target = tmp_path / "conventions.md"
    cog.record(conn, "Telegram alerts", "sent to telegram", "keep local",
               keywords="telegram,alerts", target=str(target))
    cog.record(conn, "Telegram alerts", "telegram again", "local only",
               keywords="telegram", target=str(target))  # different keywords, same subject
    msg = cog.record(conn, "telegram alert", "third time", "no external notifications",
                     target=str(target))  # fuzzy-matched singular
    # one row, promoted, and the pattern was written
    assert conn.execute("SELECT COUNT(*) FROM corrections").fetchone()[0] == 1
    assert "promoted" in msg
    assert conn.execute("SELECT promoted FROM corrections").fetchone()[0] == 1
    assert target.exists() and "no external notifications" in target.read_text()


def test_distinct_subjects_stay_separate(tmp_path):
    conn = _conn(tmp_path)
    t = str(tmp_path / "conventions.md")
    cog.record(conn, "telegram alerts", "a", "b", target=t)
    cog.record(conn, "van breakover lectures", "c", "d", target=t)
    assert conn.execute("SELECT COUNT(*) FROM corrections").fetchone()[0] == 2


def test_promote_only_once(tmp_path):
    conn = _conn(tmp_path)
    t = str(tmp_path / "conventions.md")
    for _ in range(4):
        msg = cog.record(conn, "same thing", "wrong", "right", target=t)
    # 4th call increments but does not re-promote
    assert "repeat #4" in msg
    assert t and Path(t).read_text().count("same thing") == 1


def test_sweep_removes_expired_unpromoted(tmp_path):
    conn = _conn(tmp_path)
    conn.execute(
        "INSERT INTO corrections (signature, subject, wrong_fact, correct_fact, "
        "created_at, last_corrected_at, expires_at, promoted) "
        "VALUES ('old','old','w','c','2020-01-01','2020-01-01','2020-01-08',0)")
    conn.commit()
    cog.cmd_sweep(conn)
    assert conn.execute("SELECT COUNT(*) FROM corrections").fetchone()[0] == 0
