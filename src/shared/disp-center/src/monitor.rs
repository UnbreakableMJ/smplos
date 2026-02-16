use serde::Deserialize;

/// A single available display mode (resolution + refresh rate).
#[derive(Debug, Clone, Deserialize)]
pub struct MonitorMode {
    pub width: i32,
    pub height: i32,
    #[serde(rename = "refreshRate")]
    pub refresh_rate: f64,
}

impl MonitorMode {
    pub fn label(&self) -> String {
        format!("{}x{}@{:.0}Hz", self.width, self.height, self.refresh_rate)
    }
}

/// Represents one physical display as reported by the compositor.
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct Monitor {
    pub id: i32,
    pub name: String,        // e.g. "DP-1", "HDMI-A-1", "eDP-1"
    pub description: String, // e.g. "LG Electronics 27GP950"
    pub width: i32,          // current active resolution
    pub height: i32,
    pub refresh_rate: f64,
    pub x: i32, // position in the global compositor space
    pub y: i32,
    pub scale: f64,
    pub transform: i32,  // 0=normal, 1=90, 2=180, 3=270
    pub enabled: bool,
    pub dpms: bool,
    pub focused: bool,
    pub available_modes: Vec<MonitorMode>,
}

/// Configuration to apply to a single monitor.
#[derive(Debug, Clone)]
pub struct MonitorConfig {
    pub name: String,
    pub width: i32,
    pub height: i32,
    pub refresh_rate: f64,
    pub x: i32,
    pub y: i32,
    pub scale: f64,
    pub enabled: bool,
}

impl MonitorConfig {
    /// Format as Hyprland monitor line: `monitor = NAME, WxH@HZ, XxY, SCALE`
    pub fn to_hyprland_line(&self) -> String {
        if !self.enabled {
            return format!("monitor = {}, disable", self.name);
        }
        format!(
            "monitor = {}, {}x{}@{:.2}, {}x{}, {:.2}",
            self.name, self.width, self.height, self.refresh_rate, self.x, self.y, self.scale,
        )
    }
}

/// Edge-snapping: given a monitor being dragged, snap it to the nearest
/// edge of another monitor. Returns the snapped (x, y) position.
/// `canvas_scale` converts real pixels → canvas pixels.
pub fn snap_to_nearest_edge(
    dragged_x: i32,
    dragged_y: i32,
    dragged_w: i32,
    dragged_h: i32,
    others: &[(i32, i32, i32, i32)], // (x, y, w, h) of other monitors
    threshold: i32,
) -> (i32, i32) {
    let mut best_x = dragged_x;
    let mut best_y = dragged_y;
    let mut best_dist = i32::MAX;

    for &(ox, oy, ow, oh) in others {
        // Candidate snap positions — dragged monitor edge → other monitor edge
        let snap_candidates: [(i32, i32); 8] = [
            // Right edge of dragged → left edge of other
            (ox - dragged_w, dragged_y),
            // Left edge of dragged → right edge of other
            (ox + ow, dragged_y),
            // Bottom edge of dragged → top edge of other
            (dragged_x, oy - dragged_h),
            // Top edge of dragged → bottom edge of other
            (dragged_x, oy + oh),
            // Align tops
            (dragged_x, oy),
            // Align bottoms
            (dragged_x, oy + oh - dragged_h),
            // Align lefts
            (ox, dragged_y),
            // Align rights
            (ox + ow - dragged_w, dragged_y),
        ];

        for (cx, cy) in snap_candidates {
            let dx = (cx - dragged_x).abs();
            let dy = (cy - dragged_y).abs();
            let dist = dx + dy;
            if dist < best_dist && dist < threshold {
                best_dist = dist;
                best_x = cx;
                best_y = cy;
            }
        }
    }

    (best_x, best_y)
}

/// Calculate a uniform scale factor so all monitors fit inside the given canvas dimensions.
pub fn canvas_scale_factor(monitors: &[Monitor], canvas_w: f64, canvas_h: f64) -> f64 {
    if monitors.is_empty() {
        return 1.0;
    }

    let mut min_x = i32::MAX;
    let mut min_y = i32::MAX;
    let mut max_x = i32::MIN;
    let mut max_y = i32::MIN;

    for m in monitors {
        min_x = min_x.min(m.x);
        min_y = min_y.min(m.y);
        max_x = max_x.max(m.x + m.width);
        max_y = max_y.max(m.y + m.height);
    }

    let total_w = (max_x - min_x) as f64;
    let total_h = (max_y - min_y) as f64;

    if total_w <= 0.0 || total_h <= 0.0 {
        return 1.0;
    }

    let margin = 40.0; // px padding around the canvas
    let scale_x = (canvas_w - margin * 2.0) / total_w;
    let scale_y = (canvas_h - margin * 2.0) / total_h;

    scale_x.min(scale_y).min(0.25) // cap at 1:4 so tiny monitors don't blow up
}
