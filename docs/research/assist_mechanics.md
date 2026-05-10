# Assist Mechanics — Implementation Research

Research for the **Assisted** controller profile (PLAN P0 item 4). Covers the
three assist types identified in `mobile_touch_ux.md` plus the `character_controllers.md`
ledge-magnetism recommendation, with concrete Godot 4 implementation approaches for
`CharacterBody3D`.

This note bridges the design targets already documented to the code needed in
`player.gd`. No new design choices here — implementation paths only.

---

## Design targets recap (from prior research)

From `mobile_touch_ux.md`:

| Assist | Target parameter | Threshold |
|---|---|---|
| Ledge magnetism | ≤ 1.5 m/s impulse | within 0.2 m of edge |
| Arc assist | ≤ 15% of `jump_velocity` | at arc peak |
| Sticky landing | 20% speed reduction | for 2 frames on narrow platforms |
| Edge-snap | auto-snap to platform edge | on landing overshoot |

From `character_controllers.md`:
> "Assisted profile should prioritise ledge magnetism (~0.15 m snap radius) over
> mid-air steering."

The note recommends **ledge magnetism at jump time** first, **arc assist** second
(more complex, higher jank risk), and **sticky landing** third (simplest).

---

## 1 — Ledge Magnetism

**What it does**: When the player's foot path at peak jump would graze a platform
edge, apply a small lateral impulse (< 1.5 m/s) to nudge the player toward the
platform centre. Invisible if subtle; jarring if over-applied.

**Detection approach in Godot 4**

Use `PhysicsDirectSpaceState3D.intersect_shape` with a small sphere shape cast
downward just outside the player capsule's horizontal radius.

Concrete pattern (fire at jump time only, not every frame):

```gdscript
# In player.gd::_try_jump() — after velocity.y = profile.jump_velocity
func _attract_to_ledge() -> void:
    var space := get_world_3d().direct_space_state
    var query := PhysicsShapeQueryParameters3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = profile.ledge_magnet_radius   # e.g. 0.20 m
    query.shape = sphere
    query.collision_mask = 1   # world geometry only, not player
    query.exclude = [get_rid()]
    # cast downward 0.3 m below foot, offset sideways by capsule radius + 0.05
    var foot := global_position + Vector3(0, -0.45, 0)
    for x_off: float in [-0.35, 0.35]:
        query.transform = Transform3D(Basis.IDENTITY, foot + Vector3(x_off, 0, 0))
        var hits := space.intersect_shape(query, 1)
        if hits.size() > 0:
            var edge_point: Vector3 = hits[0]["point"]
            var pull := (edge_point - foot)
            pull.y = 0.0
            if pull.length() > 1e-3:
                var impulse := pull.normalized() * minf(
                    pull.length() / profile.ledge_magnet_radius,
                    1.0
                ) * profile.ledge_magnet_strength
                velocity += impulse
            break   # one edge at a time
```

**Parameters needed in `ControllerProfile`**:
- `ledge_magnet_radius: float = 0.0` — detect range (0 = off). Assisted default: `0.20`.
- `ledge_magnet_strength: float = 0.0` — max horizontal impulse m/s. Assisted default: `1.0`.

**Tuning notes**:
- Fire only at `_try_jump()` (not every frame) — prevents the magnet from
  dragging the player mid-air.
- Cast perpendicular to movement direction only, not behind — avoids pulling
  toward edges the player is intentionally leaving.
- The cast offset (capsule_radius + small gap) should match the capsule's
  actual collider radius. Stray capsule: r ≈ 0.28 m.
- Disable during coyote window (the player has already left the platform edge).

---

## 2 — Arc Assist (in-air steering toward platforms)

**What it does**: While airborne, if a platform lies within a small angular cone
ahead of the predicted trajectory, apply a tiny horizontal velocity correction to
steer the player toward it. Budget: ≤ 15% of `jump_velocity`.

**Why it's riskier than ledge magnetism**: The assist runs every physics frame
during the arc, compounding. It can fight the player's intentional air control.
Gate the strength heavily and apply exponential falloff near the correction limit.

**Detection approach**

Simulate the parabolic arc 15–20 frames ahead using current `velocity` + the
applicable gravity band. At each simulated step, ShapeCast downward from the
predicted position. If a hit is found:
1. Compute the lateral offset between the predicted landing point and the
   platform surface centre.
2. If `|offset| < arc_assist_max` (e.g. 0.4 m), apply a fraction of the
   correction impulse per frame.

```gdscript
# Fire in _physics_process while airborne (not on_floor).
func _apply_arc_assist(delta: float) -> void:
    if profile.arc_assist_max <= 0.0:
        return
    var sim_pos := global_position
    var sim_vel := velocity
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.new()
    query.exclude = [get_rid()]
    query.collision_mask = 1
    for _step in 20:
        sim_vel.y = maxf(-profile.terminal_velocity,
            sim_vel.y - profile.gravity_after_apex * delta)
        sim_pos += sim_vel * delta
        query.from = sim_pos
        query.to = sim_pos + Vector3(0, -0.5, 0)
        var hit := space.intersect_ray(query)
        if hit.is_empty():
            continue
        var land_pt: Vector3 = hit["position"]
        var offset := land_pt - sim_pos
        offset.y = 0.0
        if offset.length() < profile.arc_assist_max:
            var correction := offset.normalized() * profile.arc_assist_max * 0.05
            velocity += correction.limit_length(
                profile.jump_velocity * 0.15 * delta)
        break
```

**Parameters needed in `ControllerProfile`**:
- `arc_assist_max: float = 0.0` — max correction magnitude m/s (0 = off). Assisted default: `0.4`.

**Tuning notes**:
- The 0.05 factor and 15% cap mean the assist contributes at most
  `0.4 × 0.05 = 0.02 m/s per frame`. Over 30 frames that's 0.6 m — enough to
  land a platform 0.4 m away without feeling steered.
- Only enable on the **Assisted** profile. Not in Snappy/Floaty/Momentum.
- Must not trigger while the player is on the ground or during the coyote window
  (first 80–100 ms after leaving a platform).
- Consider clamping total accumulated correction to ≤ 1.0 m over the arc's
  lifetime to prevent runaway drift.

---

## 3 — Sticky Landing

**What it does**: On the frame the player lands (transitions airborne → on_floor),
multiply horizontal speed by `(1 - sticky_factor)` for `sticky_frames` frames.
Prevents sliding off the far edge of a narrow platform immediately after landing.

This is the simplest of the three assists and has the fewest failure modes.

**Implementation in `player.gd`**

Track a sticky countdown:

```gdscript
var _sticky_frames_remaining: int = 0
var _was_on_floor_last_frame: bool = false

# In _physics_process, before _apply_horizontal:
var on_floor := is_on_floor()
if on_floor and not _was_on_floor_last_frame:
    _sticky_frames_remaining = profile.landing_sticky_frames
_was_on_floor_last_frame = on_floor

# In _apply_horizontal, after computing new_h:
if _sticky_frames_remaining > 0 and on_floor:
    new_h *= (1.0 - profile.landing_sticky_factor)
    _sticky_frames_remaining -= 1
```

**Parameters needed in `ControllerProfile`**:
- `landing_sticky_frames: int = 0` — frames to apply reduction (0 = off). Assisted: `2`.
- `landing_sticky_factor: float = 0.0` — fraction to reduce speed (0–1). Assisted: `0.20`.

**Tuning notes**:
- 2 frames at 60 fps = 33 ms. Enough to prevent a slide-off; imperceptible as
  a "slowdown."
- The Stray's capsule radius is 0.28 m. A "narrow platform" in PLAN.md terms is
  a 1×0.5×1 platform (depth 1 m). At Snappy max_speed ≈ 7 m/s, 33 ms of 20%
  reduction saves ≈ 0.046 m of slide — just enough for the narrow-ledge precision
  feel documented in character_controllers.md.
- Only matters on platforms narrower than ~2 m (wider platforms are self-correcting).

---

## 4 — Edge-Snap on Landing

**What it does**: If the player's foot position would land just off the edge of a
platform (within 0.15 m), snap the horizontal position to keep the player on the
platform. Distinguished from sticky landing (speed) — this is a position correction.

**Implementation approach**

Most complex of the four. In `move_and_slide()`, after the slide resolves, if
`is_on_floor()` becomes true but the player's foot is close to the floor polygon's
boundary, apply a small XZ correction vector.

Godot 4 `CharacterBody3D` does not expose the contact polygon boundary directly.
Practical approach: after `move_and_slide()`, cast two rays downward at the foot
centre ± capsule_radius in the movement direction. If one hits and one misses, the
foot is over an edge — push back by the miss distance (capped at `edge_snap_dist`).

**Parameters needed in `ControllerProfile`**:
- `edge_snap_dist: float = 0.0` — max snap distance m (0 = off). Assisted: `0.15`.

**Complexity note**: This assist is the most likely to produce jitter (fighting
with the physics step). Recommend implementing ledge magnetism and sticky landing
first, then adding edge-snap only if on-device feel shows players still falling
off regularly.

---

## 5 — New `ControllerProfile` properties needed

| Property | Type | Default (all) | Assisted default |
|---|---|---|---|
| `ledge_magnet_radius` | float | 0.0 | 0.20 |
| `ledge_magnet_strength` | float | 0.0 | 1.0 |
| `arc_assist_max` | float | 0.0 | 0.40 |
| `landing_sticky_frames` | int | 0 | 2 |
| `landing_sticky_factor` | float | 0.0 | 0.20 |
| `edge_snap_dist` | float | 0.0 | 0.15 |

Snappy/Floaty/Momentum all default to 0 for every property — no code changes,
no new behaviour, fully backwards-compatible.

---

## 6 — Implementation order

For the Assisted profile iteration (PLAN P0 item 4):

1. **Sticky landing** — fewest lines, lowest jank risk. Start here.
2. **Ledge magnetism at jump time** — next safest, highest feel impact per
   `character_controllers.md`.
3. **Arc assist** — implement but gate at a very low default until on-device tuning
   confirms it doesn't fight intentional control.
4. **Edge-snap** — implement last if still needed after the above three.

Expose all parameters via dev menu sliders the same iteration they're implemented.

---

## Implications for Project Void

- **`assisted.tres`** can be authored with all assist properties at their 0
  defaults and individually enabled one at a time. This lets the human feel each
  assist in isolation, not as a bundle.
- **Dev menu order** for Assisted: add a new "Assist" subsection in the Controller
  section, separate from Movement/Jump/Slope. Sliders for each of the 6 properties.
- **The `_was_on_floor_last_frame` tracker** needed for sticky landing is also
  useful for the juice system (landing squash fires on the same frame transition).
  Extract it to a shared `_landed_this_frame: bool` computed once in
  `_physics_process` before all sub-routines — avoids two separate `is_on_floor()`
  comparisons.
- **Ray budget**: ledge magnetism fires 2 casts per jump; arc assist fires up to
  20 casts per frame while airborne. On the test device (Adreno 710), a Jolt ray
  against a static convex-hull level is ~0.1 ms each. 20 arc-assist rays per frame
  = up to 2 ms additional physics cost — monitor on device and reduce step count if
  needed.
- **Coyote interaction**: disable ledge magnetism during the coyote window. A
  magnet pulling toward the platform the player just walked off defeats the whole
  point of coyote time.
