---
name: reviewing-docs
description: Use when reviewing a generated document against what it was generated from — a user guide against code, a research summary against experiment logs and the sources it cites, a blog article against the facts it claims. Activates on "review this document", "check this against the source", "verify these claims", "does this guide/summary/report hold up", or before publishing generated writing. Runs a blind, adversarial review on two tracks: fidelity to the source you provide, and verification of factual claims against the real world. Plus an optional second-model pass. The point is to stop the author from grading its own homework.
---

# Reviewing Docs

This reviews a **generated document against what it was generated from**. The source can be code, an app's UI, research papers, experiment logs, data, notes, a transcript, web research, or the author's own claims.

Two failure modes it exists to catch:
1. The model that wrote the document grading its own document. Same-context self-review anchors on its own choices and hands you reassurance.
2. A document that reads confidently while quietly fabricating, misattributing, overstating, or dropping the caveats the source actually had. Generated writing sounds equally sure whether or not anything backs it up. That gap is the main target.

## Two engines

Real documents need both. Decide which apply before you start.

- **Engine A — fidelity to a source you provide.** "Does the document match this thing it came from." A user guide vs the code. A summary vs the experiment logs. Local, deterministic, no web needed.
- **Engine B — claim verification.** "Are the document's factual claims actually true and faithfully represented." This has to go *out* and check, because a document's own citations cannot be trusted to say what the document says they say. You cannot verify a claim by reading the thing that makes it.

A user guide from code is almost all Engine A. A research doc from logs + web research is A (the logs) plus B (the web claims). A blog article is mostly B, plus a sorting step to leave the author's opinions alone.

Both engines run the same way: a reviewer that is **blind** (never saw it written), **adversarial** (job is to prove it wrong), and **grounded** (checks against the real source, not the document's account of the source). A genuinely different model is optional (Step 5); it matters far more for Engine B than Engine A.

## What you need before starting

- **The artifact** — the document under review (path).
- **Its sources** — what it was generated from. Can be *provided* (code, app UI, logs, notes, transcript, cited papers) and/or *external* (web research the document relied on, general factual claims). Establish explicitly what this document was generated from. If the user didn't say, ask. Without a source the review collapses to prose-quality only, and you must flag that.

## Step 1 — Build the source map (provided sources)

Extract what the provided source actually contains, from the source, not from the document. Method depends on type:

- **Code / app** — enumerate real features, commands, menu items, buttons, settings, current labels. Note version and anything renamed or removed.
- **Logs / data / research you hold** — extract the actual results, numbers, decisions, and the caveats/limitations they state. Note what they explicitly do NOT claim.
- **Notes / transcript / interview** — extract what was actually said, by whom, with what hedging.

If the document also rests on external research (web), you don't map that here — it gets verified live in Step 4.

## Step 2 — Extract and classify the document's claims

Pull the discrete claims, instructions, numbers, and quotes out of the document. Tag each:

- **Internal-traceable** — should be backed by the provided source map. → Engine A (Step 3).
- **Externally-checkable** — a fact about the world: a statistic, a "research shows," a named attribution, a cited study. → Engine B (Step 4).
- **Opinion / experience** — the author's judgment, taste, or lived experience. Not verifiable. Flag it as the author's and leave it alone. Do NOT fact-check taste.

This classification is what lets one review handle a code-based guide, a research doc, and an opinion blog post.

## Step 3 — Engine A: blind adversarial fidelity review (subagents)

Spawn reviewer subagents over the internal-traceable claims + the document. Each gets ONLY the artifact + the source map + its rubric. Never tell them who wrote it. One lens per agent:

- **Traceability** (highest value) — every internal claim, instruction, name, and number must trace to the source map. Flag any with nothing behind it. Those are fabrications.
- **Faithfulness** — for claims that DO trace: does the document overstate, soften a caveat, drop an "approximately," misattribute, or state-as-certain something the source hedged? The document sounding sure is not evidence the source was.
- **Completeness** — walk the source map. What important content, feature, finding, or caveat did the document drop or underweight?
- **Audience** — role-play the intended reader (confused first-timer, skeptical exec, peer). Where do they get stuck, hit an undefined term, or lack a prerequisite the document never gave?

Frame every reviewer: *"Assume this document misrepresents its source. Prove it. Default to flagging."* Each returns: location, what's wrong, the source it does/doesn't trace to, severity, the fix.

## Step 4 — Engine B: claim verification (externally-checkable claims)

For each externally-checkable claim, spawn a verifier that actually goes and checks:

1. **Find the real source** — fetch the URL the document cites; if it cites none, search for the claim's origin.
2. **Confirm it exists** — a cited study/page/number that can't be found is a red flag, not a pass.
3. **Confirm it says what the document says** — read the source and check the claim against it. Misattribution and "the source says something adjacent but not this" are the common failures.
4. **Confirm it isn't overstated** — did the document drop the sample size, the "in some cases," the hedge, the date?

Verdict per claim: **supported / overstated / misattributed / unsupported-or-fabricated / can't-verify**. Adversarial: try to refute the claim; default to "not verified" when you can't confirm. This is where a second model and live web access pay off most.

## Step 5 — Optional: a genuinely different model

For subjective calls and independent re-verification, run a cross-model pass IF a provider is configured. Skip local models (weaker, must stay running). Hosted options:

- **OpenRouter** (preferred) — one `OPENROUTER_API_KEY` reaches any model. Defaults to Gemini 3.1 Pro (`google/gemini-3.1-pro-preview`); swap models with `OPENROUTER_MODEL`. OpenAI-compatible.
- **Gemini** (Google AI Studio direct, free tier) — `GEMINI_API_KEY`.
- **GitHub Models** — free, rate-limited OpenAI/other model via a GitHub token you already have.
- **OpenAI / Codex** — strongest for code/logic; `OPENAI_API_KEY`, or Codex CLI (`codex exec ...`) for an agentic pass that reads the source itself. Worth more for code review than document fidelity.

Run it with the bundled helper, which auto-detects the provider from whichever key is set (or pass `--provider`):

```
~/flight-plan/scripts/second-opinion.py --doc <document> --source <source-map-or-file> [--provider openrouter|gemini|github-models|openai|codex]
```

It prints the other model's findings to stdout (exit 2 = no provider configured, just skip). Collect them, then reconcile against the blind-Claude pass: agreement = high confidence; disagreement = surface both, don't auto-resolve. The blind-grounded-adversarial pass is the foundation; the second model is a tiebreaker.

### Two-stage pipeline (reasoning, then citation check)

The strongest setup, all through one OpenRouter key — a reasoner reviews, then a search model verifies the facts:

```
# 1. Gemini 3.1 Pro — adversarial review (with a source, checks fidelity; without one, flags claims that need checking)
~/flight-plan/scripts/second-opinion.py --doc DOC --provider openrouter --mode review [--source SRC]

# 2. Perplexity Sonar — live web fact-check of the document's citations and claims
~/flight-plan/scripts/second-opinion.py --doc DOC --provider openrouter --model perplexity/sonar --mode verify
```

`--mode review` with **no `--source`** is the common case for AI-written docs that have no separate source: Gemini flags every confident factual claim as "needs external verification," and stage 2 (Sonar) actually checks them on the web. Feed stage 1's flagged claims into stage 2.

## Step 6 — Report, then revise

Present findings grouped:
- **Must fix** — fidelity defects (Engine A) + unsupported / fabricated / misattributed claims (Engine B).
- **Should fix** — overstatements, dropped caveats, completeness gaps.
- **Opinion / unverifiable** — noted and left to the author's judgment.
- **Second-model disagreements** — if Step 5 ran.

Do NOT silently rewrite. Show the findings first. On approval, apply fixes, then re-run the relevant engine on the revised document until the must-fix list is empty. Convergence, not one-shot.

## The rule

A review that only someone who watched it being written would pass is not a review. The reviewer must be blind, adversarial, and checking against the real source — the provided source for Engine A, the actual world for Engine B. If you didn't establish what the document was generated from, classify its claims, and check them against something outside the document, you didn't review it. You proofread it.
