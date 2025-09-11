#!/bin/bash

SCRIPT_PATH="$(pwd)/uptime.sh"

MARKER="# UPTIME_CHECK"

CRONTAB_CONTENT=$(crontab -l 2>/dev/null || true)

NEW_CRONTAB=$(echo "$CRONTAB_CONTENT" | grep -v "$MARKER" ; echo "0 * * * * $SCRIPT_PATH $MARKER")

echo "$NEW_CRONTAB" | crontab -

echo "✅ Задача добавлена в cron: запуск $SCRIPT_PATH каждый час"