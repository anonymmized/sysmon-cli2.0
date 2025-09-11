#!/bin/bash
# upmon.sh — uptime monitor (Linux/macOS + Docker-aware)

set -euo pipefail

THRESHOLD_DAYS=${UPMON_DAYS:-3}
INTERVAL_SECONDS=${UPMON_INTERVAL:-3600}

RED_BOLD="\033[1;31m"
RESET="\033[0m"

is_container() {
  [[ -f /.dockerenv ]] && return 0
  grep -Eqs '(docker|containerd|kubepods)' /proc/1/cgroup 2>/dev/null
}

get_uptime_seconds_linux_host() {
  cut -d. -f1 /proc/uptime
}

get_container_uptime_seconds() {
  local stat start_ticks hz host_uptime_s
  stat=$(</proc/1/stat)
  start_ticks=$(awk '{print $22}' <<<"$stat")
  hz=$(getconf CLK_TCK)
  host_uptime_s=$(get_uptime_seconds_linux_host)
  awk -v U="$host_uptime_s" -v S="$start_ticks" -v HZ="$hz" 'BEGIN{printf "%.0f", U - (S/HZ)}'
}

get_uptime_seconds() {
  case "$OSTYPE" in
    linux-gnu*)
      if is_container; then
        get_container_uptime_seconds
      else
        get_uptime_seconds_linux_host
      fi
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
  is_container && return 0
  case "$OSTYPE" in
    linux-gnu*)
      command -v notify-send >/dev/null 2>&1 && notify-send "⚠️ $1" "$2"
      ;;
    darwin*)
      /usr/bin/osascript -e "display notification \"$2\" with title \"$1\""
      ;;
  esac
}

while true; do
  uptime_s="$(get_uptime_seconds || echo 0)"
  uptime_days=$(( uptime_s / 86400 ))

  if (( uptime_days >= THRESHOLD_DAYS )); then
    echo -e "${RED_BOLD}⚠️  System has been running for ${uptime_days} days without reboot!${RESET}"
    echo -e "${RED_BOLD}👉 It is recommended to reboot the system.${RESET}"
    notify_user "Upmon" "System has been running for ${uptime_days} days. A reboot is recommended."
  fi

  sleep "$INTERVAL_SECONDS"
done
