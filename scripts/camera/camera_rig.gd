extends Node3D
class_name CameraRig
## Tripod-style follow camera. The camera holds its world position when the
## player moves laterally, rotating in place (via look_at) to keep the player
## centered. Only forward/backward motion (along the camera-to-player axis)
## translates the camera, and only enough to maintain the configured distance.
## This eliminates the lateral background slide that caused motion sickness
## with the previous behind-the-shoulder rig.
##
## Manual right-drag (or touch drag from the overlay) orbits the camera around
## the player; pitch and yaw are derived live from the camera's relative
## position rather than stored as authoritative state.
##
## Occlusion: ray cast from the aim point to the desired camera position; if
## blocked, the camera snaps to the hit point minus `occlusion_margin`.

@export var target_path: NodePath = ^"../Player"

@export_category("Geometry")
## Horizontal distance the camera tries to maintain from the player. The
## camera only moves along the camera-to-player axis to enforce this — lateral
## drift from the player walking sideways is absorbed by rotation.
@export_range(2.0, 15.0, 0.1) var distance: float = 6.0
## Camera tilt below horizontal, degrees. Drives the camera's height above
## the player and the look-down angle. Manual pitch drag overrides at runtime.
@export_range(0.0, 80.0, 0.5) var pitch_degrees: float = 22.0
## Vertical offset of the look-at point above the player's feet.
@export_range(0.0, 3.0, 0.05) var aim_height: float = 0.6

@export_category("Fall pull")
## Multiplier applied to the player's negative Y velocity to drop the
## camera while falling. Helps the player see what's below.
@export_range(0.0, 1.0, 0.01) var vertical_pull: float = 0.18

@export_category("Manual override")
@export_range(0.0001, 0.05, 0.0001) var yaw_drag_sens: float = 0.005
@export_range(0.0001, 0.05, 0.0001) var pitch_drag_sens: float = 0.003
@export_range(-89.0, 0.0, 1.0) var pitch_min_degrees: float = -55.0
@export_range(0.0, 89.0, 1.0) var pitch_max_degrees: float = 55.0

@export_category("Occlusion")
@export_range(0.1, 1.0, 0.05) var occlusion_margin: float = 0.3
@export_range(0.3, 3.0, 0.05) var occlusion_min_distance: float = 0.8
@export_flags_3d_physics var occlusion_mask: int = 1

var _target: Node3D
var _initialized: bool = false
# Working pitch in radians, negative = looking down. Initialised from
# `pitch_degrees` and updated by manual drag.
var _pitch_rad: float = 0.0

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_pitch_rad = -deg_to_rad(pitch_degrees)
	_target = get_node_or_null(target_path) as Node3D
	if has_node("/root/DevMenu"):
		DevMenu.camera_param_changed.connect(_on_camera_param_changed)


func _process(_delta: float) -> void:
	if _target == null:
		return
	var target_pos := _target.global_position
	var aim_point := target_pos + Vector3(0.0, aim_height, 0.0)

	if not _initialized:
		_place_camera_initial(target_pos)
		_initialized = true

	_apply_drag_input(target_pos)

	# Constrain camera to (distance, height) but only along the current
	# camera-to-player axis. Lateral player motion is absorbed by look_at.
	var cam_pos := _camera.global_position
	var horiz := Vector3(target_pos.x - cam_pos.x, 0.0, target_pos.z - cam_pos.z)
	var current_dist := horiz.length()
	if current_dist > 0.001:
		var dir := horiz / current_dist
		var dist_error := current_dist - distance
		cam_pos.x += dir.x * dist_error
		cam_pos.z += dir.z * dist_error
	var fall_offset := _vertical_pull_offset(_get_target_velocity().y)
	cam_pos.y = target_pos.y + sin(absf(_pitch_rad)) * distance + aim_height + fall_offset

	_camera.global_position = _occlude(aim_point, cam_pos)
	_camera.look_at(aim_point, Vector3.UP)

	# Publish the yaw the player should rotate input by. We want stick-up to
	# move the player away from the camera, so the published yaw is the angle
	# from the player to the camera (atan2(cam.x - player.x, cam.z - player.z)).
	# Use call() because _target is typed Node3D — Player adds set_camera_yaw.
	if _target.has_method("set_camera_yaw"):
		var pub_yaw := atan2(
			_camera.global_position.x - target_pos.x,
			_camera.global_position.z - target_pos.z)
		_target.call(&"set_camera_yaw", pub_yaw)


func _place_camera_initial(target_pos: Vector3) -> void:
	_camera.global_position = target_pos + Vector3(
		0.0,
		sin(absf(_pitch_rad)) * distance + aim_height,
		cos(absf(_pitch_rad)) * distance,
	)


# Drag rotates the camera around the player. Yaw orbits in the XZ plane;
# pitch tilts the camera up/down while preserving the horizontal radius.
# We re-derive theta/phi from the current camera position each call so the
# camera's geometric drift along the look axis stays consistent with drag.
func _apply_drag_input(target_pos: Vector3) -> void:
	var drag := TouchInput.consume_camera_drag_delta()
	if drag.length_squared() == 0.0:
		return
	var to_cam := _camera.global_position - target_pos
	var radius := to_cam.length()
	if radius < 0.001:
		return
	var theta := atan2(to_cam.x, to_cam.z)
	var phi := asin(clampf(to_cam.y / radius, -1.0, 1.0))
	theta -= drag.x * yaw_drag_sens
	phi = clampf(
		phi - drag.y * pitch_drag_sens,
		deg_to_rad(pitch_min_degrees),
		deg_to_rad(pitch_max_degrees),
	)
	_pitch_rad = -phi  # negative = looking down
	var cos_phi := cos(phi)
	_camera.global_position = target_pos + Vector3(
		radius * cos_phi * sin(theta),
		radius * sin(phi),
		radius * cos_phi * cos(theta),
	)


# 0.05 converts the pull multiplier from "fraction of velocity" to metres of
# camera offset — keeps vertical_pull in a 0–1 inspector range.
func _vertical_pull_offset(vel_y: float) -> float:
	if vel_y >= 0.0:
		return 0.0
	return vel_y * vertical_pull * 0.05


func _get_target_velocity() -> Vector3:
	if _target is CharacterBody3D:
		return (_target as CharacterBody3D).velocity
	return Vector3.ZERO


## Returns the camera position to use after checking for occluding geometry.
## Casts a ray from `aim` (what the camera focuses on) to `desired`; if
## something is in the way, snaps the camera to the hit point minus the
## occlusion margin, floored at occlusion_min_distance from aim.
func _occlude(aim: Vector3, desired: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.new()
	params.from = aim
	params.to = desired
	params.collision_mask = occlusion_mask
	if _target is PhysicsBody3D:
		var excl: Array[RID] = [(_target as PhysicsBody3D).get_rid()]
		params.exclude = excl
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return desired
	var dir := (desired - aim).normalized()
	var hit_pos: Vector3 = hit.position
	var hit_dist := (hit_pos - aim).length()
	var safe_dist := maxf(occlusion_min_distance, hit_dist - occlusion_margin)
	return aim + dir * safe_dist


func _on_camera_param_changed(param_name: StringName, value: float) -> void:
	match param_name:
		&"distance":
			distance = value
		&"pitch_degrees":
			pitch_degrees = value
			_pitch_rad = -deg_to_rad(pitch_degrees)
		&"yaw_drag_sens":
			yaw_drag_sens = value
		&"pitch_drag_sens":
			pitch_drag_sens = value
		&"vertical_pull":
			vertical_pull = value
		&"occlusion_margin":
			occlusion_margin = value
		# Lookahead and auto-recenter sliders are no-ops in the tripod model.
		_:
			pass
