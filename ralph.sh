#!/usr/bin/env bash
# Ralph loop for "Should I Coat?" — a deterministically-bad agent loop.
#
# Each iteration:
#   1. Re-invokes `claude` with PROMPT.md as the only context.
#   2. Lets it do exactly one thing (the topmost unchecked TODO item).
#   3. Commits whatever it produced.
#   4. Loops, until TODO.md contains "STATUS: DONE" or MAX_ITERS is hit.
#
# Memory lives in files + git history, not in the agent's context window.
#
# Requirements: `claude` CLI installed and logged in, `git` available.
#
# Usage:
#   chmod +x ralph.sh
#   ./ralph.sh                  # up to MAX_ITERS=20 iterations
#   MAX_ITERS=5 ./ralph.sh      # cap iterations
#   DRY_RUN=1 ./ralph.sh        # show what would happen, don't call claude
set -euo pipefail

MAX_ITERS="${MAX_ITERS:-20}"
DRY_RUN="${DRY_RUN:-0}"

# Initialise git if needed so Ralph has a memory.
if [ ! -d .git ]; then
  echo "Initialising git so Ralph has a memory..."
  git init -q
  git add -A
  git -c user.email=ralph@local -c user.name=Ralph commit -q -m "ralph: initial scaffold" || true
fi

for i in $(seq 1 "$MAX_ITERS"); do
  echo ""
  echo "=========================================="
  echo " Ralph iteration $i / $MAX_ITERS"
  echo "=========================================="

  if grep -q "^STATUS: DONE" TODO.md 2>/dev/null; then
    echo "TODO.md reports STATUS: DONE — stopping."
    exit 0
  fi

  # Preview which item the agent is about to attempt, for human watching.
  next_item="$(grep -n '^- \[ \]' TODO.md | head -1 || true)"
  if [ -n "$next_item" ]; then
    echo "Next item: $next_item"
  fi

  PROMPT="$(cat PROMPT.md)"

  if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] Would invoke: claude --print --permission-mode acceptEdits"
  else
    # --print runs non-interactively; --permission-mode acceptEdits lets
    # the agent edit files without per-call confirmation.
    claude --print --permission-mode acceptEdits "$PROMPT" || {
      echo "claude exited non-zero on iter $i — continuing anyway (Ralph is persistent)."
    }
  fi

  # Commit anything the agent produced so the next fresh agent can see progress.
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git -c user.email=ralph@local -c user.name=Ralph commit -q -m "ralph: iter $i" || true
    echo "Committed."
  else
    echo "No file changes this iteration."
  fi
done

echo ""
echo "Reached MAX_ITERS=$MAX_ITERS without STATUS: DONE."
echo "Inspect TODO.md, decide whether to keep going (./ralph.sh again) or edit the list."
