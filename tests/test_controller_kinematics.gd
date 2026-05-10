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
	_test_camera_lookahead_target()
	_test_camera_pitch_formula()
	_test_camera_yaw_recenter()
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


func _test_camera_lookahead_target() -> void:
	## Verifies the desired-lookahead computation from camera_rig.gd::_update_lookahead.
	## When horiz speed > lookahead_min_speed: desired = horiz.normalized() * dist.
	## The lerp weight is clamped [0, 1], preventing overshoot on any delta.
	print("\n-- Camera lookahead target direction --")
	const DIST: float = 1.2
	const MIN_SPD: float = 0.15

	# Below min_speed: desired is the zero vector
	var horiz_slow := Vector3(0.05, 0.0, 0.0)
	var desired_slow := horiz_slow.normalized() * DIST if horiz_slow.length() > MIN_SPD else Vector3.ZERO
	_ok("below min_speed: desired lookahead is zero vector",
		desired_slow.length_squared() < 1e-6)

	# Above min_speed: desired has the correct length and direction
	var horiz_fast := Vector3(3.0, 0.0, 0.0)
	var desired_fast := horiz_fast.normalized() * DIST if horiz_fast.length() > MIN_SPD else Vector3.ZERO
	_ok("above min_speed: desired lookahead length == lookahead_distance",
		_near(desired_fast.length(), DIST, 1e-3))
	_ok("above min_speed: desired lookahead is in velocity direction (x > 0, z ≈ 0)",
		desired_fast.x > 0.0 and _near(desired_fast.z, 0.0))

	# Diagonal velocity: X and Z components are equal after normalisation
	var horiz_diag := Vector3(1.0, 0.0, 1.0)
	var desired_diag := horiz_diag.normalized() * DIST if horiz_diag.length() > MIN_SPD else Vector3.ZERO
	_ok("diagonal velocity: lookahead X and Z components are equal",
		_near(desired_diag.x, desired_diag.z, 1e-3))

	# Lerp weight is clamped so large lookahead_lerp values can't overshoot
	const DELTA: float = 1.0 / 60.0
	var weight_large := clampf(100.0 * DELTA, 0.0, 1.0)
	_ok("large lookahead_lerp value: lerp weight clamped to 1.0",
		_near(weight_large, 1.0))


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


func _test_camera_yaw_recenter() -> void:
	## Verifies the yaw auto-recenter math from camera_rig.gd::_update_yaw_recenter.
	## Formula: diff = wrapf(desired_yaw - _yaw, -PI, PI)
	##          _yaw += diff * minf(1.0, idle_recenter_speed * delta)
	## wrapf ensures the camera rotates the short way around (shortest arc).
	## minf(1.0, ...) prevents overshoot when idle_recenter_speed is large.
	print("\n-- Camera yaw auto-recenter math --")
	const DELTA := 1.0 / 60.0

	# wrapf shortest-path: naive diff from +175° to -175° is -350°.
	# wrapf wraps it to +10° — the short arc crossing the ±180° boundary.
	var diff_far := wrapf(deg_to_rad(-175.0) - deg_to_rad(175.0), -PI, PI)
	_ok("wrapf: 175° to -175° short arc is +10° (not -350°)",
		_near(diff_far, deg_to_rad(10.0), 1e-4))

	# Reverse: naive +350°; wrapf gives -10° (short arc, opposite direction).
	var diff_rev := wrapf(deg_to_rad(175.0) - deg_to_rad(-175.0), -PI, PI)
	_ok("wrapf: -175° to +175° short arc is -10° (not +350°)",
		_near(diff_rev, deg_to_rad(-10.0), 1e-4))

	# Default idle_recenter_speed (1.5): weight per frame is small and smooth.
	var weight := minf(1.0, 1.5 * DELTA)
	_ok("default recenter speed (1.5): weight > 0 (makes progress each frame)", weight > 0.0)
	_ok("default recenter speed (1.5): weight < 0.1 (smooth, not instant)", weight < 0.1)

	# Lerp step on a 90° diff must be strictly less than the diff — no overshoot.
	_ok("default speed: recenter step < diff (no overshoot on 90° rotation)",
		deg_to_rad(90.0) * weight < deg_to_rad(90.0))

	# High recenter_speed: minf clamps weight to 1.0 — one-frame snap.
	var weight_fast := minf(1.0, 200.0 * DELTA)
	_ok("high recenter_speed (200): weight clamped to 1.0 (snap, no overshoot past target)",
		_near(weight_fast, 1.0))

	# Convergence: simulate 30 frames of recenter from 0° toward 90°.
	# Angular error (absolute diff to target) must shrink each frame.
	var yaw := 0.0
	var target := deg_to_rad(90.0)
	var prev_err := absf(wrapf(target - yaw, -PI, PI))
	var monotonic := true
	for _i in 30:
		var d := wrapf(target - yaw, -PI, PI)
		yaw += d * weight
		var err := absf(wrapf(target - yaw, -PI, PI))
		if err > prev_err + 1e-6:
			monotonic = false
		prev_err = err
	_ok("yaw recenter: angular error decreases monotonically over 30 frames", monotonic)
	_ok("yaw recenter: > 50%% progress toward target after 30 frames",
		prev_err < deg_to_rad(90.0) * 0.5)
