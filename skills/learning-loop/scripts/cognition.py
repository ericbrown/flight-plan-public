#!/usr/bin/env python3
"""cognition.py — the Learning Loop: corrections that auto-promote to permanent patterns.

A correction the user gives the agent is recorded here with a 7-day TTL. If the
SAME correction recurs, its counter increments and the TTL refreshes. At the 3rd
occurrence it auto-promotes: it escapes the TTL and is written into the project's
Memory Bank conventions (`.claude/memory/conventions.md`) as a permanent learned
pattern — which flight-plan's existing self-improvement loop can then sync to
CLAUDE.md. Without the promotion step, today's fix expires next week and the same
mistake comes back.

Local only — a SQLite table in `.claude/cognition.db` (add it to .gitignore).

Capture happens two ways (both call record()):
  - LIVE: when the user corrects the agent, run
      cognition.py correction --subject "..." --wrong "..." --correct "..."
  - SESSION-END / NIGHTLY: a scrape pass reads recent session logs and records
    what live capture missed.

Commands:
  cognition.py correction --subject S --wrong W --correct C [--keywords a,b]
  cognition.py list [--all]
  cognition.py sweep
"""
import argparse
import re
import sqlite3
from datetime import datetime, timedelta, timezone
from difflib import SequenceMatcher
from pathlib import Path

TTL_DAYS = 7
PROMOTION_THRESHOLD = 3
_WORD = re.compile(r"[a-z0-9]+")


def project_root(start=None):
    """Walk up from cwd to the nearest dir containing .claude/ (else cwd)."""
    p = Path(start or Path.cwd()).resolve()
    for d in [p, *p.parents]:
        if (d / ".claude").is_dir():
            return d
    return Path.cwd()


def default_db(root):
    return root / ".claude" / "cognition.db"


def default_target(root):
    return root / ".claude" / "memory" / "conventions.md"


def now():
    return datetime.now(timezone.utc)


def iso(dt):
    return dt.isoformat()


def signature(subject):
    """Dedup key = normalized subject. Keywords are metadata, not part of the key,
    so the same correction dedups even if wording drifts between occurrences."""
    return " ".join(_WORD.findall(subject.lower()))


def connect(db_path):
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("""
        CREATE TABLE IF NOT EXISTS corrections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            signature TEXT NOT NULL,
            subject TEXT NOT NULL,
            keywords TEXT,
            wrong_fact TEXT,
            correct_fact TEXT,
            created_at TEXT NOT NULL,
            last_corrected_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            repeat_count INTEGER DEFAULT 1,
            promoted INTEGER DEFAULT 0
        )""")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_sig ON corrections(signature)")
    conn.commit()
    return conn


def _find_match(conn, sig):
    """Exact signature match, else the closest fuzzy subject match (>=0.8)."""
    row = conn.execute(
        "SELECT * FROM corrections WHERE signature = ? ORDER BY id LIMIT 1", (sig,)).fetchone()
    if row:
        return row
    best, best_ratio = None, 0.0
    for r in conn.execute("SELECT * FROM corrections").fetchall():
        ratio = SequenceMatcher(None, sig, r["signature"]).ratio()
        if ratio > best_ratio:
            best, best_ratio = r, ratio
    return best if best_ratio >= 0.8 else None


def record(conn, subject, wrong, correct, keywords="", target=None, dry_run=False):
    sig = signature(subject)
    n = now()
    row = _find_match(conn, sig)
    if row:
        new_count = row["repeat_count"] + 1
        conn.execute(
            "UPDATE corrections SET repeat_count = ?, last_corrected_at = ?, "
            "expires_at = ?, correct_fact = ? WHERE id = ?",
            (new_count, iso(n), iso(n + timedelta(days=TTL_DAYS)), correct, row["id"]))
        conn.commit()
        if new_count >= PROMOTION_THRESHOLD and not row["promoted"]:
            _promote(conn, row["id"], subject, wrong, correct, new_count, target, dry_run)
            return f"promoted (seen {new_count}x) -> permanent pattern"
        return f"repeat #{new_count} (promotes at {PROMOTION_THRESHOLD})"

    conn.execute(
        "INSERT INTO corrections (signature, subject, keywords, wrong_fact, correct_fact, "
        "created_at, last_corrected_at, expires_at) VALUES (?,?,?,?,?,?,?,?)",
        (sig, subject, keywords, wrong, correct, iso(n), iso(n),
         iso(n + timedelta(days=TTL_DAYS))))
    conn.commit()
    return "new correction logged (7-day TTL)"


def _promote(conn, cid, subject, wrong, correct, count, target, dry_run):
    """Append a permanent learned pattern to the Memory Bank conventions file."""
    today = now().strftime("%Y-%m-%d")
    entry = (f"\n### {today} — {subject.strip()}\n"
             f"**Trigger:** recurring correction (seen {count}x): {wrong.strip()}\n"
             f"**Rule:** {correct.strip()}\n")
    if dry_run:
        print(f"  [dry-run] would append to {target}:\n{entry}")
    else:
        Path(target).parent.mkdir(parents=True, exist_ok=True)
        with open(target, "a", encoding="utf-8") as f:
            f.write(entry)
    conn.execute("UPDATE corrections SET promoted = 1, expires_at = ? WHERE id = ?",
                 (iso(now() + timedelta(days=3650)), cid))
    conn.commit()


def cmd_list(conn, show_all):
    n = iso(now())
    q = ("SELECT * FROM corrections ORDER BY promoted DESC, repeat_count DESC" if show_all
         else "SELECT * FROM corrections WHERE expires_at > ? OR promoted = 1 "
              "ORDER BY promoted DESC, repeat_count DESC")
    rows = conn.execute(q, () if show_all else (n,)).fetchall()
    if not rows:
        print("no corrections tracked")
        return
    for r in rows:
        flag = "* PROMOTED" if r["promoted"] else f"{r['repeat_count']}/{PROMOTION_THRESHOLD}"
        print(f"  [{flag:>10}] {r['subject'][:60]}")
        print(f"               wrong: {(r['wrong_fact'] or '')[:70]}")
        print(f"               right: {(r['correct_fact'] or '')[:70]}")


def cmd_sweep(conn):
    cur = conn.execute("DELETE FROM corrections WHERE expires_at <= ? AND promoted = 0",
                       (iso(now()),))
    conn.commit()
    print(f"swept {cur.rowcount} expired unpromoted correction(s)")


def main():
    root = project_root()
    ap = argparse.ArgumentParser(description="Learning Loop — corrections auto-promote to patterns.")
    ap.add_argument("--db", default=str(default_db(root)))
    ap.add_argument("--target", default=str(default_target(root)),
                    help="promotion target (Memory Bank conventions.md)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("correction")
    c.add_argument("--subject", required=True)
    c.add_argument("--wrong", required=True)
    c.add_argument("--correct", required=True)
    c.add_argument("--keywords", default="")
    c.add_argument("--dry-run", action="store_true")

    l = sub.add_parser("list")
    l.add_argument("--all", action="store_true")
    sub.add_parser("sweep")

    args = ap.parse_args()
    conn = connect(args.db)
    if args.cmd == "correction":
        print(record(conn, args.subject, args.wrong, args.correct,
                     args.keywords, args.target, args.dry_run))
    elif args.cmd == "list":
        cmd_list(conn, args.all)
    elif args.cmd == "sweep":
        cmd_sweep(conn)


if __name__ == "__main__":
    main()
