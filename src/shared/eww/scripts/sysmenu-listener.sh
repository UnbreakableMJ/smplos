#!/bin/bash
# EWW system menu state listener
# Output: single-line JSON with airplane mode and night light state

emit() {
  local airplane="off" nightlight="off"

  # Airplane: on if ALL radios are soft-blocked
  if command -v rfkill &>/dev/null; then
    local unblocked
    unblocked=$(rfkill -o SOFT -n list 2>/dev/null | grep -ci "unblocked")
    [[ "$unblocked" -eq 0 ]] && airplane="on"
  fi

  # Night light: on if gammastep is running
  pgrep -x gammastep &>/dev/null && nightlight="on"

  printf '{"airplane":"%s","nightlight":"%s"}\n' "$airplane" "$nightlight"
}

emit
while sleep 3; do emit; done
