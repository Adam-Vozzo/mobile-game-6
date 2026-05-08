extends Node3D
class_name CameraRig
## Third-person camera rig for the Stray. Behind-and-above by default,
## with horizontal-velocity lookahead, downward-vel vertical pull, manual
## right-drag override (consumed from TouchInput), and auto-recenter
## behind movement direction after a short idle window.
##
## Wall occlusion is handled by SpringArm3D: the arm sweeps from the pivot
## toward the desired camera position and shortens on collision, so the
## camera never clips into walls. Camera look_at is called after the arm
## positions the child each frame.

@export var target_path: NodePath = ^"../Player"

@export_category("Geometry")
## Distance from the player along the back-and-up vector.
@export_range(2.0, 15.0, 0.1) var distance: float = 6.0
## Camera tilt below horizontal, degrees. Positive = looks down.
@export_range(0.0, 80.0, 0.5) var pitch_degrees: float = 22.0
## Vertical offset of the camera's aim point above the player's feet.
@export_range(0.0, 3.0, 0.05) var aim_height: float = 0.6

@export_category("Lookahead")
## How far ahead of the player (in the horizontal velocity direction)
## the rig pulls before settling.
@export_range(0.0, 5.0, 0.05) var lookahead_distance: float = 1.2
## Lerp speed toward the lookahead target. Higher = snappier.
@export_range(0.5, 20.0, 0.1) var lookahead_lerp: float = 4.0
## Below this horizontal speed (m/s) lookahead decays to zero.
@export_range(0.0, 5.0, 0.05) var lookahead_min_speed: float = 0.15

@export_category("Fall pull")
## Multiplier applied to the player's negative Y velocity to drop the
## camera target while falling. Helps the player see what's below.
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
var _pitch: float = 0.0  # radians, negative = looking down
var _lookahead: Vector3 = Vector3.ZERO
var _last_drag_time: float = -1000.0
var _target: Node3D

@onready var _spring_arm: SpringArm3D = $SpringArm
@onready var _camera: Camera3D = $SpringArm/Camera


func _ready() -> void:
	_pitch = -deg_to_rad(pitch_degrees)
	_target = get_node_or_null(target_path) as Node3D
	if has_node("/root/DevMenu"):
		DevMenu.camera_param_changed.connect(_on_camera_param_changed)


func _process(delta: float) -> void:
	if _target == null:
		return
	var now := Time.get_ticks_msec() / 1000.0

	# --- Manual drag override ---
	var drag := TouchInput.consume_camera_drag_delta()
	if drag.length_squared() > 0.0:
		_yaw -= drag.x * yaw_drag_sens
		_pitch = clampf(_pitch - drag.y * pitch_drag_sens,
			-deg_to_rad(absf(pitch_min_degrees)),
			deg_to_rad(absf(pitch_max_degrees)))
		_last_drag_time = now

	# --- Velocity sample ---
	var vel := _get_target_velocity()
	var horiz := Vector3(vel.x, 0.0, vel.z)
	var horiz_speed := horiz.length()

	# --- Auto-recenter behind movement direction after idle ---
	if horiz_speed > recenter_min_speed and now - _last_drag_time > idle_recenter_delay:
		var desired_yaw := atan2(horiz.x, horiz.z)
		var diff := wrapf(desired_yaw - _yaw, -PI, PI)
		_yaw += diff * minf(1.0, idle_recenter_speed * delta)

	# --- Lookahead lerp ---
	var desired_lookahead := Vector3.ZERO
	if horiz_speed > lookahead_min_speed:
		desired_lookahead = horiz.normalized() * lookahead_distance
	_lookahead = _lookahead.lerp(desired_lookahead,
		clampf(lookahead_lerp * delta, 0.0, 1.0))

	# --- Vertical pull when falling ---
	var vertical_offset := 0.0
	if vel.y < 0.0:
		vertical_offset = vel.y * vertical_pull * 0.05

	# --- Orient SpringArm from pivot toward desired camera position ---
	# The arm's +Z axis points from the player outward toward the camera.
	# SpringArm3D moves its children to local (0, 0, spring_length) and
	# shortens that length when the sweep hits geometry.
	var target_pos := _target.global_position
	var pivot := target_pos + _lookahead + Vector3(0.0, vertical_offset, 0.0)

	var p := absf(_pitch)
	var yaw_basis := Basis(Vector3.UP, _yaw)
	# back_dir: world-space direction from player toward camera (behind+above).
	var back_dir := yaw_basis * Vector3(0.0, sin(p), cos(p))

	# Build an orthonormal basis with +Z = back_dir.
	# Degenerate case (straight up/down) falls back to yaw-right.
	var right := back_dir.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = yaw_basis * Vector3.RIGHT
	right = right.normalized()
	var arm_up := right.cross(back_dir).normalized()
	_spring_arm.global_transform = Transform3D(Basis(right, arm_up, back_dir), pivot)
	_spring_arm.spring_length = distance

	# Camera look_at: SpringArm3D is a child, so it moves Camera in its own
	# _process which fires AFTER this parent's. look_at runs from last frame's
	# spring-corrected position — one frame behind, imperceptible at 60 fps.
	var look_target := target_pos + Vector3(0.0, aim_height, 0.0)
	if _camera.global_position.distance_squared_to(look_target) > 0.0001:
		_camera.look_at(look_target, Vector3.UP)

	# --- Publish yaw to player so input is camera-relative ---
	if _target.has_method("set_camera_yaw"):
		_target.set_camera_yaw(_yaw)


func _get_target_velocity() -> Vector3:
	if _target is CharacterBody3D:
		return (_target as CharacterBody3D).velocity
	return Vector3.ZERO


func _on_camera_param_changed(param_name: StringName, value: float) -> void:
	match param_name:
		&"distance":
			distance = value
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
