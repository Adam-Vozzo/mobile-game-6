extends Node3D
class_name CameraRig
## Third-person camera rig for the Stray. Behind-and-above by default,
## with horizontal-velocity lookahead, downward-vel vertical pull, manual
## right-drag override (consumed from TouchInput), and auto-recenter
## behind movement direction after a short idle window.
##
## Collision avoidance: a SpringArm3D child casts a sphere from the rig
## origin toward the camera position each frame. get_hit_length() returns
## the shortest safe distance, which _current_distance lerps toward so
## transitions are smooth rather than jarring. Camera3D is then placed
## manually at that distance and told to look_at the aim point.
##
## SpringArm3D rotation formula (see DECISIONS.md):
##   rotation = Vector3(|pitch|, yaw + PI, 0)
##   → local -Z points from rig_pos toward camera world-space position.

@export var target_path: NodePath = ^"../Player"

@export_category("Geometry")
@export_range(2.0, 15.0, 0.1) var distance: float = 6.0
@export_range(0.0, 80.0, 0.5) var pitch_degrees: float = 22.0
@export_range(0.0, 3.0, 0.05) var aim_height: float = 0.6

@export_category("Lookahead")
@export_range(0.0, 5.0, 0.05) var lookahead_distance: float = 1.2
@export_range(0.5, 20.0, 0.1) var lookahead_lerp: float = 4.0
@export_range(0.0, 5.0, 0.05) var lookahead_min_speed: float = 0.15

@export_category("Fall pull")
@export_range(0.0, 1.0, 0.01) var vertical_pull: float = 0.18

@export_category("Manual override")
@export_range(0.0001, 0.05, 0.0001) var yaw_drag_sens: float = 0.005
@export_range(0.0001, 0.05, 0.0001) var pitch_drag_sens: float = 0.003
@export_range(-89.0, 0.0, 1.0) var pitch_min_degrees: float = -55.0
@export_range(0.0, 89.0, 1.0) var pitch_max_degrees: float = 55.0

@export_category("Auto-recenter")
@export_range(0.0, 5.0, 0.05) var idle_recenter_delay: float = 1.2
@export_range(0.1, 10.0, 0.1) var idle_recenter_speed: float = 1.5
@export_range(0.0, 10.0, 0.1) var recenter_min_speed: float = 0.5

var _yaw: float = 0.0
var _pitch: float = 0.0
var _lookahead: Vector3 = Vector3.ZERO
var _last_drag_time: float = -1000.0
var _target: Node3D
var _current_distance: float = 0.0

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_pitch = -deg_to_rad(pitch_degrees)
	_target = get_node_or_null(target_path) as Node3D
	_current_distance = distance
	_spring_arm.spring_length = distance
	if has_node("/root/DevMenu"):
		DevMenu.camera_param_changed.connect(_on_camera_param_changed)


func _process(delta: float) -> void:
	if _target == null:
		return
	var now := Time.get_ticks_msec() / 1000.0

	var drag := TouchInput.consume_camera_drag_delta()
	if drag.length_squared() > 0.0:
		_yaw -= drag.x * yaw_drag_sens
		_pitch = clampf(_pitch - drag.y * pitch_drag_sens,
			-deg_to_rad(absf(pitch_min_degrees)),
			deg_to_rad(absf(pitch_max_degrees)))
		_last_drag_time = now

	var vel := _get_target_velocity()
	var horiz := Vector3(vel.x, 0.0, vel.z)
	var horiz_speed := horiz.length()

	if horiz_speed > recenter_min_speed and now - _last_drag_time > idle_recenter_delay:
		var desired_yaw := atan2(horiz.x, horiz.z)
		_yaw += wrapf(desired_yaw - _yaw, -PI, PI) * minf(1.0, idle_recenter_speed * delta)

	var desired_lookahead := Vector3.ZERO
	if horiz_speed > lookahead_min_speed:
		desired_lookahead = horiz.normalized() * lookahead_distance
	_lookahead = _lookahead.lerp(desired_lookahead, clampf(lookahead_lerp * delta, 0.0, 1.0))

	var vertical_offset := vel.y * vertical_pull * 0.05 if vel.y < 0.0 else 0.0
	var target_pos := _target.global_position
	var rig_pos := target_pos + _lookahead + Vector3(0.0, vertical_offset, 0.0)
	global_position = rig_pos

	var p := absf(_pitch)
	_tick_spring_arm(p, delta)
	var cam_dir := Basis(Vector3.UP, _yaw) * Vector3(0.0, sin(p), cos(p))
	_camera.global_position = rig_pos + cam_dir * _current_distance
	_camera.look_at(target_pos + Vector3(0.0, aim_height, 0.0), Vector3.UP)

	if _target.has_method("set_camera_yaw"):
		_target.set_camera_yaw(_yaw)


## Aims SpringArm3D toward the camera position, reads the collision-adjusted
## length (1-frame lag acceptable), and lerps _current_distance toward it.
func _tick_spring_arm(p: float, delta: float) -> void:
	# Euler YXZ: Ry(yaw + PI) · Rx(|pitch|) maps local -Z to camera direction.
	_spring_arm.spring_length = distance
	_spring_arm.rotation = Vector3(p, _yaw + PI, 0.0)
	var hit_len := _spring_arm.get_hit_length()
	var target_dist := distance if hit_len < 0.001 else hit_len
	var lerp_speed := 18.0 if target_dist < _current_distance else 5.0
	_current_distance = lerpf(_current_distance, target_dist,
		clampf(lerp_speed * delta, 0.0, 1.0))


func _get_target_velocity() -> Vector3:
	if _target is CharacterBody3D:
		return (_target as CharacterBody3D).velocity
	return Vector3.ZERO


func _on_camera_param_changed(param_name: StringName, value: float) -> void:
	match param_name:
		&"distance":
			distance = value
			_spring_arm.spring_length = value
		&"pitch_degrees":
			pitch_degrees = value
			_pitch = -deg_to_rad(pitch_degrees)
		&"yaw_drag_sens":
			yaw_drag_sens = value
		&"pitch_drag_sens":
			pitch_drag_sens = value
		&"lookahead_distance":
			lookahead_distance = value
		&"vertical_pull":
			vertical_pull = value
