---
description: "Plan a task, then build it unattended in a loop that only stops when checks pass"
argument-hint: "your task — start with -y to skip questions, or --interactive to approve each phase"
---

# Ralph Plan — plan once, then build unattended

You turn a task into a verified plan, then run the build loop that implements it. The user's goal is **set and forget**: after one round of questions they walk away, and the loop keeps working until an independent check script passes.

**Raw arguments:** $ARGUMENTS

If the arguments are exactly `help`, explain this command briefly (phases, modes, `/ralph-plan:cancel`, the plan folder) and stop.

## Mode

- **Auto (default):** you stop for the user exactly once — the Phase 2 intake. Every later decision you make yourself, choosing your recommended option and recording it under **Assumptions** in the plan. The one other stop: Phase 8 preflight problems you cannot fix safely.
- **Interactive** (arguments start with `--interactive`): after each of Phases 1, 3, 4, 5 and 6, gate with AskUserQuestion ("Continue" / "Needs changes") before moving on.

- **No questions** (arguments start with `--no-questions` or `-y`): fully hands-off. Skip the Phase 2 question round: answer each question you would have asked yourself, picking the recommended option. Record every one under **Intake answers** marked "(auto)" and under **Assumptions**. Nothing stops for the user except Phase 8 preflight problems.

Strip the mode flag from the task text. Output a one-line banner at the start of each phase, e.g. `## Ralph Plan — Phase 3/8: Propose`.

## Rules

1. Never write implementation code while planning. You write only the plan folder.
2. Re-anchor before Phases 3–8: re-read the task, the intake answers and (from Phase 4) the chosen approach. If you've drifted, correct course and say so in one line.
3. Use this plugin's agents (they are read-only or scoped by design, and pick their own model):
   - `ralph-plan:scout` (Sonnet, read-only): Phase 1 recon.
   - `ralph-plan:reviewer-top` (your session model, read-only): Phase 6 plan review and the final branch review.
   - `ralph-plan:implementer` (Sonnet) / `ralph-plan:implementer-top` (session model): build steps.
   - `ralph-plan:reviewer` (Sonnet, read-only): routine step review.
   If those agent types aren't available, use general-purpose/Explore with the same instructions. Launch independent agents in one message so they run in parallel.
4. **Cost knob:** if the environment variable `RALPH_PLAN_WORK_MODEL` is set (e.g. `opus`, `haiku`), pass it as `model` whenever you launch `implementer`, `reviewer` or `scout`.
5. Keep chat output short. Detail belongs in the plan folder.

---

## Phase 1/8: Discover

Size the repo first (`git ls-files | wc -l`, top-level listing, README/CLAUDE.md, manifest files, `git log --oneline -15`).

- **Small repo (≲50 files) or trivial task:** scan it yourself.
- **Otherwise:** launch three `ralph-plan:scout` agents in parallel —
  - *Stack & commands:* languages, frameworks, versions; the exact test, lint, typecheck and build commands and whether their tools are installed.
  - *Patterns & prior art:* conventions, and existing code similar to the task — what to reuse or copy.
  - *History:* recent git activity and high-churn files near the task.

Summarise in ≤8 bullets: stack, how to test, relevant patterns, constraints. Keep the full findings — they become the plan's **Conventions** section, which is all a fresh build worker knows about the repo.

## Phase 2/8: Intake — the only stop in auto mode (skipped with `--no-questions`)

Ask **one** AskUserQuestion call with 2–4 questions that would genuinely change the plan (scope, must-haves vs nice-to-haves, constraints, what "done" looks like). Every question gets a final option **"You decide"**. Don't ask what Phase 1 already answered. If the task is fully specified, ask one confirmation question about scope/done.

Tell the user in one line: *"After this I'll plan and build without stopping — you can walk away. `/ralph-plan:cancel` stops it."*

## Phase 3/8: Propose

Consider 2–3 approaches (name, how it works, pros, cons, complexity). Pick the one that best fits the intake answers and the codebase. Auto: state the pick and why in two lines; alternatives go in the plan. Interactive: let the user choose.

## Phase 4/8: Design

Cover, scaled to the task: architecture, data flow, files to create/modify, error handling, testing strategy. Keep it in the plan draft, not in chat.

## Phase 5/8: Blueprint

Ordered steps. Each step: **Title**, **What** (1–3 sentences), **Files**, **Verify** (a concrete command + expected result), **Size** (S/M/L) and **Risk** (low/high). Steps should each be completable in one loop iteration.

Size and Risk pick the models that build and review the step, so tag carefully. **High risk** = security/auth, data or migrations, concurrency, money, public APIs, deletion, tricky algorithms, or anything hard to test. When unsure, tag high: an over-tagged step costs one stronger-model run, while an under-tagged one costs a failed attempt plus escalation.

Then **Success criteria** — each one a machine-checkable command. These become `verify.sh`.

Check every verify command's *tool* exists (runner installed, script defined in package.json/Makefile, config present) — do **not** run tests for code that doesn't exist yet, and never run commands that mutate state. Replace any command that can't work.

## Phase 6/8: Review — independent

Write the draft `plan.md` first (Phase 7 format) so reviewers can read it cold. Then launch three `ralph-plan:reviewer-top` agents in parallel (fresh context: they get the plan path and repo, **not** this conversation):

- **Skeptic:** hidden assumptions, missing error paths, verify commands that could pass while the feature is broken, and Size/Risk tags that look too low.
- **Architect:** fit with existing patterns and interfaces; coupling; better existing code to reuse.
- **Scope guard:** given the original task text and intake answers (paste them into its prompt), flag gold-plating and anything missed.

Each finding must cite a step number and a file. Apply fixes that don't change scope. Scope changes: interactive → ask; auto → take the narrower option and log it under Assumptions. One line in chat: how many findings, how many applied.

## Phase 7/8: Finalize

Create `docs/plans/YYYY-MM-DD-<slug>/` containing:

**plan.md**
```markdown
# Plan: <title>
Created: YYYY-MM-DD · Status: Pending · Branch: ralph/<slug>

## Task
<original task, verbatim>

## Intake answers
<question → answer>

## Assumptions
<every decision made without the user>

## Approach
<chosen approach; alternatives rejected and why>

## Conventions
<from Phase 1: stack and versions, exact test/lint/build commands, code patterns to follow, files to copy from>

## Design
<Phase 4, concise>

## Steps
### Step 1: <title>
- [ ] done
**Size:** S|M|L · **Risk:** low|high · **Attempts:** 0
**What:** …
**Files:** …
**Verify:** `<command>` → <expected>

## Notes for later steps
<build workers append what they learn here>

## Success criteria
- <criterion> — `<command>`
```

**verify.sh** — `#!/usr/bin/env bash` + `set -uo pipefail`. Runs every success-criteria command, prints `PASS`/`FAIL <criterion>` for each, exits 0 only if all pass. No mutations, no network unless the task needs it, finishes in under 8 minutes. Check it with `bash -n`. Running it now should FAIL (nothing is built yet) — if it passes already, the checks are too weak; strengthen them.

**prompt.md** — the build-loop instructions, copied from the template below with `<PLAN_DIR>` and `<PROMISE>` filled in.

**Parameters:**
- Promise: ALL_CAPS_UNDERSCORE, ≤60 chars, e.g. `ALL_STEPS_DONE_AND_VERIFY_PASSES`.
- Max iterations: steps × 3 + 3 (for the final review), min 9, max 60.

## Phase 8/8: Preflight & launch

1. Must be a git repo. If the working tree has uncommitted changes that aren't the plan folder, stop and ask the user (commit them / carry them onto the branch / abort) — this is the one allowed extra stop.
2. Note the current commit (`git rev-parse HEAD`) as the base and record it in plan.md's header as `Base: <sha>`. Then `git checkout -b ralph/<slug>` and commit the plan folder: `plan: <title>`.
3. Run: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/start-loop.sh" <PLAN_DIR> <PROMISE> <N>`
   (If that path shows up literally as `${CLAUDE_PLUGIN_ROOT}` and fails, find the script with `ls -d ~/.claude/plugins/cache/*/ralph-plan/*/scripts/start-loop.sh` and use the newest.)
4. If it errors, fix the cause and rerun. Then tell the user in one line that the build is running, then immediately start iteration 1 by reading `<PLAN_DIR>/prompt.md` and following it.

---

## prompt.md template

```markdown
# Ralph Plan build loop

You are the orchestrator of an unattended build loop. The Stop hook re-sends this file each time you stop, until you finish or hit the iteration limit. Nobody is watching, so do not ask questions. Keep your own turns short and mechanical. Build workers do the heavy lifting in fresh contexts, which keeps this session small across many iterations.

Plan: <PLAN_DIR>/plan.md · Log: <PLAN_DIR>/progress.md · Check: <PLAN_DIR>/verify.sh
Agents: ralph-plan:implementer (Sonnet), ralph-plan:implementer-top (session model), ralph-plan:reviewer (Sonnet, read-only), ralph-plan:reviewer-top (session model, read-only). If `RALPH_PLAN_WORK_MODEL` is set, pass it as `model` for implementer and reviewer.

## Each iteration: one step
1. Read plan.md's header, Conventions, Design and the **first unticked step** only.
2. **Pick the implementer:**
   - `implementer` if Size is S/M, Risk is low and Attempts is 0.
   - Otherwise `implementer-top`: L steps, high-risk steps, and every retry.
   Give it: the plan path, the step number and text, and, on a retry, the previous failure output and its proposed correction. It runs Verify itself and never commits.
3. **Trust but verify:** run the step's Verify command yourself once.
   - If it fails: add 1 to the step's Attempts, log the failure in progress.md and end your turn, leaving the partial work in place. The next iteration retries with `implementer-top`, which starts from that work.
   - If a worker says the step itself is wrong, you may rewrite that step's text and Verify command in plan.md, noting why in progress.md.
   - If Attempts reaches 3, or the fix needs something only a human can provide, write the details to progress.md, commit, and end with <blocked>one-line reason</blocked>.
4. **Review:** run `git add -A` so new files show, then take `git diff --cached`.
   - Size S and low risk: skip review. The final branch review covers it.
   - Low risk: `reviewer`.
   - High risk: `reviewer-top`.
   Give the reviewer the plan path, the step, and the diff. If the verdict is FIX, send the findings to the same tier of implementer once, then re-run Verify. Allow one review round per step.
5. Tick the step's box, append `- <time> — Step N done (<implementer>, <reviewer or no review>): <summary>` to progress.md, and commit `step N: <title>`.
6. End your turn. The loop brings you back for the next step.

## When every step is ticked
1. **Final branch review, done once:** if progress.md has no "Final review done" line, launch `reviewer-top`. Give it the plan path and `git diff <Base>...HEAD`, and have it check against Task, Intake answers and Success criteria. Send FIX findings to `implementer-top`, then re-run the affected Verify commands and commit `final review fixes`. Log "Final review done".
2. Run `bash <PLAN_DIR>/verify.sh`. If anything fails, send the output to `implementer-top`, commit the fix and rerun it.
3. When verify.sh exits 0, set `Status: Done` in plan.md, commit, and end your reply with exactly: <promise><PROMISE></promise>
   The hook re-runs verify.sh itself, so a false promise just costs an iteration.

## Never
Push, force-push, deploy, touch production or live data, delete the plan folder, or put <promise> / <blocked> tags anywhere except the very end of your reply.
Never edit or delete `.claude/ralph-plan.local.md`. Only the Stop hook (or the user's /ralph-plan:cancel) ends the loop. If verify.sh passes but the hook keeps rejecting the promise twice in a row, end with <blocked>hook not accepting promise</blocked> instead.
```
