#!/bin/bash
# Start the Ralph Plan build loop for a finished plan directory.
# Usage: start-loop.sh <plan-dir> <completion-promise> <max-iterations>
#
# Writes .claude/ralph-plan.local.md. From then on, the plugin's Stop hook
# re-feeds the plan's prompt.md every time Claude tries to stop, until the
# promise is output AND the plan's verify.sh exits 0 (or max iterations hit).

set -euo pipefail

PLAN_DIR="${1:-}"
PROMISE="${2:-}"
MAX="${3:-}"

die() { echo "ralph-plan: $*" >&2; exit 1; }

[[ -n "$PLAN_DIR" && -n "$PROMISE" && -n "$MAX" ]] || die "usage: start-loop.sh <plan-dir> <promise> <max-iterations>"
# Always work from the repo root, with an absolute plan path, so the Stop hook
# finds the state file no matter where the shell's cwd has drifted.
[[ -d "$PLAN_DIR" ]] || die "no such plan dir: $PLAN_DIR"
PLAN_DIR=$(cd "$PLAN_DIR" && pwd -P)
ROOT=$(git -C "$PLAN_DIR" rev-parse --show-toplevel 2>/dev/null) || die "plan dir is not inside a git repo"
cd "$ROOT"

[[ -f "$PLAN_DIR/plan.md" ]]   || die "missing $PLAN_DIR/plan.md"
[[ -f "$PLAN_DIR/prompt.md" ]] || die "missing $PLAN_DIR/prompt.md"
[[ -f "$PLAN_DIR/verify.sh" ]] || die "missing $PLAN_DIR/verify.sh"
[[ "$MAX" =~ ^[0-9]+$ ]]       || die "max-iterations must be a number (got '$MAX')"
[[ "$PROMISE" =~ ^[A-Z0-9_]+$ ]] || die "promise must be ALL_CAPS_UNDERSCORE (got '$PROMISE')"
bash -n "$PLAN_DIR/verify.sh"  || die "$PLAN_DIR/verify.sh has a syntax error"
chmod +x "$PLAN_DIR/verify.sh"

if [[ -f .claude/ralph-plan.local.md ]]; then
  die "a loop is already active (.claude/ralph-plan.local.md). Run /ralph-plan:cancel first."
fi

mkdir -p .claude
# Keep the loop state out of step commits.
EXCLUDE="$(git rev-parse --git-path info/exclude)"
grep -qxF '.claude/ralph-plan.local.md' "$EXCLUDE" 2>/dev/null || echo '.claude/ralph-plan.local.md' >> "$EXCLUDE"
[[ -f "$PLAN_DIR/progress.md" ]] || printf '# Progress log\n\n' > "$PLAN_DIR/progress.md"

cat > .claude/ralph-plan.local.md <<EOF
---
iteration: 1
session_id: ${CLAUDE_CODE_SESSION_ID:-}
max_iterations: $MAX
completion_promise: $PROMISE
plan_dir: $PLAN_DIR
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---
EOF

echo "Ralph Plan loop started."
echo "  Plan:       $PLAN_DIR/plan.md"
echo "  Done when:  <promise>$PROMISE</promise> is output AND $PLAN_DIR/verify.sh exits 0"
echo "  Max loops:  $MAX"
echo "  Stop early: /ralph-plan:cancel"
