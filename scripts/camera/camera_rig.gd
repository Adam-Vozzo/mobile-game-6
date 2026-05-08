class_name CameraRig
extends Node3D

## Third-person camera rig.
## Follows a target node. SpringArm3D handles wall collision.
## Lookahead in horizontal velocity direction.
## Right-side touch drag for manual yaw/pitch override.
## Auto-recenters behind player after idle_recenter_delay seconds.

@export var target: Node3D = null

@export_group("Follow")
@export var follow_speed: float = 8.0
@export var follow_vertical_speed: float = 5.0

@export_group("Spring Arm")
@export var arm_length: float = 6.0
@export var arm_length_min: float = 2.0
@export var camera_height_offset: float = 1.5

@export_group("Lookahead")
@export var lookahead_strength: float = 1.8
@export var lookahead_speed: float = 4.0

@export_group("Pitch limits (degrees)")
@export var pitch_min: float = -20.0
@export var pitch_max: float = 50.0

@export_group("Touch drag")
@export var drag_sensitivity_x: float = 0.3
@export var drag_sensitivity_y: float = 0.2

@export_group("Auto-recenter")
@export var idle_recenter_delay: float = 2.5
@export var recenter_speed: float = 2.0

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D

var _yaw: float = 0.0
var _pitch: float = 15.0
var _lookahead_offset: Vector3 = Vector3.ZERO
var _idle_timer: float = 0.0
var _is_manually_controlled: bool = false

# Touch drag state
var _drag_touch_index: int = -1
var _drag_last_pos: Vector2 = Vector2.ZERO
var _drag_zone_min_x_ratio: float = 0.5  # Right half of screen


func _ready() -> void:
	_spring_arm.spring_length = arm_length
	_spring_arm.margin = 0.2
	Game.register_camera(self)


func _process(delta: float) -> void:
	if target == null:
		return

	_update_follow(delta)
	_update_lookahead(delta)
	_update_idle_recenter(delta)
	_apply_arm_rotation()


func _input(event: InputEvent) -> void:
	_handle_touch_drag(event)
	# Keyboard rotation for editor testing.
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_yaw -= event.relative.x * drag_sensitivity_x
		_pitch -= event.relative.y * drag_sensitivity_y
		_pitch = clamp(_pitch, pitch_min, pitch_max)
		_idle_timer = 0.0
		_is_manually_controlled = true


# ─── Follow ───────────────────────────────────────────────────────────────────

func _update_follow(delta: float) -> void:
	var target_pos: Vector3 = target.global_position + Vector3(0, camera_height_offset, 0)
	var lerp_xz: float = clamp(follow_speed * delta, 0.0, 1.0)
	var lerp_y: float = clamp(follow_vertical_speed * delta, 0.0, 1.0)

	global_position.x = lerp(global_position.x, target_pos.x + _lookahead_offset.x, lerp_xz)
	global_position.z = lerp(global_position.z, target_pos.z + _lookahead_offset.z, lerp_xz)
	global_position.y = lerp(global_position.y, target_pos.y, lerp_y)


# ─── Lookahead ────────────────────────────────────────────────────────────────

func _update_lookahead(delta: float) -> void:
	if not target is CharacterBody3D:
		return
	var player: CharacterBody3D = target as CharacterBody3D
	var horiz_vel: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var target_offset: Vector3 = horiz_vel.normalized() * min(horiz_vel.length(), 10.0) * lookahead_strength * 0.1
	_lookahead_offset = _lookahead_offset.lerp(target_offset, clamp(lookahead_speed * delta, 0.0, 1.0))


# ─── Recenter ─────────────────────────────────────────────────────────────────

func _update_idle_recenter(delta: float) -> void:
	if not _is_manually_controlled:
		return

	# Count idle time only when player is roughly stationary.
	if target is CharacterBody3D:
		var spd: float = Vector2((target as CharacterBody3D).velocity.x, (target as CharacterBody3D).velocity.z).length()
		if spd < 0.5:
			_idle_timer += delta
		else:
			_idle_timer = 0.0
	else:
		_idle_timer += delta

	if _idle_timer >= idle_recenter_delay:
		# Smoothly recenter yaw behind player movement direction.
		var player_yaw: float = _get_player_yaw()
		var yaw_diff: float = wrapf(player_yaw - _yaw, -180.0, 180.0)
		_yaw += yaw_diff * clamp(recenter_speed * delta, 0.0, 1.0)
		if abs(yaw_diff) < 1.0:
			_is_manually_controlled = false
			_idle_timer = 0.0


func _get_player_yaw() -> float:
	if target == null:
		return _yaw
	if not target is CharacterBody3D:
		return _yaw
	var vel: Vector3 = (target as CharacterBody3D).velocity
	if Vector2(vel.x, vel.z).length() < 0.5:
		return _yaw
	return rad_to_deg(atan2(vel.x, vel.z))


# ─── Arm rotation ─────────────────────────────────────────────────────────────

func _apply_arm_rotation() -> void:
	rotation_degrees.y = _yaw
	_spring_arm.rotation_degrees.x = -_pitch


# ─── Touch drag ───────────────────────────────────────────────────────────────

func _handle_touch_drag(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event as InputEventScreenTouch
		if e.pressed:
			# Only claim touches in the right half of the screen.
			if e.position.x / get_viewport().get_visible_rect().size.x >= _drag_zone_min_x_ratio:
				if _drag_touch_index == -1:
					_drag_touch_index = e.index
					_drag_last_pos = e.position
					_is_manually_controlled = true
					_idle_timer = 0.0
		else:
			if e.index == _drag_touch_index:
				_drag_touch_index = -1

	elif event is InputEventScreenDrag:
		var e: InputEventScreenDrag = event as InputEventScreenDrag
		if e.index == _drag_touch_index:
			var delta_pos: Vector2 = e.position - _drag_last_pos
			_yaw -= delta_pos.x * drag_sensitivity_x
			_pitch -= delta_pos.y * drag_sensitivity_y
			_pitch = clamp(_pitch, pitch_min, pitch_max)
			_drag_last_pos = e.position
			_idle_timer = 0.0


# ─── Accessors used by player.gd ─────────────────────────────────────────────

func get_camera_forward() -> Vector3:
	return -_camera.global_basis.z


func get_camera_right() -> Vector3:
	return _camera.global_basis.x
