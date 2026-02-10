#!/bin/bash
# EWW volume listener (single-line JSON)

emit() {
  local level mute icon
  if ! command -v pactl &>/dev/null; then
    echo '{"level":"0","muted":"yes","icon":""}'
    return
  fi

  level=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F'/' 'NR==1{gsub(/ /,"",$2); gsub(/%/,"",$2); print $2}')
  mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')

  if [[ -z "$level" ]]; then
    level=0
  fi

  if [[ "$mute" == "yes" ]]; then
    icon="󰝟"
  elif (( level == 0 )); then
    icon="󰕿"
  elif (( level < 50 )); then
    icon="󰖀"
  else
    icon="󰕾"
  fi

  printf '{"level":"%s","muted":"%s","icon":"%s"}\n' "$level" "$mute" "$icon"
}

emit

if command -v pactl &>/dev/null; then
  pactl subscribe 2>/dev/null | while read -r line; do
    [[ "$line" == *"sink"* || "$line" == *"server"* ]] && emit
  done
else
  while sleep 2; do emit; done
fi
