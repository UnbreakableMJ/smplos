# disp-center

A simple display management GUI for Linux compositors, built with Rust + Slint.

## Features

- Show all connected monitors as draggable rectangles
- Drag to rearrange monitor positions (snaps to edges)
- Change resolution and refresh rate per monitor
- Adjust display scale
- Set primary monitor
- Apply changes live + persist to config
- Revert to original layout

## Building

```bash
cargo build --release
```

## Running

```bash
cargo run
```

## Architecture

```
src/
  main.rs          # Slint <-> Rust wiring, callbacks, state management
  monitor.rs       # Data model, edge-snap algorithm, canvas scaling
  backend.rs       # DisplayBackend trait + compositor auto-detection
  hyprland.rs      # Hyprland backend (hyprctl IPC)
ui/
  app.slint        # Slint UI layout
```

The `DisplayBackend` trait abstracts compositor-specific logic. Adding a new
compositor means implementing one file with 4 methods (query, apply, persist,
set_primary).

## TODO

### X11 / xrandr backend
- [ ] Create `src/xrandr.rs` implementing `DisplayBackend`
- [ ] Parse `xrandr --query` output to get monitors, resolutions, positions
- [ ] Apply changes via `xrandr --output NAME --mode WxH --rate HZ --pos XxY --scale S`
- [ ] Persist by writing xrandr commands to `~/.xprofile` or `~/.screenlayout/`
- [ ] Set primary via `xrandr --output NAME --primary`
- [ ] Wire up detection in `backend.rs` (the `DISPLAY` env var branch is already stubbed)
- [ ] Test with DWM, i3, and other X11 window managers

### Future improvements
- [ ] Monitor hotplug detection (Hyprland socket2 events / udev for X11)
- [ ] Transform / rotation dropdown
- [ ] Enable / disable toggle per monitor
- [ ] Duplicate / extend / mirror mode toggle
- [ ] Night light / color temperature (defer to hyprsunset / redshift)
