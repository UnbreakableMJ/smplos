# smplOS

A minimal Arch Linux distribution designed around simplicity and cross-compositor support.

## Architecture

smplOS separates shared infrastructure from compositor-specific configuration. The goal is maximum code reuse -- compositors are a thin layer on top of a shared foundation.

```
src/
  shared/              Everything here works on ALL compositors
    bin/               User-facing scripts (installed to /usr/local/bin/)
    eww/               EWW bar and widgets (GTK3 -- works on X11 + Wayland)
    configs/smplos/    Cross-compositor configs (bindings.conf, branding)
    themes/            14 themes with templates for all apps
    installer/         OS installer
    settings-panel/    System settings
  compositors/
    hyprland/          Hyprland-specific config (hypr/, st-wl terminal)
    dwm/               DWM-specific config (st terminal, future)
  builder/             ISO build pipeline
  iso/                 ISO resources (boot entries, offline repo)
release/               VM testing tools (dev-push, test-iso, QEMU scripts)
```

## Key Design Decisions

- **Cross-compositor first.** Every feature must work across Hyprland (Wayland) and DWM (X11). Compositor-specific code stays in `src/compositors/<name>/`.
- **EWW is the UI layer.** Bar, widgets, dialogs -- all EWW. It runs on both GTK3/X11 and GTK3/Wayland.
- **One theme system.** `theme-set` applies colors to EWW, terminals, btop, notifications, compositor borders, lock screen, and neovim. 14 built-in themes.
- **bindings.conf is the single source of truth** for keybindings across all compositors.
- **Minimal packages.** One terminal, one launcher, one bar. No redundant tools.

## Compositors

| Compositor | Display Server | Terminal | Status |
|------------|---------------|----------|--------|
| Hyprland   | Wayland       | st-wl    | Active |
| DWM        | X11           | st       | Planned |

## Building

### ISO

```bash
cd src && ./build-iso.sh
```

This produces a bootable Arch Linux ISO with smplOS pre-configured. Takes ~15 minutes.

### Development Iteration

For config/script changes, avoid full ISO rebuilds:

```bash
# Host: push changes to VM shared folder
cd release && ./dev-push.sh eww    # or: bin, hypr, themes, all

# VM: apply changes to the live system
sudo bash /mnt/dev-apply.sh
```

### VM Testing

```bash
cd release && ./test-iso.sh
```

## Themes

14 built-in themes, each providing colors for all UI components:

Catppuccin Mocha, Catppuccin Latte, Dracula, Gruvbox Dark, Gruvbox Light, Nord, One Dark, Rose Pine, Rose Pine Dawn, Solarized Dark, Solarized Light, Sweet, Tokyo Night, Tokyo Night Light.

## License

MIT License. See [LICENSE](LICENSE) for details.

Terminal emulators (st, st-wl) are under their own licenses -- see their respective directories.
