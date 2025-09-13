#!/bin/bash
# upmon.sh — uptime monitor (Linux/macOS + Docker-aware)

set -euo pipefail

get_uptime_seconds_linux_host() {
  cut -d. -f1 /proc/uptime
}

get_uptime_seconds() {
  case "$OSTYPE" in
    linux-gnu*) get_uptime_seconds_linux_host ;;
    darwin*) 
      local boot now
      boot="$(/usr/sbin/sysctl -n kern.boottime | /usr/bin/awk -F'[ ,]' '{print $4}')"
      now="$(/bin/date +%s)"
      uptime_s=$(( now - boot))
      days=$(( uptime_s / 86400 ))
      hours=$(( (uptime_s / 86400) / 3600 ))
      minutes=$(( (uptime_s % 3600) / 60 ))
      echo "Active $days дней, $hours часов, $minutes минут"
      ;;
    *)
      echo "Unsupported OS: $OSTYPE" >&2
      return 2
      ;;
  esac
}

get_uptime_seconds
