#!/bin/bash
# EWW brightness listener (percentage)

emit() {
  local cur max pct
  if command -v brightnessctl &>/dev/null; then
    cur=$(brightnessctl get 2>/dev/null)
    max=$(brightnessctl max 2>/dev/null)
    if [[ -n "$cur" && -n "$max" && "$max" -gt 0 ]]; then
      pct=$(( cur * 100 / max ))
      echo "$pct"
      return
    fi
  fi
  echo "100"
}

emit

if command -v inotifywait &>/dev/null && ls /sys/class/backlight/*/brightness &>/dev/null; then
  inotifywait -mq -e close_write /sys/class/backlight/*/brightness 2>/dev/null | while read -r _; do
    emit
  done
else
  while sleep 2; do emit; done
fi
