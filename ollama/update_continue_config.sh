#!/bin/bash

# Location of the Continue config file
CONFIG="$HOME/.continue/config.yaml"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$CONFIG")"

# Write header
cat > "$CONFIG" <<EOL
name: Local Assistant
version: 1.0.0
schema: v1

models:
EOL

# Append one entry per installed model
ollama list | tail -n +2 | while read -r line; do
  model=$(echo "$line" | awk '{print $1}')
  cat >> "$CONFIG" <<EOM
  - name: $model
    provider: ollama
    model: $model
    api_base: http://localhost:11434
    roles:
      - chat
      - edit
      - apply
EOM

  # Add autocomplete only for smaller models
  if [[ "$model" == *"tiny"* || "$model" == *"3b"* || "$model" == *"1.3b"* ]]; then
    echo "      - autocomplete" >> "$CONFIG"
  fi
done

# Append context providers
cat >> "$CONFIG" <<EOL

context:
  - provider: code
  - provider: docs
  - provider: diff
  - provider: terminal
  - provider: problems
  - provider: folder
  - provider: codebase

default_model: $(ollama list | awk 'NR==2{print $1}')
inline_suggestions: false
EOL

echo "✅ Continue config updated at $CONFIG"
