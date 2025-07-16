#!/bin/bash

LIST_HASH_FILE="$HOME/automation/.ollama_list.hash"
CONFIG_UPDATER="$HOME/update_continue_config.sh"

# Get current hash of `ollama list` output
current_hash=$(ollama list | sha256sum | awk '{print $1}')

# Read previous hash if exists
if [[ -f "$LIST_HASH_FILE" ]]; then
  last_hash=$(cat "$LIST_HASH_FILE")
else
  last_hash=""
fi

# If hashes are different → model list changed
if [[ "$current_hash" != "$last_hash" ]]; then
  echo "🔁 Ollama model list changed. Running config updater..."
  bash "$CONFIG_UPDATER"
  echo "$current_hash" > "$LIST_HASH_FILE"
else
  echo "✅ No changes in Ollama model list."
fi
