use crate::monitor::{Monitor, MonitorConfig};

/// Trait for compositor-specific display management.
/// Implement this for each compositor backend (Hyprland, DWM/xrandr, etc.).
pub trait DisplayBackend {
    /// Query all connected monitors and their current configuration.
    fn query_monitors(&self) -> Result<Vec<Monitor>, String>;

    /// Apply a set of monitor configurations live (without restarting the compositor).
    fn apply(&self, configs: &[MonitorConfig]) -> Result<(), String>;

    /// Persist the monitor configuration to disk so it survives reboot.
    fn persist(&self, configs: &[MonitorConfig]) -> Result<String, String>;

    /// Move workspace 1 (or the "default" workspace) to the given monitor,
    /// effectively making it the primary display.
    fn set_primary(&self, monitor_name: &str) -> Result<(), String>;

    /// Flash a large label on each physical monitor so the user can identify which is which.
    fn identify(&self, monitors: &[Monitor]) -> Result<(), String>;

    /// Human-readable name of this backend.
    fn name(&self) -> &'static str;
}

/// Detect the running compositor and return the appropriate backend.
pub fn detect_backend() -> Result<Box<dyn DisplayBackend>, String> {
    // Check for Hyprland first (most specific)
    if std::env::var("HYPRLAND_INSTANCE_SIGNATURE").is_ok() {
        return Ok(Box::new(crate::hyprland::HyprlandBackend::new()));
    }

    // Check for generic Wayland (future: sway, river, etc.)
    if std::env::var("WAYLAND_DISPLAY").is_ok() {
        return Err("Wayland compositor detected but not Hyprland. Only Hyprland is currently supported.".into());
    }

    // X11 fallback (future: xrandr backend for DWM, i3, etc.)
    if std::env::var("DISPLAY").is_ok() {
        return Err("X11 detected. Only Hyprland is currently supported. X11/xrandr backend coming soon.".into());
    }

    Err("No display server detected.".into())
}
