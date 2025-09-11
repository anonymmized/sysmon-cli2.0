# Upmon — Simple Uptime Monitor

`upmon.sh` is a lightweight uptime monitor for Linux and macOS (with Docker support).
It checks how long the system (or container) has been running without a reboot and warns you if it exceeds a configurable threshold.

✅ Works on Linux and macOS
✅ Detects if running inside a Docker container and calculates container uptime correctly
✅ Shows red bold warning in terminal when threshold is exceeded
✅ Sends system notifications (Linux: notify-send, macOS: osascript)
✅ No cron jobs, no log files, just a simple loop

## ⚙️ Installation
Clone or copy the script into your system:
```bash
git clone https://github.com/anonymmized/upmon-script.git
cd upmon-script
chmod +x uptime.sh
```
Optionally add it to your PATH:
```bash
cp uptime.sh ~/.local/bin/uptime
```

## 🚀 Usage
Run directly:
```bash
./uptime.sh
```
Or run in the background:
```bash
./uptime.sh & disown
```
Stop it later with:
```bash
pkill -f uptime.sh
```

## 🔧 Configuration

You can override default settings with environment variables:
- `UPTIME_DAYS` — number of days before showing warnings (default: 3)
- `UPTIME_INTERVAL` — check interval in seconds (default: 3600 = 1 hour)
Example: check every 10 seconds and warn after 0 days (for testing):
```bash
UPTIME_DAYS=0 UPTIME_INTERVAL=10 ./uptime.sh
```

## 🐳 Docker Support
Inside Docker, `uptime.sh` calculates uptime based on the container’s PID 1 start time, not the host uptime.
This way you can monitor container runtime correctly.

## 📋 Requirements
- Linux:
`notify-send` (optional, package: `libnotify-bin`)
- macOS:
`osascript` (built-in)
If notifications are not available, script still prints warnings in the terminal.

### 📌 Example Output
```bash
⚠️  System has been running for 7 days without reboot!
👉 It is recommended to reboot the system.
```
And on macOS/Linux desktop, a system notification appears:
```bash
⚠️ System has been running for 7 days. A reboot is recommended.
```