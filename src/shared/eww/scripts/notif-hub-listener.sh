#!/bin/bash
# EWW notification hub listener
# Reads dunstctl history and outputs a JSON array for the notification hub
# Each entry: {id, appname, summary, body, timestamp, time_ago, desktop_entry}
# Output: single-line JSON on each poll cycle

emit() {
  if ! command -v dunstctl &>/dev/null; then
    echo '[]'
    return
  fi

  local raw
  raw=$(dunstctl history 2>/dev/null) || { echo '[]'; return; }

  # dunstctl history outputs JSON with a "data" array of arrays of notification objects
  # Parse with jq: extract fields, compute time_ago, filter out our own transient notifications
  if ! command -v jq &>/dev/null; then
    echo '[]'
    return
  fi

  local now
  now=$(date +%s)

  # dunst timestamps are monotonic uptime in microseconds (CLOCK_BOOTTIME)
  # Convert to wall clock by: now_epoch - (uptime_seconds - timestamp/1000000)
  local uptime_s
  uptime_s=$(awk '{print int($1)}' /proc/uptime)

  echo "$raw" | jq -c --argjson now "$now" --argjson uptime "$uptime_s" '
    [
      (.data // [[]])[0][]
      | select(.appname.data != null)
      | (($now - ($uptime - ((.timestamp.data // 0) / 1000000 | floor)))) as $epoch |
        {
          id: (.id.data // 0),
          appname: (.appname.data // "Unknown"),
          summary: ((.summary.data // "") | gsub("[\"\\\\]"; "")),
          body: ((.body.data // "") | gsub("[\"\\\\]"; "") | if length > 120 then .[:120] + "..." else . end),
          timestamp: (.timestamp.data // 0),
          desktop_entry: (.desktop_entry.data // ""),
          icon: (.icon_path.data // ""),
          date: ($epoch | strftime("%b %d")),
          time: ($epoch | strftime("%I:%M %p"))
        }
    ]
  ' 2>/dev/null || echo '[]'
}

emit

# Re-emit on SIGUSR1 (sent by dismiss/clear buttons)
trap 'emit' USR1

# Write our PID so buttons can signal us
echo $$ > /tmp/notif-hub-listener.pid

# Background poll every 5s as fallback, but instant on signal
while true; do
  sleep 5 &
  wait $!
  emit
done
