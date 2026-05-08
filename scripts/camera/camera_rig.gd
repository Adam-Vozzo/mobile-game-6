extends Node3D
class_name CameraRig
## Third-person camera rig for the Stray. Behind-and-above by default,
## with horizontal-velocity lookahead, downward-vel vertical pull, manual
## right-drag override (consumed from TouchInput), and auto-recenter
## behind movement direction after a short idle window.
##
## SpringArm3D collision avoidance: the arm casts from the aim point toward
## the camera position and shortens on geometry contact, preventing clipping.
## The player's own collision shape is excluded from the cast.

@export var target_path: NodePath = ^"../Player"

@export_category("Geometry")
## Distance from the player along the back-and-up vector.
@export_range(2.0, 15.0, 0.1) var distance: float = 6.0
## Camera tilt below horizontal, degrees. Positive = looks down.
@export_range(0.0, 80.0, 0.5) var pitch_degrees: float = 22.0
## Vertical offset of the camera's aim point above the player's feet.
@export_range(0.0, 3.0, 0.05) var aim_height: float = 0.6
## Gap kept between camera and geometry when spring arm shortens.
@export_range(0.0, 1.0, 0.01) var wall_margin: float = 0.2

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

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera


func _ready() -> void:
	_pitch = -deg_to_rad(pitch_degrees)
	_target = get_node_or_null(target_path) as Node3D
	_spring_arm.spring_length = distance
	_spring_arm.margin = wall_margin
	# Exclude the player's capsule so the arm never detects the Stray as an
	# obstacle and incorrectly pulls the camera forward.
	if _target is CollisionObject3D:
		_spring_arm.add_excluded_object((_target as CollisionObject3D).get_rid())
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

	# --- Place rig at aim point ---
	var target_pos := _target.global_position
	var rig_pos := target_pos + _lookahead + Vector3(0.0, vertical_offset, 0.0)
	global_position = rig_pos

	# --- Orient spring arm so its +Z axis points toward the camera position ---
	# arm_dir: direction from aim point toward the desired camera offset.
	var p := absf(_pitch)
	var arm_dir := (Basis(Vector3.UP, _yaw) * Vector3(0.0, sin(p), cos(p))).normalized()
	_spring_arm.spring_length = distance

	# Basis.looking_at(dir) makes -Z face dir, so negating arm_dir makes +Z
	# face arm_dir.  Guard against near-vertical arm where UP and arm_dir are
	# nearly parallel (would produce a degenerate cross product).
	var safe_up := Vector3(0.0, 0.0, 1.0) \
		if arm_dir.abs().dot(Vector3.UP) > 0.999 \
		else Vector3.UP
	_spring_arm.global_basis = Basis.looking_at(-arm_dir, safe_up)

	# SpringArm3D positions the Camera child at hit_length along +Z each frame.
	# We call look_at here; spring arm updates camera position after us in the
	# same frame (child processes after parent), so look_at uses last frame's
	# spring-corrected position — one-frame lag is imperceptible on smooth motion.
	_camera.look_at(target_pos + Vector3(0.0, aim_height, 0.0), Vector3.UP)

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
		&"wall_margin":
			wall_margin = value
			if _spring_arm != null:
				_spring_arm.margin = value
