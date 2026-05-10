# Air Dash — Gate 1 Mechanic Candidate

## Context

The SMB 3D research note (`smb3d.md`) identified **depth perception** as "the hardest new problem
in 2D→3D precision platforming." SMB 3D's full spatial aid suite — blob shadow, ground circle,
45° geometry angles, 8-directional stick constraint — *still* drew depth-perception criticism
in reviews. The blob shadow (implemented in iter 28) addresses the *read* problem (where will I
land?). The air dash addresses the *recovery* problem: **what do I do when I misjudge the depth
and my jump is already committed?**

SMB 3D's air dash is described by developers as "one-shot depth-error correction" — a single
horizontal burst that ignores gravity briefly, recharges on landing, and exists specifically to
let skilled players recover from depth misjudgements without dying. On mobile, a swipe maps
naturally to this mechanic.

This note designs the air dash for Void and sketches the Godot 4 implementation.

---

## What the air dash should do

- Brief horizontal burst (~0.15–0.25 s) in any horizontal direction.
- During the dash: gravity suspended (or reduced ~80%). No vertical acceleration.
- After the dash: normal physics resume immediately.
- Single charge per airborne phase. Recharges on landing (`is_on_floor()` → `true`).
- Does **not** stack: double-dash is not a mechanic (charges = 1).
- Cannot be triggered while grounded (it is an *airborne* tool).
- Dash direction: driven by the input vector at the moment of trigger. If input is zero,
  dash in the current movement direction (forward dash as fallback).
- Speed: fast enough to cover the typical depth-error gap in SMB 3D (~2–3 m) in one dash.
  Estimated target: 8–12 m/s for 0.2 s = 1.6–2.4 m horizontal. Start conservative.

---

## Input mapping

### Option A — Right-side horizontal swipe (preferred)

The right half of the screen is the jump zone and camera drag zone. A *quick* horizontal swipe
(velocity threshold, not duration) on the right half triggers the dash in the swipe direction.

**Pros**: directional, intuitive, maps the metaphor (swipe = burst). Naturally distinct from
a camera drag (which is slower). No new UI elements needed.

**Cons**: requires gesture disambiguation in `touch_overlay.gd`. Short vs. long right-side
touch sequences would need different handling (quick swipe = dash; slow drag = camera).

**Gesture disambiguation rule** (proposed): if a right-zone touch travels >40 px in <200 ms,
classify it as a dash gesture; otherwise continue as camera drag. The thresholds belong in
`touch_overlay.gd` as `@export` tunables.

### Option B — Double-tap jump button

Second tap of the jump button within a short window (~150 ms) while airborne triggers a
forward dash.

**Pros**: no gesture disambiguation. One button area. Simple to implement.

**Cons**: only forward; no directional choice. Double-tap window conflicts with variable jump
height (short tap = cut jump; double tap = dash is tricky to distinguish). Higher error rate
on fast inputs.

**Recommendation**: start with Option A. If touch-disambiguation proves unreliable on device,
fall back to Option B. Both could coexist with a Settings toggle ("Dash input: swipe / tap").

### Keyboard (editor testing)

Bind to `shift` or a configurable action `air_dash`. `Input.is_action_just_pressed(&"air_dash")`
as the keyboard path, with the touch path going through `TouchInput`.

---

## ControllerProfile integration

Add to `controller_profile.gd`:

```gdscript
@export_category("Air Dash")
## Horizontal speed during the air dash burst, m/s. 0 = dash disabled.
@export_range(0.0, 20.0, 0.5) var air_dash_speed: float = 0.0
## How long the dash burst lasts, seconds.
@export_range(0.05, 0.5, 0.01) var air_dash_duration: float = 0.18
## Gravity scale during the dash (0 = fully suspended, 1 = normal).
## 0.15 keeps a slight arc so the dash doesn't feel floaty.
@export_range(0.0, 1.0, 0.05) var air_dash_gravity_scale: float = 0.15
```

Default `air_dash_speed = 0.0` means no dash (backwards-compatible; all existing profiles
are unaffected unless `air_dash_speed` is set non-zero).

Profile tuning targets:

| Profile | `air_dash_speed` | `air_dash_duration` | Notes |
|---------|---------|---------|-------|
| Snappy | 10.0 | 0.15 s | Tight burst; fast recovery |
| Floaty | 8.0 | 0.22 s | Slightly longer; fits hang-time feel |
| Momentum | 12.0 | 0.15 s | Fast, pairs with momentum ramp |
| Assisted | 9.0 | 0.20 s | Conservative; Assisted is forgiving overall |

These are starting values for device tuning. The human should feel each on device.

---

## player.gd integration sketch

New state vars (add to `player.gd`):

```gdscript
var _dash_charges: int = 0
var _dash_timer: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
```

Restore charge on landing:

```gdscript
# In _tick_timers, after: var just_landed := on_floor and not _was_on_floor_last_frame
if just_landed:
    _dash_charges = 1  # recharge on touch-down
```

Trigger from input (called when dash gesture is recognised):

```gdscript
func try_air_dash(dir: Vector3) -> void:
    if _is_rebooting or _dash_charges <= 0 or is_on_floor():
        return
    if profile.air_dash_speed <= 0.0:
        return
    _dash_charges -= 1
    _dash_timer = profile.air_dash_duration
    _dash_dir = dir if dir.length() > 0.01 else Vector3(velocity.x, 0, velocity.z).normalized()
    velocity.x = _dash_dir.x * profile.air_dash_speed
    velocity.z = _dash_dir.z * profile.air_dash_speed
    velocity.y = 0.0  # kill Y on dash start
```

In `_apply_gravity`:

```gdscript
# Existing gravity bands
if _dash_timer > 0.0:
    _dash_timer -= delta
    # During dash: gravity scaled down
    var g := ... (existing band selection) ...
    velocity.y = maxf(-profile.terminal_velocity,
        velocity.y - g * profile.air_dash_gravity_scale * delta)
    # Override horizontal to hold dash direction
    velocity.x = _dash_dir.x * profile.air_dash_speed
    velocity.z = _dash_dir.z * profile.air_dash_speed
    return
# ... rest of existing gravity logic
```

*(Actual implementation will need to slot into the extracted sub-routines from iter 10.
`_apply_gravity` handles gravity; `_apply_horizontal` handles XZ. The dash needs to
override both for its duration. Likely cleanest as a `_apply_dash` method that runs
before `_apply_horizontal` and `_apply_gravity`, setting a flag that those methods check.)*

---

## TouchInput integration sketch

In `touch_overlay.gd`, inside the right-zone touch handling:

```gdscript
# New state vars:
var _right_dash_start: Vector2 = Vector2.ZERO
var _right_dash_start_time: float = 0.0
const _DASH_PX_THRESHOLD: float = 40.0     # export-tuneable
const _DASH_TIME_THRESHOLD: float = 0.20    # seconds; export-tuneable

func _on_right_zone_touch_moved(event: InputEventScreenTouch, pos: Vector2) -> void:
    var delta_px := pos - _right_dash_start
    var elapsed := Time.get_ticks_msec() / 1000.0 - _right_dash_start_time
    if delta_px.length() > _DASH_PX_THRESHOLD and elapsed < _DASH_TIME_THRESHOLD:
        # Classify as dash, not camera drag
        var dir_3d := Vector3(delta_px.normalized().x, 0.0, delta_px.normalized().y)
        # rotate by camera yaw so the swipe direction is camera-relative
        dir_3d = Basis(Vector3.UP, _camera_yaw) * dir_3d
        TouchInput.emit_signal("air_dash_triggered", dir_3d)
        _right_dash_start = pos  # reset so no double-trigger
    else:
        _handle_camera_drag(event)  # existing camera drag path
```

Add `air_dash_triggered(dir: Vector3)` signal to `touch_input.gd`. Connect in `player.gd`
similarly to `jump_pressed`.

---

## Juice integration

On dash trigger:
- `squash_stretch`: brief X/Z stretch in dash direction (`_visual.scale = Vector3(1.3, 0.7, 1.3)` aligned to dir).
- `motion_trails`: emit a short afterimage trail (1–2 frames) at high alpha.
- `sound_layers`: short speed-burst SFX (servo at high pitch for 0.15 s).

All gated behind their respective `DevMenu.is_juice_on(...)` keys. No new juice keys needed
(reuses existing ones).

Dev menu tuning (add to Controller section after sticky-landing sliders):
- Air dash speed (0–20 m/s)
- Air dash duration (0.05–0.5 s)
- Air dash gravity scale (0–1)

These expose the three new ControllerProfile params live, same pattern as all other profile sliders.

---

## Universal vs. profile-exclusive

### Arguments for universal (all profiles, default non-zero speed)

- Depth-error recovery benefits every player on mobile, regardless of profile.
- Avoids teaching bad habits: a player who switches from Assisted to Snappy still has the
  recovery tool, rather than suddenly losing an expected affordance.
- Simpler mental model: "the dash is a thing you can do."

### Arguments for profile-exclusive (only Assisted, speed=0 on others)

- Keeps Snappy feeling tight and SMB-honest. SMB 3D (Snappy's reference) has no air dash.
- Preserves the design intent of "Assisted is mobile-first, others are console-first."
- The human can always turn it on per profile via the dev menu during device testing.

**Recommendation**: implement with `air_dash_speed = 0` on all profiles (disabled by default),
then let the human tune each profile on device. Start by enabling on Assisted only. If Snappy
and Floaty feel better with it, enable there too. This is exactly the right question for
the device-feel session.

---

## Implementation order within Gate 1

Implement **after** ghost trails and **before** the first level's geometry is finalized, so
the level can be tuned to offer depth-perception challenges that the dash is the intended
response to.

Rough order:
1. Add `air_dash_speed/duration/gravity_scale` to `ControllerProfile`.
2. Add state vars + `try_air_dash` to `player.gd`.
3. Wire keyboard trigger (no touch yet — test in editor).
4. Wire dev menu sliders for the three new params.
5. Add touch gesture to `touch_overlay.gd` + `TouchInput` signal.
6. Add juice hooks.
7. On device: tune per profile.

Estimated implementation: ~1.5–2 hours across two sub-iterations (GDScript + touch) — fits
as a primary task once the human opens Godot and confirms the project builds.

---

## Implications for Void

1. **Do not gate behind Assisted.** Test universal from the start; the mobile platform
   needs this recovery tool more than the SMB-feel purity argument resists it.
2. **Swipe-as-input is the right mobile UX.** Option A gesture disambiguation belongs in
   `touch_overlay.gd` as tunables before Gate 1 ships.
3. **The level concepts depend on this.** "Spine" Beat 3 (alternate exterior route) and
   "Threshold" Beat 3 (long industrial gaps) are both designed assuming depth-error recovery
   exists. Without a dash, both sections need simpler geometry or wider platforms.
4. **Blob shadow + air dash = the full depth-perception aid suite.** Together they cover the
   two complementary problems: orientation (shadow) and recovery (dash). This is Void's
   direct answer to the criticism SMB 3D drew.
5. **Charges = 1 is the correct starting point.** Multiple charges would enable flight; one
   charge forces the player to commit and land. Revisit only if device testing reveals
   players spending more time dead than dashing.
6. **The `_dash_timer` override of horizontal velocity conflicts with `_apply_horizontal`'s
   `move_toward` logic.** The implementation must either skip `_apply_horizontal` during the
   dash or clamp `move_toward` to the dash velocity. A `_is_dashing: bool` flag checked at
   the top of `_apply_horizontal` is cleaner than modifying `move_toward` parameters.
