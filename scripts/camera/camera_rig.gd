extends Node3D
class_name CameraRig
## Third-person camera rig for the Stray. Behind-and-above by default,
## with horizontal-velocity lookahead, downward-vel vertical pull, manual
## right-drag override (consumed from TouchInput), and auto-recenter
## behind movement direction after a short idle window.
##
## CLAUDE.md flagged camera fiddling on mobile as the single biggest
## Dadish-3D pain point — the recenter behaviour is the answer to that.
##
## Occlusion avoidance: a ray cast from the look-at point to the desired
## camera position each frame; if geometry blocks the shot the camera
## pulls forward to the hit point minus `occlusion_margin`. No SpringArm3D
## node is needed — using PhysicsDirectSpaceState3D lets us exclude the
## player body and reuse the existing position maths exactly.
## See docs/DECISIONS.md for the SpringArm3D vs. raycast rationale.

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

@export_category("Occlusion")
## Gap kept between the camera and any occluder surface.
@export_range(0.1, 1.0, 0.05) var occlusion_margin: float = 0.3
## Minimum distance the camera is allowed to snap to (prevents camera
## burying in the player when inside a tight space).
@export_range(0.3, 3.0, 0.05) var occlusion_min_distance: float = 0.8
## Physics layer mask queried for occlusion (default: layer 1 = world).
@export_flags_3d_physics var occlusion_mask: int = 1

var _yaw: float = 0.0
var _pitch: float = 0.0  # radians, negative = looking down
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
	var vel := _get_target_velocity()
	var horiz := Vector3(vel.x, 0.0, vel.z)

	_apply_drag_input(now)
	_update_yaw_recenter(horiz, now, delta)
	_update_lookahead(horiz, delta)

	var target_pos := _target.global_position
	var vertical_offset := _vertical_pull_offset(vel.y)
	var rig_pos := target_pos + _lookahead + Vector3(0.0, vertical_offset, 0.0)
	global_position = rig_pos

	var aim_point := target_pos + Vector3(0.0, aim_height, 0.0)
	var desired_cam_pos := _desired_camera_position(rig_pos)
	_camera.global_position = _occlude(aim_point, desired_cam_pos)
	_camera.look_at(aim_point, Vector3.UP)

	if _target.has_method("set_camera_yaw"):
		_target.set_camera_yaw(_yaw)


func _apply_drag_input(now: float) -> void:
	var drag := TouchInput.consume_camera_drag_delta()
	if drag.length_squared() > 0.0:
		_yaw -= drag.x * yaw_drag_sens
		_pitch = clampf(_pitch - drag.y * pitch_drag_sens,
			-deg_to_rad(absf(pitch_min_degrees)),
			deg_to_rad(absf(pitch_max_degrees)))
		_last_drag_time = now


func _update_yaw_recenter(horiz: Vector3, now: float, delta: float) -> void:
	var horiz_speed := horiz.length()
	if horiz_speed > recenter_min_speed and now - _last_drag_time > idle_recenter_delay:
		var desired_yaw := atan2(horiz.x, horiz.z)
		var diff := wrapf(desired_yaw - _yaw, -PI, PI)
		_yaw += diff * minf(1.0, idle_recenter_speed * delta)


func _update_lookahead(horiz: Vector3, delta: float) -> void:
	var horiz_speed := horiz.length()
	var desired_lookahead := Vector3.ZERO
	if horiz_speed > lookahead_min_speed:
		desired_lookahead = horiz.normalized() * lookahead_distance
	_lookahead = _lookahead.lerp(desired_lookahead,
		clampf(lookahead_lerp * delta, 0.0, 1.0))


# 0.05 converts the pull multiplier from "fraction of velocity" to metres of
# camera offset — keeps vertical_pull in a 0–1 inspector range.
func _vertical_pull_offset(vel_y: float) -> float:
	if vel_y >= 0.0:
		return 0.0
	return vel_y * vertical_pull * 0.05


func _desired_camera_position(rig_pos: Vector3) -> Vector3:
	var p := absf(_pitch)
	var local_offset := Vector3(0.0, sin(p) * distance, cos(p) * distance)
	return rig_pos + Basis(Vector3.UP, _yaw) * local_offset


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
	if _target:
		var excl: Array[RID] = [_target.get_rid()]
		params.exclude = excl
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return desired
	var dir := (desired - aim).normalized()
	var hit_dist := (hit.position - aim).length()
	var safe_dist := maxf(occlusion_min_distance, hit_dist - occlusion_margin)
	return aim + dir * safe_dist


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
		&"idle_recenter_delay":
			idle_recenter_delay = value
		&"idle_recenter_speed":
			idle_recenter_speed = value
		&"occlusion_margin":
			occlusion_margin = value
