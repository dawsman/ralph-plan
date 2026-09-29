---
description: "Plan a task, then build it unattended in a loop that only stops when checks pass"
argument-hint: "[--interactive] description of the task"
---

# Ralph Plan — plan once, then build unattended

You turn a task into a verified plan, then run the build loop that implements it. The user's goal is **set and forget**: after one round of questions they walk away, and the loop keeps working until an independent check script passes.

**Raw arguments:** $ARGUMENTS

If the arguments are exactly `help`, explain this command briefly (phases, modes, `/ralph-plan:cancel`, the plan folder) and stop.

## Mode

- **Auto (default):** you stop for the user exactly once — the Phase 2 intake. Every later decision you make yourself, choosing your recommended option and recording it under **Assumptions** in the plan. The one other stop: Phase 8 preflight problems you cannot fix safely.
- **Interactive** (arguments start with `--interactive`): after each of Phases 1, 3, 4, 5 and 6, gate with AskUserQuestion ("Continue" / "Needs changes") before moving on.

Strip `--interactive` from the task text. Output a one-line banner at the start of each phase, e.g. `## Ralph Plan — Phase 3/8: Propose`.

## Rules

1. Never write implementation code while planning. You write only the plan folder.
2. Re-anchor before Phases 3–8: re-read the task, the intake answers and (from Phase 4) the chosen approach. If you've drifted, correct course and say so in one line.
3. While planning (Phases 1–7), subagents you spawn must be told: **"Do not modify files. Do not spawn further agents. Report findings only, citing file paths."** Launch independent subagents in one message so they run in parallel.
4. Keep chat output short. Detail belongs in the plan folder.

---

## Phase 1/8: Discover

Size the repo first (`git ls-files | wc -l`, top-level listing, README/CLAUDE.md, manifest files, `git log --oneline -15`).

- **Small repo (≲50 files) or trivial task:** scan it yourself.
- **Otherwise:** launch in parallel —
  - *Stack & commands* (Explore): languages, frameworks, versions; the exact test, lint, typecheck and build commands and whether their tools are installed.
  - *Patterns & prior art* (Explore): conventions, and existing code similar to the task — what to reuse or copy.
  - *History* (general-purpose): recent git activity and high-churn files near the task.

Summarise in ≤8 bullets: stack, how to test, relevant patterns, constraints.

## Phase 2/8: Intake — the only stop in auto mode

Ask **one** AskUserQuestion call with 2–4 questions that would genuinely change the plan (scope, must-haves vs nice-to-haves, constraints, what "done" looks like). Every question gets a final option **"You decide"**. Don't ask what Phase 1 already answered. If the task is fully specified, ask one confirmation question about scope/done.

Tell the user in one line: *"After this I'll plan and build without stopping — you can walk away. `/ralph-plan:cancel` stops it."*

## Phase 3/8: Propose

Consider 2–3 approaches (name, how it works, pros, cons, complexity). Pick the one that best fits the intake answers and the codebase. Auto: state the pick and why in two lines; alternatives go in the plan. Interactive: let the user choose.

## Phase 4/8: Design

Cover, scaled to the task: architecture, data flow, files to create/modify, error handling, testing strategy. Keep it in the plan draft, not in chat.

## Phase 5/8: Blueprint

Ordered steps. Each step: **Title**, **What** (1–3 sentences), **Files**, **Verify** (a concrete command + expected result). Steps should each be completable in one loop iteration.

Then **Success criteria** — each one a machine-checkable command. These become `verify.sh`.

Check every verify command's *tool* exists (runner installed, script defined in package.json/Makefile, config present) — do **not** run tests for code that doesn't exist yet, and never run commands that mutate state. Replace any command that can't work.

## Phase 6/8: Review — independent

Write the draft `plan.md` first (Phase 7 format) so reviewers can read it cold. Then launch in parallel (general-purpose, fresh context — they get the plan path and repo, **not** this conversation):

- **Skeptic:** hidden assumptions, missing error paths, verify commands that could pass while the feature is broken.
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

## Design
<Phase 4, concise>

## Steps
### Step 1: <title>
- [ ] done
**What:** …
**Files:** …
**Verify:** `<command>` → <expected>

## Success criteria
- <criterion> — `<command>`
```

**verify.sh** — `#!/usr/bin/env bash` + `set -uo pipefail`. Runs every success-criteria command, prints `PASS`/`FAIL <criterion>` for each, exits 0 only if all pass. No mutations, no network unless the task needs it, finishes in under 8 minutes. Check it with `bash -n`. Running it now should FAIL (nothing is built yet) — if it passes already, the checks are too weak; strengthen them.

**prompt.md** — the build-loop instructions, copied from the template below with `<PLAN_DIR>` and `<PROMISE>` filled in.

**Parameters:**
- Promise: ALL_CAPS_UNDERSCORE, ≤60 chars, e.g. `ALL_STEPS_DONE_AND_VERIFY_PASSES`.
- Max iterations: steps × 3, min 9, max 60.

## Phase 8/8: Preflight & launch

1. Must be a git repo. If the working tree has uncommitted changes that aren't the plan folder, stop and ask the user (commit them / carry them onto the branch / abort) — this is the one allowed extra stop.
2. `git checkout -b ralph/<slug>`, then commit the plan folder: `plan: <title>`.
3. Run: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/start-loop.sh" <PLAN_DIR> <PROMISE> <N>`
   (If that path shows up literally as `${CLAUDE_PLUGIN_ROOT}` and fails, find the script with `ls -d ~/.claude/plugins/cache/*/ralph-plan/*/scripts/start-loop.sh` and use the newest.)
4. If it errors, fix the cause and rerun. Then tell the user in one line that the build is running, then immediately start iteration 1 by reading `<PLAN_DIR>/prompt.md` and following it.

---

## prompt.md template

```markdown
# Ralph Plan build loop

You are one iteration of an unattended build loop. The Stop hook re-sends this file each time you stop, until you finish or hit the iteration limit. Nobody is watching — do not ask questions.

Plan: <PLAN_DIR>/plan.md · Log: <PLAN_DIR>/progress.md · Check: <PLAN_DIR>/verify.sh

Each iteration:
1. Read plan.md and the last 30 lines of progress.md. Run `git log --oneline -10`. Find the first step whose box isn't ticked.
2. Implement that one step, following the plan's Design and the repo's conventions. For a large step you may hand the implementation to one subagent, but tell it not to spawn agents.
3. Run the step's Verify command. Fix until it passes. If it can't pass because the plan is wrong, fix the plan (edit the step, note why in progress.md) rather than faking it.
4. Independent check: spawn one general-purpose subagent with the step text and `git diff` for this step. Instructions: "Review this change against the step. Report bugs, missed requirements, and whether the Verify command really proves the step. Do not modify files or spawn agents." Fix real findings.
5. Tick the step's box in plan.md, append one line to progress.md (`- <time> — Step N done: <summary>`), and commit: `step N: <title>`.
6. If steps remain, stop here (end your turn) — the loop will bring you back.

When every step is ticked:
- Run `bash <PLAN_DIR>/verify.sh`. If anything fails, fix it and rerun.
- When it exits 0, set `Status: Done` in plan.md, commit, and end your reply with exactly: <promise><PROMISE></promise>
- The hook re-runs verify.sh itself; a false promise just costs an iteration.

If you are truly blocked by something only a human can provide (credentials, a product decision, an external outage), write the details to progress.md, commit, and end your reply with: <blocked>one-line reason</blocked>. Never use this to escape hard work.

Never: push, force-push, deploy, touch production or live data, or delete the plan folder.
```
