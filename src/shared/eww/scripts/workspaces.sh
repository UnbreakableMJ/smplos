#!/bin/bash
# EWW workspaces listener (Hyprland)

emit() {
  if command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
    hyprctl workspaces -j 2>/dev/null | jq -c '[.[].id] | sort' || echo '[]'
  else
    echo '[]'
  fi
}

emit

sock="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
if [[ -S "$sock" ]] && command -v socat &>/dev/null; then
  socat -u UNIX-CONNECT:"$sock" - 2>/dev/null | while read -r line; do
    case "$line" in
      workspace*|focusedmon*|createworkspace*|destroyworkspace*|moveworkspace*) emit ;;
    esac
  done
else
  while sleep 1; do emit; done
fi
