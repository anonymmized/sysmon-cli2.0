#!/bin/bash

set -euo pipefail

OS=$(uname -s)

get_user_information() {
    cur_hostname=$(hostname)
    cur_username=$(whoami)
    echo "$cur_hostname,$cur_username"
}

get_top_processes() {
    printf "%-8s %-15s %8s %8s %s\n" "PID" "Name" "%CPU" "%MEM" "Path"
    ps aux | sort -nr -k 3 | head -5 | awk '{
        split($11, a, "/"); 
        printf "%-8s %-15s %8s %8s %s\n", $2, a[length(a)], $3"%", $4"%", $11
    }'
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
        echo "$cpu_model,$cores"
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

# === get_uptime_seconds ===
uptime_s=$(get_uptime_seconds)
days=$((uptime_s/86400))
hours=$(((uptime_s%86400)/3600))
mins=$(((uptime_s%3600)/60))
# === get_user_information ===
user_info=$(get_user_information)
IFS=',' read -r cur_hostname cur_username <<< "$user_info"
# === get_os_information ===
# $kernel_type,$os_type,$kernel_ver
os_info=$(get_os_information)
IFS=',' read -r kernel_type os_type kernel_ver <<< "$os_info"
# === get_time_information ===
# $cur_time,$cur_zone
time_info=$(get_time_information)
IFS=',' read -r cur_time cur_zone <<< "$time_info"
# === get_cpu_information ===
if [[ "$OS" == "Darwin" ]]; then
    #$cpu_brand,$core_count,$thread_count
    cpu_info=$(get_cpu_information)
    IFS=',' read -r cpu_brand core_count thread_count <<< "$cpu_info"
elif [[ "$OS" == "Linux" ]]; then
    #$cpu_model,$cores
    cpu_info=$(get_cpu_information)
    IFS=',' read -r cpu_model cores <<< "$cpu_info"
fi
# === get_mem_information === 
# $total_gb,$free_gb
mem_info=$(get_mem_information)
IFS=',' read -r total_gb free_gb <<< "$mem_info"
# === get_filesystem_info ===
# $filesys,$size,$capacity
fs_info=$(get_filesystem_info)
IFS=',' read -r filesys size capacity <<< "$fs_info"
# === output ===
echo "Time:"
echo "|-> Current time"
echo "|->->-> $cur_time"
echo "|-> TimeZone"
echo "|->->-> $cur_zone"
echo "Uptime:" 
echo "|-> ${days}d ${hours}h ${mins}m"
echo "Users:"
echo "|-> Host"
echo "|->->-> $cur_hostname"
echo "|-> User"
echo "|->->-> $cur_username"
echo "Kernel:"
echo "|-> Type"
echo "|->->-> $kernel_type"
echo "|-> Version"
echo "|->->-> $kernel_ver"
echo "|-> OS type"
echo "|->->-> $os_type"
if [[ "$OS" == "Darwin" ]]; then
    echo "CPU:"
    echo "|-> Brand"
    echo "|->->-> $cpu_brand"
    echo "|-> Cores"
    echo "|->->-> $core_count"
    echo "|-> Threads"
    echo "|->->-> $thread_count"
elif [[ "$OS" == "Linux" ]]; then
    echo "CPU:"
    echo "|-> Model"
    echo "|->->-> $cpu_model"
    echo "|-> Cores"
    echo "|->->-> $cores"
fi
echo "RAM:"
echo "|-> Total"
echo "|->->-> $total_gb"
echo "|-> Free"
echo "|->->-> $free_gb"
echo "Files:"
echo "|-> Filesystem"
echo "|->->-> $filesys"
echo "|-> Size"
echo "|->->-> $size"
echo "|-> Capacity"
echo "|->->-> $capacity"
get_top_processes