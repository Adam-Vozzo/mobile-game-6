class_name Player
extends CharacterBody3D

signal jumped
signal landed

@export var profile: ControllerProfile

# Set each frame by feel_lab or other scene controller.
var move_input: Vector2 = Vector2.ZERO
var jump_held: bool = false

var _jump_pressed: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_jump_held: bool = false
var _was_grounded: bool = false

func _ready() -> void:
	if profile == null:
		profile = ControllerProfile.new()

func _physics_process(delta: float) -> void:
	var on_ground := is_on_floor()

	_tick_coyote(on_ground, delta)
	_tick_jump_buffer(delta)
	_apply_gravity(on_ground, delta)
	_try_jump(on_ground)
	_apply_horizontal(on_ground, delta)
	_face_movement(delta)
	_emit_land(on_ground)

	move_and_slide()
	_jump_pressed = false

func on_jump_pressed() -> void:
	_jump_pressed = true

func on_jump_released() -> void:
	jump_held = false

# ── input helpers called from touch / keyboard ───────────────────────────────

func _tick_coyote(on_ground: bool, delta: float) -> void:
	if on_ground:
		_coyote_timer = profile.coyote_time
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

func _tick_jump_buffer(delta: float) -> void:
	if _jump_pressed:
		_jump_buffer_timer = profile.jump_buffer_time
	elif _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

func _apply_gravity(on_ground: bool, delta: float) -> void:
	if on_ground:
		return
	var scale := 1.0
	if _is_jump_held and velocity.y > 0.0:
		scale = profile.jump_hold_gravity_scale
	elif velocity.y < 0.0:
		scale = profile.fall_gravity_scale
	velocity.y -= profile.base_gravity * scale * delta
	velocity.y = max(velocity.y, -profile.max_fall_speed)

func _try_jump(on_ground: bool) -> void:
	var can_jump := _coyote_timer > 0.0
	if _jump_buffer_timer > 0.0 and can_jump:
		velocity.y = profile.jump_velocity
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_is_jump_held = jump_held
		jumped.emit()
	if not jump_held:
		_is_jump_held = false

func _apply_horizontal(on_ground: bool, delta: float) -> void:
	var cam_basis := _camera_flat_basis()
	var wish_dir := (cam_basis * Vector3(move_input.x, 0.0, move_input.y))
	wish_dir.y = 0.0
	if wish_dir.length_squared() > 0.01:
		wish_dir = wish_dir.normalized()

	var moving := move_input.length_squared() > 0.01
	var target := wish_dir * (profile.walk_speed if moving else 0.0)
	var rate := (profile.acceleration if moving else profile.friction) if on_ground \
		else (profile.air_acceleration if moving else profile.air_friction)

	var horiz := Vector2(velocity.x, velocity.z)
	horiz = horiz.move_toward(Vector2(target.x, target.z), rate * delta)
	velocity.x = horiz.x
	velocity.z = horiz.y

func _face_movement(delta: float) -> void:
	var horiz := Vector2(velocity.x, velocity.z)
	if horiz.length_squared() < 0.1:
		return
	# -velocity.z because Godot's "forward" is -Z; atan2 expects +Z as 0°.
	var target_y := atan2(velocity.x, -velocity.z)
	rotation.y = lerp_angle(rotation.y, target_y, deg_to_rad(profile.turn_speed_deg) * delta)

func _emit_land(on_ground: bool) -> void:
	if on_ground and not _was_grounded:
		landed.emit()
	_was_grounded = on_ground

func _camera_flat_basis() -> Basis:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Basis.IDENTITY
	var fwd := -cam.global_basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.001:
		return Basis.IDENTITY
	fwd = fwd.normalized()
	return Basis(fwd.cross(Vector3.UP), Vector3.UP, -fwd)
