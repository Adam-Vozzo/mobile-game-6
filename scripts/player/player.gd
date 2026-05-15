extends CharacterBody3D
class_name Player
## The Stray. Gate 0 character controller.
##
## Drives all movement parameters from a swappable ControllerProfile resource
## so the dev menu can hot-swap profiles at runtime. CLAUDE.md mandates
## coyote time, jump buffer, variable jump height, preserved horizontal
## velocity through jumps, slope handling, and instant respawn with a
## placeholder reboot effect — all implemented below.
##
## Camera frame: movement input is rotated by the camera's yaw, published
## each frame by camera_rig.gd via set_camera_yaw().

@export var profile: ControllerProfile:
	set = set_profile

@export_category("Visual")
## How fast the visual capsule rotates to face horizontal movement direction.
## Higher = snappier turning.
@export_range(1.0, 30.0, 0.5) var visual_turn_speed: float = 12.0
## Below this horizontal speed (m/s) the visual stops chasing heading and
## holds its last orientation — prevents jitter at near-zero velocity.
@export_range(0.0, 2.0, 0.05) var visual_turn_min_speed: float = 0.2

var _camera_yaw: float = 0.0
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _is_rebooting: bool = false
var _spawn_transform: Transform3D
var _last_grounded_pos_y: float = 0.0
var _jump_held_last_frame: bool = false
var _override_material: StandardMaterial3D
# Assisted-profile landing mechanic: track the previous grounded state so we
# can detect the exact frame of touch-down, then count down a short damping
# window.  Both vars are useful outside the Assisted profile — `_was_on_floor`
# doubles as the landing-squash trigger for the juice system (see JUICE.md).
var _was_on_floor_last_frame: bool = false
var _sticky_frames_remaining: int = 0
# Squash-stretch: track falling speed before landing so impact factor is correct
# on the just_landed frame (velocity.y is zeroed by move_and_slide a frame earlier).
var _last_fall_speed: float = 0.0
var _impact_squash_scale: float = 0.5   # dev-menu tunable: 0–1
var _jump_stretch_scale: float = 0.5    # dev-menu tunable: 0–1
var _squash_tween: Tween = null
# Air-jump counter. Seeded from profile.air_jumps on every grounded frame
# (via _tick_timers) and on each ground/coyote jump (via _try_jump) so the
# pool refills for the next aerial phase. Decremented per air jump.
var _air_jumps_remaining: int = 0
# Momentum-profile speed ramp: current effective top speed, always in the range
# [profile.max_speed, profile.ramp_max_speed]. Ramped up by sustained input,
# decayed back to max_speed when input is released. Irrelevant (ignored) when
# profile.speed_ramp_rate == 0 (all non-Momentum profiles).
var _ramp_speed: float = 0.0
# Air dash state. One charge per airborne phase; recharges on landing.
# _is_dashing blocks _apply_horizontal and scales gravity while active.
var _dash_charges: int = 0
var _dash_timer: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _is_dashing: bool = false
# Arc-assist lifetime cap: total horizontal correction (m/s sum) applied since the
# last jump. Resets at jump-time so each arc gets a fresh budget. Prevents the
# per-frame 0.05-factor from compounding into a runaway steering force over a long
# arc. Capped at 1.5 m/s total — enough to land a platform 0.4 m off-centre.
var _arc_assist_accumulated: float = 0.0
# Footstep dust: time since last footstep puff; reset to _footstep_dust_interval
# after each spawn so the effect is throttled regardless of frame rate.
var _footstep_dust_timer: float = 0.0
# Interval between footstep dust puffs (seconds). Tunable via dev menu
# Particles — Tuning → "Footstep interval (s)".
var _footstep_dust_interval: float = 0.15

# Impact factor below which land impact particles are suppressed.
# Lower than Audio.LAND_HEAVY_THRESHOLD (0.25) so even gentle landings
# produce a small dust burst.
const _LAND_IMPACT_THRESHOLD := 0.15

@onready var _visual: Node3D = $Visual
# Chick GLB node hierarchy: Chick → root → body (mesh). Null-safe: if the GLB
# hasn't been imported yet, emission flash stays inert without crashing.
@onready var _body_mesh: MeshInstance3D = get_node_or_null("Visual/Chick/root/body") as MeshInstance3D
@onready var _anim_player: AnimationPlayer = get_node_or_null("Visual/Chick/AnimationPlayer") as AnimationPlayer

const _ANIM_WALK_SPEED := 0.4   # m/s — above this, switch idle → walk
const _ANIM_RUN_SPEED  := 2.5   # m/s — above this, switch walk → run


func _ready() -> void:
	add_to_group(&"player")
	_spawn_transform = global_transform
	_apply_profile_to_body()

	if Engine.has_singleton("DevMenu") or has_node("/root/DevMenu"):
		DevMenu.controller_profile_changed.connect(_on_dev_profile_changed)
		DevMenu.squash_stretch_param_changed.connect(_on_squash_stretch_param)
		DevMenu.particles_param_changed.connect(_on_particles_param)
	if has_node("/root/TouchInput"):
		TouchInput.jump_pressed.connect(_on_jump_pressed)
		TouchInput.air_dash_triggered.connect(_on_air_dash_triggered)


func set_profile(p: ControllerProfile) -> void:
	profile = p
	if is_inside_tree():
		_apply_profile_to_body()


## Called by the camera rig (step 7) when its yaw changes.
func set_camera_yaw(yaw_radians: float) -> void:
	_camera_yaw = yaw_radians


## Default max jump apex height in metres above the takeoff floor, derived
## from the active profile via v² / (2g). Used by the camera rig to decide
## when the player has cleared the "normal jump" band and the camera should
## start tracking vertically. Returns 0.0 if profile is missing/degenerate.
func get_default_apex_height() -> float:
	if profile == null or profile.gravity_rising <= 0.0:
		return 0.0
	return (profile.jump_velocity * profile.jump_velocity) / (2.0 * profile.gravity_rising)


func _apply_profile_to_body() -> void:
	if profile == null:
		profile = ControllerProfile.new()
	floor_max_angle = deg_to_rad(profile.max_floor_angle_degrees)
	floor_snap_length = 0.3
	# Preserve platform-velocity on takeoff (SMB-style momentum off moving
	# platforms): Godot 4 default for `platform_on_leave` is ADD_VELOCITY.
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY
	_ramp_speed = profile.max_speed   # reset speed ramp on profile swap


func _physics_process(delta: float) -> void:
	if _is_rebooting:
		return
	floor_max_angle = deg_to_rad(profile.max_floor_angle_degrees)
	var on_floor := is_on_floor()
	_tick_timers(delta, on_floor)
	var jump_held := _collect_jump_input()
	var jump_released := _was_jump_released(jump_held)
	_jump_held_last_frame = jump_held
	if Input.is_action_just_pressed(&"respawn"):
		respawn()
		return
	if Input.is_action_just_pressed(&"air_dash"):
		_try_air_dash(Vector3.ZERO)
	var move_dir := _camera_relative_move_dir()
	_apply_horizontal(delta, on_floor, move_dir)
	_apply_gravity(delta, jump_held)
	_try_jump()
	_cut_jump(jump_released)
	if not on_floor and not _is_dashing:
		_apply_arc_assist(delta)
	move_and_slide()
	_update_visual_facing(delta)
	_update_anim_state()
	if global_position.y < profile.fall_kill_y:
		respawn()


# ---------- physics sub-routines ----------

func _tick_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = profile.coyote_time
		_last_grounded_pos_y = global_position.y
		_air_jumps_remaining = profile.air_jumps
		_dash_charges = 1   # recharge on landing regardless of profile speed
		_is_dashing = false  # landing always ends an in-progress dash
		_dash_timer = 0.0
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		# Capture falling speed while airborne. On the just_landed frame, on_floor
		# is true so this branch is skipped, preserving the pre-landing value.
		_last_fall_speed = velocity.y
		if _is_dashing:
			_dash_timer = maxf(0.0, _dash_timer - delta)
			if _dash_timer <= 0.0:
				_is_dashing = false
	if _buffer_timer > 0.0:
		_buffer_timer = maxf(0.0, _buffer_timer - delta)
	# Landing detection for Assisted profile sticky-landing mechanic (and juice).
	# `just_landed` is true only on the single frame of touch-down.
	var just_landed := on_floor and not _was_on_floor_last_frame
	if just_landed and profile.landing_sticky_frames > 0:
		_sticky_frames_remaining = profile.landing_sticky_frames
	elif _sticky_frames_remaining > 0:
		if on_floor:
			_sticky_frames_remaining -= 1
		else:
			_sticky_frames_remaining = 0  # took off before window expired
	if just_landed and not _is_rebooting:
		var impact := clampf(-_last_fall_speed / profile.terminal_velocity, 0.0, 1.0)
		_apply_landing_effects(impact)
	_was_on_floor_last_frame = on_floor
	_tick_footstep_dust(on_floor, just_landed, delta)


## Throttled footstep dust emitter. Skips the landing frame so the land-impact
## burst isn't masked by simultaneous footstep geometry.
func _tick_footstep_dust(on_floor: bool, just_landed: bool, delta: float) -> void:
	_footstep_dust_timer = maxf(0.0, _footstep_dust_timer - delta)
	if on_floor and not just_landed and DevMenu.is_juice_on(&"particles"):
		var h_speed := Vector3(velocity.x, 0.0, velocity.z).length()
		if h_speed > 0.5 and _footstep_dust_timer <= 0.0:
			_spawn_footstep_dust()
			_footstep_dust_timer = _footstep_dust_interval


func _collect_jump_input() -> bool:
	if Input.is_action_just_pressed(&"jump"):
		_buffer_timer = profile.jump_buffer
	return TouchInput.is_jump_held() or Input.is_action_pressed(&"jump")


func _was_jump_released(jump_held: bool) -> bool:
	return (
		Input.is_action_just_released(&"jump")
		or (_jump_held_last_frame and not jump_held)
	)


func _camera_relative_move_dir() -> Vector3:
	var move_input := TouchInput.get_move_vector()
	var dir := Basis(Vector3.UP, _camera_yaw) * Vector3(move_input.x, 0.0, move_input.y)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return dir


func _apply_horizontal(delta: float, on_floor: bool, move_dir: Vector3) -> void:
	if _is_dashing:
		return  # horizontal velocity is held at dash speed; _try_air_dash set it
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	# Speed ramp: sustained input builds top speed up to ramp_max_speed.
	# Decays back to max_speed when input is absent. Disabled when rate == 0.
	var effective_max := profile.max_speed
	if profile.speed_ramp_rate > 0.0:
		if move_dir.length() > 0.01:
			_ramp_speed = minf(_ramp_speed + profile.speed_ramp_rate * delta,
				profile.ramp_max_speed)
		else:
			_ramp_speed = maxf(_ramp_speed - profile.speed_ramp_rate * delta,
				profile.max_speed)
		effective_max = _ramp_speed
	var target_h := move_dir * effective_max
	var accel: float
	if move_dir.length() < 0.01 and on_floor:
		accel = profile.ground_deceleration
	elif on_floor:
		accel = profile.ground_acceleration
	else:
		accel = profile.air_acceleration
	var new_h := current_h.move_toward(target_h, accel * delta)
	if not on_floor and profile.air_horizontal_damping > 0.0:
		new_h *= maxf(0.0, 1.0 - profile.air_horizontal_damping * delta)
	# Assisted sticky landing: damp horizontal speed for the first N grounded
	# frames after touch-down so the Stray doesn't skid off narrow platforms.
	if _sticky_frames_remaining > 0 and profile.landing_sticky_factor > 0.0:
		new_h *= (1.0 - profile.landing_sticky_factor)
	velocity.x = new_h.x
	velocity.z = new_h.z


func _apply_gravity(delta: float, jump_held: bool) -> void:
	var g: float
	if velocity.y <= 0.0:
		g = profile.gravity_after_apex
	elif jump_held:
		g = profile.gravity_rising
	else:
		g = profile.gravity_falling
	if _is_dashing:
		g *= profile.air_dash_gravity_scale
	velocity.y = maxf(-profile.terminal_velocity, velocity.y - g * delta)


func _try_jump() -> void:
	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		_attract_to_ledge()
		velocity.y = profile.jump_velocity
		_buffer_timer = 0.0
		_coyote_timer = 0.0
		_arc_assist_accumulated = 0.0
		# Refill the air-jump pool for the new aerial phase.
		_air_jumps_remaining = profile.air_jumps
		if DevMenu.is_juice_on(&"squash_stretch"):
			_play_jump_stretch()
		_spawn_jump_puff()
		if has_node("/root/Audio"):
			Audio.on_jump()
	elif _buffer_timer > 0.0 and _air_jumps_remaining > 0:
		velocity.y = profile.jump_velocity * profile.air_jump_velocity_multiplier
		# Scale horizontal velocity at the moment of jump (1.0 = full preserve,
		# 0.0 = full reset). Default 1.0 upholds the CLAUDE.md invariant.
		velocity.x *= profile.air_jump_horizontal_preserve
		velocity.z *= profile.air_jump_horizontal_preserve
		_buffer_timer = 0.0
		_air_jumps_remaining -= 1
		_arc_assist_accumulated = 0.0
		if DevMenu.is_juice_on(&"squash_stretch"):
			_play_jump_stretch()
		_spawn_jump_puff()
		if has_node("/root/Audio"):
			Audio.on_jump()


func _cut_jump(jump_released: bool) -> void:
	if jump_released and velocity.y > profile.jump_velocity * profile.release_velocity_ratio:
		velocity.y = profile.jump_velocity * profile.release_velocity_ratio


## Ledge magnetism — fires once at ground/coyote jump time.
## Probes ahead-left and ahead-right of the input direction for a nearby platform
## surface. If found, applies a small lateral impulse toward it so a jump that
## would barely graze an edge lands cleanly instead. Gate: on_floor only (not in
## the coyote window) and ledge_magnet_radius > 0.
func _attract_to_ledge() -> void:
	if profile.ledge_magnet_radius <= 0.0 or profile.ledge_magnet_strength <= 0.0:
		return
	if not is_on_floor():
		return
	var move_input := TouchInput.get_move_vector()
	var dir_3d := Basis(Vector3.UP, _camera_yaw) * Vector3(move_input.x, 0.0, move_input.y)
	if dir_3d.length_squared() < 0.01:
		return
	velocity += _compute_ledge_pull(dir_3d.normalized())


## Sphere-casts left and right of the normalised movement direction for a nearby
## platform edge. Returns the proportional lateral impulse toward the first hit,
## or Vector3.ZERO when no edge is within ledge_magnet_radius.
## Called exclusively from _attract_to_ledge after guards pass.
func _compute_ledge_pull(dir_3d: Vector3) -> Vector3:
	const CAPSULE_R := 0.28  # Stray capsule radius (matches CollisionShape3D in player.tscn)
	const FOOT_Y_OFFSET := -0.45  # foot position relative to capsule centre
	const PROBE_AHEAD := CAPSULE_R + 0.05  # just beyond the capsule edge
	var perp := dir_3d.cross(Vector3.UP).normalized()
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = profile.ledge_magnet_radius
	query.shape = sphere
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var foot := global_position + Vector3(0.0, FOOT_Y_OFFSET, 0.0)
	var ahead := dir_3d * PROBE_AHEAD
	for side: float in [-1.0, 1.0]:
		query.transform = Transform3D(Basis.IDENTITY, foot + ahead + perp * side * CAPSULE_R)
		var hits := space.intersect_shape(query, 1)
		if hits.is_empty():
			continue
		var pull := (hits[0]["point"] as Vector3) - foot
		pull.y = 0.0
		var dist := pull.length()
		if dist < 1e-3:
			continue
		# Proportional impulse: closer edge → weaker nudge, capped at strength.
		var impulse := minf(
			(dist / profile.ledge_magnet_radius) * profile.ledge_magnet_strength,
			profile.ledge_magnet_strength
		)
		return pull.normalized() * impulse
	return Vector3.ZERO


## Arc assist — runs every airborne frame (gated by on_floor and dash checks in
## _physics_process). Simulates 20 physics steps ahead to predict the landing
## point. If the predicted landing drifts within arc_assist_max metres of a
## detected surface, a small per-frame lateral impulse steers toward it.
## Lifetime cap: 1.5 m/s accumulated correction per arc (_arc_assist_accumulated).
## Gate: arc_assist_max > 0, not in coyote window, not dashing.
func _apply_arc_assist(delta: float) -> void:
	if profile.arc_assist_max <= 0.0:
		return
	if _coyote_timer > 0.0:
		return  # still at platform edge; don't fight the floor-departure
	const MAX_ACCUMULATED := 1.5  # m/s lifetime cap per arc
	if _arc_assist_accumulated >= MAX_ACCUMULATED:
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
		query.to = sim_pos + Vector3(0.0, -0.5, 0.0)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var land_pt: Vector3 = hit["position"]
		var offset := land_pt - sim_pos
		offset.y = 0.0
		if offset.length() >= profile.arc_assist_max:
			break  # too far off; don't steer
		# Per-frame correction: 5% of max per frame, capped to 15% of jump_velocity × delta.
		var per_frame := (offset.normalized() * profile.arc_assist_max * 0.05).limit_length(
			profile.jump_velocity * 0.15 * delta)
		var budget := MAX_ACCUMULATED - _arc_assist_accumulated
		per_frame = per_frame.limit_length(budget)
		velocity += per_frame
		_arc_assist_accumulated += per_frame.length()
		break


func _update_anim_state() -> void:
	if _anim_player == null:
		return
	var target: StringName
	if is_on_floor():
		var horiz := Vector2(velocity.x, velocity.z).length()
		if horiz >= _ANIM_RUN_SPEED:
			target = &"run"
		elif horiz >= _ANIM_WALK_SPEED:
			target = &"walk"
		else:
			target = &"idle"
	else:
		target = &"idle"
	if _anim_player.current_animation != target:
		_anim_player.play(target)


func _update_visual_facing(delta: float) -> void:
	if _visual == null:
		return
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if horiz_speed < visual_turn_min_speed:
		return
	# Character faces the movement direction with its local -Z (Godot forward),
	# so target yaw rotates local -Z onto the horizontal velocity vector.
	var target_yaw := atan2(-velocity.x, -velocity.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw,
		clampf(visual_turn_speed * delta, 0.0, 1.0))


func _play_land_squash(impact: float) -> void:
	if _visual == null:
		return
	var squash_y  := 1.0 - impact * 0.45 * _impact_squash_scale
	var squash_xz := 1.0 + impact * 0.20 * _impact_squash_scale
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	_squash_tween.tween_property(_visual, "scale",
		Vector3(squash_xz, squash_y, squash_xz), 0.06)
	_squash_tween.tween_property(_visual, "scale", Vector3.ONE, 0.25)


func _play_jump_stretch() -> void:
	if _visual == null:
		return
	var stretch_y  := 1.0 + 0.30 * _jump_stretch_scale
	var stretch_xz := 1.0 - 0.15 * _jump_stretch_scale
	# Anticipation squish: brief coil before the stretch launches (classic
	# platformer "tell" — compresses then releases).
	var coil_y   := 1.0 - 0.18 * _jump_stretch_scale
	var coil_xz  := 1.0 + 0.08 * _jump_stretch_scale
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_squash_tween.tween_property(_visual, "scale",
		Vector3(coil_xz, coil_y, coil_xz), 0.04)
	_squash_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_squash_tween.tween_property(_visual, "scale",
		Vector3(stretch_xz, stretch_y, stretch_xz), 0.05)
	_squash_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_squash_tween.tween_property(_visual, "scale", Vector3.ONE, 0.18)


func respawn() -> void:
	if _is_rebooting:
		return
	_is_rebooting = true
	velocity = Vector3.ZERO
	# Clear input timers so a buffered jump at death-time doesn't fire on the
	# first frame after reboot. Timers don't tick while _is_rebooting is true,
	# so without this they would still be "live" after a 0.5 s reboot sequence.
	_buffer_timer = 0.0
	_coyote_timer = 0.0
	_air_jumps_remaining = 0
	_dash_charges = 0
	_dash_timer = 0.0
	_is_dashing = false
	_ramp_speed = profile.max_speed
	_arc_assist_accumulated = 0.0
	# Kill any running squash-stretch tween so it doesn't fight _run_reboot_effect.
	if _squash_tween != null:
		_squash_tween.kill()
		_squash_tween = null
	if _visual != null:
		_visual.scale = Vector3.ONE
	if has_node("/root/Game"):
		Game.register_attempt()
		Game.player_respawned.emit()
		Game.screen_shake_requested.emit(0.022, 0.20, 26.0)
	if has_node("/root/Audio"):
		Audio.on_respawn_start()
	_run_reboot_effect()


func set_spawn_transform(t: Transform3D) -> void:
	_spawn_transform = t


# ---------- internals ----------

func _on_jump_pressed() -> void:
	# Touch jump fires through TouchInput.jump_pressed — buffer it the same
	# way as the keyboard "just_pressed."
	if profile != null:
		_buffer_timer = profile.jump_buffer


func _on_dev_profile_changed(new_profile: Resource) -> void:
	if new_profile is ControllerProfile:
		set_profile(new_profile)


func _on_squash_stretch_param(param: StringName, value: float) -> void:
	match param:
		&"impact_squash_scale": _impact_squash_scale = value
		&"jump_stretch_scale":  _jump_stretch_scale = value


func _on_air_dash_triggered(dir_2d: Vector2) -> void:
	# Touch overlay emits a 2D screen-space direction; rotate into world space
	# using the camera yaw, consistent with _camera_relative_move_dir().
	var dir_3d := Basis(Vector3.UP, _camera_yaw) * Vector3(dir_2d.x, 0.0, dir_2d.y)
	_try_air_dash(dir_3d)


## Trigger an air dash in `dir` (world space, horizontal). Pass Vector3.ZERO to
## fall back to the current horizontal velocity direction (keyboard usage).
## Guards: rebooting, already dashing, no charges, on floor, speed disabled.
func _try_air_dash(dir: Vector3) -> void:
	if _is_rebooting or _is_dashing or _dash_charges <= 0 or is_on_floor():
		return
	if profile.air_dash_speed <= 0.0:
		return
	var dash_dir := dir
	if dash_dir.length() < 0.01:
		dash_dir = Vector3(velocity.x, 0.0, velocity.z).normalized()
	if dash_dir.length() < 0.01:
		# Absolute fallback: face direction of visual (local -Z)
		dash_dir = -_visual.global_basis.z if _visual else Vector3.FORWARD
	_dash_charges -= 1
	_dash_timer = profile.air_dash_duration
	_dash_dir = dash_dir.normalized()
	_is_dashing = true
	velocity.x = _dash_dir.x * profile.air_dash_speed
	velocity.z = _dash_dir.z * profile.air_dash_speed
	velocity.y = 0.0
	if DevMenu.is_juice_on(&"squash_stretch"):
		_play_dash_stretch()


func _play_dash_stretch() -> void:
	if _visual == null:
		return
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_squash_tween.tween_property(_visual, "scale", Vector3(1.25, 0.75, 1.25), 0.05)
	_squash_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_squash_tween.tween_property(_visual, "scale", Vector3.ONE, 0.15)


func _play_death_squish(duration: float) -> void:
	if _visual == null or not DevMenu.is_juice_on(&"squash_stretch"):
		return
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.tween_property(_visual, "scale", Vector3(1.25, 0.25, 1.25), duration)


func _play_reboot_grow(duration: float) -> void:
	# When juice is off, just ensure the scale is correct at spawn.
	if _visual == null:
		return
	if not DevMenu.is_juice_on(&"squash_stretch"):
		_visual.scale = Vector3.ONE
		return
	_visual.scale = Vector3(0.05, 0.05, 0.05)
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_squash_tween.tween_property(_visual, "scale", Vector3.ONE, duration)


func _run_reboot_effect() -> void:
	var dur := profile.reboot_duration
	var death_centre := global_position + Vector3(0.0, 0.45, 0.0)

	# 1. Death beat: sparks burst + squish crush
	_spawn_sparks(death_centre)
	_set_emission(Color(1.0, 0.18, 0.1), 5.0)
	_play_death_squish(dur * 0.08)
	await get_tree().create_timer(dur * 0.12).timeout

	# 2. Dark frame: hide visual, reset scale, teleport
	if _visual:
		_visual.visible = false
		_visual.scale = Vector3.ONE
	_clear_emission()
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	await get_tree().create_timer(dur * 0.35).timeout

	# 3. Power-on: show visual, scale up from near-zero with overshoot
	if _visual:
		_visual.visible = true
	_play_reboot_grow(dur * 0.28)
	_set_emission(Color(1.0, 0.55, 0.15), 2.5)
	await get_tree().create_timer(dur * 0.35).timeout

	# 4. Settle: clear glow, confirm scale, resume
	if _visual:
		_visual.scale = Vector3.ONE
	_clear_emission()
	await get_tree().create_timer(dur * 0.18).timeout
	_is_rebooting = false


# Spawns temporary ImmediateMesh spark lines at `origin` in world space.
# Gated behind the "particles" juice toggle; frees itself after ~0.5 s.
func _spawn_sparks(origin: Vector3) -> void:
	if not DevMenu.is_juice_on(&"particles"):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var mat := _build_spark_material()
	var mi := MeshInstance3D.new()
	mi.mesh = _build_spark_mesh(rng)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().root.add_child(mi)
	mi.global_position = origin
	_fade_and_free_spark(mi, mat)


func _build_spark_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.78, 0.12, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _build_spark_mesh(rng: RandomNumberGenerator) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for _i in 12:
		var dir := Vector3(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(0.15, 1.6),
			rng.randf_range(-1.0, 1.0)
		).normalized()
		var length := rng.randf_range(0.18, 0.65)
		mesh.surface_add_vertex(dir * 0.1)
		mesh.surface_add_vertex(dir * (0.1 + length))
	mesh.surface_end()
	return mesh


func _fade_and_free_spark(mi: MeshInstance3D, mat: StandardMaterial3D) -> void:
	var tween := mi.create_tween()
	tween.tween_interval(0.07)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.38)
	tween.tween_callback(mi.queue_free)


# Gated behind the "particles" juice toggle; frees itself after ~0.2 s.
func _spawn_jump_puff() -> void:
	if not DevMenu.is_juice_on(&"particles"):
		return
	var mat := _build_puff_material()
	var mi := MeshInstance3D.new()
	mi.mesh = _build_puff_mesh()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().root.add_child(mi)
	mi.global_position = global_position + Vector3(0.0, 0.06, 0.0)
	_fade_and_free_puff(mi, mat)


func _build_puff_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.80, 0.77, 0.72, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _build_puff_mesh() -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 8:
		var angle := float(i) * TAU / 8.0 + rng.randf_range(-0.25, 0.25)
		var length := rng.randf_range(0.10, 0.28)
		# Slight upward kick on each line so the burst reads as dust lifting off.
		var dir := Vector3(cos(angle), rng.randf_range(0.0, 0.12), sin(angle)).normalized()
		mesh.surface_add_vertex(dir * 0.04)
		mesh.surface_add_vertex(dir * (0.04 + length))
	mesh.surface_end()
	return mesh


func _fade_and_free_puff(mi: MeshInstance3D, mat: StandardMaterial3D) -> void:
	var tween := mi.create_tween()
	tween.tween_interval(0.04)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.16)
	tween.tween_callback(mi.queue_free)


# Dispatches all landing-frame feedback: squash-stretch, audio, screen shake,
# and land impact particles. Extracted from _tick_timers to keep it under 40 lines.
func _apply_landing_effects(impact: float) -> void:
	if DevMenu.is_juice_on(&"squash_stretch"):
		_play_land_squash(impact)
	if has_node("/root/Audio"):
		Audio.on_land(impact)
	# Heavy landing only (same threshold as audio heavy/light split).
	if has_node("/root/Game") and impact >= Audio.LAND_HEAVY_THRESHOLD:
		Game.screen_shake_requested.emit(0.011 * impact, 0.13, 20.0)
	if DevMenu.is_juice_on(&"particles") and impact >= _LAND_IMPACT_THRESHOLD:
		_spawn_land_impact(impact)


# Gated behind "particles" toggle. 4 short lines at foot level; fades in 0.10 s.
# Throttled by _footstep_dust_timer so it fires at most every _footstep_dust_interval.
func _spawn_footstep_dust() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.80, 0.77, 0.72, 0.50)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = _build_footstep_mesh()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().root.add_child(mi)
	mi.global_position = global_position + Vector3(0.0, 0.04, 0.0)
	var tween := mi.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.10)
	tween.tween_callback(mi.queue_free)


func _build_footstep_mesh() -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 4:
		var angle := float(i) * TAU / 4.0
		# Small upward kick so the dust reads as lifting off the floor.
		var dir := Vector3(cos(angle), 0.06, sin(angle)).normalized()
		mesh.surface_add_vertex(dir * 0.03)
		mesh.surface_add_vertex(dir * 0.09)
	mesh.surface_end()
	return mesh


# Gated behind "particles" toggle. Radial burst scaled by landing impact;
# suppressed below _LAND_IMPACT_THRESHOLD. Fades in 0.18 s after a 0.03 s hold.
func _spawn_land_impact(impact: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.80, 0.77, 0.72, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = _build_impact_mesh(impact)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().root.add_child(mi)
	mi.global_position = global_position + Vector3(0.0, 0.04, 0.0)
	var tween := mi.create_tween()
	tween.tween_interval(0.03)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tween.tween_callback(mi.queue_free)


func _build_impact_mesh(impact: float) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 6:
		var angle := float(i) * TAU / 6.0
		var length := 0.08 + impact * 0.22
		# Upward kick scales with impact so heavy landings spray higher.
		var dir := Vector3(cos(angle), impact * 0.12, sin(angle)).normalized()
		mesh.surface_add_vertex(dir * 0.05)
		mesh.surface_add_vertex(dir * (0.05 + length))
	mesh.surface_end()
	return mesh


func _on_particles_param(param: StringName, value: float) -> void:
	match param:
		&"footstep_interval": _footstep_dust_interval = value


func _set_emission(color: Color, energy: float) -> void:
	if _body_mesh == null:
		return
	if _override_material == null:
		_override_material = StandardMaterial3D.new()
	_override_material.albedo_color = Color(0.05, 0.05, 0.06, 1)
	_override_material.emission_enabled = true
	_override_material.emission = color
	_override_material.emission_energy_multiplier = energy
	_body_mesh.material_override = _override_material


func _clear_emission() -> void:
	if _body_mesh != null:
		_body_mesh.material_override = null
