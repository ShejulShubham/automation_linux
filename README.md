# 🛠️ Task Runner Bash Script

This script automates background tasks by parsing commands and their intervals from a `tasks.json` file. It runs tasks **once on startup** and then **repeats them periodically**, making it perfect for long-running background automation.

---

## 📦 Features

- 🕓 Run shell commands on login and repeat at a defined interval.
- 🌀 Auto-reloads when `tasks.json` changes.
- 🔐 Lock mechanism to prevent duplicate runs.
- 🧠 Human-readable delay units: `s`, `m`, `h`.
- 📜 Logging support with automatic output capture.
- 🧩 Built-in handling for special commands like `check_ollama_update`.

---

## 🛠️ Dependencies

Install required tools:

```bash
# Fedora/RHEL:
sudo dnf install jq inotify-tools

# Debian/Ubuntu:
sudo apt install jq inotify-tools
```

---

## 📁 Directory Structure

```bash
~/automation/
├── tasks.json              # JSON file with tasks and intervals
├── check_ollama_update.sh  # Optional: Custom script
├── task.log                # Auto-generated logs
└── run_tasks.sh            # The main runner script
```

---

## 📋 tasks.json Format

```json
[
  {
    "command": "check_ollama_update",
    "delay": "5m"
  },
  {
    "command": "echo '🔔 Background task started'",
    "delay": "30s"
  }
]
```

- `command`: Any valid shell command or script.
- `delay`: Interval to re-run the command (e.g., `"10s"`, `"5m"`, `"1h"`).

---

## 🧪 Example Task: Create and Run

### 1. Create your task file

```bash
mkdir -p ~/automation

cat > ~/automation/tasks.json <<EOF
[
  {
    "command": "echo '✅ System check running...'",
    "delay": "1m"
  },
  {
    "command": "check_ollama_update",
    "delay": "10m"
  }
]
EOF
```

---

## 🚀 Run on Startup (with Logging)

To start the automation on every terminal session: **add this line to your `.zshrc`** (or `.bashrc`):

```bash
bash ~/automation/run_tasks.sh &
```
> The `&` ensures it runs in the background.

OR to start the automation on every terminal session with logs saved to `task.log`, **add this line to your `.zshrc`** (or `.bashrc`):

```bash
(bash "$HOME/automation/run_tasks.sh" >> "$HOME/automation/task.log" 2>&1 &)
```

> This runs the script in the background **and** appends both output and error logs to `task.log`.

---

## 🔁 Logs & Monitoring

All output from background tasks will be stored in:

```bash
~/automation/task.log
```

To watch logs in real time:

```bash
tail -f ~/automation/task.log
```

---

## 🧹 Stop and Clean Up

To manually stop the script and remove lock:

```bash
pkill -f run_tasks.sh
rm -f /tmp/run_tasks.lock
```

---

## 💬 Tips

- Add as many tasks as needed in `tasks.json`, each with a unique delay.
- Avoid very short delays unless necessary to prevent CPU waste.
- Custom command handling (like `check_ollama_update`) can be extended in the script.

---
