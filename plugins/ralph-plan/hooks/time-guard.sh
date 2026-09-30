#!/bin/bash
# Ralph Plan time guard (PreToolUse): once a loop has passed its time limit,
# deny every tool call so even a single never-ending turn winds down. The Stop
# hook then ends the loop. No active loop = no effect.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
STATE=".claude/ralph-plan.local.md"
if [[ ! -f "$STATE" ]]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
  STATE="$ROOT/$STATE"; [[ -f "$STATE" ]] || exit 0
fi
STARTED=$(grep -m1 '^started_epoch:' "$STATE" | sed 's/^started_epoch: *//')
MAX_HOURS=$(grep -m1 '^max_hours:' "$STATE" | sed 's/^max_hours: *//')
[[ "$STARTED" =~ ^[0-9]+$ && "$MAX_HOURS" =~ ^[0-9]+$ ]] || exit 0
if (( $(date +%s) - STARTED > MAX_HOURS * 3600 )); then
  jq -n --arg r "Ralph Plan time limit (${MAX_HOURS}h) reached. Do not call any more tools; end your turn now." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
fi
exit 0
