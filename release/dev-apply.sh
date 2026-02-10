#!/usr/bin/env bash
set -euo pipefail
#
# dev-apply.sh -- Apply hot-pushed files inside the running VM
#
# Run this inside the VM after dev-push.sh has staged files.
# It copies configs to the right places and restarts affected services.
#
# Usage:
#   sudo mount /dev/vdb /mnt
#   bash /mnt/dev-apply.sh          # apply everything
#   bash /mnt/dev-apply.sh eww      # apply only EWW
#   bash /mnt/dev-apply.sh bin      # apply only bin scripts
#   bash /mnt/dev-apply.sh hypr     # apply only Hyprland configs
#   bash /mnt/dev-apply.sh themes   # apply only themes
#

SHARE="/mnt"
USER_HOME="$HOME"

# If running as root, find the real user
if [[ "$EUID" -eq 0 ]]; then
    REAL_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-}")
    if [[ -n "$REAL_USER" && "$REAL_USER" != "root" ]]; then
        USER_HOME="/home/$REAL_USER"
        USER_ID=$(id -u "$REAL_USER")
    fi
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[apply]${NC} $*"; }
warn() { echo -e "${YELLOW}[apply]${NC} $*"; }

# Helper: Run command as user with graphical environment
run_as_user() {
    local cmd="$1"
    if [[ "$EUID" -eq 0 && -n "${REAL_USER:-}" ]]; then
        log "  [debug] Running as root, REAL_USER=$REAL_USER, USER_ID=${USER_ID:-unset}"

        local xdg_dir="/run/user/$USER_ID"
        local env_vars="export XDG_RUNTIME_DIR=$xdg_dir;"

        # Detect WAYLAND_DISPLAY from the socket file in XDG_RUNTIME_DIR
        local wl_display=""
        for sock in "$xdg_dir"/wayland-*; do
            [[ -S "$sock" ]] || continue
            wl_display=$(basename "$sock")
            break
        done
        log "  [debug] WAYLAND_DISPLAY=${wl_display:-NOT FOUND} (from socket in $xdg_dir)"
        [[ -n "$wl_display" ]] && env_vars+="export WAYLAND_DISPLAY=$wl_display;"

        # Detect HYPRLAND_INSTANCE_SIGNATURE from multiple locations
        local hypr_sig=""
        # Try /tmp/hypr/
        [[ -d /tmp/hypr ]] && hypr_sig=$(ls -1 /tmp/hypr/ 2>/dev/null | head -n1)
        # Try XDG_RUNTIME_DIR/hypr/
        [[ -z "$hypr_sig" && -d "$xdg_dir/hypr" ]] && hypr_sig=$(ls -1 "$xdg_dir/hypr/" 2>/dev/null | head -n1)
        # Fallback: scrape from any child of Hyprland (e.g. eww, bar scripts)
        if [[ -z "$hypr_sig" ]]; then
            local child_pid=$(pgrep -u "$REAL_USER" -f 'eww|hyprctl|waybar' 2>/dev/null | head -n1)
            [[ -n "$child_pid" ]] && hypr_sig=$(tr '\0' '\n' < /proc/"$child_pid"/environ 2>/dev/null | grep ^HYPRLAND_INSTANCE_SIGNATURE= | cut -d= -f2)
        fi
        log "  [debug] HYPRLAND_INSTANCE_SIGNATURE=${hypr_sig:-NOT FOUND}"
        [[ -n "$hypr_sig" ]] && env_vars+="export HYPRLAND_INSTANCE_SIGNATURE=$hypr_sig;"

        log "  [debug] Final env: $env_vars"
        log "  [debug] Command: $cmd"

        su - "$REAL_USER" -c "$env_vars $cmd"
    else
        bash -c "$cmd"
    fi
}

# Check mount
if [[ ! -f "$SHARE/dev-apply.sh" ]]; then
    echo "Shared folder not mounted. Run:"
    echo "  sudo mount -t 9p -o trans=virtio hostshare /mnt"
    exit 1
fi

what="${1:-all}"
restart_eww=false
restart_hypr=false

# ── EWW configs ─────────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "eww" ]]; then
    if [[ -d "$SHARE/eww" && "$(ls -A "$SHARE/eww" 2>/dev/null)" ]]; then
        log "Applying EWW configs..."
        # Clean target so deleted files don't linger
        rm -rf "$USER_HOME/.config/eww"
        mkdir -p "$USER_HOME/.config/eww"
        cp -r "$SHARE/eww/"* "$USER_HOME/.config/eww/"
        find "$USER_HOME/.config/eww/scripts" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
        chown -R "$(stat -c '%U:%G' "$USER_HOME")" "$USER_HOME/.config/eww/" 2>/dev/null || true
        restart_eww=true
        log "  EWW configs installed"
    fi
fi

# ── Bin scripts ─────────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "bin" ]]; then
    if [[ -d "$SHARE/bin" && "$(ls -A "$SHARE/bin" 2>/dev/null)" ]]; then
        log "Applying bin scripts..."
        # Remove stale scripts that no longer exist in source
        for existing in /usr/local/bin/*; do
            [[ -f "$existing" ]] || continue
            name=$(basename "$existing")
            # Only remove if it was ours (has smplOS marker or matches a name we ship)
            [[ -f "$SHARE/bin/$name" ]] || {
                head -5 "$existing" 2>/dev/null | grep -qi 'smplos\|smplOS' && rm -f "$existing" && log "  Removed stale: $name"
            }
        done
        cp -r "$SHARE/bin/"* /usr/local/bin/
        # Only chmod our scripts, not everything in /usr/local/bin/
        for f in "$SHARE/bin/"*; do
            chmod +x "/usr/local/bin/$(basename "$f")" 2>/dev/null || true
        done
        log "  $(ls "$SHARE/bin" | wc -l) scripts installed to /usr/local/bin/"
    fi
fi

# ── Hyprland configs ────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "hypr" ]]; then
    if [[ -d "$SHARE/hypr" && "$(ls -A "$SHARE/hypr" 2>/dev/null)" ]]; then
        log "Applying Hyprland configs..."
        mkdir -p "$USER_HOME/.config/hypr"
        cp -r "$SHARE/hypr/"* "$USER_HOME/.config/hypr/"
        chown -R "$(stat -c '%U:%G' "$USER_HOME")" "$USER_HOME/.config/hypr/" 2>/dev/null || true
        # Also copy bindings.conf to shared smplos dir (cross-compositor source of truth)
        if [[ -f "$SHARE/hypr/bindings.conf" ]]; then
            mkdir -p "$USER_HOME/.config/smplos"
            cp "$SHARE/hypr/bindings.conf" "$USER_HOME/.config/smplos/bindings.conf"
            chown -R "$(stat -c '%U:%G' "$USER_HOME")" "$USER_HOME/.config/smplos/" 2>/dev/null || true
        fi
        restart_hypr=true
        log "  Hyprland configs installed"
    fi
fi

# ── Themes ──────────────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "themes" ]]; then
    if [[ -d "$SHARE/themes" && "$(ls -A "$SHARE/themes" 2>/dev/null)" ]]; then
        THEMES_DEST="$USER_HOME/.local/share/smplos/themes"
        log "Applying themes..."
        mkdir -p "$THEMES_DEST"
        cp -r "$SHARE/themes/"* "$THEMES_DEST/"
        chown -R "$(stat -c '%U:%G' "$USER_HOME")" "$THEMES_DEST" 2>/dev/null || true
        log "  Themes installed to $THEMES_DEST"
    fi
fi

# ── Restart services ────────────────────────────────────────
if $restart_eww; then
    log "Restarting EWW..."
    # Kill existing eww and listeners
    log "  [debug] Killing existing eww processes..."
    pkill -x eww 2>/dev/null || true
    sleep 0.5
    
    # Verify it's dead
    if pgrep -x eww &>/dev/null; then
        warn "  [debug] eww still running after pkill, force killing..."
        pkill -9 -x eww 2>/dev/null || true
        sleep 0.3
    fi
    log "  [debug] eww processes after kill: $(pgrep -x eww 2>/dev/null | tr '\n' ' ' || echo 'none')"
    
    # Restart EWW daemon + open bar
    LOG="/tmp/eww-start.log"
    # Ensure log file is owned by the real user (not root)
    rm -f "$LOG"
    su - "$REAL_USER" -c "echo '=== EWW restart $(date) ===' > $LOG" 2>/dev/null
    
    CMD="eww daemon --config $USER_HOME/.config/eww >>$LOG 2>&1; sleep 1; eww --config $USER_HOME/.config/eww open bar >>$LOG 2>&1"
    
    log "  [debug] Starting EWW daemon + bar..."
    run_as_user "$CMD"
    
    log "  [debug] eww processes after start: $(pgrep -x eww 2>/dev/null | tr '\n' ' ' || echo 'none')"
    log "  [debug] /tmp/eww-start.log contents:"
    cat "$LOG" 2>/dev/null | while IFS= read -r line; do
        log "    $line"
    done
    log "  EWW restart complete"
fi

if $restart_hypr; then
    log "Reloading Hyprland..."
    run_as_user "hyprctl reload" 2>/dev/null || warn "  hyprctl reload failed"
    log "  Hyprland config reloaded"
fi

# ── Re-apply current theme (after restarts so configs are fresh) ──
if $restart_hypr || [[ "$what" == "all" || "$what" == "themes" ]]; then
    current_theme=$(cat "$USER_HOME/.config/smplos/current/theme.name" 2>/dev/null || true)
    if [[ -n "${current_theme:-}" ]]; then
        log "Re-applying theme '$current_theme'..."
        run_as_user "theme-set '$current_theme'" 2>/dev/null || warn "  theme-set failed"
    fi
fi

log ""
log "All done! Changes are live."
