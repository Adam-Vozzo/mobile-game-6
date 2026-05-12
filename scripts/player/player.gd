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

@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Body


func _ready() -> void:
	add_to_group(&"player")
	_spawn_transform = global_transform
	_apply_profile_to_body()

	if Engine.has_singleton("DevMenu") or has_node("/root/DevMenu"):
		DevMenu.controller_profile_changed.connect(_on_dev_profile_changed)
		DevMenu.squash_stretch_param_changed.connect(_on_squash_stretch_param)
	if has_node("/root/TouchInput"):
		TouchInput.jump_pressed.connect(_on_jump_pressed)


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
	var move_dir := _camera_relative_move_dir()
	_apply_horizontal(delta, on_floor, move_dir)
	_apply_gravity(delta, jump_held)
	_try_jump()
	_cut_jump(jump_released)
	move_and_slide()
	_update_visual_facing(delta)
	if global_position.y < profile.fall_kill_y:
		respawn()


# ---------- physics sub-routines ----------

func _tick_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = profile.coyote_time
		_last_grounded_pos_y = global_position.y
		_air_jumps_remaining = profile.air_jumps
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		# Capture falling speed while airborne. On the just_landed frame, on_floor
		# is true so this branch is skipped, preserving the pre-landing value.
		_last_fall_speed = velocity.y
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
	if just_landed and not _is_rebooting and DevMenu.is_juice_on(&"squash_stretch"):
		var impact := clampf(-_last_fall_speed / profile.terminal_velocity, 0.0, 1.0)
		_play_land_squash(impact)
	_was_on_floor_last_frame = on_floor


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
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var target_h := move_dir * profile.max_speed
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
	velocity.y = maxf(-profile.terminal_velocity, velocity.y - g * delta)


func _try_jump() -> void:
	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = profile.jump_velocity
		_buffer_timer = 0.0
		_coyote_timer = 0.0
		# Refill the air-jump pool for the new aerial phase.
		_air_jumps_remaining = profile.air_jumps
		if DevMenu.is_juice_on(&"squash_stretch"):
			_play_jump_stretch()
		_spawn_jump_puff()
	elif _buffer_timer > 0.0 and _air_jumps_remaining > 0:
		velocity.y = profile.jump_velocity * profile.air_jump_velocity_multiplier
		# Scale horizontal velocity at the moment of jump (1.0 = full preserve,
		# 0.0 = full reset). Default 1.0 upholds the CLAUDE.md invariant.
		velocity.x *= profile.air_jump_horizontal_preserve
		velocity.z *= profile.air_jump_horizontal_preserve
		_buffer_timer = 0.0
		_air_jumps_remaining -= 1
		if DevMenu.is_juice_on(&"squash_stretch"):
			_play_jump_stretch()
		_spawn_jump_puff()


func _cut_jump(jump_released: bool) -> void:
	if jump_released and velocity.y > profile.jump_velocity * profile.release_velocity_ratio:
		velocity.y = profile.jump_velocity * profile.release_velocity_ratio


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
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
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
	# Kill any running squash-stretch tween so it doesn't fight _run_reboot_effect.
	if _squash_tween != null:
		_squash_tween.kill()
		_squash_tween = null
	if _visual != null:
		_visual.scale = Vector3.ONE
	if has_node("/root/Game"):
		Game.register_attempt()
		Game.player_respawned.emit()
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


func _run_reboot_effect() -> void:
	var dur := profile.reboot_duration
	var death_centre := global_position + Vector3(0.0, 0.45, 0.0)

	# 1. Death beat: sparks burst + squish crush
	_spawn_sparks(death_centre)
	_set_emission(Color(1.0, 0.18, 0.1), 5.0)
	if _visual and DevMenu.is_juice_on(&"squash_stretch"):
		var squish := create_tween()
		squish.tween_property(_visual, "scale",
				Vector3(1.25, 0.25, 1.25), dur * 0.08)
	await get_tree().create_timer(dur * 0.12).timeout

	# 2. Dark frame: hide visual, reset scale, teleport
	if _visual:
		_visual.visible = false
		_visual.scale = Vector3.ONE
	_clear_emission()
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	await get_tree().create_timer(dur * 0.35).timeout

	# 3. Power-on: scale up from near-zero with overshoot (upright beat)
	if _visual:
		_visual.visible = true
		if DevMenu.is_juice_on(&"squash_stretch"):
			_visual.scale = Vector3(0.05, 0.05, 0.05)
			var grow := create_tween()
			grow.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			grow.tween_property(_visual, "scale", Vector3.ONE, dur * 0.28)
		else:
			_visual.scale = Vector3.ONE
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
