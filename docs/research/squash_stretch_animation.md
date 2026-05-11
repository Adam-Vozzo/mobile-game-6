# Squash-Stretch Animation — Godot 4 Techniques

Research for Project Void — Gate 1 juice priority #1 (landing squash, per `juice_density.md`).

---

## The Principle

Squash-stretch is the oldest Disney animation principle and the highest-ROI juice element in a
precision platformer. A small robot landing on concrete reads as *physically real* when it
compresses vertically and expands laterally on impact, then springs back. Without it, the
Stray feels like a cursor sliding around a 3D scene.

Key constraint for Void: the Stray is a chibi primitive capsule (Gate 0), with no skeleton.
All squash-stretch must be delivered via **node scale tweens** on the `$Visual` node, not
bone deformation. This is actually an advantage — scale tweens are trivially cheap.

---

## Godot 4 Approaches

### Option A — `Tween` on `Visual.scale` (recommended)

```gdscript
# Landing squash: compress Y, bulge XZ, spring back.
func _play_land_squash(impact_factor: float) -> void:
	# impact_factor: 0..1, derived from vertical speed at landing.
	var squash_y  := 1.0 - impact_factor * 0.45   # e.g., 0.55 at hard landing
	var squash_xz := 1.0 + impact_factor * 0.20   # compensate volume
	var squash := create_tween()
	squash.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	squash.tween_property(_visual, "scale",
		Vector3(squash_xz, squash_y, squash_xz), 0.06)  # fast compress
	squash.tween_property(_visual, "scale",
		Vector3.ONE, 0.25)                               # spring recovery

# Jump stretch: elongate Y, compress XZ on takeoff.
func _play_jump_stretch() -> void:
	var stretch := create_tween()
	stretch.set_ease(Tween.EASE_OUT)
	stretch.tween_property(_visual, "scale",
		Vector3(0.85, 1.3, 0.85), 0.05)   # quick stretch up
	stretch.tween_property(_visual, "scale",
		Vector3.ONE, 0.18)                 # settle in air
```

**Why Tween, not AnimationPlayer?**
- `Tween` is procedural: impact magnitude is a float computed at runtime, not an authored keyframe.
- `AnimationPlayer` works when the animation is always the same duration and curve — use it
  for the reboot animation (fixed sequence) or a fixed-duration anticipation squish.
- Runtime landing hardness varies by fall height, so `Tween` is the correct tool.

### Option B — `AnimationPlayer` blend (fixed-magnitude elements)

Pre-jump anticipation squish (in the buffer window) is a *fixed* small squish regardless of
jump height — 10% Y compress over 60 ms. This is a good `AnimationPlayer` candidate: plays
from a trigger signal, same shape every time.

### Option C — `ShaderMaterial` + uniform (not recommended for Gate 1)

Vertex-shader squash-stretch preserves volume more accurately but requires a custom shader
on the body mesh and is harder to tune without device testing. Defer to Gate 2+ if scale
tweens look wrong on the real mesh.

---

## Impact Factor Derivation

The landing squash should scale with how hard the Stray hit. `player.gd` already knows
`velocity.y` on the frame `just_landed` fires:

```gdscript
# In _tick_timers or a new _on_landed() hook:
if just_landed:
	var impact := clampf(-velocity.y / profile.terminal_velocity, 0.0, 1.0)
	# impact == 0 for a gentle step-down, 1.0 for a terminal-velocity slam.
	_play_land_squash(impact)
```

The `_was_on_floor_last_frame` / `just_landed` tracker is already in place (iter 27 for the
Assisted profile). It doubles as the juice landing trigger — this was noted in
`assist_mechanics.md`: "`_was_on_floor_last_frame` doubles as the landing-squash trigger."

---

## Draw-Call Cost

Zero. Property tweens mutate a uniform (`scale`) that the GPU already reads each frame.
No additional draw calls, no particle allocation, no new nodes. This is the cheapest
possible juice element at runtime.

---

## Curve Recommendations

| beat | Tween ease | Tween trans | duration |
|------|-----------|-------------|----------|
| Landing compress | EASE_OUT | TRANS_BOUNCE or TRANS_SPRING | 0.05–0.08 s |
| Landing recovery | EASE_OUT | TRANS_SPRING | 0.20–0.30 s |
| Jump stretch | EASE_OUT | TRANS_QUAD | 0.04–0.06 s |
| Jump settle | EASE_IN_OUT | TRANS_SINE | 0.15–0.22 s |
| Pre-jump anticipation | EASE_IN | TRANS_QUAD | 0.05–0.08 s |

TRANS_SPRING produces a natural overshoot without coding it manually (analogous to
the `TRANS_BACK` already used in the reboot grow-up). It is ideal for physical-feeling
recovery from a squash. TRANS_BOUNCE is similar but double-bounces — test both.

---

## Conflict with Reboot Sequence

`_run_reboot_effect` already tweens `_visual.scale` (death squish → zero → TRANS_BACK overshoot).
If a landing squash tween fires during a reboot, the two tweens will fight.

Safeguard: check `_is_rebooting` before starting a landing squash tween. Since `just_landed`
can fire after the teleport step of reboot (player lands at spawn point), this guard is essential:

```gdscript
if just_landed and not _is_rebooting:
	_play_land_squash(impact)
```

---

## Integration Checklist (for the implementing iteration)

1. Add `_play_land_squash(impact: float)` and `_play_jump_stretch()` to `player.gd`.
2. Call `_play_land_squash` from the `just_landed` block in `_tick_timers` (after the
   Assisted sticky-landing block so both can read `just_landed`).
3. Call `_play_jump_stretch` from `_try_jump()` after setting `velocity.y`.
4. Gate both behind `DevMenu.is_juice_on(&"squash_stretch")`.
5. Add `landing_squash_factor` and `jump_stretch_factor` `@export_range` on player (or
   hardcode initial values and add dev-menu sliders for impact_scale and stretch_scale).
6. Add to `JUICE.md`: update "Land squish" and "Pre-jump anticipation" from `idea` → `prototype`.

---

## Implications for Void

1. **Landing squash is free** (zero draw calls, zero particles). Ship it in Gate 1 before
   any other squash-stretch element — it has the highest perceptual payoff per cost.
2. **`just_landed` is already tracked** in `player.gd` via `_was_on_floor_last_frame`. The
   impact factor only requires reading `velocity.y` on that frame — a one-liner.
3. **Scale on `$Visual`, not on the root CharacterBody3D**. Scaling `CharacterBody3D`
   would deform the physics capsule. `$Visual` is already the separate render node.
4. **Guard against reboot conflict** — both `_run_reboot_effect` and landing squash write
   to `_visual.scale`. The `_is_rebooting` flag is the correct gate.
5. **Apex hold** (brief Y stretch at jump apex — vy ≈ 0) needs the gravity band to publish
   "entering apex" state, which doesn't exist yet. Log as a follow-up; land squash first.
6. **Pre-jump anticipation** is the best candidate for `AnimationPlayer` (fixed shape,
   fixed duration, triggered by `_buffer_timer` becoming non-zero). Implement after
   landing squash is tuned on device.
7. **Tunable magnitudes are mandatory**: the human will feel whether the squash is too heavy
   or too light on the test device. Expose `impact_scale` (0–1 float) as a dev-menu slider
   in the Juice section from day one.
