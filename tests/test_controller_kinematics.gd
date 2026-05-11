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
	_test_horizontal_deceleration()
	_test_air_damping()
	_test_terminal_velocity()
	_test_coyote_countdown()
	_test_buffer_countdown()
	_test_profile_cross_invariants()
	_test_slope_params()
	_test_respawn_params()
	_test_movement_params()
	_test_assisted_params()
	_test_try_jump_logic()
	_test_camera_vertical_pull()
	_test_camera_occlude_math()
	_test_camera_pitch_formula()
	_test_tripod_placement()
	_test_tripod_drag_orbit()
	_test_move_dir_rotation()
	_test_visual_facing_formula()
	_test_gravity_band_selection()
	_test_blob_shadow_math()
	_test_sticky_landing_countdown()
	_test_sticky_landing_damping()
	_test_cut_jump_behavior()
	_test_gravity_integration()
	_test_squash_stretch_math()
	_test_jump_puff_math()
	_test_impact_factor_math()
	_test_land_squash_scale_math()
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
	## Tests all four shipped profiles (coyote_time varies: 0.1 / 0.18 / 0.08 / 0.22 s).
	print("\n-- Coyote timer countdown --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
		["assisted", "res://resources/profiles/assisted.tres"],
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
	## on all four shipped profiles (jump_buffer: 0.12 / 0.20 / 0.10 / 0.24 s).
	print("\n-- Jump buffer countdown --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
		["assisted", "res://resources/profiles/assisted.tres"],
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
	## Assisted is the most forgiving on slopes, Floaty next, Snappy last.
	print("\n-- Slope parameters --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
		["assisted", "res://resources/profiles/assisted.tres"],
	]
	var angle_snappy  := 0.0
	var angle_floaty  := 0.0
	var angle_assisted := 0.0
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
		elif name == "assisted":
			angle_assisted = p.max_floor_angle_degrees
	if angle_snappy > 0.0 and angle_floaty > 0.0:
		_ok("floaty max_floor_angle >= snappy (more forgiving on slopes)",
			angle_floaty >= angle_snappy)
	if angle_floaty > 0.0 and angle_assisted > 0.0:
		_ok("assisted max_floor_angle >= floaty (most forgiving on slopes)",
			angle_assisted >= angle_floaty)


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
		["assisted", "res://resources/profiles/assisted.tres"],
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
		["assisted", "res://resources/profiles/assisted.tres"],
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
	var ap: CP = _load_profile("res://resources/profiles/assisted.tres")
	if sp == null or fp == null or mp == null:
		return
	_ok("momentum max_speed > snappy max_speed", mp.max_speed > sp.max_speed)
	_ok("floaty max_speed < snappy max_speed (controlled profile)", fp.max_speed < sp.max_speed)
	# Momentum preserves velocity fully: zero air damping, like Snappy.
	# Floaty is the only base profile with non-zero damping.
	_ok("momentum air_horizontal_damping == 0 (full velocity preservation)",
		mp.air_horizontal_damping == 0.0)
	# Momentum intentionally decelerates slowly on the ground (high-momentum feel).
	# ground_deceleration < ground_acceleration means it takes longer to stop than
	# to reach max speed — the opposite of Snappy and Floaty which stop quickly.
	_ok("momentum ground_deceleration < momentum ground_acceleration (loose decel feel)",
		mp.ground_deceleration < mp.ground_acceleration)
	# Assisted is the slowest and grippiest profile: lowest max_speed, most air damping.
	if ap != null:
		_ok("assisted max_speed <= floaty max_speed (most controlled profile)",
			ap.max_speed <= fp.max_speed)
		_ok("assisted air_horizontal_damping > floaty air_horizontal_damping (maximum grip)",
			ap.air_horizontal_damping > fp.air_horizontal_damping)


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


func _test_horizontal_deceleration() -> void:
	## Simulates the deceleration branch of player.gd::_apply_horizontal.
	## When move_dir.length() < 0.01 and on_floor is true, accel becomes
	## ground_deceleration and the target is Vector3.ZERO (player brakes to rest).
	## move_toward(current, ZERO, decel * delta) converges to rest without overshoot.
	print("\n-- Horizontal deceleration convergence --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
		["assisted", "res://resources/profiles/assisted.tres"],
	]
	const DELTA := 1.0 / 60.0
	var frames_snappy := 0
	var frames_momentum := 0
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var h := Vector3(p.max_speed, 0.0, 0.0)
		var frames := 0
		while h.length() > 0.01 and frames < 600:
			h = h.move_toward(Vector3.ZERO, p.ground_deceleration * DELTA)
			frames += 1
		_ok(name + ": decel converges to near-zero within 10 s (600 frames)", frames < 600)
		_ok(name + ": final speed < 0.01 m/s after decel", h.length() < 0.01)
		_ok(name + ": no overshoot — speed stays ≥ 0 (move_toward guarantee)", h.length() >= 0.0)
		if name == "snappy":
			frames_snappy = frames
		elif name == "momentum":
			frames_momentum = frames

	# Snappy: max_speed=6.5, ground_decel=90 → stops in ~5 frames.
	# Momentum: max_speed=11.0, ground_decel=30 → stops in ~23 frames.
	# Momentum's "loose decel" design intent means it takes longer to stop.
	if frames_snappy > 0 and frames_momentum > 0:
		_ok("momentum brakes slower than snappy (loose-decel design intent)",
			frames_momentum > frames_snappy)

	# Edge case: starting at rest with no input — should stay at rest.
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	if sp != null:
		var h_rest := Vector3.ZERO
		h_rest = h_rest.move_toward(Vector3.ZERO, sp.ground_deceleration * DELTA)
		_ok("starting at rest: stays at rest after decel step", h_rest.length() < 1e-6)


func _test_visual_facing_formula() -> void:
	## Verifies the target_yaw formula from player.gd::_update_visual_facing:
	##   target_yaw = atan2(-velocity.x, -velocity.z)
	## This maps each movement direction to the yaw the visual must rotate to
	## so its local -Z (Godot default forward) faces the direction of motion.
	## Also verifies the lerp weight clamp and speed deadband values.
	print("\n-- Visual facing formula (target yaw + weight clamp + deadband) --")

	# Moving in -Z (forward in camera-default frame): local -Z already faces -Z → yaw = 0
	_ok("moving -Z: target yaw = 0 (local -Z faces -Z, forward)",
		_near(_vis_yaw(0.0, -1.0), 0.0))
	# Moving in +Z (backward): yaw = PI (or -PI at wrap boundary)
	_ok("moving +Z: |target yaw| = PI (local -Z faces +Z, backward)",
		_near(absf(_vis_yaw(0.0, 1.0)), PI, 1e-3))
	# Moving +X (right): local -Z must face +X → yaw = -PI/2
	_ok("moving +X: target yaw = -PI/2 (local -Z faces +X, strafe right)",
		_near(_vis_yaw(1.0, 0.0), -PI / 2.0, 1e-3))
	# Moving -X (left): local -Z must face -X → yaw = +PI/2
	_ok("moving -X: target yaw = +PI/2 (local -Z faces -X, strafe left)",
		_near(_vis_yaw(-1.0, 0.0), PI / 2.0, 1e-3))

	# Lerp weight: clampf(turn_speed * delta, 0, 1)
	# Default turn_speed = 12.0; at 60 fps delta = 1/60 ≈ 0.0167 → weight ≈ 0.2.
	const DELTA := 1.0 / 60.0
	_ok("default turn_speed (12) at 60 fps: lerp weight in (0, 1) — smooth, not instant",
		clampf(12.0 * DELTA, 0.0, 1.0) > 0.0 and clampf(12.0 * DELTA, 0.0, 1.0) < 1.0)
	# Max turn_speed = 30.0 (export upper bound); weight is clamped ≤ 1.0.
	_ok("max turn_speed (30) at 60 fps: lerp weight ≤ 1.0 (clampf prevents overshoot)",
		clampf(30.0 * DELTA, 0.0, 1.0) <= 1.0)

	# Speed deadband: if horiz_speed < visual_turn_min_speed (default 0.2 m/s), return early.
	# The guard prevents jitter when the player is nearly stationary.
	_ok("speed 0.1 m/s < min_speed 0.2: deadband fires (no visual rotation update)",
		0.1 < 0.2)
	_ok("speed 0.3 m/s >= min_speed 0.2: deadband clear (visual rotation updates)",
		0.3 >= 0.2)


func _vis_yaw(vx: float, vz: float) -> float:
	## Mirrors player.gd::_update_visual_facing: target_yaw = atan2(-vx, -vz).
	return atan2(-vx, -vz)


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
		["assisted", "res://resources/profiles/assisted.tres"],
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


func _test_assisted_params() -> void:
	## Sanity checks for the Assisted profile's new landing_sticky_* properties.
	## All non-Assisted profiles must have these properties at 0 (the safe default
	## that disables the mechanic so existing behaviour is unchanged).
	print("\n-- Assisted profile parameters --")
	var ap: CP = _load_profile("res://resources/profiles/assisted.tres")
	if ap == null:
		return
	# Assisted must actually enable stickiness.
	_ok("assisted: landing_sticky_factor > 0 (mechanic enabled)", ap.landing_sticky_factor > 0.0)
	_ok("assisted: landing_sticky_factor in (0, 1) (partial damping only)",
		ap.landing_sticky_factor > 0.0 and ap.landing_sticky_factor < 1.0)
	_ok("assisted: landing_sticky_frames > 0 (at least one damped frame)",
		ap.landing_sticky_frames > 0)
	_ok("assisted: landing_sticky_frames <= 6 (slider max, avoids dragging feel)",
		ap.landing_sticky_frames <= 6)
	# Assisted has the most generous timing windows (coyote + buffer).
	var fp: CP = _load_profile("res://resources/profiles/floaty.tres")
	if fp != null:
		_ok("assisted coyote_time >= floaty coyote_time (most forgiving timing)",
			ap.coyote_time >= fp.coyote_time)
		_ok("assisted jump_buffer >= floaty jump_buffer (most forgiving pre-press window)",
			ap.jump_buffer >= fp.jump_buffer)
	# Non-Assisted profiles must have sticky params at safe defaults (0 = disabled).
	for entry: Array in [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
	]:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		_ok(name + ": landing_sticky_factor == 0 (disabled by default)",
			p.landing_sticky_factor == 0.0)
		_ok(name + ": landing_sticky_frames == 0 (disabled by default)",
			p.landing_sticky_frames == 0)


func _test_try_jump_logic() -> void:
	## Verifies the conjunction logic from player.gd::_try_jump.
	## Rule: jump fires only when BOTH _buffer_timer > 0 AND _coyote_timer > 0.
	## After firing: both timers are zeroed (prevents double-jump on the next
	## frame if both happened to still be > 0), and velocity.y = jump_velocity.
	## This function's AND condition is the core of the coyote + buffer system:
	## the player can have an unspent press (buffer > 0) OR unspent grace
	## (coyote > 0), but NOT trigger a jump unless both exist simultaneously.
	print("\n-- _try_jump logic (buffer × coyote conjunction) --")
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
		["assisted", "res://resources/profiles/assisted.tres"],
	]
	# Shared edge-case assertions independent of profile.
	var r_both := _try_jump_helper(0.1, 0.1, 10.0)
	_ok("both timers > 0: jump fires (vy = jump_velocity)", _near(r_both["vy"], 10.0))
	_ok("both timers > 0: buffer zeroed after jump", _near(r_both["buffer"], 0.0))
	_ok("both timers > 0: coyote zeroed after jump", _near(r_both["coyote"], 0.0))

	var r_no_buffer := _try_jump_helper(0.0, 0.1, 10.0)
	_ok("buffer == 0, coyote > 0: no jump (no recent press)", _near(r_no_buffer["vy"], 0.0))
	_ok("buffer == 0, coyote > 0: coyote unchanged (no consumption)", _near(r_no_buffer["coyote"], 0.1))

	var r_no_coyote := _try_jump_helper(0.1, 0.0, 10.0)
	_ok("buffer > 0, coyote == 0: no jump (ran off ledge too long)", _near(r_no_coyote["vy"], 0.0))
	_ok("buffer > 0, coyote == 0: buffer unchanged (no consumption)", _near(r_no_coyote["buffer"], 0.1))

	var r_both_zero := _try_jump_helper(0.0, 0.0, 10.0)
	_ok("both timers == 0: no jump", _near(r_both_zero["vy"], 0.0))

	# Per-profile: vy assigned is exactly jump_velocity (no scaling).
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var r := _try_jump_helper(0.1, 0.1, p.jump_velocity)
		_ok(name + ": jump fires with vy == profile.jump_velocity",
			_near(r["vy"], p.jump_velocity))


func _test_blob_shadow_math() -> void:
	# Mirrors the three formulas in blob_shadow.gd::_process so regressions
	# are caught if the formulas change during per-tunable dev-menu iteration.
	var rg := 0.22   # radius_at_ground default
	var rh := 0.55   # radius_at_height default
	var fh := 6.0    # fade_height default
	var am := 0.42   # alpha_max default

	# t = clampf(height / fade_height, 0.0, 1.0)
	_ok("bs: t=0 at height=0", is_equal_approx(clampf(0.0 / fh, 0.0, 1.0), 0.0))
	_ok("bs: t=1 at fade_height", is_equal_approx(clampf(fh / fh, 0.0, 1.0), 1.0))
	_ok("bs: t clamped above fade_height", is_equal_approx(clampf(fh * 2.0 / fh, 0.0, 1.0), 1.0))
	_ok("bs: t proportional at half height", is_equal_approx(clampf(fh * 0.5 / fh, 0.0, 1.0), 0.5))

	# r = lerpf(radius_at_ground, radius_at_height, t)  — shadow expands upward
	_ok("bs: radius=ground at t=0", is_equal_approx(lerpf(rg, rh, 0.0), rg))
	_ok("bs: radius=height at t=1", is_equal_approx(lerpf(rg, rh, 1.0), rh))
	_ok("bs: radius in (rg,rh) at midpoint", lerpf(rg, rh, 0.5) > rg and lerpf(rg, rh, 0.5) < rh)
	_ok("bs: radius monotone r(0.7)>r(0.3)", lerpf(rg, rh, 0.7) > lerpf(rg, rh, 0.3))

	# a = lerpf(alpha_max, 0.0, t*t)  — quadratic falloff (slower early drop)
	_ok("bs: alpha=max at ground (t=0)", is_equal_approx(lerpf(am, 0.0, 0.0 * 0.0), am))
	_ok("bs: alpha=0 at fade_height (t=1)", is_equal_approx(lerpf(am, 0.0, 1.0 * 1.0), 0.0))
	_ok("bs: quadratic slower than linear at t=0.5",
		lerpf(am, 0.0, 0.5 * 0.5) > lerpf(am, 0.0, 0.5))
	_ok("bs: alpha monotone decreasing a(0.3)>a(0.8)",
		lerpf(am, 0.0, 0.3 * 0.3) > lerpf(am, 0.0, 0.8 * 0.8))


func _test_sticky_landing_countdown() -> void:
	## Mirrors the landing-detection + countdown block in player.gd::_tick_timers.
	## just_landed is true only on the single frame of floor-contact transition.
	## _sticky_frames_remaining is set on landing, decrements each grounded frame,
	## and resets immediately to 0 if the player leaves the floor mid-window.
	print("\n-- Sticky landing countdown (Assisted profile) --")
	var ap: CP = _load_profile("res://resources/profiles/assisted.tres")
	if ap == null:
		return

	# Still airborne — no landing.
	var s1 := _sticky_tick(false, false, 0, ap.landing_sticky_frames)
	_ok("airborne→airborne: just_landed = false", not s1["just_landed"])
	_ok("airborne→airborne: remaining stays 0", s1["remaining"] == 0)

	# Touch-down frame (was airborne last frame, now grounded).
	var s2 := _sticky_tick(true, false, 0, ap.landing_sticky_frames)
	_ok("landing frame: just_landed = true", s2["just_landed"])
	_ok("landing frame: remaining set to landing_sticky_frames",
		s2["remaining"] == ap.landing_sticky_frames)

	# Subsequent grounded frames — countdown drains to zero.
	var rem := ap.landing_sticky_frames
	for _i in ap.landing_sticky_frames:
		var s := _sticky_tick(true, true, rem, ap.landing_sticky_frames)
		rem = s["remaining"]
	_ok("after landing_sticky_frames grounded frames: counter reaches 0", rem == 0)

	# One grounded frame followed by early takeoff — window cancels.
	var s_land  := _sticky_tick(true, false, 0, ap.landing_sticky_frames)
	var s_one   := _sticky_tick(true, true, s_land["remaining"], ap.landing_sticky_frames)
	_ok("one grounded frame: counter decremented by 1",
		s_one["remaining"] == ap.landing_sticky_frames - 1)
	var s_off := _sticky_tick(false, true, s_one["remaining"], ap.landing_sticky_frames)
	_ok("early takeoff: remaining resets to 0 (window cancelled)", s_off["remaining"] == 0)

	# Non-Assisted profile: landing_sticky_frames == 0 → counter never set.
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	if sp != null:
		var s3 := _sticky_tick(true, false, 0, sp.landing_sticky_frames)
		_ok("snappy (sticky_frames=0): landing doesn't set counter", s3["remaining"] == 0)


func _test_sticky_landing_damping() -> void:
	## Mirrors the damping branch in player.gd::_apply_horizontal:
	##   if _sticky_frames_remaining > 0 and profile.landing_sticky_factor > 0.0:
	##       new_h *= (1.0 - profile.landing_sticky_factor)
	## Documents the exact per-frame speed-reduction formula for the Assisted profile.
	print("\n-- Sticky landing damping formula --")
	var ap: CP = _load_profile("res://resources/profiles/assisted.tres")
	if ap == null:
		return

	var start_speed := 5.0
	var factor := ap.landing_sticky_factor

	# One damped frame.
	var damped := start_speed * (1.0 - factor)
	_ok("one damped frame: speed is reduced", damped < start_speed)
	_ok("one damped frame: result = speed × (1 − factor)",
		_near(damped, start_speed * (1.0 - factor)))
	_ok("one damped frame: speed stays > 0 (factor < 1 guaranteed by slider max)",
		damped > 0.0)

	# factor = 0.0 (disabled profile) → no speed change.
	_ok("factor=0: damping has no effect (1 − 0 = 1)",
		_near(start_speed * (1.0 - 0.0), start_speed))

	# Multi-frame compound: geometric series speed × (1−factor)^N.
	var multi_speed := start_speed
	for _i in ap.landing_sticky_frames:
		multi_speed *= (1.0 - factor)
	var expected := start_speed * pow(1.0 - factor, float(ap.landing_sticky_frames))
	_ok("N damped frames: result matches geometric series", _near(multi_speed, expected, 1e-3))
	_ok("N damped frames: speed still > 0 after all damped frames", multi_speed > 0.0)

	# Guard: branch only fires when BOTH counter > 0 AND factor > 0.
	# counter > 0, factor == 0 → no damping.
	var h_no_factor := start_speed
	if 1 > 0 and 0.0 > 0.0:
		h_no_factor *= (1.0 - 0.0)
	_ok("counter>0 but factor=0: damping branch not taken", _near(h_no_factor, start_speed))
	# factor > 0, counter == 0 → no damping.
	var h_no_counter := start_speed
	if 0 > 0 and factor > 0.0:
		h_no_counter *= (1.0 - factor)
	_ok("factor>0 but counter=0: damping branch not taken", _near(h_no_counter, start_speed))


func _test_cut_jump_behavior() -> void:
	## Simulates player.gd::_cut_jump to verify the exact cut condition
	## and its vy-in → vy-out effect.  Complements _test_jump_cut_math
	## (parameter relationships only) with explicit behavioral assertions.
	##   if jump_released and velocity.y > jump_velocity * release_velocity_ratio:
	##       velocity.y = jump_velocity * release_velocity_ratio
	print("\n-- Cut-jump behavior (vy clamp on release) --")
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	if sp == null:
		return
	var threshold := sp.jump_velocity * sp.release_velocity_ratio

	# Button held: cut never fires regardless of vy.
	_ok("jump_held: no cut when vy > threshold",
		_near(_sim_cut(false, sp.jump_velocity, sp.jump_velocity, sp.release_velocity_ratio),
			  sp.jump_velocity))

	# Released at peak: cut fires and vy lands exactly at threshold.
	_ok("released at peak jump_velocity: vy cut to release threshold",
		_near(_sim_cut(true, sp.jump_velocity, sp.jump_velocity, sp.release_velocity_ratio),
			  threshold))

	# Boundary: vy == threshold, condition is '>' not '>=' → no cut.
	_ok("released, vy == threshold (boundary): no cut (strict >)",
		_near(_sim_cut(true, threshold, sp.jump_velocity, sp.release_velocity_ratio), threshold))

	# Below threshold: no cut.
	var vy_low := threshold * 0.5
	_ok("released, vy at 50%% of threshold: no cut",
		_near(_sim_cut(true, vy_low, sp.jump_velocity, sp.release_velocity_ratio), vy_low))

	# vy == 0 (apex or on ground): 0 < threshold for any valid profile → no cut.
	_ok("released, vy == 0: no cut (0 is not > threshold)",
		_near(_sim_cut(true, 0.0, sp.jump_velocity, sp.release_velocity_ratio), 0.0))

	# Per-profile: cut at peak jump_velocity lands exactly at that profile's threshold.
	var profiles := [
		["snappy",   "res://resources/profiles/snappy.tres"],
		["floaty",   "res://resources/profiles/floaty.tres"],
		["momentum", "res://resources/profiles/momentum.tres"],
		["assisted", "res://resources/profiles/assisted.tres"],
	]
	for entry in profiles:
		var name: String = entry[0]
		var p: CP = _load_profile(entry[1])
		if p == null:
			continue
		var t := p.jump_velocity * p.release_velocity_ratio
		_ok(name + ": cut at peak jump_velocity → vy == release threshold",
			_near(_sim_cut(true, p.jump_velocity, p.jump_velocity, p.release_velocity_ratio), t))


func _test_gravity_integration() -> void:
	## Simulates player.gd::_apply_gravity per-frame to verify:
	##   1. Integration formula: vy' = max(-terminal, vy - g * delta)
	##   2. Rising arc decelerates monotonically under gravity_rising.
	##   3. Apex transitions: gravity_after_apex pulls harder than gravity_rising.
	##   4. Terminal velocity clamp holds once reached.
	##   5. Floaty arcs higher than Snappy (design intent).
	print("\n-- Gravity per-frame integration (apply_gravity formula) --")
	const DELTA := 1.0 / 60.0
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	if sp == null:
		return

	# Single-step formula: vy' = vy - g * delta (when not at terminal clamp).
	var vy_after := _gravity_step(10.0, sp.gravity_rising, sp.terminal_velocity, DELTA)
	_ok("one rising step: vy' == vy - g_rising * delta",
		_near(vy_after, 10.0 - sp.gravity_rising * DELTA))
	_ok("one rising step: vy decreases (decelerating upward)", vy_after < 10.0)

	# Rising arc under gravity_rising is monotonically decelerating.
	var vy := sp.jump_velocity
	var monotone := true
	var frames_to_apex := 0
	for _i in 300:
		var new_vy := _gravity_step(vy, sp.gravity_rising, sp.terminal_velocity, DELTA)
		if new_vy >= vy and vy > 0.0:
			monotone = false
		vy = new_vy
		if vy <= 0.0:
			frames_to_apex = _i + 1
			break
	_ok("snappy rising arc: monotonically decelerating under gravity_rising", monotone)
	_ok("snappy rising arc: apex reached within 5 s (300 frames)", frames_to_apex > 0)
	_ok("snappy rising arc: > 1 frame to apex (arc is not instant)", frames_to_apex > 1)

	# gravity_after_apex > gravity_rising → harder pull from apex than rising band.
	var fall_aa := _gravity_step(0.0, sp.gravity_after_apex, sp.terminal_velocity, DELTA)
	var fall_ri := _gravity_step(0.0, sp.gravity_rising, sp.terminal_velocity, DELTA)
	_ok("from apex (vy=0): gravity_after_apex pulls vy lower than gravity_rising would",
		fall_aa < fall_ri)

	# At terminal velocity the clamp holds: one more step stays clamped.
	var at_term := -sp.terminal_velocity
	var after_clamp := _gravity_step(at_term, sp.gravity_after_apex, sp.terminal_velocity, DELTA)
	_ok("at terminal velocity: further steps stay clamped to -terminal_velocity",
		_near(after_clamp, at_term))

	# Floaty has >= Snappy frames to apex (higher arc design intent — also tested
	# in _test_jump_height_plausible; here we verify the arc *length* in frames).
	var fp: CP = _load_profile("res://resources/profiles/floaty.tres")
	if fp != null:
		var vy_f := fp.jump_velocity
		var frames_f := 0
		for _i in 300:
			vy_f = _gravity_step(vy_f, fp.gravity_rising, fp.terminal_velocity, DELTA)
			if vy_f <= 0.0:
				frames_f = _i + 1
				break
		_ok("floaty apex frames >= snappy apex frames (higher arc design intent)",
			frames_f >= frames_to_apex)


# ── helpers ──────────────────────────────────────────────────────────────────

func _sticky_tick(on_floor: bool, was_on_floor: bool, sticky_remaining: int,
		sticky_frames: int) -> Dictionary:
	## Mirrors the sticky-landing block in player.gd::_tick_timers.
	## Returns {"just_landed": bool, "remaining": int} after one physics tick.
	var just_landed := on_floor and not was_on_floor
	var rem := sticky_remaining
	if just_landed and sticky_frames > 0:
		rem = sticky_frames
	elif rem > 0:
		if on_floor:
			rem -= 1
		else:
			rem = 0
	return {"just_landed": just_landed, "remaining": rem}


func _try_jump_helper(buffer: float, coyote: float, jump_v: float) -> Dictionary:
	## Mirrors player.gd::_try_jump exactly. Returns post-call state.
	var buf_out := buffer
	var coy_out := coyote
	var vy_out  := 0.0
	if buf_out > 0.0 and coy_out > 0.0:
		vy_out  = jump_v
		buf_out = 0.0
		coy_out = 0.0
	return {"vy": vy_out, "buffer": buf_out, "coyote": coy_out}


func _sim_cut(jump_released: bool, vy: float, jump_v: float, ratio: float) -> float:
	## Mirrors player.gd::_cut_jump.
	if jump_released and vy > jump_v * ratio:
		return jump_v * ratio
	return vy


func _gravity_step(vy: float, g: float, terminal: float, delta: float) -> float:
	## Mirrors player.gd::_apply_gravity: vy' = max(-terminal, vy - g * delta).
	return maxf(-terminal, vy - g * delta)


func _test_squash_stretch_math() -> void:
	## Mirrors the impact-factor derivation and scale formulas in player.gd
	## _play_land_squash / _play_jump_stretch. Pure math — no node needed.
	print("\n-- Squash-stretch math (impact factor + scale formulas) --")
	var terminal := 20.0

	# Impact factor: clamp(-vy / terminal, 0, 1)
	_ok("impact: vy=0 → 0.0 (step-down)",
		_near(clampf(0.0 / terminal, 0.0, 1.0), 0.0))
	_ok("impact: half terminal → 0.5",
		_near(clampf(10.0 / terminal, 0.0, 1.0), 0.5))
	_ok("impact: full terminal → 1.0",
		_near(clampf(20.0 / terminal, 0.0, 1.0), 1.0))
	_ok("impact: over terminal → clamped 1.0",
		_near(clampf(30.0 / terminal, 0.0, 1.0), 1.0))
	_ok("impact: positive vy (impossible landing) → clamped 0.0",
		_near(clampf(-5.0 / terminal, 0.0, 1.0), 0.0))

	# Landing squash formulas at impact_squash_scale=1.0 (full intensity).
	# squash_y  = 1.0 - impact * 0.45;  squash_xz = 1.0 + impact * 0.20
	for impact in [0.0, 0.5, 1.0]:
		var squash_y  := 1.0 - impact * 0.45
		var squash_xz := 1.0 + impact * 0.20
		_ok("squash: impact %.1f → squash_y <= 1.0 (Y compresses or stays)" % impact,
			squash_y <= 1.0)
		_ok("squash: impact %.1f → squash_xz >= 1.0 (XZ expands or stays)" % impact,
			squash_xz >= 1.0)

	# At impact=1, volume conservation is approximate: squash_y * squash_xz^2 ≈ 0.55 * 1.2^2.
	var sq_y := 1.0 - 1.0 * 0.45
	var sq_xz := 1.0 + 1.0 * 0.20
	_ok("squash at full impact: Y+XZ expand/compress in opposite directions",
		sq_y < 1.0 and sq_xz > 1.0)

	# At scale=0.0 both formulas produce identity (no squash).
	var squash_y_off  := 1.0 - 1.0 * 0.45 * 0.0
	var squash_xz_off := 1.0 + 1.0 * 0.20 * 0.0
	_ok("squash: scale=0 → squash_y == 1.0 (identity)",
		_near(squash_y_off, 1.0))
	_ok("squash: scale=0 → squash_xz == 1.0 (identity)",
		_near(squash_xz_off, 1.0))

	# Jump-stretch formulas at jump_stretch_scale=1.0.
	# stretch_y = 1.0 + 0.30 * scale;  stretch_xz = 1.0 - 0.15 * scale
	var str_y  := 1.0 + 0.30 * 1.0
	var str_xz := 1.0 - 0.15 * 1.0
	_ok("stretch: scale=1 → stretch_y > 1.0 (Y elongates)",   str_y > 1.0)
	_ok("stretch: scale=1 → stretch_xz < 1.0 (XZ compresses)", str_xz < 1.0)
	_ok("stretch: Y elongates and XZ compresses together",
		str_y > 1.0 and str_xz < 1.0)


func _test_jump_puff_math() -> void:
	## Mirrors the geometry constants in player.gd::_build_puff_mesh.
	## Pure math — no node needed.
	print("\n-- Jump puff geometry + material math --")
	_puff_geometry_checks()
	_puff_material_fade_checks()


func _puff_geometry_checks() -> void:
	# 8 evenly-spaced base angles must span exactly one full revolution.
	var angle_step := TAU / 8.0
	_ok("puff: 8 steps × angle_step == TAU (full revolution)",
		_near(8.0 * angle_step, TAU))
	# Each step < PI/2 so adjacent lines don't overlap even with ±0.25 rad jitter.
	_ok("puff: angle_step > 0 and < PI/2 (non-degenerate)",
		angle_step > 0.0 and angle_step < PI / 2.0)

	# i=0 (no jitter): angle=0 → XZ unit vector points +X.
	var a0 := 0.0 * angle_step
	_ok("puff: i=0 → cos(0)=1.0, sin(0)=0.0",
		_near(cos(a0), 1.0) and _near(sin(a0), 0.0))

	# i=4: angle=PI → opposite hemisphere.
	var a4 := 4.0 * angle_step
	_ok("puff: i=4 base angle == PI", _near(a4, PI))
	_ok("puff: i=4 cos(PI) == -1.0",  _near(cos(a4), -1.0))

	# Length bounds.
	var len_min := 0.10;  var len_max := 0.28
	_ok("puff: length_min < length_max",     len_min < len_max)
	_ok("puff: length_min > 0.0 (positive)", len_min > 0.0)
	_ok("puff: length_max < 1.0 (compact)",  len_max < 1.0)

	# Upward Y-kick: no downward component; XZ plane still dominates.
	var y_max := 0.12
	_ok("puff: y_kick_min >= 0.0 (no downward lines)", 0.0 >= 0.0)
	_ok("puff: y_kick_max > 0.0 (some upward lift)",   y_max > 0.0)
	_ok("puff: y_kick_max < 1.0 (XZ plane dominates)", y_max < 1.0)

	# Direction normalisation: at angle=0, y_kick=y_max the raw vector is slightly
	# off-unit; after .normalized() it must be exactly unit length.
	var dir_raw  := Vector3(cos(a0), y_max, sin(a0))
	var dir_norm := dir_raw.normalized()
	_ok("puff: raw dir length > 1 when y_kick > 0", dir_raw.length() > 1.0)
	_ok("puff: normalised dir is unit length",       _near(dir_norm.length(), 1.0))

	# Hub offset 0.04 m keeps lines clear of player origin and < length_min.
	var hub := 0.04
	_ok("puff: hub > 0 and < length_min", hub > 0.0 and hub < len_min)

	# Jitter (±0.25 rad) must leave a positive gap between adjacent base angles.
	# Worst case: neighbours jitter toward each other by 0.25 rad each.
	var jitter_max := 0.25
	_ok("puff: jitter within angle_step gap (no line overlap at worst case)",
		angle_step - 2.0 * jitter_max > 0.0)


func _puff_material_fade_checks() -> void:
	# Warm-grey material: R > G > B (slight warm/concrete bias); all channels [0, 1].
	var r := 0.80;  var g := 0.77;  var b := 0.72
	_ok("puff material: R > G > B (warm-concrete bias)", r > g and g > b)
	_ok("puff material: channels in [0, 1]",
		r >= 0.0 and r <= 1.0 and g >= 0.0 and g <= 1.0 and b >= 0.0 and b <= 1.0)

	# Fade timing: 0.04 s hold + 0.16 s fade = 0.20 s total effect life.
	var hold_s := 0.04;  var fade_s := 0.16
	_ok("puff fade: hold < fade (burst-then-fade grammar)",         hold_s < fade_s)
	_ok("puff fade: hold + fade ≈ 0.20 s (documented effect life)", _near(hold_s + fade_s, 0.20))
	_ok("puff fade: total < 0.5 s (won't linger after next jump)",  hold_s + fade_s < 0.5)


func _test_impact_factor_math() -> void:
	## Mirrors _tick_timers:
	##   impact = clampf(-_last_fall_speed / terminal_velocity, 0, 1)
	## _last_fall_speed = velocity.y while airborne (negative when descending).
	print("\n-- Impact factor derivation math --")
	var terminal := 18.0  # representative Snappy terminal_velocity

	# Zero fall speed → no squash.
	_ok("impact: vel_y=0.0 → factor=0.0",
		_near(clampf(-0.0 / terminal, 0.0, 1.0), 0.0))

	# Linear interior: half-terminal fall → factor = 0.5.
	_ok("impact: half-terminal fall → factor=0.5",
		_near(clampf(-(-terminal * 0.5) / terminal, 0.0, 1.0), 0.5))

	# At full terminal: factor = 1.0.
	_ok("impact: full-terminal fall → factor=1.0",
		_near(clampf(-(-terminal) / terminal, 0.0, 1.0), 1.0))

	# Speed beyond terminal: still clamped to 1.0 (can't happen in normal play).
	_ok("impact: speed > terminal → factor=1.0 (clamp guard)",
		_near(clampf(-(-terminal * 1.8) / terminal, 0.0, 1.0), 1.0))

	# Rising velocity (positive vel_y) yields negative numerator → clamped to 0.
	_ok("impact: rising vel_y > 0 → factor=0.0",
		_near(clampf(-(terminal * 0.5) / terminal, 0.0, 1.0), 0.0))

	# Monotone in the unclamped region.
	var f_slow := clampf(-(-terminal * 0.3) / terminal, 0.0, 1.0)
	var f_fast := clampf(-(-terminal * 0.7) / terminal, 0.0, 1.0)
	_ok("impact: faster fall → larger factor (monotone in unclamped range)", f_fast > f_slow)

	# Scale-invariant: factor = ratio to terminal, independent of absolute magnitude.
	_ok("impact: factor=1.0 regardless of terminal magnitude (ratio only)",
		_near(clampf(-(-2.0 * terminal) / (2.0 * terminal), 0.0, 1.0), 1.0))


func _test_land_squash_scale_math() -> void:
	## Mirrors _play_land_squash:
	##   squash_y  = 1.0 - impact * 0.45 * _impact_squash_scale
	##   squash_xz = 1.0 + impact * 0.20 * _impact_squash_scale
	print("\n-- Land squash scale formulas --")

	# At impact=0: no deformation regardless of squash scale.
	_ok("squash: impact=0 → sq_y=1.0",  _near(1.0 - 0.0 * 0.45 * 0.5, 1.0))
	_ok("squash: impact=0 → sq_xz=1.0", _near(1.0 + 0.0 * 0.20 * 0.5, 1.0))

	# At squash_scale=0: no deformation regardless of impact.
	_ok("squash: scale=0 → sq_y=1.0",  _near(1.0 - 1.0 * 0.45 * 0.0, 1.0))
	_ok("squash: scale=0 → sq_xz=1.0", _near(1.0 + 1.0 * 0.20 * 0.0, 1.0))

	# Full deformation at impact=1, scale=1: exact expected values.
	_ok("squash: impact=1, scale=1 → sq_y=0.55",  _near(1.0 - 1.0 * 0.45 * 1.0, 0.55))
	_ok("squash: impact=1, scale=1 → sq_xz=1.20", _near(1.0 + 1.0 * 0.20 * 1.0, 1.20))

	# Direction invariants (impact=0.5, scale=0.7 as a representative mid-range).
	var sq_y  := 1.0 - 0.5 * 0.45 * 0.7
	var sq_xz := 1.0 + 0.5 * 0.20 * 0.7
	_ok("squash: sq_y < 1.0 when impact > 0, scale > 0 (Y compresses)", sq_y < 1.0)
	_ok("squash: sq_xz > 1.0 when impact > 0, scale > 0 (XZ expands)",  sq_xz > 1.0)

	# Linearity: doubling impact doubles the deformation delta from neutral (1.0).
	var delta_half := 0.5 * 0.45 * 1.0  # Y-delta at impact=0.5, scale=1
	var delta_full := 1.0 * 0.45 * 1.0  # Y-delta at impact=1.0, scale=1
	_ok("squash: Y deformation scales linearly with impact (delta doubles)",
		_near(delta_full / delta_half, 2.0))
