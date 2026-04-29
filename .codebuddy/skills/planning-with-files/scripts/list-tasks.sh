#!/usr/bin/env bash
# list-tasks.sh - List all tasks and their current status from the planning session
# Usage: ./list-tasks.sh [--filter <status>] [--session <session_dir>]

set -euo pipefail

# Default values
FILTER=""
SESSION_DIR=".codebuddy/session"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter)
      FILTER="$2"
      shift 2
      ;;
    --session)
      SESSION_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--filter <status>] [--session <session_dir>]"
      echo ""
      echo "Options:"
      echo "  --filter <status>   Filter tasks by status (pending, in-progress, complete, blocked)"
      echo "  --session <dir>     Path to the session directory (default: .codebuddy/session)"
      echo "  -h, --help          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Check that session directory exists
if [[ ! -d "$SESSION_DIR" ]]; then
  echo -e "${RED}Error:${NC} Session directory not found: $SESSION_DIR" >&2
  echo "Run init-session.sh to start a new planning session."
  exit 1
fi

TASKS_FILE="$SESSION_DIR/tasks.md"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo -e "${YELLOW}No tasks file found at:${NC} $TASKS_FILE"
  exit 0
fi

# Parse and display tasks
echo -e "${CYAN}=== Planning Session Tasks ===${NC}"
echo ""

total=0
pending=0
in_progress=0
complete=0
blocked=0

while IFS= read -r line; do
  # Match task lines: - [ ] task, - [x] task, - [~] task, - [!] task
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[([[:space:]xX~!])\][[:space:]](.+)$ ]]; then
    status_char="${BASH_REMATCH[1]}"
    task_text="${BASH_REMATCH[2]}"
    total=$((total + 1))

    case "$status_char" in
      " ")
        status="pending"
        icon="○"
        color="$NC"
        pending=$((pending + 1))
        ;;
      x|X)
        status="complete"
        icon="✓"
        color="$GREEN"
        complete=$((complete + 1))
        ;;
      "~")
        status="in-progress"
        icon="◑"
        color="$BLUE"
        in_progress=$((in_progress + 1))
        ;;
      "!")
        status="blocked"
        icon="✗"
        color="$RED"
        blocked=$((blocked + 1))
        ;;
      *)
        status="unknown"
        icon="?"
        color="$YELLOW"
        ;;
    esac

    # Apply filter if specified
    if [[ -z "$FILTER" || "$FILTER" == "$status" ]]; then
      echo -e "  ${color}${icon} [${status}]${NC} ${task_text}"
    fi
  fi
done < "$TASKS_FILE"

echo ""
echo -e "${CYAN}Summary:${NC} Total=${total} | ${GREEN}Complete=${complete}${NC} | ${BLUE}In-Progress=${in_progress}${NC} | Pending=${pending} | ${RED}Blocked=${blocked}${NC}"

# Exit with non-zero if there are blocked tasks
if [[ $blocked -gt 0 ]]; then
  exit 2
fi

exit 0
