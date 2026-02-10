#!/bin/bash
# EWW active window title listener (Hyprland)

emit() {
  if command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
    hyprctl activewindow -j 2>/dev/null | jq -r '.title // ""'
  else
    echo ""
  fi
}

emit

sock="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
if [[ -S "$sock" ]] && command -v socat &>/dev/null; then
  socat -u UNIX-CONNECT:"$sock" - 2>/dev/null | while read -r line; do
    case "$line" in
      activewindow*|closewindow*|movewindow*|fullscreen*) emit ;;
    esac
  done
else
  while sleep 1; do emit; done
fi
