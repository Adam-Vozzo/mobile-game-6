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
@export_range(0.0, 89.0, 1.0) var pitch_max_degrees: float = 70.0

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
# Extra spring-arm distance (metres) blended in while the player is inside a
# CameraHint volume. Lerps toward the max pull_back_amount among all active
# hints at 3 /sec (→ 95% blend in ~1 s). Zero when no hints are active.
var _hint_distance_extra: float = 0.0

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
	var effective_distance := _update_hint_distance(delta)
	# Apex anchor: instant-tracked on grounded frames, held during airborne.
	# Drives only the apex threshold (held-band upper limit). Distinct from
	# the smoothed _reference_floor_y, which drives the camera's Y target —
	# the threshold must be tied to the actual takeoff floor so normal jumps
	# from a tier the reference hasn't caught up to yet don't trigger track-up.
	if on_floor:
		_apex_anchor_y = target_pos.y
	_update_reference_floor(target_pos.y, on_floor, delta)
	var effective_target := _build_effective_target(target_pos)
	var aim_point := effective_target + Vector3(0.0, aim_height, 0.0)
	_try_initialize(effective_target, target_pos)
	# Airborne: rigid translate. Camera copies the player's per-frame delta via
	# _air_offset, locking the input frame from takeoff to landing. Drag still
	# works; look_at is a near no-op (offset vector unchanged) unless drag ran.
	if not on_floor:
		_camera.global_position = effective_target + _air_offset
	_apply_drag_input(effective_target, effective_distance)
	if on_floor:
		_update_ground_camera(target_pos, effective_target, effective_distance, aim_point, delta)
	_camera.look_at(aim_point, Vector3.UP)
	_publish_camera_yaw(target_pos)
	# Refresh air offset every frame so takeoff captures the current pose and
	# mid-air drag propagates. Stored relative to effective_target (not raw
	# target_pos) so below-apex vertical motion doesn't leak into the offset.
	_air_offset = _camera.global_position - effective_target


# Blends the CameraHint extra distance every frame (including while airborne,
# so the pull-back is already easing in when the player lands inside a hint).
# Returns the total effective arm length for this frame.
func _update_hint_distance(delta: float) -> float:
	_hint_distance_extra = lerpf(
		_hint_distance_extra,
		_get_active_hint_extra(),
		1.0 - exp(-3.0 * delta),
	)
	return distance + _hint_distance_extra


# X/Z follow the player exactly; Y is the vertical-follow ratchet's output.
func _build_effective_target(target_pos: Vector3) -> Vector3:
	return Vector3(target_pos.x, _compute_effective_y(target_pos.y), target_pos.z)


func _try_initialize(effective_target: Vector3, target_pos: Vector3) -> void:
	if _initialized:
		return
	_place_camera_initial(effective_target)
	_air_offset = _camera.global_position - effective_target
	_apex_anchor_y = target_pos.y
	_initialized = true


# Ground pose pipeline: distance maintenance → occlusion → position smoothing.
func _update_ground_camera(target_pos: Vector3, effective_target: Vector3,
		effective_distance: float, aim_point: Vector3, delta: float) -> void:
	var cam_pos := _compute_ground_camera_pos(target_pos, effective_target, effective_distance)
	var desired := _occlude_and_latch(aim_point, cam_pos, delta)
	_apply_position_smooth(aim_point, desired, delta)


# Horizontal distance uses raw target_pos (player's actual X/Z); only Y is
# held by the ratchet via effective_target. Fall pull is gated on tracking
# regimes so it doesn't yank the camera during held-band jumps.
func _compute_ground_camera_pos(target_pos: Vector3, effective_target: Vector3,
		effective_distance: float) -> Vector3:
	var cam_pos := _camera.global_position
	var horiz := Vector3(target_pos.x - cam_pos.x, 0.0, target_pos.z - cam_pos.z)
	var current_dist := horiz.length()
	if current_dist > 0.001:
		var dir := horiz / current_dist
		var dist_error := current_dist - effective_distance
		cam_pos.x += dir.x * dist_error
		cam_pos.z += dir.z * dist_error
	var fall_offset := _conditional_fall_offset(target_pos.y, _get_target_velocity().y)
	# _pitch_rad ≤ 0; negate to get elevation angle (absf would V-shape at drag
	# crossing horizontal — see iter 22 DECISIONS.md entry).
	var elevation := -_pitch_rad
	cam_pos.y = effective_target.y + sin(elevation) * effective_distance + aim_height + fall_offset
	return cam_pos


# Runs the occlusion probe and updates the hysteresis latch. Any probe hit
# re-arms the "occluded" state for occlusion_release_delay seconds so the
# camera stays pulled in while grazing a wall corner. Returns the desired pose.
func _occlude_and_latch(aim: Vector3, cam_pos: Vector3, delta: float) -> Vector3:
	var probe := _occlude(aim, cam_pos)
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
	if _is_occluded:
		return probe_pos if probe_hit else _last_occluded_pos
	return cam_pos


# Frame-rate-independent asymmetric ease: pull_in_smoothing when moving toward
# the player (occluder just entered), ease_out_smoothing when falling back.
func _apply_position_smooth(aim_point: Vector3, desired: Vector3, delta: float) -> void:
	var prev_aim_dist := (_camera.global_position - aim_point).length()
	var desired_aim_dist := (desired - aim_point).length()
	var rate := pull_in_smoothing if desired_aim_dist < prev_aim_dist else ease_out_smoothing
	var smooth_t := 1.0 - exp(-rate * delta)
	_camera.global_position = _camera.global_position.lerp(desired, smooth_t)


# Use call() because _target is typed Node3D — Player adds set_camera_yaw.
# Yaw is the angle from the player to the camera so stick-up moves the player
# away from the camera regardless of orbit angle.
func _publish_camera_yaw(target_pos: Vector3) -> void:
	if not _target.has_method(&"set_camera_yaw"):
		return
	var pub_yaw := atan2(
		_camera.global_position.x - target_pos.x,
		_camera.global_position.z - target_pos.z,
	)
	_target.call(&"set_camera_yaw", pub_yaw)


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


# Drag rotates the camera around the effective target. Yaw is re-derived
# from the camera position each call (the tripod model lets the player walk
# around the camera, so the camera-relative theta drifts and must be read
# off the geometry). Pitch reads from `_pitch_rad` directly — it is the
# authoritative state, mutated only by drag and the dev menu.
#
# Parametrization matches `_compute_ground_camera_pos` exactly: XZ at full
# `effective_distance` from the pivot (cylindrical, not spherical) and
# Y = aim_height + sin(elev)*effective_distance above the pivot. A previous
# implementation re-derived phi via `asin(to_cam.y / radius)` and combined
# that with the additive `aim_height`, which quietly auto-raised the camera
# on slow downward swipes. A spherical write here (with a `cos(elev)` factor
# on XZ) introduced a different mismatch: at high pitch the drag put XZ at
# `effective_distance * cos(elev)`, then the ground branch eased the camera
# back out to full XZ distance over ~0.5 s — visible as an "auto-correction
# fight" after pitching up. Writing the new position with the same
# cylindrical formula `_compute_ground_camera_pos` enforces keeps the two
# in lockstep at every pitch.
func _apply_drag_input(pivot: Vector3, effective_distance: float) -> void:
	var drag := TouchInput.consume_camera_drag_delta()
	if drag.length_squared() == 0.0:
		return
	var to_cam := _camera.global_position - pivot
	if Vector2(to_cam.x, to_cam.z).length_squared() < 0.000001:
		return
	var theta := atan2(to_cam.x, to_cam.z) - drag.x * yaw_drag_sens
	# `+` (was `-`) inverts the vertical axis: swipe down on screen now raises
	# the camera (so the view tilts down at the player's feet), matching the
	# FPS look convention. Lower bound 0 keeps the camera at or above
	# horizontal; upper bound caps how high the player can lift it. _pitch_rad
	# stays ≤ 0 — the V-turn fix downstream still relies on that.
	var elev := clampf(
		-_pitch_rad + drag.y * pitch_drag_sens,
		0.0,
		deg_to_rad(pitch_max_degrees),
	)
	_pitch_rad = -elev
	_camera.global_position = pivot + Vector3(
		effective_distance * sin(theta),
		effective_distance * sin(elev) + aim_height,
		effective_distance * cos(theta),
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
## tames frame-to-frame flicker at wall edges; the boolean lets the caller
## apply a release-delay latch on top.
func _occlude(aim: Vector3, desired: Vector3) -> Dictionary:
	var to_desired := desired - aim
	var total_len := to_desired.length()
	if total_len < 0.001:
		return {"hit": false, "pos": desired}
	var dir := to_desired / total_len
	var hit_dist := _probe_hit_dist(aim, to_desired, total_len)
	if hit_dist >= total_len:
		return {"hit": false, "pos": desired}
	var safe_dist := maxf(occlusion_min_distance, hit_dist - occlusion_margin)
	return {"hit": true, "pos": aim + dir * safe_dist}


# Dispatches to sphere cast (when occlusion_probe_radius > 0) or ray cast.
# Returns the distance from `aim` to the first contact along `to_desired`, or
# `total_len` when the sweep is clear (= "no hit" sentinel).
# cast_motion safe_fraction == 1.0 → no contact along the full sweep.
func _probe_hit_dist(aim: Vector3, to_desired: Vector3, total_len: float) -> float:
	var space := get_world_3d().direct_space_state
	var excludes: Array[RID] = []
	if _target is PhysicsBody3D:
		excludes.append((_target as PhysicsBody3D).get_rid())
	if occlusion_probe_radius > 0.0:
		var shape := SphereShape3D.new()
		shape.radius = occlusion_probe_radius
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = shape
		params.transform = Transform3D(Basis.IDENTITY, aim)
		params.motion = to_desired
		params.collision_mask = occlusion_mask
		params.exclude = excludes
		var fractions := space.cast_motion(params)
		if fractions.size() == 2 and fractions[0] < 1.0:
			return total_len * fractions[0]
	else:
		var ray := PhysicsRayQueryParameters3D.new()
		ray.from = aim
		ray.to = aim + to_desired
		ray.collision_mask = occlusion_mask
		ray.exclude = excludes
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			return ((hit.position as Vector3) - aim).length()
	return total_len


# Returns the largest pull_back_amount among all active CameraHint volumes
# (i.e. those that currently contain the player). Returns 0.0 when none are
# active so _hint_distance_extra bleeds back to zero at the same 3/sec rate.
func _get_active_hint_extra() -> float:
	var max_extra: float = 0.0
	for hint: Node in get_tree().get_nodes_in_group(&"camera_hints"):
		if hint is CameraHint and (hint as CameraHint).is_player_inside():
			max_extra = maxf(max_extra, (hint as CameraHint).pull_back_amount)
	return max_extra


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
		&"occlusion_probe_radius":
			occlusion_probe_radius = value
		&"pull_in_smoothing":
			pull_in_smoothing = value
		&"ease_out_smoothing":
			ease_out_smoothing = value
		&"occlusion_release_delay":
			occlusion_release_delay = value
		# Lookahead and auto-recenter sliders are no-ops in the tripod model.
		_:
			pass
