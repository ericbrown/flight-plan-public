#!/usr/bin/env python3
"""
second-opinion.py — get a genuinely different model to review a document.

Used by the `reviewing-docs` skill (Step 5/6) to add an independent, cross-model
review on top of the blind Claude subagent pass. Stdlib only, no pip installs.

It sends the document + the source/context it should be faithful to, with a blind
adversarial rubric, to whichever provider is configured, and prints that model's
findings to stdout. The skill captures and reconciles them.

PROVIDERS (pick with --provider or REVIEW_PROVIDER; auto-detects by which key is set):
  openrouter     OPENROUTER_API_KEY    one key -> any model; default Gemini 3.1 Pro (preferred)
  gemini         GEMINI_API_KEY        Google AI Studio direct, free tier
  github-models  GITHUB_TOKEN          free, rate-limited OpenAI/other via your GH token
  openai         OPENAI_API_KEY        OpenAI API (pay per token)
  codex          (codex CLI on PATH)   agentic pass; reads sources itself

Model names and endpoints drift. Override per provider with the *_MODEL env vars
below, and verify current values in each provider's docs if a call 400s.

Usage:
  second-opinion.py --doc PATH [--source PATH] [--provider NAME] [--model M] [--mode review|verify]

  # fidelity review against a source (e.g. a guide vs the code):
  second-opinion.py --doc guide.md --source <(cat src/**/*.py) --provider openrouter

  # AI-written doc with NO source — flag claims that need checking, then web-verify them:
  second-opinion.py --doc post.md --provider openrouter --mode review
  second-opinion.py --doc post.md --provider openrouter --model perplexity/sonar-pro --mode verify

--source is OPTIONAL. In --mode review without a source, the model flags every confident
factual claim as needing verification; --mode verify (Perplexity Sonar) checks them on the web.
Use perplexity/sonar-pro for verify, NOT base perplexity/sonar — the base tier loops on
short docs (it once repeated one line 496 times). All chat calls are now token-capped and
penalised against repetition, and a degenerate-output guard fails loudly if a model loops.

Exit codes: 0 ok, 2 no provider/key configured, 3 provider/API error.
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

# Endpoints + default models — override via env when they drift.
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-4o")
GITHUB_MODEL = os.environ.get("GITHUB_MODEL", "openai/gpt-4o")
GITHUB_MODELS_URL = os.environ.get(
    "GITHUB_MODELS_URL", "https://models.github.ai/inference/chat/completions"
)
# OpenRouter: one key, any model. Default routes to Gemini 3.1 Pro (verified slug
# from openrouter.ai/api/v1/models on 2026-06-05; 1M context, $2/M in, $12/M out).
# Override with OPENROUTER_MODEL; check openrouter.ai/models for newer/cheaper slugs.
OPENROUTER_MODEL = os.environ.get("OPENROUTER_MODEL", "google/gemini-3.1-pro-preview")
OPENROUTER_URL = os.environ.get(
    "OPENROUTER_URL", "https://openrouter.ai/api/v1/chat/completions"
)

# Output bounding. Without a cap, a weak model (notably perplexity/sonar) will run
# to its context limit repeating one line — it once emitted the same sentence 496
# times for a 700-word post. max_tokens hard-bounds it; frequency_penalty + low
# temperature discourage degenerate repetition. All env-overridable.
REVIEW_MAX_TOKENS = int(os.environ.get("REVIEW_MAX_TOKENS", "4000"))
REVIEW_TEMPERATURE = float(os.environ.get("REVIEW_TEMPERATURE", "0.2"))
REVIEW_FREQ_PENALTY = float(os.environ.get("REVIEW_FREQ_PENALTY", "0.6"))

RUBRIC = """You are a BLIND, ADVERSARIAL reviewer. You did not write this document and
you must not assume it is correct. Your job is to prove it wrong.

You are given a DOCUMENT and the SOURCE it is supposed to be faithful to.

Find, specifically:
1. Claims, numbers, names, or quotes in the document that the source does NOT support (fabrications).
2. Claims that the source supports but the document OVERSTATES, or where it dropped a caveat / hedge / sample size / date.
3. Misattributions (the source says something adjacent but not this).
4. Important things in the source the document DROPPED or underweighted.

Ignore matters of taste and the author's stated opinions or personal experience.
Default to flagging when unsure.

Return a concise list of findings. For each: a short location/quote from the document,
what is wrong, the severity (blocker | should-fix | nit), and the specific fix."""

REVIEW_NO_SOURCE_RUBRIC = """You are a BLIND, ADVERSARIAL reviewer. You are given a DOCUMENT
written with AI help. There is NO separate source to check it against — so your job is to
find what is weak, overstated, or unverified, and to flag what needs external checking.

Find, specifically:
1. Factual claims stated confidently with no citation — statistics, named studies,
   attributions, "research shows", dated facts, quotes. List each and mark it
   "NEEDS EXTERNAL VERIFICATION" (a separate web fact-checker will confirm these).
2. Overstatements and dropped hedges — confident phrasing the evidence may not support.
3. Internal contradictions, or claims that don't follow from what precedes them.
4. Anything that reads as fabricated, too clean, or suspiciously specific.

Ignore matters of taste and the author's stated opinions or personal experience.
Return findings: a short quote, what is wrong, severity (blocker | should-fix | nit),
and the fix. Clearly separate the claims that need external verification."""

VERIFY_RUBRIC = """You are a fact-checker with live web access. You are given a DOCUMENT.
Pull out its checkable factual claims: statistics, named studies, attributions,
"research shows" statements, dated facts, and quotes.

For EACH checkable claim, search the web and verify:
1. Does the cited or implied source actually exist?
2. Does that source actually say what the document claims? (watch for misattribution)
3. Is the document overstating it, or did it drop a caveat / sample size / date?

Return, per claim: the claim, a verdict (supported | overstated | misattributed |
unsupported-or-fabricated | cannot-verify), the source URL you checked, and a one-line note.
Ignore opinions and the author's personal experience — verify only checkable facts.
This pass pairs with a separate reasoning review; focus on citations and facts."""


def build_prompt(doc: str, source: str, extra: str, mode: str = "review") -> str:
    if mode == "verify":
        rubric = VERIFY_RUBRIC          # web citation check; source rarely needed
    elif source:
        rubric = RUBRIC                 # fidelity to the provided source
    else:
        rubric = REVIEW_NO_SOURCE_RUBRIC  # no source: flag unverified/overstated claims
    parts = [rubric]
    if extra:
        parts.append("ADDITIONAL INSTRUCTIONS:\n" + extra)
    parts.append("=== DOCUMENT UNDER REVIEW ===\n" + doc)
    if source:
        parts.append("=== SOURCE OF TRUTH ===\n" + source)
    return "\n\n".join(parts)


def _post(url: str, headers: dict, body: dict, timeout: int = 120) -> dict:
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(), headers=headers, method="POST"
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def _chat_body(model: str, prompt: str) -> dict:
    # Bounded, penalised chat body shared by all OpenAI-style providers (incl.
    # OpenRouter). The cap + penalty are what stop weak models from looping.
    return {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": REVIEW_MAX_TOKENS,
        "temperature": REVIEW_TEMPERATURE,
        "frequency_penalty": REVIEW_FREQ_PENALTY,
    }


def _guard_degenerate(text: str) -> str:
    # Fail LOUDLY if the model looped instead of answering. A 500-line garbage
    # response reads as "the fact-check ran" when it didn't — that's worse than
    # an error, because it silently passes the gate. Caller turns this into exit 3.
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    if len(lines) >= 12 and len(set(lines)) / len(lines) < 0.4:
        raise RuntimeError(
            f"degenerate output: {len(lines)} non-blank lines, only "
            f"{len(set(lines))} unique — the model looped. Use a stronger model "
            "(e.g. --model perplexity/sonar-pro), not base perplexity/sonar."
        )
    return text


def call_gemini(prompt: str) -> str:
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        raise KeyError("GEMINI_API_KEY not set")
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GEMINI_MODEL}:generateContent?key={key}"
    )
    data = _post(url, {"Content-Type": "application/json"},
                 {"contents": [{"parts": [{"text": prompt}]}],
                  "generationConfig": {"maxOutputTokens": REVIEW_MAX_TOKENS,
                                       "temperature": REVIEW_TEMPERATURE}})
    return _guard_degenerate(data["candidates"][0]["content"]["parts"][0]["text"])


def _openai_style(url: str, key: str, model: str, prompt: str) -> str:
    data = _post(
        url,
        {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        _chat_body(model, prompt),
    )
    return _guard_degenerate(data["choices"][0]["message"]["content"])


def call_openai(prompt: str) -> str:
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        raise KeyError("OPENAI_API_KEY not set")
    return _openai_style("https://api.openai.com/v1/chat/completions", key, OPENAI_MODEL, prompt)


def call_github_models(prompt: str) -> str:
    key = os.environ.get("GITHUB_TOKEN")
    if not key:
        raise KeyError("GITHUB_TOKEN not set")
    return _openai_style(GITHUB_MODELS_URL, key, GITHUB_MODEL, prompt)


def call_openrouter(prompt: str) -> str:
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise KeyError("OPENROUTER_API_KEY not set")
    data = _post(
        OPENROUTER_URL,
        {
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            # Optional attribution headers OpenRouter uses for its rankings.
            "HTTP-Referer": "https://github.com/ericbrown/flight-plan-public",
            "X-Title": "flight-plan reviewing-docs",
        },
        _chat_body(OPENROUTER_MODEL, prompt),
    )
    return _guard_degenerate(data["choices"][0]["message"]["content"])


def call_codex(prompt: str) -> str:
    # Agentic pass via the Codex CLI. Requires `codex` on PATH and authenticated.
    proc = subprocess.run(
        ["codex", "exec", prompt],
        capture_output=True, text=True, timeout=600,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "codex exec failed")
    return proc.stdout.strip()


PROVIDERS = {
    "openrouter": (call_openrouter, "OPENROUTER_API_KEY"),
    "gemini": (call_gemini, "GEMINI_API_KEY"),
    "openai": (call_openai, "OPENAI_API_KEY"),
    "github-models": (call_github_models, "GITHUB_TOKEN"),
    "codex": (call_codex, None),
}


def autodetect() -> str | None:
    if os.environ.get("REVIEW_PROVIDER"):
        return os.environ["REVIEW_PROVIDER"]
    for name in ("openrouter", "gemini", "github-models", "openai"):
        if os.environ.get(PROVIDERS[name][1]):
            return name
    if subprocess.run(["which", "codex"], capture_output=True).returncode == 0:
        return "codex"
    return None


def read_arg(value: str) -> str:
    # Treat as a path if it exists, otherwise as literal text.
    if value and os.path.exists(value):
        with open(value, encoding="utf-8", errors="replace") as f:
            return f.read()
    return value or ""


def main() -> int:
    ap = argparse.ArgumentParser(description="Cross-model second-opinion review.")
    ap.add_argument("--doc", required=True, help="Document under review (path or text).")
    ap.add_argument("--source", default="", help="Source of truth (path or text). Optional in --mode verify.")
    ap.add_argument("--rubric", default="", help="Optional extra instructions.")
    ap.add_argument("--provider", default="", help="openrouter | gemini | github-models | openai | codex.")
    ap.add_argument("--model", default="", help="Override the model for this call (e.g. perplexity/sonar).")
    ap.add_argument("--mode", default="review", choices=["review", "verify"],
                    help="review = adversarial fidelity (Gemini); verify = web citation check (Sonar).")
    args = ap.parse_args()

    provider = args.provider or autodetect()
    if not provider:
        print(
            "No second-opinion provider configured. Set one of GEMINI_API_KEY, "
            "GITHUB_TOKEN, or OPENAI_API_KEY, or install the codex CLI, or pass "
            "--provider. Skipping the cross-model pass.",
            file=sys.stderr,
        )
        return 2
    if provider not in PROVIDERS:
        print(f"Unknown provider: {provider}. Choices: {', '.join(PROVIDERS)}", file=sys.stderr)
        return 2

    # --model overrides the model for the selected provider (all OpenAI-style providers
    # plus openrouter/gemini reuse the same module-level *_MODEL global at call time).
    if args.model:
        model_globals = {
            "openrouter": "OPENROUTER_MODEL", "gemini": "GEMINI_MODEL",
            "openai": "OPENAI_MODEL", "github-models": "GITHUB_MODEL",
        }
        if provider in model_globals:
            globals()[model_globals[provider]] = args.model

    prompt = build_prompt(read_arg(args.doc), read_arg(args.source),
                          read_arg(args.rubric), mode=args.mode)
    fn = PROVIDERS[provider][0]
    try:
        model_note = f" ({args.model})" if args.model else ""
        print(f"# Second opinion via: {provider}{model_note} [mode={args.mode}]\n", file=sys.stderr)
        print(fn(prompt))
        return 0
    except KeyError as e:
        print(str(e), file=sys.stderr)
        return 2
    except (urllib.error.HTTPError, urllib.error.URLError) as e:
        detail = ""
        if isinstance(e, urllib.error.HTTPError):
            try:
                detail = e.read().decode()[:300]
            except Exception:
                pass
        print(f"{provider} API error: {e} {detail}", file=sys.stderr)
        return 3
    except Exception as e:
        print(f"{provider} failed: {e}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main())
