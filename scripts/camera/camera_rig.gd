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
## camera while falling. Helps the player see what's below. Only applied
## when the player is above the apex-height threshold — below the threshold
## the camera is held still and fall pull would re-introduce the vertical
## motion the vertical-follow ratchet is removing.
@export_range(0.0, 1.0, 0.01) var vertical_pull: float = 0.18

@export_category("Vertical follow")
## Multiplier on the active profile's default jump apex height
## (`Player.get_default_apex_height()`). The camera holds its Y while the
## player stays below `reference_floor_y + apex_height * multiplier`; above
## that band, the camera tracks the player's Y so a double-jump or wall-
## jump above the normal arc still keeps the player in frame. The reference
## floor is whatever floor Y the player most recently stood on. Setting the
## multiplier > 1 makes the camera lazier about following jumps; setting it
## < 1 (toward 0) makes the camera follow earlier — at the limit (0) the
## camera reverts to always-track-Y behaviour.
##
## Default 1.15 sits 15% above the *analytic* max single jump height
## (`v² / 2g`). The 15% headroom absorbs floor-physics jitter at peak — Jolt's
## capsule-vs-static-mesh resolution can nudge `player.y` by a few mm above
## the analytic max, and without headroom the held/tracking branches flicker
## back and forth across the boundary on those frames. The threshold is
## still well below any double-jump reachable height, so above-apex
## traversal still triggers tracking as designed.
@export_range(0.0, 5.0, 0.05) var apex_height_multiplier: float = 1.15
## Rate (per second) at which the reference floor catches up to the player
## when grounded. Big tier changes (landing on a higher/lower platform) ease
## in rather than snap. Higher = snappier transition (toward instant); lower
## = camera lags up to the new tier (cinematic). 0 disables smoothing
## entirely (instant snap — the pre-fix behaviour). Defaults to 6/sec for an
## ~400 ms settle on a single-platform-height tier change: fast enough that
## the camera arrives in time for the next jump, slow enough that the human
## reads it as motion rather than a cut.
@export_range(0.0, 30.0, 0.5) var reference_floor_smoothing: float = 6.0
## Y delta (m) above which the reference floor snaps directly to the player
## instead of lerping. Catches respawns and very long falls — anything where
## the smoothed transition would visibly lag and read as broken. 8 m is
## roughly four Snappy jump heights; below that, the smoothing path handles
## normal level-design tier shifts.
@export_range(0.5, 30.0, 0.5) var reference_floor_snap_threshold: float = 8.0

@export_category("Manual override")
@export_range(0.0001, 0.05, 0.0001) var yaw_drag_sens: float = 0.005
@export_range(0.0001, 0.05, 0.0001) var pitch_drag_sens: float = 0.003
## Maximum elevation the player can drag the camera to, in degrees above horizontal.
## The lower bound (camera at horizontal) is hardcoded 0.0 — the tripod model
## always keeps the camera above the player.
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
# Camera position offset from the *effective* target, refreshed every frame.
# Effective target's X/Z equals the player's; its Y is the vertical-follow
# ratchet's output (reference floor below apex, player.y above apex). While
# the player is airborne, this offset is held constant and the camera's world
# position is reconstructed as `effective_target + _air_offset` — a rigid
# translate that follows the player's horizontal motion exactly and the
# player's vertical motion only when they've cleared the apex band.
var _air_offset: Vector3 = Vector3.ZERO
# Vertical-follow ratchet: the Y of the floor the player most recently stood
# on, smoothed toward player.y on each grounded frame at
# `reference_floor_smoothing` per second. Drives the camera's *target* Y for
# the held / track-down branches — so when the player lands on a new tier
# the camera eases up/down rather than snapping. Held while airborne so
# jumps don't lift it.
var _reference_floor_y: float = 0.0
# Apex anchor: the Y of the floor the player is currently standing on, with
# *instant* tracking on each grounded frame (no smoothing). Held while
# airborne. Used only for the apex check (`apex_y = anchor + band`) — keeps
# the threshold tied to the player's actual takeoff floor, so a normal jump
# from a tier the smoothed reference hasn't caught up to yet doesn't
# spuriously trigger the track-up branch. Distinct from `_reference_floor_y`:
# this one drives the *threshold*, the smoothed one drives the *target*.
var _apex_anchor_y: float = 0.0

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
	var on_floor := _is_target_on_floor()
	# Apex anchor: instant tracking of grounded player.y, held during
	# airborne. Used only for the apex check (= track-up threshold). Keeping
	# this distinct from the smoothed `_reference_floor_y` is the whole point
	# — the threshold should be tied to the player's actual takeoff floor
	# (so a normal jump from a tier the smoothed reference hasn't caught up
	# to yet doesn't spuriously trigger track-up), but the camera's *target*
	# Y still eases via the smoothed reference (so tier-change transitions
	# still glide rather than snap).
	if on_floor:
		_apex_anchor_y = target_pos.y
	# else: held — held value is the player's most recent grounded Y, which
	# is the correct takeoff floor for any airborne ratchet decisions.
	_update_reference_floor(target_pos.y, on_floor, delta)
	# Effective target: the position the camera *tracks*. X/Z follow the player
	# exactly; Y is the vertical-follow ratchet's output (held at reference
	# floor below apex; tracks the player above apex / below reference). All
	# camera-position math derives from this, so the camera ignores below-
	# apex jumps but still follows horizontal motion + floor changes +
	# above-apex traversal + below-reference descents.
	var effective_target := Vector3(
		target_pos.x,
		_compute_effective_y(target_pos.y),
		target_pos.z,
	)
	var aim_point := effective_target + Vector3(0.0, aim_height, 0.0)

	if not _initialized:
		_place_camera_initial(effective_target)
		_air_offset = _camera.global_position - effective_target
		_apex_anchor_y = target_pos.y
		_initialized = true

	# Airborne: rigid follow. Reconstruct the camera position as
	# `effective_target + _air_offset` *before* drag/look_at runs, so any
	# horizontal motion the player did this frame is reflected as a pure
	# translation, while vertical motion under apex is absorbed (effective_y
	# stays pinned to reference floor). The offset itself is captured at the
	# end of the previous (grounded) frame, so the camera→effective-target
	# vector is preserved across the entire jump and look_at gives the same
	# basis frame after frame — no yaw or pitch rotation while airborne. Drag
	# and landing both update the offset correctly via the unified end-of-
	# frame save below.
	if not on_floor:
		_camera.global_position = effective_target + _air_offset

	_apply_drag_input(effective_target)

	if on_floor:
		# Ground: tripod-style distance maintenance + occlusion + smoothing.
		# Horizontal distance still uses raw target_pos so the camera tracks
		# the player's actual X/Z; only Y is held by the ratchet.
		var cam_pos := _camera.global_position
		var horiz := Vector3(target_pos.x - cam_pos.x, 0.0, target_pos.z - cam_pos.z)
		var current_dist := horiz.length()
		if current_dist > 0.001:
			var dir := horiz / current_dist
			var dist_error := current_dist - distance
			cam_pos.x += dir.x * dist_error
			cam_pos.z += dir.z * dist_error
		# Fall pull is gated on being above apex — below apex the camera is
		# held still by design, and pulling it down on descent would
		# reintroduce the vertical motion the ratchet is removing.
		var fall_offset := _conditional_fall_offset(target_pos.y, _get_target_velocity().y)
		# `_pitch_rad` is ≤ 0; -_pitch_rad is the elevation angle. Using `absf`
		# would V-shape as the drag crosses horizontal — see iter 22 fix on main.
		var elevation := -_pitch_rad
		cam_pos.y = effective_target.y + sin(elevation) * distance + aim_height + fall_offset

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

	# Refresh the air offset every frame, relative to the *effective* target.
	# On the ground this captures the latest camera/effective relationship in
	# case the player takes off next frame; in the air it propagates any drag-
	# induced offset changes. Storing relative to effective_target (not raw
	# target_pos) keeps below-apex jumps from leaking into the offset and re-
	# applying as Y motion on the next frame.
	_air_offset = _camera.global_position - effective_target


func _place_camera_initial(anchor: Vector3) -> void:
	var elevation := -_pitch_rad
	_camera.global_position = anchor + Vector3(
		0.0,
		sin(elevation) * distance + aim_height,
		cos(elevation) * distance,
	)


# Vertical-follow ratchet: reference floor tracks the Y of the floor the
# player is currently standing on. Updates only on grounded frames; airborne
# frames leave the reference alone so jumps don't lift the camera unless
# the apex band is exceeded (see _compute_effective_y).
#
# On a grounded frame, the reference eases toward `player_y` at
# `reference_floor_smoothing` per second rather than snapping. Big deltas
# (respawn, very long falls) bypass the smoothing via the snap threshold
# so the camera doesn't visibly lag for half a second after a teleport.
func _update_reference_floor(player_y: float, on_floor: bool, delta: float) -> void:
	if not _initialized:
		_reference_floor_y = player_y
		return
	if not on_floor:
		return
	var d := absf(player_y - _reference_floor_y)
	if d > reference_floor_snap_threshold or reference_floor_smoothing <= 0.0:
		_reference_floor_y = player_y
		return
	var t := 1.0 - exp(-reference_floor_smoothing * delta)
	_reference_floor_y = lerpf(_reference_floor_y, player_y, t)


# Vertical-follow ratchet: returns the Y the camera should track. Three
# regimes around the reference floor:
#   1. player_y > apex_anchor + apex_band → track up (player.y - band).
#      Above-apex traversal (double-jump, wall-jump, vertical megastructure
#      beats) still keeps the player in frame, lifting 1:1.
#   2. player_y < reference              → track down (player.y).
#      Walking off a ledge or falling into a pit: the camera follows the
#      descent immediately rather than waiting for the player to touch a
#      new floor before catching up. The asymmetric position lerp on top
#      still smooths the actual motion.
#   3. otherwise (in the held band)      → hold at reference_floor_y.
#      Normal jumps that stay between the floor and the apex don't move
#      the camera at all.
#
# The *threshold* (apex_y) uses `_apex_anchor_y` — instant-tracked on
# grounded frames, held during airborne — so the check is tied to the
# player's actual takeoff floor. The *target* (the hold and track-down
# returns) uses `_reference_floor_y` — smoothed — so tier-change
# transitions still glide rather than snap.
func _compute_effective_y(player_y: float) -> float:
	var apex_h := _get_target_apex_height() * apex_height_multiplier
	if apex_h <= 0.0:
		# Multiplier 0 or missing-profile fallback: revert to always-track-Y.
		return player_y
	var apex_y := _apex_anchor_y + apex_h
	if player_y > apex_y:
		return player_y - apex_h
	if player_y < _reference_floor_y:
		return player_y
	return _reference_floor_y


# Live read of the active controller profile's max jump apex height (m).
# Camera uses this rather than its own @export so the band auto-adjusts when
# profiles hot-swap from the dev menu. Returns 0.0 if target doesn't expose
# the method — _compute_effective_y treats that as "always follow Y".
func _get_target_apex_height() -> float:
	if _target != null and _target.has_method(&"get_default_apex_height"):
		return float(_target.call(&"get_default_apex_height"))
	return 0.0


# Vertical-pull is the fall-aware camera drop that helps the player see
# what's below. Fires whenever the camera is in a Y-tracking regime —
# either above the apex band (track-up) or below the reference floor
# (track-down / falling). Inside the held band the camera is pinned and a
# fall pull would yank it down off-baseline, re-introducing the vertical
# motion the ratchet is removing.
func _conditional_fall_offset(player_y: float, vel_y: float) -> float:
	var apex_h := _get_target_apex_height() * apex_height_multiplier
	if apex_h <= 0.0:
		return _vertical_pull_offset(vel_y)
	# Mirrors `_compute_effective_y`'s three regimes — fall-pull fires
	# wherever the ratchet would put the camera in tracking mode.
	if player_y > _apex_anchor_y + apex_h:
		return _vertical_pull_offset(vel_y)
	if player_y < _reference_floor_y:
		return _vertical_pull_offset(vel_y)
	return 0.0


# Drag rotates the camera around the effective target. Yaw orbits in the
# XZ plane; pitch tilts the camera up/down while preserving the horizontal
# radius. We re-derive theta/phi from the current camera position each call
# so the camera's geometric drift along the look axis stays consistent with
# drag. `pivot` is the effective target (raw player X/Z + ratchet-held Y),
# matching the rest of the camera's Y-handling so drag rotates around the
# same point the camera is tracking.
func _apply_drag_input(pivot: Vector3) -> void:
	var drag := TouchInput.consume_camera_drag_delta()
	if drag.length_squared() == 0.0:
		return
	var to_cam := _camera.global_position - pivot
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
	_camera.global_position = pivot + Vector3(
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
		&"pitch_max_degrees":
			pitch_max_degrees = value
		&"apex_height_multiplier":
			apex_height_multiplier = value
		&"reference_floor_smoothing":
			reference_floor_smoothing = value
		&"reference_floor_snap_threshold":
			reference_floor_snap_threshold = value
		# Lookahead and auto-recenter sliders are no-ops in the tripod model.
		_:
			pass
