extends Resource
class_name ControllerProfile
## Tunable parameter set for the Stray's character controller. Profiles
## live in /resources/profiles/ as .tres files and are hot-swappable from
## the dev menu. CLAUDE.md mandates four targets: Snappy (SMB-leaning),
## Floaty (Dadish-leaning), Momentum (experimental), Assisted (mobile-first).
## Snappy, Floaty, and Momentum are implemented; Assisted is queued in PLAN.md.
##
## Units: metres, seconds. The Stray is ~0.8 m tall.

@export_category("Movement")
## Maximum horizontal speed, m/s.
@export_range(2.0, 20.0, 0.1) var max_speed: float = 8.0
## How fast we ramp toward `max_speed` when grounded, in (m/s)/s.
@export_range(10.0, 200.0, 1.0) var ground_acceleration: float = 80.0
## How fast we slow to a stop when input is released, grounded.
@export_range(10.0, 200.0, 1.0) var ground_deceleration: float = 90.0
## Acceleration toward target speed while airborne. Lower = "floatier."
@export_range(5.0, 200.0, 1.0) var air_acceleration: float = 50.0
## Optional damping applied to airborne horizontal velocity each second.
## 0.0 = no damping (full preservation, SMB-style); higher = grippier.
@export_range(0.0, 5.0, 0.05) var air_horizontal_damping: float = 0.0

@export_category("Jump")
## Initial upward velocity at jump start, m/s.
@export_range(2.0, 20.0, 0.1) var jump_velocity: float = 11.5
## Gravity while ascending and jump is held, m/s² (positive, applied as -Y).
@export_range(10.0, 80.0, 0.5) var gravity_rising: float = 38.0
## Gravity once jump is released early or at apex.
@export_range(10.0, 80.0, 0.5) var gravity_falling: float = 60.0
## Gravity once Y velocity goes negative (after apex). Adds "snap" to fall.
@export_range(10.0, 100.0, 0.5) var gravity_after_apex: float = 75.0
## Maximum downward speed (terminal velocity).
@export_range(10.0, 60.0, 0.5) var terminal_velocity: float = 40.0
## Coyote time: how long after leaving ground a jump still works.
@export_range(0.0, 0.3, 0.005) var coyote_time: float = 0.10
## Jump buffer: how long an early jump press stays "live."
@export_range(0.0, 0.3, 0.005) var jump_buffer: float = 0.12
## Variable jump cap: when jump is released early, vertical velocity is
## clamped to (jump_velocity * release_velocity_ratio).
@export_range(0.1, 1.0, 0.01) var release_velocity_ratio: float = 0.45
## Number of extra jumps available while airborne. 0 = disabled (default for
## all profiles). 1 = classic double-jump. Resets on landing and whenever a
## ground/coyote jump fires. Tunable per-profile from the dev menu.
@export_range(0, 3, 1) var air_jumps: int = 0
## Velocity multiplier for each air jump as a fraction of jump_velocity.
## 1.0 = same initial speed as the ground jump; 0.8 = slightly weaker, which
## creates a feel distinction between ground and air jumps.
@export_range(0.3, 1.2, 0.05) var air_jump_velocity_multiplier: float = 0.8
## Fraction of current horizontal velocity preserved at the moment an air
## jump fires. 1.0 = full preservation (default — upholds the CLAUDE.md
## preserved-horizontal-velocity invariant). Lower values let the air jump
## act as a partial horizontal brake; 0.0 = full horizontal reset.
@export_range(0.0, 1.0, 0.05) var air_jump_horizontal_preserve: float = 1.0

@export_category("Slope")
## Max angle (degrees) the Stray treats as walkable ground.
@export_range(20.0, 70.0, 1.0) var max_floor_angle_degrees: float = 50.0

@export_category("Respawn")
## Y-coordinate below which the player auto-respawns.
@export_range(-200.0, 0.0, 0.5) var fall_kill_y: float = -25.0
## Duration of the reboot effect (red flash → dark → fade in).
@export_range(0.05, 1.5, 0.05) var reboot_duration: float = 0.5

@export_category("Assisted")
## Speed multiplier applied to horizontal velocity for `landing_sticky_frames`
## physics frames after the player touches down. 0 = disabled (default for all
## non-Assisted profiles). 0.2 = 20% per-frame reduction for 2 frames on landing.
## This shortens the slide-out on narrow platforms — the key mobile-first
## "sticky landing" mechanic for the Assisted profile.
@export_range(0.0, 0.8, 0.05) var landing_sticky_factor: float = 0.0
## How many grounded physics frames to apply landing_sticky_factor after landing.
## 0 = disabled. Counting resets if the player leaves the floor before it expires.
@export_range(0, 6, 1) var landing_sticky_frames: int = 0
