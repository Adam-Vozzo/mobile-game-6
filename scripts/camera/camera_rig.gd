extends Node3D
class_name CameraRig
## Third-person camera rig for the Stray. Behind-and-above by default,
## with horizontal-velocity lookahead, downward-vel vertical pull, manual
## right-drag override (consumed from TouchInput), auto-recenter
## behind movement direction after a short idle window, and ray-cast-based
## collision avoidance so the camera never clips through walls.

@export var target_path: NodePath = ^"../Player"

@export_category("Geometry")
## Distance from the player along the back-and-up vector.
@export_range(2.0, 15.0, 0.1) var distance: float = 6.0
## Camera tilt below horizontal, degrees. Positive = looks down.
@export_range(0.0, 80.0, 0.5) var pitch_degrees: float = 22.0
## Vertical offset of the camera's aim point above the player's feet.
@export_range(0.0, 3.0, 0.05) var aim_height: float = 0.6
## Camera field of view in degrees.
@export_range(40.0, 120.0, 1.0) var fov: float = 60.0

@export_category("Lookahead")
## How far ahead of the player (in the horizontal velocity direction) the rig pulls.
@export_range(0.0, 5.0, 0.05) var lookahead_distance: float = 1.2
## Lerp speed toward the lookahead target. Higher = snappier.
@export_range(0.5, 20.0, 0.1) var lookahead_lerp: float = 4.0
## Below this horizontal speed (m/s) lookahead decays to zero.
@export_range(0.0, 5.0, 0.05) var lookahead_min_speed: float = 0.15

@export_category("Fall pull")
## Multiplier applied to negative Y velocity to drop the aim point while falling.
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

@export_category("Collision")
## Gap kept between the camera and any occluding surface.
@export_range(0.0, 1.0, 0.05) var collision_margin: float = 0.15
## Physics layers the camera avoids. Layer 1 = World.
@export_flags_3d_physics var collision_mask: int = 1

var _yaw: float = 0.0
var _pitch: float = 0.0
var _lookahead: Vector3 = Vector3.ZERO
var _last_drag_time: float = -1000.0
var _target: Node3D

@onready var _camera: Camera3D = $Camera


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

	# --- Pivot: player + lookahead + vertical pull ---
	var target_pos := _target.global_position
	var pivot := target_pos + _lookahead + Vector3(0.0, vertical_offset, 0.0)
	global_position = pivot

	# --- Desired camera position: behind-and-above via yaw + pitch ---
	var p := absf(_pitch)
	var yaw_basis := Basis(Vector3.UP, _yaw)
	var local_offset := Vector3(0.0, sin(p) * distance, cos(p) * distance)
	var desired_cam_pos := pivot + yaw_basis * local_offset

	# --- Collision avoidance: shorten the arm if a wall blocks the view ---
	var actual_cam_pos := _occlude(pivot, desired_cam_pos)

	_camera.global_position = actual_cam_pos
	_camera.look_at(target_pos + Vector3(0.0, aim_height, 0.0), Vector3.UP)
	_camera.fov = fov

	# --- Publish yaw to player so input is camera-relative ---
	if _target.has_method("set_camera_yaw"):
		_target.set_camera_yaw(_yaw)


## Casts a ray from `from` toward `to`. If something is in the way, returns
## a point just in front of the hit surface. Otherwise returns `to`.
func _occlude(from: Vector3, to: Vector3) -> Vector3:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return to
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	if _target is CollisionObject3D:
		query.exclude = [(_target as CollisionObject3D).get_rid()]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return to
	var dir := (to - from).normalized()
	return (result["position"] as Vector3) - dir * collision_margin


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
		&"fov":
			fov = value
		&"yaw_drag_sens":
			yaw_drag_sens = value
		&"pitch_drag_sens":
			pitch_drag_sens = value
		&"lookahead_distance":
			lookahead_distance = value
		&"vertical_pull":
			vertical_pull = value
		&"idle_recenter_delay":
			idle_recenter_delay = value
		&"idle_recenter_speed":
			idle_recenter_speed = value
