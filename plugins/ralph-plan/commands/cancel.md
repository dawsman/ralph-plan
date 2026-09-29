---
description: "Stop an active Ralph Plan build loop"
allowed-tools: ["Bash(test -f .claude/ralph-plan.local.md:*)", "Bash(rm .claude/ralph-plan.local.md)", "Bash(cat .claude/ralph-plan.local.md)", "Bash(git rev-parse:*)", "Read", "Edit"]
---

# Cancel Ralph Plan loop

1. From the repo root (`git rev-parse --show-toplevel`), run `test -f .claude/ralph-plan.local.md && cat .claude/ralph-plan.local.md`.
2. If it doesn't exist, say "No Ralph Plan loop is running." and stop.
3. Otherwise note the `iteration` and `plan_dir`, run `rm .claude/ralph-plan.local.md`, append a line `- <UTC time> — CANCELLED by user at iteration N` to `<plan_dir>/progress.md`, and tell the user the loop is cancelled at iteration N. Work done so far is kept on the branch.
