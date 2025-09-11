#!/bin/bash

SCRIPT_PATH="$(pwd)/uptime.sh"
MARKER="# UPTIME_CHECK"
CRONTAB_CONTENT=$(crontab -l 2>/dev/null || true)
NEW_CRONTAB=$(
  { echo "$CRONTAB_CONTENT" | grep -v "$MARKER"
    echo "* * * * * $SCRIPT_PATH >> /tmp/uptime.log 2>&1 $MARKER"; }
)
echo "$NEW_CRONTAB" | crontab -
echo "[*] Crontab configuration added"
uptime_line=$(w | head -n1)
uptime_part=$(echo "$uptime_line" | sed -E 's/.*up (.*), [0-9]+ user.*/\1/')

case "$uptime_part" in
    *secs)
        number=$(echo "$uptime_part" | awk '{print $1}')
        echo "Активен $number секунд"
        ;;
    *min)
        number=$(echo "$uptime_part" | awk '{print $1}')
        echo "Активен $number минут"
        ;;
    *days,*:*)
        days=$(echo "$uptime_part" | awk '{print $1}')
        time=$(echo "$uptime_part" | awk '{print $3}')
        IFS=":" read -r hours minutes <<< "$time"
        echo "Активен $days дней $hours часов $minutes минут"
        ;;
    *days)
        number=$(echo "$uptime_part" | awk '{print $1}')
        echo "Активен $number дней"
        ;;
    *:*)
        IFS=":" read -r hours minutes <<< "$uptime_part"
        echo "Активен $hours часов $minutes минут"
        ;;
    *)
        echo "Неизвестный формат: $uptime_part"
        ;;
esac