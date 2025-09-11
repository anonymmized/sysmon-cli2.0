#!/bin/bash
# upmon.sh — simple uptime monitor without cron/logs (Linux + macOS)

set -euo pipefail

# ===== Settings =====
THRESHOLD_DAYS=${UPMON_DAYS:-3}           # threshold in days (can override via env UPMON_DAYS)
INTERVAL_SECONDS=${UPMON_INTERVAL:-3600}  # check interval in seconds (e.g., 10 for testing)

# Colors
RED_BOLD="\033[1;31m"
RESET="\033[0m"

# ===== Functions =====
get_uptime_seconds() {
  case "$OSTYPE" in
    linux-gnu*)
      cut -d. -f1 /proc/uptime
      ;;
    darwin*)
      local boot now
      boot="$(/usr/sbin/sysctl -n kern.boottime | /usr/bin/awk -F'[ ,]' '{print $4}')"
      now="$(/bin/date +%s)"
      echo $(( now - boot ))
      ;;
    *)
      echo "Unsupported OS: $OSTYPE" >&2
      return 2
      ;;
  esac
}

notify_user() {
  # $1 = title, $2 = message
  case "$OSTYPE" in
    linux-gnu*)
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "⚠️ $1" "$2"
      fi
      ;;
    darwin*)
      /usr/bin/osascript -e "display notification \"$2\" with title \"$1\""
      ;;
  esac
}

# ===== Main loop =====
while true; do
  uptime_s="$(get_uptime_seconds || echo 0)"
  uptime_days=$(( uptime_s / 86400 ))

  if (( uptime_days >= THRESHOLD_DAYS )); then
    # Print to terminal every time the threshold is exceeded
    echo -e "${RED_BOLD}⚠️  System has been running for ${uptime_days} days without reboot!${RESET}"
    echo -e "${RED_BOLD}👉 It is recommended to reboot the system.${RESET}"

    # Always send a system notification
    notify_user "Upmon" "System has been running for ${uptime_days} days. A reboot is recommended."
  fi

  sleep "$INTERVAL_SECONDS"
done
