#!/bin/bash
# init-session.sh
# Initializes a planning session by creating the necessary directory structure
# and session files for the planning-with-files skill.
#
# Usage: ./init-session.sh [session-name] [--force]

set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PLANNING_ROOT="${PLANNING_ROOT:-./planning}"
SESSION_FILE=".session"
PLAN_FILE="PLAN.md"
TASKS_FILE="TASKS.md"
NOTES_FILE="NOTES.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [SESSION_NAME] [--force]

Arguments:
  SESSION_NAME   Optional name for the session (default: session-<timestamp>)
  --force        Overwrite an existing session directory

Environment variables:
  PLANNING_ROOT  Root directory for planning sessions (default: ./planning)
EOF
  exit 0
}

# ─── Argument Parsing ─────────────────────────────────────────────────────────
SESSION_NAME=""
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --force|-f) FORCE=true ;;
    *) SESSION_NAME="$arg" ;;
  esac
done

if [[ -z "$SESSION_NAME" ]]; then
  SESSION_NAME="session-$(date -u +"%Y%m%d-%H%M%S")"
  warn "No session name provided. Using auto-generated name: ${SESSION_NAME}"
fi

SESSION_DIR="${PLANNING_ROOT}/${SESSION_NAME}"

# ─── Pre-flight Checks ────────────────────────────────────────────────────────
if [[ -d "$SESSION_DIR" ]]; then
  if [[ "$FORCE" == true ]]; then
    warn "Session directory already exists. --force flag set; overwriting."
    rm -rf "$SESSION_DIR"
  else
    error "Session directory '${SESSION_DIR}' already exists."
    error "Use --force to overwrite, or choose a different session name."
    exit 1
  fi
fi

# ─── Create Directory Structure ───────────────────────────────────────────────
info "Creating session directory: ${SESSION_DIR}"
mkdir -p "${SESSION_DIR}/notes"
mkdir -p "${SESSION_DIR}/artifacts"
success "Directory structure created."

# ─── Write .session metadata ──────────────────────────────────────────────────
cat > "${SESSION_DIR}/${SESSION_FILE}" <<EOF
# Planning Session Metadata
session_name=${SESSION_NAME}
created_at=${TIMESTAMP}
status=active
skill_version=$(grep '"version"' "${SKILL_DIR}/../../../.claude-plugin/plugin.json" 2>/dev/null | head -1 | grep -oP '[\d.]+'  || echo 'unknown')
EOF
success "Session metadata written to ${SESSION_FILE}."

# ─── Write PLAN.md ────────────────────────────────────────────────────────────
cat > "${SESSION_DIR}/${PLAN_FILE}" <<EOF
# Plan — ${SESSION_NAME}

> Created: ${TIMESTAMP}

## Objective

<!-- Describe the high-level goal of this planning session. -->

## Scope

- **In scope:**
- **Out of scope:**

## Milestones

| # | Milestone | Target Date | Status |
|---|-----------|-------------|--------|
| 1 |           |             | 🔲 Todo |

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
EOF
success "${PLAN_FILE} initialised."

# ─── Write TASKS.md ───────────────────────────────────────────────────────────
cat > "${SESSION_DIR}/${TASKS_FILE}" <<EOF
# Tasks — ${SESSION_NAME}

> Created: ${TIMESTAMP}

## Backlog

- [ ] <!-- Add tasks here -->

## In Progress

## Done
EOF
success "${TASKS_FILE} initialised."

# ─── Write NOTES.md ───────────────────────────────────────────────────────────
cat > "${SESSION_DIR}/${NOTES_FILE}" <<EOF
# Notes — ${SESSION_NAME}

> Created: ${TIMESTAMP}

<!-- Capture any freeform notes, links, or context here. -->
EOF
success "${NOTES_FILE} initialised."

# ─── Summary ──────────────────────────────────────────────────────────────────
echo
echo -e "${GREEN}Session '${SESSION_NAME}' is ready.${NC}"
echo -e "  Location : ${SESSION_DIR}"
echo -e "  Files    : ${PLAN_FILE}, ${TASKS_FILE}, ${NOTES_FILE}, ${SESSION_FILE}"
echo
