class_name Player
extends CharacterBody3D

# --- Movement ---
@export_group("Movement")
@export var walk_speed: float = 6.0
@export var acceleration_ground: float = 25.0
@export var friction_ground: float = 20.0
@export var acceleration_air: float = 8.0
@export var friction_air: float = 3.0

# --- Jump ---
@export_group("Jump")
@export var jump_velocity: float = 9.0
@export var gravity_rise: float = 28.0
@export var gravity_fall: float = 40.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.10

# --- State ---
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

signal landed

func _ready() -> void:
	add_to_group("player")
	_register_dev_menu()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	var was_airborne := not is_on_floor()
	move_and_slide()
	if was_airborne and is_on_floor():
		landed.emit()

# --- Private ---

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if InputManager.is_jump_just_pressed():
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var grav: float = gravity_rise if velocity.y > 0.0 else gravity_fall
	velocity.y -= grav * delta

func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

func _handle_movement(delta: float) -> void:
	var input := InputManager.get_move_vector()
	var cam_basis := _camera_flat_basis()
	var dir := (cam_basis * Vector3(input.x, 0.0, input.y)).normalized()

	var accel: float = acceleration_ground if is_on_floor() else acceleration_air
	var fric: float = friction_ground if is_on_floor() else friction_air

	if dir.length_squared() > 0.0001:
		velocity.x = move_toward(velocity.x, dir.x * walk_speed, accel * delta)
		velocity.z = move_toward(velocity.z, dir.z * walk_speed, accel * delta)
		if is_on_floor():
			var target_yaw := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)
		velocity.z = move_toward(velocity.z, 0.0, fric * delta)

func _camera_flat_basis() -> Basis:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Basis.IDENTITY
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Basis.IDENTITY
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	return Basis(right, Vector3.UP, -forward)

func _register_dev_menu() -> void:
	if not has_node("/root/DevMenu"):
		return
	var dm := get_node("/root/DevMenu")
	dm.register_float("Physics", "Walk Speed", self, "walk_speed", 1.0, 15.0)
	dm.register_float("Physics", "Jump Velocity", self, "jump_velocity", 3.0, 20.0)
	dm.register_float("Physics", "Gravity Rise", self, "gravity_rise", 10.0, 60.0)
	dm.register_float("Physics", "Gravity Fall", self, "gravity_fall", 10.0, 80.0)
	dm.register_float("Physics", "Coyote Time", self, "coyote_time", 0.0, 0.3)
	dm.register_float("Physics", "Jump Buffer", self, "jump_buffer_time", 0.0, 0.3)
	dm.register_float("Physics", "Accel Ground", self, "acceleration_ground", 5.0, 60.0)
	dm.register_float("Physics", "Friction Ground", self, "friction_ground", 5.0, 60.0)
