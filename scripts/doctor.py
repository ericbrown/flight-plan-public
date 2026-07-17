#!/usr/bin/env python3
"""doctor.py — Flight Plan install + environment health check.

Flight Plan ships via install.sh across machines and projects. This validates that
a project is actually set up to use it, and that the delegate CLIs are available —
so "grok CLI not authed" or "hooks didn't install" surfaces here instead of failing
confusingly mid-session. It does NOT auto-repair (there are no data pipelines to fix);
it reports, like a linter for your setup.

Checks: delegate CLIs on PATH, .claude/ present, Memory Bank files, hooks/settings,
secrets.env, Linear config. Run from a project root (or pass --root).

Exit code: 0 if clean, 1 if any FAIL. Usage: python3 scripts/doctor.py [--root DIR] [--quiet]
"""
import argparse
import shutil
import sys
from pathlib import Path

OK, WARN, FAIL = "OK", "WARN", "FAIL"
ICON = {OK: "✅", WARN: "🔶", FAIL: "❌"}


def fp_home():
    """Where Flight Plan itself is installed (this script's repo root)."""
    return Path(__file__).resolve().parent.parent


def discover_delegates():
    """The CLI tools this Flight Plan ships delegate skills for — derived from
    skills/<name>/scripts/<tool>_delegate.py, so it stays accurate per install."""
    tools = set()
    for p in (fp_home() / "skills").glob("*/scripts/*_delegate.py"):
        tools.add(p.name.replace("_delegate.py", ""))
    # normalize a couple of known aliases to their binary names
    alias = {"claude": "claude"}
    return sorted(alias.get(t, t) for t in tools)


def check(results, status, label, detail):
    results.append((status, label, detail))


def run_checks(root):
    results = []
    claude_dir = root / ".claude"

    # 1. Delegate CLIs on PATH
    delegates = discover_delegates()
    if not delegates:
        check(results, WARN, "Delegate CLIs", "no *_delegate.py skills found")
    for tool in delegates:
        if shutil.which(tool):
            check(results, OK, f"CLI: {tool}", "on PATH (auth not verified here)")
        else:
            check(results, WARN, f"CLI: {tool}", f"'{tool}' not on PATH — delegation to it will fail")

    # 2. Project initialized
    if claude_dir.is_dir():
        check(results, OK, ".claude/", "present")
    else:
        check(results, FAIL, ".claude/", f"missing in {root} — run install.sh / init")
        return results  # nothing else to check

    # 3. Memory Bank
    mem = claude_dir / "memory"
    expected = ["projectContext.md", "activeContext.md", "progress.md",
                "decisionLog.md", "conventions.md", "sessionHistory.md"]
    if mem.is_dir():
        missing = [f for f in expected if not (mem / f).exists()]
        if missing:
            check(results, WARN, "Memory Bank", f"missing: {', '.join(missing)}")
        else:
            check(results, OK, "Memory Bank", f"all {len(expected)} files present")
    else:
        check(results, WARN, "Memory Bank", ".claude/memory/ missing — run /memory-init")

    # 4. Hooks / settings
    settings = next((s for s in [claude_dir / "settings.json",
                                 claude_dir / "settings.local.json"] if s.exists()), None)
    if settings and "hooks" in settings.read_text():
        check(results, OK, "Hooks", f"configured in {settings.name}")
    elif settings:
        check(results, WARN, "Hooks", f"{settings.name} present but no hooks configured")
    else:
        check(results, WARN, "Hooks", "no .claude/settings.json — hooks not installed")

    # 5. secrets.env (delegate CLI keys)
    secrets = next((s for s in [root / "secrets.env", fp_home() / "secrets.env"] if s.exists()), None)
    check(results, OK if secrets else WARN, "secrets.env",
          str(secrets) if secrets else "not found — delegate CLIs may lack API keys")

    # 6. Linear config
    cfg = claude_dir / "project-config.json"
    if cfg.exists() and ("linear" in cfg.read_text().lower() or "team" in cfg.read_text().lower()):
        check(results, OK, "Linear config", "project-config.json has team/Linear info")
    else:
        check(results, WARN, "Linear config", "project-config.json missing or no Linear team set")

    return results


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args(argv)

    results = run_checks(Path(args.root).resolve())
    order = {FAIL: 0, WARN: 1, OK: 2}
    print("# Flight Plan Doctor\n")
    for status, label, detail in sorted(results, key=lambda r: order[r[0]]):
        if args.quiet and status == OK:
            continue
        print(f"{ICON[status]} {label:18} {detail}")
    fails = sum(1 for r in results if r[0] == FAIL)
    warns = sum(1 for r in results if r[0] == WARN)
    print(f"\n{len(results)} checks — ✅ {sum(1 for r in results if r[0]==OK)}  "
          f"🔶 {warns}  ❌ {fails}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
