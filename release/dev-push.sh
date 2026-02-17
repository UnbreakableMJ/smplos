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
rm -rf "$SHARE"/{eww,bin,hypr,themes,configs,icons,st,notif-center,kb-center,disp-center,applications}
mkdir -p "$SHARE"/{eww,bin,hypr,themes,configs,icons,st,notif-center,kb-center,disp-center,applications}

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

# Applications (.desktop files)
if [[ -d "$SRC_DIR/shared/applications" ]]; then
    cp "$SRC_DIR/shared/applications/"*.desktop "$SHARE/applications/" 2>/dev/null || true
    log "Applications: $(find "$SHARE/applications" -type f | wc -l) files"
fi

# Hyprland configs + shared bindings.conf
cp -r "$SRC_DIR/compositors/hyprland/hypr/"* "$SHARE/hypr/"
[[ -f "$SRC_DIR/shared/configs/smplos/bindings.conf" ]] && \
    cp "$SRC_DIR/shared/configs/smplos/bindings.conf" "$SHARE/hypr/bindings.conf"
log "Hypr: $(find "$SHARE/hypr" -type f | wc -l) files"

# Themes
cp -r "$SRC_DIR/shared/themes/"* "$SHARE/themes/"
log "Themes: $(find "$SHARE/themes" -type f | wc -l) files"

# Notification Center (build + copy binary)
NOTIF_DIR="$SRC_DIR/shared/notif-center"
NOTIF_BIN="$NOTIF_DIR/target/release/notif-center"
if [[ -f "$NOTIF_DIR/Cargo.toml" ]]; then
    log "Building notif-center..."
    (cd "$NOTIF_DIR" && cargo build --release 2>&1 | tail -1)
    if [[ -f "$NOTIF_BIN" ]]; then
        cp "$NOTIF_BIN" "$SHARE/notif-center/"
        log "notif-center: binary copied"
    else
        log "notif-center: build FAILED"
    fi
else
    log "notif-center: source not found, skipping"
fi

# Keyboard Center (build + copy binary)
KC_DIR="$SRC_DIR/shared/kb-center"
KC_BIN="$KC_DIR/target/release/kb-center"
if [[ -f "$KC_DIR/Cargo.toml" ]]; then
    log "Building kb-center..."
    (cd "$KC_DIR" && cargo build --release 2>&1 | tail -1)
    if [[ -f "$KC_BIN" ]]; then
        cp "$KC_BIN" "$SHARE/kb-center/"
        log "kb-center: binary copied"
    else
        log "kb-center: build FAILED"
    fi
else
    log "kb-center: source not found, skipping"
fi

# disp-center display manager (Rust+Slint display settings)
DC_DIR="$SRC_DIR/shared/disp-center"
DC_BIN="$DC_DIR/target/release/disp-center"
if [[ -f "$DC_DIR/Cargo.toml" ]]; then
    mkdir -p "$SHARE/disp-center"
    log "Building disp-center..."
    (cd "$DC_DIR" && cargo build --release 2>&1 | tail -1)
    if [[ -f "$DC_BIN" ]]; then
        cp "$DC_BIN" "$SHARE/disp-center/"
        log "disp-center: binary copied"
    else
        log "disp-center: build FAILED"
    fi
else
    log "disp-center: source not found at $DC_DIR, skipping"
fi

# st-wl terminal (build from source, keep pinned VERSION from config.mk)
ST_DIR="$SRC_DIR/compositors/hyprland/st"
if [[ -f "$ST_DIR/st.c" ]]; then
    cur_ver=$(grep '^VERSION' "$ST_DIR/config.mk" | sed 's/.*= *//')

    log "Building st-wl $cur_ver..."
    (cd "$ST_DIR" && rm -f config.h && make clean && make -j"$(nproc)") 2>&1 | tail -1
    if [[ -f "$ST_DIR/st-wl" ]]; then
        cp "$ST_DIR/st-wl" "$SHARE/st/"
        log "st-wl $cur_ver: binary copied"
    else
        log "st-wl: build FAILED"
    fi
fi

# Copy the apply script itself
cp "$SCRIPT_DIR/dev-apply.sh" "$SHARE/dev-apply.sh"
chmod +x "$SHARE/dev-apply.sh"

log ""
log "Done! In the VM run:  ${YELLOW}sudo bash /mnt/dev-apply.sh${NC}"
