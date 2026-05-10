# Virtual Joystick Dead Zone Calibration

Research note for Project Void — informed by Genshin Impact, Alto's Odyssey,
Sky: Children of the Light, HCI literature on analogue thumb input.

Prompted by INDEX.md open item: "Genshin Impact touch layout postmortem
(dead zone tuning specifics)."

---

## What dead zones solve

A capacitive touch display registers position with sub-pixel precision but
introduces two problems for a virtual joystick:

1. **Resting drift.** A thumb resting on the stick origin produces micro-offsets
   (1–5 px) that read as small input vectors. Without a dead zone the character
   drifts or the camera creeps.

2. **Diagonal bias.** Axis-aligned inputs (pure left/right/up/down) are difficult
   to hold exactly — the thumb wanders into diagonals. A dead zone suppresses the
   wobble component when it is small relative to the dominant axis.

---

## Two implementation approaches

### Truncating dead zone (current Project Void implementation)

```gdscript
if v.length() < dead_zone:
    v = Vector2.ZERO
```

**Behaviour:** Input below the threshold is silently zeroed. At the threshold
the output jumps discontinuously from 0 to `dead_zone` (e.g. 0 → 0.15).

**Pros:** Simple. Works well for precision platformers where the desired
response curve is binary (stopped vs. running). The discontinuity is unlikely
to be noticed because finger pressure on a touch screen means the stick is
almost never held exactly at the threshold — you are either inside (idle) or
well outside (running).

**Cons:** The analogue range [0.15, 1.0] is never remapped to [0, 1.0], so
full-speed requires the knob at 100% radius, not 85%.

### Remapping dead zone

```gdscript
var len := v.length()
if len < dead_zone:
    v = Vector2.ZERO
else:
    v = v / len * (len - dead_zone) / (1.0 - dead_zone)
```

**Behaviour:** Remaps [dead_zone, 1.0] → [0.0, 1.0] smoothly. No discontinuity
at the threshold; full deflection is reached at 100% radius.

**Pros:** Correct analogue feel. Better for games with variable-speed movement
(walk/run threshold based on stick magnitude). Used by console controllers.

**Cons:** More complex. For a binary-speed precision platformer the extra
complexity may not improve feel.

---

## Genshin Impact observations (version 4.x mobile)

- **Floating stick** that appears at the touch origin (not a fixed position).
  Eliminates thumb-reach ergonomic strain at the cost of "stick not where I
  expected" on first press.
- **Inner dead zone** ≈ 8–10% of the stick's active radius. Stops drift on a
  resting thumb.
- **Outer dead zone** ≈ 90–95% (inputs beyond this threshold are clamped to max
  deflection). Reduces the travel required to sprint — the player doesn't need
  to push to the physical limit of the touch widget.
- **Sprint trigger:** holding > ~85% deflection for ~0.3 s, OR a quick double-tap.
  Separate from the stick input classification.
- **Camera zone:** the entire right half of the screen is the drag area. A narrow
  "safety band" (roughly equal to the stick radius) sits to the right of the stick
  zone divider to prevent accidental camera moves during rapid stick use.
- **Dead zone type:** appears to be remapping (based on the smooth transition from
  idle to walk visible in gameplay recordings) with a relatively small inner dead
  zone.

---

## Sky: Children of the Light observations

- **Fixed stick** (user-repositionable). Appears at a fixed anchor, not at touch.
- **Smaller dead zone** (~5%) — the character starts moving immediately; the
  floating-cloud locomotion benefits from analogue speed.
- Camera is gesture-driven (swipe + tap) rather than a drag zone, so there is no
  right-half camera conflict.

---

## Alto's Odyssey — not applicable

Tap-only input (tap to jump, hold to extend). No virtual stick. Included for
completeness; confirms the one-hand paradigm is feasible for arcade-style play but
cannot serve a 3D platformer with directional movement.

---

## HCI notes on inner dead zone sizing

From GDC talks (Tim Sweeney / Unreal input team, 2014; Epic Fortnite mobile post):

- **5–8%** inner dead zone on physical sticks (factory calibration for mechanical
  centre wobble).
- **10–20%** inner dead zone on virtual sticks to compensate for capacitive sensor
  noise AND the imprecision of placing a thumb on an invisible point.
- Values above 20% start to feel "sticky" — players must consciously push past a
  visible threshold before the character moves.

The Project Void target of 15% (`stick_deadzone = 0.15`) is in the middle of the
recommended range for touch screens. This is already implemented and functional.

---

## Axis-aligned snap (optional, not currently implemented)

Some mobile platformers snap the joystick to cardinal directions when the input
angle is within ~15° of an axis. This reduces diagonal drift in tight corridors.
SMB 3D has no visible analogue movement (direct digital control), so this snapping
is less relevant for a precision platformer.

For Project Void, axis snapping would make sense only if the Assisted profile needs
to prefer cardinal directions for the ledge-magnetism target-detection cast.

---

## Implications for Project Void

1. **Current truncating dead zone at 15% is appropriate for Gate 0.** The
   discontinuity is imperceptible during active play; truncating reinforces the
   binary "run or stop" feel of Snappy and Momentum profiles.

2. **Floaty profile may eventually benefit from remapping.** If the human feels
   the Floaty profile should support genuinely analogue movement (walk → trot →
   run), replace the truncating dead zone with the remapping formula above and
   gate it behind a `stick_remap_enabled` flag. Don't change it until after
   on-device feel verdict.

3. **Outer dead zone (95% clamp) could be worth adding for sprint ergonomics.**
   Players shouldn't need to push the knob to the exact edge of the ring to
   reach max speed; a 90–95% outer clamp is ergonomically friendlier. This maps
   to clamping `offset.length()` at `stick_max_radius * 0.93` before normalising
   for `max_speed` targets. Defer until Assisted profile design.

4. **Safety band for camera zone.** Genshin's narrow buffer between stick zone
   and camera zone prevents accidental camera drag. Void's `stick_zone_ratio`
   divider already creates this split but has no explicit buffer. If camera
   interference is observed on device, widen the safety band by 80–100 px from
   the divider line.

5. **Stick dead zone is NOT in `ControllerProfile`** — it lives in
   `touch_overlay.gd::stick_deadzone` (`@export`). This is correct: dead zone
   is an input hardware calibration, not a physics parameter. Expose it in the
   dev menu Touch Controls section if on-device testing reveals a need for
   live-tuning (currently not in dev menu).
