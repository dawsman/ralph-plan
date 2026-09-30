# ralph-plan

A Claude Code plugin for **set-and-forget builds**. You describe a task and answer one round of questions. Claude then plans it, has the plan reviewed by independent agents, and builds it step by step on a new branch. The loop only stops when a check script it wrote at the start actually passes.

```
/ralph-plan Add user authentication with JWT
```

## How it works

| Phase | What happens | Stops for you? |
|---|---|---|
| 1. Discover | Scans the repo. Larger repos get parallel recon agents (stack & test commands, patterns & prior art, git history) | no |
| 2. Intake | One batch of 2–4 questions, each with a "You decide" option | **yes, once** |
| 3. Propose | Weighs 2–3 approaches and picks the best fit | no |
| 4. Design | Architecture, files, error handling, tests | no |
| 5. Blueprint | Ordered steps, each with a verify command; checks the test tooling exists | no |
| 6. Review | Three fresh-context reviewers (Skeptic, Architect, Scope guard) read the plan cold; fixes applied | no |
| 7. Finalize | Writes the plan folder: `plan.md`, `verify.sh`, `prompt.md` | no |
| 8. Launch | Creates branch `ralph/<slug>`, commits the plan, starts the build loop | only if your tree is dirty |

Every decision Claude makes without you is written to the plan's **Assumptions** section, so you can see it afterwards.

Skip even the question round with `--no-questions` (or `-y`). Claude answers its own questions with the recommended option and logs them in the plan:

```
/ralph-plan --no-questions Add a dark mode toggle
```

Use `--interactive` to approve each phase yourself:

```
/ralph-plan --interactive Refactor the cache layer to use Redis
```

## The build loop

This plugin has its own loop now. It doesn't need the separate ralph-loop plugin. Each iteration:

1. Picks the next unticked step in `plan.md`
2. Hands it to a fresh worker agent that implements it and runs its verify command. The orchestrator then re-runs the check itself
3. Has a fresh reviewer check the diff against the step (skipped for small, low-risk steps)
4. Ticks the step, logs to `progress.md`, commits `step N: <title>`

### Smart model use

Each job goes to the model where it pays off most:

| Job | Model |
|---|---|
| Planning, design, Phase 6 plan review | your session model (start Claude on your strongest) |
| Repo recon (Phase 1) | Sonnet, read-only |
| Routine steps (size S/M, low risk) | Sonnet implementer |
| Large or high-risk steps, and every retry | session-model implementer |
| Step review | none for S/low-risk, Sonnet for M/L low-risk, session model for high-risk |
| Final whole-branch review | session model |

Each step's worker starts fresh, so the main session stays small across a long run. Workers learn the repo from the plan's **Conventions** section and pass tips forward in **Notes for later steps**. When a step fails its check, the retry escalates to the stronger model. After 3 attempts the loop stops as blocked instead of wasting iterations. Reviewers can't edit files, because their tools don't allow it.

Set `RALPH_PLAN_WORK_MODEL` (e.g. `opus` or `haiku`) to change the model for the routine workers.

The loop ends when:

- **Done:** Claude outputs the completion promise **and** the Stop hook runs `verify.sh` itself and it exits 0. A premature "done" is rejected and the failure output is fed back.
- **Blocked:** Claude needs something only a human can give, such as credentials or a product decision. It writes the details to `progress.md` and stops instead of burning iterations.
- **Limit:** max iterations reached (steps × 3 + 3, 9–60).
- **Cancelled:** you run `/ralph-plan:cancel`.

### Safe to leave running

Several independent brakes stop a run from looping forever or burning tokens while you're away:

- **Iteration cap:** steps × 3 + 3, with a hard ceiling of 60 whatever the plan says.
- **Time limit:** 6 hours by default (`RALPH_PLAN_MAX_HOURS`). Checked at every stop and before every tool call, including inside workers, so even a single runaway turn is cut off.
- **Stall detector:** if 3 turns in a row change nothing (no commit, no file edits, no plan update — log lines don't count), the loop stops.
- **Retry cap:** a step that fails its check 3 times stops the run as blocked. It doesn't keep trying.
- **Blocked exit:** when Claude needs something only you can provide, it stops and says why.
- **Check timeout:** `verify.sh` is killed after about 8 minutes.

Every stop is logged in `progress.md` and sent to `RALPH_PLAN_NOTIFY` if you've set it.

Claude never pushes, deploys or touches production from inside the loop. Everything stays on the local branch for you to review.

### Plan folder

```
docs/plans/2026-09-29-jwt-auth/
  plan.md       task, intake answers, assumptions, steps with checkboxes, success criteria
  verify.sh     machine check for every success criterion (exit 0 = done)
  prompt.md     the instructions each loop iteration follows
  progress.md   timestamped log of every step, failed check, block or finish
```

### Get notified when it finishes

Set `RALPH_PLAN_NOTIFY` to a shell command. It receives the message as `$1`:

```bash
export RALPH_PLAN_NOTIFY='curl -s "https://api.telegram.org/bot$TG_TOKEN/sendMessage" -d chat_id=$TG_CHAT -d text="$1"'
```

## Commands

| Command | |
|---|---|
| `/ralph-plan <task>` | plan + build (auto mode) |
| `/ralph-plan --no-questions <task>` (or `-y`) | fully hands-off: Claude answers its own questions |
| `/ralph-plan --interactive <task>` | approve each phase |
| `/ralph-plan help` | explain the flow |
| `/ralph-plan:cancel` | stop a running build loop |

## Requirements

**To be truly unattended, run Claude with permissions that won't stop for approval.** For example, start it with `--permission-mode bypassPermissions` in a sandbox or container, or use `acceptEdits` plus an allowlist for git and your test commands. Otherwise the loop pauses at the first permission prompt until someone clicks.

`bash`, `jq`, `perl`, `git`. If your project isn't a git repo yet, Ralph Plan creates a local one, with a `.gitignore` for secrets, and nothing is pushed. `timeout` or `gtimeout` is optional; it caps `verify.sh` at about 8 minutes.

## Installation

```bash
claude plugin marketplace add dawsman/ralph-plan
claude plugin install ralph-plan@dawsman
```

## Changes in v3

- **Loop could never finish on success (fixed).** v2 told the loop not to use angle brackets. But ralph-loop only ends when it sees a literal `<promise>…</promise>` tag, so runs always went to max iterations.
- **Built-in loop.** The prompt now lives in a file rather than shell arguments, so the zsh `NO_NOMATCH` workaround is gone.
- **Done is enforced.** The hook runs `verify.sh` itself instead of trusting the model's promise.
- **Auto mode by default.** One question round, then no stops.
- **Independent reviewers.** Recon runs by default on larger repos, and Phase 6 reviewers are fresh agents instead of self-critique.
- **Model routing.** Sonnet workers handle routine steps and the session model takes hard or risky steps. Failed steps escalate to the stronger model, and a whole-branch review runs before finishing.
- **Leaner commands.** The unreachable `/claude-codes` command and the separate help command were folded in.
