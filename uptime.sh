#!/bin/bash
# upmon.sh — uptime monitor (Linux/macOS + Docker-aware)

set -euo pipefail

get_user_information() {
    cur_hostname=$(hostname)
    cur_username=$(whoami)

}

get_time_information() {
    cur_time=$(w | head -n1 | awk '{print $1}')
    cur_zone=$(ls -l /etc/localtime | awk -F/ '{print $(NF-1) "/" $NF}')
    echo -e "Current time - $cur_time\nCurrent zone - $cur_zone"
}

get_os_information() {
    kernel_type=$(uname -m)
    kernel_ver=$(uname -r)
    os_type=$(uname -s)
    if [[ $os_type == "Darwin" ]]; then
        echo -e "Kernel - $kernel_type\nOS - MacOS\nKernel version - $kernel_ver"
    elif [[ $os_type == "Linux" ]]; then
        echo -e "Kernel - $kernel_type\nOS - Linux\nKernel version - $kernel_ver"
    fi
}

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
get_os_information
get_time_information