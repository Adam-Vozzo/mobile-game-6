# Touch Button Repositioning & Resizing — Design + Implementation Research

*Written iter 122 — 2026-05-17.*

CLAUDE.md requires: "Buttons must be repositionable and resizable." `touch_overlay.gd`
currently exposes positions as `@export` vars (editor-only). No runtime reposition UI
exists. This note designs and plans the implementation so it's ready whenever Gate 1
depth-pass work begins.

---

## What reference games do

### Genshin Impact (HoYoverse)
- Dedicated **Custom button layout** mode in Settings → Controls.
- Each button becomes draggable; long-press to enter drag state per button or a global
  "Customize" mode.
- **Resize**: fixed presets (Small / Medium / Large) per button type, not free-form pinch.
- Resets to default button in same screen.
- Persistence: saved to the HoYoverse account (cloud); local fallback on device.
- Takeaway: preset sizes are easier than pinch-to-resize; the "Customize" mode is a
  separate editing mode, not always-on.

### Honkai: Star Rail / Tower of Fantasy / Nikke
- Same HoYoverse / similar pattern: Customize mode, per-button drag + preset sizes.
- All show a semi-transparent editor overlay with a "Done" / "Reset" pair.
- Takeaway: a clean modal editing mode with explicit Done/Reset is the established pattern.

### Dadish 3D (the anti-pattern)
- Play Store reviews repeatedly request resizable/repositionable buttons.
- The game never shipped this feature.
- Takeaway: it *is* the differentiator CLAUDE.md identified — users notice and ask for it.

---

## What `touch_overlay.gd` currently has

- `@export var stick_center: Vector2` — virtual stick origin in viewport coords.
- `@export var jump_center: Vector2` — jump button centre.
- `@export var action_center: Vector2` — air-dash / secondary action button centre.
- `@export var button_radius: float` — jump button radius (pixels).
- Positions are loaded from the `.tscn` file; no runtime write path exists.

---

## Minimal viable implementation (Gate 1 path)

Two stages: **dev-menu sliders** (Gate 1, no persistence) → **configure mode** (Gate 3).

### Stage 1 — dev-menu position sliders (can implement in one iter)

Add a "Touch — Layout" section to the dev menu overlay:

```
Touch — Layout
  Stick X        [slider 0–1000 px]   default: stick_center.x
  Stick Y        [slider 0–800 px]    default: stick_center.y
  Jump X         [slider 0–1000 px]
  Jump Y         [slider 0–800 px]
  Button radius  [slider 40–120 px]
```

In `dev_menu_overlay.gd`:
- Wire to a new `touch_layout_param_changed(param: StringName, value: float)` signal
  in `dev_menu.gd`.
- In `touch_overlay.gd::_on_touch_layout_param_changed`: update the live position and
  call `_reposition_controls()` (already how stick/button moves when `@export` changes
  in editor).
- No persistence: positions survive only for the session. Sufficient for Gate 1 on-device
  tuning (the human feeds back numbers and we bake them into the `.tscn`).

### Stage 2 — configure mode (Gate 3 path)

A "Configure touch layout" button in the Settings menu enters an editing mode:

1. Game pauses (`get_tree().paused = true`, touch_overlay continues).
2. Each button shows a drag handle (ring gizmo drawn in `_draw()`).
3. Touch-and-drag on a handle repositions that button. Long-press drag.
4. Resize: second pair of handles (or a slide-out size picker).
5. "Done" → save to `user://input_layout.cfg` via `ConfigFile`; resume.
6. "Reset" → reload defaults from `input_layout_default.cfg` (read-only res://).

#### Persistence pattern (Godot 4 `ConfigFile`)

```gdscript
const _LAYOUT_PATH := "user://input_layout.cfg"

func save_layout() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("layout", "stick_center", stick_center)
    cfg.set_value("layout", "jump_center", jump_center)
    cfg.set_value("layout", "button_radius", button_radius)
    cfg.save(_LAYOUT_PATH)

func load_layout() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(_LAYOUT_PATH) != OK:
        return  # use @export defaults from .tscn
    stick_center  = cfg.get_value("layout", "stick_center",  stick_center)
    jump_center   = cfg.get_value("layout", "jump_center",   jump_center)
    button_radius = cfg.get_value("layout", "button_radius", button_radius)
    _reposition_controls()
```

Call `load_layout()` at the end of `_ready()`. This is backwards-compatible: the
.cfg file doesn't exist on first install, so defaults apply.

---

## Implementation order

1. **(Gate 1)** Dev-menu sliders for stick_center, jump_center, button_radius. Exposes
   the values the human adjusts during the first on-device session.  
2. **(Gate 1)** Feed back the calibrated numbers into `touch_overlay.tscn` `@export`
   defaults once the human approves them.  
3. **(Gate 3)** Configure mode with drag-handles + `ConfigFile` persistence.  
4. **(Gate 3)** Size presets (S/M/L) rather than raw radius slider for the shipping build.

---

## Implications for Void

1. **Gate 1 unblocked today**: the dev-menu slider approach (Stage 1) is implementable
   in one iter without any human approval needed.
2. **No new architectural surface**: `touch_layout_param_changed` is one more signal in
   `dev_menu.gd` — same pattern as `controller_param_changed`, `camera_param_changed`, etc.
3. **ConfigFile is the right persistence layer**: it's human-readable, survives APK
   reinstall (stored in app's private data), and survives engine upgrades. No custom
   serialisation needed.
4. **Drag handle gizmo is the hardest part**: `Control._draw()` for handles in configure
   mode, plus touch hit-testing to detect which handle is being dragged. Budget half a day.
5. **Thumb-reach sanity check required**: when adding Stage 1 sliders, verify stick centre
   sits in the left-thumb zone (x ≤ 400, y ≥ 400 in 1920×1080 landscape) and jump button
   in the right-thumb zone (x ≥ 1520, y ≥ 400). These are the safe-zone boundaries from
   `mobile_touch_ux.md`.
6. **Don't add "action centre" slider until air-dash verdict resolves**: the tertiary
   button layout depends on whether the air dash stays or goes (human-blocked item,
   README "Open questions #1").
