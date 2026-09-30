#!/bin/bash
# Ralph Plan Stop hook — keeps the build loop running until the work is
# genuinely done.
#
# Finishing needs BOTH:
#   1. Claude's last message contains <promise>PROMISE</promise>
#   2. <plan_dir>/verify.sh exits 0 (checked here, not trusted to the model)
# Claude can also end the loop honestly with <blocked>reason</blocked> when it
# needs a human (credentials, a product decision) instead of burning iterations.

set -euo pipefail

HOOK_INPUT=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}"

STATE=".claude/ralph-plan.local.md"
# start-loop.sh writes the state at the git root; the session may sit in a subdir.
if [[ ! -f "$STATE" ]]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
  [[ -n "$ROOT" && -f "$ROOT/$STATE" ]] || exit 0
  cd "$ROOT"
fi

field() { sed -n '/^---$/,/^---$/p' "$STATE" | grep "^$1:" | head -1 | sed "s/^$1: *//" || true; }

ITERATION=$(field iteration)
MAX=$(field max_iterations)
PROMISE=$(field completion_promise)
PLAN_DIR=$(field plan_dir)
STATE_SESSION=$(field session_id)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')

# Only the session that started the loop is held in it.
if [[ -n "$STATE_SESSION" && "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

PROGRESS="$PLAN_DIR/progress.md"
log()    { printf '\n- %s — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$PROGRESS" 2>/dev/null || true; }
notify() {
  if [[ -n "${RALPH_PLAN_NOTIFY:-}" ]]; then
    (bash -c "$RALPH_PLAN_NOTIFY" _ "$1" >/dev/null 2>&1 &) || true
  fi
}
finish() { # $1 = message
  log "$1"
  # Commit just the log line so the branch is left clean.
  git add -- "$PROGRESS" >/dev/null 2>&1 && git commit -q --no-verify -m "ralph-plan: ${1%% *}" -- "$PROGRESS" >/dev/null 2>&1 || true
  notify "Ralph Plan ($PLAN_DIR): $1"
  rm -f "$STATE"
  jq -n --arg m "Ralph Plan: $1 (log: $PROGRESS)" '{systemMessage: $m}'
  exit 0
}

if [[ ! "$ITERATION" =~ ^[0-9]+$ || ! "$MAX" =~ ^[0-9]+$ || -z "$PLAN_DIR" ]]; then
  echo "ralph-plan: state file corrupted, stopping loop" >&2
  rm -f "$STATE"
  exit 0
fi

# Last assistant text. Prefer the payload field: Claude Code writes the final
# assistant entry to the transcript AFTER Stop hooks run, so the transcript
# tail is one message stale. Fall back to it only on older versions.
LAST_TEXT=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // ""')
TRANSCRIPT=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
if [[ -z "$LAST_TEXT" && -f "$TRANSCRIPT" ]]; then
  LAST_TEXT=$(grep '"role":"assistant"' "$TRANSCRIPT" | tail -n 100 \
    | jq -rs 'map(.message.content[]? | select(.type == "text") | .text) | last // ""' 2>/dev/null || true)
fi
tag() { echo "$LAST_TEXT" | perl -0777 -ne "print \$1 if /<$1>(.*?)<\\/$1>\\s*\$/s" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//'; }

BLOCKED=$(tag blocked)
if [[ -n "$BLOCKED" ]]; then
  finish "BLOCKED after iteration $ITERATION: $BLOCKED"
fi

# Stall: nothing changed (commit, working tree, or plan; progress.md ignored)
# for 3 turns in a row. Computed before this hook writes its own log lines.
FP=$( { git rev-parse HEAD 2>/dev/null; git diff HEAD -- . ":(exclude)$PLAN_DIR/progress.md" 2>/dev/null
        git ls-files -o --exclude-standard 2>/dev/null | grep -v 'progress\.md$' | while IFS= read -r f; do cksum "$f"; done 2>/dev/null
        cat "$PLAN_DIR/plan.md" 2>/dev/null; } | cksum | cut -d' ' -f1)
STALLS=$(field stalls); [[ "$STALLS" =~ ^[0-9]+$ ]] || STALLS=0
if [[ "$FP" == "$(field fingerprint)" ]]; then STALLS=$((STALLS + 1)); else STALLS=0; fi

VERIFY_NOTE=""
if [[ -n "$PROMISE" && "$(tag promise)" == "$PROMISE" ]]; then
  TO=""
  command -v gtimeout >/dev/null && TO="gtimeout 500"
  [[ -z "$TO" ]] && command -v timeout >/dev/null && TO="timeout 500"
  set +e
  VERIFY_OUT=$($TO bash "$PLAN_DIR/verify.sh" 2>&1)
  VERIFY_RC=$?
  set -e
  if [[ $VERIFY_RC -eq 0 ]]; then
    finish "DONE after $ITERATION iteration(s) — verify.sh passed."
  fi
  log "Iteration $ITERATION claimed done but verify.sh exited $VERIFY_RC"
  VERIFY_NOTE="You output the completion promise, but $PLAN_DIR/verify.sh FAILED (exit $VERIFY_RC). The work is not done. Last lines of its output:
$(echo "$VERIFY_OUT" | tail -n 40)

Fix the cause, re-run verify.sh yourself, and only output the promise once it exits 0."
fi

if (( STALLS >= 3 )); then
  finish "STOPPED: stalled — no progress in the last 3 turns (iteration $ITERATION)."
fi

if [[ $ITERATION -ge $MAX ]]; then
  finish "STOPPED: hit max iterations ($MAX) without passing verify.sh."
fi

# Runaway guards for unattended runs.
STARTED=$(field started_epoch); MAX_HOURS=$(field max_hours)
if [[ "$STARTED" =~ ^[0-9]+$ && "$MAX_HOURS" =~ ^[0-9]+$ ]]; then
  if (( $(date +%s) - STARTED > MAX_HOURS * 3600 )); then
    finish "STOPPED: time limit (${MAX_HOURS}h) reached at iteration $ITERATION without passing verify.sh."
  fi
fi

NEXT=$((ITERATION + 1))
TMP="$STATE.tmp.$$"
sed -e "s/^iteration: .*/iteration: $NEXT/" -e "s/^fingerprint: .*/fingerprint: $FP/" -e "s/^stalls: .*/stalls: $STALLS/" "$STATE" > "$TMP" && mv "$TMP" "$STATE"

REASON="Ralph Plan build loop, iteration $NEXT of $MAX. Read $PLAN_DIR/prompt.md and follow it exactly."
[[ -n "$VERIFY_NOTE" ]] && REASON="$REASON

$VERIFY_NOTE"

jq -n --arg r "$REASON" --arg m "🔄 Ralph Plan iteration $NEXT/$MAX — done only when <promise>$PROMISE</promise> AND verify.sh passes" \
  '{decision: "block", reason: $r, systemMessage: $m}'
exit 0
