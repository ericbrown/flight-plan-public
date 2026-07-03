---
description: "Verify/revise a thesis, argument, draft, or plan into a defensible artifact. Bounded proof loop, then locks hardened/final.md. Usage: /harden [path or pasted text]"
---

You are running the harden primitive. Take an existing seed (a thesis, argument, claim, draft, or plan) and run a BOUNDED verify-and-revise cycle on it before it gets used. `/verify` checks code; `/harden` checks an idea.

The seed can be:
- an existing `plan.md` or design doc in the working dir
- a file the user points at
- text the user pasted into the prompt

**One rule above all: only ask questions that change the proof bar, the loop structure, or the stop rule.** Everything else you decide with a reasonable default and state as an assumption.

If the seed is too foggy to state as a one-sentence thesis with a clear conclusion, STOP. Tell the user to sharpen it first (or run `/plan-context` on it to firm up scope), then come back. Do not plan a loop around a fog.

---

## Stage 1 — Frame The Thesis

Read the seed. Reflect back, tightly:

```
## Harden: [short name]

Thesis (one sentence): [the claim, stated so it could be true or false]
Intended use:          [where this goes next — a PR, a pitch, a decision, a doc]
Conclusion at risk:    [what the thesis is asking the reader to accept]
Stakes:                [low / medium / high — drives how many passes]
```

If you cannot write the thesis as one falsifiable sentence, stop here and tell the user to sharpen it. Do not proceed.

Confirm the frame is right before moving on. One question max, and only if the thesis itself is ambiguous.

---

## Stage 2 — Set The Proof Bar

Pressure-test the thesis. Establish, explicitly:

```
### Proof bar
Strong evidence looks like:  [what would make this convincing — data, a working demo, a cited source, a reproduction]
Would falsify it:            [what fact, if true, sinks the conclusion]
Central + fragile claims:    [the 1-3 load-bearing claims most likely to be wrong]
Evidence allowed:            [what you may use — the repo, tests, the web, the user's own numbers]
Out of scope:                [claims you are deliberately not verifying this pass]
```

Ask a question here ONLY if the answer changes the proof bar (e.g. "does 'strong evidence' require a live reproduction, or is a cited benchmark enough?"). Otherwise pick a sane default and label it an assumption.

---

## Stage 3 — Run The Loop

The loop is conversational. No blueprint file, no runner, no external tool. Verify the fragile claims against the allowed evidence, then revise the artifact against what you find.

Default to one or two passes. Add a third ONLY when stakes are high and meaningful new evidence is still available. Keep each pass verification-centered: do not run critique/rewrite cycles that leave the evidence base unchanged.

Each pass:

1. **Capture** the current artifact and mark the top red claims (the fragile ones from Stage 2).
2. **Verify** each red claim against the allowed evidence. For each: state the claim, the evidence found, and the verdict (holds / weakened / falsified). Do not invent facts or sources; if evidence is missing, say so and treat the claim as unproven.
3. **Revise** the artifact against what you found: strengthen supported claims with the evidence, soften or cut unsupported ones, fix anything falsified.
4. **Decide** whether another pass earns its keep. Stop when the fragile claims are resolved or no new evidence is available.

Report each pass compactly: claim, evidence, verdict, what changed. Lead with the deliverable, keep the running notes lean.

---

## Stage 4 — Lock

When the loop stops, write two files to the working directory:

- `hardened/final.md` — the hardened artifact. The revised thesis and its support, ready to use. This is the deliverable.
- `hardened/one-paragraph-summary.md` — a single paragraph: the thesis as it now stands, the strongest evidence for it, and the one caveat a careful reader should know.

Keep both lean and user-facing. No runner scaffolding, no internal loop logs in the final files — those stay in the conversation.

Close with:

```
## Hardened

Thesis:      [final one-sentence thesis]
Passes run:  [N]
Held:        [claims that survived verification]
Changed:     [claims softened, cut, or fixed]
Open risk:   [the one caveat that remains, if any]

Files:
  hardened/final.md
  hardened/one-paragraph-summary.md
```

Do not auto-execute whatever the artifact proposes. Harden stops at a locked, defensible artifact. Acting on it is a separate step (`/boris`, `/plan-context`, etc.).

---

## Hard rules

- Only ask questions that change the proof bar, the loop structure, or the stop rule.
- Never invent facts or sources. Missing evidence means the claim is unproven, not true.
- Foggy seed → stop and send the user to sharpen it. Do not plan around a fog.
- One or two passes by default. A third only for high stakes with real new evidence.
- Outputs stay lean: `hardened/final.md` + `hardened/one-paragraph-summary.md`. Nothing else.
