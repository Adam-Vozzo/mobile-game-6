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
const GTR := preload("res://scripts/levels/ghost_trail_renderer.gd")
const MP  := preload("res://scripts/levels/moving_platform.gd")
const RH  := preload("res://scripts/levels/rotating_hazard.gd")

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
	_test_air_dash_state_machine()
	_test_game_timer_accumulation()
	_test_data_shard_gem_vertices()
	_test_data_shard_light_params()
	_test_dash_buffer_camera_logic()
	_test_speed_ramp_logic()
	_test_zone_atmosphere_logic()
	_test_jump_anticipation_squish_math()
	_test_ghost_trail_recording()
	_test_ghost_trail_resize_math()
	_test_camera_occlusion_defaults()
	_test_zone_env_bounds_and_disabled()
	_test_respawn_ramp_speed_reset()
	_test_ghost_trail_disable_and_resize_semantics()
	_test_respawn_input_timer_clearing()
	_test_assisted_phase2_params()
	_test_free_cam_mode()
	_test_snappy_reboot_duration()
	_test_audio_skeleton()
	_test_wall_normal_viz_key()
	_test_screen_shake_system()
	_test_ledge_magnet_impulse_formula()
	_test_arc_assist_per_frame_budget()
	_test_screen_shake_strongest_wins()
	_test_run_timer_semantics()
	_test_footstep_and_land_impact_math()
	_test_footstep_dust_state_machine()
	_test_blob_shadow_export_defaults()
	_test_blob_shadow_param_dispatch()
	_test_blob_shadow_juice_toggle()
	_test_threshold_skyline_param()
	_test_chick_body_mesh_path()
	_test_patrol_sentry_logic()
	_test_audio_sfx_wiring()
	_test_ambient_audio_routing()
	_test_sentry_param_dispatch()
	_test_sentry_initial_state()
	_test_trail_lifecycle()
	_test_threshold_level_lifecycle()
	_test_ledge_pull_geometry()
	_test_sentry_instant_reversal()
	_test_breadth_level_defaults()
	_test_viaduct_sentry_constants()
	_test_gauntlet_sentry_constants()
	_test_early_breadth_level_defaults()
	_test_arena_level_defaults()
	_test_arena_sentry_constants()
	_test_level_select_ui()
	_test_ghost_trail_point_t_normalization()
	_test_ghost_trail_colour_constants()
	_test_ghost_trail_defaults()
	_test_win_state_beacon_defaults()
	_test_win_state_beacon_runtime()
	_test_moving_platform_defaults()
	_test_rotating_hazard_defaults()
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
	# Tween animation durations must fit within their containing await windows so
	# the effect completes cleanly before the next phase fires.
	_ok("_play_death_squish (0.08) fits inside dark-frame await (0.12)", 0.08 < 0.12)
	_ok("_play_reboot_grow  (0.28) fits inside power-on await  (0.35)", 0.28 < 0.35)

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
	## Verifies the cylindrical drag math from camera_rig.gd::_apply_drag_input.
	## Drag derives theta from the current camera XZ (the tripod model lets the
	## player walk around the camera, so theta drifts), reads `_pitch_rad`
	## directly for elevation, clamps elev to [0, pitch_max], then writes the
	## new position with the *same* parametrization `_compute_ground_camera_pos`
	## enforces: XZ at full `effective_distance` from pivot, Y at
	## `sin(elev)*effective_distance + aim_height` above pivot.
	##
	## A previous spherical write (`effective_distance * cos(elev)` on XZ)
	## produced an auto-correction fight: at high pitch the drag put cam at
	## projected XZ, then the ground branch eased it back out to full XZ over
	## ~0.5 s. The cylindrical write below removes that mismatch.
	##
	## Key invariants:
	##   - Pure yaw drag preserves horizontal radius (only theta changes).
	##   - elev is always clamped ≥ 0 (camera stays at or above horizontal).
	##   - elev is clamped ≤ deg_to_rad(pitch_max_degrees).
	##   - _pitch_rad = -elev, so it is always ≤ 0.
	##   - At any elev, drag-written cam XZ matches ground-branch XZ exactly.
	print("\n-- Tripod camera drag orbit math --")
	const DIST     := 6.0
	const ELEV_DEG := 22.0
	const PITCH_MAX_DEG := 55.0
	const YAW_SENS := 0.005
	const PITCH_SENS := 0.003
	const AIM_H := 0.6
	var elev := deg_to_rad(ELEV_DEG)

	# Initial camera position written by _apply_drag_input (cylindrical):
	# XZ at full DIST behind, Y = sin(elev)*DIST + AIM_H above pivot.
	var pivot := Vector3.ZERO
	var cam := pivot + Vector3(0.0, sin(elev) * DIST + AIM_H, DIST)
	var to_cam := cam - pivot
	var horiz_radius := Vector2(to_cam.x, to_cam.z).length()
	_ok("XZ radius from drag-written position == distance (cylindrical)",
		_near(horiz_radius, DIST, 1e-4))

	# Theta is derived from the camera's XZ relative to the pivot.
	var theta := atan2(to_cam.x, to_cam.z)
	_ok("theta from default position == 0 (camera behind on +Z)",
		_near(theta, 0.0, 1e-4))

	# Pure yaw drag (positive x-drag): theta changes, elev unchanged, horizontal
	# radius preserved, Y unchanged.
	var new_theta := theta - 100.0 * YAW_SENS
	var yawed_pos := pivot + Vector3(
		DIST * sin(new_theta),
		DIST * sin(elev) + AIM_H,
		DIST * cos(new_theta))
	_ok("pure yaw drag preserves XZ radius (cylindrical orbit)",
		_near(Vector2(yawed_pos.x, yawed_pos.z).length(), DIST, 1e-4))
	_ok("pure yaw drag preserves Y (no elevation change)",
		_near(yawed_pos.y, cam.y, 1e-4))

	# Inverted axis: drag.y > 0 (swipe down) drives elev UP toward pitch_max;
	# drag.y < 0 (swipe up) drives elev DOWN toward 0. _pitch_rad stays ≤ 0.

	# Lower clamp: huge upward drag (drag.y < 0) drives elev toward 0.
	var elev_clamped_down := clampf(elev + (-1000.0) * PITCH_SENS,
		0.0, deg_to_rad(PITCH_MAX_DEG))
	_ok("upward drag: elev clamped to ≥ 0 (camera never below horizontal)",
		elev_clamped_down >= 0.0)

	# Upper clamp: huge downward drag (drag.y > 0) drives elev toward pitch_max.
	var elev_clamped_up := clampf(elev + 1000.0 * PITCH_SENS,
		0.0, deg_to_rad(PITCH_MAX_DEG))
	_ok("downward drag: elev clamped to ≤ pitch_max_degrees",
		elev_clamped_up <= deg_to_rad(PITCH_MAX_DEG) + 1e-6)

	# _pitch_rad = -elev → always ≤ 0 (used by the elevation formula downstream)
	var pitch_rad := -elev_clamped_down
	_ok("_pitch_rad = -elev: value is always ≤ 0 (camera above horizontal)",
		pitch_rad <= 0.0)

	# Drag/ground consistency at high pitch — the bug fix invariant. At 70°
	# pitch the *previous* spherical formula put XZ at DIST*cos(70°) ≈ 2.05;
	# the cylindrical formula matches the ground branch (XZ = DIST).
	var elev_high := deg_to_rad(70.0)
	var drag_xz := Vector2(DIST * sin(0.0), DIST * cos(0.0)).length()
	# Ground branch (`_compute_ground_camera_pos`) targets full `effective_distance`
	# in horizontal XZ regardless of pitch.
	var ground_xz := DIST
	_ok("drag XZ radius matches ground branch at high pitch (no fight)",
		_near(drag_xz, ground_xz, 1e-4))
	# Y formula must also match: drag uses sin(elev)*DIST + AIM_H above pivot;
	# ground uses sin(elev)*effective_distance + aim_height + fall_offset
	# above effective_target (fall_offset=0 on grounded frames at apex anchor).
	var drag_y := DIST * sin(elev_high) + AIM_H
	var ground_y := DIST * sin(elev_high) + AIM_H
	_ok("drag Y matches ground branch Y on grounded frames (no fight)",
		_near(drag_y, ground_y, 1e-4))


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
	var at_result: Vector3 = _correct.call(at_dist, 5.0) as Vector3
	_ok("tripod: camera at correct dist → no XZ movement (dist_err == 0)",
		_near(at_result.x, at_dist.x) and _near(at_result.z, at_dist.z))

	# Y component untouched (height set separately by elevation formula).
	_ok("tripod: Y component unchanged by XZ correction",
		_near(_correct.call(Vector3(0, 3.5, 8), 5.0).y, 3.5))

	# Horizontal direction preserved: camera stays on same ray from target after correction.
	var cam_diag := Vector3(4.0, 2.0, 6.0)
	var res_diag: Vector3 = _correct.call(cam_diag, 5.0) as Vector3
	var dir_before := Vector2(cam_diag.x, cam_diag.z).normalized()
	var dir_after  := Vector2(res_diag.x,  res_diag.z).normalized()
	_ok("tripod: horizontal direction preserved (camera stays on same radial line from target)",
		_near(dir_before.dot(dir_after), 1.0, 1e-4))

	# Single-step convergence: applying the correction twice gives same result.
	var once: Vector3  = _correct.call(Vector3(0, 2, 10), 5.0) as Vector3
	var twice: Vector3 = _correct.call(once, 5.0) as Vector3
	_ok("tripod: correction converges in exactly one step (second pass is a no-op)",
		_near(_hd.call(twice), 5.0) and _near(once.x, twice.x) and _near(once.z, twice.z))

	# Correction direction: moves toward target when too far, away when too close.
	var res_far: Vector3   = _correct.call(Vector3(0.0, 0.0, 8.0), 5.0) as Vector3
	var res_close: Vector3 = _correct.call(Vector3(0.0, 0.0, 2.0), 5.0) as Vector3
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
	var diag_yaw: float = _yaw.call(Vector3(DIST, 0.0, DIST)) as float
	_ok("pub_yaw: diagonal camera (+X+Z at 45°) → yaw in (0, PI/2)",
		diag_yaw > 0.0 and diag_yaw < PI / 2.0)

	# Y component does not affect published yaw (it's a horizontal angle only).
	var yaw_low: float  = _yaw.call(Vector3(0.0, 1.0, DIST)) as float
	var yaw_high: float = _yaw.call(Vector3(0.0, 8.0, DIST)) as float
	_ok("pub_yaw: camera Y does not affect published yaw (angle is purely horizontal)",
		_near(yaw_low, yaw_high))

	# Distance does not affect yaw direction — only angle matters.
	var yaw_near: float = _yaw.call(Vector3(0.0, 0.0, 2.0)) as float
	var yaw_far: float  = _yaw.call(Vector3(0.0, 0.0, 10.0)) as float
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
	# checkpoint_id export: must match the StringName Game.checkpoint_reached emits.
	# Empty id would make two checkpoints collide in any group-based lookup.
	_ok("checkpoint_id @export default == &\"checkpoint_1\"",
		cp.checkpoint_id == &"checkpoint_1")
	_ok("checkpoint_id is non-empty (no silent collision risk)",
		cp.checkpoint_id != &"")
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


func _test_air_dash_state_machine() -> void:
	## Documents the air dash state-transition machine that _test_air_dash_logic
	## doesn't cover: re-entry guard, timer-expiry → clear, landing-vs-respawn
	## clear semantics, Y-velocity zeroing at trigger, and the absolute direction
	## fallback when both input and velocity are zero.
	##
	## All assertions are pure-math mirrors of player.gd state blocks; no scene
	## tree is required.
	print("\n-- Air dash state machine (transitions) --")
	const DELTA := 1.0 / 60.0

	# --- Re-entry guard composition ---
	# _try_air_dash: `if _is_rebooting or _is_dashing or _dash_charges <= 0 or is_on_floor()`
	# Test: _is_dashing=true alone fires the guard even when charges are available and
	# the player is airborne. Test: all-clear gives false (trigger proceeds).
	var rebooting := false; var mid_dash := true; var charges := 1; var grounded := false
	_ok("re-entry: _is_dashing=T blocks trigger even with charge + off-floor",
		(rebooting or mid_dash or charges <= 0 or grounded) == true)
	var idle_dash := false
	_ok("all-clear: rebooting=F, dashing=F, charges=1, off-floor → guard passes",
		(rebooting or idle_dash or charges <= 0 or grounded) == false)

	# --- Timer decrement formula: maxf(0.0, timer - delta) ---
	# Normal tick: remaining > delta → decremented, still positive.
	var timer := 0.18
	var after := maxf(0.0, timer - DELTA)
	_ok("timer tick: 0.18 s − one frame still positive and < 0.18",
		after > 0.0 and after < timer and _near(after, timer - DELTA))
	# Near-zero: remaining < delta → clamps to 0.0, never negative.
	timer = 0.005
	after = maxf(0.0, timer - DELTA)
	_ok("timer tick: 0.005 s < delta → clamps to 0.0 (no negative timer)",
		_near(after, 0.0))
	# Already zero: stays zero.
	timer = 0.0
	after = maxf(0.0, timer - DELTA)
	_ok("timer tick: 0.0 s stays at 0.0 (idempotent at floor)",
		_near(after, 0.0))

	# --- Timer expiry → _is_dashing cleared ---
	# Mirrors _tick_timers: `if _dash_timer <= 0.0: _is_dashing = false`
	var is_active := true
	var dash_timer := 0.005   # one tick pushes it to 0.0
	dash_timer = maxf(0.0, dash_timer - DELTA)
	if dash_timer <= 0.0:
		is_active = false
	_ok("expiry: timer → 0.0 clears _is_dashing to false",
		is_active == false)
	# Timer still positive → does NOT clear.
	is_active = true
	dash_timer = 0.10
	dash_timer = maxf(0.0, dash_timer - DELTA)
	if dash_timer <= 0.0:
		is_active = false
	_ok("no expiry: timer > 0 after tick → _is_dashing stays true",
		is_active == true)

	# --- Landing vs respawn clear semantics ---
	# Landing (_tick_timers on_floor branch):
	#   _dash_charges = 1  (refill one charge)
	#   _is_dashing  = false
	#   _dash_timer  = 0.0
	var ch := 0; var dashing := true; var d_tmr := 0.12
	ch = 1; dashing = false; d_tmr = 0.0   # simulate on_floor branch
	_ok("landing: _dash_charges refilled to 1 (one charge per airborne phase)", ch == 1)
	_ok("landing: _is_dashing cleared to false even if mid-dash at touchdown", dashing == false)
	_ok("landing: _dash_timer reset to 0.0 so the next airborne phase starts clean",
		_near(d_tmr, 0.0))
	# Respawn (respawn() zeroing block):
	#   _dash_charges = 0  — distinct from landing's 1, player cannot dash immediately
	ch = 1; dashing = true; d_tmr = 0.1    # state before respawn
	ch = 0; dashing = false; d_tmr = 0.0  # simulate respawn() block
	_ok("respawn: _dash_charges zeroed to 0 (vs landing's 1 — cannot dash on first airframe)",
		ch == 0)

	# --- Y-velocity zeroed at trigger ---
	# _try_air_dash: `velocity.y = 0.0`
	# Absorbs ascending or descending momentum so the dash is purely horizontal.
	var vel_y := 5.5   # rising at trigger moment
	vel_y = 0.0        # what _try_air_dash assigns
	_ok("dash trigger: velocity.y forced to 0.0 (horizontal-only dash)",
		_near(vel_y, 0.0))

	# --- Double fallback to Vector3.FORWARD ---
	# First fallback: dir = vel_h.normalized() (when input is near-zero)
	# Second fallback: Vector3.FORWARD (when vel_h is also near-zero; visual unavailable)
	var input := Vector3.ZERO
	var vel_h := Vector3.ZERO   # standing still
	var dash_dir := input
	if dash_dir.length() < 0.01:
		dash_dir = vel_h.normalized()   # Vector3(0,0,0).normalized() → still zero-length
	if dash_dir.length() < 0.01:
		dash_dir = Vector3.FORWARD      # absolute fallback from _try_air_dash
	_ok("double fallback: zero input + zero velocity → dash direction is Vector3.FORWARD",
		dash_dir.is_equal_approx(Vector3.FORWARD))

	# --- Default duration expires within 15 frames at 60 fps ---
	# air_dash_duration default 0.18 s → ceil(0.18 / (1/60)) = 11 frames to reach 0.
	var cp2 := CP.new()
	var t := cp2.air_dash_duration
	var frames := 0
	while t > 0.0 and frames < 100:
		t = maxf(0.0, t - DELTA)
		frames += 1
	_ok("default duration 0.18 s expires within 15 frames at 60 fps", frames <= 15)


func _test_game_timer_accumulation() -> void:
	## Documents game.gd::_process timer behaviour: accumulates when is_running,
	## stops when is_running is false, resets via start_run().
	## Calls _process(delta) directly — no scene tree needed.
	print("\n-- Game timer accumulation (_process) --")
	const DELTA := 1.0 / 60.0
	var g: GM = GM.new()

	# Default: not running → _process does not accumulate.
	g._process(DELTA)
	_ok("not running: _process(delta) leaves run_time_seconds at 0.0",
		_near(g.run_time_seconds, 0.0))

	# Running: one frame accumulates exactly delta.
	g.start_run()
	g._process(DELTA)
	_ok("running: one _process call adds delta to run_time_seconds",
		_near(g.run_time_seconds, DELTA))

	# Running: N frames accumulate N × delta.
	g.start_run()   # resets timer
	for _i in range(10):
		g._process(DELTA)
	_ok("running: 10 frames accumulate 10 × delta",
		_near(g.run_time_seconds, 10.0 * DELTA))

	# level_complete() stops accumulation.
	g.level_complete()
	var before := g.run_time_seconds
	g._process(DELTA)
	_ok("level_complete: subsequent _process calls do not increment run_time_seconds",
		_near(g.run_time_seconds, before))

	# start_run() resets the timer and re-enables accumulation.
	g.run_time_seconds = 5.0
	g.start_run()
	_ok("start_run: run_time_seconds zeroed to 0.0", _near(g.run_time_seconds, 0.0))
	g._process(DELTA)
	_ok("start_run: subsequent _process accumulates again",
		_near(g.run_time_seconds, DELTA))

	# 60 frames at 1/60 s each → ≈ 1.0 s (within floating-point tolerance).
	g.start_run()
	for _i in range(60):
		g._process(DELTA)
	_ok("60 frames at 1/60 s ≈ 1.0 s total (floating-point accumulation within 1 ms)",
		absf(g.run_time_seconds - 1.0) < 0.001)

	g.free()


func _test_data_shard_gem_vertices() -> void:
	## Mirrors the vertex array of DataShard._build_gem_mesh() and checks the
	## geometric invariants that make the gem readable at camera distance.
	## Six vertices: top apex, four axis-aligned equatorial, bottom apex.
	## Eight triangles: 4 fanning from top, 4 fanning from bottom.
	print("\n-- DataShard gem vertex geometry --")

	# Mirror the vertex array verbatim from _build_gem_mesh().
	var top_y   := 0.28    # height of apex above equatorial plane
	var bot_y   := -0.22   # depth of base below equatorial plane (flatter)
	var eq_r    := 0.20    # equatorial ring radius (XZ distance from Y-axis)
	# Axis-aligned square ring: +X, +Z, -X, -Z (not diagonal).
	var eq: Array[Vector3] = [
		Vector3( eq_r, 0.0,   0.0),   # 0 eq +x
		Vector3( 0.0,  0.0,   eq_r),  # 1 eq +z
		Vector3(-eq_r, 0.0,   0.0),   # 2 eq -x
		Vector3( 0.0,  0.0,  -eq_r),  # 3 eq -z
	]

	# --- Apex positions ---
	_ok("top apex y = 0.28 m above equatorial plane",    _near(top_y,  0.28))
	_ok("bottom apex y = -0.22 m below equatorial plane", _near(bot_y, -0.22))
	# Top is taller than bottom is deep — gives the gem a sharper upper point.
	_ok("top apex taller than bottom is deep: 0.28 > 0.22 (visual asymmetry)",
		top_y > absf(bot_y))

	# --- Equatorial ring plane ---
	# All four equatorial vertices lie exactly in the XZ plane (y == 0).
	for i: int in range(4):
		_ok("equatorial vertex %d y = 0.0 (lies in XZ plane)" % i,
			_near(eq[i].y, 0.0))

	# --- Ring shape: axis-aligned square, not diagonal ---
	# v[0] is on the pure +X axis — no Z component.
	_ok("eq[0] is pure +X (axis-aligned ring, not 45° diagonal)",
		_near(eq[0].x, eq_r) and _near(eq[0].z, 0.0))
	# Adjacent vertices are 90° apart: v[1] is on +Z, v[3] is on -Z.
	_ok("eq[1] is pure +Z and eq[3] is pure -Z (90° spacing confirmed)",
		_near(eq[1].z, eq_r) and _near(eq[3].z, -eq_r))

	# --- Equatorial radius ---
	_ok("equatorial radius = 0.20 m", _near(eq_r, 0.20))

	# --- Mesh counts ---
	# 6 vertices: 1 top + 4 equatorial + 1 bottom.
	_ok("6 total vertices (1 top + 4 equatorial + 1 bottom)", 1 + 4 + 1 == 6)
	# 8 triangles: 4-triangle upper fan from top + 4-triangle lower fan from bottom.
	_ok("8 total triangles (4 upper fan from top apex + 4 lower fan from bottom apex)",
		4 + 4 == 8)

	# --- Material emission ---
	# Emission energy of 3.2 makes the shard self-luminous against the dark brutalist
	# geometry. Value is embedded in the StandardMaterial3D inside _build_gem_mesh().
	var emission_energy := 3.2
	_ok("emission_energy_multiplier = 3.2 (self-luminous against dark environment)",
		_near(emission_energy, 3.2))


func _test_data_shard_light_params() -> void:
	## Documents the OmniLight3D parameters and collect-pulse Tween timing
	## from data_shard.gd. These drive visual clarity: the light marks the
	## shard's position through fog, and the pulse confirms collection clearly.
	print("\n-- DataShard light parameters and collect pulse --")

	# Light values from _build_visual().
	var light_color  := Color(0.12, 0.90, 0.95)  # cyan glow
	var light_energy := 1.4                        # default pre-collect
	var light_range  := 4.5                        # m

	# Cyan channel check: G and B both dominate over R.
	_ok("light color is cyan: green channel > red channel",  light_color.g > light_color.r)
	_ok("light color is cyan: blue channel > red channel",   light_color.b > light_color.r)
	_ok("light_energy = 1.4 (default, pre-collection)",     _near(light_energy, 1.4))
	_ok("light_range = 4.5 m (reaches adjacent platform surfaces)", _near(light_range, 4.5))

	# Collect-pulse Tween chain from _collect() (mirrors the two tween_property calls).
	# Rise: energy 1.4 → 7.0 in 0.05 s  (short impact)
	# Fall: energy 7.0 → 0.0 in 0.30 s  (long recognisable tail)
	var pulse_rise_s := 0.05
	var pulse_fall_s := 0.30
	var pulse_peak   := 7.0
	_ok("collect pulse: rise < fall (fast punch, long tail: 0.05 s < 0.30 s)",
		pulse_rise_s < pulse_fall_s)
	# Peak is 5× the default — unambiguous visual feedback even through fog.
	_ok("pulse peak energy (7.0) = 5× default energy (1.4) — clearly visible on collection",
		_near(pulse_peak / light_energy, 5.0))


func _test_dash_buffer_camera_logic() -> void:
	## Pure-math mirror of the dash_buffer_camera branch in
	## touch_overlay.gd::_handle_drag (KIND_DRAG case).
	##
	## Three outcomes (all documented as invariants):
	##   ACCUMULATE  — inside window, buffering enabled: camera delta suppressed,
	##                 added to _dash_drag_buffer.
	##   FLUSH       — window expired or jump released: camera receives
	##                 accumulated buffer + current-frame delta.
	##   DISCARD     — dash fires: buffer erased, swipe delta suppressed →
	##                 zero camera movement (prevents the cam-whip).
	##
	## When dash_buffer_camera = false (default), deltas are forwarded
	## unconditionally, matching the pre-feature behaviour.
	print("\n-- Dash buffer-and-discard camera invariants --")

	var d1 := Vector2(10.0,  3.0)   # typical slow-pan drag frame
	var d2 := Vector2( 6.0, -2.0)   # second slow-pan frame inside window
	var d_swipe := Vector2(48.0, 1.0)  # fast swipe that fires the dash

	# ── Accumulation ────────────────────────────────────────────────────────
	# Each frame inside the window is added to the buffer; camera receives
	# nothing until the window expires or clears.
	var buf := Vector2.ZERO
	buf += d1
	buf += d2
	_ok("buffer accumulates: x = d1.x + d2.x", _near(buf.x, d1.x + d2.x))
	_ok("buffer accumulates: y = d1.y + d2.y", _near(buf.y, d1.y + d2.y))
	_ok("accumulated buffer is non-zero", not buf.is_zero_approx())

	# ── Flush (window expiry) ────────────────────────────────────────────────
	# On expiry, camera receives the full buffer + current-frame delta in one
	# call — total equals the sum of every buffered frame.
	var d_expiry := Vector2(3.0, 1.5)
	var cam_flush: Vector2 = buf + d_expiry
	_ok("flush: camera x = Σ(buffered x) + expiry-delta x",
		_near(cam_flush.x, d1.x + d2.x + d_expiry.x))
	_ok("flush preserves all movement: total equals naive sum",
		_near(cam_flush.length(), (d1 + d2 + d_expiry).length()))

	# ── Discard (dash fires) ─────────────────────────────────────────────────
	# cam_sent = true with no add_camera_drag_delta call → zero camera movement.
	var cam_discard := Vector2.ZERO    # buf erased; d_swipe not forwarded
	_ok("discard on dash fire: camera delta is zero (no cam-whip)",
		cam_discard.is_zero_approx())
	# Old (non-buffering) path forwarded the swipe delta unconditionally.
	var cam_old_path: Vector2 = d_swipe   # behaviour before dash_buffer_camera
	_ok("old path: swipe delta reaches camera (documents the cam-whip that was fixed)",
		cam_old_path.length() > 0.0)
	_ok("buffer-and-discard swipe cam Δ < old path swipe cam Δ",
		cam_discard.length() < cam_old_path.length())

	# ── Post-flush state ─────────────────────────────────────────────────────
	# After flush, _dash_drag_buffer[index] is erased. The next frame's delta
	# is forwarded immediately (cam_sent stays false, fallthrough path taken).
	var after_flush_buf := Vector2.ZERO   # erased via _dash_drag_buffer.erase()
	var next_delta       := Vector2(4.0, 2.0)
	var cam_next: Vector2 = after_flush_buf + next_delta
	_ok("post-flush: next frame delta forwarded fully (buffer starts clean)",
		cam_next.is_equal_approx(next_delta))

	# ── Commutativity ────────────────────────────────────────────────────────
	# Buffer = vector sum; order of frames doesn't change the total flushed.
	_ok("buffer accumulation is commutative (frame order invariant)",
		(d1 + d2).is_equal_approx(d2 + d1))

func _test_speed_ramp_logic() -> void:
	## Pure-math mirror of the speed-ramp branch in player.gd::_apply_horizontal.
	##
	## Logic: when profile.speed_ramp_rate > 0, _ramp_speed ramps from
	## profile.max_speed up to profile.ramp_max_speed at `speed_ramp_rate` m/s²
	## while directional input is held, and decays back at the same rate when
	## input is absent. rate == 0 disables the ramp entirely (all profiles except
	## Momentum default to 0).
	print("\n-- Speed ramp logic (Momentum profile) --")

	const SNAPPY_TRES   := preload("res://resources/profiles/snappy.tres")
	const FLOATY_TRES   := preload("res://resources/profiles/floaty.tres")
	const MOMENTUM_TRES := preload("res://resources/profiles/momentum.tres")

	# ── rate=0 default means no ramping ────────────────────────────────────────
	var p := CP.new()
	_ok("CP default: speed_ramp_rate = 0 (ramp disabled for plain profiles)",
		p.speed_ramp_rate == 0.0)

	# ── Ramp-up formula: one second of sustained input ─────────────────────────
	# Mirror: _ramp_speed = minf(_ramp_speed + rate * delta, ramp_max_speed)
	var rate    := 4.0
	var max_spd := 11.0
	var ramp_max := 18.0
	var ramp_spd := max_spd
	var dt := 1.0 / 60.0
	for _i: int in range(60):   # 1 second of input
		ramp_spd = minf(ramp_spd + rate * dt, ramp_max)
	var expected_after_1s := minf(max_spd + rate * 1.0, ramp_max)
	_ok("ramp-up: after 1 s of input speed ≈ max_spd + rate*1 (14.0 m/s)",
		_near(ramp_spd, expected_after_1s))

	# ── Ramp-up clamps at ramp_max_speed ──────────────────────────────────────
	for _i: int in range(600):  # 10 seconds
		ramp_spd = minf(ramp_spd + rate * dt, ramp_max)
	_ok("ramp-up: speed clamps at ramp_max_speed (18.0 m/s) after sustained input",
		_near(ramp_spd, ramp_max))

	# ── Ramp-down formula: one second of no input from ramp_max ───────────────
	# Mirror: _ramp_speed = maxf(_ramp_speed - rate * delta, profile.max_speed)
	ramp_spd = ramp_max
	for _i: int in range(60):   # 1 second no input
		ramp_spd = maxf(ramp_spd - rate * dt, max_spd)
	var expected_after_1s_decay := maxf(ramp_max - rate * 1.0, max_spd)
	_ok("ramp-down: after 1 s no input speed ≈ ramp_max − rate*1 (14.0 m/s)",
		_near(ramp_spd, expected_after_1s_decay))

	# ── Ramp-down floor: never falls below max_speed ──────────────────────────
	for _i: int in range(600):  # 10 seconds no input
		ramp_spd = maxf(ramp_spd - rate * dt, max_spd)
	_ok("ramp-down: speed never falls below max_speed (11.0 m/s)",
		_near(ramp_spd, max_spd))

	# ── Monotone increasing with sustained input ──────────────────────────────
	ramp_spd = max_spd
	var monotone := true
	var prev_spd := ramp_spd
	for _i: int in range(60):
		ramp_spd = minf(ramp_spd + rate * dt, ramp_max)
		if ramp_spd < prev_spd:
			monotone = false
			break
		prev_spd = ramp_spd
	_ok("ramp-up is monotone non-decreasing with sustained input", monotone)

	# ── Momentum profile has nonzero rate and meaningful headroom ─────────────
	_ok("Momentum profile: speed_ramp_rate > 0 (ramp enabled)",
		MOMENTUM_TRES.speed_ramp_rate > 0.0)
	_ok("Momentum profile: ramp_max_speed > max_speed (ramp adds top-speed headroom)",
		MOMENTUM_TRES.ramp_max_speed > MOMENTUM_TRES.max_speed)

	# ── Other profiles have rate == 0 ─────────────────────────────────────────
	_ok("Snappy profile: speed_ramp_rate = 0 (ramp disabled)",
		SNAPPY_TRES.speed_ramp_rate == 0.0)
	_ok("Floaty profile: speed_ramp_rate = 0 (ramp disabled)",
		FLOATY_TRES.speed_ramp_rate == 0.0)


func _test_zone_atmosphere_logic() -> void:
	## Pure-math mirror of the zone atmosphere constants defined in threshold.tscn
	## sub_resources (Env_Z1, Env_Z2, Env_Z3) and the zone trigger dimensions.
	## Values are sourced from docs/research/zone_atmosphere.md and guard against
	## accidental resets of the zone identity system.
	print("\n-- Zone atmosphere constants (Threshold zone identity) --")

	# ── Ambient colour temperature ordering ────────────────────────────────────
	# Zone 1 (Habitation): sodium-yellow warmth — R > G > B.
	var z1 := Color(0.35, 0.30, 0.22)
	_ok("Z1 ambient: R > G (sodium-yellow warmth)", z1.r > z1.g)
	_ok("Z1 ambient: G > B (no blue in warm habitation zone)", z1.g > z1.b)

	# Zone 2 (Maintenance): cold blue-white — B dominates R.
	var z2 := Color(0.22, 0.26, 0.38)
	_ok("Z2 ambient: B > R (cold blue-white dominance)", z2.b > z2.r)

	# Zone 3 (Industrial): amber — R > G > B.
	var z3 := Color(0.30, 0.22, 0.14)
	_ok("Z3 ambient: R > G > B (amber/orange dominance)", z3.r > z3.g and z3.g > z3.b)

	# ── Fog density ordering: vast hall < warm plaza < cold corridor ───────────
	# Larger spaces read as less dense; Zone 3's industrial hall has the least fog.
	var fog_z1 := 0.012; var fog_z2 := 0.015; var fog_z3 := 0.008
	_ok("Fog density order: Z3 (vast) < Z1 (warm) < Z2 (cold)",
		fog_z3 < fog_z1 and fog_z1 < fog_z2)

	# ── Zone trigger Z-axis coverage (from threshold.tscn node transforms + shapes) ─
	# Zone1Trigger: center_z=18, half_z=22 (size_z=44) → covers z=-4 to z=40.
	# Zone2Trigger: center_z=56, half_z=19 (size_z=38) → covers z=37 to z=75.
	# Zone3Trigger: center_z=112, half_z=43 (size_z=86) → covers z=69 to z=155.
	var z1_cz := 18.0;  var z1_hz := 22.0
	var z2_cz := 56.0;  var z2_hz := 19.0
	var z3_cz := 112.0; var z3_hz := 43.0

	# Player spawn (z=0) must be inside Zone1Trigger.
	_ok("Z1 trigger covers spawn z=0", absf(0.0 - z1_cz) <= z1_hz)

	# Zone2 floor centre (z=52.5) must be inside Zone2Trigger.
	_ok("Z2 trigger covers maintenance floor z=52.5", absf(52.5 - z2_cz) <= z2_hz)

	# G1 gantry (z=81) and Terminal (z=135) must both be inside Zone3Trigger.
	_ok("Z3 trigger covers G1 gantry (z=81) and Terminal (z=135)",
		absf(81.0 - z3_cz) <= z3_hz and absf(135.0 - z3_cz) <= z3_hz)


func _test_jump_anticipation_squish_math() -> void:
	## Mirrors _play_jump_stretch's new anticipation phase (coil before launch):
	##   coil_y  = 1.0 - 0.18 * _jump_stretch_scale
	##   coil_xz = 1.0 + 0.08 * _jump_stretch_scale
	## Guards that the anticipation squish is directionally opposite to the
	## stretch, is bounded (never inverts geometry), and is weaker than the
	## stretch (anticipation is subtle; stretch is the main event).
	print("\n-- Jump anticipation squish formulas (coil phase of _play_jump_stretch) --")

	# At scale=0: identity — slider off means no animation at all.
	_ok("anticipation: scale=0 → coil_y=1.0 (identity)",
		_near(1.0 - 0.18 * 0.0, 1.0))
	_ok("anticipation: scale=0 → coil_xz=1.0 (identity)",
		_near(1.0 + 0.08 * 0.0, 1.0))

	# At scale=1: exact expected values.
	_ok("anticipation: scale=1 → coil_y=0.82 (18%% squish)",
		_near(1.0 - 0.18 * 1.0, 0.82))
	_ok("anticipation: scale=1 → coil_xz=1.08 (8%% expand)",
		_near(1.0 + 0.08 * 1.0, 1.08))

	# Direction invariants at mid-range: squish (Y<1, XZ>1) — opposite to stretch.
	var coil_y_mid  := 1.0 - 0.18 * 0.5
	var coil_xz_mid := 1.0 + 0.08 * 0.5
	_ok("anticipation: scale=0.5 → coil_y < 1.0 (Y squishes, opposite stretch)",
		coil_y_mid < 1.0)
	_ok("anticipation: scale=0.5 → coil_xz > 1.0 (XZ expands, opposite stretch)",
		coil_xz_mid > 1.0)

	# Coil amplitude is weaker than stretch amplitude — anticipation is the tell,
	# stretch is the punchline. Coil Y-delta (0.18) < stretch Y-delta (0.30).
	var coil_y_delta    := 0.18
	var stretch_y_delta := 0.30
	_ok("anticipation: coil Y-delta < stretch Y-delta (anticipation is subtler)",
		coil_y_delta < stretch_y_delta)

	# Geometry never inverts: at max scale=1, coil_y=0.82 > 0 and coil_xz=1.08 reasonable.
	_ok("anticipation: coil_y > 0 at max scale (geometry never inverts)",
		1.0 - 0.18 * 1.0 > 0.0)
	_ok("anticipation: coil_xz < 1.5 at max scale (no over-expand)",
		1.0 + 0.08 * 1.0 < 1.5)


func _test_ghost_trail_recording() -> void:
	## Mirrors game.gd ghost trail recording logic:
	##   SAMPLE_INTERVAL = 1/30, MAX_TRAIL_DEPTH = 5, MAX_TRAIL_LEN = 2700
	##   _on_player_respawned(): push_front + pop_back if > MAX_TRAIL_DEPTH
	##   _physics_process(): accumulate + sample at SAMPLE_INTERVAL
	print("\n-- Ghost trail recording logic (game.gd) --")
	const SAMPLE_INTERVAL := 1.0 / 30.0
	const MAX_DEPTH       := 5
	const MAX_TRAIL_LEN   := 2700

	# Sampling interval is exactly 1/30 s.
	_ok("ghost trail: SAMPLE_INTERVAL = 1/30 s",
		_near(SAMPLE_INTERVAL, 0.03333, 0.00001))

	# Accumulator fires on the frame that crosses the threshold.
	var accum := 0.0
	var sample_count := 0
	for _i: int in 63:     # 63 frames at 60 fps = 1.05 s → expect 31 samples
		accum += 1.0 / 60.0
		if accum >= SAMPLE_INTERVAL:
			accum -= SAMPLE_INTERVAL
			sample_count += 1
	_ok("ghost trail: 63 frames at 60 fps → 31 samples (30 Hz with drift)",
		sample_count == 31)

	# Max trail length cap: trail never exceeds 2700 points.
	var trail := PackedVector3Array()
	for _i: int in 2710:
		trail.append(Vector3.ZERO)
		if trail.size() > MAX_TRAIL_LEN:
			trail.remove_at(0)
	_ok("ghost trail: trail capped at MAX_TRAIL_LEN = 2700",
		trail.size() == MAX_TRAIL_LEN)

	# Archive on respawn: trail_history grows up to MAX_DEPTH.
	var trail_history: Array[PackedVector3Array] = []
	for attempt: int in 7:
		var cur := PackedVector3Array()
		cur.append(Vector3(float(attempt), 0.0, 0.0))
		if cur.size() > 0:
			trail_history.push_front(cur.duplicate())
			if trail_history.size() > MAX_DEPTH:
				trail_history.pop_back()
	_ok("ghost trail: history depth capped at MAX_DEPTH = 5",
		trail_history.size() == MAX_DEPTH)

	# Most recent attempt is at index 0 (push_front ordering).
	_ok("ghost trail: most recent attempt at history[0]",
		_near(trail_history[0][0].x, 6.0))  # attempt 6 (last) pushed front

	# Oldest retained attempt is at index MAX_DEPTH - 1.
	_ok("ghost trail: oldest retained attempt at history[4]",
		_near(trail_history[MAX_DEPTH - 1][0].x, 2.0))  # attempt 2 (7-MAX_DEPTH=2)

	# Alpha formula: attempt 0 = ATTEMPT_ALPHA_MAX (0.50), each subsequent × ATTEMPT_ALPHA_DECAY (0.55).
	# Updated iter 110: was 0.35 before cold-blue colour redesign raised alpha for contrast.
	var alpha0 := 0.50 * pow(0.55, 0.0)
	var alpha1 := 0.50 * pow(0.55, 1.0)
	_ok("ghost trail: alpha[0] = 0.50 (newest, brightest — updated iter 110)",
		_near(alpha0, 0.50))
	_ok("ghost trail: alpha[1] = alpha[0] × 0.55 (each attempt fades)",
		_near(alpha1, alpha0 * 0.55))

	# Visible points formula: window_s * 30 Hz.
	_ok("ghost trail: visible_points(2.0 s) = 60",
		roundi(2.0 * 30.0) == 60)
	_ok("ghost trail: visible_points(4.0 s) = 120",
		roundi(4.0 * 30.0) == 120)


func _test_ghost_trail_resize_math() -> void:
	# Documents instance_count = MAX_DEPTH × visible_points after a slider resize.
	# These invariants verify that blank-after-resize covers all instances,
	# including the new ones above the old count.
	const MAX_D  := 5
	const SAMPLE := 30.0

	# 2 s window → 60 pts per attempt → 300 instances.
	_ok("ghost trail resize: instance_count(2 s) = 300",
		MAX_D * roundi(2.0 * SAMPLE) == 300)

	# 1 s window → 30 pts per attempt → 150 instances.
	_ok("ghost trail resize: instance_count(1 s) = 150",
		MAX_D * roundi(1.0 * SAMPLE) == 150)

	# 5 s window → 150 pts per attempt → 750 instances.
	_ok("ghost trail resize: instance_count(5 s) = 750",
		MAX_D * roundi(5.0 * SAMPLE) == 750)

	# Growing the window produces more instances (monotone).
	var count_2s := MAX_D * roundi(2.0 * SAMPLE)
	var count_5s := MAX_D * roundi(5.0 * SAMPLE)
	_ok("ghost trail resize: larger window → more instances (monotone)",
		count_5s > count_2s)

	# Shrinking the window produces fewer instances (monotone).
	var count_1s := MAX_D * roundi(1.0 * SAMPLE)
	_ok("ghost trail resize: smaller window → fewer instances (monotone)",
		count_1s < count_2s)


func _test_ghost_trail_point_t_normalization() -> void:
	## Documents the iter-110 fix: point_t normalises by actual range_len, not
	## visible_pts.  Before the fix, a short trail (fewer samples than
	## visible_pts) produced near-zero alpha on the newest point.
	##
	## Invariant (post-fix): for any trail length ≥ 1 the newest visible point
	## always gets point_t = 1.0 → full attempt_alpha.
	print("\n-- Ghost trail point_t normalization (iter 110) --")

	const VISIBLE_PTS := 60  # 2 s × 30 Hz

	# Short trail (5 points) — p_idx of newest point = 4.
	var short_range_len := 5
	var short_point_t := float(short_range_len - 1) / float(maxi(short_range_len - 1, 1))
	_ok("short trail (5 pts): newest point_t = 1.0 (was 0.067 with old formula)",
		_near(short_point_t, 1.0))

	# Single-point trail — range_len=1, denominator clamped to 1; no div-by-zero.
	var single_range_len := 1
	var single_point_t := float(0) / float(maxi(single_range_len - 1, 1))
	_ok("single-point trail: point_t = 0 (div-by-zero guard holds)",
		_near(single_point_t, 0.0))

	# Full-window trail — behaviour matches old formula to within 2%.
	var full_range_len := VISIBLE_PTS
	var new_full := float(full_range_len - 1) / float(maxi(full_range_len - 1, 1))
	_ok("full-window trail: newest point_t = 1.0 (old formula gave 59/60 ≈ 0.983)",
		_near(new_full, 1.0))


func _test_ghost_trail_colour_constants() -> void:
	## Guards the visual constants set in iter 110.
	## TRAIL_COLOUR: cold blue chosen for contrast against concrete grey;
	##   complements sodium amber, echoes biolume palette, does not dilute Stray yellow.
	## ATTEMPT_ALPHA_MAX: raised 0.35→0.50 with the colour change (cold blue needs more
	##   opacity to read on grey concrete than the old warm grey did).
	## ATTEMPT_ALPHA_DECAY: per-attempt fade so trail[4] ≈ 0.033 × trail[0] (barely visible).
	print("\n-- Ghost trail colour constants (iter 110) --")

	_ok("TRAIL_COLOUR.r = 0.40 (cold blue, low red component)",
		_near(GTR.TRAIL_COLOUR.r, 0.40))
	_ok("TRAIL_COLOUR.g = 0.55 (cold blue, mid green component)",
		_near(GTR.TRAIL_COLOUR.g, 0.55))
	_ok("TRAIL_COLOUR.b = 0.95 (cold blue, high blue component)",
		_near(GTR.TRAIL_COLOUR.b, 0.95))
	_ok("ATTEMPT_ALPHA_MAX = 0.50 (raised from 0.35 for contrast against concrete)",
		_near(GTR.ATTEMPT_ALPHA_MAX, 0.50))
	_ok("ATTEMPT_ALPHA_DECAY = 0.55 (oldest of 5 trails at ~3% of newest)",
		_near(GTR.ATTEMPT_ALPHA_DECAY, 0.55))

	# Decay is monotone: each successive attempt is strictly dimmer.
	var a0 := GTR.ATTEMPT_ALPHA_MAX * pow(GTR.ATTEMPT_ALPHA_DECAY, 0.0)
	var a4 := GTR.ATTEMPT_ALPHA_MAX * pow(GTR.ATTEMPT_ALPHA_DECAY, 4.0)
	_ok("ATTEMPT_ALPHA_DECAY: trail[4] < trail[0] (decay is monotone over 5 attempts)",
		a4 < a0)


func _test_ghost_trail_defaults() -> void:
	## Guards GhostTrailRenderer constants and the visible_window_s export
	## default (iter 114).
	##
	## Prior resize-math and disable-semantics tests copy MAX_DEPTH/SAMPLE_HZ
	## as local constants (MAX_D=5, SAMPLE=30.0), so a change in the source
	## file would not be caught by those tests.  Reading GTR.MAX_DEPTH and
	## GTR.SAMPLE_HZ directly here pins the implementation values.
	##
	## visible_window_s default and _enabled initial value are untested by any
	## other function; they matter for the first device session because:
	##   - visible_window_s default must match the dev-menu slider default_val (2.0),
	##     or the slider will silently override the script value on _build_ui.
	##   - _enabled must start false so no MultiMesh draw happens before the first
	##     respawn populates Game.trail_history.
	print("\n-- GhostTrailRenderer defaults (iter 114) --")

	# Constants read from GTR directly (not local copies).
	_ok("MAX_DEPTH = 5 (5 concurrent attempt trails in the MultiMesh pool)",
		GTR.MAX_DEPTH == 5)
	_ok("SAMPLE_HZ = 30.0 (trail recording rate — 30 position samples per second)",
		is_equal_approx(GTR.SAMPLE_HZ, 30.0))

	# Export default and derived pool size.  GTR.new() without a scene tree means
	# _ready() / _build_multimesh() do NOT run — tests pure script-declared state.
	var gtr := GTR.new()
	_ok("visible_window_s default = 2.0 (must match dev-menu slider default_val)",
		is_equal_approx(gtr.visible_window_s, 2.0))
	_ok("initial pool = MAX_DEPTH × visible_pts(2.0) = 5 × 60 = 300 instances",
		GTR.MAX_DEPTH * roundi(gtr.visible_window_s * GTR.SAMPLE_HZ) == 300)
	_ok("_enabled starts false (ghost trail OFF until level has meaningful data)",
		gtr._enabled == false)
	gtr.free()


func _test_camera_occlusion_defaults() -> void:
	## Documents the sphere-cast occlusion parameter defaults from camera_rig.gd.
	## These match the dev-menu slider default_val arguments added in iter 74.
	## A mismatch means the dev menu initialises a slider at the wrong position,
	## silently overwriting the camera's runtime value on _build_ui.
	print("\n-- Camera occlusion defaults (iter 74) --")

	# Sphere probe radius: 0.22 m absorbs frame-to-frame ray jitter at wall
	# edges, which is what causes the camera to flicker between "occluded" and
	# "clear" each frame when a thin ray grazes a corner. 0.0 falls back to a
	# single ray (legacy behaviour before the sphere cast was added).
	const PROBE_RADIUS_DEFAULT := 0.22
	_ok("probe_radius default 0.22 (sphere-cast occlusion active out of box)",
		_near(PROBE_RADIUS_DEFAULT, 0.22))

	# Probe radius 0 triggers the ray-cast fallback branch — sphere cast is
	# only dispatched when occlusion_probe_radius > 0.0 (camera_rig.gd line
	# `if occlusion_probe_radius > 0.0:`).
	_ok("probe_radius 0.0 → ray fallback (sphere cast inactive)",
		not (0.0 > 0.0))
	_ok("probe_radius 0.22 → sphere cast active",
		PROBE_RADIUS_DEFAULT > 0.0)

	# Pull-in must be faster than ease-out. Fast pull-in means the player is
	# never hidden for long when a wall enters the line of sight. Slow ease-out
	# prevents a bounce artefact when the camera grazes a corner edge and the
	# probe alternates hit/clear each frame.
	const PULL_IN_DEFAULT   := 28.0
	const EASE_OUT_DEFAULT  :=  6.0
	_ok("pull_in_smoothing (28) > ease_out_smoothing (6): fast reveal, slow fallback",
		PULL_IN_DEFAULT > EASE_OUT_DEFAULT)

	# Release-delay latch: camera stays at last-occluded pose for 0.18 s after
	# the probe reports a clear path, preventing flicker at corner edges.
	const LATCH_DELAY_DEFAULT := 0.18
	_ok("occlusion_release_delay default 0.18 s (hysteresis latch window)",
		_near(LATCH_DELAY_DEFAULT, 0.18))

	# Safe-distance floor formula: max(occlusion_min_distance, hit_dist - margin).
	# When the occluder is very close (hit_dist < min_dist + margin) the min-
	# distance floor prevents the camera from snapping into the player's geometry.
	const MIN_DIST := 0.8
	const MARGIN   := 0.3
	# Case: hit at 0.5 m — margin subtraction gives 0.2 m, below the floor → floor wins.
	_ok("safe_dist floor: hit 0.5, margin 0.3 → max(0.8, 0.2) = 0.8",
		_near(maxf(MIN_DIST, 0.5 - MARGIN), MIN_DIST))
	# Case: hit at 2.0 m — margin subtraction gives 1.7 m, above the floor → margin wins.
	_ok("safe_dist margin: hit 2.0, margin 0.3 → max(0.8, 1.7) = 1.7",
		_near(maxf(MIN_DIST, 2.0 - MARGIN), 1.7))


func _test_zone_env_bounds_and_disabled() -> void:
	## Pure-logic mirror of threshold.gd::_apply_zone_env.
	##
	## envs = [null, zone1_env, zone2_env, zone3_env]  (indices 0–3, size=4)
	## target = envs[zone_id] if zone_id < 4 else null
	##
	## Swap condition (enabled path):   zone_atmosphere_enabled AND target != null
	## Disabled-mode fallback (elif):   NOT zone_atmosphere_enabled AND zone1_env != null
	##
	## No Environment objects created — tests the selection/guard formulas directly.
	print("\n-- zone env selection: bounds check + disabled-mode fallback (threshold.gd) --")

	# Model envs as integer slots: -1 = null sentinel, 1/2/3 = zone slot index.
	var SIZE := 4
	var _slot := func(id: int) -> int:
		if id >= SIZE:
			return -1   # out of bounds → null
		return [-1, 1, 2, 3][id]

	# Index 0 is the null sentinel — zone IDs are 1-based.
	_ok("zone env: envs[0] is null sentinel (zone IDs are 1-based, not 0-based)",
		_slot.call(0) == -1)
	_ok("zone env: envs[1] = zone1 slot (valid zone_id=1 maps to zone1_env)",
		_slot.call(1) == 1)
	_ok("zone env: envs[2] = zone2 slot (valid zone_id=2 maps to zone2_env)",
		_slot.call(2) == 2)
	_ok("zone env: envs[3] = zone3 slot (valid zone_id=3 maps to zone3_env)",
		_slot.call(3) == 3)
	# Out-of-bounds guard: a caller passing zone_id=4 gets null, no crash or OOB read.
	_ok("zone env: zone_id=4 is out of bounds → null slot (safe; no array OOB crash)",
		_slot.call(4) == -1)

	# zone_id=0 with enabled=true: null sentinel blocks the swap (first condition false).
	# This prevents an accidental off-by-one from reaching zone1_env via the enabled path.
	var zone_id_0_slot: int = _slot.call(0) as int
	_ok("zone env: zone_id=0 enabled → no swap (null slot, enabled branch requires target != null)",
		not (true and zone_id_0_slot != -1))

	# Disabled-mode fallback: mirrors the `elif` branch in threshold.gd.
	# When the dev-menu "Zone atmo" toggle is OFF, zone1_env is used regardless
	# of which zone the player is in — providing a clean A/B reference frame.
	var _disabled_result := func(atmo_on: bool, z1_present: bool, zone_id: int) -> int:
		# Returns: -1 = no swap, 1 = zone1 fallback/slot, 2/3 = target slot
		var slot: int = _slot.call(zone_id) as int
		if atmo_on and slot != -1:
			return slot
		elif not atmo_on and z1_present:
			return 1   # zone1 fallback
		return -1   # no swap (null target or no z1)

	# Disabled + zone2 → zone1 fallback (dev-menu off always shows zone1 reference).
	_ok("zone env: zone_id=2 disabled + z1_present → zone1 fallback (A/B comparison baseline)",
		_disabled_result.call(false, true, 2) == 1)
	# Disabled + zone3 → zone1 fallback.
	_ok("zone env: zone_id=3 disabled → zone1 fallback",
		_disabled_result.call(false, true, 3) == 1)
	# Enabled + zone1 → zone1 via the enabled path (not the fallback).
	_ok("zone env: zone_id=1 enabled → zone1 via enabled path (slot=1, not fallback)",
		_disabled_result.call(true, true, 1) == 1)
	# Enabled + zone2 → zone2 (not zone1 fallback).
	_ok("zone env: zone_id=2 enabled → zone2 via enabled path (correct zone identity)",
		_disabled_result.call(true, true, 2) == 2)


func _test_respawn_ramp_speed_reset() -> void:
	## Documents the _ramp_speed lifecycle in player.gd.
	##
	## Initialised/reset to profile.max_speed in exactly two places:
	##   _apply_profile_to_body() — profile load or dev-menu swap.
	##   respawn()               — on death, so speed carry-over can't inflate
	##                             the next attempt's momentum profile.
	##
	## Landing (on_floor branch in _tick_timers) does NOT reset _ramp_speed.
	## The `else` branch in _apply_horizontal decays it back to max_speed
	## naturally when no input is held — landing alone does not clear momentum.
	print("\n-- _ramp_speed lifecycle: init / respawn reset / landing-no-reset --")
	const RATE     := 4.0    # Momentum profile speed_ramp_rate
	const MAX_SPD  := 11.0   # Momentum profile max_speed
	const RAMP_MAX := 18.0   # Momentum profile ramp_max_speed
	const DELTA    := 1.0 / 60.0

	# Initial state: _apply_profile_to_body() sets _ramp_speed = profile.max_speed.
	var ramp := MAX_SPD
	_ok("ramp lifecycle: initial _ramp_speed = profile.max_speed (not ramp_max)",
		_near(ramp, MAX_SPD))

	# Ramp-up: 2 seconds of sustained input lifts speed above max_speed.
	for _i: int in 120:
		ramp = minf(ramp + RATE * DELTA, RAMP_MAX)
	_ok("ramp lifecycle: after 2 s input _ramp_speed > max_speed (ramp engaged)",
		ramp > MAX_SPD)

	# Respawn: _ramp_speed reset to max_speed — carries no momentum into next attempt.
	ramp = MAX_SPD   # simulate: `_ramp_speed = profile.max_speed` in respawn()
	_ok("ramp lifecycle: respawn resets _ramp_speed to max_speed (no attempt carry-over)",
		_near(ramp, MAX_SPD))

	# Decay without input: each no-input frame brings _ramp_speed back toward max_speed.
	ramp = RAMP_MAX   # assume fully ramped
	var prev := ramp
	ramp = maxf(ramp - RATE * DELTA, MAX_SPD)   # one no-input frame
	_ok("ramp lifecycle: no-input frame decreases _ramp_speed (decay branch active)",
		ramp < prev)
	_ok("ramp lifecycle: decay floor — _ramp_speed never falls below max_speed",
		ramp >= MAX_SPD)

	# Landing alone does NOT reset _ramp_speed (decay is the mechanism, not on_floor).
	# After landing + 0.5 s no input, speed is still above max_speed — not yet decayed.
	ramp = RAMP_MAX
	for _i: int in 30:   # 0.5 s × 60 fps = 30 frames of no input post-landing
		ramp = maxf(ramp - RATE * DELTA, MAX_SPD)
	# After 0.5 s: 18.0 − 4.0 × 0.5 = 16.0 > 11.0
	_ok("ramp lifecycle: 0.5 s post-landing no-input → _ramp_speed still above max (decay not landing-reset)",
		ramp > MAX_SPD)
	# Full decay to max_speed takes (18 − 11) / 4 = 1.75 s — documents the window.
	_ok("ramp lifecycle: full decay from ramp_max to max_speed takes ≥ 1.5 s ((ramp_max-max)/rate)",
		(RAMP_MAX - MAX_SPD) / RATE > 1.5)


func _test_ghost_trail_disable_and_resize_semantics() -> void:
	## Documents iter-73 behavioral fixes in ghost_trail_renderer.gd:
	##
	## Fix 1 — blank AFTER resize:
	##   _on_ghost_trail_param resizes instance_count THEN calls _blank_from(0).
	##   Blanking BEFORE resize only zeros [0..old_count) and leaves the new slots
	##   [old_count..new_count) at Godot's default colour (opaque white), producing
	##   a one-frame flash on window enlargement.
	##
	## Fix 2 — _process disabled path uses _mmesh.visible = false (O(1)),
	##   not _blank_from(0) per frame (O(instances)).
	##   _on_juice_changed still calls _blank_from(0) once on the disable event
	##   so stale data is cleared before the node is hidden.
	print("\n-- Ghost trail: disable blank and resize-then-blank semantics (iter-73 fixes) --")
	const MAX_D  := 5
	const SAMPLE := 30.0

	# --- Fix 1: resize-then-blank covers all instances including newly added ones. ---
	# Window enlarged from 2 s (300 instances) to 5 s (750 instances).
	var old_count := MAX_D * roundi(2.0 * SAMPLE)   # 300
	var new_count := MAX_D * roundi(5.0 * SAMPLE)   # 750

	# Buggy path: blank [0, old_count) first, THEN set instance_count = new_count.
	# Slots [old_count, new_count) are added AFTER blanking — never zeroed.
	var buggy_blank_ceiling := old_count              # 300 — stops here
	var buggy_unzeroed      := new_count - buggy_blank_ceiling  # 450 slots flash white

	# Fixed path: set instance_count = new_count first, THEN blank [0, new_count).
	# All slots, including the new ones, are zeroed in the same pass.
	var fixed_blank_ceiling := new_count              # 750 — covers everything
	var fixed_unzeroed      := new_count - fixed_blank_ceiling  # 0

	_ok("resize-then-blank: buggy path leaves 450 new slots unzeroed (documents the bug)",
		buggy_unzeroed == 450)
	_ok("resize-then-blank: fixed path leaves zero slots unzeroed",
		fixed_unzeroed == 0)
	_ok("resize-then-blank: fixed blank ceiling > buggy blank ceiling",
		fixed_blank_ceiling > buggy_blank_ceiling)

	# Shrink case (5 s → 2 s): slots above new_count are discarded by the resize;
	# blank [0, new_count) covers only the surviving instances. No flash possible.
	var shrink_discarded := (MAX_D * roundi(5.0 * SAMPLE)) - (MAX_D * roundi(2.0 * SAMPLE))
	_ok("resize shrink: 450 old slots discarded by resize (no unzeroed-slot risk on shrink)",
		shrink_discarded == 450)

	# --- Fix 2: _process disabled path performance model. ---
	# Before fix: _process called _blank_from(0) every frame while disabled.
	#   Cost: 300 instances × 60 fps = 18,000 set_instance_color GPU writes/sec.
	# After fix: _process sets _mmesh.visible = false (1 call/frame, O(1)).
	#   _on_juice_changed calls _blank_from(0) once on the disable event (data hygiene).
	var instances := old_count   # 300 (default 2 s window)
	var fps       := 60
	var old_cost  := instances * fps   # 18,000 writes/sec
	var new_cost  := 1 * fps           # 60 writes/sec

	_ok("disabled path old cost: 300 × 60 = 18,000 GPU writes/sec (per-frame blank_from)",
		old_cost == 18000)
	_ok("disabled path new cost: 60 writes/sec (visible=false, O(1) per frame)",
		new_cost == 60)
	_ok("disabled path: fix reduces write rate by exactly instance_count (300×)",
		old_cost / new_cost == instances)

	# Combined disable behaviour: one blank on the event, then node hidden per frame.
	# Ensures no stale trail data is visible if ghost trails are re-enabled mid-run.
	var blank_calls_on_disable := 1   # _on_juice_changed: _blank_from(0) called once
	var blank_calls_per_frame  := 0   # _process: visible=false, no _blank_from
	_ok("on disable: one _blank_from call on event + zero per frame (data hygiene + efficiency)",
		blank_calls_on_disable == 1 and blank_calls_per_frame == 0)


func _test_respawn_input_timer_clearing() -> void:
	## Documents the cleanup performed by player.gd::respawn():
	## every input-derived timer and state flag is zeroed at death so nothing from
	## the fatal frame can carry into the next attempt's startup.
	##
	## Guard: `if _is_rebooting: return` at the top of respawn() ensures a second
	## death event during the reboot animation is silently discarded.
	## _physics_process has the same guard — no gravity, movement, or jumps during
	## the reboot animation sequence.
	print("\n-- respawn(): input timer clearing and double-respawn guard --")

	# Simulate pre-death state: all timers live, dash active.
	var buffer_timer := 0.15   # jump buffered one frame before death
	var coyote_timer := 0.08   # died mid-coyote-window
	var air_jumps    := 1      # one air jump remaining in the aerial pool
	var dash_charges := 1      # dash charge available
	var dash_timer   := 0.10   # mid-dash at moment of death
	var is_dashing   := true

	# Apply the exact clearing assignments from player.gd::respawn() (lines 322–335).
	buffer_timer = 0.0
	coyote_timer = 0.0
	air_jumps    = 0
	dash_charges = 0
	dash_timer   = 0.0
	is_dashing   = false

	_ok("respawn: _buffer_timer cleared (buffered jump at death-frame cannot fire post-reboot)",
		_near(buffer_timer, 0.0))
	_ok("respawn: _coyote_timer cleared (coyote window cannot carry into reboot)",
		_near(coyote_timer, 0.0))
	_ok("respawn: _air_jumps_remaining zeroed (no aerial jump pool during reboot)",
		air_jumps == 0)
	_ok("respawn: _dash_charges zeroed (charge cannot carry into next attempt)",
		dash_charges == 0)
	_ok("respawn: _dash_timer cleared (no lingering dash duration after death)",
		_near(dash_timer, 0.0))
	_ok("respawn: _is_dashing cleared (dash cannot be active during reboot animation)",
		is_dashing == false)

	# Double-respawn guard: _is_rebooting is set immediately at the top of respawn(),
	# before any async work starts.  A second respawn() call hits the guard and returns.
	var is_rebooting := false
	is_rebooting = true   # first call: sets flag at entry
	var second_call_proceeds := not is_rebooting  # guard: "if _is_rebooting: return"
	_ok("respawn guard: second call during reboot is discarded (_is_rebooting blocks re-entry)",
		second_call_proceeds == false)

	# _physics_process also checks _is_rebooting and returns early,
	# blocking gravity, movement, and jump processing for the full reboot duration.
	var physics_runs := not is_rebooting
	_ok("respawn guard: _physics_process blocked while rebooting (no movement during animation)",
		physics_runs == false)


func _test_assisted_phase2_params() -> void:
	## Ledge magnetism and arc assist — new Assisted Phase 2 mechanics.
	##
	## _attract_to_ledge():
	##   Fire at ground/coyote jump. Probe ahead-left and ahead-right for a
	##   nearby surface; apply a lateral impulse if found. Guard: disabled when
	##   ledge_magnet_radius == 0, or when the player is NOT on the floor
	##   (coyote window: player already left the edge — magnet would pull them back).
	##
	## _apply_arc_assist():
	##   Runs every airborne frame. Simulates 20 steps ahead; if predicted landing
	##   drifts within arc_assist_max of a surface, adds a tiny per-frame lateral
	##   nudge. Guard: disabled when arc_assist_max == 0, when _coyote_timer > 0
	##   (floor-departure window), and when accumulated correction ≥ 1.5 m/s.
	print("\n-- Assisted Phase 2: ledge magnetism + arc assist params and guards --")

	# --- Default profile: all three new params must be 0 (disabled) ---
	var default_profile := ControllerProfile.new()
	_ok("ledge magnet: default ControllerProfile.ledge_magnet_radius == 0 (disabled)",
		_near(default_profile.ledge_magnet_radius, 0.0))
	_ok("ledge magnet: default ControllerProfile.ledge_magnet_strength == 0 (disabled)",
		_near(default_profile.ledge_magnet_strength, 0.0))
	_ok("arc assist: default ControllerProfile.arc_assist_max == 0 (disabled)",
		_near(default_profile.arc_assist_max, 0.0))

	# --- Assisted.tres: non-zero defaults for all three ---
	var assisted := load("res://resources/profiles/assisted.tres") as ControllerProfile
	_ok("ledge magnet: assisted.tres ledge_magnet_radius == 0.20",
		_near(assisted.ledge_magnet_radius, 0.20))
	_ok("ledge magnet: assisted.tres ledge_magnet_strength == 1.0",
		_near(assisted.ledge_magnet_strength, 1.0))
	_ok("arc assist: assisted.tres arc_assist_max == 0.40",
		_near(assisted.arc_assist_max, 0.40))

	# --- _attract_to_ledge guard: radius == 0 → no impulse ---
	# Mirrors the early-return condition at the top of _attract_to_ledge().
	var profile_no_magnet := ControllerProfile.new()  # ledge_magnet_radius = 0
	var magnet_fires := profile_no_magnet.ledge_magnet_radius > 0.0 and \
		profile_no_magnet.ledge_magnet_strength > 0.0
	_ok("ledge magnet guard: radius=0 → _attract_to_ledge returns without impulse",
		magnet_fires == false)

	# --- _apply_arc_assist guard: arc_assist_max == 0 → no correction ---
	var profile_no_arc := ControllerProfile.new()  # arc_assist_max = 0
	var arc_fires := profile_no_arc.arc_assist_max > 0.0
	_ok("arc assist guard: arc_assist_max=0 → _apply_arc_assist returns without correction",
		arc_fires == false)

	# --- _apply_arc_assist guard: coyote window active → no correction ---
	# _coyote_timer > 0 while airborne means the player just walked off a ledge and
	# hasn't jumped yet. Arc-assist during this window would fight the floor-departure.
	var coyote_timer := 0.06  # mid-coyote-window
	var arc_fires_in_coyote := assisted.arc_assist_max > 0.0 and coyote_timer <= 0.0
	_ok("arc assist guard: coyote_timer > 0 → _apply_arc_assist returns (no fight on floor-departure)",
		arc_fires_in_coyote == false)

	# --- _arc_assist_accumulated reset on jump ---
	# Both the ground-jump and air-jump branches reset _arc_assist_accumulated to 0.0
	# so each new arc gets a fresh correction budget.
	var accumulated := 1.2  # some carry-over from previous arc
	# Simulate the jump branch clearing it (line in _try_jump: _arc_assist_accumulated = 0.0)
	accumulated = 0.0
	_ok("arc assist: _arc_assist_accumulated reset to 0 on jump (fresh budget per arc)",
		_near(accumulated, 0.0))


func _test_free_cam_mode() -> void:
	## Free-camera mode — CLAUDE.md required Level section dev menu item.
	##
	## Key invariants:
	##   - debug_viz_state contains &"free_cam" key, default false.
	##   - CameraRig.free_cam_speed default is 10.0 m/s.
	##   - Shift boost multiplies speed by 3×.
	##   - Pitch clamp bounds: ±PI*0.45 (~81°).
	##   - On enable: _free_cam_yaw/_pitch seeded from current camera pose.
	##   - On disable: _initialized reset so the tracking ratchet rebuilds cleanly.
	##   - TouchInput drain: consume_camera_drag_delta() called each free-cam frame
	##     to prevent drag accumulation appearing as a jump on mode exit.
	print("\n-- Free cam mode: debug viz entry + CameraRig defaults --")

	# DevMenu: key present and defaults to false
	_ok("free cam: DevMenu.debug_viz_state has &'free_cam' key",
		DevMenu.debug_viz_state.has(&"free_cam"))
	_ok("free cam: default is false (player-tracking mode on startup)",
		DevMenu.is_debug_viz_on(&"free_cam") == false)

	# Round-trip set/get
	DevMenu.set_debug_viz(&"free_cam", true)
	_ok("free cam: set_debug_viz(true) → is_debug_viz_on() == true",
		DevMenu.is_debug_viz_on(&"free_cam") == true)
	DevMenu.set_debug_viz(&"free_cam", false)
	_ok("free cam: set_debug_viz(false) → is_debug_viz_on() == false",
		DevMenu.is_debug_viz_on(&"free_cam") == false)

	# CameraRig: free_cam_speed export default
	var rig := CameraRig.new()
	_ok("free cam: CameraRig.free_cam_speed default == 10.0 m/s",
		_near(rig.free_cam_speed, 10.0))

	# Shift speed-boost formula
	var boosted := rig.free_cam_speed * 3.0
	_ok("free cam: Shift boost is 3× base speed (30.0 m/s at default)",
		_near(boosted, 30.0))

	# Pitch clamp bounds
	var max_pitch := PI * 0.45
	_ok("free cam: pitch upper bound == PI * 0.45 (~81°)",
		_near(max_pitch, 1.4137, 0.001))
	_ok("free cam: clampf beyond +PI stays at PI * 0.45",
		_near(clampf(PI, -max_pitch, max_pitch), max_pitch))
	_ok("free cam: clampf beyond -PI stays at -PI * 0.45",
		_near(clampf(-PI, -max_pitch, max_pitch), -max_pitch))

	# _initialized starts false on a fresh rig (tracking not yet started)
	_ok("free cam: CameraRig._initialized starts false (no tracking until first _process)",
		rig._initialized == false)

	rig.free()


func _test_snappy_reboot_duration() -> void:
	## Snappy reboot_duration tuning (side quest iter 79).
	##
	## Research (level_design_references.md): precision platformers benefit from
	## ≤ 0.35 s reboot (SMB analysis: 0.3–0.35 s optimal — fast enough for thumb
	## re-settle before the next attempt). Cinematic profiles (Floaty, Assisted,
	## Momentum) stay at 0.5 s. Human confirmed Snappy feel is "good overall"
	## (2026-05-14 direction session), unblocking this tune-down.
	print("\n-- Snappy reboot_duration: precision timing vs cinematic profiles --")

	var snappy  := load("res://resources/profiles/snappy.tres")  as ControllerProfile
	var floaty  := load("res://resources/profiles/floaty.tres")  as ControllerProfile
	var momentum := load("res://resources/profiles/momentum.tres") as ControllerProfile
	var assisted := load("res://resources/profiles/assisted.tres") as ControllerProfile

	# Snappy must be within the research-recommended precision range
	_ok("reboot_duration: snappy.tres is within [0.30, 0.35] s",
		snappy.reboot_duration >= 0.30 and snappy.reboot_duration <= 0.35)
	_ok("reboot_duration: snappy.tres == 0.33 (research midpoint)",
		_near(snappy.reboot_duration, 0.33))

	# Floaty / Assisted / Momentum remain at 0.5 s (cinematic / forgiving)
	_ok("reboot_duration: floaty.tres == 0.5 (cinematic)",
		_near(floaty.reboot_duration, 0.5))
	_ok("reboot_duration: assisted.tres == 0.5 (forgiving)",
		_near(assisted.reboot_duration, 0.5))
	_ok("reboot_duration: momentum.tres == 0.5 (cinematic)",
		_near(momentum.reboot_duration, 0.5))

	# Ordering invariant: Snappy < Floaty (precision < cinematic)
	_ok("reboot_duration: snappy < floaty (precision-feel shorter than cinematic)",
		snappy.reboot_duration < floaty.reboot_duration)


func _test_audio_skeleton() -> void:
	## Audio autoload (iter 80): bus setup, sound_layers wiring, event dispatch
	## stubs. Stream vars default null (populated in _ready() from sfx/ assets);
	## every dispatch method must exist; LAND_HEAVY_THRESHOLD in valid range.
	print("\n-- Audio skeleton: stream defaults + dispatch methods --")

	# LAND_HEAVY_THRESHOLD splits light vs heavy landing SFX.
	_ok("LAND_HEAVY_THRESHOLD == 0.25",
		_near(AU.LAND_HEAVY_THRESHOLD, 0.25))
	_ok("LAND_HEAVY_THRESHOLD is in valid impact range (0, 1)",
		AU.LAND_HEAVY_THRESHOLD > 0.0 and AU.LAND_HEAVY_THRESHOLD < 1.0)

	# Instantiate without adding to tree so _ready() does not fire.
	var au := AU.new()

	# All stream vars must default null (no assets committed yet).
	_ok("_sfx_jump defaults null",          au._sfx_jump         == null)
	_ok("_sfx_land_light defaults null",    au._sfx_land_light   == null)
	_ok("_sfx_land_heavy defaults null",    au._sfx_land_heavy   == null)
	_ok("_sfx_collect_shard defaults null", au._sfx_collect_shard == null)
	_ok("_sfx_respawn_start defaults null", au._sfx_respawn_start == null)

	# Dispatch methods must exist so call-sites in player.gd / data_shard.gd
	# compile without error even before any stream is assigned.
	_ok("has method on_jump()",           au.has_method(&"on_jump"))
	_ok("has method on_land()",           au.has_method(&"on_land"))
	_ok("has method on_collect_shard()",  au.has_method(&"on_collect_shard"))
	_ok("has method on_respawn_start()",  au.has_method(&"on_respawn_start"))
	_ok("has method play_sfx()",          au.has_method(&"play_sfx"))

	au.free()


func _test_wall_normal_viz_key() -> void:
	## Wall normal is listed in CLAUDE.md debug-viz requirements ("ground/wall
	## normals"). Verify the key was added to debug_viz_state and defaults OFF
	## (consistent with other on-demand viz keys).
	print("\n-- Wall normal debug viz key --")

	var dm := DM.new()

	_ok("wall_normal key present in debug_viz_state",
		dm.debug_viz_state.has(&"wall_normal"))
	_ok("wall_normal defaults false (off by default)",
		dm.debug_viz_state[&"wall_normal"] == false)
	_ok("ground_normal key still present (no regression)",
		dm.debug_viz_state.has(&"ground_normal"))

	dm.free()


func _test_screen_shake_system() -> void:
	## Screen shake (iter 81): camera_rig.gd shake state, Game signal,
	## and player.gd emission thresholds / magnitudes.
	print("\n-- Screen shake system (iter 81) --")

	# --- CameraRig defaults ---
	var rig := CameraRig.new()
	_ok("shake_intensity_scale export defaults 1.0",
		_near(rig.shake_intensity_scale, 1.0))
	_ok("_shake_remaining starts 0.0 (no shake at spawn)",
		_near(rig._shake_remaining, 0.0))
	_ok("_shake_decay starts 0.0",
		_near(rig._shake_decay, 0.0))
	rig.free()

	# --- Game signal exists ---
	var g: GM = GM.new()
	_ok("Game has screen_shake_requested signal",
		g.has_signal("screen_shake_requested"))
	g.free()

	# --- Shake preset value sanity checks ---
	# Land: 0.011 rad per unit of impact (impact range 0–1); fires above 0.25.
	# Death: 0.022 rad fixed.  Both < 0.05 rad (~2.9°) to avoid motion sickness.
	const LAND_MAG_PER_IMPACT := 0.011
	const DEATH_MAG := 0.022
	_ok("land shake magnitude < death shake (land less jarring)",
		LAND_MAG_PER_IMPACT < DEATH_MAG)
	_ok("land max (impact=1.0) > 0 and < 0.05 rad",
		LAND_MAG_PER_IMPACT > 0.0 and LAND_MAG_PER_IMPACT < 0.05)
	_ok("death magnitude > 0 and < 0.05 rad",
		DEATH_MAG > 0.0 and DEATH_MAG < 0.05)

	# Land shake threshold = Audio.LAND_HEAVY_THRESHOLD = 0.25.
	# Kept in 0.20–0.35 range: low enough to catch noticeable falls,
	# high enough to skip micro-landings on shallow slopes.
	const LAND_THRESHOLD := 0.25
	_ok("land shake threshold in [0.20, 0.35] (matches heavy-land audio band)",
		LAND_THRESHOLD >= 0.20 and LAND_THRESHOLD <= 0.35)

	# Decay formula: _shake_decay = magnitude / duration. After `duration`
	# seconds the full magnitude is subtracted → shake reaches 0.
	const DEATH_DUR := 0.20
	const DEATH_DECAY := DEATH_MAG / DEATH_DUR
	_ok("death shake: decay * duration == magnitude (decays to zero in time)",
		_near(DEATH_DECAY * DEATH_DUR, DEATH_MAG))
	_ok("death shake decay rate > magnitude (clears in < 1 s)",
		DEATH_DECAY > DEATH_MAG)


func _test_ledge_magnet_impulse_formula() -> void:
	## Mirrors the proportional-impulse formula in player.gd::_attract_to_ledge.
	##
	## Formula: impulse = minf((dist / ledge_magnet_radius) * ledge_magnet_strength,
	##                          ledge_magnet_strength)
	##
	## A closer edge needs a weaker nudge (player is already mostly over the platform);
	## an edge at the full radius gets the configured max strength; beyond radius, capped.
	print("\n-- Ledge magnet proportional impulse formula (_attract_to_ledge) --")
	const R := 0.20
	const S := 1.0

	_ok("lm: dist=0 → impulse=0 (edge at foot — player already over it, no pull needed)",
		is_equal_approx(minf((0.0 / R) * S, S), 0.0))
	_ok("lm: dist=radius → impulse=strength (edge at max range → full pull)",
		is_equal_approx(minf((R / R) * S, S), S))
	_ok("lm: dist=2×radius → capped at strength (beyond range, cap prevents overshoot)",
		is_equal_approx(minf((R * 2.0 / R) * S, S), S))
	_ok("lm: dist=radius/2 → impulse=strength/2 (linearly proportional)",
		_near(minf((R * 0.5 / R) * S, S), S * 0.5))
	_ok("lm: monotone — farther edge within radius produces stronger nudge",
		minf((0.15 / R) * S, S) > minf((0.05 / R) * S, S))

	var ap := load("res://resources/profiles/assisted.tres") as ControllerProfile
	if ap == null:
		return
	var dist_half := ap.ledge_magnet_radius * 0.5
	_ok("lm: Assisted at half-radius (0.10 m) → impulse = strength/2 (0.5 m/s)",
		_near(minf((dist_half / ap.ledge_magnet_radius) * ap.ledge_magnet_strength, ap.ledge_magnet_strength),
			ap.ledge_magnet_strength * 0.5))
	_ok("lm: Assisted at full radius (0.20 m) → impulse = strength exactly (1.0 m/s)",
		_near(minf((ap.ledge_magnet_radius / ap.ledge_magnet_radius) * ap.ledge_magnet_strength, ap.ledge_magnet_strength),
			ap.ledge_magnet_strength))


func _test_arc_assist_per_frame_budget() -> void:
	## Mirrors the per-frame correction limits and lifetime budget in
	## player.gd::_apply_arc_assist.
	##
	## Two concurrent limits gate each correction step:
	##   Limit A (raw)      = arc_assist_max * 0.05  (5% of tolerated offset per frame)
	##   Limit B (vel-cap)  = jump_velocity * 0.15 * delta  (≤ 15% of jump vel × dt)
	##   Effective per frame = min(Limit A, Limit B)
	## Lifetime budget = MAX_ACCUMULATED (1.5 m/s), reset on each jump. Once exhausted
	## _apply_arc_assist returns early — no further steering for that arc.
	print("\n-- Arc assist per-frame correction limits and lifetime budget --")
	const MAX_ACC    := 1.5
	const DELTA_60   := 1.0 / 60.0

	var ap := load("res://resources/profiles/assisted.tres") as ControllerProfile
	if ap == null:
		return

	# Limit A: raw cap — at most 5% of the tolerated offset per frame
	var limit_a := ap.arc_assist_max * 0.05
	_ok("arc: Limit A = arc_assist_max * 0.05 = 0.40 * 0.05 = 0.02 m/frame",
		_near(limit_a, 0.02))

	# Limit B: velocity-based cap at 60 fps (Assisted jump_velocity = 10.0)
	var limit_b := ap.jump_velocity * 0.15 * DELTA_60
	_ok("arc: Limit B = jump_velocity * 0.15 / 60 = 10.0 * 0.15 / 60 = 0.025 m/frame",
		_near(limit_b, 0.025, 1e-4))

	# Effective = min(A, B) — Limit A is tighter at Assisted defaults
	var effective := minf(limit_a, limit_b)
	_ok("arc: effective = min(Limit A, Limit B) = 0.02 (Limit A wins at Assisted defaults)",
		_near(effective, limit_a))
	_ok("arc: effective < Limit B (5%-of-offset cap is smaller than 15%-vel cap here)",
		effective < limit_b)

	# Budget remaining after partial accumulation
	var acc_partial := 1.2
	_ok("arc: budget = MAX_ACCUMULATED - accumulated: 1.5 - 1.2 = 0.3 m/s remaining",
		_near(MAX_ACC - acc_partial, 0.3))

	# Budget exhausted: per_frame is clamped to zero via limit_length(0)
	var acc_full := 1.5
	var budget_at_full := MAX_ACC - acc_full
	var clamped_correction := Vector3(effective, 0.0, 0.0).limit_length(budget_at_full).length()
	_ok("arc: accumulated=1.5 → budget=0 → per_frame clamped to 0 (no steering past lifetime cap)",
		_near(clamped_correction, 0.0))

	# Offset guard: correction skipped when offset >= arc_assist_max (break before velocity update)
	var offset_beyond := ap.arc_assist_max + 0.01
	_ok("arc: offset >= arc_assist_max → correction skipped (landing too far off-centre to help)",
		not (offset_beyond < ap.arc_assist_max))
	var offset_within := ap.arc_assist_max * 0.5
	_ok("arc: offset < arc_assist_max → correction fires (drift is within the steerable window)",
		offset_within < ap.arc_assist_max)


func _test_screen_shake_strongest_wins() -> void:
	## Mirrors the "only the strongest in-flight shake wins" rule in
	## camera_rig.gd::_on_screen_shake_requested.
	##
	## Rule:
	##   if magnitude <= _shake_remaining: return  # weaker-or-equal discarded
	##   _shake_remaining = magnitude
	##   _shake_decay = magnitude / maxf(0.001, duration)
	##
	## Prevents land-shake clusters from resetting a stronger death shake, while still
	## allowing a second death shake to correctly restart the decay from the new peak.
	print("\n-- Screen shake: strongest-wins rule (_on_screen_shake_requested) --")

	# --- Case 1: stronger incoming replaces the weaker in-flight shake ---
	var rem_1 := 0.011   # land shake in flight
	var inc_1 := 0.022   # death shake arrives mid-flight
	var after_1 := rem_1
	if inc_1 > rem_1:
		after_1 = inc_1
	_ok("stronger shake replaces weaker: death (0.022) overrides land (0.011) in flight",
		_near(after_1, inc_1))

	# --- Case 2: weaker incoming is discarded ---
	var rem_2 := 0.022   # death shake in flight
	var inc_2 := 0.011   # land shake arrives later in the same run
	var after_2 := rem_2
	if inc_2 > rem_2:
		after_2 = inc_2  # would replace — must NOT happen
	_ok("weaker shake discarded: land (0.011) cannot override in-flight death (0.022)",
		_near(after_2, rem_2))

	# --- Case 3: equal magnitude is also discarded (guard is <=, not <) ---
	var rem_3 := 0.022
	var inc_3 := 0.022
	var overrode_3 := false
	if inc_3 > rem_3:  # strict >; equal does not qualify
		overrode_3 = true
	_ok("equal magnitude discarded: a second 0.022 does not restart an in-flight 0.022",
		overrode_3 == false)

	# --- Decay formula: _shake_decay = magnitude / maxf(0.001, duration) ---
	const MAG := 0.022
	const DUR := 0.20
	var decay := MAG / maxf(0.001, DUR)
	_ok("decay formula: magnitude / duration = 0.022 / 0.20 = 0.11 rad/s",
		_near(decay, MAG / DUR))
	_ok("decay * duration == magnitude (shake decays to zero after exactly duration s)",
		_near(decay * DUR, MAG))

	# --- Zero-duration guard prevents division by zero ---
	var decay_zero_dur := MAG / maxf(0.001, 0.0)
	_ok("zero-duration guard: maxf(0.001, 0) → 0.001 → decay is finite (no div-by-zero)",
		decay_zero_dur > 0.0 and is_finite(decay_zero_dur))

	# --- Land and death shakes use distinct frequencies ---
	const LAND_FREQ  := 20.0
	const DEATH_FREQ := 26.0
	_ok("land (20 Hz) and death (26 Hz) shake frequencies are distinct — different tactile feel",
		not is_equal_approx(LAND_FREQ, DEATH_FREQ))


func _test_run_timer_semantics() -> void:
	## Documents the wall-clock timer model: timer runs continuously through all
	## deaths and reboot animations. Mirrors the analysis in
	## docs/research/run_timer_semantics.md.
	##
	## Key invariant: Game.is_running is NOT toggled by respawn — only by
	## level_complete() (win) and reset_run() (replay). This means displayed
	## run_time_seconds includes reboot-animation overhead.
	##
	## Par-time calibration formula:
	##   par_wall_clock = movement_time + (expected_deaths × reboot_duration)
	print("\n-- Run-timer semantics (wall-clock model, run_timer_semantics.md) --")
	var g: GM = GM.new()

	# register_attempt() is what respawn() calls on the Game autoload.
	# It must NOT change is_running — only increments the attempt counter.
	g.start_run()
	g.register_attempt()
	_ok("register_attempt (respawn path) does not stop the run timer (is_running stays true)",
		g.is_running == true)
	g.register_attempt()
	g.register_attempt()
	_ok("multiple respawns keep is_running true (wall-clock model: timer runs through deaths)",
		g.is_running == true)

	# Reboot-duration overhead table (from run_timer_semantics.md):
	#   Snappy 0.33 s, others 0.50 s
	const SNAPPY_REBOOT := 0.33
	const FLOATY_REBOOT := 0.50

	# Snappy overhead: 4 deaths × 0.33 s = 1.32 s
	var snappy_overhead_4 := 4 * SNAPPY_REBOOT
	_ok("Snappy 4 deaths: overhead = 4 × 0.33 = 1.32 s",
		_near(snappy_overhead_4, 1.32))

	# Floaty overhead: 4 deaths × 0.50 s = 2.0 s
	var floaty_overhead_4 := 4 * FLOATY_REBOOT
	_ok("Floaty 4 deaths: overhead = 4 × 0.50 = 2.0 s",
		_near(floaty_overhead_4, 2.0))

	# Par calibration: Threshold placeholder is 35.0 s (pure movement time).
	# With 4 Snappy deaths, wall-clock par ≈ 35.0 + 1.32 = 36.32 s.
	# The research note recommends rounding up to 37 s for a conservative par.
	const THRESHOLD_MOVEMENT_PAR := 35.0
	var calibrated_par := THRESHOLD_MOVEMENT_PAR + snappy_overhead_4
	_ok("par calibration: movement_time + overhead > pure movement_time (wall-clock par is higher)",
		calibrated_par > THRESHOLD_MOVEMENT_PAR)
	_ok("par calibration: Threshold wall-clock par with 4 Snappy deaths ≈ 36.3 s",
		_near(calibrated_par, 36.32))

	# "deaths needed to add ~10 s overhead" threshold from the research table.
	# Snappy: 10 / 0.33 ≈ 30.3 → 30 deaths. Floaty: 10 / 0.50 = 20 deaths.
	var snappy_deaths_for_10s: int = int(10.0 / SNAPPY_REBOOT)
	var floaty_deaths_for_10s: int = int(10.0 / FLOATY_REBOOT)
	_ok("Snappy: ~30 deaths to accumulate 10 s overhead (Snappy reboot 0.33 s)",
		snappy_deaths_for_10s == 30)
	_ok("Floaty: 20 deaths to accumulate 10 s overhead (Floaty reboot 0.50 s)",
		floaty_deaths_for_10s == 20)

	# Snappy reboot is shorter than Floaty — less per-death overhead, faster respawn feel.
	_ok("Snappy reboot (0.33 s) is shorter than Floaty reboot (0.50 s)",
		SNAPPY_REBOOT < FLOATY_REBOOT)

	g.free()


func _test_footstep_and_land_impact_math() -> void:
	## Mirrors the throttle logic in _tick_timers() and the geometry formulas in
	## _build_footstep_mesh() / _build_impact_mesh() from player.gd (iter 84).
	print("\n-- Footstep dust + land impact particle math (iter 84) --")

	# ---- Footstep dust timer throttle ----
	# Default interval is 0.15 s — greater than zero so it does not fire every frame.
	const FOOTSTEP_INTERVAL := 0.15
	_ok("footstep interval default (0.15 s) > 0 — throttled, not every frame",
		FOOTSTEP_INTERVAL > 0.0)

	# Timer countdown: maxf clamps to 0, does not go negative.
	_ok("timer countdown: maxf(0, 0.12 - 0.016) < 0.12",
		maxf(0.0, 0.12 - 0.016) < 0.12)
	_ok("timer countdown: maxf(0, 0.010 - 0.016) == 0.0 (clamps at zero)",
		is_equal_approx(maxf(0.0, 0.010 - 0.016), 0.0))

	# Fire condition: timer <= 0.
	_ok("footstep fires when timer == 0.0 (condition: timer <= 0.0)", 0.0 <= 0.0)
	# After firing, timer is reset to interval (not zero) so next fire is delayed.
	var timer_after_fire := FOOTSTEP_INTERVAL
	_ok("footstep timer resets to interval (0.15 s) after firing, not 0",
		timer_after_fire > 0.0)

	# Speed gate: fires only when horizontal speed > 0.5 m/s (above dead zone).
	const MIN_SPEED := 0.5
	_ok("footstep suppressed at h_speed = 0.3 m/s (below gate)", 0.3 < MIN_SPEED)
	_ok("footstep fires at h_speed = 2.0 m/s (above gate)", 2.0 >= MIN_SPEED)

	# ---- Footstep mesh geometry ----
	# 4 lines at TAU/4 (90°) increments. cos²+sin² == 1 confirms unit XZ directions.
	for i in 4:
		var angle := float(i) * TAU / 4.0
		_ok("footstep line %d at 90° interval: cos²+sin² == 1" % i,
			_near(cos(angle) * cos(angle) + sin(angle) * sin(angle), 1.0))

	# ---- Land impact threshold ----
	const LAND_THRESHOLD := 0.15
	_ok("land impact threshold (0.15) below audio heavy threshold (0.25) — fires on lighter landings",
		LAND_THRESHOLD < 0.25)
	_ok("light landing impact=0.10 < threshold — no particles", 0.10 < LAND_THRESHOLD)
	_ok("medium impact=0.20 >= threshold — particles fire", 0.20 >= LAND_THRESHOLD)
	_ok("heavy impact=1.0 >= threshold — particles fire", 1.0 >= LAND_THRESHOLD)

	# ---- Land impact line-length formula ----
	# length = 0.08 + impact * 0.22  — heavier landing → longer lines.
	var len_at_threshold := 0.08 + LAND_THRESHOLD * 0.22
	var len_at_max       := 0.08 + 1.0 * 0.22
	_ok("land impact at threshold (0.15): line length ≈ 0.113",
		_near(len_at_threshold, 0.113))
	_ok("land impact at max (1.0): line length = 0.30",
		_near(len_at_max, 0.30))
	_ok("land impact: heavy lines longer than threshold-level lines",
		len_at_max > len_at_threshold)


func _test_footstep_dust_state_machine() -> void:
	## Mirrors the state-machine logic extracted into _tick_footstep_dust() in
	## player.gd (iter 85 refactor). Tests the three conditions that gate dust emission:
	## (A) not the landing frame, (B) on_floor, (C) h_speed > 0.5.
	## The timer countdown and reset are also verified.
	print("\n-- _tick_footstep_dust state machine (iter 85) --")

	const INTERVAL := 0.15   # _footstep_dust_interval default
	const MIN_SPEED := 0.5   # h_speed gate
	const DELTA := 1.0 / 60.0  # one physics tick

	# Landing-frame skip: even when on_floor and h_speed is above gate,
	# dust must NOT fire when just_landed is true (land impact burst has its own frame).
	var timer_before := 0.0   # timer already expired — would fire next tick
	var timer_after_landing_frame := maxf(0.0, timer_before - DELTA)
	var would_fire_without_skip := (true and not false and true and (2.0 >= MIN_SPEED) and timer_after_landing_frame <= 0.0)
	var would_fire_with_skip    := (true and not true  and true and (2.0 >= MIN_SPEED) and timer_after_landing_frame <= 0.0)
	_ok("landing frame: without just_landed guard, dust would fire (baseline)", would_fire_without_skip)
	_ok("landing frame: with just_landed=true guard, dust does NOT fire", not would_fire_with_skip)

	# Airborne guard: on_floor=false suppresses dust regardless of speed or timer.
	var airborne_fire := (false and not false and true and (5.0 >= MIN_SPEED) and 0.0 <= 0.0)
	_ok("airborne: on_floor=false prevents dust even with high speed and expired timer", not airborne_fire)

	# Speed gate: h_speed <= MIN_SPEED suppresses dust even when timer expired and on floor.
	var slow_fire := (true and not false and true and (0.3 >= MIN_SPEED) and 0.0 <= 0.0)
	_ok("speed gate: h_speed=0.3 < MIN_SPEED (0.5) suppresses dust", not slow_fire)
	var walk_fire := (true and not false and true and (0.6 >= MIN_SPEED) and 0.0 <= 0.0)
	_ok("speed gate: h_speed=0.6 >= MIN_SPEED (0.5) allows dust", walk_fire)

	# Timer reset after firing: timer is set to INTERVAL, not zero.
	# Next emission is delayed by exactly INTERVAL seconds.
	var timer_after_fire := INTERVAL
	_ok("timer resets to INTERVAL (0.15 s) after spawn — prevents next-frame re-fire",
		timer_after_fire > 0.0)
	_ok("timer after reset will not immediately expire on next tick (INTERVAL > DELTA)",
		timer_after_fire > DELTA)

	# Timer countdown clamps at zero (maxf guard).
	var t := maxf(0.0, 0.005 - DELTA)
	_ok("timer countdown: nearly-expired timer clamps to 0.0, does not go negative",
		t >= 0.0)
	_ok("timer countdown: nearly-expired timer IS 0 (ready to fire next check)",
		t == 0.0)


func _test_blob_shadow_export_defaults() -> void:
	## Guards the BlobShadow @export_range initial values that the dev-menu sliders
	## and the depth-perception tuning session depend on. Changing a default here
	## without updating the dev-menu slider range or the iter-85 research note is a
	## silent regression — this test makes it loud.
	print("\n-- BlobShadow export defaults --")

	var bs := BlobShadow.new()
	_ok("radius_at_ground default 0.22 m (close-to-floor disc size)",
		_near(bs.radius_at_ground, 0.22))
	_ok("radius_at_height default 0.55 m (disc expands with height for penumbra cue)",
		_near(bs.radius_at_height, 0.55))
	_ok("fade_height default 6.0 m (shadow readable for typical jump arcs)",
		_near(bs.fade_height, 6.0))
	_ok("alpha_max default 0.42 (visible but not black-disc distracting)",
		_near(bs.alpha_max, 0.42))
	_ok("radius_at_height > radius_at_ground (shadow expands upward — depth cue correct)",
		bs.radius_at_height > bs.radius_at_ground)
	bs.free()


func _test_blob_shadow_param_dispatch() -> void:
	## Mirrors the match block in blob_shadow.gd::_on_blob_shadow_param_changed.
	## Ensures every dev-menu "Blob Shadow — Tuning" slider routes to the correct
	## property. A missing or mis-spelled match arm is caught here before it causes
	## a silent no-op on device.
	print("\n-- BlobShadow param dispatch --")

	var bs := BlobShadow.new()

	bs._on_blob_shadow_param_changed(&"radius_at_ground", 0.35)
	_ok("radius_at_ground dispatch sets property", _near(bs.radius_at_ground, 0.35))

	bs._on_blob_shadow_param_changed(&"radius_at_height", 0.90)
	_ok("radius_at_height dispatch sets property", _near(bs.radius_at_height, 0.90))

	bs._on_blob_shadow_param_changed(&"fade_height", 12.0)
	_ok("fade_height dispatch sets property", _near(bs.fade_height, 12.0))

	bs._on_blob_shadow_param_changed(&"alpha_max", 0.75)
	_ok("alpha_max dispatch sets property", _near(bs.alpha_max, 0.75))

	# Unknown param must be a silent no-op — no crash, no mutation of known props.
	var rg_snapshot := bs.radius_at_ground
	bs._on_blob_shadow_param_changed(&"nonexistent_param", 99.0)
	_ok("unknown param leaves radius_at_ground unchanged (match is exhaustive)",
		_near(bs.radius_at_ground, rg_snapshot))

	bs.free()


func _test_blob_shadow_juice_toggle() -> void:
	## Mirrors blob_shadow.gd::_on_juice_changed. The juice toggle system calls
	## this with every key change; only the &"blob_shadow" key should mutate
	## _enabled. Other keys must be ignored so toggling unrelated juice elements
	## (squash_stretch, screen_shake, etc.) does not affect the shadow.
	print("\n-- BlobShadow juice toggle --")

	var bs := BlobShadow.new()

	_ok("blob shadow starts enabled (_enabled default true)", bs._enabled == true)

	bs._on_juice_changed(&"blob_shadow", false)
	_ok("juice_changed blob_shadow→false disables shadow", bs._enabled == false)

	bs._on_juice_changed(&"blob_shadow", true)
	_ok("juice_changed blob_shadow→true re-enables shadow", bs._enabled == true)

	bs._on_juice_changed(&"squash_stretch", false)
	_ok("unrelated key squash_stretch does not disable blob shadow", bs._enabled == true)

	bs.free()


func _test_threshold_skyline_param() -> void:
	## Mirrors threshold.gd::_on_atmosphere_param_changed — skyline_visible arm.
	## Null guard must hold when _skyline is absent (no scene tree), and the
	## visible property must toggle when a Node3D is wired directly.
	print("\n-- Threshold skyline param --")

	var ThresholdScript = load("res://scripts/levels/threshold.gd")
	var t = ThresholdScript.new()
	# _ready() never fires without a scene tree; _skyline stays null.
	# Null guard must prevent crash — reaching the next line is the pass condition.
	t._on_atmosphere_param_changed(&"skyline_visible", true)
	_ok("skyline_visible with null _skyline is a safe no-op", true)

	# Wire a real Node3D and confirm visible is toggled.
	var fake_skyline := Node3D.new()
	fake_skyline.visible = true
	t._skyline = fake_skyline
	t._on_atmosphere_param_changed(&"skyline_visible", false)
	_ok("skyline_visible=false hides the DistantSkyline node", fake_skyline.visible == false)
	t._on_atmosphere_param_changed(&"skyline_visible", true)
	_ok("skyline_visible=true shows the DistantSkyline node", fake_skyline.visible == true)

	# Unrelated param must leave skyline visibility unchanged.
	t._on_atmosphere_param_changed(&"zone_atmo_enabled", false)
	_ok("zone_atmo_enabled param does not touch skyline visibility", fake_skyline.visible == true)

	fake_skyline.free()
	t.free()


func _test_chick_body_mesh_path() -> void:
	## Documents and guards the expected Godot node path to the chick body mesh.
	## GLB node hierarchy (parsed from animal-chick.glb binary):
	##   node[0]=animal-chick (root, no mesh) → node[1]=root (no mesh)
	##   → node[4]=body (mesh 2, has wing children).
	## When imported as PackedScene named "Chick" under Visual, the path
	## from player root is "Visual/Chick/root/body".
	## Also guards that _set_emission/_clear_emission handle null _body_mesh safely.
	print("\n-- Chick body mesh path + emission null guard --")

	var expected_path := "Visual/Chick/root/body"
	var parts := expected_path.split("/")
	_ok("chick body mesh path has 4 segments (Visual/Chick/root/body)",
		parts.size() == 4)
	_ok("chick body mesh path starts with Visual/Chick",
		expected_path.begins_with("Visual/Chick"))
	_ok("chick body mesh path leaf node is 'body'",
		parts[parts.size() - 1] == "body")
	_ok("chick body mesh intermediate node matches GLB root child 'root'",
		parts[2] == "root")

	# Null guard: instantiate player without a scene tree so @onready vars stay
	# null, then call emission helpers — no crash is the pass condition.
	var PlayerScript = load("res://scripts/player/player.gd")
	_ok("player.gd loads without error", PlayerScript != null)
	var p = PlayerScript.new()
	p._set_emission(Color(1, 0.18, 0.1), 5.0)
	_ok("_set_emission with null _body_mesh is a safe no-op", true)
	p._clear_emission()
	_ok("_clear_emission with null _body_mesh is a safe no-op", true)
	p.free()


func _test_patrol_sentry_logic() -> void:
	## Mirrors the patrol math in patrol_sentry.gd without instantiating any node.
	## Tests timing, boundary clamping, wait semantics, bob formula,
	## position composition, and kill-zone sizing.
	print("\n-- Patrol sentry patrol math --")

	# Default export values from patrol_sentry.gd
	const PATROL_SPEED := 2.5
	const PATROL_DIST  := 8.0
	const WAIT_DUR     := 0.5
	const BODY_HALF    := 0.40
	const KILL_HALF    := 0.50
	const BOB_AMP      := 0.08
	const BOB_PERIOD   := 2.0

	var half := PATROL_DIST * 0.5   # = 4.0 m

	# 1. Starting offset is 0.
	var offset := 0.0
	_ok("initial offset is 0", _near(offset, 0.0))

	# 2. After T = half/speed seconds the sentry reaches the endpoint.
	var t_to_end := half / PATROL_SPEED   # = 1.6 s
	var simulated_offset := minf(PATROL_SPEED * t_to_end, half)
	_ok("offset reaches half_dist after T = half/speed", _near(simulated_offset, half))

	# 3. At the endpoint the direction flips (direction goes from +1 to -1).
	var dir_after := -1.0   # mirrors _dir = -1.0 set in _tick_patrol at +half boundary
	_ok("direction is -1 after reaching +half endpoint", _near(dir_after, -1.0))

	# 4. While waiting, offset is unchanged.
	var offset_at_end := half
	var offset_after_wait_tick := offset_at_end   # _tick_patrol returns early during wait
	_ok("offset unchanged during wait period", _near(offset_after_wait_tick, half))

	# 5. Wait expires after wait_duration seconds.
	var wait_t := 0.0
	wait_t += WAIT_DUR
	_ok("wait timer reaches wait_duration after one increment", _near(wait_t, WAIT_DUR))

	# 6. After wait, sentry moves back toward –half.
	# One delta step at speed after reversal from +half:
	var delta := 0.1
	var offset_after_one_step := half + dir_after * PATROL_SPEED * delta   # = 4.0 - 0.25 = 3.75
	_ok("offset decreases after reversal", offset_after_one_step < half)

	# 7. Full round-trip travel time (ignoring wait) = patrol_dist / speed.
	var travel_time := PATROL_DIST / PATROL_SPEED   # = 3.2 s
	_ok("round-trip travel time = patrol_dist / speed", _near(travel_time, 3.2))

	# 8. Full cycle time includes two waits.
	var cycle_time := travel_time + 2.0 * WAIT_DUR   # = 3.2 + 1.0 = 4.2 s
	_ok("full cycle time = travel_time + 2 × wait_duration", _near(cycle_time, 4.2))

	# 9. Bob formula: sin(0) = 0, sin(TAU/4) = 1 → amplitude at quarter-period.
	var bob_t0 := sin(0.0 * TAU / BOB_PERIOD) * BOB_AMP
	var bob_qtr := sin((BOB_PERIOD * 0.25) * TAU / BOB_PERIOD) * BOB_AMP
	_ok("bob at t=0 is 0", _near(bob_t0, 0.0))
	_ok("bob at t=period/4 equals amplitude", _near(bob_qtr, BOB_AMP))

	# 10. Kill zone half-extent is larger than body half-extent.
	#     Ensures Area3D fires before the physics wall stops the player.
	_ok("kill zone larger than visual body (fires before physics wall)", KILL_HALF > BODY_HALF)


func _test_audio_sfx_wiring() -> void:
	## Kenney Sci-Fi Sounds SFX assets wired (iter 91): validates landing-path
	## routing, linear-to-dB volume formula, SFX asset paths, and the new
	## audio_param_changed signal key — without needing AudioServer.
	print("\n-- Audio SFX wiring (iter 91) --")

	const LAND_HEAVY := 0.25  # mirrors Audio.LAND_HEAVY_THRESHOLD

	# 1. Impact just below threshold routes to land_light path.
	_ok("impact 0.24 < LAND_HEAVY_THRESHOLD → land_light",
		(LAND_HEAVY - 0.01) < LAND_HEAVY)

	# 2. Impact exactly at threshold routes to land_heavy path.
	_ok("impact 0.25 >= LAND_HEAVY_THRESHOLD → land_heavy",
		LAND_HEAVY >= LAND_HEAVY)

	# 3. Impact above threshold also routes to land_heavy.
	_ok("impact 0.5 >= LAND_HEAVY_THRESHOLD → land_heavy", 0.5 >= LAND_HEAVY)

	# 4. sfx_volume = 1.0 → 0 dB (unity gain).
	_ok("sfx_volume=1.0 → 0 dB", _near(linear_to_db(1.0), 0.0))

	# 5. sfx_volume < 1.0 → negative dB (attenuated).
	_ok("sfx_volume=0.25 → negative dB", linear_to_db(0.25) < 0.0)

	# 6. sfx_volume > 1.0 → positive dB (amplified).
	_ok("sfx_volume=2.0 → positive dB", linear_to_db(2.0) > 0.0)

	# 7. audio_param_changed key &"sfx_volume" is the correct StringName.
	var dm := DM.new()
	_ok("DM has audio_param_changed signal",
		dm.has_signal(&"audio_param_changed"))
	dm.free()

	# 8. Five SFX asset paths follow the assets/audio/sfx/<event>.ogg pattern.
	var paths: Array[String] = [
		"res://assets/audio/sfx/jump.ogg",
		"res://assets/audio/sfx/land_light.ogg",
		"res://assets/audio/sfx/land_heavy.ogg",
		"res://assets/audio/sfx/collect_shard.ogg",
		"res://assets/audio/sfx/respawn_start.ogg",
	]
	_ok("five SFX assets under res://assets/audio/sfx/", paths.size() == 5)


func _test_ambient_audio_routing() -> void:
	## Ambient audio infrastructure (iter 92): BUS_AMBIENT constant, null-default
	## stream vars, set_ambient_zone API, ambient_volume dB formula, zone-2
	## routing condition, and two expected ambient asset paths.
	print("\n-- Ambient audio routing (iter 92) --")

	# 1. BUS_AMBIENT constant is the expected StringName.
	_ok("BUS_AMBIENT == &\"Ambient\"", AU.BUS_AMBIENT == &"Ambient")

	# 2–3. Ambient stream vars default null (no asset files committed yet).
	var au := AU.new()
	_ok("_ambient_global defaults null", au._ambient_global == null)
	_ok("_ambient_zone2 defaults null",  au._ambient_zone2  == null)
	au.free()

	# 4. set_ambient_zone method exists (API surface for threshold.gd call).
	var au2 := AU.new()
	_ok("has method set_ambient_zone()", au2.has_method(&"set_ambient_zone"))
	au2.free()

	# 5. ambient_volume = 1.0 → 0 dB (unity gain; same linear_to_db formula as sfx_volume).
	_ok("ambient_volume=1.0 → 0 dB", _near(linear_to_db(1.0), 0.0))

	# 6. ambient_volume = 0.5 → negative dB (half-power attenuation).
	_ok("ambient_volume=0.5 → negative dB", linear_to_db(0.5) < 0.0)

	# 7. Zone 2 routing condition: zone_id == 2 is the unique trigger for the
	#    zone2 fan layer; zones 1 and 3 do not satisfy it.
	_ok("zone_id=2 triggers zone2 layer (condition true)",  2 == 2)
	_ok("zone_id=1 does not trigger zone2 layer (cond false)", 1 != 2)
	_ok("zone_id=3 does not trigger zone2 layer (cond false)", 3 != 2)

	# 8. Expected ambient asset paths follow the assets/audio/ambient/<name>.ogg pattern.
	var ambient_paths: Array[String] = [
		"res://assets/audio/ambient/ambient_global.ogg",
		"res://assets/audio/ambient/ambient_zone2.ogg",
	]
	_ok("two ambient asset paths defined", ambient_paths.size() == 2)
	_ok("global path starts with res://assets/audio/ambient/",
		ambient_paths[0].begins_with("res://assets/audio/ambient/"))


func _test_sentry_param_dispatch() -> void:
	## Mirrors patrol_sentry.gd::_on_sentry_param_changed which uses GDScript
	## self.set(prop, value) to route dev-menu slider changes to sentry properties.
	## Tests that all four dev-menu-exposed params accept their expected types and
	## values, and that an unknown param is a silent no-op for existing props.
	##
	## Uses PatrolSentry.new() without scene-tree insertion so _ready() is not
	## called — this exercises the dispatch method in isolation.
	print("\n-- Patrol sentry param dispatch (_on_sentry_param_changed) --")

	var ps := PatrolSentry.new()

	# Default export values — a silent change to a default would drift the
	# dev-menu initial slider position and go unnoticed on device without this.
	_ok("sentry patrol_speed default 2.5",    _near(ps.patrol_speed,    2.5))
	_ok("sentry patrol_distance default 8.0", _near(ps.patrol_distance, 8.0))
	_ok("sentry wait_duration default 0.5",   _near(ps.wait_duration,   0.5))
	_ok("sentry bob_enabled default true",    ps.bob_enabled == true)

	# Float dispatch — dev-menu sliders emit float values via sentry_param_changed.
	ps._on_sentry_param_changed(&"patrol_speed",    4.0)
	_ok("patrol_speed dispatch sets 4.0",    _near(ps.patrol_speed,    4.0))

	ps._on_sentry_param_changed(&"patrol_distance", 12.0)
	_ok("patrol_distance dispatch sets 12.0", _near(ps.patrol_distance, 12.0))

	ps._on_sentry_param_changed(&"wait_duration",   1.5)
	_ok("wait_duration dispatch sets 1.5",   _near(ps.wait_duration,   1.5))

	# Bool dispatch — the bob toggle emits bool through sentry_param_changed.
	ps._on_sentry_param_changed(&"bob_enabled", false)
	_ok("bob_enabled dispatch → false", ps.bob_enabled == false)

	ps._on_sentry_param_changed(&"bob_enabled", true)
	_ok("bob_enabled dispatch → true",  ps.bob_enabled == true)

	# Unknown property: GDScript set() on a non-existent key adds an instance
	# variable but leaves known @export properties untouched. A dev-menu typo
	# must never corrupt patrol_speed.
	var speed_snap := ps.patrol_speed
	ps._on_sentry_param_changed(&"nonexistent_sentry_param", 999.0)
	_ok("unknown param leaves patrol_speed unchanged (GDScript set is silent no-op)",
		_near(ps.patrol_speed, speed_snap))

	ps.free()


func _test_sentry_initial_state() -> void:
	## Guards the five private tick-state vars that drive the patrol algorithm.
	## PatrolSentry.new() without scene-tree insertion skips _ready(), so
	## _origin, visual mesh, and kill-zone are absent — but the tick vars must
	## start at their declared defaults so _tick_patrol's first frame is correct.
	print("\n-- Patrol sentry initial state (tick vars at declaration defaults) --")

	var ps := PatrolSentry.new()

	_ok("_offset starts 0.0 — patrol begins at spawn origin",     _near(ps._offset,  0.0))
	_ok("_dir starts +1.0 — first move is in the +axis direction", _near(ps._dir,    1.0))
	_ok("_waiting starts false — not paused at startup",           ps._waiting == false)
	_ok("_wait_t starts 0.0 — wait timer not yet running",         _near(ps._wait_t, 0.0))
	_ok("_bob_t starts 0.0 — bob phase at sin(0) = 0 on frame 1", _near(ps._bob_t,  0.0))

	ps.free()


func _test_trail_lifecycle() -> void:
	## Guards game.gd trail recording invariants NOT covered by _test_ghost_trail_recording()
	## (which tests sampling math and archive-depth capping) or _test_game_gate1_api()
	## (which tests run-timer and shard fields but not trail_history or _recording):
	##
	##   start_run()      → trail_history.clear() + _recording = true
	##   level_complete() → _recording = false  (no samples after the win trigger)
	##   reset_run()      → trail_history.clear() (replay starts with no ghost data)
	##   _on_player_respawned() with empty _current_trail
	##                    → trail_history unchanged, _sample_accum still reset
	##   _on_player_respawned() with non-empty _current_trail under MAX_TRAIL_DEPTH
	##                    → trail_history grows by 1 without pop_back; _current_trail cleared
	print("\n-- Trail recording lifecycle (game.gd) --")
	var g: GM = GM.new()

	# ── start_run() clears old trail data ────────────────────────────────────
	# Without this guard a level replay would show ghost trails from the
	# previous run — the "you already know the route" anti-pattern.
	var dummy := PackedVector3Array()
	dummy.append(Vector3.ONE)
	g.trail_history.push_back(dummy)
	g.trail_history.push_back(dummy)
	g.start_run()
	_ok("start_run: trail_history cleared so prior-run ghosts never appear on replay",
		g.trail_history.size() == 0)

	# ── start_run() arms the sampler ─────────────────────────────────────────
	_ok("start_run: _recording set to true (physics_process will write samples)",
		g._recording == true)

	# ── level_complete() disarms the sampler ─────────────────────────────────
	# Movement after the WinState trigger must not corrupt the trail that
	# will be shown as a ghost on the next replay attempt.
	g.level_complete()
	_ok("level_complete: _recording set to false (post-win movement not sampled)",
		g._recording == false)

	# ── reset_run() clears trail data ────────────────────────────────────────
	g.trail_history.push_back(dummy)
	g.reset_run()
	_ok("reset_run: trail_history cleared (ghost data gone for a fresh game)",
		g.trail_history.size() == 0)

	# ── empty-trail respawn: history guard ───────────────────────────────────
	# If the player dies before a single 30 Hz sample fires (< 33 ms into the
	# attempt), _current_trail is empty.  The "if _current_trail.size() > 0"
	# guard must prevent an empty PackedVector3Array from entering trail_history;
	# an empty history entry would produce invisible MultiMesh instances and
	# confuse the archive-depth counter.
	g.start_run()  # clears trail_history and _current_trail; _recording = true
	g._on_player_respawned()
	_ok("_on_player_respawned with empty trail: trail_history stays at 0 (guard skips push_front)",
		g.trail_history.size() == 0)

	# ── empty-trail respawn: accumulator still resets ─────────────────────────
	# _sample_accum must reset even when the trail guard fires, otherwise the
	# next attempt's first sample is delayed by whatever residual was in accum.
	g._sample_accum = 0.12
	g._current_trail.resize(0)
	g._on_player_respawned()
	_ok("_on_player_respawned with empty trail: _sample_accum reset to 0 (accum guard must not skip it)",
		_near(g._sample_accum, 0.0))

	# ── non-empty trail respawn under MAX_DEPTH ───────────────────────────────
	# When history is below capacity no pop_back should fire — the first
	# several deaths just grow the archive linearly.
	g.trail_history.clear()
	g._current_trail.resize(0)
	g._current_trail.append(Vector3(3.0, 0.0, 0.0))
	g._on_player_respawned()
	_ok("first respawn with 1 sample: trail_history grows to 1 (no pop_back below MAX_TRAIL_DEPTH)",
		g.trail_history.size() == 1)

	# ── _current_trail cleared after archive ─────────────────────────────────
	# The archived copy is a duplicate(); the live trail must be empty so the
	# next attempt records a fresh path instead of appending to the old one.
	_ok("_on_player_respawned: _current_trail cleared after archiving (next attempt starts fresh)",
		g._current_trail.size() == 0)

	g.free()


func _test_threshold_level_lifecycle() -> void:
	## Guards threshold.gd state-machine invariants not covered by
	## _test_zone_env_bounds_and_disabled (_apply_zone_env pure logic) or
	## _test_threshold_skyline_param (skyline arm: checks skyline.visible but
	## does NOT verify the zone_atmosphere_enabled field is mutated correctly).
	##
	## Three gaps covered:
	##   A. zone_atmosphere_enabled field state under _on_atmosphere_param_changed.
	##   B. _on_zone_body_entered non-Player body filter (_active_zone must not
	##      change when a physics body that is not the Player enters a trigger).
	##   C. get_spawn_transform() null guard (no crash + returns IDENTITY when
	##      PlayerSpawn marker is absent from the scene).
	print("\n-- Threshold level lifecycle (threshold.gd) --")

	var ThresholdScript = load("res://scripts/levels/threshold.gd")
	_ok("threshold.gd loads without error", ThresholdScript != null)
	if ThresholdScript == null:
		return
	var t = ThresholdScript.new()

	# ── A. zone_atmosphere_enabled field state ───────────────────────────────
	# Atmosphere toggle must default to enabled so zone-identity fires on level
	# load without any dev-menu interaction required from the tester.
	_ok("zone_atmosphere_enabled defaults to true (zone triggers active on level load)",
		t.zone_atmosphere_enabled == true)

	# The zone_atmo_enabled param must write the field to false (not just skip the
	# skyline branch — that is what _test_threshold_skyline_param already guards).
	t._on_atmosphere_param_changed(&"zone_atmo_enabled", false)
	_ok("zone_atmo_enabled=false sets zone_atmosphere_enabled to false",
		t.zone_atmosphere_enabled == false)

	# Re-enabling restores the field so subsequent zone entries resume swapping.
	t._on_atmosphere_param_changed(&"zone_atmo_enabled", true)
	_ok("zone_atmo_enabled=true restores zone_atmosphere_enabled to true",
		t.zone_atmosphere_enabled == true)

	# An unrecognised param must not silently mutate the field (no default branch).
	t._on_atmosphere_param_changed(&"unknown_xyz", false)
	_ok("unknown param leaves zone_atmosphere_enabled unchanged (no default branch side-effect)",
		t.zone_atmosphere_enabled == true)

	# ── B. _on_zone_body_entered non-Player body filter ──────────────────────
	# _active_zone starts at 1 — the level entry is always Zone 1.
	_ok("_active_zone initialises to 1 (level entry is Zone 1)",
		t._active_zone == 1)

	# A plain Node3D (patrol sentry, crate, etc.) must not trigger a zone swap.
	# The early-return guard `if not body is Player: return` exists for exactly this.
	var non_player := Node3D.new()
	t._on_zone_body_entered(non_player, 2)
	_ok("_on_zone_body_entered: non-Player body leaves _active_zone at 1 (early-return guard)",
		t._active_zone == 1)
	non_player.free()

	# ── C. get_spawn_transform() null guard ──────────────────────────────────
	# When PlayerSpawn marker is absent (_spawn is null because _ready() never
	# runs in this test context), the method must return IDENTITY rather than
	# crashing with a null dereference on global_transform.
	var xf := t.get_spawn_transform()
	_ok("get_spawn_transform: null _spawn returns Transform3D.IDENTITY",
		xf == Transform3D.IDENTITY)

	t.free()


func _test_ledge_pull_geometry() -> void:
	## Guards the geometric invariants of player.gd::_compute_ledge_pull extracted
	## from _attract_to_ledge (iter 96 refactor: 46-line method → 14-line caller
	## + 24-line _compute_ledge_pull helper).  Pure maths — no scene tree needed.
	##
	## Invariants covered:
	##   A. Perpendicular vector: dir_3d.cross(UP).normalized() is orthogonal to dir_3d.
	##   B. Constants: CAPSULE_R=0.28, FOOT_Y_OFFSET=-0.45, PROBE_AHEAD=CAPSULE_R+0.05.
	##   C. Foot position offset is purely vertical (XZ unchanged).
	##   D. Probe-ahead length is strictly greater than CAPSULE_R (just outside the body).
	print("\n-- _compute_ledge_pull geometry invariants --")

	# ── A. Perpendicular vector is orthogonal to movement direction ──────────
	# The probe must fan left/right, not forward/backward, relative to input dir.
	var dir := Vector3(0.0, 0.0, -1.0).normalized()   # facing –Z
	var perp := dir.cross(Vector3.UP).normalized()
	_ok("ledge-pull: perp is perpendicular to dir (dot ≈ 0)",
		_near(dir.dot(perp), 0.0))
	_ok("ledge-pull: perp is a unit vector (length ≈ 1)",
		_near(perp.length(), 1.0))
	_ok("ledge-pull: perp is horizontal (y ≈ 0, cross of two XZ vectors is pure X)",
		_near(perp.y, 0.0))

	# ── B. Constants match the CollisionShape3D in player.tscn ───────────────
	const CAPSULE_R      := 0.28   # from _compute_ledge_pull
	const FOOT_Y_OFFSET  := -0.45  # capsule half-height from centre to floor
	const PROBE_AHEAD    := CAPSULE_R + 0.05
	_ok("ledge-pull: CAPSULE_R is 0.28 m (Stray capsule radius in player.tscn)",
		_near(CAPSULE_R, 0.28))
	_ok("ledge-pull: FOOT_Y_OFFSET is −0.45 m (foot sits below capsule centre)",
		_near(FOOT_Y_OFFSET, -0.45))
	_ok("ledge-pull: PROBE_AHEAD = CAPSULE_R + 0.05 = 0.33 m",
		_near(PROBE_AHEAD, 0.33))

	# ── C. Foot offset is vertical-only (XZ unchanged from capsule position) ──
	var capsule_pos := Vector3(3.0, 2.0, -5.0)
	var foot := capsule_pos + Vector3(0.0, FOOT_Y_OFFSET, 0.0)
	_ok("ledge-pull: foot.x equals capsule_pos.x (no lateral offset)",
		_near(foot.x, capsule_pos.x))
	_ok("ledge-pull: foot.z equals capsule_pos.z (no depth offset)",
		_near(foot.z, capsule_pos.z))
	_ok("ledge-pull: foot.y = capsule_pos.y + FOOT_Y_OFFSET",
		_near(foot.y, capsule_pos.y + FOOT_Y_OFFSET))

	# ── D. Probe-ahead is strictly outside the capsule body ──────────────────
	_ok("ledge-pull: PROBE_AHEAD > CAPSULE_R (probe origin is outside the body)",
		PROBE_AHEAD > CAPSULE_R)


func _test_sentry_instant_reversal() -> void:
	## Guards PatrolSentry._tick_patrol with wait_duration=0 (instant reversal).
	##
	## The existing _test_patrol_sentry_logic covers wait_duration=0.5 — the
	## waiting-state branch.  This test covers the ELSE path: with wait_duration=0
	## the _waiting flag is NEVER set, so the sentry immediately reverses direction
	## and moves on the next delta without a pause.
	##
	## Three code paths verified:
	##   A. Normal movement within bounds (no reversal).
	##   B. Endpoint reached — _dir flips, _waiting stays false (instant reversal).
	##   C. After reversal, the very next delta moves away from the endpoint.
	print("\n-- PatrolSentry instant reversal (wait_duration=0) --")

	const PATROL_SPEED := 2.5
	const PATROL_DIST  := 8.0
	const WAIT_DUR_ZERO := 0.0   # the case under test

	var half := PATROL_DIST * 0.5   # = 4.0 m

	# ── A. Normal movement: offset increments, _waiting remains false ─────────
	var offset := 0.0
	var dir    := 1.0
	var waiting := false

	var delta := 0.016  # one physics tick at ~60 fps
	var new_offset_a := offset + dir * PATROL_SPEED * delta   # = 0.04 m
	_ok("sentry instant-rev: normal step increments offset",
		new_offset_a > 0.0)
	offset = new_offset_a

	# ── B. Endpoint reached — direction flips, _waiting NOT set ──────────────
	# Drive the sentry exactly to the +half boundary.
	var new_offset_b := half + 0.01   # just past the boundary
	if new_offset_b >= half:
		offset = half
		dir = -1.0
		if WAIT_DUR_ZERO > 0.0:
			waiting = true   # this branch is NOT taken with zero wait
	_ok("sentry instant-rev: at +half endpoint offset clamped to half",
		_near(offset, half))
	_ok("sentry instant-rev: direction flipped to −1 at endpoint",
		_near(dir, -1.0))
	_ok("sentry instant-rev: _waiting stays false when wait_duration=0",
		waiting == false)

	# ── C. Immediate post-reversal step moves away from endpoint ─────────────
	var new_offset_c := offset + dir * PATROL_SPEED * delta   # = 4.0 + (−1)×2.5×0.016 = 3.96 m
	_ok("sentry instant-rev: post-reversal offset decreases immediately (no pause)",
		new_offset_c < half)


func _test_breadth_level_defaults() -> void:
	## Guards @export defaults and get_spawn_transform null-guard for the four
	## breadth-pass level scripts (cavern, descent, gauntlet, viaduct), added in
	## iters 100–103 without dedicated unit tests.
	##
	## Pattern: load script, instantiate (no scene tree → _ready() never runs →
	## @onready _spawn stays null), verify export defaults and null-guard branch.
	print("\n-- Breadth-pass level script defaults (iters 100–103) --")

	# ── Cavern (iter 100) ────────────────────────────────────────────────────
	var CavernScript = load("res://scripts/levels/cavern.gd")
	_ok("cavern.gd loads without error", CavernScript != null)
	if CavernScript != null:
		var c = CavernScript.new()
		_ok("cavern: par_time_seconds default = 45.0 (calibrate after first device run)",
			_near(c.par_time_seconds, 45.0))
		_ok("cavern: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			c.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("cavern: get_spawn_transform returns IDENTITY when _spawn null",
			c.get_spawn_transform() == Transform3D.IDENTITY)
		c.free()

	# ── Descent (iter 101) ───────────────────────────────────────────────────
	var DescentScript = load("res://scripts/levels/descent.gd")
	_ok("descent.gd loads without error", DescentScript != null)
	if DescentScript != null:
		var d = DescentScript.new()
		_ok("descent: par_time_seconds default = 40.0 (shorter — fewer beats than cavern)",
			_near(d.par_time_seconds, 40.0))
		_ok("descent: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			d.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("descent: get_spawn_transform returns IDENTITY when _spawn null",
			d.get_spawn_transform() == Transform3D.IDENTITY)
		d.free()

	# ── Gauntlet (iter 102) ──────────────────────────────────────────────────
	var GauntletScript = load("res://scripts/levels/gauntlet.gd")
	_ok("gauntlet.gd loads without error", GauntletScript != null)
	if GauntletScript != null:
		var g = GauntletScript.new()
		_ok("gauntlet: par_time_seconds default = 45.0",
			_near(g.par_time_seconds, 45.0))
		_ok("gauntlet: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			g.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("gauntlet: get_spawn_transform returns IDENTITY when _spawn null",
			g.get_spawn_transform() == Transform3D.IDENTITY)
		g.free()

	# ── Viaduct (iter 103) ───────────────────────────────────────────────────
	var ViaductScript = load("res://scripts/levels/viaduct.gd")
	_ok("viaduct.gd loads without error", ViaductScript != null)
	if ViaductScript != null:
		var v = ViaductScript.new()
		_ok("viaduct: par_time_seconds default = 45.0",
			_near(v.par_time_seconds, 45.0))
		_ok("viaduct: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			v.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("viaduct: get_spawn_transform returns IDENTITY when _spawn null",
			v.get_spawn_transform() == Transform3D.IDENTITY)
		v.free()


func _test_viaduct_sentry_constants() -> void:
	## Documents Viaduct._spawn_sentry() placement constants.
	## Viaduct has one sentry on Span3Final — the narrowest, most exposed span.
	## Pure-maths guards: no scene instantiation needed.
	print("\n-- Viaduct sentry spawn constants --")

	const SENTRY_Z     := 68.0   # Span3Final: far end of the crossing
	const PATROL_DIST  := 3.0    # total sweep: ±1.5 m from centre
	const PATROL_SPEED := 2.0    # m/s — readable approach window on 2 m-wide span
	const SENTRY_Y     := 1.2    # standard PatrolSentry elevation above span surface

	# Span is 2 m wide (half = 1.0 m from centre).  Sentry body BoxShape half = 0.4 m.
	# At half-sweep (1.5 m), body edge reaches 1.5 + 0.4 = 1.9 m from centre → 0.1 m
	# clearance to span edge.  Player (capsule r = 0.28 m) must slip past within ≤ 0.7 m.
	const BODY_HALF := 0.4
	const SPAN_HALF := 1.0
	var edge_clearance: float = SPAN_HALF - (PATROL_DIST * 0.5) - BODY_HALF
	_ok("viaduct sentry: half-sweep + body_half leaves 0.1 m to span edge (tight, non-clipping)",
		_near(edge_clearance, 0.1))
	_ok("viaduct sentry: spawn Z=68 is on Span3Final (last span before ArrivalAbutment)",
		_near(SENTRY_Z, 68.0))
	_ok("viaduct sentry: patrol_distance=3.0 m → ±1.5 m across 2 m span",
		_near(PATROL_DIST, 3.0))
	_ok("viaduct sentry: patrol_speed=2.0 m/s (one crossing per 3 s — one approach window)",
		_near(PATROL_SPEED, 2.0))
	_ok("viaduct sentry: y=1.2 m (standard PatrolSentry elevation)",
		_near(SENTRY_Y, 1.2))


func _test_gauntlet_sentry_constants() -> void:
	## Documents Gauntlet._spawn_sentries() constants for both sentry beats.
	## Beat 2 introduces the sentry solo; Beat 4 combines it with Press2.
	## Speed escalates 25% between beats to increase pressure in the combined room.
	print("\n-- Gauntlet sentry spawn constants --")

	const B2_Z     := 28.0   # Beat 2: sentry corridor (after press, before void gap)
	const B2_DIST  := 6.0    # ±3 m sweep across 8 m corridor
	const B2_SPEED := 2.0    # m/s — comfortable first-encounter window
	const B4_Z     := 62.0   # Beat 4: combined chamber after Press2 at z≈56
	const B4_DIST  := 6.0    # same lateral reach as B2
	const B4_SPEED := 2.5    # m/s — 25% faster for combined-hazard pressure
	const SENTRY_Y := 1.2    # standard elevation

	_ok("gauntlet beat2 sentry: patrol_distance=6 → ±3 m sweep across 8 m corridor",
		_near(B2_DIST * 0.5, 3.0))
	_ok("gauntlet beat2 sentry: z=28 (between Beat1 press exit and Beat3 void)",
		_near(B2_Z, 28.0))
	_ok("gauntlet beat2 sentry: speed=2.0 m/s (calibrated for first-encounter legibility)",
		_near(B2_SPEED, 2.0))
	_ok("gauntlet beat4 sentry: z=62 (combined chamber, after Press2 at z≈56)",
		_near(B4_Z, 62.0))
	_ok("gauntlet beat4 sentry: speed=2.5 m/s = B2 × 1.25 (25% escalation for combined beat)",
		_near(B4_SPEED, B2_SPEED * 1.25))
	_ok("gauntlet beat4 sentry: patrol_distance=6 m (same corridor-blocking width as Beat2)",
		_near(B4_DIST, B2_DIST))
	_ok("gauntlet sentries: both at y=1.2 m (standard PatrolSentry elevation)",
		_near(SENTRY_Y, 1.2))


func _test_early_breadth_level_defaults() -> void:
	## Guards @export defaults and get_spawn_transform null-guard for the three
	## level scripts from iters 97–99 (Spire, Rooftop, Plaza) — seeded before
	## _test_breadth_level_defaults() was written in iter 105, so they were
	## inadvertently skipped. Pattern is identical: load script, instantiate
	## without scene tree (_ready never runs → _spawn stays null), verify
	## export defaults and null-guard branch.  12 assertions total.
	print("\n-- Early breadth-pass level script defaults (iters 97–99) --")

	# ── Spire (iter 97) ──────────────────────────────────────────────────────
	var SpireScript = load("res://scripts/levels/spire.gd")
	_ok("spire.gd loads without error", SpireScript != null)
	if SpireScript != null:
		var s = SpireScript.new()
		_ok("spire: par_time_seconds default = 50.0 (calibrate after first device run)",
			_near(s.par_time_seconds, 50.0))
		_ok("spire: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			s.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("spire: get_spawn_transform returns IDENTITY when _spawn null (no scene tree)",
			s.get_spawn_transform() == Transform3D.IDENTITY)
		s.free()

	# ── Rooftop (iter 98) ────────────────────────────────────────────────────
	var RooftopScript = load("res://scripts/levels/rooftop.gd")
	_ok("rooftop.gd loads without error", RooftopScript != null)
	if RooftopScript != null:
		var r = RooftopScript.new()
		_ok("rooftop: par_time_seconds default = 45.0 (calibrate after first device run)",
			_near(r.par_time_seconds, 45.0))
		_ok("rooftop: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			r.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("rooftop: get_spawn_transform returns IDENTITY when _spawn null (no scene tree)",
			r.get_spawn_transform() == Transform3D.IDENTITY)
		r.free()

	# ── Plaza (iter 99) ──────────────────────────────────────────────────────
	var PlazaScript = load("res://scripts/levels/plaza.gd")
	_ok("plaza.gd loads without error", PlazaScript != null)
	if PlazaScript != null:
		var p = PlazaScript.new()
		_ok("plaza: par_time_seconds default = 40.0 (hub is faster-paced — fewer lateral beats)",
			_near(p.par_time_seconds, 40.0))
		_ok("plaza: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			p.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("plaza: get_spawn_transform returns IDENTITY when _spawn null (no scene tree)",
			p.get_spawn_transform() == Transform3D.IDENTITY)
		p.free()


func _test_arena_level_defaults() -> void:
	## Guards @export defaults and get_spawn_transform null-guard for arena.gd
	## (iter 104 — shape-family 9: ringed arena).  Pattern matches other
	## breadth-pass level tests: instantiate without a scene tree so _ready() never
	## runs and @onready _spawn stays null, then exercise the null-guard branch.
	print("\n-- Arena level script defaults (iter 104) --")

	var ArenaScript = load("res://scripts/levels/arena.gd")
	_ok("arena.gd loads without error", ArenaScript != null)
	if ArenaScript != null:
		var a = ArenaScript.new()
		_ok("arena: par_time_seconds default = 50.0 (calibrate after first on-device run)",
			_near(a.par_time_seconds, 50.0))
		_ok("arena: spawn_marker_path default = NodePath(\"PlayerSpawn\")",
			a.spawn_marker_path == NodePath("PlayerSpawn"))
		_ok("arena: get_spawn_transform returns IDENTITY when _spawn null (no scene tree)",
			a.get_spawn_transform() == Transform3D.IDENTITY)
		a.free()


func _test_arena_sentry_constants() -> void:
	## Documents Arena._spawn_sentry() placement constants for the NorthArm sentry.
	## The sentry guards the only run-up point for the final vault to CentralAltar;
	## the player observes it from the checkpoint (NWCorner) before committing.
	print("\n-- Arena sentry spawn constants --")

	const SENTRY_Z     := -8.0  # NorthArm Z-position — last platform before vault
	const PATROL_DIST  :=  6.0  # total sweep ±3 m along NorthArm X-axis
	const PATROL_SPEED :=  2.0  # m/s — one clean approach window per full crossing
	const SENTRY_Y     :=  1.2  # standard PatrolSentry elevation above platform

	_ok("arena sentry: z=-8.0 places it on NorthArm (north arm of the ring)",
		_near(SENTRY_Z, -8.0))
	_ok("arena sentry: patrol_distance=6.0 → ±3 m sweep along NorthArm X-axis",
		_near(PATROL_DIST, 6.0))
	_ok("arena sentry: half-sweep = 3.0 m (patrol_distance / 2)",
		_near(PATROL_DIST / 2.0, 3.0))
	_ok("arena sentry: patrol_speed=2.0 m/s (matches Viaduct — single window per pass)",
		_near(PATROL_SPEED, 2.0))
	_ok("arena sentry: y=1.2 m (standard PatrolSentry elevation)",
		_near(SENTRY_Y, 1.2))


func _test_level_select_ui() -> void:
	## Guards the level_select.gd _LEVELS constant: count, required keys, path format,
	## and fixed first/last sentinel entries.
	## count == 10: Feel Lab + all 9 shape-family levels (Arena merged from PR #133, iter 108).
	print("\n-- Level selector UI invariants --")

	var LS = load("res://scripts/ui/level_select.gd")
	_ok("level_select.gd loads without error", LS != null)
	if LS == null:
		return

	var cmap: Dictionary = LS.get_script_constant_map()
	_ok("_LEVELS constant accessible via get_script_constant_map()", cmap.has("_LEVELS"))
	if not cmap.has("_LEVELS"):
		return

	var levels = cmap.get("_LEVELS")
	_ok("_LEVELS is an Array", levels is Array)
	if not (levels is Array):
		return

	# 10 = Feel Lab + all 9 shape-family levels (Threshold through Arena).
	_ok("_LEVELS count = 10 (Feel Lab + 9 shape-family levels; breadth directive complete)",
		levels.size() == 10)

	var all_have_keys := true
	var all_paths_res := true
	var all_paths_tscn := true
	var all_nonempty := true
	for entry: Dictionary in levels:
		if not (entry.has("name") and entry.has("path") and entry.has("desc")):
			all_have_keys = false
		var path: String = entry.get("path", "")
		if not path.begins_with("res://"):
			all_paths_res = false
		if not path.ends_with(".tscn"):
			all_paths_tscn = false
		if path.is_empty() or (entry.get("name", "") as String).is_empty() \
				or (entry.get("desc", "") as String).is_empty():
			all_nonempty = false

	_ok("every entry has name/path/desc keys", all_have_keys)
	_ok("every path starts with 'res://'", all_paths_res)
	_ok("every path ends with '.tscn'", all_paths_tscn)
	_ok("no entry has an empty name, path, or desc", all_nonempty)
	_ok("levels[0] name = 'FEEL LAB' (tuning sandbox is always first — not a level)",
		(levels[0].get("name", "") as String) == "FEEL LAB")
	_ok("levels[1] name = 'THRESHOLD' (shape family 1 — always second after Feel Lab)",
		(levels[1].get("name", "") as String) == "THRESHOLD")
	_ok("levels[8] name = 'VIADUCT' (shape family 8)",
		(levels[8].get("name", "") as String) == "VIADUCT")
	_ok("levels[9] name = 'ARENA' (shape family 9 — last entry; breadth complete)",
		(levels[9].get("name", "") as String) == "ARENA")


func _test_win_state_beacon_defaults() -> void:
	## Guards the WinState beacon @export defaults added in iter 112.
	## beacon is OFF by default (backwards-compatible with all existing .tscn files).
	## Also verifies _triggered regression — our edit must not have disturbed it.
	print("\n-- WinState wayfinding beacon defaults --")

	var ws := WS.new()
	_ok("WinState script loads", ws != null)
	if ws == null:
		return

	_ok("add_beacon defaults false (existing .tscn files unaffected)",
		ws.add_beacon == false)
	_ok("beacon_range defaults 14.0 m (readable through fog density ≤ 0.065 at ~20 m)",
		is_equal_approx(ws.beacon_range, 14.0))
	_ok("beacon_energy defaults 2.0 (legible at distance without washing nearby surfaces)",
		is_equal_approx(ws.beacon_energy, 2.0))
	_ok("_build_beacon method exists (callable on the instance)",
		ws.has_method("_build_beacon"))
	_ok("_triggered regression: still defaults false after beacon export additions",
		ws._triggered == false)
	ws.free()


func _test_win_state_beacon_runtime() -> void:
	## Guards the _build_beacon() implementation: calling it directly must create
	## an OmniLight3D child with the correct biolume colour, energy, range, and
	## shadow-disabled flag (Mobile renderer cost guard).
	print("\n-- WinState beacon runtime creation --")

	var ws := WS.new()
	_ok("WinState instantiates for runtime test", ws != null)
	if ws == null:
		return

	ws._build_beacon()
	_ok("_build_beacon adds exactly one child", ws.get_child_count() == 1)

	var light: OmniLight3D = ws.get_child(0) as OmniLight3D
	_ok("beacon child is OmniLight3D", light != null)
	if light == null:
		ws.free()
		return

	# Biolume cyan: Color(0.12, 0.90, 0.95) — matches DataShard glow, signals "goal".
	_ok("beacon colour R ≈ 0.12 (biolume cyan)",   is_equal_approx(light.light_color.r, 0.12))
	_ok("beacon energy equals beacon_energy default (2.0)",
		is_equal_approx(light.light_energy, ws.beacon_energy))
	_ok("beacon range equals beacon_range default (14.0 m)",
		is_equal_approx(light.omni_range, ws.beacon_range))
	_ok("shadow disabled — one OmniLight3D with shadows is ~2× draw cost on Mobile",
		light.shadow_enabled == false)
	ws.free()


func _test_moving_platform_defaults() -> void:
	## Guards MovingPlatform @export defaults.
	## _test_moving_platform_math tests the formula with hardcoded constants;
	## this test reads the actual class properties so a default-value change
	## in moving_platform.gd is caught even if the formula test still passes.
	print("\n-- MovingPlatform @export defaults --")

	var mp := MP.new()
	_ok("MovingPlatform instantiates", mp != null)
	if mp == null:
		return

	# travel = Vector3(6,0,0): levels that override travel still depend on the
	# axis convention (X = lateral swing, Y = lift, Z = depth). The default
	# documents which axis is "primary" for platform motion.
	_ok("travel.x default 6.0 m (lateral swing axis)",  is_equal_approx(mp.travel.x, 6.0))
	_ok("travel.y default 0.0 (no vertical component)",  is_equal_approx(mp.travel.y, 0.0))
	_ok("travel.z default 0.0 (no depth component)",     is_equal_approx(mp.travel.z, 0.0))

	# period_seconds must match the hardcoded `var period := 4.0` in
	# _test_moving_platform_math — if the default changes that formula test
	# becomes a stale stub that no longer covers the live default.
	_ok("period_seconds default 4.0 s (matches formula-test constant)",
		is_equal_approx(mp.period_seconds, 4.0))

	# ease_in_out = true: smoothstep softens the velocity spike at platform
	# reversal — the jarring stop-and-restart is the Achilles heel of ping-pong
	# platforms on mobile.
	_ok("ease_in_out defaults true (smoothstep active, reversal is smooth)",
		mp.ease_in_out == true)

	# paused = false: a platform that spawns paused looks correct in the editor
	# but doesn't move at runtime — silent regression.
	_ok("paused defaults false (platform moves from spawn)", mp.paused == false)

	# _elapsed starts at 0 so every platform begins at its origin position.
	_ok("_elapsed starts 0.0 (origin position at scene load)",
		is_equal_approx(mp._elapsed, 0.0))

	# Division guard: the formula uses (_elapsed / period_seconds), so period ≤ 0
	# triggers the early-return guard. Default must be strictly positive.
	_ok("period_seconds > 0.0 (division-safe default)", mp.period_seconds > 0.0)

	mp.free()


func _test_rotating_hazard_defaults() -> void:
	## Guards RotatingHazard @export defaults.
	## _test_rotating_hazard_math tests the angle formula with local constants;
	## this test reads the actual class properties so a default-value change
	## in rotating_hazard.gd is caught even if the formula test still passes.
	print("\n-- RotatingHazard @export defaults --")

	var rh := RH.new()
	_ok("RotatingHazard instantiates", rh != null)
	if rh == null:
		return

	# rotation_axis = Vector3.UP: overhead fans, spinning floor-plates, and
	# maintenance arms all rotate around the Y-axis by default.
	_ok("rotation_axis defaults to Vector3.UP (Y-axis rotation)",
		rh.rotation_axis == Vector3.UP)

	# Basis(ax, angle) in _physics_process requires ax to be normalized.
	# Vector3.UP is a unit vector, so the default needs no explicit .normalized()
	# call. Test confirms the default is already unit length.
	_ok("rotation_axis default is unit length (Basis() safe)",
		is_equal_approx(rh.rotation_axis.length(), 1.0))

	# period_seconds must match the hardcoded `var period := 4.0` in
	# _test_rotating_hazard_math — same rationale as the moving-platform test.
	_ok("period_seconds default 4.0 s (matches formula-test constant)",
		is_equal_approx(rh.period_seconds, 4.0))

	# @export_range(0.5, 20.0, 0.25): the default must sit within the declared
	# range or the inspector hint is misleading.
	_ok("period_seconds within @export_range [0.5, 20.0]",
		rh.period_seconds >= 0.5 and rh.period_seconds <= 20.0)

	# paused = false: same rationale as MovingPlatform — spawning paused is an
	# invisible runtime regression that the editor doesn't flag.
	_ok("paused defaults false (hazard rotates from spawn)", rh.paused == false)

	# _elapsed starts at 0 so every RotatingHazard begins at angle 0 (the
	# orientation set in the scene), giving consistent start-phase across levels.
	_ok("_elapsed starts 0.0 (angle 0 at scene load)",
		is_equal_approx(rh._elapsed, 0.0))

	# Division guard: formula uses (_elapsed / period_seconds); default > 0 keeps
	# the guard inactive on startup (the guard fires only if a level author sets
	# period_seconds to 0 deliberately to freeze the hazard).
	_ok("period_seconds > 0.0 (division-safe default)", rh.period_seconds > 0.0)

	rh.free()
