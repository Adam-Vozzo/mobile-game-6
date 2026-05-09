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

const ControllerProfileScript := preload("res://scripts/controller/controller_profile.gd")

@export var profile: Resource:
	set = set_profile

var _camera_yaw: float = 0.0
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _is_rebooting: bool = false
var _spawn_transform: Transform3D
var _last_grounded_pos_y: float = 0.0
var _jump_held_last_frame: bool = false
var _override_material: StandardMaterial3D

@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Body
@onready var _accent_mesh: MeshInstance3D = $Visual/Accent


func _ready() -> void:
	add_to_group(&"player")
	_spawn_transform = global_transform
	_apply_profile_to_body()

	if Engine.has_singleton("DevMenu") or has_node("/root/DevMenu"):
		DevMenu.controller_profile_changed.connect(_on_dev_profile_changed)
	if has_node("/root/TouchInput"):
		TouchInput.jump_pressed.connect(_on_jump_pressed)


func set_profile(p: Resource) -> void:
	profile = p
	if is_inside_tree():
		_apply_profile_to_body()


## Called by the camera rig (step 7) when its yaw changes.
func set_camera_yaw(yaw_radians: float) -> void:
	_camera_yaw = yaw_radians


func _apply_profile_to_body() -> void:
	if profile == null:
		profile = ControllerProfileScript.new()
	floor_max_angle = deg_to_rad(profile.max_floor_angle_degrees)
	floor_snap_length = 0.3
	# Preserve platform-velocity on takeoff (SMB-style momentum off moving
	# platforms): Godot 4 default for `platform_on_leave` is ADD_VELOCITY.
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY


func _physics_process(delta: float) -> void:
	if _is_rebooting:
		return

	# --- Timers ---
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = profile.coyote_time
		_last_grounded_pos_y = global_position.y
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if _buffer_timer > 0.0:
		_buffer_timer = maxf(0.0, _buffer_timer - delta)

	# --- Input ---
	var move_input := TouchInput.get_move_vector()
	var jump_pressed_now := Input.is_action_just_pressed(&"jump")
	var jump_held := TouchInput.is_jump_held() or Input.is_action_pressed(&"jump")
	var jump_released_now := (
		Input.is_action_just_released(&"jump")
		or (_jump_held_last_frame and not jump_held)
	)
	_jump_held_last_frame = jump_held

	if jump_pressed_now:
		_buffer_timer = profile.jump_buffer

	if Input.is_action_just_pressed(&"respawn"):
		respawn()
		return

	# --- Horizontal movement (camera-relative) ---
	var camera_basis := Basis(Vector3.UP, _camera_yaw)
	var move_dir := camera_basis * Vector3(move_input.x, 0.0, move_input.y)
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()

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

	velocity.x = new_h.x
	velocity.z = new_h.z

	# --- Gravity (three-band: rising-held / rising-released / falling) ---
	var g: float
	if velocity.y <= 0.0:
		g = profile.gravity_after_apex
	elif jump_held:
		g = profile.gravity_rising
	else:
		g = profile.gravity_falling
	velocity.y = maxf(-profile.terminal_velocity, velocity.y - g * delta)

	# --- Jump (consumes coyote + buffer if both alive) ---
	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = profile.jump_velocity
		_buffer_timer = 0.0
		_coyote_timer = 0.0

	# --- Variable jump cut on early release ---
	if jump_released_now and velocity.y > profile.jump_velocity * profile.release_velocity_ratio:
		velocity.y = profile.jump_velocity * profile.release_velocity_ratio

	move_and_slide()

	# --- Fall kill ---
	if global_position.y < profile.fall_kill_y:
		respawn()


func respawn() -> void:
	if _is_rebooting:
		return
	_is_rebooting = true
	velocity = Vector3.ZERO
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
	if new_profile != null:
		set_profile(new_profile)


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

	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.78, 0.12, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var rng := RandomNumberGenerator.new()
	rng.randomize()

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

	get_tree().root.add_child(mi)
	mi.global_position = origin

	var tween := mi.create_tween()
	tween.tween_interval(0.07)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.38)
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
