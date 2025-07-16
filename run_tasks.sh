#!/bin/bash

TASKS_FILE="$HOME/automation/tasks.json"
LOG_FILE="$HOME/automation/task.log"
LOCK_FILE="/tmp/run_tasks.lock"
JQ=$(command -v jq)
INOTIFYWAIT=$(command -v inotifywait)

# Cleanup on exit
cleanup() {
  echo "🧹 Cleaning up lock..."
  rm -f "$LOCK_FILE"
  exit 0
}
trap cleanup INT TERM EXIT

# Check dependencies
if [[ -z "$JQ" || -z "$INOTIFYWAIT" ]]; then
  echo "❌ Missing tools: Install with 'sudo dnf install jq inotify-tools'"
  exit 1
fi

# Prevent multiple instances
if [[ -f "$LOCK_FILE" ]]; then
  echo "⚠️ Already running (lock file exists at $LOCK_FILE)"
  exit 1
else
  touch "$LOCK_FILE"
fi

# Parse "5s", "2m", etc.
parse_delay() {
  local delay="$1"
  local unit="${delay: -1}"
  local number="${delay:0:${#delay}-1}"
  case "$unit" in
    s) echo "$number" ;;
    m) echo $((number * 60)) ;;
    h) echo $((number * 3600)) ;;
    *) echo "$delay" ;;
  esac
}

# Run a task
run_task() {
  local cmd="$1"
  local start_time="$2"
  local TIMESTAMP
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  echo "▶️ [$TIMESTAMP] Running: $cmd"

  if [[ "$cmd" == "check_ollama_update" ]]; then
    echo "[$TIMESTAMP] $cmd" >> "$LOG_FILE"
    bash -c "$HOME/automation/check_ollama_update.sh" >> "$LOG_FILE" 2>&1
  else
    if [[ $(($(date +%s) - start_time)) -ge 3600 ]]; then
      echo "[$TIMESTAMP] $cmd" >> "$LOG_FILE"
      bash -c "$cmd" >> "$LOG_FILE" 2>&1
    else
      bash -c "$cmd"
    fi
  fi

  if [[ $? -ne 0 ]]; then
    echo "❌ [$TIMESTAMP] Failed: $cmd" >> "$LOG_FILE"
  fi
}

# Run all tasks once, then enter interval-based loop
run_initial_and_interval_tasks() {
  local task_count
  task_count=$(jq length "$TASKS_FILE" 2>/dev/null)

  if [[ -z "$task_count" || "$task_count" -eq 0 ]]; then
    echo "⚠️ No valid tasks found in $TASKS_FILE"
    return
  fi

  declare -A delays
  declare -A commands

  echo "🚀 Running all tasks immediately first..."
  local start_time=$(date +%s)
  for (( i=0; i<task_count; i++ )); do
    local delay=$(jq -r ".[$i].delay" "$TASKS_FILE")
    local cmd=$(jq -r ".[$i].command" "$TASKS_FILE")

    if [[ "$delay" == "null" || "$cmd" == "null" ]]; then
      echo "⚠️ Skipping invalid task $i"
      continue
    fi

    delays[$i]=$(parse_delay "$delay")
    commands[$i]="$cmd"

    run_task "$cmd" "$start_time"
  done

  echo "🔁 Entering interval loop..."
  while true; do
    for i in "${!commands[@]}"; do
      sleep "${delays[$i]}"
      run_task "${commands[$i]}" "$start_time"
    done
  done
}

# Loop with file watch
watch_task_file() {
  while true; do
    run_initial_and_interval_tasks
    echo "📭 Waiting for changes in $TASKS_FILE..."
    inotifywait -e close_write "$TASKS_FILE" > /dev/null 2>&1
    echo "🔄 $TASKS_FILE updated, reloading..."
  done
}

echo "🔁 Task runner started."
watch_task_file
