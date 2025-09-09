#!/bin/bash
# work-session status line - Shows current work session information
# Refresh interval: 10 seconds

# Colors and symbols
CLOCK='⏱️'
FILES='📝'
LINES='📊'
FOLDER='📁'
FEATURE='🌟'
WORK='💼'

# Get current directory
CURRENT_DIR=$(basename "$(pwd)")

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$BRANCH" ]; then
  echo "${FOLDER} ${CURRENT_DIR} - Not a git repo"
  exit 0
fi

# Format branch name
if [ ${#BRANCH} -gt 15 ]; then
  BRANCH_DISPLAY="${BRANCH:0:12}..."
else
  BRANCH_DISPLAY="$BRANCH"
fi

# Check if feature branch
IS_FEATURE=""
if [[ "$BRANCH" == feat/* ]] || [[ "$BRANCH" == feature/* ]]; then
  IS_FEATURE="${FEATURE}"
fi

# Get session start time (use first commit time on this branch or file modification time)
SESSION_START_FILE="/tmp/claude-session-${USER}-$(pwd | md5sum | cut -d' ' -f1)"
if [ ! -f "$SESSION_START_FILE" ]; then
  date +%s > "$SESSION_START_FILE"
fi
SESSION_START=$(cat "$SESSION_START_FILE")
NOW=$(date +%s)
SESSION_DURATION=$(( (NOW - SESSION_START) / 60 ))

# Format duration
if [ $SESSION_DURATION -lt 60 ]; then
  DURATION="${SESSION_DURATION}m"
else
  HOURS=$((SESSION_DURATION / 60))
  MINS=$((SESSION_DURATION % 60))
  DURATION="${HOURS}h${MINS}m"
fi

# Count changed files in this session
CHANGED_FILES=$(git diff --name-only 2>/dev/null | wc -l)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l)
TOTAL_FILES=$((CHANGED_FILES + STAGED_FILES))

# Count lines changed
if [ $TOTAL_FILES -gt 0 ]; then
  ADDED=$(git diff --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
  DELETED=$(git diff --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
  
  # Include staged changes
  STAGED_ADDED=$(git diff --cached --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
  STAGED_DELETED=$(git diff --cached --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
  
  TOTAL_ADDED=$((${ADDED:-0} + ${STAGED_ADDED:-0}))
  TOTAL_DELETED=$((${DELETED:-0} + ${STAGED_DELETED:-0}))
  
  LINES_INFO=" +${TOTAL_ADDED}/-${TOTAL_DELETED}"
else
  LINES_INFO=""
fi

# Build status line
echo "${WORK} ${CURRENT_DIR}/${IS_FEATURE}${BRANCH_DISPLAY} ${CLOCK}${DURATION} ${FILES}${TOTAL_FILES}${LINES_INFO}"