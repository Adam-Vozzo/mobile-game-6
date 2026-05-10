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
## Layers queried for camera occlusion. Defaults to layer 7 = `CameraOccluder`
## only — tag bodies that should hide the player from view (walls, pillars,
## big architecture) on this layer. Common gameplay obstacles like small
## platforms stay off it, so the camera doesn't push in every time the player
## passes behind them.
@export_flags_3d_physics var occlusion_mask: int = 1 << 6
## Radius of the sphere cast used to detect occluders. A small sphere (≥ ~0.1)
## absorbs frame-to-frame ray jitter at wall edges, which is what causes the
## camera to flicker between "occluded" and "clear" each frame. 0 falls back
## to a single ray (the old behaviour, prone to flicker near corners).
@export_range(0.0, 0.5, 0.01) var occlusion_probe_radius: float = 0.22

@export_category("Smoothing")
## Position-follow rate when the camera is moving toward the player — i.e.
## an occluder just entered the line of sight and the camera needs to pull
## in. High = quick reveal, no period where the player is hidden.
@export_range(1.0, 60.0, 0.5) var pull_in_smoothing: float = 28.0
## Position-follow rate when the camera is moving away from the player — i.e.
## an occluder cleared and the camera can fall back to full distance. Low =
## no bounce when grazing corner edges, which would otherwise toggle the
## occlusion result one frame at a time.
@export_range(0.5, 60.0, 0.5) var ease_out_smoothing: float = 6.0
## How long, in seconds, the camera stays in its "occluded" pose after the
## probe stops detecting an occluder. A walk past a wall corner can flicker
## the probe between hit and clear; this latch keeps the camera pulled in
## until the path has been clear for the full delay, eliminating the bounce.
@export_range(0.0, 0.6, 0.01) var occlusion_release_delay: float = 0.18

var _target: Node3D
var _initialized: bool = false
# Working pitch in radians, always ≤ 0 (0 = horizontal, negative = camera
# above player). Negated to get the elevation angle. Initialised from
# `pitch_degrees`; updated by manual drag. Kept ≤ 0 to avoid the V-shape
# the old `absf(_pitch)` formula produced as drag crossed horizontal
# (see iter 22 in main).
var _pitch_rad: float = 0.0
# Hysteresis state for occlusion. `_is_occluded` latches true on any hit and
# only clears after `occlusion_release_delay` seconds of consecutive misses.
# `_last_occluded_pos` is the pose the camera holds while latched.
var _is_occluded: bool = false
var _clear_streak_seconds: float = 0.0
var _last_occluded_pos: Vector3 = Vector3.ZERO
# Camera position offset from the player, refreshed every frame. While the
# player is airborne, this offset is held constant and the camera's world
# position is reconstructed as `target_pos + _air_offset` — a rigid translate
# that follows the jumping player without rotating around them.
var _air_offset: Vector3 = Vector3.ZERO

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_pitch_rad = -deg_to_rad(pitch_degrees)
	_target = get_node_or_null(target_path) as Node3D
	if has_node("/root/DevMenu"):
		DevMenu.camera_param_changed.connect(_on_camera_param_changed)


func _process(delta: float) -> void:
	if _target == null:
		return
	var target_pos := _target.global_position
	var aim_point := target_pos + Vector3(0.0, aim_height, 0.0)

	if not _initialized:
		_place_camera_initial(target_pos)
		_air_offset = _camera.global_position - target_pos
		_initialized = true

	# Airborne: rigid follow. Reconstruct the camera position as
	# `target_pos + _air_offset` *before* drag/look_at runs, so any movement
	# the player did this frame is reflected as a pure translation. The
	# offset itself is captured at the end of the previous (grounded) frame,
	# so the camera→player vector is preserved across the entire jump and
	# look_at gives the same basis frame after frame — no yaw or pitch
	# rotation while airborne. Drag and landing both update the offset
	# correctly via the unified end-of-frame save below.
	var on_floor := _is_target_on_floor()
	if not on_floor:
		_camera.global_position = target_pos + _air_offset

	_apply_drag_input(target_pos)

	if on_floor:
		# Ground: tripod-style distance maintenance + occlusion + smoothing.
		var cam_pos := _camera.global_position
		var horiz := Vector3(target_pos.x - cam_pos.x, 0.0, target_pos.z - cam_pos.z)
		var current_dist := horiz.length()
		if current_dist > 0.001:
			var dir := horiz / current_dist
			var dist_error := current_dist - distance
			cam_pos.x += dir.x * dist_error
			cam_pos.z += dir.z * dist_error
		var fall_offset := _vertical_pull_offset(_get_target_velocity().y)
		# `_pitch_rad` is ≤ 0; -_pitch_rad is the elevation angle. Using `absf`
		# would V-shape as the drag crosses horizontal — see iter 22 fix on main.
		var elevation := -_pitch_rad
		cam_pos.y = target_pos.y + sin(elevation) * distance + aim_height + fall_offset

		# Probe for occlusion, then apply a hysteresis latch: any hit re-arms
		# the "occluded" state for `occlusion_release_delay` seconds, during
		# which the camera holds its pulled-in pose even if the probe momentarily
		# clears. Kills the bounce when walking around a wall corner.
		var probe := _occlude(aim_point, cam_pos)
		var probe_hit: bool = probe["hit"]
		var probe_pos: Vector3 = probe["pos"]
		if probe_hit:
			_is_occluded = true
			_clear_streak_seconds = 0.0
			_last_occluded_pos = probe_pos
		elif _is_occluded:
			_clear_streak_seconds += delta
			if _clear_streak_seconds >= occlusion_release_delay:
				_is_occluded = false
				_clear_streak_seconds = 0.0

		var desired: Vector3
		if _is_occluded:
			desired = probe_pos if probe_hit else _last_occluded_pos
		else:
			desired = cam_pos

		# Frame-rate-independent asymmetric ease toward the desired pose.
		var prev_aim_dist := (_camera.global_position - aim_point).length()
		var desired_aim_dist := (desired - aim_point).length()
		var rate := pull_in_smoothing if desired_aim_dist < prev_aim_dist else ease_out_smoothing
		var smooth_t := 1.0 - exp(-rate * delta)
		_camera.global_position = _camera.global_position.lerp(desired, smooth_t)

	# look_at runs in both states. On the ground it tracks the player as the
	# tripod adjusts. While airborne the rigid translation preserves the
	# camera→player vector exactly, so look_at is a no-op unless drag has
	# changed the offset — which is the only thing that *should* rotate the
	# camera mid-jump.
	_camera.look_at(aim_point, Vector3.UP)

	# Publish the yaw the player should rotate input by. We want stick-up to
	# move the player away from the camera, so the published yaw is the angle
	# from the player to the camera (atan2(cam.x - player.x, cam.z - player.z)).
	# Use call() because _target is typed Node3D — Player adds set_camera_yaw.
	# In the air this is constant frame-to-frame (no drag) → input frame stays
	# locked from takeoff to landing.
	if _target.has_method("set_camera_yaw"):
		var pub_yaw := atan2(
			_camera.global_position.x - target_pos.x,
			_camera.global_position.z - target_pos.z)
		_target.call(&"set_camera_yaw", pub_yaw)

	# Refresh the air offset every frame. On the ground this captures the
	# latest camera/player relationship in case the player takes off next
	# frame; in the air it propagates any drag-induced offset changes.
	_air_offset = _camera.global_position - target_pos


func _place_camera_initial(target_pos: Vector3) -> void:
	var elevation := -_pitch_rad
	_camera.global_position = target_pos + Vector3(
		0.0,
		sin(elevation) * distance + aim_height,
		cos(elevation) * distance,
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
	# Upper bound clamped to pitch_max (camera at horizontal); lower bound is
	# 0 so the camera never drops below the player. _pitch_rad therefore stays
	# ≤ 0, which is what the V-turn fix relies on.
	phi = clampf(
		phi - drag.y * pitch_drag_sens,
		0.0,
		deg_to_rad(pitch_max_degrees),
	)
	_pitch_rad = -phi
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


# True when the target is grounded. Falls back to true (camera tracks normally)
# when the target isn't a CharacterBody3D, so non-character targets aren't
# accidentally locked into the airborne-freeze branch.
func _is_target_on_floor() -> bool:
	if _target is CharacterBody3D:
		return (_target as CharacterBody3D).is_on_floor()
	return true


## Returns `{hit: bool, pos: Vector3}` for the line of sight from `aim` to
## `desired`. When `hit` is true, `pos` is the safe camera position (the
## impact point minus the occlusion margin, floored at occlusion_min_distance).
## When `hit` is false, `pos == desired`. Sphere cast (rather than a thin ray)
## tames the frame-to-frame flicker at wall edges; the boolean lets the
## caller apply a release-delay latch on top.
func _occlude(aim: Vector3, desired: Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var to_desired := desired - aim
	var total_len := to_desired.length()
	if total_len < 0.001:
		return {"hit": false, "pos": desired}
	var dir := to_desired / total_len

	var excludes: Array[RID] = []
	if _target is PhysicsBody3D:
		excludes.append((_target as PhysicsBody3D).get_rid())

	var hit_dist := total_len
	var hit_found := false
	if occlusion_probe_radius > 0.0:
		var shape := SphereShape3D.new()
		shape.radius = occlusion_probe_radius
		var motion_params := PhysicsShapeQueryParameters3D.new()
		motion_params.shape = shape
		motion_params.transform = Transform3D(Basis.IDENTITY, aim)
		motion_params.motion = to_desired
		motion_params.collision_mask = occlusion_mask
		motion_params.exclude = excludes
		# cast_motion returns [safe_fraction, unsafe_fraction] in [0, 1].
		# safe_fraction == 1.0 → no contact along the sweep.
		var fractions := space.cast_motion(motion_params)
		if fractions.size() == 2 and fractions[0] < 1.0:
			hit_dist = total_len * fractions[0]
			hit_found = true
	else:
		var ray := PhysicsRayQueryParameters3D.new()
		ray.from = aim
		ray.to = desired
		ray.collision_mask = occlusion_mask
		ray.exclude = excludes
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			var hit_pos: Vector3 = hit.position
			hit_dist = (hit_pos - aim).length()
			hit_found = true

	if not hit_found:
		return {"hit": false, "pos": desired}
	var safe_dist := maxf(occlusion_min_distance, hit_dist - occlusion_margin)
	return {"hit": true, "pos": aim + dir * safe_dist}


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
		&"aim_height":
			aim_height = value
		&"pitch_min_degrees":
			pitch_min_degrees = value
		&"pitch_max_degrees":
			pitch_max_degrees = value
		# Lookahead and auto-recenter sliders are no-ops in the tripod model.
		_:
			pass
