#!/bin/bash

set -euo pipefail

OS=$(uname -s)

get_user_information() {
    cur_hostname=$(hostname)
    cur_username=$(whoami)
    echo "$cur_hostname,$cur_username"
}

get_filesystem_info() {
    if [[ $OS == "Darwin" ]]; then
        filesys=$(df -h / | awk 'NR==2 {print $1}')
        size=$(df -h / | awk 'NR==2 {print $2}')
        capacity=$(df -h / | awk 'NR==2 {print $5}')
        echo "$filesys,$size,$capacity"
    elif [[ $OS == "Linux" ]]; then
        filesys=$(df -h --output=source / | sed 1d)
        size=$(df -h --output=size / | sed 1d)
        capacity=$(df -h --output=pcent / | sed 1d)
        echo "$filesys,$size,$capacity"
    fi
}

get_cpu_information() {
    if [[ $OS == "Darwin" ]]; then
        cpu_brand=$(sysctl -n machdep.cpu.brand_string)
        core_count=$(sysctl -n machdep.cpu.core_count)
        thread_count=$(sysctl -n machdep.cpu.thread_count)
        echo "$cpu_brand,$core_count,$thread_count"
    elif [[ $OS == "Linux" ]]; then
        cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
        cores=$(grep -c '^processor' /proc/cpuinfo)
        echo "$cpu_model, $cores"
    fi 
}
get_mem_information() {
    if [[ $OS == "Darwin" ]]; then 
        total_bytes=$(sysctl -n hw.memsize)
        total_gb=$(( total_bytes / 1073741824 ))

        pagesize=$(sysctl -n hw.pagesize)
        free_bytes=$(vm_stat | awk -v ps="$pagesize" '
            /Pages free/        {free=$3*ps}
            /Pages inactive/    {inactive=$3*ps}
            /Pages speculative/ {spec=$3*ps}
            END {print free+inactive+spec}
        ')
        free_gb=$(( free_bytes / 1073741824 ))

        echo "$total_gb,$free_gb"

    elif [[ $OS == "Linux" ]]; then
        total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        free_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        total_gb=$(( total_kb / 1048576 ))
        free_gb=$(( free_kb / 1048576 ))

        echo "$total_gb,$free_gb"
    fi
}

get_time_information() {
    cur_time=$(w | head -n1 | awk '{print $1}')
    cur_zone=$(ls -l /etc/localtime | awk -F/ '{print $(NF-1) "/" $NF}')
    echo "$cur_time,$cur_zone"
}

get_os_information() {
    kernel_type=$(uname -m)
    kernel_ver=$(uname -r)
    os_type=$(uname -s)
    echo "$kernel_type,$os_type,$kernel_ver"
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
      echo $(( now - boot ))
      ;;
    *)
      echo "Unsupported OS: $OSTYPE" >&2
      return 2
      ;;
  esac
}

uptime_s=$(get_uptime_seconds)

days=$((uptime_s/86400))
hours=$(((uptime_s%86400)/3600))
mins=$(((uptime_s%3600)/60))
echo "Uptime: ${days}d ${hours}h ${mins}m"
get_user_information
get_os_information
get_time_information
get_cpu_information
get_mem_information
get_filesystem_info