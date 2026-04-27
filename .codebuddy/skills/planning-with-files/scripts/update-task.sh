#!/usr/bin/env bash
# update-task.sh — Update the status of a task in the active planning session
# Usage: ./update-task.sh <task-id> <status> [notes]
#   task-id : The identifier of the task (e.g. T-001)
#   status  : One of: todo | in-progress | done | blocked | skipped
#   notes   : Optional free-text notes to append to the task entry

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
VALID_STATUSES=("todo" "in-progress" "done" "blocked" "skipped")
SESSION_DIR="${PLANNING_SESSION_DIR:-.codebuddy/sessions}"
ACTIVE_LINK="${SESSION_DIR}/active"

# ── Helpers ──────────────────────────────────────────────────────────────────
die() { echo "[update-task] ERROR: $*" >&2; exit 1; }
info() { echo "[update-task] $*"; }

usage() {
  echo "Usage: $0 <task-id> <status> [notes]"
  echo "  status: todo | in-progress | done | blocked | skipped"
  exit 1
}

is_valid_status() {
  local s="$1"
  for v in "${VALID_STATUSES[@]}"; do
    [[ "$v" == "$s" ]] && return 0
  done
  return 1
}

# ── Argument validation ───────────────────────────────────────────────────────
[[ $# -lt 2 ]] && usage

TASK_ID="$1"
STATUS="$2"
NOTES="${3:-}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

is_valid_status "$STATUS" || die "Invalid status '${STATUS}'. Must be one of: ${VALID_STATUSES[*]}"

# ── Locate active session ─────────────────────────────────────────────────────
if [[ -L "$ACTIVE_LINK" ]]; then
  SESSION_FILE=$(readlink -f "$ACTIVE_LINK")
elif [[ -f "${SESSION_DIR}/session.md" ]]; then
  SESSION_FILE="${SESSION_DIR}/session.md"
else
  die "No active planning session found. Run init-session.sh first."
fi

[[ -f "$SESSION_FILE" ]] || die "Session file not found: ${SESSION_FILE}"

# ── Check task exists ─────────────────────────────────────────────────────────
if ! grep -qE "^[[:space:]]*[-*].*\b${TASK_ID}\b" "$SESSION_FILE" 2>/dev/null; then
  die "Task '${TASK_ID}' not found in session file: ${SESSION_FILE}"
fi

# ── Backup session file ───────────────────────────────────────────────────────
cp "$SESSION_FILE" "${SESSION_FILE}.bak"

# ── Update task status in-place ───────────────────────────────────────────────
# Expected line format (from init-session):
#   - [ ] T-001 | todo | Description text
# After update:
#   - [x] T-001 | done | Description text

CHECKBOX="[ ]"
[[ "$STATUS" == "done" ]] && CHECKBOX="[x]"

# Replace the status field and checkbox for the matching task ID
sed -i.tmp -E \
  "s|^([[:space:]]*- )\[[xX ]\]([[:space:]]+${TASK_ID}[[:space:]]*\|)[[:space:]]*[a-z-]+([[:space:]]*\|)(.*)$|\1${CHECKBOX}\2 ${STATUS}\3\4|" \
  "$SESSION_FILE"

rm -f "${SESSION_FILE}.tmp"

# ── Append notes if provided ──────────────────────────────────────────────────
if [[ -n "$NOTES" ]]; then
  # Find the line number of the task and insert a note line after it
  LINE_NUM=$(grep -nE "\b${TASK_ID}\b" "$SESSION_FILE" | head -1 | cut -d: -f1)
  if [[ -n "$LINE_NUM" ]]; then
    NOTE_LINE="  > [${TIMESTAMP}] ${NOTES}"
    sed -i.tmp "${LINE_NUM}a\\${NOTE_LINE}" "$SESSION_FILE"
    rm -f "${SESSION_FILE}.tmp"
  fi
fi

# ── Log the change ────────────────────────────────────────────────────────────
LOG_FILE="${SESSION_DIR}/update.log"
mkdir -p "$SESSION_DIR"
echo "${TIMESTAMP} | ${TASK_ID} | ${STATUS}${NOTES:+ | ${NOTES}}" >> "$LOG_FILE"

info "Task '${TASK_ID}' updated to '${STATUS}'${NOTES:+ with note: \"${NOTES}\"}"
info "Session file: ${SESSION_FILE}"
info "Change log:   ${LOG_FILE}"
