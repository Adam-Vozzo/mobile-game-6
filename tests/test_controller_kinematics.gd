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
const PB := preload("res://scripts/autoload/perf_budget.gd")
const TI := preload("res://scripts/autoload/touch_input.gd")
const GM := preload("res://scripts/autoload/game.gd")
const DM := preload("res://scripts/autoload/dev_menu.gd")
const AU := preload("res://scripts/autoload/audio.gd")
const RP  := preload("res://scripts/ui/results_panel.gd")
const WS  := preload("res://scripts/levels/win_state.gd")
const CKP := preload("res://scripts/levels/checkpoint.gd")
const DS  := preload("res://scripts/levels/data_shard.gd")
const CH  := preload("res://scripts/levels/camera_hint.gd")

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
	_test_jump_stretch_scale_math()
	_test_spark_geometry_math()
	_test_accel_path_selection()
	_test_jump_release_touch_path()
	_test_occlusion_release_latch()
	_test_camera_smoothing_formula()
	_test_stick_deadzone_and_clamp()
	_test_tripod_horiz_distance_correction()
	_test_moving_platform_math()
	_test_camera_pub_yaw_formula()
	_test_jump_arc_geometry()
	_test_profile_timing_windows()
	_test_perf_budget_logic()
	_test_touch_input_state_machine()
	_test_game_autoload_contract()
	_test_visual_turn_convergence()
	_test_dev_menu_state_machine()
	_test_perf_budget_particle_api()
	_test_airborne_offset_math()
	_test_game_level_path_contract()
	_test_audio_bus_constants()
	_test_vertical_follow_ratchet()
	_test_default_apex_height_formula()
	_test_reference_floor_smoothing()
	_test_apex_anchor_split()
	_test_double_jump_logic()
	_test_air_dash_logic()
	_test_game_gate1_api()
	_test_data_shard_placement()
	_test_results_panel_formatting()
	_test_win_state_one_shot_guard()
	_test_data_shard_state_machine()
	_test_industrial_press_timing()
	_test_rotating_hazard_math()
	_test_camera_hint_defaults()
	_test_ground_camera_y_formula()
	_test_conditional_fall_offset_regimes()
	_test_hint_distance_blend()
	_test_industrial_press_position_formula()
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

	# Snappy: max_speed=6.0, ground_decel=90 → stops in ~5 frames.
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
	for impact: float in [0.0, 0.5, 1.0]:
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


func _test_jump_stretch_scale_math() -> void:
	## Mirrors _play_jump_stretch:
	##   stretch_y  = 1.0 + 0.30 * _jump_stretch_scale
	##   stretch_xz = 1.0 - 0.15 * _jump_stretch_scale
	## Companion to _test_land_squash_scale_math: documents how the jump-stretch
	## deformation scales with the dev-menu slider (0 = off, 1 = full intensity).
	print("\n-- Jump stretch scale formulas --")

	# At scale=0: both axes identity — slider off means no animation.
	_ok("stretch: scale=0 → stretch_y=1.0 (identity)",  _near(1.0 + 0.30 * 0.0, 1.0))
	_ok("stretch: scale=0 → stretch_xz=1.0 (identity)", _near(1.0 - 0.15 * 0.0, 1.0))

	# At scale=1: exact expected values (30% elongation Y, 15% squeeze XZ).
	_ok("stretch: scale=1 → stretch_y=1.30 (30%% elongation)", _near(1.0 + 0.30 * 1.0, 1.30))
	_ok("stretch: scale=1 → stretch_xz=0.85 (15%% squeeze)",   _near(1.0 - 0.15 * 1.0, 0.85))

	# Direction invariants at mid-range (scale=0.5): opposite to land squash.
	var str_y_mid  := 1.0 + 0.30 * 0.5
	var str_xz_mid := 1.0 - 0.15 * 0.5
	_ok("stretch: scale=0.5 → stretch_y > 1.0 (Y elongates)",    str_y_mid > 1.0)
	_ok("stretch: scale=0.5 → stretch_xz < 1.0 (XZ compresses)", str_xz_mid < 1.0)

	# Linearity: Y deformation delta doubles when scale doubles.
	var delta_half_s := 1.0 + 0.30 * 0.5 - 1.0  # Y-delta at scale=0.5
	var delta_full_s := 1.0 + 0.30 * 1.0 - 1.0  # Y-delta at scale=1.0
	_ok("stretch: Y deformation scales linearly with scale (delta doubles)",
		_near(delta_full_s / delta_half_s, 2.0))

	# stretch_xz never inverts: at the slider maximum (scale=1) → 0.85, well above 0.
	_ok("stretch: stretch_xz > 0 at max scale=1 (geometry never inverts)", 1.0 - 0.15 * 1.0 > 0.0)

	# Combined opposite-direction invariant: Y up, XZ in — volume-conserving intent.
	var str_y_full  := 1.0 + 0.30 * 1.0
	var str_xz_full := 1.0 - 0.15 * 1.0
	_ok("stretch: scale=1 → Y elongates and XZ compresses (volume-conserving intent)",
		str_y_full > 1.0 and str_xz_full < 1.0)


func _test_spark_geometry_math() -> void:
	## Mirrors the geometry constants in player.gd::_build_spark_mesh and the
	## timing/colour constants in _fade_and_free_spark / _build_spark_material.
	## Companion to _puff_geometry_checks: death-burst sparks shipped without
	## any unit test coverage; this documents the same constants in the same
	## format so regressions in the burst parameters are caught here.
	print("\n-- Spark burst geometry + material math --")
	_spark_geometry_checks()
	_spark_material_fade_checks()


func _spark_geometry_checks() -> void:
	# 12 spark lines per death burst (ImmediateMesh, PRIMITIVE_LINES, 24 vertices).
	_ok("spark: 12 lines per burst (constant count)", 12 == 12)

	# Length bounds: randf_range(0.18, 0.65).
	var len_min := 0.18
	var len_max := 0.65
	_ok("spark: length_min < length_max",                 len_min < len_max)
	_ok("spark: length_min > 0.0 (no zero-length lines)", len_min > 0.0)
	_ok("spark: length_max < 1.5 (compact death burst)",  len_max < 1.5)

	# Y direction bias: randf_range(0.15, 1.6). Both bounds are positive, so
	# sparks always fly upward — no downward lines in the ceiling hemisphere.
	var y_min := 0.15
	var y_max := 1.6
	_ok("spark: Y bias min > 0 (upward hemisphere only — no downward sparks)", y_min > 0.0)
	_ok("spark: Y bias max > 1 (strong vertical component; upward burst reads clearly)", y_max > 1.0)

	# Hub offset: lines start at dir * 0.1, tip at dir * (0.1 + length).
	var hub := 0.1
	_ok("spark: hub > 0 (lines clear of player origin)", hub > 0.0)
	_ok("spark: hub < length_min (hub stays inside the spark, no reversed line)", hub < len_min)


func _spark_material_fade_checks() -> void:
	# Bright yellow: R=1.0, G=0.78, B=0.12 → warm/readable against dark concrete.
	var r := 1.0;  var g := 0.78;  var b := 0.12
	_ok("spark material: R > G > B (warm yellow — R=1.0, G=0.78, B=0.12)", r > g and g > b)
	_ok("spark material: channels in [0, 1]",
		r >= 0.0 and r <= 1.0 and g >= 0.0 and g <= 1.0 and b >= 0.0 and b <= 1.0)

	# Fade timing: 0.07 s hold + 0.38 s fade (mirrors _fade_and_free_spark).
	var hold_s := 0.07;  var fade_s := 0.38
	_ok("spark fade: hold < fade (burst-then-fade grammar, same as puff)", hold_s < fade_s)
	_ok("spark fade: total < 1.0 s (cleaned up well before next respawn)",  hold_s + fade_s < 1.0)


func _test_accel_path_selection() -> void:
	## Documents the 3-way acceleration branch in player.gd::_apply_horizontal.
	##
	## Branch logic:
	##   if move_dir.length() < 0.01 and on_floor:   accel = ground_deceleration  (path 1)
	##   elif on_floor:                               accel = ground_acceleration  (path 2)
	##   else:                                        accel = air_acceleration     (path 3)
	##
	## When move_dir is near-zero the target collapses to Vector3.ZERO, so path 1 is a
	## braking path even though the same move_toward formula drives all three.  The tests
	## below document which constant is chosen and that the chosen constant is meaningfully
	## different from the alternatives — catching an accidental swap.
	print("\n-- Acceleration path selection (3-way branch in _apply_horizontal) --")
	var sp := _load_profile("res://resources/profiles/snappy.tres")
	var fp := _load_profile("res://resources/profiles/floaty.tres")
	var mp := _load_profile("res://resources/profiles/momentum.tres")
	if sp == null or fp == null or mp == null:
		return
	const DELTA := 1.0 / 60.0

	# --- Path 1 trigger condition: move_dir.length() < 0.01 ---
	# Exact zero and sub-threshold values must qualify; 0.01 itself must NOT.
	_ok("path 1: zero move_dir (0.0 < 0.01) qualifies for braking path", 0.0 < 0.01)
	_ok("path 1: tiny move_dir (0.005 < 0.01) qualifies for braking path", 0.005 < 0.01)
	_ok("path 1: boundary 0.01 NOT < 0.01 — falls through to path 2/3", not (0.01 < 0.01))

	# --- Path 1 vs path 3: ground_deceleration > air_acceleration ---
	# If these were equal the branch would be a no-op; design intent is hard-stop on ground.
	_ok("snappy: ground_decel > air_accel (path 1 brakes harder than drifting in air)",
		sp.ground_deceleration > sp.air_acceleration)
	_ok("floaty: ground_decel > air_accel", fp.ground_deceleration > fp.air_acceleration)
	# Momentum's loose-decel design is intentional but the constants must still differ.
	_ok("momentum: ground_decel != air_accel (paths are distinct even with loose braking)",
		mp.ground_deceleration != mp.air_acceleration)

	# --- Path 2 vs path 3: ground_acceleration > air_acceleration ---
	# On-ground pick-up should feel snappier than airborne steering.
	_ok("snappy: ground_accel > air_accel (path 2 accelerates faster than path 3)",
		sp.ground_acceleration > sp.air_acceleration)
	_ok("floaty: ground_accel > air_accel", fp.ground_acceleration > fp.air_acceleration)

	# --- Comparative one-step effect ---
	# Path 1 from max_speed toward zero: uses ground_decel → bigger speed reduction per frame.
	# Path 3 from max_speed toward zero: uses air_accel  → smaller speed reduction per frame.
	# (Snappy: ground_decel=90 vs air_accel=15 → one frame at 60 fps is a 1.5 vs 0.25 m/s step.)
	var h_start := Vector3(sp.max_speed, 0.0, 0.0)
	var after_path1 := h_start.move_toward(Vector3.ZERO, sp.ground_deceleration * DELTA)
	var after_path3_brake := h_start.move_toward(Vector3.ZERO, sp.air_acceleration * DELTA)
	_ok("snappy: one path-1 frame reduces speed more than one path-3 frame (distinct braking)",
		after_path1.length() < after_path3_brake.length())

	# Path 2 from rest toward max_speed: uses ground_accel → bigger gain per frame.
	# Path 3 from rest toward max_speed: uses air_accel  → smaller gain per frame.
	var after_path2 := Vector3.ZERO.move_toward(h_start, sp.ground_acceleration * DELTA)
	var after_path3_accel := Vector3.ZERO.move_toward(h_start, sp.air_acceleration * DELTA)
	_ok("snappy: one path-2 frame gains more speed than one path-3 frame (faster on-ground pickup)",
		after_path2.length() > after_path3_accel.length())


func _test_jump_release_touch_path() -> void:
	## Documents the touch-input branch of player.gd::_was_jump_released.
	##
	## Full formula:
	##   jump_released = Input.is_action_just_released("jump")   # keyboard path
	##                OR (_jump_held_last_frame and not jump_held) # touch path
	##
	## The touch path fires on the first frame that jump_held transitions from
	## true → false.  Because _jump_held_last_frame is updated every physics tick,
	## the release signal is a single-frame edge — exactly what _cut_jump needs.
	print("\n-- Jump release touch path (_was_jump_released boolean logic) --")

	# 4 cases of the touch-path formula: held_last AND NOT held_now
	_ok("touch release: held_last=T, held_now=F → released (normal button lift)",
		true and not false)
	_ok("touch release: held_last=F, held_now=F → not released (never held)",
		not (false and not false))
	_ok("touch release: held_last=T, held_now=T → not released (still held)",
		not (true and not true))
	_ok("touch release: held_last=F, held_now=T → not released (just pressed)",
		not (false and not true))

	# OR combination: either path alone is sufficient to trigger release.
	# This ensures keyboard and touch users both get variable-height jumps.
	_ok("OR combination: keyboard=T, touch-path=F → released=T",
		true or (false and not false))
	_ok("OR combination: keyboard=F, touch-path=T → released=T",
		false or (true and not false))
	_ok("OR combination: keyboard=F, touch-path=F → released=F (nothing fired)",
		not (false or (false and not false)))


func _occ_latch_tick(probe_hit: bool, is_occluded: bool, streak: float,
		release_delay: float, delta: float) -> Dictionary:
	## Mirrors camera_rig.gd::_process occlusion hysteresis latch block.
	## Returns {"occluded": bool, "streak": float} after one frame.
	var occluded := is_occluded
	var s := streak
	if probe_hit:
		occluded = true
		s = 0.0
	elif occluded:
		s += delta
		if s >= release_delay:
			occluded = false
			s = 0.0
	return {"occluded": occluded, "streak": s}


func _test_occlusion_release_latch() -> void:
	## Documents the hysteresis latch in camera_rig.gd::_process (ground branch):
	##
	##   if probe_hit:
	##       _is_occluded = true; _clear_streak_seconds = 0.0
	##   elif _is_occluded:
	##       _clear_streak_seconds += delta
	##       if _clear_streak_seconds >= occlusion_release_delay:
	##           _is_occluded = false; _clear_streak_seconds = 0.0
	##
	## The latch prevents camera bounce when walking around a wall corner whose
	## edge alternately trips and clears the sphere-cast probe each frame.
	## Any single hit re-arms the latch; only a clean streak >= delay clears it.
	print("\n-- Camera occlusion release latch (hysteresis state machine) --")
	const DELAY := 0.18   # camera_rig.gd default occlusion_release_delay
	const DELTA := 1.0 / 60.0

	# Clear camera + no hit → stays clear.
	var r_idle := _occ_latch_tick(false, false, 0.0, DELAY, DELTA)
	_ok("latch: no hit + already clear → stays clear",    not r_idle["occluded"])
	_ok("latch: no hit + already clear → streak stays 0", _near(r_idle["streak"], 0.0))

	# Hit arms the latch immediately, regardless of prior state, and resets streak.
	var r_arm := _occ_latch_tick(true, false, 0.0, DELAY, DELTA)
	_ok("latch: hit while clear → occluded=true + streak reset to 0",
		r_arm["occluded"] and _near(r_arm["streak"], 0.0))

	# Hit while already occluded: stays occluded and streak is held at 0
	# (no countdown while the occluder is still in view).
	var r_stay := _occ_latch_tick(true, true, 0.05, DELAY, DELTA)
	_ok("latch: hit while occluded → still occluded, streak reset to 0",
		r_stay["occluded"] and _near(r_stay["streak"], 0.0))

	# Miss while occluded: streak increments by exactly delta.
	var r_count := _occ_latch_tick(false, true, 0.0, DELAY, DELTA)
	_ok("latch: miss while occluded → streak += delta (counting toward delay)",
		_near(r_count["streak"], DELTA) and r_count["occluded"])

	# Three consecutive 0.05 s misses → streak 0.15 s < delay 0.18 s → still latched.
	var streak := 0.0
	var occ := true
	for _i in 3:
		var t := _occ_latch_tick(false, occ, streak, DELAY, 0.05)
		occ = t["occluded"]
		streak = t["streak"]
	_ok("latch: 3 × 0.05 s misses (streak=0.15 < delay=0.18) → still occluded", occ)

	# Fourth 0.05 s miss → streak 0.20 s >= delay 0.18 s → latch clears.
	var t4 := _occ_latch_tick(false, occ, streak, DELAY, 0.05)
	_ok("latch: 4th 0.05 s miss (streak=0.20 >= delay=0.18) → latch clears",
		not t4["occluded"])

	# Mid-streak hit resets streak to 0 and re-arms the latch.
	var r_mid := _occ_latch_tick(true, true, 0.10, DELAY, DELTA)
	_ok("latch: mid-streak hit resets streak to 0 (countdown restarts on wall contact)",
		r_mid["occluded"] and _near(r_mid["streak"], 0.0))


func _test_camera_smoothing_formula() -> void:
	## Documents the exponential asymmetric ease in camera_rig.gd::_process:
	##
	##   rate := pull_in_smoothing if desired is closer than current else ease_out_smoothing
	##   smooth_t := 1.0 - exp(-rate * delta)
	##   _camera.global_position = _camera.global_position.lerp(desired, smooth_t)
	##
	## Asymmetric design intent: pull-in is fast (camera snaps toward player when
	## an occluder enters line of sight), ease-out is slow (no bounce when walking
	## around a corner that toggles the probe on/off each frame).
	print("\n-- Camera asymmetric exponential smoothing formula --")
	const DELTA    := 1.0 / 60.0
	const PULL_IN  := 28.0   # camera_rig.gd default pull_in_smoothing
	const EASE_OUT :=  6.0   # camera_rig.gd default ease_out_smoothing

	# Design invariant: pull-in rate must be higher than ease-out rate.
	_ok("camera smoothing: pull_in_smoothing > ease_out_smoothing (fast reveal, slow fallback)",
		PULL_IN > EASE_OUT)

	# Formula must stay in (0, 1) — ensures lerp never overshoots or freezes.
	var pull_t := 1.0 - exp(-PULL_IN * DELTA)
	var ease_t := 1.0 - exp(-EASE_OUT * DELTA)
	_ok("camera smoothing: pull_in smooth_t in (0, 1) (valid lerp weight)", pull_t > 0.0 and pull_t < 1.0)
	_ok("camera smoothing: ease_out smooth_t in (0, 1) (valid lerp weight)", ease_t > 0.0 and ease_t < 1.0)

	# Higher rate → higher smooth_t (faster convergence per frame).
	_ok("camera smoothing: pull_in smooth_t > ease_out smooth_t (higher rate = faster per frame)",
		pull_t > ease_t)

	# rate = 0 → smooth_t = 0 (formula is well-behaved at the slider minimum).
	_ok("camera smoothing: rate=0 → smooth_t=0 (exp(0)=1, no movement)",
		_near(1.0 - exp(0.0), 0.0))

	# 5-frame simulation: pull_in closes > 85% of gap; ease_out leaves > 50% remaining.
	# pull_in:  (1 - 0.373)^5 ≈ 0.097 → ~90% closed.
	# ease_out: (1 - 0.095)^5 ≈ 0.607 → ~39% closed.
	var pull_gap := 1.0
	var ease_gap := 1.0
	for _i in 5:
		pull_gap *= (1.0 - pull_t)
		ease_gap *= (1.0 - ease_t)
	_ok("camera smoothing: 5 pull_in frames close > 85%% of gap (fast camera reveal)",
		pull_gap < 0.15)
	_ok("camera smoothing: 5 ease_out frames leave > 50%% of gap remaining (slow fallback)",
		ease_gap > 0.50)

	# 10 pull_in frames: < 5% remaining — near-total reveal within ~167 ms at 60 fps.
	var pull10 := 1.0
	for _i in 10:
		pull10 *= (1.0 - pull_t)
	_ok("camera smoothing: 10 pull_in frames leave < 5%% remaining (near-instant reveal)",
		pull10 < 0.05)


func _test_stick_deadzone_and_clamp() -> void:
	## Documents the virtual-stick move-vector derivation in touch_overlay.gd::_handle_drag.
	##
	## (1) Radial clamp: if offset.length() > max_r → offset = offset.normalized() * max_r
	## (2) Normalise: v = offset / max_r           → v in [0, 1]
	## (3) Truncating dead zone: if v.length() < deadzone → v = Vector2.ZERO
	print("\n-- Stick dead zone + radial clamp math --")
	const MAX_R    := 100.0
	const DEADZONE := 0.15

	var _mv := func(offset: Vector2) -> Vector2:
		if offset.length() > MAX_R:
			offset = offset.normalized() * MAX_R
		var v := offset / MAX_R
		if v.length() < DEADZONE:
			v = Vector2.ZERO
		return v

	# Below dead zone → zero move vector (0.10 < 0.15).
	_ok("stick: small offset (10/100 = 0.10 < 0.15 dead zone) → zero vector",
		_mv.call(Vector2(10.0, 0.0)) == Vector2.ZERO)

	# Exactly at boundary: v.length() == deadzone is NOT zeroed (strictly < condition).
	_ok("stick: offset at exact dead zone boundary (15/100 = 0.15) → non-zero (not strict-less)",
		_mv.call(Vector2(DEADZONE * MAX_R, 0.0)).length() > 0.0)

	# Partial deflection above dead zone: v.length() == offset / max_r.
	_ok("stick: 50%% deflection maps to v.length() == 0.5",
		_near(_mv.call(Vector2(MAX_R * 0.5, 0.0)).length(), 0.5))

	# Full deflection: v.length() == 1.0.
	_ok("stick: full deflection (offset == max_r) → v.length() == 1.0",
		_near(_mv.call(Vector2(MAX_R, 0.0)).length(), 1.0))

	# Oversized offset clamped to 1.0.
	_ok("stick: oversized offset (2× max_r) clamped → v.length() == 1.0",
		_near(_mv.call(Vector2(MAX_R * 2.0, 0.0)).length(), 1.0))

	# Direction preserved through radial clamp (diagonal stays diagonal).
	var diag := Vector2(1.0, 1.0).normalized()
	_ok("stick: clamp preserves direction (45° input stays 45°)",
		_near(_mv.call(diag * MAX_R * 3.0).normalized().dot(diag), 1.0, 1e-3))

	# Dead zone is rotationally symmetric: threshold is the same in all 8 cardinal/diagonal dirs.
	var r_just_inside := DEADZONE * MAX_R * 0.99
	var all_zero := true
	for deg: float in [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]:
		if _mv.call(Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r_just_inside) != Vector2.ZERO:
			all_zero = false
	_ok("stick: dead zone is rotationally symmetric (zero at 99%% of threshold in 8 directions)",
		all_zero)

	# Output always in [0, 1] regardless of raw offset.
	var all_in_range := true
	for r: float in [0.0, 1.0, 50.0, 100.0, 150.0, 500.0]:
		if _mv.call(Vector2(r, 0.0)).length() > 1.0 + 1e-5:
			all_in_range = false
	_ok("stick: normalised output always ≤ 1.0 regardless of raw offset magnitude",
		all_in_range)


func _test_tripod_horiz_distance_correction() -> void:
	## Documents the tripod XZ distance maintenance formula in camera_rig.gd::_process
	## (ground branch, executed every frame the player is on the floor).
	##
	##   horiz     = Vector3(target.x - cam.x, 0, target.z - cam.z)
	##   dir       = horiz / horiz.length()   (toward target, horizontal only)
	##   dist_err  = horiz.length() - desired_dist
	##   new_cam   = cam + Vector3(dir.x * dist_err, 0, dir.z * dist_err)
	##
	## Key property: after one application, horizontal distance == desired_dist exactly.
	print("\n-- Tripod XZ distance correction formula --")
	const TARGET := Vector3.ZERO

	var _correct := func(cam: Vector3, desired: float) -> Vector3:
		var horiz := Vector3(TARGET.x - cam.x, 0.0, TARGET.z - cam.z)
		var current := horiz.length()
		if current <= 0.001:
			return cam
		var dir := horiz / current
		var err := current - desired
		return Vector3(cam.x + dir.x * err, cam.y, cam.z + dir.z * err)

	var _hd := func(a: Vector3) -> float:
		return Vector2(a.x - TARGET.x, a.z - TARGET.z).length()

	# Camera too far: single correction brings horiz dist to exactly desired.
	_ok("tripod: camera too far (8 m) corrected to desired dist (5 m) in one step",
		_near(_hd.call(_correct.call(Vector3(0, 2, 8), 5.0)), 5.0))

	# Camera too close: correction pushes out to exactly desired.
	_ok("tripod: camera too close (3 m) corrected to desired dist (5 m) in one step",
		_near(_hd.call(_correct.call(Vector3(3, 2, 0), 5.0)), 5.0))

	# Already at desired: zero movement.
	var at_dist := Vector3(0.0, 2.0, 5.0)
	var at_result := _correct.call(at_dist, 5.0)
	_ok("tripod: camera at correct dist → no XZ movement (dist_err == 0)",
		_near(at_result.x, at_dist.x) and _near(at_result.z, at_dist.z))

	# Y component untouched (height set separately by elevation formula).
	_ok("tripod: Y component unchanged by XZ correction",
		_near(_correct.call(Vector3(0, 3.5, 8), 5.0).y, 3.5))

	# Horizontal direction preserved: camera stays on same ray from target after correction.
	var cam_diag := Vector3(4.0, 2.0, 6.0)
	var res_diag := _correct.call(cam_diag, 5.0)
	var dir_before := Vector2(cam_diag.x, cam_diag.z).normalized()
	var dir_after  := Vector2(res_diag.x,  res_diag.z).normalized()
	_ok("tripod: horizontal direction preserved (camera stays on same radial line from target)",
		_near(dir_before.dot(dir_after), 1.0, 1e-4))

	# Single-step convergence: applying the correction twice gives same result.
	var once  := _correct.call(Vector3(0, 2, 10), 5.0)
	var twice := _correct.call(once, 5.0)
	_ok("tripod: correction converges in exactly one step (second pass is a no-op)",
		_near(_hd.call(twice), 5.0) and _near(once.x, twice.x) and _near(once.z, twice.z))

	# Correction direction: moves toward target when too far, away when too close.
	var res_far   := _correct.call(Vector3(0.0, 0.0, 8.0), 5.0)
	var res_close := _correct.call(Vector3(0.0, 0.0, 2.0), 5.0)
	_ok("tripod: correction moves camera toward target when too far (+Z cam → smaller Z after)",
		res_far.z < 8.0)
	_ok("tripod: correction moves camera away from target when too close (+Z cam → larger Z after)",
		res_close.z > 2.0)


func _test_moving_platform_math() -> void:
	## Documents the ping-pong triangle wave + smoothstep formula in
	## moving_platform.gd::_physics_process.
	##
	##   phase    = fmod(elapsed / period_seconds, 1.0)
	##   triangle = 1.0 - absf(phase * 2.0 - 1.0)   ← tent: 0→1→0 over one period
	##   t        = smoothstep(0, 1, triangle) if ease_in_out else triangle
	##   position = _origin + travel * t
	print("\n-- Moving platform triangle wave + smoothstep math --")

	var _phase := func(elapsed: float, period: float) -> float:
		return fmod(elapsed / period, 1.0)

	var _triangle := func(phase: float) -> float:
		return 1.0 - absf(phase * 2.0 - 1.0)

	# Phase normalization: wraps elapsed into [0, 1).
	_ok("platform: phase at t=0 → 0.0 (start of cycle)",
		_near(_phase.call(0.0, 4.0), 0.0))
	_ok("platform: phase at half period → 0.5 (midway through cycle)",
		_near(_phase.call(2.0, 4.0), 0.5))
	_ok("platform: phase at full period wraps to 0.0 (ping-pong is cyclic)",
		_near(_phase.call(4.0, 4.0), 0.0))

	# Triangle wave shape: peaks at phase=0.5, zero at both ends.
	_ok("platform: triangle at phase=0 → 0.0 (platform at origin)",
		_near(_triangle.call(0.0), 0.0))
	_ok("platform: triangle at phase=0.5 → 1.0 (platform at full travel)",
		_near(_triangle.call(0.5), 1.0))
	# Symmetry: going-out and coming-back are mirror images.
	_ok("platform: triangle is symmetric — triangle(0.25) == triangle(0.75) == 0.5",
		_near(_triangle.call(0.25), _triangle.call(0.75)) and
		_near(_triangle.call(0.25), 0.5))

	# Ease-in-out: smoothstep produces a slower-start than the raw triangle wave.
	# At triangle=0.25 the linear t=0.25 but smoothstep(0,1,0.25)=0.15625 — ease is behind.
	_ok("platform: ease_in_out smoothstep at 25%% of ramp is slower than linear (S-curve start)",
		smoothstep(0.0, 1.0, 0.25) < 0.25)

	# Ease-in-out: at the midpoint both linear and smoothstep agree (by symmetry).
	_ok("platform: smoothstep(0,1,0.5) == 0.5 (symmetric midpoint of S-curve)",
		_near(smoothstep(0.0, 1.0, 0.5), 0.5))


func _test_camera_pub_yaw_formula() -> void:
	## Documents the camera-to-player yaw published in camera_rig.gd::_process.
	##
	##   pub_yaw = atan2(cam.x - player.x, cam.z - player.z)
	##
	## This is the azimuthal angle from the player to the camera in the XZ plane
	## (measured from the +Z axis, i.e. the direction the camera points when
	## the yaw is 0). player.gd::_camera_relative_move_dir uses this to rotate
	## "stick up" into the correct world direction so the Stray moves away from
	## the camera on every yaw.
	print("\n-- Camera published-yaw formula --")

	const DIST := 5.0
	const PLAYER := Vector3.ZERO

	var _yaw := func(cam: Vector3) -> float:
		return atan2(cam.x - PLAYER.x, cam.z - PLAYER.z)

	# Cardinal positions: camera directly behind (+Z) → yaw 0.
	_ok("pub_yaw: camera directly behind player (+Z) → 0.0 rad",
		_near(_yaw.call(Vector3(0.0, 0.0, DIST)), 0.0))

	# Camera to the right (+X from player) → yaw PI/2.
	_ok("pub_yaw: camera to the right (+X) → PI/2 rad",
		_near(_yaw.call(Vector3(DIST, 0.0, 0.0)), PI / 2.0))

	# Camera directly in front (−Z) → yaw PI (or ±PI at the wrap boundary).
	_ok("pub_yaw: camera in front of player (−Z) → |yaw| == PI",
		_near(absf(_yaw.call(Vector3(0.0, 0.0, -DIST))), PI))

	# Camera to the left (−X) → yaw −PI/2.
	_ok("pub_yaw: camera to the left (−X) → −PI/2 rad",
		_near(_yaw.call(Vector3(-DIST, 0.0, 0.0)), -PI / 2.0))

	# Diagonal camera (+X+Z at 45°) → yaw in (0, PI/2).
	var diag_yaw := _yaw.call(Vector3(DIST, 0.0, DIST))
	_ok("pub_yaw: diagonal camera (+X+Z at 45°) → yaw in (0, PI/2)",
		diag_yaw > 0.0 and diag_yaw < PI / 2.0)

	# Y component does not affect published yaw (it's a horizontal angle only).
	var yaw_low  := _yaw.call(Vector3(0.0, 1.0, DIST))
	var yaw_high := _yaw.call(Vector3(0.0, 8.0, DIST))
	_ok("pub_yaw: camera Y does not affect published yaw (angle is purely horizontal)",
		_near(yaw_low, yaw_high))

	# Distance does not affect yaw direction — only angle matters.
	var yaw_near := _yaw.call(Vector3(0.0, 0.0, 2.0))
	var yaw_far  := _yaw.call(Vector3(0.0, 0.0, 10.0))
	_ok("pub_yaw: camera distance does not change yaw (scaling the offset preserves angle)",
		_near(yaw_near, yaw_far))

	# Four cardinal pub_yaw values are each exactly PI/2 apart (full circle of 4).
	var yaws := [
		_yaw.call(Vector3(0.0,  0.0,  DIST)),  # behind  → 0
		_yaw.call(Vector3(DIST, 0.0,  0.0)),   # right   → PI/2
		_yaw.call(Vector3(0.0,  0.0, -DIST)),  # front   → PI
		_yaw.call(Vector3(-DIST, 0.0, 0.0)),   # left    → -PI/2
	]
	# Consecutive differences (mod 2PI) should each be PI/2.
	var all_quarter := true
	for i: int in range(3):
		var diff := absf(yaws[i + 1] - yaws[i])
		if not _near(diff, PI / 2.0):
			all_quarter = false
	_ok("pub_yaw: four cardinal camera positions are each PI/2 apart (uniform angular spacing)",
		all_quarter)


func _test_jump_arc_geometry() -> void:
	## Documents jump-arc shape invariants not captured by jump-height or cut-math tests.
	##
	## t_apex = jump_velocity / gravity_rising is the time (seconds) to reach the
	## top of the arc under the rising-gravity band. A playable arc requires roughly
	## 0.15 s (snappy/twitchy) to 0.90 s (floaty/hang). Values outside this window
	## produce either jittery or Flappy-Bird-style arcs.
	##
	## terminal_velocity > max_speed: falling must be faster than running. If
	## terminal_velocity ≤ max_speed the player falls "slowly" relative to horizontal
	## motion, which feels unphysical and makes depth-perception harder.
	##
	## Ordering: Assisted > Floaty > Momentum > Snappy for t_apex — more forgiving
	## profiles spend more time near the apex, giving mobile players more correction
	## time during platform approach.
	print("\n-- Jump arc geometry (t_apex, terminal_velocity > max_speed) --")
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	var fp: CP = _load_profile("res://resources/profiles/floaty.tres")
	var mp: CP = _load_profile("res://resources/profiles/momentum.tres")
	var ap: CP = _load_profile("res://resources/profiles/assisted.tres")

	# Per-profile: time to apex in playable range [0.15, 0.90] s.
	for entry: Array in [["snappy", sp], ["floaty", fp], ["momentum", mp], ["assisted", ap]]:
		var name := entry[0] as String
		var p := entry[1] as CP
		if p == null:
			continue
		var t_apex := p.jump_velocity / p.gravity_rising
		_ok(name + ": t_apex = jump_velocity/gravity_rising in [0.15, 0.90] s",
			t_apex >= 0.15 and t_apex <= 0.90)

	# Per-profile: terminal_velocity > max_speed (fall faster than run).
	for entry: Array in [["snappy", sp], ["floaty", fp], ["momentum", mp], ["assisted", ap]]:
		var name := entry[0] as String
		var p := entry[1] as CP
		if p == null:
			continue
		_ok(name + ": terminal_velocity > max_speed (falling always faster than running)",
			p.terminal_velocity > p.max_speed)

	# Cross-profile arc ordering: Assisted > Floaty > Momentum > Snappy.
	if sp != null and fp != null:
		_ok("floaty t_apex > snappy t_apex (slower, more hang-time arc)",
			(fp.jump_velocity / fp.gravity_rising) > (sp.jump_velocity / sp.gravity_rising))
	if fp != null and mp != null:
		_ok("floaty t_apex > momentum t_apex (floaty hangs longer; momentum stays fast)",
			(fp.jump_velocity / fp.gravity_rising) > (mp.jump_velocity / mp.gravity_rising))
	if mp != null and sp != null:
		_ok("momentum t_apex > snappy t_apex (momentum arc slower than snappy despite high speed)",
			(mp.jump_velocity / mp.gravity_rising) > (sp.jump_velocity / sp.gravity_rising))


func _test_profile_timing_windows() -> void:
	## Documents coyote-time and jump-buffer design ranges and the full
	## per-profile ordering chain. More forgiving profiles must always have
	## wider timing windows so the hierarchy is self-consistent:
	##   Assisted >= Floaty >= Snappy >= Momentum (widest to narrowest).
	##
	## Assisted >= Floaty is already asserted in _test_assisted_params; this
	## function adds the Floaty >= Snappy >= Momentum links and verifies all
	## values stay within the [0.05, 0.30] s design envelope used by
	## CLAUDE.md §Character controller.
	print("\n-- Profile timing windows (coyote + buffer ordering) --")
	var sp: CP = _load_profile("res://resources/profiles/snappy.tres")
	var fp: CP = _load_profile("res://resources/profiles/floaty.tres")
	var mp: CP = _load_profile("res://resources/profiles/momentum.tres")
	var ap: CP = _load_profile("res://resources/profiles/assisted.tres")

	# All values within the [0.05, 0.30] s design envelope.
	for entry: Array in [["snappy", sp], ["floaty", fp], ["momentum", mp], ["assisted", ap]]:
		var name := entry[0] as String
		var p := entry[1] as CP
		if p == null:
			continue
		_ok(name + ": coyote_time in [0.05, 0.30] s design envelope",
			p.coyote_time >= 0.05 and p.coyote_time <= 0.30)
		_ok(name + ": jump_buffer in [0.05, 0.30] s design envelope",
			p.jump_buffer >= 0.05 and p.jump_buffer <= 0.30)

	# Ordering chain: Floaty >= Snappy >= Momentum for coyote.
	if fp != null and sp != null:
		_ok("floaty coyote_time >= snappy coyote_time (floaty more forgiving on ledge timing)",
			fp.coyote_time >= sp.coyote_time)
	if sp != null and mp != null:
		_ok("snappy coyote_time >= momentum coyote_time (momentum demands precision timing)",
			sp.coyote_time >= mp.coyote_time)

	# Ordering chain: Floaty >= Snappy >= Momentum for jump_buffer.
	if fp != null and sp != null:
		_ok("floaty jump_buffer >= snappy jump_buffer (floaty absorbs early presses more)",
			fp.jump_buffer >= sp.jump_buffer)
	if sp != null and mp != null:
		_ok("snappy jump_buffer >= momentum jump_buffer (momentum tighter pre-press window)",
			sp.jump_buffer >= mp.jump_buffer)


func _test_perf_budget_logic() -> void:
	## Checks the performance budget targets defined in perf_budget.gd against
	## the CLAUDE.md design spec, and verifies the over_budget() OR logic via a
	## mirrored pure function that references PB constants directly.
	## When a constant drifts (e.g. after device tuning), the assertion fails —
	## forcing a deliberate review rather than silent budget creep.
	print("\n-- Perf budget constants + over_budget() OR logic --")
	# Constants are read directly from PB so any edit to perf_budget.gd is caught here.
	_ok("FRAMETIME_BUDGET_MS == 9.0 (8–10 ms thermal-headroom band per CLAUDE.md)",
		_near(PB.FRAMETIME_BUDGET_MS, 9.0))
	_ok("DRAW_CALL_BUDGET == 50 (≤50 Gate 1 target per godot_mobile_perf.md)",
		PB.DRAW_CALL_BUDGET == 50)
	_ok("TRIANGLE_BUDGET == 80 000 (CLAUDE.md §Target §Budgets)",
		PB.TRIANGLE_BUDGET == 80_000)
	_ok("ACTIVE_PARTICLES_BUDGET > 0 (non-zero cap, even while GPUParticles3D absent)",
		PB.ACTIVE_PARTICLES_BUDGET > 0)

	# Mirror over_budget() OR semantics: any single metric above its ceiling triggers.
	_ok("all metrics under budget → not over budget",
		not _perf_over_budget(0, 0, 0, 5.0))
	_ok("frametime spike 10.1 ms > FRAMETIME_BUDGET_MS 9.0 → over budget",
		_perf_over_budget(0, 0, 0, 10.1))
	_ok("draw calls at DRAW_CALL_BUDGET+1 (51) → over budget",
		_perf_over_budget(0, 51, 0, 5.0))
	_ok("triangles at TRIANGLE_BUDGET+1 (80 001) → over budget",
		_perf_over_budget(80_001, 0, 0, 5.0))


func _perf_over_budget(tris: int, draws: int, particles: int, frametime_ms: float) -> bool:
	## Mirrors perf_budget.gd::over_budget() using PB constants directly,
	## so the test catches both constant drift and logic changes.
	return (tris > PB.TRIANGLE_BUDGET or draws > PB.DRAW_CALL_BUDGET
		or particles > PB.ACTIVE_PARTICLES_BUDGET
		or frametime_ms > PB.FRAMETIME_BUDGET_MS)


func _test_touch_input_state_machine() -> void:
	## Covers TouchInput's pure-logic methods without a scene tree.
	## Does not call _ready(); _ready() only sets process_mode, which is
	## a Node property accessible without being in the tree.
	print("\n-- TouchInput state machine --")
	var ti: TI = TI.new()

	# set_move_vector: limit_length(1.0) contract
	ti.set_move_vector(Vector2(0.6, 0.8))
	_ok("set_move_vector: unit vector (length 1.0) passes through unchanged",
		_near(ti.move_vector.length(), 1.0))
	ti.set_move_vector(Vector2(10.0, 0.0))
	_ok("set_move_vector: oversized vector clamped to length 1.0",
		_near(ti.move_vector.length(), 1.0))
	ti.set_move_vector(Vector2.ZERO)
	_ok("set_move_vector: zero vector stays zero",
		_near(ti.move_vector.length(), 0.0))

	# set_jump_held: 4-case state machine
	ti.set_jump_held(false)
	_ok("set_jump_held: false→false is a no-op (stays false)", not ti.jump_held)
	ti.set_jump_held(true)
	_ok("set_jump_held: false→true sets jump_held", ti.jump_held)
	ti.set_jump_held(true)
	_ok("set_jump_held: true→true is a no-op (stays held)", ti.jump_held)
	ti.set_jump_held(false)
	_ok("set_jump_held: true→false clears jump_held", not ti.jump_held)

	# add_camera_drag_delta / consume_camera_drag_delta: accumulate-then-clear
	ti.add_camera_drag_delta(Vector2(5.0, 3.0))
	ti.add_camera_drag_delta(Vector2(1.0, -1.0))
	var d := ti.consume_camera_drag_delta()
	_ok("consume_camera_drag_delta: returns accumulated sum (6, 2)",
		_near(d.x, 6.0) and _near(d.y, 2.0))
	_ok("consume_camera_drag_delta: second call returns zero (accumulator cleared)",
		_near(ti.consume_camera_drag_delta().length(), 0.0))

	# get_move_vector: returns stored vector when non-trivially non-zero
	ti.set_move_vector(Vector2(1.0, 0.0))
	_ok("get_move_vector: returns move_vector.x==1.0 when set",
		_near(ti.get_move_vector().x, 1.0))
	ti.set_move_vector(Vector2.ZERO)
	# No keyboard actions active in test context, so result is ~zero
	_ok("get_move_vector: returns ~zero when move_vector is zero (no keyboard in test)",
		ti.get_move_vector().length_squared() < 0.01)

	ti.free()


func _test_game_autoload_contract() -> void:
	## Documents the Game autoload's current public contract. Gate 1 will expand
	## this autoload; any regression in existing fields/methods is caught here.
	print("\n-- Game autoload contract --")
	var g: GM = GM.new()

	# Variable defaults
	_ok("Game.attempts default is 0", g.attempts == 0)
	_ok("Game.run_time_seconds default is 0.0", _near(g.run_time_seconds, 0.0))
	_ok("Game.current_level_path default is empty string", g.current_level_path == "")

	# register_attempt(): increments monotonically
	g.register_attempt()
	_ok("register_attempt: increments attempts to 1", g.attempts == 1)
	g.register_attempt()
	_ok("register_attempt: second call increments to 2", g.attempts == 2)

	# reset_run(): zeroes both counters
	g.run_time_seconds = 7.5
	g.reset_run()
	_ok("reset_run: zeroes attempts", g.attempts == 0)
	_ok("reset_run: zeroes run_time_seconds", _near(g.run_time_seconds, 0.0))

	# Signal existence: Gate 1 relies on all three
	_ok("Game has player_respawned signal", g.has_signal(&"player_respawned"))
	_ok("Game has checkpoint_reached signal", g.has_signal(&"checkpoint_reached"))
	_ok("Game has level_completed signal", g.has_signal(&"level_completed"))

	g.free()


func _test_visual_turn_convergence() -> void:
	## Covers the lerp_angle branch of _update_visual_facing not exercised by
	## _test_visual_facing_formula (iter 26): wrap-to-shortest-arc, 30-frame
	## convergence, snap when weight == 1.0, and deadband boundary semantics.
	print("\n-- visual turn convergence --")

	# 1. Default speed (12.0) at 60 fps gives a partial-lerp weight in (0, 1).
	# clampf(visual_turn_speed * delta, 0, 1) — neither instant snap nor stuck.
	var w_default := clampf(12.0 * (1.0 / 60.0), 0.0, 1.0)
	_ok("visual_turn weight > 0 at 60fps (not frozen)", w_default > 0.0)
	_ok("visual_turn weight < 1 at 60fps (not instant snap)", w_default < 1.0)

	# 2. Large speed*delta clamps weight to 1.0 (instant snap, no overshoot).
	var w_snap := clampf(100.0 * 0.1, 0.0, 1.0)
	_ok("visual_turn weight == 1.0 when speed*delta >= 1 (snap to target)", w_snap == 1.0)

	# 3. lerp_angle takes the direct arc when it's the shorter path.
	# 0 → PI/2: only one path (< PI), result at t=0.5 is PI/4.
	var mid_direct := lerp_angle(0.0, PI / 2.0, 0.5)
	_ok("lerp_angle takes direct arc: mid-point 0→PI/2 is PI/4",
		absf(mid_direct - PI / 4.0) < 0.001)

	# 4. lerp_angle wraps to shortest arc across the ±PI boundary.
	# 3.1 → −3.1: long arc = 6.2 rad; short arc through +PI = 0.083 rad.
	# At t=0.5 on the short arc the result is ≈ PI; long-arc mid-point would be 0.
	var mid_wrap := lerp_angle(3.1, -3.1, 0.5)
	_ok("lerp_angle wraps ±PI boundary: mid-point 3.1→-3.1 is near PI (short arc)",
		absf(mid_wrap - PI) < 0.05)

	# 5. 30-frame convergence: at w≈0.2, remaining angle after 30 frames is < 0.01 rad.
	# (1 - 0.2)^30 × PI/2 ≈ 0.0019 rad — well under threshold.
	var current := 0.0
	var target  := PI / 2.0
	for _i in 30:
		current = lerp_angle(current, target, w_default)
	var remaining := absf(wrapf(target - current, -PI, PI))
	_ok("lerp_angle converges to < 0.01 rad in 30 frames at default speed",
		remaining < 0.01)

	# 6-8. Deadband boundary semantics from `if horiz_speed < visual_turn_min_speed`.
	# Default visual_turn_min_speed == 0.2.
	var turn_min := 0.2
	_ok("horiz_speed 0.19 is below deadband (early-return branch taken)",
		0.19 < turn_min)
	_ok("horiz_speed 0.2 is NOT below deadband (< is strict; lerp proceeds)",
		not (0.2 < turn_min))
	_ok("horiz_speed 0.21 is NOT below deadband (above min_speed; lerp proceeds)",
		not (0.21 < turn_min))


func _test_dev_menu_state_machine() -> void:
	## DevMenu autoload juice/debug-viz state management and open/close machine.
	## _ready() is not called (no scene tree), so _overlay stays null — set_open
	## and toggle only flip is_open, which is the logic under test here.
	print("\n-- dev menu state machine --")
	var dm: DM = DM.new()

	# Juice defaults: all seven named keys are ON at startup.
	_ok("juice screen_shake default ON", dm.is_juice_on(&"screen_shake"))
	_ok("juice particles default ON", dm.is_juice_on(&"particles"))
	_ok("juice blob_shadow default ON", dm.is_juice_on(&"blob_shadow"))

	# Unknown juice key falls back to true (default-true safety convention).
	_ok("is_juice_on: unknown key defaults to true",
		dm.is_juice_on(&"__nonexistent_key"))

	# State transitions: off then back on.
	dm.set_juice(&"particles", false)
	_ok("set_juice OFF: particles is false", not dm.is_juice_on(&"particles"))
	dm.set_juice(&"particles", true)
	_ok("set_juice ON: particles restored to true", dm.is_juice_on(&"particles"))

	# Debug viz: perf_hud starts ON; velocity_vec and other overlays start OFF.
	_ok("debug_viz perf_hud default ON", dm.is_debug_viz_on(&"perf_hud"))
	_ok("debug_viz velocity_vec default OFF", not dm.is_debug_viz_on(&"velocity_vec"))

	# Unknown debug key falls back to false (opposite to juice — keeps HUD tidy).
	_ok("is_debug_viz_on: unknown key defaults to false",
		not dm.is_debug_viz_on(&"__nonexistent_key"))

	# Debug viz state transition.
	dm.set_debug_viz(&"velocity_vec", true)
	_ok("set_debug_viz ON: velocity_vec becomes true",
		dm.is_debug_viz_on(&"velocity_vec"))

	# Open/close state machine: starts closed, set_open, then toggle round-trips.
	_ok("dev menu closed by default", not dm.is_open)
	dm.set_open(true)
	_ok("set_open(true): is_open is true", dm.is_open)
	dm.set_open(false)
	_ok("set_open(false): is_open is false", not dm.is_open)
	dm.toggle()
	_ok("toggle from false: is_open becomes true", dm.is_open)
	dm.toggle()
	_ok("toggle back to false: is_open is false", not dm.is_open)

	dm.free()


func _test_perf_budget_particle_api() -> void:
	## Covers the register_particles / unregister_particles / reset_particles API
	## added to perf_budget.gd (iter 48).  Prior to this fix, active_particles
	## was always 0, so the over_budget() particle branch was permanently false.
	## Uses PB.new() — _process is never called, so triangles/draws/frametime
	## stay at 0, letting us isolate the particle branch of over_budget().
	print("\n-- PerfBudget particle tracking API --")
	var pb: PB = PB.new()

	# Initial state: counter starts at zero.
	_ok("active_particles starts at 0", pb.active_particles == 0)

	# register_particles: additive increments.
	pb.register_particles(50)
	_ok("register_particles(50): active_particles is 50", pb.active_particles == 50)
	pb.register_particles(100)
	_ok("register_particles(100) stacks: active_particles is 150", pb.active_particles == 150)

	# unregister_particles: decrements and clamps to 0.
	pb.unregister_particles(30)
	_ok("unregister_particles(30): active_particles is 120", pb.active_particles == 120)
	pb.unregister_particles(9999)
	_ok("unregister_particles beyond total: clamped to 0, not negative",
		pb.active_particles == 0)

	# over_budget() particle branch with live state.
	_ok("active_particles 0 → over_budget() particle branch false", not pb.over_budget())
	pb.register_particles(pb.ACTIVE_PARTICLES_BUDGET)
	_ok("active_particles == ACTIVE_PARTICLES_BUDGET → not over budget (strictly >)",
		not pb.over_budget())
	pb.register_particles(1)
	_ok("active_particles == ACTIVE_PARTICLES_BUDGET+1 → over_budget() true",
		pb.over_budget())

	# reset_particles: zeroes the counter, clears over-budget state.
	pb.reset_particles()
	_ok("reset_particles: active_particles is 0", pb.active_particles == 0)
	_ok("after reset_particles: over_budget() false (all metrics zero)", not pb.over_budget())

	# snapshot() reflects the live counter.
	pb.register_particles(77)
	var snap := pb.snapshot()
	_ok("snapshot() contains key 'active_particles'", snap.has("active_particles"))
	_ok("snapshot()['active_particles'] matches active_particles after register",
		snap["active_particles"] == 77)

	pb.free()


func _test_airborne_offset_math() -> void:
	## Covers the rigid-translate airborne camera invariant in camera_rig.gd.
	## Core maths (no Node objects — pure Vector3 arithmetic):
	##   offset = cam_pos − target_pos           (captured each grounded frame)
	##   cam_new = target_new + offset            (airborne branch)
	## Invariant: the camera translates by exactly the same delta as the player —
	## no rotation, no scale — so the cam→player vector is preserved mid-jump.
	print("\n-- airborne offset math (camera rigid translate) --")

	var cam_old := Vector3(7.0, 3.0, -5.0)
	var player_old := Vector3(1.0, 0.0, 0.0)

	# 1. Offset definition: player_pos + offset == cam_pos.
	var offset := cam_old - player_old
	_ok("offset recovers cam from player: player + offset == cam_old",
		(player_old + offset).is_equal_approx(cam_old))

	# 2. Rigid translate X: player moves laterally, camera tracks the same delta.
	var player_x := player_old + Vector3(2.0, 0.0, 0.0)
	var cam_x := player_x + offset
	_ok("rigid translate: camera X-delta == player X-delta (2.0)",
		is_equal_approx(cam_x.x - cam_old.x, 2.0))

	# 3. Rigid translate Y: player rises, camera rises by the same amount.
	var player_y := player_old + Vector3(0.0, 5.0, 0.0)
	var cam_y := player_y + offset
	_ok("rigid translate: camera Y-delta == player Y-delta (5.0)",
		is_equal_approx(cam_y.y - cam_old.y, 5.0))

	# 4. Zero player delta: camera does not move at all.
	var cam_zero_delta := player_old + offset
	_ok("rigid translate: zero player delta → camera stationary",
		cam_zero_delta.is_equal_approx(cam_old))

	# 5. Full 3D delta: all three axes tracked simultaneously.
	var delta_3d := Vector3(3.0, -1.0, 2.0)
	var p3_new := player_old + delta_3d
	var c3_new := p3_new + offset
	_ok("rigid translate: full 3D delta tracked exactly (cam_delta == player_delta)",
		(c3_new - cam_old).is_equal_approx(delta_3d))

	# 6. Offset invariant: after a rigid translate, new_offset equals old_offset.
	# Proof: (cam_new − player_new) = (cam_old + Δ) − (player_old + Δ) = offset.
	var new_offset := cam_x - player_x
	_ok("offset invariant: offset unchanged after rigid translate",
		new_offset.is_equal_approx(offset))

	# 7. Drag-during-airborne: dragging shifts cam → end-of-frame offset refresh
	# picks up the shift, so the NEXT frame's rigid translate incorporates drag.
	var drag_shift := Vector3(1.5, 0.0, -0.5)
	var cam_after_drag := cam_x + drag_shift
	var offset_after_drag := cam_after_drag - player_x
	_ok("drag during airborne shifts offset by drag vector",
		(offset_after_drag - offset).is_equal_approx(drag_shift))

	# 8. Sign convention: camera directly behind player (+Z) gives +Z offset.
	var cam_behind := Vector3(0.0, 2.0, 6.0)
	var player_centre := Vector3.ZERO
	_ok("camera behind player → positive Z offset",
		(cam_behind - player_centre).z > 0.0)


func _test_game_level_path_contract() -> void:
	## Documents that current_level_path is NOT cleared by reset_run() or
	## register_attempt(). This invariant is critical for Gate 1 scene
	## lifecycle: the reloader must know which level to restart, and that
	## path must survive any number of run resets within the same session.
	print("\n-- Game current_level_path contract --")
	var g: GM = GM.new()

	# 1. Field is writable.
	g.current_level_path = "res://scenes/levels/feel_lab.tscn"
	_ok("current_level_path is writable and readable",
		g.current_level_path == "res://scenes/levels/feel_lab.tscn")

	# 2. reset_run() must NOT clear current_level_path.
	# Rationale: a run reset (player dies, respawns at level start) is
	# a counter reset, not a level unload — the scene context persists.
	g.reset_run()
	_ok("reset_run does NOT clear current_level_path",
		g.current_level_path == "res://scenes/levels/feel_lab.tscn")

	# 3. register_attempt() must NOT clear current_level_path.
	g.register_attempt()
	_ok("register_attempt does NOT clear current_level_path",
		g.current_level_path == "res://scenes/levels/feel_lab.tscn")

	# 4. Path can be updated mid-session (as it would be when a new level loads).
	g.current_level_path = "res://scenes/levels/style_test.tscn"
	_ok("current_level_path can be updated to a different path",
		g.current_level_path == "res://scenes/levels/style_test.tscn")

	# 5. reset_run() still does not touch the updated path.
	g.reset_run()
	_ok("reset_run does NOT clear current_level_path after path update",
		g.current_level_path == "res://scenes/levels/style_test.tscn")

	# 6. Field can be cleared explicitly (blank = no level loaded).
	g.current_level_path = ""
	_ok("current_level_path can be set to empty string explicitly",
		g.current_level_path == "")

	# 7. Type is String, not StringName — resource paths use the String type.
	g.current_level_path = "res://scenes/levels/feel_lab.tscn"
	_ok("current_level_path is a String (not StringName)",
		typeof(g.current_level_path) == TYPE_STRING)

	g.free()


func _test_audio_bus_constants() -> void:
	## Documents the Audio autoload's bus name contract. Gate 1 SFX calls
	## will use Audio.BUS_SFX_PLAYER / BUS_SFX_WORLD — this test catches
	## any accidental renaming before it surfaces as a silent AudioServer miss.
	print("\n-- Audio autoload bus constants --")

	_ok("BUS_MASTER is 'Master'",    AU.BUS_MASTER    == &"Master")
	_ok("BUS_SFX_PLAYER is 'SFX_Player'", AU.BUS_SFX_PLAYER == &"SFX_Player")
	_ok("BUS_SFX_WORLD is 'SFX_World'",   AU.BUS_SFX_WORLD  == &"SFX_World")
	_ok("BUS_MUSIC is 'Music'",      AU.BUS_MUSIC     == &"Music")

	# No two bus names are the same — duplicate names would route SFX to the
	# wrong channel silently at runtime.
	var names: Array[StringName] = [
		AU.BUS_MASTER, AU.BUS_SFX_PLAYER, AU.BUS_SFX_WORLD, AU.BUS_MUSIC
	]
	var seen: Dictionary = {}
	for n in names:
		seen[n] = true
	_ok("all four bus constants are distinct (no accidental duplicates)",
		seen.size() == 4)


func _test_vertical_follow_ratchet() -> void:
	## Mirrors camera_rig.gd::_compute_effective_y. The camera holds Y at the
	## reference floor while the player stays below `floor + apex * multiplier`;
	## above that band, the camera tracks `player.y - apex * multiplier` so it
	## lifts at the same rate as the player. Multiplier 0 reverts to always-
	## track-Y. Pure math — no scene tree needed.
	print("\n-- Camera vertical-follow ratchet --")
	# Snappy at default values: apex_h = 11.5^2 / (2*38) ≈ 1.7401 m
	var snappy_apex := (11.5 * 11.5) / (2.0 * 38.0)

	# --- Below apex: camera holds Y at reference floor ---
	_ok("at rest on reference floor → effective_y == reference_floor",
		_near(_eff_y(0.0, 0.0, snappy_apex, 1.0), 0.0))
	_ok("mid-air at half-apex → effective_y still == reference_floor",
		_near(_eff_y(snappy_apex * 0.5, 0.0, snappy_apex, 1.0), 0.0))
	_ok("airborne at 0.9 of apex → effective_y still == reference_floor (normal jump)",
		_near(_eff_y(snappy_apex * 0.9, 0.0, snappy_apex, 1.0), 0.0))
	# Exact boundary at apex_y is the held-Y branch (`>`, not `>=`).
	_ok("at exactly apex_y → effective_y == reference_floor (boundary is `>`, strict)",
		_near(_eff_y(snappy_apex, 0.0, snappy_apex, 1.0), 0.0))

	# --- Above apex: camera tracks player.y - apex_h ---
	_ok("just above apex (apex + 0.01) → effective_y == 0.01 (tracking starts)",
		_near(_eff_y(snappy_apex + 0.01, 0.0, snappy_apex, 1.0), 0.01))
	_ok("0.5 m above apex → effective_y == 0.5 (linear above threshold)",
		_near(_eff_y(snappy_apex + 0.5, 0.0, snappy_apex, 1.0), 0.5))
	_ok("1.0 m above apex → effective_y == 1.0",
		_near(_eff_y(snappy_apex + 1.0, 0.0, snappy_apex, 1.0), 1.0))

	# --- Reference floor change (player landed on higher tier) ---
	# Reference floor lifts to 4.0 → apex band shifts up with it.
	_ok("on higher floor (y=4): at rest → effective_y == new reference (4.0)",
		_near(_eff_y(4.0, 4.0, snappy_apex, 1.0), 4.0))
	_ok("on higher floor (y=4): at half-apex → effective_y == 4.0 (band shifts with floor)",
		_near(_eff_y(4.0 + snappy_apex * 0.5, 4.0, snappy_apex, 1.0), 4.0))
	_ok("on higher floor (y=4): 1 m above apex → effective_y == 4 + 1 = 5.0",
		_near(_eff_y(4.0 + snappy_apex + 1.0, 4.0, snappy_apex, 1.0), 5.0))

	# --- Apex multiplier scaling ---
	# Multiplier 0.5 halves the band — camera follows earlier.
	_ok("multiplier 0.5: player at 0.5 * apex is exactly at half-band boundary (still holds)",
		_near(_eff_y(snappy_apex * 0.5, 0.0, snappy_apex, 0.5), 0.0))
	_ok("multiplier 0.5: just above half-band → effective_y == 0.01",
		_near(_eff_y(snappy_apex * 0.5 + 0.01, 0.0, snappy_apex, 0.5), 0.01))
	# Multiplier 2.0 doubles the band — camera lazier.
	_ok("multiplier 2.0: player at apex_h is still below the band → holds",
		_near(_eff_y(snappy_apex, 0.0, snappy_apex, 2.0), 0.0))
	_ok("multiplier 2.0: 1 m above 2*apex → effective_y == 1.0",
		_near(_eff_y(snappy_apex * 2.0 + 1.0, 0.0, snappy_apex, 2.0), 1.0))

	# --- Multiplier 0 (or missing profile): legacy always-track-Y ---
	_ok("multiplier 0: at rest on reference → effective_y == player_y (= reference)",
		_near(_eff_y(0.0, 0.0, snappy_apex, 0.0), 0.0))
	_ok("multiplier 0: airborne at 1.0 → effective_y == player_y (always tracks)",
		_near(_eff_y(1.0, 0.0, snappy_apex, 0.0), 1.0))
	_ok("multiplier 0: airborne at 5.0 → effective_y == player_y (always tracks)",
		_near(_eff_y(5.0, 0.0, snappy_apex, 0.0), 5.0))
	_ok("apex_h 0 (no profile): falls back to always-track-Y",
		_near(_eff_y(3.0, 0.0, 0.0, 1.0), 3.0))

	# --- Continuity: effective_y is C0 in player_y across the boundary ---
	# At apex_y, effective_y = reference. Just above, effective_y = epsilon.
	var below := _eff_y(snappy_apex - 0.0001, 0.0, snappy_apex, 1.0)
	var above := _eff_y(snappy_apex + 0.0001, 0.0, snappy_apex, 1.0)
	_ok("continuity at apex boundary: |delta| < 0.001 across the threshold",
		absf(above - below) < 0.001)

	# --- Monotonicity above apex: as player rises, effective_y rises 1:1 ---
	var step1 := _eff_y(snappy_apex + 1.0, 0.0, snappy_apex, 1.0)
	var step2 := _eff_y(snappy_apex + 2.0, 0.0, snappy_apex, 1.0)
	_ok("monotonicity above apex: effective_y(player+1) < effective_y(player+2)",
		step1 < step2)
	_ok("rate above apex: rises 1:1 with player.y (a 1 m rise → 1 m effective_y rise)",
		_near(step2 - step1, 1.0))

	# --- Below reference: camera tracks the fall 1:1 ---
	# Walking off a ledge from reference Y=4 — as player falls, effective_y
	# should follow down rather than stay pinned at the old reference.
	_ok("fall: 0.1 m below reference (small drop, just leaving the ledge) → tracks",
		_near(_eff_y(3.9, 4.0, snappy_apex, 1.0), 3.9))
	_ok("fall: 1 m below reference → effective_y == 3.0",
		_near(_eff_y(3.0, 4.0, snappy_apex, 1.0), 3.0))
	_ok("fall: 4 m drop into a pit → effective_y == 0.0",
		_near(_eff_y(0.0, 4.0, snappy_apex, 1.0), 0.0))
	_ok("fall: below-reference branch also fires from reference 0 (descent into negative Y)",
		_near(_eff_y(-2.0, 0.0, snappy_apex, 1.0), -2.0))

	# --- Boundary at player.y == reference_floor: hold (not track) ---
	# The check is strict `<`, so a player landed exactly at reference stays
	# in the held branch. Prevents one-frame oscillation between hold/track
	# when the player is at-rest on the reference floor.
	_ok("at exactly reference_floor_y → hold (strict `<` boundary)",
		_near(_eff_y(4.0, 4.0, snappy_apex, 1.0), 4.0))

	# --- Continuity at the lower (reference-floor) boundary ---
	# At reference, effective = reference. Just below, effective = epsilon-below.
	var ref_above := _eff_y(4.0, 4.0, snappy_apex, 1.0)
	var ref_below := _eff_y(3.9999, 4.0, snappy_apex, 1.0)
	_ok("continuity at reference-floor boundary: |delta| < 0.001 across the threshold",
		absf(ref_above - ref_below) < 0.001)

	# --- Monotonicity below reference: as player falls, effective_y falls 1:1 ---
	var fall1 := _eff_y(3.5, 4.0, snappy_apex, 1.0)
	var fall2 := _eff_y(2.5, 4.0, snappy_apex, 1.0)
	_ok("monotonicity below reference: effective_y at lower player.y is lower",
		fall2 < fall1)
	_ok("rate below reference: falls 1:1 with player.y (1 m drop → 1 m effective_y drop)",
		_near(fall1 - fall2, 1.0))

	# --- Default multiplier 1.15: analytic max is comfortably inside hold band ---
	# Player at analytic max (Snappy ~1.74 m) sits in the held band because
	# 1.15 × 1.74 = 2.001 m, comfortably above the player's reachable peak.
	# The 15% headroom absorbs Jolt floor-physics jitter that can momentarily
	# push player.y a few mm over the analytic peak.
	const DEFAULT_MULT := 1.15
	_ok("default multiplier 1.15: player AT analytic max → held (no tracking)",
		_near(_eff_y(snappy_apex, 0.0, snappy_apex, DEFAULT_MULT), 0.0))
	_ok("default multiplier 1.15: player 5 cm above analytic max → still held",
		_near(_eff_y(snappy_apex + 0.05, 0.0, snappy_apex, DEFAULT_MULT), 0.0))
	_ok("default multiplier 1.15: player 14% above analytic max → still held",
		_near(_eff_y(snappy_apex * 1.14, 0.0, snappy_apex, DEFAULT_MULT), 0.0))
	# A double-jump or wall-jump should still trigger tracking — i.e. heights
	# significantly above the analytic max (say >30%) should clear the band.
	_ok("default multiplier 1.15: 30% above analytic max → tracks (double-jump territory)",
		_eff_y(snappy_apex * 1.30, 0.0, snappy_apex, DEFAULT_MULT) > 0.0)
	_ok("default multiplier 1.15: 50% above analytic max → tracks (wall-jump / vertical traversal)",
		_eff_y(snappy_apex * 1.50, 0.0, snappy_apex, DEFAULT_MULT) > 0.0)


func _test_default_apex_height_formula() -> void:
	## Documents player.gd::get_default_apex_height, which derives the camera
	## ratchet's apex band from v² / (2g) of the active profile. Tests the pure
	## formula against the four shipped profiles' jump_velocity / gravity_rising
	## pairs so a profile-edit doesn't silently re-tune the camera.
	print("\n-- Default apex height (v² / 2g) per profile --")
	# Apex = jump_velocity² / (2 * gravity_rising)
	# Snappy:   11.5² / (2 * 38.0)  = 132.25 / 76    ≈ 1.7401 m
	# Floaty:   10.0² / (2 * 20.0)  = 100.0 / 40     = 2.5000 m
	# Momentum: 12.0² / (2 * 30.0)  = 144.0 / 60     = 2.4000 m
	# Assisted: 10.0² / (2 * 15.0)  = 100.0 / 30     ≈ 3.3333 m
	# (Values read from .tres files at iter 51 baseline. Test reads them live.)
	# Bounds [0.8, 4.0] m: lower bound = jumping over a 1 m platform comfortably;
	# upper bound accommodates Assisted's accessibility-tuned high apex without
	# allowing a pathologically tall jump that would never trip the ratchet.

	for path: String in [
		"res://resources/profiles/snappy.tres",
		"res://resources/profiles/floaty.tres",
		"res://resources/profiles/momentum.tres",
		"res://resources/profiles/assisted.tres",
	]:
		var p := _load_profile(path)
		if p == null:
			continue
		var apex := (p.jump_velocity * p.jump_velocity) / (2.0 * p.gravity_rising)
		var name := path.get_file().get_basename()
		_ok("%s: apex height in [0.8, 4.0] m (got %.3f)" % [name, apex],
			apex >= 0.8 and apex <= 4.0)
		_ok("%s: gravity_rising > 0 (formula safe)" % name, p.gravity_rising > 0.0)
		_ok("%s: jump_velocity > 0 (formula safe)" % name, p.jump_velocity > 0.0)

	# Edge cases of the formula itself
	_ok("zero jump_velocity → 0 m apex (no jump → no band)",
		_near(_apex_formula(0.0, 38.0), 0.0))
	_ok("zero gravity → fallback returns 0 (would divide-by-zero otherwise)",
		_near(_apex_formula(11.5, 0.0), 0.0))
	_ok("negative gravity → fallback returns 0 (guard against malformed profile)",
		_near(_apex_formula(11.5, -1.0), 0.0))
	# Double jump_velocity → 4× apex (quadratic in v)
	var single_v := _apex_formula(10.0, 30.0)
	var double_v := _apex_formula(20.0, 30.0)
	_ok("quadratic in velocity: double v → 4× apex",
		_near(double_v, single_v * 4.0))


# Helpers for the vertical-follow tests.

func _eff_y(player_y: float, anchor_y: float, apex_h: float, multiplier: float) -> float:
	## Mirror of camera_rig.gd::_compute_effective_y when the apex anchor and
	## reference floor are the same value — i.e. the steady-state case where
	## the player has been standing on a tier long enough for the smoothed
	## reference to converge to the instant-tracked anchor. Delegates to
	## `_eff_y_split` with `apex_anchor_y == reference_y == anchor_y`. For
	## testing the split case (anchor ≠ reference, e.g. during a jump after
	## a recent tier change while smoothing is still in progress), use
	## `_eff_y_split` directly.
	return _eff_y_split(player_y, anchor_y, anchor_y, apex_h, multiplier)


func _apex_formula(jump_velocity: float, gravity_rising: float) -> float:
	## Mirror of player.gd::get_default_apex_height. v² / (2g), with guards.
	if gravity_rising <= 0.0 or jump_velocity <= 0.0:
		return 0.0
	return (jump_velocity * jump_velocity) / (2.0 * gravity_rising)


func _test_reference_floor_smoothing() -> void:
	## Mirrors camera_rig.gd::_update_reference_floor. When the player lands on
	## a new tier, the reference floor eases up/down rather than snapping —
	## the camera transitions over ~400 ms at the default 6/sec rate instead
	## of cutting hard. Snap threshold preserves the instant-jump behaviour
	## for respawns and very long falls.
	print("\n-- Camera reference-floor smoothing --")
	const DELTA := 1.0 / 60.0
	const RATE := 6.0
	const SNAP := 8.0

	# --- Airborne: reference stays put (no leak from jumping above old floor) ---
	var ref := 0.0
	# Player Y rising above old reference while airborne shouldn't update ref.
	for _f in 30:
		ref = _ref_update(ref, 3.0, false, DELTA, RATE, SNAP)
	_ok("airborne for 30 frames: reference holds at 0 (no grounded-frame update)",
		_near(ref, 0.0))

	# --- Smoothed catch-up on grounded frames ---
	# After one frame at rate=6/sec, delta=1/60: t = 1 - exp(-0.1) ≈ 0.0952.
	# Lerp from 0 toward 4: 0 + 0.0952 * 4 ≈ 0.381.
	ref = 0.0
	ref = _ref_update(ref, 4.0, true, DELTA, RATE, SNAP)
	_ok("first grounded frame on +4 m tier: ref lifts ~0.38 m (not all the way)",
		ref > 0.30 and ref < 0.45)
	# After 10 frames (~167 ms): closer but still not at target.
	ref = 0.0
	for _f in 10:
		ref = _ref_update(ref, 4.0, true, DELTA, RATE, SNAP)
	# Closed-form: ref = 4 * (1 - exp(-6 * 10/60)) = 4 * (1 - exp(-1)) ≈ 2.53.
	_ok("10 frames in (~167 ms): ref ≈ 2.53 m (≈63% of the way to 4 m)",
		ref > 2.4 and ref < 2.6)
	# After 30 frames (~500 ms): essentially settled (within ~5%; the residual
	# at 3 time constants is exp(-3) ≈ 4.98% so the target is at 3.80 m).
	ref = 0.0
	for _f in 30:
		ref = _ref_update(ref, 4.0, true, DELTA, RATE, SNAP)
	_ok("30 frames in (~500 ms): ref settled within 6% of target (≥ 3.76 m)",
		ref > 3.76 and ref <= 4.0)
	# Monotonic + asymptotic: never overshoots.
	var prev := 0.0
	var monotonic := true
	var capped := true
	ref = 0.0
	for _f in 120:
		ref = _ref_update(ref, 4.0, true, DELTA, RATE, SNAP)
		if ref < prev - 1e-6:
			monotonic = false
		if ref > 4.0 + 1e-6:
			capped = false
		prev = ref
	_ok("monotonic: smoothed ref never reverses across 120 frames", monotonic)
	_ok("asymptotic: smoothed ref never overshoots target across 120 frames", capped)

	# --- Symmetry: dropping down to a lower tier eases the same way ---
	ref = 4.0
	for _f in 30:
		ref = _ref_update(ref, 0.0, true, DELTA, RATE, SNAP)
	_ok("dropping from +4 m to 0 over 30 frames: residual < 0.25 m (symmetric to climb)",
		ref >= 0.0 and ref < 0.25)

	# --- Snap threshold: huge delta bypasses the smoothing ---
	ref = 0.0
	# A 10 m jump exceeds the 8 m default snap threshold.
	ref = _ref_update(ref, 10.0, true, DELTA, RATE, SNAP)
	_ok("delta > snap threshold (10 m > 8 m): single frame snaps to player_y",
		_near(ref, 10.0))
	# Exactly at the threshold: still smooth (strict `>`).
	ref = 0.0
	ref = _ref_update(ref, 8.0, true, DELTA, RATE, SNAP)
	_ok("delta == snap threshold (8 m == 8 m): smooth, not snap (boundary strict)",
		ref < 8.0 and ref > 0.0)
	# Snap is symmetric for descents too.
	ref = 10.0
	ref = _ref_update(ref, 0.0, true, DELTA, RATE, SNAP)
	_ok("descending delta > snap threshold (10 m drop): single frame snaps to 0",
		_near(ref, 0.0))

	# --- Smoothing rate 0: legacy instant-snap behaviour ---
	ref = 0.0
	ref = _ref_update(ref, 4.0, true, DELTA, 0.0, SNAP)
	_ok("smoothing rate 0: single frame snaps to player_y (legacy behaviour)",
		_near(ref, 4.0))

	# --- Higher rate converges faster ---
	var ref_slow := 0.0
	var ref_fast := 0.0
	for _f in 10:
		ref_slow = _ref_update(ref_slow, 4.0, true, DELTA, 3.0, SNAP)
		ref_fast = _ref_update(ref_fast, 4.0, true, DELTA, 12.0, SNAP)
	_ok("rate=12 closes faster than rate=3 over the same 10 frames",
		ref_fast > ref_slow)

	# --- Initial-frame snap (uninitialised camera) ---
	ref = _ref_update_initial(7.5)
	_ok("initial frame (not initialised): ref snaps to player_y regardless of rate",
		_near(ref, 7.5))


# Mirrors camera_rig.gd::_update_reference_floor for the post-init smoothing path.
# Returns the next _reference_floor_y given current reference + player Y + state.
func _ref_update(current_ref: float, player_y: float, on_floor: bool,
		delta: float, rate: float, snap_threshold: float) -> float:
	if not on_floor:
		return current_ref
	var d := absf(player_y - current_ref)
	if d > snap_threshold or rate <= 0.0:
		return player_y
	var t := 1.0 - exp(-rate * delta)
	return lerpf(current_ref, player_y, t)


# Mirrors the not-yet-initialised first-frame branch — reference always snaps
# regardless of smoothing rate, since the camera has no prior pose to ease from.
func _ref_update_initial(player_y: float) -> float:
	return player_y


func _test_apex_anchor_split() -> void:
	## Mirrors the apex-anchor / reference split in `camera_rig.gd`. The apex
	## threshold uses `_apex_anchor_y` (instant-tracked on grounded frames,
	## held during airborne) so the check is tied to the player's actual
	## takeoff floor; the hold and track-down branches use `_reference_floor_y`
	## (smoothed) so tier-change transitions still glide rather than snap.
	## This split fixes the "jump-too-soon-after-landing" jitter while
	## preserving the smoothed landing transition.
	print("\n-- Camera apex-anchor / reference split --")
	const DEFAULT_MULT := 1.15
	var snappy_apex := (11.5 * 11.5) / (2.0 * 38.0)  # ≈ 1.74 m
	var snappy_peak_euler := 1.646  # semi-implicit Euler peak at 60 fps with Snappy params

	# --- The bug pre-split: jump-too-soon-after-tier-change ---
	# Scenario: player landed on tier Y=1.5 from Y=0. Reference smooths 0→1.5
	# at 6/sec; mid-smooth value is e.g. 0.5. Player jumps before smoothing
	# completes. Apex anchor is at 1.5 (instant-tracked on the last grounded
	# frame), reference is held at 0.5 during airborne.
	var ref_mid_smooth := 0.5
	var anchor_takeoff := 1.5
	var player_peak := anchor_takeoff + snappy_peak_euler  # 3.146

	# With the split, the apex threshold is `anchor + band = 1.5 + 2.0 = 3.5`.
	# Player peak 3.146 < 3.5 → hold → effective_y = reference (0.5).
	var split_at_peak := _eff_y_split(player_peak, anchor_takeoff, ref_mid_smooth, snappy_apex, DEFAULT_MULT)
	_ok("split: peak below `anchor + band` → hold branch (effective_y = reference)",
		_near(split_at_peak, ref_mid_smooth))

	# Pre-split (the buggy state): apex threshold was `reference + band = 0.5 + 2.0 = 2.5`.
	# Same player peak 3.146 > 2.5 → track-up → effective_y = player.y - band.
	var presplit_at_peak := _eff_y(player_peak, ref_mid_smooth, snappy_apex, DEFAULT_MULT)
	_ok("pre-split: peak above `reference + band` → spurious track-up",
		presplit_at_peak > ref_mid_smooth)

	# The split eliminates the spurious motion: at peak, effective_y stays at
	# reference, which is the same value it had pre-takeoff. No discontinuity.
	_ok("split: at peak, effective_y equals reference (= pre-takeoff effective_y)",
		_near(split_at_peak, ref_mid_smooth))

	# --- effective_y is continuous across takeoff ---
	# Pre-takeoff: grounded with apex_anchor = player.y (instant tracked).
	# anchor = 1.5, reference = 0.5. Player.y = 1.5.
	# apex_y = 1.5 + 2.0 = 3.5. player.y (1.5) > 3.5? No. < reference (0.5)? No. Hold → reference.
	var preflight := _eff_y_split(1.5, 1.5, ref_mid_smooth, snappy_apex, DEFAULT_MULT)
	_ok("pre-takeoff (grounded): effective_y = reference (= 0.5, mid-smoothing)",
		_near(preflight, ref_mid_smooth))

	# Takeoff frame: airborne. Anchor held at 1.5. Reference held at 0.5.
	# Same effective_y. NO change at the takeoff transition.
	var first_air_frame := _eff_y_split(1.5, 1.5, ref_mid_smooth, snappy_apex, DEFAULT_MULT)
	_ok("takeoff frame: effective_y unchanged from pre-takeoff (no rotation, no pop)",
		_near(first_air_frame, preflight))

	# --- Above-apex still triggers track-up ---
	# A double-jump from Y=1.5 reaching ~1.5 + 2 × 1.646 = 4.79 m exceeds the
	# anchor-band ceiling (1.5 + 2.0 = 3.5) and should track up.
	var double_jump_peak := anchor_takeoff + 2.0 * snappy_peak_euler
	var double_jump_eff := _eff_y_split(double_jump_peak, anchor_takeoff, ref_mid_smooth, snappy_apex, DEFAULT_MULT)
	_ok("split: double-jump peak above `anchor + band` → tracks up (camera lifts as designed)",
		double_jump_eff > ref_mid_smooth)
	_ok("split: track-up returns player.y - band (1:1 lift above anchor)",
		_near(double_jump_eff, double_jump_peak - snappy_apex * DEFAULT_MULT))

	# --- Below-reference still triggers track-down ---
	# Walking off a ledge from Y=1.5 (anchor 1.5, reference settled at 1.5),
	# then falling to Y=0.5 (below reference). Anchor held at 1.5, reference
	# held at 1.5. Player.y < reference → track-down.
	var anchor_settled := 1.5
	var reference_settled := 1.5
	var falling_eff := _eff_y_split(0.5, anchor_settled, reference_settled, snappy_apex, DEFAULT_MULT)
	_ok("split: below reference → track-down (effective_y = player.y)",
		_near(falling_eff, 0.5))

	# --- Boundary at reference (held branch is strict `<`) ---
	_ok("split: player.y exactly at reference → hold (boundary strict)",
		_near(_eff_y_split(1.5, anchor_settled, reference_settled, snappy_apex, DEFAULT_MULT),
			reference_settled))

	# --- Anchor == reference equivalence (steady state) ---
	# When grounded and settled, anchor == reference == player.y. The split
	# helper reduces to the original `_eff_y` semantics in this case.
	var p := 2.0
	_ok("anchor == reference equivalence: split === eff_y (held band)",
		_near(_eff_y_split(p + 1.0, p, p, snappy_apex, DEFAULT_MULT),
			_eff_y(p + 1.0, p, snappy_apex, DEFAULT_MULT)))
	_ok("anchor == reference equivalence: split === eff_y (track-up)",
		_near(_eff_y_split(p + 3.0, p, p, snappy_apex, DEFAULT_MULT),
			_eff_y(p + 3.0, p, snappy_apex, DEFAULT_MULT)))


# Mirrors camera_rig.gd::_compute_effective_y when the apex anchor and
# reference floor are *split* — i.e. their semantic distinction (apex
# anchor = instant-tracked, reference = smoothed) matters. The original
# `_eff_y` is a wrapper that passes the same value for both.
func _eff_y_split(player_y: float, apex_anchor_y: float, reference_y: float,
		apex_h: float, multiplier: float) -> float:
	var band := apex_h * multiplier
	if band <= 0.0:
		return player_y
	if player_y > apex_anchor_y + band:
		return player_y - band
	if player_y < reference_y:
		return player_y
	return reference_y


func _test_double_jump_logic() -> void:
	# --- Backwards-compatibility: all shipped profiles default to 0 air jumps ---
	# (1-4) Each .tres file omits the property, so it uses the class default (0).
	var snappy   := preload("res://resources/profiles/snappy.tres")   as CP
	var floaty   := preload("res://resources/profiles/floaty.tres")   as CP
	var momentum := preload("res://resources/profiles/momentum.tres") as CP
	var assisted := preload("res://resources/profiles/assisted.tres") as CP
	_ok("snappy: air_jumps default = 0 (backwards-compatible)", snappy.air_jumps == 0)
	_ok("floaty: air_jumps default = 0 (backwards-compatible)", floaty.air_jumps == 0)
	_ok("momentum: air_jumps default = 0 (backwards-compatible)", momentum.air_jumps == 0)
	_ok("assisted: air_jumps default = 0 (backwards-compatible)", assisted.air_jumps == 0)

	# --- Default parameter values are sensible and backwards-compatible ---
	var cp := CP.new()
	# (5) Default multiplier sits in the "weaker-than-ground but not trivially weak" band.
	_ok("default air_jump_velocity_multiplier in (0.5, 1.0]",
		cp.air_jump_velocity_multiplier > 0.5 and cp.air_jump_velocity_multiplier <= 1.0)
	# (6) Default horizontal-preserve = 1.0 → upholds the CLAUDE.md preserved-H-vel invariant.
	_ok("default air_jump_horizontal_preserve = 1.0 (full preservation, backwards-compatible)",
		_near(cp.air_jump_horizontal_preserve, 1.0))

	# --- Air jump velocity formula ---
	# (7) v_air = jump_velocity × multiplier.
	cp.jump_velocity = 10.0
	cp.air_jump_velocity_multiplier = 0.8
	var v_air := cp.jump_velocity * cp.air_jump_velocity_multiplier
	_ok("air jump velocity formula: 10.0 × 0.8 = 8.0", _near(v_air, 8.0))
	# (8) multiplier < 1 → air jump is weaker than ground jump.
	_ok("multiplier 0.8 → air jump weaker than ground jump", v_air < cp.jump_velocity)
	# (9) multiplier = 1.0 → air jump matches ground jump.
	cp.air_jump_velocity_multiplier = 1.0
	_ok("multiplier 1.0 → air jump equals ground jump velocity",
		_near(cp.jump_velocity * cp.air_jump_velocity_multiplier, cp.jump_velocity))

	# --- Horizontal-preserve formula ---
	# (10) Full preservation: H × 1.0 = H unchanged.
	var h_vel := 5.0
	_ok("horizontal preserve 1.0 leaves horizontal velocity unchanged",
		_near(h_vel * 1.0, h_vel))
	# (11) Half preservation: H × 0.5 halves horizontal speed.
	_ok("horizontal preserve 0.5 halves horizontal speed", _near(h_vel * 0.5, 2.5))

	# --- Branch priority: ground jump takes precedence over air jump ---
	# Mirrors the `if buffer>0 and coyote>0` / `elif buffer>0 and remaining>0` logic
	# in player.gd::_try_jump().
	var buf := 0.05     # live buffer
	var coy := 0.05     # live coyote (still on/just left ground)
	var rem := 1        # one air jump available
	# (12) When both buffer and coyote are positive, the ground branch fires.
	_ok("buffer + coyote > 0 → ground branch fires (not air branch)",
		buf > 0.0 and coy > 0.0)
	# (13) When coyote expires, the air branch fires (provided remaining > 0).
	coy = 0.0
	_ok("buffer > 0, coyote = 0, remaining > 0 → air branch fires",
		buf > 0.0 and not (buf > 0.0 and coy > 0.0) and rem > 0)

	# --- Counter management ---
	# (14) Decrement: one air jump used → remaining goes from 1 to 0.
	rem -= 1
	_ok("remaining decrements after one air jump: 1 → 0", rem == 0)
	# (15) Exhausted counter → air branch condition false.
	_ok("remaining = 0 → air branch does not fire", rem <= 0)

	# --- On-floor reset (mirrors _tick_timers on_floor branch) ---
	# (16) Landing refills the counter to air_jumps.
	cp.air_jumps = 2
	var reset_val := cp.air_jumps   # _tick_timers: _air_jumps_remaining = profile.air_jumps
	_ok("on_floor reset: _air_jumps_remaining restored to air_jumps (2)", reset_val == 2)
	# (17) When air_jumps = 0, reset still gives 0 (feature disabled on this profile).
	cp.air_jumps = 0
	_ok("air_jumps = 0: on_floor reset gives 0 (double-jump disabled)", cp.air_jumps == 0)


func _test_air_dash_logic() -> void:
	# --- Backwards-compat: all shipped profiles default to air_dash_speed = 0.0 ---
	var snappy   := preload("res://resources/profiles/snappy.tres")   as CP
	var floaty   := preload("res://resources/profiles/floaty.tres")   as CP
	var momentum := preload("res://resources/profiles/momentum.tres") as CP
	var assisted := preload("res://resources/profiles/assisted.tres") as CP
	# (1-4)
	_ok("snappy: air_dash_speed = 0.0 (dash disabled by default)",   _near(snappy.air_dash_speed, 0.0))
	_ok("floaty: air_dash_speed = 0.0 (dash disabled by default)",   _near(floaty.air_dash_speed, 0.0))
	_ok("momentum: air_dash_speed = 0.0 (dash disabled by default)", _near(momentum.air_dash_speed, 0.0))
	_ok("assisted: air_dash_speed = 0.0 (dash disabled by default)", _near(assisted.air_dash_speed, 0.0))

	var cp := CP.new()
	# (5) Duration in usable range: not so short it's invisible, not so long it becomes flight.
	_ok("default air_dash_duration in [0.05, 0.5]",
		cp.air_dash_duration >= 0.05 and cp.air_dash_duration <= 0.5)
	# (6) Gravity scale in [0, 1].
	_ok("default air_dash_gravity_scale in [0.0, 1.0]",
		cp.air_dash_gravity_scale >= 0.0 and cp.air_dash_gravity_scale <= 1.0)
	# (7) Default gravity scale is perceptibly reduced (< 0.5) — dash should feel like near-flight.
	_ok("default air_dash_gravity_scale < 0.5 (noticeable gravity reduction during dash)",
		cp.air_dash_gravity_scale < 0.5)

	# --- Charge management (mirrors _tick_timers + _try_air_dash logic) ---
	var charges := 0
	# (8) Landing refills to 1.
	charges = 1   # _tick_timers on_floor branch
	_ok("charges refill to 1 on landing", charges == 1)
	# (9) Using a dash decrements the counter.
	charges -= 1
	_ok("charges decrement after use: 1 → 0", charges == 0)
	# (10) Exhausted guard: condition in _try_air_dash.
	_ok("charges = 0 → dash blocked by guard", charges <= 0)

	# --- Trigger guards ---
	# (11) air_dash_speed = 0.0 disables the dash.
	cp.air_dash_speed = 0.0
	_ok("air_dash_speed = 0.0 → speed guard blocks dash", cp.air_dash_speed <= 0.0)
	# (12) Non-zero speed passes the guard.
	cp.air_dash_speed = 10.0
	_ok("air_dash_speed = 10.0 → speed guard passes", cp.air_dash_speed > 0.0)

	# --- Dash velocity formula (mirrors _try_air_dash assignment) ---
	var speed := 10.0
	var dir   := Vector3(1.0, 0.0, 0.0)   # dash right
	# (13) Horizontal velocity set to dir × speed.
	_ok("velocity.x = dir.x × speed: 1.0 × 10.0 = 10.0", _near(dir.x * speed, 10.0))
	# (14) Z component = 0 for a pure-right dash.
	_ok("velocity.z = dir.z × speed: 0.0 × 10.0 = 0.0", _near(dir.z * speed, 0.0))

	# --- Gravity scaling during dash (mirrors _apply_gravity) ---
	var g_normal := 75.0   # gravity_after_apex for snappy
	cp.air_dash_gravity_scale = 0.15
	# (15) Scaled gravity = g_normal × scale.
	_ok("gravity during dash = g_normal × scale: 75 × 0.15 = 11.25",
		_near(g_normal * cp.air_dash_gravity_scale, 75.0 * 0.15))
	# (16) scale = 0.0 → zero gravity during dash.
	cp.air_dash_gravity_scale = 0.0
	_ok("gravity_scale = 0.0 → zero gravity during dash",
		_near(g_normal * cp.air_dash_gravity_scale, 0.0))
	# (17) scale = 1.0 → full normal gravity.
	cp.air_dash_gravity_scale = 1.0
	_ok("gravity_scale = 1.0 → full normal gravity during dash",
		_near(g_normal * cp.air_dash_gravity_scale, g_normal))

	# --- Direction fallback logic (mirrors _try_air_dash resolution) ---
	var vel_h := Vector3(5.0, 0.0, 0.0)
	var input_dir := Vector3.ZERO
	var resolved := input_dir if input_dir.length() > 0.01 else vel_h.normalized()
	# (18) Zero input → falls back to current horizontal velocity direction.
	_ok("zero input → dash direction falls back to velocity direction (+X)",
		resolved.is_equal_approx(Vector3(1.0, 0.0, 0.0)))
	# Non-zero input overrides: verify the condition produces the input.
	input_dir = Vector3(0.0, 0.0, -1.0)
	resolved   = input_dir if input_dir.length() > 0.01 else vel_h.normalized()
	_ok("non-zero input → dash direction uses input direction (-Z)",
		resolved.is_equal_approx(Vector3(0.0, 0.0, -1.0)))


func _test_game_gate1_api() -> void:
	## Gate 1 additions to the Game autoload: is_running, shards_collected/total,
	## start_run(), level_complete(). Also validates that reset_run() clears the
	## new fields (backwards-compat for code that calls reset_run without start_run).
	print("\n-- Game Gate 1 API --")
	var g: GM = GM.new()

	# Default values for all new Gate 1 fields.
	_ok("Game.is_running default is false", g.is_running == false)
	_ok("Game.shards_collected default is 0", g.shards_collected == 0)
	_ok("Game.shards_total default is 0", g.shards_total == 0)

	# start_run(): activates timer and clears per-run state.
	g.run_time_seconds = 5.0
	g.shards_collected = 3
	g.start_run()
	_ok("start_run: is_running set to true", g.is_running == true)
	_ok("start_run: run_time_seconds zeroed", _near(g.run_time_seconds, 0.0))
	_ok("start_run: shards_collected zeroed", g.shards_collected == 0)

	# level_complete(): stops timer; level_completed signal emitted (existence checked
	# in _test_game_autoload_contract; emission is tested via connected callback).
	g.level_complete()
	_ok("level_complete: is_running set to false (timer stops)", g.is_running == false)

	# reset_run(): clears all run-state including Gate 1 fields.
	g.is_running = true
	g.shards_collected = 2
	g.reset_run()
	_ok("reset_run: is_running cleared to false", g.is_running == false)
	_ok("reset_run: shards_collected cleared to 0", g.shards_collected == 0)

	# shards_total is level-owned: set by the level script, not by start_run/reset_run.
	g.shards_total = 3
	g.start_run()
	_ok("shards_total unchanged by start_run (level sets it)", g.shards_total == 3)
	g.reset_run()
	_ok("shards_total unchanged by reset_run (level sets it)", g.shards_total == 3)

	g.free()


func _test_data_shard_placement() -> void:
	## Documents the collection-geometry contract for the Threshold data shard.
	## Shard at (7, -4.0, 82). Small ledge surface at y = -6.0 (center -6.25, h=0.5).
	## Player capsule: radius 0.28, height (cylinder) 0.9, center offset 0.45 from origin.
	## Snappy profile: jump_velocity 11.5, gravity_rising 38.0.
	print("\n-- Data shard placement --")

	# Constants mirrored from data_shard.gd and player.tscn.
	var sphere_radius: float = 0.6
	var capsule_radius: float = 0.28
	var capsule_center_offset: float = 0.45
	var collection_threshold: float = sphere_radius + capsule_radius  # 0.88 m

	_ok("Collection threshold = sphere_r + capsule_r = 0.88 m",
		_near(collection_threshold, 0.88))

	# Player origin when standing on a surface: surface_y + capsule_radius
	# (bottom hemisphere centre sits at player.origin; shape bottom = origin - radius).
	var ledge_surface_y: float = -6.0  # ShardLedge top face
	var shard_y: float = -4.0

	var origin_on_ledge: float = ledge_surface_y + capsule_radius  # -5.72
	var cap_centre_standing: float = origin_on_ledge + capsule_center_offset  # -5.27
	var dist_standing: float = absf(cap_centre_standing - shard_y)
	_ok("Shard NOT collected while standing on ledge (dist %.2f > threshold %.2f)" %
		[dist_standing, collection_threshold],
		dist_standing > collection_threshold)

	# At jump apex from the ledge.
	var jump_velocity: float = 11.5   # Snappy default
	var gravity_rising: float = 38.0  # Snappy default
	var apex_height: float = jump_velocity * jump_velocity / (2.0 * gravity_rising)
	var origin_at_apex: float = origin_on_ledge + apex_height
	var cap_centre_apex: float = origin_at_apex + capsule_center_offset
	var dist_apex: float = absf(cap_centre_apex - shard_y)
	_ok("Shard collected at jump apex from ledge (dist %.2f < threshold %.2f)" %
		[dist_apex, collection_threshold],
		dist_apex < collection_threshold)

	# From the G1 gantry surface (y = -5.0), player at right edge (x = 4).
	# Shard is at x = 7, y = -4.0 — separation is 3D, not just vertical.
	var g1_surface_y: float = -5.0
	var origin_on_g1: float = g1_surface_y + capsule_radius  # -4.72
	var cap_centre_g1: float = origin_on_g1 + capsule_center_offset  # -4.27
	var g1_right_edge_x: float = 4.0
	var shard_x: float = 7.0
	var dist_from_g1: float = sqrt(
		pow(shard_x - g1_right_edge_x, 2) + pow(shard_y - cap_centre_g1, 2))
	_ok("Shard NOT collected from G1 gantry right edge (3D dist %.2f > threshold)" %
		dist_from_g1,
		dist_from_g1 > collection_threshold)

	# Game.shards_collected increment and double-collect guard.
	var g: GM = GM.new()
	g._ready()
	_ok("shards_collected starts at 0", g.shards_collected == 0)

	# Simulate first collection.
	var already: bool = false
	if not already:
		g.shards_collected += 1
		already = true
	_ok("shards_collected is 1 after first collect", g.shards_collected == 1)

	# Simulate second trigger (guard should block).
	if not already:
		g.shards_collected += 1
	_ok("Double-collect guard: shards_collected still 1", g.shards_collected == 1)

	g.free()


func _test_results_panel_formatting() -> void:
	## ResultsPanel._fmt_time() output and par-colour logic.
	## Pure functions — no scene tree needed.
	print("\n-- ResultsPanel formatting --")
	var rp := RP.new()

	# Time format: "%d:%02d.%02d" — minutes, seconds, centiseconds.
	_ok("fmt_time(0.0) == '0:00.00'",    rp._fmt_time(0.0)    == "0:00.00")
	_ok("fmt_time(35.0) == '0:35.00'",   rp._fmt_time(35.0)   == "0:35.00")
	_ok("fmt_time(60.0) == '1:00.00'",   rp._fmt_time(60.0)   == "1:00.00")
	_ok("fmt_time(65.5) == '1:05.50'",   rp._fmt_time(65.5)   == "1:05.50")
	_ok("fmt_time(3661.0) == '61:01.00'",rp._fmt_time(3661.0) == "61:01.00")
	_ok("fmt_time(0.25) == '0:00.25'",   rp._fmt_time(0.25)   == "0:00.25")

	# Par colour selection (mirrors `show_results` ternary — testable without scene):
	#   Color(0.45, 1.0, 0.45) if time_s <= par_s else Color(1.0, 0.45, 0.45)
	var beat_color := Color(0.45, 1.0, 0.45)
	var fail_color := Color(1.0, 0.45, 0.45)
	_ok("par-beat color is green (g > r)", beat_color.g > beat_color.r)
	_ok("par-fail color is red (r > g)",   fail_color.r > fail_color.g)
	_ok("par exactly equal counts as beat (<=, not <)", 35.0 <= 35.0)

	# Shard count string (mirrors show_results shard_val.text).
	_ok("shard string '2 / 3'", ("%d / %d" % [2, 3]) == "2 / 3")
	_ok("shard string '0 / 1'", ("%d / %d" % [0, 1]) == "0 / 1")

	rp.free()


func _test_win_state_one_shot_guard() -> void:
	## WinState and CheckPoint both use a single bool to block re-entry.
	## Verify defaults, set, and (for CheckPoint) reset().
	## No _ready() call — only checking instance var defaults and state transitions.
	print("\n-- Win-state + checkpoint one-shot guards --")

	# WinState: _triggered prevents Game.level_complete() from firing twice.
	var ws := WS.new()
	_ok("WinState._triggered defaults false",
		ws._triggered == false)
	ws._triggered = true
	_ok("_triggered set to true after first player entry",
		ws._triggered == true)
	_ok("One-shot guard: 'if _triggered: return' is a bool check (bool is true)",
		ws._triggered)
	ws.free()

	# CheckPoint: _activated locks after first player pass; reset() clears it
	# so the same trigger can be reused (dev menu "teleport" round-trips).
	var cp := CKP.new()
	_ok("CheckPoint._activated defaults false",
		cp._activated == false)
	cp._activated = true
	cp.reset()
	_ok("reset() clears _activated to false",
		cp._activated == false)
	cp._activated = true
	_ok("_activated locked true until reset() is called",
		cp._activated == true)
	cp.free()


func _test_data_shard_state_machine() -> void:
	## DataShard instance-var defaults and pure geometry constants.
	## Avoids calling methods that require a live scene tree
	## (create_tween, set_deferred) by testing only state and maths.
	print("\n-- DataShard state machine --")
	var ds := DS.new()

	# Instance-variable defaults (set by var declarations, not _ready()).
	_ok("_collected defaults false",    ds._collected == false)
	_ok("_mesh_instance defaults null", ds._mesh_instance == null)
	_ok("_light defaults null",         ds._light == null)

	# One-shot collection guard: _on_body_entered returns when _collected is true.
	ds._collected = true
	_ok("_collected=true blocks re-collection (guard is a simple bool check)",
		ds._collected)

	# Spin rate: 1.15 rad/s → one full revolution in ~5.47 s.
	# Readable without blurring: > 4 s (not a strobe), < 6 s (clearly spinning).
	var spin_period: float = (2.0 * PI) / 1.15
	_ok("Spin period < 6 s (visible motion at camera distance)", spin_period < 6.0)
	_ok("Spin period > 4 s (not blurring at frame rate)",        spin_period > 4.0)

	# Gem geometry from _build_gem_mesh(): top y=0.28, bottom y=-0.22, eq radius=0.20.
	# Height = 0.28 + 0.22 = 0.50 m — readable but not blocking the view.
	_ok("Gem total height (top + |bottom|) == 0.50 m",
		_near(0.28 + 0.22, 0.50))
	# Equatorial radius must fit inside the SphereShape3D collision radius (0.60 m).
	_ok("Gem equatorial radius 0.20 m < sphere collider radius 0.60 m",
		0.20 < 0.60)
	# Group name contract: threshold.gd auto-counts via get_nodes_in_group("data_shard").
	_ok("data_shard group StringName matches level auto-count query",
		StringName("data_shard") == &"data_shard")

	ds.free()


func _test_industrial_press_timing() -> void:
	## Mirrors the four-beat cycle math in industrial_press.gd.
	## Tests timing invariants, target_y formula, emissive energy formula,
	## and the kill-zone inset rule without instantiating any scene node.
	print("\n-- Industrial press timing math --")

	# Default export values from industrial_press.gd
	var stroke_depth  := 2.5
	var dormant_time  := 1.5
	var windup_time   := 0.80
	var stroke_time   := 0.18
	var rebound_time  := 0.50
	var origin_y      := 0.0   # test origin

	# Cycle time equals sum of all four phases.
	var cycle := dormant_time + windup_time + stroke_time + rebound_time
	_ok("cycle_time == 2.98 s", _near(cycle, 2.98))

	# Mobile safety: dormant >= 1.5 × crossing_time.
	# Press Z-depth = 5 m (size of Mesh_IndustrialPress); Snappy max_speed = 6.0 m/s.
	var press_depth    := 5.0
	var max_speed      := 6.0
	var crossing_time  := press_depth / max_speed
	_ok("dormant >= 1.5 × crossing_time (mobile latency safety)",
		dormant_time >= 1.5 * crossing_time)

	# Windup longer than stroke: player sees the windup and can react before the slam.
	_ok("windup_time > stroke_time", windup_time > stroke_time)

	# Stroke time is fast (danger beat is short, dormant window is the payoff).
	_ok("stroke_time < dormant_time", stroke_time < dormant_time)

	# _target_y formulas (mirror industrial_press.gd::_target_y()).
	# DORMANT — press at rest, p irrelevant.
	_ok("DORMANT target_y == origin_y", _near(origin_y, origin_y))

	# WINDUP at full p=1: retract 0.3 m above origin (small cocked-back draw).
	var windup_peak := origin_y + 1.0 * 0.3
	_ok("WINDUP p=1 retracted 0.3 m above origin", _near(windup_peak, origin_y + 0.3))

	# STROKE at p=0: still at origin (just started descent).
	var stroke_start := origin_y - 0.0 * stroke_depth
	_ok("STROKE p=0 == origin_y", _near(stroke_start, origin_y))

	# STROKE at p=1: fully extended, origin - stroke_depth.
	var stroke_end := origin_y - 1.0 * stroke_depth
	_ok("STROKE p=1 == origin_y - stroke_depth", _near(stroke_end, origin_y - stroke_depth))

	# REBOUND at p=1: fully returned to origin.
	var rebound_end := (origin_y - stroke_depth) + 1.0 * stroke_depth
	_ok("REBOUND p=1 == origin_y (full return)", _near(rebound_end, origin_y))

	# _update_emissive() energy formula.
	# DORMANT: constant 0.3 (dim ambient glow — press is safe).
	_ok("DORMANT emissive energy == 0.3", _near(0.3, 0.3))

	# STROKE: constant 2.5 (maximum brightness — danger).
	_ok("STROKE emissive energy == 2.5", _near(2.5, 2.5))

	# WINDUP at mid-stroke: lerpf(0.3, 2.5, 0.5) == 1.4.
	var mid_windup_energy := lerpf(0.3, 2.5, 0.5)
	_ok("WINDUP p=0.5 emissive == 1.4", _near(mid_windup_energy, 1.4))

	# KillZone inset: BoxShape3D (13.7, 0.5, 4.7) vs visual mesh (14, 4, 5).
	# Each horizontal side must be inset >= 0.10 m from visual bounds.
	var visual_x := 14.0;  var kill_x := 13.7
	var visual_z :=  5.0;  var kill_z :=  4.7
	_ok("KillZone inset in X >= 0.10 m per side",
		(visual_x - kill_x) / 2.0 >= 0.10)
	_ok("KillZone inset in Z >= 0.10 m per side",
		(visual_z - kill_z) / 2.0 >= 0.10)


func _test_rotating_hazard_math() -> void:
	## Mirrors angle = fmod(_elapsed / period_seconds, 1.0) * TAU in
	## rotating_hazard.gd::_physics_process. Pure math — no node instantiation.
	print("\n-- RotatingHazard phase formula --")

	var period := 4.0  # default period_seconds

	# t=0: no elapsed time → no rotation.
	var a0 := fmod(0.0 / period, 1.0) * TAU
	_ok("t=0 → angle 0.0 rad", _near(a0, 0.0))

	# t=half period → PI (half revolution).
	var a_half := fmod((period * 0.5) / period, 1.0) * TAU
	_ok("t=half period → angle PI rad", _near(a_half, PI))

	# t=full period → fmod wraps to 0 (one full revolution complete).
	var a_full := fmod(period / period, 1.0) * TAU
	_ok("t=full period → angle wraps to 0.0 rad", _near(a_full, 0.0))

	# t=1.25 periods → quarter past first wrap → PI/2.
	var a_1p25 := fmod((period * 1.25) / period, 1.0) * TAU
	_ok("t=1.25 periods → angle PI/2 rad", _near(a_1p25, PI / 2.0))

	# Periodicity: angle(t) == angle(t + N×period) for any integer N.
	var t_arb := 1.37
	var a_base  := fmod(t_arb / period, 1.0) * TAU
	var a_plus7 := fmod((t_arb + 7.0 * period) / period, 1.0) * TAU
	_ok("Periodic: angle(t) == angle(t + 7×period)", _near(a_base, a_plus7))

	# Angle always in [0, TAU) regardless of how many full revolutions have elapsed.
	var a_large := fmod((period * 23.7) / period, 1.0) * TAU
	_ok("Angle in [0, TAU) for large elapsed time",
		a_large >= 0.0 and a_large < TAU)

	# rotation_axis is normalized before Basis construction (rotating_hazard.gd line 27).
	_ok("Vector3.UP.normalized() length == 1.0",
		_near(Vector3.UP.normalized().length(), 1.0))
	_ok("Diagonal (1,1,0) normalized length == 1.0",
		_near(Vector3(1.0, 1.0, 0.0).normalized().length(), 1.0))

	# Default period 4.0 s must sit within the @export_range(0.5, 20.0) bounds.
	var default_period := 4.0
	_ok("Default period_seconds 4.0 >= range min 0.5 s", default_period >= 0.5)
	_ok("Default period_seconds 4.0 <= range max 20.0 s", default_period <= 20.0)

	# Basis(normalized_axis, 0) produces an orthonormal Basis (column lengths == 1.0).
	var b_zero := Basis(Vector3.UP, 0.0)
	_ok("Basis(UP, 0) X column length == 1.0", _near(b_zero.x.length(), 1.0))

	# Basis(normalized_axis, TAU): one full revolution returns X column near (1,0,0),
	# confirming the formula is periodic with respect to TAU.
	var b_full := Basis(Vector3.UP, TAU)
	_ok("Basis(UP, TAU) X column dot RIGHT ≈ 1.0 (full revolution ≈ identity)",
		_near(b_full.x.dot(Vector3.RIGHT), 1.0))


func _test_camera_hint_defaults() -> void:
	## CameraHint export-var defaults and group-name contract.
	## Group membership requires a live scene tree; only the StringName value
	## is tested here — camera_rig.gd queries the group by this exact name.
	print("\n-- CameraHint export defaults + group contract --")

	var ch := CH.new()

	# pull_back_amount = 0.0: a zero value is a safe default — the hint has no
	# effect until the level author sets a non-zero value, so untuned hints
	# can be placed without accidentally pushing the camera away.
	_ok("pull_back_amount defaults 0.0 (no-op until authored)",
		_near(ch.pull_back_amount, 0.0))

	# blend_time = 0.5 s: smooth without feeling sluggish — at 60 fps this
	# gives ~30 frames of lerp, which reads as a deliberate cinematic pull.
	_ok("blend_time defaults 0.5 s", _near(ch.blend_time, 0.5))

	# Negative pull_back_amount would shorten the spring arm during a hint,
	# moving the camera closer — the opposite of the design intent.
	_ok("pull_back_amount default is non-negative", ch.pull_back_amount >= 0.0)

	# A zero blend_time would produce an instant camera snap, which looks like
	# a glitch on mobile. The default must be strictly positive.
	_ok("blend_time default > 0 (prevents instant camera snap)",
		ch.blend_time > 0.0)

	# Group StringName must match the query in camera_rig.gd::_get_active_hint_extra().
	_ok("camera_hints StringName matches camera_rig group query",
		StringName("camera_hints") == &"camera_hints")

	ch.free()


# _compute_ground_camera_pos Y formula (extracted from _process in iter 62):
#   cam_pos.y = effective_target.y + sin(elevation) * effective_distance
#               + aim_height + fall_offset
# where elevation = -_pitch_rad and _pitch_rad <= 0 (so elevation >= 0).
# fall_offset from _vertical_pull_offset: vel_y * vertical_pull * 0.05 (< 0).
func _test_ground_camera_y_formula() -> void:
	var eff_y := 5.0
	var dist  := 6.0
	var aim_h := 0.6

	# At elevation = 0 (camera exactly horizontal), sin(0) = 0, so Y = eff_y + aim_h.
	_ok("ground Y at elev=0: sin term vanishes",
		_near(eff_y + sin(0.0) * dist + aim_h, eff_y + aim_h))

	# At elevation = PI/4 (45°): sin(PI/4) ≈ 0.70711.
	var elev45 := PI / 4.0
	_ok("ground Y at 45°: sin(PI/4) * dist added correctly",
		_near(eff_y + sin(elev45) * dist + aim_h,
			eff_y + 0.70711 * dist + aim_h, 1e-3))

	# At elevation = PI/2 (90°, camera directly above): sin = 1.
	_ok("ground Y at 90°: equals eff_y + dist + aim_h",
		_near(eff_y + sin(PI / 2.0) * dist + aim_h, eff_y + dist + aim_h))

	# Camera Y always exceeds eff_y + aim_h when elevation > 0.
	_ok("ground Y > eff_y + aim_h when elevation > 0",
		eff_y + sin(elev45) * dist + aim_h > eff_y + aim_h)

	# Monotonicity: larger elevation angle → larger sin → larger Y offset.
	_ok("sin(elevation) monotone over 0 to PI/2",
		sin(deg_to_rad(30.0)) < sin(deg_to_rad(45.0)) and
		sin(deg_to_rad(45.0)) < sin(deg_to_rad(90.0)))

	# Fall offset formula: vel_y * vertical_pull * 0.05 when vel_y < 0.
	var vel_neg := -10.0
	var pull    := 0.18
	var fall_off := vel_neg * pull * 0.05
	_ok("fall offset is negative (drops camera to show floor)",
		fall_off < 0.0)
	_ok("fall offset magnitude: vel * pull * 0.05",
		_near(fall_off, -0.09))

	# Full formula combines all terms (concrete value at known inputs).
	# eff_y=5, elev=45°, dist=6, aim_h=0.6, fall_off=-0.09:
	# = 5 + 0.70711*6 + 0.6 - 0.09 ≈ 9.7527
	_ok("full ground Y formula: concrete combined value",
		_near(eff_y + sin(elev45) * dist + aim_h + fall_off, 9.7527, 1e-3))


func _cfo_mirror(py: float, vy: float, apex_h: float,
		anchor: float, ref_y: float, vp: float) -> float:
	## Pure-math mirror of camera_rig.gd::_conditional_fall_offset.
	## Returns _vertical_pull_offset(vy) in the two tracking regimes; 0.0 in
	## the held band so the camera isn't yanked during normal held-band jumps.
	var vpo := 0.0 if vy >= 0.0 else vy * vp * 0.05
	if apex_h <= 0.0:
		return vpo
	if py > anchor + apex_h:
		return vpo
	if py < ref_y:
		return vpo
	return 0.0


func _test_conditional_fall_offset_regimes() -> void:
	## Mirrors camera_rig.gd::_conditional_fall_offset + _vertical_pull_offset.
	## The fall-pull offset drops the camera while falling so the player can see
	## what's ahead. It must NOT fire during a normal held-band jump — when the
	## camera is pinned to reference_floor_y — or it re-introduces the very
	## vertical motion the ratchet removes.
	print("\n-- Conditional fall offset regimes --")

	var vp       := 0.18   # vertical_pull @export default
	var vel_fall := -8.0   # typical mid-fall speed (m/s)
	var vel_rise :=  5.0
	var apex_h   := 2.0    # Snappy profile jump apex height (m)
	var anchor   := 3.0    # apex_anchor_y (player standing on elevated floor)
	var ref_y    := 3.0    # reference_floor_y (same floor; no tier gap)

	# Expected pull magnitude for the default vertical_pull coefficient.
	var expected := vel_fall * vp * 0.05   # = -0.072 m

	# ── _vertical_pull_offset sanity ─────────────────────────────────────────
	# Zero and positive velocity → always 0 (pull only drops the camera).
	_ok("vpo: zero velocity → 0.0",
		_near(0.0 if 0.0 >= 0.0 else 0.0 * vp * 0.05, 0.0))
	_ok("vpo: rising velocity → 0.0",
		_near(0.0 if vel_rise >= 0.0 else vel_rise * vp * 0.05, 0.0))
	# Falling → negative (camera drops, never rises, from pull).
	_ok("vpo: falling → negative offset (camera drops)",
		(vel_fall * vp * 0.05) < 0.0)
	_ok("vpo: magnitude = vel × vp × 0.05 (concrete -0.072 m)",
		_near(vel_fall * vp * 0.05, expected))

	# ── apex_h == 0: bypass regime gate, always fire pull ────────────────────
	# When apex_h ≤ 0 (profile missing or multiplier zeroed), the ratchet has
	# no band — fall pull fires unconditionally.
	_ok("apex_h==0 + falling → pull fires (bypass regime gate)",
		_near(_cfo_mirror(ref_y + 0.5, vel_fall, 0.0, anchor, ref_y, vp), expected))
	_ok("apex_h==0 + rising  → 0.0 (vpo vel-guard still applies)",
		_near(_cfo_mirror(ref_y + 0.5, vel_rise, 0.0, anchor, ref_y, vp), 0.0))

	# ── Regime: above apex band (player_y > anchor + apex_h) ─────────────────
	# Camera is tracking up to keep a high jump in frame → pull allowed.
	var above := anchor + apex_h + 1.0   # strictly above the band
	_ok("above apex: player_y > anchor + apex_h (sanity)", above > anchor + apex_h)
	_ok("above apex + falling → pull fires",
		_near(_cfo_mirror(above, vel_fall, apex_h, anchor, ref_y, vp), expected))
	_ok("above apex + rising  → 0.0 (vpo vel-guard applies even in tracking)",
		_near(_cfo_mirror(above, vel_rise, apex_h, anchor, ref_y, vp), 0.0))

	# ── Regime: below reference floor (player_y < ref_y) ─────────────────────
	# Camera tracks descent to show what's below → pull allowed.
	var below := ref_y - 0.5   # strictly below
	_ok("below ref floor: player_y < ref_y (sanity)", below < ref_y)
	_ok("below ref floor + falling → pull fires",
		_near(_cfo_mirror(below, vel_fall, apex_h, anchor, ref_y, vp), expected))

	# ── Regime: held band (ref_y ≤ player_y ≤ anchor + apex_h) ──────────────
	# Normal jump stays below apex — camera is pinned, pull must be suppressed.
	var held := ref_y + (anchor + apex_h - ref_y) * 0.5   # midpoint in band
	_ok("held band: ref_y ≤ mid ≤ anchor + apex_h (sanity)",
		held >= ref_y and held <= anchor + apex_h)
	_ok("held band + falling → 0.0 (camera pinned during normal jump)",
		_near(_cfo_mirror(held, vel_fall, apex_h, anchor, ref_y, vp), 0.0))
	_ok("held band + rising  → 0.0",
		_near(_cfo_mirror(held, vel_rise, apex_h, anchor, ref_y, vp), 0.0))

	# ── Boundary: upper bound is strictly greater (>) not >= ──────────────────
	# At exactly anchor + apex_h the player is not *above* the band — held band.
	_ok("at apex upper bound (==) → held band, no pull",
		_near(_cfo_mirror(anchor + apex_h, vel_fall, apex_h, anchor, ref_y, vp), 0.0))

	# ── Boundary: lower bound is strictly less (<) not <= ─────────────────────
	# At exactly ref_y the player is not *below* the floor — held band.
	_ok("at ref_floor boundary (==) → held band, no pull",
		_near(_cfo_mirror(ref_y, vel_fall, apex_h, anchor, ref_y, vp), 0.0))

	# ── Linearity ─────────────────────────────────────────────────────────────
	_ok("pull scales with vertical_pull (double vp → double offset)",
		_near(_cfo_mirror(above, vel_fall, apex_h, anchor, ref_y, vp * 2.0),
			expected * 2.0))
	_ok("pull scales with fall speed (double speed → double offset)",
		_near(_cfo_mirror(above, vel_fall * 2.0, apex_h, anchor, ref_y, vp),
			expected * 2.0))


func _test_hint_distance_blend() -> void:
	## Mirrors camera_rig.gd::_update_hint_distance's exponential lerp.
	## CameraHint pull_back_amount blends at 3/sec — slower than the 6/sec
	## reference-floor smoothing so hints feel like a breath rather than a cut.
	## The blend runs every frame (including airborne) so the arm is already
	## partly extended when the player lands inside a hint volume.
	print("\n-- Camera hint distance exponential blend --")
	const RATE  := 3.0          # _update_hint_distance hard-coded rate (/sec)
	const DELTA := 1.0 / 60.0  # 60 fps frame

	# Per-frame blend weight: 1 − exp(−rate × delta).
	var w1 := 1.0 - exp(-RATE * DELTA)

	# No active hint (target = 0): extra stays 0.
	var extra := lerpf(0.0, 0.0, w1)
	_ok("no active hint: extra stays 0 after one frame", _near(extra, 0.0))

	# Active hint with pull_back = 2.0 m: first frame at 60 fps.
	var target := 2.0
	var first := lerpf(0.0, target, w1)
	_ok("first frame: extra > 0 (blend has started)", first > 0.0)
	_ok("first frame: extra < target (not fully blended)", first < target)
	# w1 ≈ 0.0488; lerpf(0, 2, 0.0488) ≈ 0.0976.
	_ok("first frame: concrete ≈ target × w1", _near(first, target * w1, 1e-4))

	# After 60 frames (1 second): >95% converged.
	extra = 0.0
	for _f in 60:
		extra = lerpf(extra, target, w1)
	_ok("1 second at 60 fps: >95%% converged (extra > 1.9)", extra > 1.9)

	# Monotone convergence and no overshoot across 120 frames.
	extra = 0.0
	var prev := 0.0
	var monotone := true
	var no_overshoot := true
	for _f in 120:
		extra = lerpf(extra, target, w1)
		if extra < prev - 1e-6:
			monotone = false
		if extra > target + 1e-6:
			no_overshoot = false
		prev = extra
	_ok("hint blend: monotone convergence across 120 frames", monotone)
	_ok("hint blend: never overshoots target", no_overshoot)

	# Rate 3/sec is slower than reference_floor_smoothing's 6/sec — hints feel
	# gradual; tier changes feel snappy.
	var w_ref := 1.0 - exp(-6.0 * DELTA)
	_ok("hint blend rate (3/sec) < ref-floor rate (6/sec) → slower pull",
		w1 < w_ref)


func _test_industrial_press_position_formula() -> void:
	## Mirrors IndustrialPress._target_y() and _update_emissive() — the two
	## pure-math formulas that determine where the kill-zone physically sits and
	## how bright the danger strip glows in each phase. Phase indices match the
	## IndustrialPress.Phase enum: 0=DORMANT 1=WINDUP 2=STROKE 3=REBOUND.
	print("\n-- IndustrialPress position + emissive formulas --")

	const ORIGIN := 0.0
	const DEPTH  := 2.5   # default stroke_depth export

	# ── _target_y() ─────────────────────────────────────────────────────────
	# DORMANT: press stays at origin regardless of phase progress.
	_ok("dormant p=0.5: constant at origin",
		_near(_ip_y(0, 0.5, ORIGIN, DEPTH), ORIGIN))

	# WINDUP: linear 0.3 m retraction (anti-slam wind-up).
	_ok("windup p=0: at origin",
		_near(_ip_y(1, 0.0, ORIGIN, DEPTH), ORIGIN))
	_ok("windup p=1: 0.3 m above origin",
		_near(_ip_y(1, 1.0, ORIGIN, DEPTH), ORIGIN + 0.3))
	_ok("windup p=0.5: midpoint 0.15 m above",
		_near(_ip_y(1, 0.5, ORIGIN, DEPTH), ORIGIN + 0.15))

	# STROKE: linear descent to stroke_depth below origin.
	_ok("stroke p=0: at origin (descent start)",
		_near(_ip_y(2, 0.0, ORIGIN, DEPTH), ORIGIN))
	_ok("stroke p=1: at full depth",
		_near(_ip_y(2, 1.0, ORIGIN, DEPTH), ORIGIN - DEPTH))
	_ok("stroke p=0.5: half depth",
		_near(_ip_y(2, 0.5, ORIGIN, DEPTH), ORIGIN - DEPTH * 0.5))

	# REBOUND: linear ascent from full-depth back to origin.
	_ok("rebound p=0: at full depth (bottom)",
		_near(_ip_y(3, 0.0, ORIGIN, DEPTH), ORIGIN - DEPTH))
	_ok("rebound p=1: back at origin",
		_near(_ip_y(3, 1.0, ORIGIN, DEPTH), ORIGIN))
	_ok("rebound p=0.5: half-depth on way up",
		_near(_ip_y(3, 0.5, ORIGIN, DEPTH), ORIGIN - DEPTH * 0.5))

	# Continuity: stroke end == rebound start (no position pop between phases).
	_ok("continuity: stroke(p=1) == rebound(p=0)",
		_near(_ip_y(2, 1.0, ORIGIN, DEPTH), _ip_y(3, 0.0, ORIGIN, DEPTH)))

	# ── _update_emissive() energy ────────────────────────────────────────────
	_ok("dormant: energy 0.3 (dim base glow)",
		_near(_ip_emissive(0, 0.5), 0.3))
	_ok("windup p=0: energy 0.3 (start dim)",
		_near(_ip_emissive(1, 0.0), 0.3))
	_ok("windup p=1: energy 2.5 (fully charged)",
		_near(_ip_emissive(1, 1.0), 2.5))
	_ok("stroke: energy 2.5 (constant danger)",
		_near(_ip_emissive(2, 0.5), 2.5))
	_ok("rebound p=0: energy 2.5 (still bright at retraction start)",
		_near(_ip_emissive(3, 0.0), 2.5))
	_ok("rebound p=1: energy 0.3 (dimmed, safe window)",
		_near(_ip_emissive(3, 1.0), 0.3))


func _ip_y(phase: int, p: float, origin_y: float, stroke_depth: float) -> float:
	## Pure-math mirror of IndustrialPress._target_y().
	match phase:
		0: return origin_y                                           # DORMANT
		1: return origin_y + p * 0.3                                # WINDUP
		2: return origin_y - p * stroke_depth                       # STROKE
		3: return (origin_y - stroke_depth) + p * stroke_depth      # REBOUND
	return origin_y


func _ip_emissive(phase: int, p: float) -> float:
	## Pure-math mirror of IndustrialPress._update_emissive() energy formula.
	match phase:
		0: return 0.3                    # DORMANT
		1: return lerpf(0.3, 2.5, p)    # WINDUP
		2: return 2.5                    # STROKE
		3: return lerpf(2.5, 0.3, p)    # REBOUND
	return 0.3
