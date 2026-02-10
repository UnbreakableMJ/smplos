#!/usr/bin/env bash
set -euo pipefail
#
# dev-push.sh -- Hot-push source files into the running VM
#
# Copies changed configs/scripts into the vmshare/ 9p shared folder.
# Inside the VM, run dev-apply.sh to install them into the live system.
#
# Usage:
#   ./dev-push.sh          # push everything
#   ./dev-push.sh eww      # push only EWW configs
#   ./dev-push.sh bin      # push only bin scripts
#   ./dev-push.sh hypr     # push only Hyprland configs
#   ./dev-push.sh themes   # push only themes
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")/src"
SHARE="$SCRIPT_DIR/vmshare"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[push]${NC} $*"; }
warn() { echo -e "${YELLOW}[push]${NC} $*"; }

# Create share directory structure
mkdir -p "$SHARE"/{eww,bin,hypr,themes}

what="${1:-all}"

# ── EWW configs ─────────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "eww" ]]; then
    log "Pushing EWW configs..."
    rm -rf "$SHARE/eww/"*
    cp -r "$SRC_DIR/shared/eww/"* "$SHARE/eww/"
    # Ensure scripts are executable
    find "$SHARE/eww/scripts" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
    log "  $(find "$SHARE/eww" -type f | wc -l) files"
fi

# ── Bin scripts ─────────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "bin" ]]; then
    log "Pushing bin scripts..."
    rm -rf "$SHARE/bin/"*
    cp -r "$SRC_DIR/shared/bin/"* "$SHARE/bin/"
    chmod +x "$SHARE/bin/"* 2>/dev/null || true
    log "  $(find "$SHARE/bin" -type f | wc -l) files"
fi

# ── Hyprland configs ────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "hypr" ]]; then
    log "Pushing Hyprland configs..."
    rm -rf "$SHARE/hypr/"*
    cp -r "$SRC_DIR/compositors/hyprland/hypr/"* "$SHARE/hypr/"
    # Copy shared bindings.conf into hypr dir (single source of truth)
    if [[ -f "$SRC_DIR/shared/configs/smplos/bindings.conf" ]]; then
        cp "$SRC_DIR/shared/configs/smplos/bindings.conf" "$SHARE/hypr/bindings.conf"
    fi
    log "  $(find "$SHARE/hypr" -type f | wc -l) files"
fi

# ── Themes ──────────────────────────────────────────────────
if [[ "$what" == "all" || "$what" == "themes" ]]; then
    log "Pushing themes..."
    rm -rf "$SHARE/themes/"*
    cp -r "$SRC_DIR/shared/themes/"* "$SHARE/themes/"
    log "  $(find "$SHARE/themes" -type f | wc -l) files"
fi

# ── Copy the apply script itself ────────────────────────────
cp "$SCRIPT_DIR/dev-apply.sh" "$SHARE/dev-apply.sh" 2>/dev/null || true
chmod +x "$SHARE/dev-apply.sh" 2>/dev/null || true

log ""
log "Done! Files staged in vmshare/"
log "In the VM, run:"
echo -e "  ${YELLOW}sudo bash /mnt/dev-apply.sh${NC}"
log "(If /mnt isn't mounted: ${YELLOW}sudo mount -t 9p -o trans=virtio hostshare /mnt${NC})"
