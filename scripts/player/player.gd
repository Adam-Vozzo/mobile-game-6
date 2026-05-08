class_name Player
extends CharacterBody3D

## The Stray — CharacterBody3D controller.
## Reads from a ControllerProfile resource; all tunables live there.
## Coyote time, jump buffer, variable jump height, preserved horizontal velocity.

signal respawned

const BASE_GRAVITY: float = -30.0

@export var profile: ControllerProfile

## Node paths — set in the inspector or by the level scene.
@onready var _mesh: Node3D = $Visual
@onready var _camera_target: Marker3D = $CameraTarget

# Timers
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

# State flags
var _was_on_floor: bool = false
var _jump_cut_available: bool = false

# Respawn data
var _spawn_position: Vector3 = Vector3.ZERO
var _spawn_rotation: Vector3 = Vector3.ZERO

# References set by level
var _camera_rig: Node3D = null

# Debug — exposed to dev menu
var debug_show_velocity: bool = false


func _ready() -> void:
	_spawn_position = global_position
	_spawn_rotation = rotation
	up_direction = Vector3.UP
	floor_max_angle = deg_to_rad(profile.max_slope_degrees if profile else 45.0)
	Game.register_player(self)


func _physics_process(delta: float) -> void:
	if not profile:
		return

	_tick_coyote(delta)
	_tick_jump_buffer(delta)
	_apply_gravity(delta)
	_apply_horizontal(delta)
	_consume_jump_buffer()
	_apply_jump_cut()
	move_and_slide()
	_check_oob()
	_update_floor_state()


# ─── Gravity ─────────────────────────────────────────────────────────────────

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		# Snap small downward drift on floor so is_on_floor stays stable.
		if velocity.y < 0.0:
			velocity.y = 0.0
		return

	var mult: float = profile.gravity_multiplier if velocity.y >= 0.0 else profile.fall_gravity_multiplier
	velocity.y += BASE_GRAVITY * mult * delta
	velocity.y = max(velocity.y, profile.terminal_velocity)


# ─── Horizontal movement ──────────────────────────────────────────────────────

func _apply_horizontal(delta: float) -> void:
	var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir: Vector3 = _camera_relative_direction(input_vec)
	var on_floor: bool = is_on_floor()
	var accel: float = profile.acceleration if on_floor else profile.air_acceleration
	var decel: float = profile.deceleration if on_floor else profile.air_deceleration

	if move_dir.length_squared() > 0.01:
		var target_xz: Vector3 = move_dir * profile.speed
		velocity.x = move_toward(velocity.x, target_xz.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_xz.z, accel * delta)
		# Rotate mesh to face movement direction.
		if _mesh and move_dir.length_squared() > 0.001:
			var target_basis: Basis = Basis.looking_at(move_dir, Vector3.UP)
			_mesh.global_basis = _mesh.global_basis.slerp(target_basis, min(1.0, 12.0 * delta))
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)


func _camera_relative_direction(input: Vector2) -> Vector3:
	if _camera_rig == null:
		# Fallback: world-space (for editor testing without camera rig).
		return Vector3(input.x, 0.0, input.y).normalized()

	var cam_forward: Vector3 = -_camera_rig.get_camera_forward()
	var cam_right: Vector3 = _camera_rig.get_camera_right()
	cam_forward.y = 0.0
	cam_right.y = 0.0
	if cam_forward.length_squared() < 0.001:
		cam_forward = Vector3(0, 0, -1)
	if cam_right.length_squared() < 0.001:
		cam_right = Vector3(1, 0, 0)
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	return (cam_forward * -input.y + cam_right * input.x).normalized() if (cam_forward * -input.y + cam_right * input.x).length_squared() > 0.001 else Vector3.ZERO


# ─── Coyote time ─────────────────────────────────────────────────────────────

func _tick_coyote(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = profile.coyote_time
	elif _was_on_floor:
		# Just walked off — coyote window starts now (already set on previous floor frame).
		pass
	else:
		_coyote_timer -= delta


func _can_coyote_jump() -> bool:
	return _coyote_timer > 0.0 and not is_on_floor()


# ─── Jump buffer ─────────────────────────────────────────────────────────────

func _tick_jump_buffer(delta: float) -> void:
	_jump_buffer_timer -= delta


func request_jump() -> void:
	## Called by input layer when jump is pressed.
	_jump_buffer_timer = profile.jump_buffer_time


func _consume_jump_buffer() -> void:
	if _jump_buffer_timer <= 0.0:
		return
	if is_on_floor() or _can_coyote_jump():
		_execute_jump()


func _execute_jump() -> void:
	velocity.y = profile.jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jump_cut_available = true


# ─── Variable jump height (release-to-cut) ───────────────────────────────────

func _apply_jump_cut() -> void:
	if not _jump_cut_available:
		return
	if velocity.y <= 0.0:
		_jump_cut_available = false
		return
	if not Input.is_action_pressed("jump"):
		velocity.y *= profile.jump_cut_factor
		_jump_cut_available = false


# ─── Floor state tracking ─────────────────────────────────────────────────────

func _update_floor_state() -> void:
	_was_on_floor = is_on_floor()


# ─── Out-of-bounds / death ────────────────────────────────────────────────────

func _check_oob() -> void:
	if global_position.y < -25.0:
		respawn()


func respawn() -> void:
	global_position = _spawn_position
	rotation = _spawn_rotation
	velocity = Vector3.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jump_cut_available = false
	emit_signal("respawned")
	# TODO: trigger reboot animation — red flash → dark → fade in (juice stub)


func set_spawn_point(pos: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	_spawn_position = pos
	_spawn_rotation = rot


func set_camera_rig(rig: Node3D) -> void:
	_camera_rig = rig


# ─── Dev / debug ──────────────────────────────────────────────────────────────

func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()
