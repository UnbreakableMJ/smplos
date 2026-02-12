#!/bin/bash
# EWW bluetooth listener
# Output: single-line JSON {"powered","connected","device","icon"}

# Hardware availability (detected once at startup)
if command -v bluetoothctl &>/dev/null && bluetoothctl show &>/dev/null; then
  HAS_BT="yes"
else
  HAS_BT="no"
fi

emit() {
  local powered connected device icon

  if ! command -v bluetoothctl &>/dev/null; then
    printf '{"powered":"off","connected":"no","device":"","icon":"󰂲","available":"%s"}\n' "$HAS_BT"
    return
  fi

  # Check adapter power state
  if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    powered="on"
  else
    powered="off"
    printf '{"powered":"off","connected":"no","device":"","icon":"󰂲","available":"%s"}\n' "$HAS_BT"
    return
  fi

  # Check connected devices
  device=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
  if [[ -n "$device" ]]; then
    connected="yes"; icon="󰂱"
  else
    connected="no"; icon="󰂯"
  fi

  printf '{"powered":"%s","connected":"%s","device":"%s","icon":"%s","available":"%s"}\n' \
    "$powered" "$connected" "$device" "$icon" "$HAS_BT"
}

emit

# Poll -- bluetoothctl monitor is unreliable for connection state changes
while sleep 5; do emit; done
