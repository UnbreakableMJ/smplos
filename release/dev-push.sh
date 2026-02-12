#!/usr/bin/env bash
set -euo pipefail
#
# dev-push.sh -- Push all source files into vmshare/ for the VM
#
# Usage:  ./dev-push.sh
#
# In the VM:  sudo bash /mnt/dev-apply.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")/src"
SHARE="$SCRIPT_DIR/vmshare"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[push]${NC} $*"; }

# Clean and recreate
rm -rf "$SHARE"/{eww,bin,hypr,themes,configs,icons,st}
mkdir -p "$SHARE"/{eww,bin,hypr,themes,configs,icons,st}

# EWW
cp -r "$SRC_DIR/shared/eww/"* "$SHARE/eww/"
find "$SHARE/eww/scripts" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
log "EWW: $(find "$SHARE/eww" -type f | wc -l) files"

# Shared icons (SVG status icons for EWW bar)
if [[ -d "$SRC_DIR/shared/icons" ]]; then
    cp -r "$SRC_DIR/shared/icons/"* "$SHARE/icons/"
    log "Icons: $(find "$SHARE/icons" -type f | wc -l) files"
fi

# Bin scripts
cp -r "$SRC_DIR/shared/bin/"* "$SHARE/bin/"
chmod +x "$SHARE/bin/"* 2>/dev/null || true
log "Bin: $(find "$SHARE/bin" -type f | wc -l) files"

# Shared configs
cp -r "$SRC_DIR/shared/configs/"* "$SHARE/configs/"
log "Configs: $(find "$SHARE/configs" -type f | wc -l) files"

# Hyprland configs + shared bindings.conf
cp -r "$SRC_DIR/compositors/hyprland/hypr/"* "$SHARE/hypr/"
[[ -f "$SRC_DIR/shared/configs/smplos/bindings.conf" ]] && \
    cp "$SRC_DIR/shared/configs/smplos/bindings.conf" "$SHARE/hypr/bindings.conf"
log "Hypr: $(find "$SHARE/hypr" -type f | wc -l) files"

# Themes
cp -r "$SRC_DIR/shared/themes/"* "$SHARE/themes/"
log "Themes: $(find "$SHARE/themes" -type f | wc -l) files"

# st-wl terminal (build from source, auto-bump build number)
ST_DIR="$SRC_DIR/compositors/hyprland/st"
if [[ -f "$ST_DIR/st.c" ]]; then
    # Auto-bump: 0.9.5-test3 → 0.9.5-test4, or 0.9.3-fix2 → 0.9.3-fix3
    cur_ver=$(grep '^VERSION' "$ST_DIR/config.mk" | sed 's/.*= *//')
    # Extract base and number from patterns like "0.9.5-test3" or "0.9.3-fix2"
    if [[ "$cur_ver" =~ ^(.+[^0-9])([0-9]+)$ ]]; then
        base_ver="${BASH_REMATCH[1]}"
        build_num="${BASH_REMATCH[2]}"
        new_ver="${base_ver}$((build_num + 1))"
    else
        # No trailing number, append 2
        new_ver="${cur_ver}2"
    fi
    sed -i "s/^VERSION = .*/VERSION = $new_ver/" "$ST_DIR/config.mk"

    log "Building st-wl $new_ver..."
    (cd "$ST_DIR" && rm -f config.h && make clean && make -j"$(nproc)") 2>&1 | tail -1
    if [[ -f "$ST_DIR/st-wl" ]]; then
        cp "$ST_DIR/st-wl" "$SHARE/st/"
        log "st-wl $new_ver: binary copied"
    else
        log "st-wl: build FAILED"
    fi
fi

# Copy the apply script itself
cp "$SCRIPT_DIR/dev-apply.sh" "$SHARE/dev-apply.sh"
chmod +x "$SHARE/dev-apply.sh"

log ""
log "Done! In the VM run:  ${YELLOW}sudo bash /mnt/dev-apply.sh${NC}"
