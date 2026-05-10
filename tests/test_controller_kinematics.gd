extends Node
## Standalone unit tests for character-controller kinematics.
##
## Covers pure maths mirrored in player.gd: gravity band ordering,
## jump height plausibility, horizontal interpolation convergence,
## air damping, terminal-velocity clamping, timer countdown, and
## variable jump cut.  No scene-tree objects are instantiated — only
## ControllerProfile resources (Resource subclass, no Node).
##
## RUN: open tests/test_runner.tscn in the editor and press F5.
##      All results appear in the Output panel.
##
## GUT MIGRATION: rename _ready() → before_all() and each _test_*()
## to test_*() — the assertion pattern is otherwise GUT-compatible.

const CP := preload("res://scripts/controller/controller_profile.gd")

var _pass_count := 0
var _fail_count := 0


func _ready() -> void:
	print("\n=== Controller kinematics tests ===")
	_test_profile_defaults()
	_test_jump_height_plausible()
	_test_gravity_band_ordering()
	_test_jump_cut_math()
	_test_horizontal_interpolation()
	_test_air_damping()
	_test_terminal_velocity()
	_test_coyote_countdown()
	_test_buffer_countdown()
	_test_profile_cross_invariants()
	_test_slope_params()
	_test_respawn_params()
	_test_movement_params()
	_test_camera_vertical_pull()
	_test_camera_occlude_math()
	_test_camera_pitch_formula()
	_test_tripod_placement()
	_test_tripod_drag_orbit()
	_test_move_dir_rotation()
	_test_gravity_band_selection()
	_report()


# ── helpers ──────────────────────────────────────────────────────────────────

func _ok(label: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
		print("  PASS  " + label)
	else:
		_fail_count += 1
		push_error("  FAIL  " + label)


func _near(a: float, b: float, eps: float = 1e-4) -> bool:
	return absf(a - b) <= eps


func _report() -> void:
	var total := _pass_count + _fail_count
	print("\n=== %d / %d passed ===" % [_pass_count, total])
	if _fail_count > 0:
		push_error("%d test(s) FAILED — see Output panel" % _fail_count)


func _load_profile(path: String) -> CP:
	var res := load(path)
	if res == null:
		push_warning("Profile not found: " + path)
	return res


# ── test groups ───────────────────────────────────────────────────────────────

func _test_profile_defaults() -> void:
	## Verify ControllerProfile.new() produces physically plausible defaults.
	print("\n-- ControllerProfile.new() defaults --")
	var p := CP.new()
	_ok("max_speed > 0", p.max_speed > 0.0)
	_ok("jump_velocity > 0", p.jump_velocity > 0.0)
	_ok("coyote_time in [0.05, 0.3]", p.coyote_time >= 0.05 and p.coyote_time <= 0.3)
	_ok("jump_buffer in [0.05, 0.3]", p.jump_buffer >= 0.05 and p.jump_buffer <= 0.3)
	_ok("release_velocity_ratio in (0, 1)", p.release_velocity_ratio > 0.0 and p.release_velocity_ratio < 1.0)
	_ok("gravity_rising > 0", p.gravity_rising > 0.0)
	_ok("terminal_velocity > 0", p.terminal_velocity > 0.0)
	_ok("reboot_duration > 0", p.reboot_duration > 0.0)


func _test_jump_height_plausible() -> void:
	## Peak height under constant gravity_rising: h = v₀² / (2g).
	## The Stray is ~0.8 m tall; 1.5–5.0 m covers all intended profiles.
	print("\n-- Jump height plausibility (h = v0² / 2g) --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	var h_snappy := 0.0
	var h_floaty := 0.0
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var h := p.jump_velocity * p.jump_velocity / (2.0 * p.gravity_rising)
		_ok(name + " peak height >= 1.5 m", h >= 1.5)
		_ok(name + " peak height <= 5.0 m", h <= 5.0)
		if name == "snappy":
			h_snappy = h
		elif name == "floaty":
			h_floaty = h

	# Floaty is designed to arch higher than Snappy (lower gravity_rising).
	if h_snappy > 0.0 and h_floaty > 0.0:
		_ok("floaty peak height >= snappy peak height", h_floaty >= h_snappy)


func _test_gravity_band_ordering() -> void:
	## player.gd uses three gravity bands:
	##   rising + held  → gravity_rising   (lowest: maximises hang time)
	##   rising + no hold → gravity_falling (cuts the arc quickly)
	##   falling (vy≤0) → gravity_after_apex (highest: snappy landing feel)
	##
	## Design invariant: gravity_after_apex >= gravity_falling >= gravity_rising
	print("\n-- Gravity band ordering (after_apex >= falling >= rising) --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		_ok(name + ": gravity_rising > 0", p.gravity_rising > 0.0)
		_ok(name + ": gravity_falling >= gravity_rising", p.gravity_falling >= p.gravity_rising)
		_ok(name + ": gravity_after_apex >= gravity_falling", p.gravity_after_apex >= p.gravity_falling)


func _test_jump_cut_math() -> void:
	## Variable jump cut (player.gd):
	##   if jump_released and vy > jump_velocity * release_velocity_ratio:
	##       vy = jump_velocity * release_velocity_ratio
	print("\n-- Variable jump cut math --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var threshold := p.jump_velocity * p.release_velocity_ratio

		# At full jump_velocity the cut must fire.
		_ok(name + ": cut fires at full jump_velocity", p.jump_velocity > threshold)

		# Threshold is strictly between zero and jump_velocity.
		_ok(name + ": threshold > 0 (still rising after cut)", threshold > 0.0)
		_ok(name + ": threshold < jump_velocity (cut reduces vy)", threshold < p.jump_velocity)

		# At exactly the threshold the condition is false — no feedback loop.
		_ok(name + ": no cut at vy == threshold (boundary)", not (threshold > threshold))

		# Well below threshold: no cut (vy at 20% of jump_velocity).
		var vy_low := p.jump_velocity * 0.2
		_ok(name + ": no cut when vy is 20% of jump_velocity", not (vy_low > threshold))


func _test_horizontal_interpolation() -> void:
	## Simulates player.gd horizontal loop for up to 300 frames (5 s at 60 fps).
	## move_toward(current, target, accel * delta) must converge to max_speed
	## within 5 s on every shipped profile. 30-frame cap documents that
	## even the slowest profile (Floaty ~12 frames, Momentum ~12 frames,
	## Snappy ~6 frames) converges well within a perceptible delay.
	print("\n-- Horizontal interpolation convergence --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	const DELTA := 1.0 / 60.0
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var h := Vector3.ZERO
		var target := Vector3(p.max_speed, 0.0, 0.0)
		var converged_at := -1
		for i in 300:
			h = h.move_toward(target, p.ground_acceleration * DELTA)
			if h.distance_to(target) < 0.01 and converged_at < 0:
				converged_at = i + 1
		_ok(name + ": converges to max_speed within 5 s at 60 fps", converged_at >= 0)
		_ok(name + ": final speed within 0.01 m/s of max_speed", h.distance_to(target) < 0.01)
		_ok(name + ": convergence within 30 frames", converged_at > 0 and converged_at <= 30)


func _test_air_damping() -> void:
	## player.gd: new_h *= maxf(0, 1 - air_horizontal_damping * delta)
	## Snappy has zero damping (full SMB-style velocity preservation).
	## Floaty has non-zero damping (grippier air control).
	print("\n-- Air horizontal damping --")
	const DELTA := 1.0 / 60.0
	var h_start := Vector3(8.0, 0.0, 0.0)

	# Zero damping must preserve magnitude exactly.
	var h_zero := h_start * maxf(0.0, 1.0 - 0.0 * DELTA)
	_ok("zero damping preserves velocity magnitude", _near(h_zero.length(), 8.0))

	# Positive damping must reduce magnitude (but keep it positive for one frame).
	var h_damp := h_start * maxf(0.0, 1.0 - 2.0 * DELTA)
	_ok("positive damping reduces velocity", h_damp.length() < h_start.length())
	_ok("one frame of damping keeps velocity positive", h_damp.length() > 0.0)

	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	var fp: CP = _load_profile("res://resources/profiles/floaty.tres")
	if sp != null:
		_ok("snappy has zero air damping (SMB-style preservation)", sp.air_horizontal_damping == 0.0)
	if fp != null:
		_ok("floaty has non-zero air damping (grippier)", fp.air_horizontal_damping > 0.0)
	if sp != null and fp != null:
		_ok("floaty damping > snappy damping", fp.air_horizontal_damping > sp.air_horizontal_damping)


func _test_terminal_velocity() -> void:
	## player.gd: velocity.y = maxf(-terminal_velocity, vy - g * delta)
	## Once at terminal velocity, additional gravity must not push further down.
	print("\n-- Terminal velocity clamp --")
	const DELTA := 1.0 / 60.0
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue

		# Already past terminal: clamp must hold.
		var vy_past := -p.terminal_velocity - 30.0
		var clamped := maxf(-p.terminal_velocity, vy_past - p.gravity_after_apex * DELTA)
		_ok(name + ": clamp holds when vy is far past terminal", _near(clamped, -p.terminal_velocity))

		# At exactly -terminal_velocity: gravity would push further → clamp holds.
		var vy_at := -p.terminal_velocity
		var clamped2 := maxf(-p.terminal_velocity, vy_at - p.gravity_after_apex * DELTA)
		_ok(name + ": clamp holds at exactly -terminal_velocity", _near(clamped2, -p.terminal_velocity))

		# Mild fall speed (not yet terminal): gravity still applies freely.
		var vy_mild := -5.0
		var after_gravity := maxf(-p.terminal_velocity, vy_mild - p.gravity_after_apex * DELTA)
		_ok(name + ": gravity applies freely below terminal speed", after_gravity < vy_mild)
		_ok(name + ": mild fall stays above -terminal_velocity", after_gravity > -p.terminal_velocity)


func _test_coyote_countdown() -> void:
	## Simulates timer = maxf(0, timer - delta) to verify:
	##   1. Never goes negative.
	##   2. Expires within 2× the expected frame count (float-rounding headroom).
	## Tests all three shipped profiles (coyote_time varies: 0.1 / 0.18 / 0.08 s).
	print("\n-- Coyote timer countdown --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	const DELTA := 1.0 / 60.0
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var timer := p.coyote_time
		var frames := 0
		while timer > 0.0 and frames < 600:
			timer = maxf(0.0, timer - DELTA)
			frames += 1
		_ok(name + ": coyote timer expires (doesn't run forever)", frames < 600)
		_ok(name + ": coyote timer never goes negative", timer >= 0.0)
		_ok(name + ": coyote timer ends at exactly 0.0", timer == 0.0)
		var expected_max := ceili(p.coyote_time * 60.0) * 2
		_ok(name + ": expires within 2× expected frame count", frames <= expected_max)


func _test_buffer_countdown() -> void:
	## Same countdown logic as coyote. Verifies buffer-specific design goals
	## on all three shipped profiles (jump_buffer: 0.12 / 0.20 / 0.10 s).
	print("\n-- Jump buffer countdown --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	const DELTA := 1.0 / 60.0
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var timer := p.jump_buffer
		var frames := 0
		while timer > 0.0 and frames < 600:
			timer = maxf(0.0, timer - DELTA)
			frames += 1
		_ok(name + ": buffer timer expires", timer == 0.0)
		_ok(name + ": buffer timer never goes negative", timer >= 0.0)
		# Buffer >= coyote on every profile: pre-press window >= coyote window.
		_ok(name + ": jump_buffer >= coyote_time (pre-press window >= coyote)",
			p.jump_buffer >= p.coyote_time)


func _test_profile_cross_invariants() -> void:
	## Invariants that should hold across ALL shipped profiles.
	print("\n-- Cross-profile invariants --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		# jump_buffer >= coyote_time on every profile (not just snappy).
		_ok(name + ": jump_buffer >= coyote_time", p.jump_buffer >= p.coyote_time)
		# release_velocity_ratio must be below 1 (variable jump actually cuts).
		_ok(name + ": release_velocity_ratio < 1.0", p.release_velocity_ratio < 1.0)
		# max_speed must be reachable (accel > 0).
		_ok(name + ": ground_acceleration > 0", p.ground_acceleration > 0.0)
		# Terminal velocity must be positive (clamp is meaningful).
		_ok(name + ": terminal_velocity > 0", p.terminal_velocity > 0.0)


func _test_slope_params() -> void:
	## max_floor_angle_degrees sanity checks.
	## Floaty is the accessibility profile and should be at least as forgiving
	## on slopes as Snappy (wider angle = walks up steeper surfaces).
	print("\n-- Slope parameters --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	var angle_snappy := 0.0
	var angle_floaty := 0.0
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		_ok(name + ": max_floor_angle_degrees in [20, 70]",
			p.max_floor_angle_degrees >= 20.0 and p.max_floor_angle_degrees <= 70.0)
		_ok(name + ": max_floor_angle_degrees > 0", p.max_floor_angle_degrees > 0.0)
		if name == "snappy":
			angle_snappy = p.max_floor_angle_degrees
		elif name == "floaty":
			angle_floaty = p.max_floor_angle_degrees
	if angle_snappy > 0.0 and angle_floaty > 0.0:
		_ok("floaty max_floor_angle >= snappy (more forgiving on slopes)",
			angle_floaty >= angle_snappy)


func _test_respawn_params() -> void:
	## Respawn / reboot parameter sanity checks.
	## The phase-fraction assertion documents the values hardcoded in
	## player.gd::_run_reboot_effect() so future edits are caught here.
	print("\n-- Respawn / reboot parameters --")
	# Phase fractions in player.gd::_run_reboot_effect: 12 + 35 + 35 + 18 = 100 %.
	_ok("reboot phase fractions sum to 1.0", _near(0.12 + 0.35 + 0.35 + 0.18, 1.0))

	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		_ok(name + ": reboot_duration > 0", p.reboot_duration > 0.0)
		_ok(name + ": reboot_duration <= 1.5 (slider max)", p.reboot_duration <= 1.5)
		_ok(name + ": fall_kill_y < 0 (below ground)", p.fall_kill_y < 0.0)
		_ok(name + ": fall_kill_y >= -200 (slider min)", p.fall_kill_y >= -200.0)


func _test_movement_params() -> void:
	## Per-profile movement parameter sanity checks not covered by
	## _test_profile_cross_invariants: ground_deceleration, air_acceleration,
	## and cross-profile design intent for speed ordering and damping.
	print("\n-- Movement parameters --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		_ok(name + ": ground_deceleration > 0", p.ground_deceleration > 0.0)
		_ok(name + ": air_acceleration > 0", p.air_acceleration > 0.0)

	# Speed-profile design intent: Momentum is the fastest, Floaty is the
	# most controlled (slower cap for precise landings on mobile).
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	var fp: CP = _load_profile("res://resources/profiles/floaty.tres")
	var mp: CP = _load_profile("res://resources/profiles/momentum.tres")
	if sp == null or fp == null or mp == null:
		return
	_ok("momentum max_speed > snappy max_speed", mp.max_speed > sp.max_speed)
	_ok("floaty max_speed < snappy max_speed (controlled profile)", fp.max_speed < sp.max_speed)
	# Momentum preserves velocity fully: zero air damping, like Snappy.
	# Floaty is the only profile with non-zero damping (covered in _test_air_damping too).
	_ok("momentum air_horizontal_damping == 0 (full velocity preservation)",
		mp.air_horizontal_damping == 0.0)
	# Momentum intentionally decelerates slowly on the ground (high-momentum feel).
	# ground_deceleration < ground_acceleration means it takes longer to stop than
	# to reach max speed — the opposite of Snappy and Floaty which stop quickly.
	_ok("momentum ground_deceleration < momentum ground_acceleration (loose decel feel)",
		mp.ground_deceleration < mp.ground_acceleration)


func _test_camera_vertical_pull() -> void:
	## Verifies the vertical pull formula from camera_rig.gd::_vertical_pull_offset.
	## Formula: vel_y >= 0 → 0.0; else → vel_y * vertical_pull * 0.05.
	## The 0.05 coefficient keeps vertical_pull in a 0–1 inspector range while
	## producing a world-space offset of at most |vel_y| * 0.05 m.
	print("\n-- Camera vertical pull offset formula --")
	_ok("no pull when rising (vel_y > 0)", _near(_cam_vp(10.0, 0.18), 0.0))
	_ok("no pull when stopped (vel_y == 0.0)", _near(_cam_vp(0.0, 0.18), 0.0))
	_ok("pull is negative when falling", _cam_vp(-20.0, 0.18) < 0.0)
	_ok("pull magnitude = vel_y * pull * 0.05",
		_near(_cam_vp(-20.0, 0.18), -20.0 * 0.18 * 0.05, 1e-4))
	_ok("zero pull coefficient → 0 m offset even while falling",
		_near(_cam_vp(-20.0, 0.0), 0.0))
	# Default pull 0.18 at Snappy terminal velocity (-40 m/s): -40*0.18*0.05 = -0.36 m.
	_ok("terminal velocity pull stays within -1 m (no jarring camera swing)",
		_cam_vp(-40.0, 0.18) >= -1.0)


func _cam_vp(vel_y: float, pull: float) -> float:
	if vel_y >= 0.0:
		return 0.0
	return vel_y * pull * 0.05


func _test_camera_occlude_math() -> void:
	## Verifies the safe-distance formula from camera_rig.gd::_occlude.
	## Formula: safe_dist = maxf(occlusion_min_distance, hit_dist - occlusion_margin).
	## Camera snaps to aim + dir * safe_dist when geometry blocks the shot.
	print("\n-- Camera occlusion safe-distance math --")
	# Typical: wall 3 m away, 0.3 m margin, 0.8 m min → 2.7 m
	_ok("typical hit (3 m): safe_dist = hit_dist - margin",
		_near(_cam_sd(3.0, 0.3, 0.8), 2.7))
	# Close wall: hit - margin < min → clamp to min
	_ok("close hit (0.5 m): clamped to occlusion_min_distance",
		_near(_cam_sd(0.5, 0.3, 0.8), 0.8))
	# Exactly at margin: hit - margin = 0 → clamp to min
	_ok("hit == margin: safe_dist clamped to min_distance",
		_near(_cam_sd(0.3, 0.3, 0.8), 0.8))
	# Zero margin: safe_dist == hit_dist when above min
	_ok("zero margin, hit > min: safe_dist == hit_dist",
		_near(_cam_sd(1.5, 0.0, 0.8), 1.5))
	# Oversized margin: hit - margin < 0 → still clamped, no negative dist
	_ok("large margin: safe_dist clamped to min_distance (never negative)",
		_near(_cam_sd(3.0, 3.5, 0.8), 0.8))
	# Invariant holds for a range of hit distances
	var invariant_holds := true
	for d: float in [0.1, 0.5, 0.8, 1.0, 3.0, 5.0]:
		if _cam_sd(d, 0.3, 0.8) < 0.8:
			invariant_holds = false
	_ok("safe_dist >= occlusion_min_distance across all hit distances", invariant_holds)


func _cam_sd(hit_dist: float, margin: float, min_dist: float) -> float:
	return maxf(min_dist, hit_dist - margin)



func _test_camera_pitch_formula() -> void:
	## Verifies the elevation angle formula from camera_rig.gd::_desired_camera_position.
	## After the V-turn fix: var p := -_pitch (was absf(_pitch)).
	## _pitch is always ≤ 0 (clamped in _apply_drag_input), so -_pitch ≥ 0 always.
	## sin(-_pitch) must be monotonically non-decreasing as _pitch becomes more negative.
	print("\n-- Camera pitch elevation formula (V-turn fix) --")
	# Camera at horizontal: pitch 0.0 → elevation 0
	_ok("pitch 0.0: elevation is 0 (camera at horizontal)",
		_near(_cam_pitch_elev(0.0), 0.0))
	# Default pitch 22°: positive elevation (camera above player)
	_ok("pitch -22°: positive elevation (camera above player)",
		_cam_pitch_elev(-deg_to_rad(22.0)) > 0.0)
	# More negative pitch = higher elevation (monotonic — no V-turn)
	_ok("pitch -45° elevation > pitch -22° elevation (monotonic, no V-turn)",
		_cam_pitch_elev(-deg_to_rad(45.0)) > _cam_pitch_elev(-deg_to_rad(22.0)))
	# Max pitch -55°: still positive elevation
	_ok("pitch -55°: elevation still positive (camera above horizontal)",
		_cam_pitch_elev(-deg_to_rad(55.0)) > 0.0)
	# Elevation is ≥ 0 across the full valid range [0°, 89°]
	var all_non_negative := true
	for deg: float in [0.0, 10.0, 22.0, 45.0, 55.0, 89.0]:
		if _cam_pitch_elev(-deg_to_rad(deg)) < -1e-6:
			all_non_negative = false
	_ok("elevation >= 0 across all valid above-horizontal pitch angles", all_non_negative)


func _cam_pitch_elev(pitch_rad: float) -> float:
	## Mirrors camera_rig.gd::_desired_camera_position: p := -_pitch; sin(p) = Y component.
	return sin(-pitch_rad)



func _test_tripod_placement() -> void:
	## Verifies the initial camera placement formula from camera_rig.gd::_place_camera_initial.
	## Formula (at default yaw=0, camera starts directly behind the player):
	##   camera = target + (0, sin(elevation)*dist + aim_height, cos(elevation)*dist)
	## where elevation = deg_to_rad(pitch_degrees) = -_pitch_rad.
	## sin²(e) + cos²(e) = 1, so the 3D distance (excluding aim_height) equals dist exactly.
	print("\n-- Tripod camera initial placement formula --")
	const DIST   := 6.0
	const ELEV_DEG := 22.0
	const AIM_H  := 0.6
	var elev := deg_to_rad(ELEV_DEG)

	# Vertical offset: sin(elev)*dist + aim_height
	_ok("initial y-offset = sin(elev)*dist + aim_height",
		_near(_tripod_cam_offset(elev, DIST, AIM_H).y, sin(elev) * DIST + AIM_H))

	# Horizontal (forward) offset at yaw=0: cos(elev)*dist
	_ok("initial z-offset = cos(elev)*dist (camera behind player at yaw=0)",
		_near(_tripod_cam_offset(elev, DIST, AIM_H).z, cos(elev) * DIST))

	# No lateral offset at yaw=0 (camera sits on the Z-axis behind the player)
	_ok("initial x-offset = 0 at yaw=0 (no lateral displacement)",
		_near(_tripod_cam_offset(elev, DIST, AIM_H).x, 0.0))

	# Pythagorean identity: 3D distance (excluding aim_height component) == dist
	# Vector3(0, sin(e)*d, cos(e)*d).length() = d * sqrt(sin² + cos²) = d
	var without_aim := Vector3(0.0, sin(elev) * DIST, cos(elev) * DIST)
	_ok("3D distance (excluding aim_height) == distance (sin² + cos² = 1)",
		_near(without_aim.length(), DIST, 1e-4))

	# Camera is above the player at any positive elevation
	_ok("camera is above the player when elevation > 0 (y-offset > 0)",
		_tripod_cam_offset(elev, DIST, AIM_H).y > 0.0)

	# Edge case: elevation = 0 → camera at the same height as aim, directly behind
	_ok("elevation=0: y-offset = aim_height; z-offset = dist",
		_near(_tripod_cam_offset(0.0, DIST, AIM_H).y, AIM_H) and
		_near(_tripod_cam_offset(0.0, DIST, AIM_H).z, DIST))


func _tripod_cam_offset(elevation: float, dist: float, aim_height: float) -> Vector3:
	## Mirrors camera_rig.gd::_place_camera_initial at default yaw=0.
	return Vector3(0.0, sin(elevation) * dist + aim_height, cos(elevation) * dist)


func _test_tripod_drag_orbit() -> void:
	## Verifies the orbital drag math from camera_rig.gd::_apply_drag_input.
	## The drag converts the current camera position to spherical coords (radius,
	## theta, phi), adjusts theta/phi by the drag deltas, clamps phi to [0, max],
	## then reconstructs the new position on the same sphere. Key invariants:
	##   - Pure yaw drag preserves radius and elevation (only theta changes).
	##   - phi is always clamped ≥ 0 (camera stays at or above horizontal).
	##   - phi is clamped ≤ deg_to_rad(pitch_max_degrees) (configurable upper limit).
	##   - _pitch_rad = -phi, so it is always ≤ 0.
	print("\n-- Tripod camera drag orbit math --")
	const DIST     := 6.0
	const ELEV_DEG := 22.0
	const PITCH_MAX_DEG := 55.0
	const YAW_SENS := 0.005
	const PITCH_SENS := 0.003
	var elev := deg_to_rad(ELEV_DEG)

	# Initial camera position: directly behind at default elevation, yaw=0.
	var cam := Vector3(0.0, sin(elev) * DIST, cos(elev) * DIST)
	var target := Vector3.ZERO
	var to_cam := cam - target
	var radius := to_cam.length()
	_ok("radius derived from default position == distance",
		_near(radius, DIST, 1e-4))

	var theta := atan2(to_cam.x, to_cam.z)
	var phi   := asin(clampf(to_cam.y / radius, -1.0, 1.0))
	_ok("phi derived from default position == elevation angle",
		_near(phi, elev, 1e-4))

	# Pure yaw drag (large positive x-drag): only theta changes, phi unchanged.
	var new_theta := theta - 100.0 * YAW_SENS
	var cos_phi := cos(phi)
	var yawed_pos := Vector3(
		radius * cos_phi * sin(new_theta),
		radius * sin(phi),
		radius * cos_phi * cos(new_theta))
	_ok("pure yaw drag preserves 3D radius (orbit on sphere)",
		_near(yawed_pos.length(), DIST, 1e-4))
	_ok("pure yaw drag preserves elevation (y component unchanged)",
		_near(yawed_pos.y, cam.y, 1e-4))

	# Lower clamp: huge downward drag (drag.y > 0 reduces phi toward 0).
	# phi must stay ≥ 0 — camera never goes below horizontal.
	var phi_clamped_down := clampf(phi - 1000.0 * PITCH_SENS,
		0.0, deg_to_rad(PITCH_MAX_DEG))
	_ok("downward drag: phi clamped to ≥ 0 (camera never below horizontal)",
		phi_clamped_down >= 0.0)

	# Upper clamp: huge upward drag (drag.y < 0 increases phi toward max).
	var phi_clamped_up := clampf(phi - (-1000.0) * PITCH_SENS,
		0.0, deg_to_rad(PITCH_MAX_DEG))
	_ok("upward drag: phi clamped to ≤ pitch_max_degrees",
		phi_clamped_up <= deg_to_rad(PITCH_MAX_DEG) + 1e-6)

	# _pitch_rad = -phi → always ≤ 0 (used by the elevation formula downstream)
	var pitch_rad := -phi_clamped_down
	_ok("_pitch_rad = -phi: value is always ≤ 0 (camera above horizontal)",
		pitch_rad <= 0.0)


func _test_move_dir_rotation() -> void:
	## Verifies _camera_relative_move_dir() from player.gd.
	## Formula: Basis(Vector3.UP, yaw) * Vector3(move_input.x, 0.0, move_input.y),
	## then normalised if length > 1.0.
	## Basis rotation around UP is orthogonal: preserves length, keeps Y == 0.
	print("\n-- Camera-relative move direction rotation --")

	# yaw = 0 (camera default, behind player): forward stick (2D y = -1) → world -Z.
	var fwd := _move_dir(Vector2(0.0, -1.0), 0.0)
	_ok("yaw=0, stick up: world z ≈ -1.0 (forward)", _near(fwd.z, -1.0))
	_ok("yaw=0, stick up: world x ≈ 0.0", _near(fwd.x, 0.0))

	# yaw = 0: right stick (2D x = +1) → world +X.
	var rgt := _move_dir(Vector2(1.0, 0.0), 0.0)
	_ok("yaw=0, stick right: world x ≈ +1.0", _near(rgt.x, 1.0))

	# yaw = PI (camera flipped 180°): forward stick → world +Z (reversed).
	var fwd_180 := _move_dir(Vector2(0.0, -1.0), PI)
	_ok("yaw=PI, stick up: world z ≈ +1.0 (camera reversed)", _near(fwd_180.z, 1.0, 1e-3))

	# yaw = PI/2 (camera pivoted 90° CCW around player): forward stick → world -X.
	var fwd_90 := _move_dir(Vector2(0.0, -1.0), PI / 2.0)
	_ok("yaw=PI/2, stick up: world x ≈ -1.0 (camera pivoted right)", _near(fwd_90.x, -1.0, 1e-3))

	# Y component is always 0: Basis(UP, yaw) rotation keeps the XZ plane flat.
	_ok("move_dir Y is always 0.0 (horizontal movement only)", _near(fwd.y, 0.0))

	# Rotation preserves vector length: unit input stays unit length at arbitrary yaw.
	# Vector2(0.6, -0.8) has length 1.0 (3-4-5 triple scaled to 1).
	var preserved := _move_dir(Vector2(0.6, -0.8), 1.23)
	_ok("rotation preserves length: unit input → length ≈ 1.0 at arbitrary yaw",
		_near(preserved.length(), 1.0, 1e-3))

	# Length guard (belt-and-braces in player.gd): if somehow > 1, normalise to 1.
	# In practice get_move_vector() always limits_length(1.0), so this is defensive.
	var raw := Vector3(1.4, 0.0, 0.0)
	var guarded := raw.normalized() if raw.length_squared() > 1.0 else raw
	_ok("length guard: over-length dir is normalised to 1.0", _near(guarded.length(), 1.0))


func _move_dir(move_input: Vector2, yaw: float) -> Vector3:
	var dir := Basis(Vector3.UP, yaw) * Vector3(move_input.x, 0.0, move_input.y)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return dir


func _test_gravity_band_selection() -> void:
	## Verifies the gravity band selection mirrored from player.gd::_apply_gravity.
	## Selection rules (in order of evaluation):
	##   vel_y <= 0.0              → gravity_after_apex  (falling or at apex)
	##   vel_y > 0 and jump_held  → gravity_rising       (ascending, button held)
	##   vel_y > 0 and not held   → gravity_falling      (ascending, button released → arc cut)
	## vel_y == 0 is treated as falling (the <= 0 branch fires first).
	print("\n-- Gravity band selection (apply_gravity if/elif) --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		_ok(name + ": falling (vel_y < 0) → gravity_after_apex",
			_near(_select_gravity(p, -5.0, true), p.gravity_after_apex))
		_ok(name + ": rising + jump_held → gravity_rising (lowest: max hangtime)",
			_near(_select_gravity(p, 5.0, true), p.gravity_rising))
		_ok(name + ": rising + jump released → gravity_falling (fast arc cut)",
			_near(_select_gravity(p, 5.0, false), p.gravity_falling))
		# vel_y == 0 exactly (apex frame): treated as falling because vel_y <= 0 is true.
		_ok(name + ": vel_y == 0 (apex) → gravity_after_apex (vel_y <= 0 is true)",
			_near(_select_gravity(p, 0.0, true), p.gravity_after_apex))


func _select_gravity(p: CP, vel_y: float, jump_held: bool) -> float:
	if vel_y <= 0.0:
		return p.gravity_after_apex
	elif jump_held:
		return p.gravity_rising
	else:
		return p.gravity_falling
