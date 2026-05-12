# PLAN — Project Void

Rolling work plan. Each iteration reads this first, picks the highest-ranked
item it can advance, and updates the queue at the end. The README's "Open
questions waiting on you" is the human-facing twin of the **Blocked / needs
human** section below.

---

## Current gate

**Gate 0 — Feel Lab** (closing out; on-device verified 2026-05-12).
**Gate 1 — Vertical Slice** prep is in flight: Threshold picked as the first level
to build; double-jump is approved as an expected mechanic and levels should be
authored with it in mind.

## Active iteration

- _No iteration currently in flight._ Iter 52 (double jump) landed 2026-05-12 — see
  Recently completed.
- Next iteration should pull from the top of the P0 queue below: **Feel Lab expansion**.
  Throttle: **1** (1 iteration since last human direction session 2026-05-12).

## Queue (ranked, top is next)

The next iteration should pull from the top of this list. Items marked
"P0" advance Gate 0 directly; "P1" is supporting; "P2" is opportunistic.

### P0 — Gate 0 close-out + Gate 1 prep

1. ~~**On-device smoke test.**~~ Done 2026-05-12. Project runs in Godot 4.6 on PC
   and deploys to Nothing Phone 4(a) Pro. Feel Lab reports 144 fps / 6.9 ms in
   editor at 1920×1080. ANDROID.md gaps remaining: headless CI signing via env
   vars, release Play Store build (both gate-locked to ship).
2. ~~**Camera vertical-follow ratchet.**~~ Done 2026-05-12 (PR #65) plus three
   on-device feel follow-ups on 2026-05-13: reference-floor smoothing (#67),
   track-down when falling below reference (#68), peak-jitter headroom via
   apex multiplier 1.0 → 1.15 (#69). Camera now holds Y on normal jumps,
   eases up/down to new tiers, follows falls immediately, and ignores Jolt
   jitter at peak. Dev-menu sliders: Apex multiplier, Floor smoothing, Floor
   snap threshold.
3. ~~**Snappy `max_speed` 6.5 → 6.0.**~~ Done 2026-05-12 (PR #66). Preserves
   the `floaty < snappy` cross-profile test invariant (Floaty 5.5 < Snappy
   6.0 < Momentum 11.0). Expect further small tweaks as level design
   progresses.
4. ~~**Double jump implementation.**~~ Done 2026-05-12 (iter 52). Three new
   `ControllerProfile` props (`air_jumps: int`, `air_jump_velocity_multiplier`,
   `air_jump_horizontal_preserve`), player.gd `_air_jumps_remaining` counter,
   dev menu sliders (Air jumps / Air jump vel × / Air jump H pres.), 17 unit
   tests. All profiles default 0 = off (backwards-compatible). See DECISIONS.md
   2026-05-12 ADR.
5. **Feel Lab expansion + interaction variety.** _Next up._ Add higher tiers (to
   exercise the vertical-follow ratchet and double jump), wall-jump corner, varied
   slopes, narrow ledges over fog, a drop-test pit, and a wider open area.
   Becomes the playground for double jump and air dash tuning.
   Brutalist primitives, no new art.
6. **Air dash implementation.** Research-ready in
   `docs/research/air_dash.md`. Three new `ControllerProfile` params
   (default 0 = off, backwards-compatible), right-zone swipe input via
   TouchInput, dev menu sliders, unit tests. Test alongside double jump
   in the expanded Feel Lab.
7. **Threshold greybox.** First Gate 1 level. Double jump now available for
   level design. Five beats per `docs/levels/threshold.md` (habitation →
   maintenance → industrial contrast). Build geometry, place `CameraHint`
   beats, drop in collectible + win state stubs.
8. **Assisted profile Phase 2.** Phase 1 (sticky landing) shipped iter 27.
   Phase 2 (ledge magnetism + arc assist) approved by human as a heavy-
   impact game-feel mechanic — build it after #5 / #6 are validated on
   device. See `docs/research/assist_mechanics.md` for implementation
   sketches.

### P1 — Supporting

- ~~**Controller kinematics unit tests.**~~ Done (iter 7).
  `tests/test_controller_kinematics.gd` + `tests/test_runner.tscn`.
  Standalone (no GUT dependency): open test_runner.tscn, F5, read Output
  panel. Covers: profile defaults, jump height, gravity band ordering,
  jump cut, horizontal interpolation, air damping, terminal velocity,
  coyote/buffer countdown, cross-profile invariants (~40 assertions).
  GUT migration: rename `_ready` → `before_all`, `_test_*` → `test_*`.
- ~~**Greybox `scenes/levels/style_test.tscn`.**~~ Done (iter 8).
  `scenes/levels/style_test.tscn` + `scripts/levels/style_test.gd`.
  Compact display room: 20×20 floor (mat_concrete_dark), standard platform
  at (4, 0.25, −2), wall panel at (−4, 2, −2), scale pillar at (6, 4, −7).
  Identical fog + lighting to Feel Lab. Walk the Stray around to answer the
  5 ART_PIPELINE.md fidelity questions when a real asset arrives.
- ~~Research notes: Mario Odyssey / Demon Turf / A Hat in Time / Pseudoregalia~~
  Done (iter 4): `docs/research/character_controllers.md`.
- ~~**Concrete material kit — materials.**~~ Done (iter 6).
  `resources/materials/mat_concrete.tres` (light, albedo 0.55/0.55/0.58,
  rough 0.85) and `mat_concrete_dark.tres` (albedo 0.32/0.32/0.35,
  rough 0.9) extracted from feel_lab.tscn inline sub_resources to
  standalone ext_resources. feel_lab.tscn updated. **Remaining:**
  `scenes/levels/kit/` prebuilt platform scenes using these materials —
  deferred to a later iter once art direction is roughed in (human gated).
- ~~Wire the player's `controller_param_changed` signal~~ — confirmed
  the dev menu overlay mutates the live profile resource directly via
  `_current_profile.set(prop, v)` in `_make_profile_slider`. The signal
  is decorative for now (player already reads the resource). No action
  needed until a second consumer appears.
- **Momentum profile speed ramp.** The current Momentum profile uses the
  same code path as Snappy/Floaty. The real ramp mechanic (sustained
  input ramps `current_max_speed` up to a `ramp_max_speed` via a
  `speed_ramp_rate` param + optional Curve) is deferred until the human
  has felt the current approximation on device. Log as debt here.
- **Snappy reboot_duration tuning.** Research note (level_design_references.md)
  recommends ≤ 0.35 s for precision feel (current default 0.5 s is "cinematic").
  Tune after first on-device feel; SMB analysis suggests 0.3–0.35 s. Floaty
  profile may keep 0.5 s. Defer until human confirms Snappy feels right otherwise.

### P2 — Opportunistic

- ~~**Always-on perf HUD.**~~ Done (iter 3). `tools/debug/hud_overlay.gd` —
  corner FPS + frametime display, toggled from dev menu Debug viz section.
- ~~**Godot Mobile renderer performance research.**~~ Done (iter 7, side quest).
  `docs/research/godot_mobile_perf.md` — TBDR architecture, draw call /
  triangle budgets, ASTC, baked lighting rationale, Jolt profiling tips.
  Implications logged there; 8 concrete "Implications for Project Void."
- ~~**Ghost trail prototype research.**~~ Done (iter 10).
  `docs/research/ghost_trail_prototype.md` — SMB trail design intent, four Godot 4
  options (MultiMesh recommended, 1 draw call, 300 instances), GDScript sketch for
  `game.gd` recorder + `GhostTrailRenderer`, alpha-by-recency formula, 6 implications.
  Gate 1 implementation task: wire `Game.player_respawned` → recorder, add
  `GhostTrailRenderer` to the vertical slice level.
- ~~Investigate Godot's Compatibility renderer fallback for very-low-end
  devices.~~ Done (iter 23). `docs/research/compatibility_renderer.md` —
  no switch needed; Compatibility APK is viable at Gate 2+ as a second
  export preset, zero code changes required.
- ~~Investigate signing-key handling via gradle env vars so a future
  Play Store build doesn't require touching the editor settings.~~
  Done (iter 26). `docs/ANDROID.md` "Headless / CI signing" section covers
  Pattern A (env vars, Godot 4.3+) and Pattern B (local.properties + Gradle patch).
- Consider upgrading camera occlusion from point ray to ShapeCast3D
  (capsule) if poke-through is observed in Gate 1 tighter geometry.
- ~~**Gate 1 level concepts.**~~ Done (iter 30). Three candidates in `docs/levels/`:
  `spine.md` (wall-jump column ascent), `lung.md` (ventilation timing chamber),
  `threshold.md` (3-zone contrast study). Human must select one. Greybox follows.
- ~~**Air dash research.**~~ Done (iter 30). `docs/research/air_dash.md` — design
  spec, input mapping, ControllerProfile params, player.gd sketch, TouchInput signal.
  Implementation queued after ghost trails in Gate 1.

## Blocked / needs human

These mirror "Open questions waiting on you" in the README.

- **First asset suggestions for human approval.** Before autonomous asset acquisition
  resumes per CLAUDE.md, the first style-defining picks (Stray mesh, ambient audio
  bed, architecture kit) get an options doc — 3–5 candidates per slot with source,
  licence, and a fidelity-check note against the brutalist palette. After ~3
  confirmed picks, autonomous mode resumes.
- **Ongoing Snappy tuning passes.** Snappy feel is good but will keep getting small
  tweaks as level design progresses. Notes of the form "Snappy felt too X on beat Y"
  drive the next tuning iteration.

## Recently completed (last 5)

- 2026-05-12 — Iteration 52. **Double jump implementation.** Three new
  `ControllerProfile` properties: `air_jumps` (int, 0 = off), `air_jump_velocity_multiplier`
  (float, 0.8 default), `air_jump_horizontal_preserve` (float, 1.0 default = full H-vel
  preservation). `player.gd`: `_air_jumps_remaining` counter reset on `is_on_floor()` and
  on every ground/coyote jump (to refill the pool for the new aerial phase); zeroed on
  `respawn()`. Air-jump branch in `_try_jump()` fires when `buffer > 0`, `coyote = 0`,
  and `remaining > 0`; decrements counter. H-vel scaled by `air_jump_horizontal_preserve`
  at jump moment. Dev menu: three new sliders in Controller — Jump subsection.
  17 unit tests in `_test_double_jump_logic`: 4 profile backwards-compat guards,
  multiplier/preserve defaults, velocity formula, branch priority, counter decrement,
  exhaustion, on-floor reset. Total ~625 → ~642 assertions. On-device pending.

- 2026-05-13 — Iter 51 follow-ups. **Camera vertical-follow feel polish.** Three
  on-device tuning PRs on top of PR #65: (#67) reference floor smooths toward
  player.y at 6/sec (was instant) so tier-change transitions glide instead of
  snap, with an 8 m snap-threshold escape hatch for respawn / very long falls;
  (#68) when player.y falls below reference, effective_y tracks the descent
  immediately rather than waiting for landing — fall-pull also enabled in that
  regime so the camera leads the fall; (#69) `apex_height_multiplier` default
  1.0 → 1.15 to give 15% headroom above the analytic peak, absorbing Jolt's
  capsule-resolution jitter and semi-implicit Euler overshoot that were
  flickering the held/tracking branches at peak. New dev-menu sliders for the
  smoothing rate and snap threshold. Three new DECISIONS.md ADRs covering each
  refinement.

- 2026-05-12 — Iteration 51. **Human direction session.** Gate 0 verified on-device
  (Godot 4.6 PC + Nothing Phone 4(a) Pro deploy). Feel verdict: Snappy is good, drop
  `max_speed` from 6.5 to 6.0 (PR #66). Camera vertical-follow rule: hold Y unless
  above default jump apex or on higher ground (PR #65). Gate 1 level: **Threshold**
  picked first; Lung and Spine queued behind it. Double jump approved as expected
  mechanic. Air dash + Assisted Phase 2 approved for Feel Lab testing. Ghost trail
  on hold (only revisit if game becomes about speedrunning). Snappy
  `reboot_duration` stays at 0.5 s. Asset acquisition workflow: surface options for
  first style-defining picks before autonomous mode resumes. Side fix:
  `tests/test_controller_kinematics.gd` parse error at the squash-math loop —
  `for impact in [...]` → `for impact: float in [...]` (was blocking the test
  runner from loading). Throttle: **RESET** (was HARD-26). Four DECISIONS.md
  entries added (Threshold pick, double jump approved, ghost trail deferred,
  reboot duration kept at 0.5 s).

- 2026-05-12 — Iteration 50. **Game level-path contract tests + Audio bus constant tests.**
  `_test_game_level_path_contract` (7 assertions): documents that `Game.current_level_path` is
  NOT cleared by `reset_run()` or `register_attempt()` — critical Gate 1 invariant (scene
  reloader needs the path to persist across run resets). Tests: write + read-back, reset_run ×2
  across two paths, register_attempt preservation, explicit clear, type-is-String check.
  Side quest: `_test_audio_bus_constants` (5 assertions) — exact StringName values for
  BUS_MASTER/BUS_SFX_PLAYER/BUS_SFX_WORLD/BUS_MUSIC, and all-distinct guard.
  Total: 548 → 560 assertions. Throttle: HARD (26 iterations since human session).

- 2026-05-12 — Iteration 49. **Airborne offset math tests + BLAME! level vocabulary.**
  `_test_airborne_offset_math` (8 assertions) added to `tests/test_controller_kinematics.gd` —
  covers the `_air_offset` rigid-translate invariant in `camera_rig.gd` (only major camera
  mechanism not yet unit tested): offset definition, X/Y/3D rigid translate, zero-delta
  stationarity, offset-after-translate invariant, drag-propagation, sign convention.
  Side quest: `docs/research/blame_level_vocab.md` — four BLAME! spatial archetypes mapped
  to Gate 1 candidates (Structural Wound→Spine, Functional Interior→Lung, Layer Boundary→
  Threshold, Exterior Glimpse→all three); 7 greybox implications. INDEX.md updated.
  Total: 540 → 548 assertions. Throttle: HARD (25 iterations since human session).

- 2026-05-12 — Iteration 48. **PerfBudget particle tracking API fix.**
  `register_particles(n)`, `unregister_particles(n)`, `reset_particles()` added to
  `perf_budget.gd` (refactor-backlog item). Fixes the permanently-false
  `active_particles > ACTIVE_PARTICLES_BUDGET` branch in `over_budget()` — Gate 1 can
  now wire GPUParticles3D nodes via this API and the budget check will actually fire.
  `_test_perf_budget_particle_api` (12 assertions): initial-zero state, additive
  `register_particles`, `unregister_particles` clamp-to-zero invariant, live
  `over_budget()` at the limit (not over) and one above (over), `reset_particles` zeroes
  and clears over-budget, `snapshot()` key presence + value match.
  Total: 528 → 540 assertions. Throttle: HARD (24 iterations since human session).

- 2026-05-12 — Iteration 47. **Apply Android latency mitigations + dev menu state tests.**
  `Input.use_accumulated_input = false` in `touch_overlay.gd::_ready()` — saves 4–8 ms per
  continuous-drag frame (researched in iter 46; this is the implementation). `common/physics_interpolation=true`
  in `project.godot` — smooth 120 Hz display for Nothing Phone test device. Bug fix: `g.free()`
  misplaced in `_test_visual_turn_convergence` moved to `_test_game_autoload_contract`. Side quest:
  `_test_dev_menu_state_machine` (16 assertions) — DevMenu autoload first coverage: juice defaults
  (all ON), debug_viz defaults (perf_hud ON, others OFF), asymmetric unknown-key defaults
  (juice→true, debug→false), state transitions, open/close machine. Total: 512 → 528 assertions.
  Throttle: HARD (23 iterations since human session).

- 2026-05-12 — Iteration 46. **Android input latency research + visual-turn convergence tests.**
  `docs/research/android_input_latency.md` — touch pipeline breakdown (28–70 ms end-to-end),
  Godot `Input.use_accumulated_input = false` recommendation, jump-buffer sizing rationale,
  120 Hz physics interpolation note, Floaty feel diagnostic, juice > platform. INDEX.md updated.
  `_test_visual_turn_convergence` (8 assertions): weight in (0,1) at 60fps, weight==1.0 snap,
  `lerp_angle` direct arc, `lerp_angle` wrap through ±PI boundary, 30-frame convergence < 0.01 rad,
  deadband strict `<` boundary (0.19/0.20/0.21 × 0.2 threshold).
  Total: 504 → 512 assertions. Throttle: HARD (22 iterations since human session).

- 2026-05-12 — Iteration 45. **TouchInput + Game autoload contract tests.**
  `_test_touch_input_state_machine` (11 assertions): set_move_vector limit_length pipeline
  (unit/oversized/zero), set_jump_held 4-state machine (false→false, false→true,
  true→true, true→false), camera drag accumulate-then-clear (add×2→consume→zero).
  `get_move_vector` returns stored vector when non-zero, ~zero in test context.
  `_test_game_autoload_contract` (10 assertions): defaults (attempts=0, run_time_seconds=0.0,
  current_level_path=""), register_attempt() +1/+2, reset_run() zeroes both, plus
  has_signal checks for player_respawned / checkpoint_reached / level_completed.
  Total: 483 → 504 assertions. Throttle: HARD (21 iterations since human session).

- 2026-05-12 — Iteration 44. **Perf budget logic tests + Gate 1 scene lifecycle research.**
  `_test_perf_budget_logic` (8 assertions): reads PB constants via preload —
  FRAMETIME_BUDGET_MS==9.0, DRAW_CALL_BUDGET==50, TRIANGLE_BUDGET==80 000,
  ACTIVE_PARTICLES_BUDGET>0; OR logic: all-under→false, frametime spike→true,
  draws+1→true, tris+1→true. Mirror helper `_perf_over_budget` uses actual PB
  constants so any drift in perf_budget.gd is caught automatically.
  Side quest: `docs/research/gate1_scene_lifecycle.md` — three reload approaches,
  run-timer in Game autoload (`start_run`/`level_complete`/`_process`), ResultsPanel
  as CanvasLayer overlay (no scene change mid-session), shard tracking, hitch avoidance,
  6 concrete `game.gd` Gate 1 change items. INDEX.md updated.
  Total: 475 → 483 assertions. Throttle: HARD (20 iterations since human session).

- 2026-05-12 — Iteration 43. **Jump arc geometry tests + profile timing window tests.**
  `_test_jump_arc_geometry` (11 assertions): t_apex = jump_velocity/gravity_rising in [0.15,0.90] s
  per profile (4); terminal_velocity > max_speed per profile (4); cross-profile arc ordering:
  Floaty t_apex > Snappy, Floaty > Momentum, Momentum > Snappy (3).
  `_test_profile_timing_windows` (12 assertions): coyote_time and jump_buffer in [0.05,0.30] s
  per profile (8); Floaty coyote ≥ Snappy coyote, Snappy ≥ Momentum (2); same for jump_buffer (2).
  Total: 452 → 475 assertions. Throttle: HARD (19 iterations since human session).

- 2026-05-11 — Iteration 42. **Moving platform triangle-wave tests + camera pub-yaw formula tests.**
  `_test_moving_platform_math` (8 assertions): fmod phase normalization (t=0/half/full-period),
  triangle wave at phase=0→0.0 and phase=0.5→1.0, symmetry triangle(0.25)==triangle(0.75)==0.5,
  smoothstep S-curve slower than linear at 25% of ramp, smoothstep midpoint==0.5.
  `_test_camera_pub_yaw_formula` (8 assertions): four cardinals (+Z→0, +X→π/2, −Z→±π, −X→−π/2),
  diagonal in (0,π/2), Y-independence, distance-independence, four cardinals each π/2 apart.
  Total: 436 → 452 assertions. Throttle: HARD (18 iterations since human session).

- 2026-05-11 — Iteration 41. **Stick dead-zone + tripod distance correction tests.**
  `_test_stick_deadzone_and_clamp` (8 assertions): radial clamp pipeline and truncating dead-zone
  from `touch_overlay.gd` — below-threshold zero, boundary pass-through (strict <), partial/full/
  oversized deflection, direction-through-clamp, rotational symmetry in 8 dirs, output-range invariant.
  `_test_tripod_horiz_distance_correction` (8 assertions): XZ distance maintenance in
  `camera_rig.gd` ground branch — too-far/too-close snap to desired, zero-movement at correct dist,
  Y untouched, direction preserved, single-step convergence, sign of correction.
  Total: 420 → 436 assertions. Throttle: HARD (17 iterations since human session).

- 2026-05-11 — Iteration 40. **Camera hysteresis latch + exponential smoothing tests.**
  `_test_occlusion_release_latch` (8 assertions) + `_test_camera_smoothing_formula` (8 assertions)
  added to `tests/test_controller_kinematics.gd`. Latch: all 4 state transitions, threshold
  boundary (3 × 0.05 s stays; 4th clears), mid-streak hit resets countdown. Smoothing:
  pull_in > ease_out invariant, both smooth_t in (0,1), rate=0 identity, 5-frame comparative
  (pull_in > 85% closed, ease_out > 50% remaining), 10-frame pull_in < 5% remaining.
  Total: 404 → 420 assertions. Throttle: HARD (16 iterations since human session).

- 2026-05-11 — Iteration 39. **Acceleration path selection tests + jump release touch-path tests.**
  `_test_accel_path_selection` (10 assertions) + `_test_jump_release_touch_path` (7 assertions)
  added to `tests/test_controller_kinematics.gd`. Path selection: trigger threshold (0.0 and
  0.005 qualify; 0.01 does not), ground_decel > air_accel per profile, ground_accel > air_accel
  per profile, one-frame comparative (path 1 brakes harder, path 2 picks up faster than path 3).
  Touch release: 4-case truth table + 3 OR-combination cases.
  Total: 387 → 404 assertions. Throttle: HARD (15 iterations since human session).

- 2026-05-11 — Iteration 38. **Jump stretch scale math tests + spark geometry tests.**
  `_test_jump_stretch_scale_math` (9 assertions) + `_test_spark_geometry_math` (12 assertions)
  added to `tests/test_controller_kinematics.gd`. Jump stretch: scale=0 identity, exact values
  at scale=1 (stretch_y=1.30, stretch_xz=0.85), direction invariants, linearity, inversion guard.
  Spark: 12-line count, length bounds (0.18–0.65 m), upward-hemisphere Y bias (0.15–1.6),
  hub offset, warm-yellow palette (R>G>B), fade timing (0.07 s hold + 0.38 s fade).
  Total: 366 → 387 assertions. Throttle: HARD (14 iterations since human session).

- 2026-05-11 — Iteration 37. **Impact factor + land squash scale math tests.**
  `_test_impact_factor_math` (7 assertions) + `_test_land_squash_scale_math` (9 assertions)
  added to `tests/test_controller_kinematics.gd`. Covers: zero-fall-speed → 0.0, half-terminal
  → 0.5, full-terminal → 1.0, overclamp guard, rising-velocity → 0.0, monotonicity,
  scale-invariance; zero-deformation at impact=0 or scale=0, exact values at impact=1 scale=1
  (sq_y=0.55, sq_xz=1.20), direction invariants, linear proportionality.
  Side quest: puff jitter non-overlap assertion in `_puff_geometry_checks` (+1).
  Total: 349 → 366 assertions. Throttle: HARD (13 iterations since human session).

- 2026-05-11 — Iteration 36. **Win state design research + test sub-helper rename.**
  `docs/research/win_state_design.md` — final unresearched Gate 1 prerequisite. SMB/SMB3D
  instant-cut stats with grade system; Dadish 3D star rating + no death count; Celeste
  personal-best delta. Mobile: ≤ 3 s to replay, no mandatory animation, no death count by
  default. Void recommendation: `WinState` Area3D → `Game.level_completed`, results panel
  (time / par comparison / shards), REPLAY = `reset_run()` + reload, post-level ghost trail
  replay deferred. 6 Gate 1 implications: `Game.is_running` flag, `par_time_seconds` in
  level meta, WinState authored last, no death count shown, par drives intrinsic motivation,
  `reset_run()` already exists. INDEX.md updated.
  Side quest: `_test_puff_geometry` → `_puff_geometry_checks`,
  `_test_puff_material_and_fade` → `_puff_material_fade_checks` — naming fix so these
  sub-helpers don't appear to be missed top-level tests. No assertion change (349 total).

- 2026-05-11 — Iteration 35. **Jump puff math unit tests + collectible design research.**
  `_test_jump_puff_math` (18 assertions) added to `tests/test_controller_kinematics.gd`.
  Covers: 8 steps × (TAU/8) = TAU (full revolution), angle_step < PI/2 (non-degenerate),
  i=0 → +X axis, i=4 → opposite hemisphere, length bounds (0.10 < 0.28, both positive, < 1 m),
  Y-kick bounds (≥ 0, > 0, < 1), direction normalisation to unit length, hub offset < length_min,
  material R > G > B (warm-concrete bias), all channels [0,1], hold < fade, hold+fade ≈ 0.20 s,
  total < 0.5 s. Total assertions: 331 → 349.
  Side quest: `docs/research/collectible_design.md` — data shard design (cyan emissive prism,
  Area3D 0.9 m radius, one per level off par-route, `Game` fields `shards_collected`/`shards_total`);
  SMB/Celeste/Odyssey survey; 6 Gate 1 implications. INDEX.md updated.

- 2026-05-11 — Iteration 34. **Jump puff particle effect + enemy archetype research.**
  `_spawn_jump_puff()` called from `_try_jump()` on every successful jump. 8 ImmediateMesh lines
  in `_build_puff_mesh()` — evenly-spaced radial angles, random length 0.10–0.28 m, slight
  upward Y component (0–0.12) so the burst reads as dust lifting off the floor. Warm grey palette
  (0.80/0.77/0.72). `_fade_and_free_puff()`: 0.04 s hold + 0.16 s fade. Gated behind `particles`
  toggle; no dev-menu changes needed. JUICE.md: "Jump puff" → prototype. ~40 lines added.
  Side quest: `docs/research/enemy_archetypes.md` — Gate 1 prerequisite; static kill zone
  (`HazardBody.tscn` with Area3D) recommended for Gate 1 (no AI), patroller deferred to Gate 2;
  palette separation (cold hazards vs Stray red); hitbox generosity guidance for mobile; 6 implications.
  INDEX.md updated.

- 2026-05-11 — Iteration 33. **Squash-stretch animation implementation.**
  `_play_land_squash(impact)` + `_play_jump_stretch()` in `player.gd` (Tween on `$Visual.scale`,
  zero draw-call cost). `_last_fall_speed` tracker added to `_tick_timers` (airborne branch)
  so impact factor is captured the frame before landing (velocity.y is already zeroed by
  move_and_slide on the just_landed frame). `respawn()` kills any in-flight tween + resets
  scale. Two dev-menu sliders via `squash_stretch_param_changed` signal. JUICE.md: Land squish
  + Jump stretch → prototype. Side quest: `_test_squash_stretch_math` (17 assertions, 314 → 331).

- 2026-05-11 — Iteration 32. **Cut-jump + gravity integration tests + squash-stretch research.**
  `_test_cut_jump_behavior` (9 assertions: held-no-cut, released-at-peak→threshold, boundary strict->,
  below-threshold-no-cut, vy=0-no-cut, 4 per-profile peak-to-threshold) +
  `_test_gravity_integration` (8 assertions: single-step formula, monotone arc, apex frames > 1,
  gravity_after_apex > gravity_rising from apex, terminal clamp, floaty apex-frames >= snappy).
  New helpers `_sim_cut` + `_gravity_step`. Net assertions: 297 → 314.
  Side quest: `docs/research/squash_stretch_animation.md` — Tween on $Visual.scale (zero draw-call),
  impact-factor derivation, TRANS_SPRING recovery, reboot-conflict guard (_is_rebooting check),
  integration checklist for implementing iteration. INDEX.md updated.

- 2026-05-10 — Iteration 31. **Sticky landing countdown + damping tests + checkpoint design research.**
  `_test_sticky_landing_countdown` (9 assertions) + `_test_sticky_landing_damping` (8 assertions)
  added to `tests/test_controller_kinematics.gd`; new `_sticky_tick` helper mirrors `_tick_timers`'
  sticky-landing block. Documents tick-by-tick countdown (set on landing, decrement per grounded
  frame, reset on early takeoff, disabled when sticky_frames=0) and per-frame damping formula
  (`speed × (1 − factor)`, geometric series over N frames, both guard conditions). Net: 280 → 297
  assertions. Side quest: `docs/research/checkpoint_design.md` — SMB/Dadish 3D/Celeste models,
  ghost-trail anchor constraint, Void recommendation: Option A for Gate 1 (no mid-level checkpoint,
  CheckPoint node signals only, per-segment trails deferred to Gate 2). INDEX.md updated.

- 2026-05-10 — Iteration 30. **Gate 1 level concepts (Spine / Lung / Threshold) + air dash research.**
  Three Gate 1 candidate levels authored in `docs/levels/`: Spine (5-beat vertical column ascent,
  wall-jump primary, ~60–75 s skilled), Lung (4-beat horizontal timing chamber with moving baffles,
  biolume cyan accent, ~70–80 s skilled), Threshold (5-beat 3-zone contrast study — habitation /
  maintenance / industrial — ~70 s skilled). All follow LEVEL_DESIGN.md workflow through step 5
  (parti, genius loci, double-reading, procession, verbs, par route, skill range, kit requirements,
  greybox notes). **Human must select one before greybox begins.** Side quest: `docs/research/air_dash.md`
  — full design spec (0.18 s burst, single charge, swipe input) + Godot 4 implementation sketch
  (ControllerProfile params, player.gd state, TouchInput signal). INDEX.md updated.

- 2026-05-10 — Iteration 29. **Blob shadow dev menu tunables + math unit tests.**
  `blob_shadow.gd` `@export_range` tunables now live in the dev menu (Juice → Blob Shadow —
  Tuning): 4 sliders for radius_at_ground, radius_at_height, fade_height, alpha_max. New signal
  `blob_shadow_param_changed` in `dev_menu.gd`; `_on_blob_shadow_param_changed` handler in
  `blob_shadow.gd`. Side quest: `_test_blob_shadow_math` (12 assertions: t formula, radius
  linear-lerp monotonicity, quadratic alpha falloff). Net assertions: 268 → 280.

- 2026-05-10 — Iteration 28. **SMB 3D research + blob shadow projector.**
  `docs/research/smb3d.md` — live reference game analysis (released March 2026):
  camera design (fixed per level; "dynamic can't keep up"), level length (20 s skilled),
  ghost trail (core loop, not bonus), depth perception aids (blob shadow, background
  landmarks, 45° geometry, ground circle, 8-directional input), air dash as depth-error
  recovery, style-loss as biggest failure risk. 8 implications for Void, including:
  blob shadow mandatory pre-device-test; airborne rigid translate already aligned with
  SMB 3D's "consistent depth axis" approach; each Void beat should be ~20 s; air dash
  is a Gate 1 candidate. Side quest: `scripts/player/blob_shadow.gd` (depth-perception
  disc shadow; 1 raycast + 1 draw call per frame; radius and alpha scale with height;
  added to `player.tscn`; new `blob_shadow` juice key in dev_menu.gd; JUICE.md updated).

- 2026-05-10 — Iteration 27. **Assisted profile Phase 1.** `assisted.tres` authored;
  sticky landing mechanic added to `player.gd` (`_was_on_floor_last_frame` tracking,
  `_sticky_frames_remaining` countdown in `_tick_timers`, `landing_sticky_factor`
  damping in `_apply_horizontal`); two new `ControllerProfile` properties (both
  default 0 = disabled, backwards-compatible); Assisted added to dev menu as 4th
  dropdown entry with a new "Controller — Assist" subsection (2 sliders).
  Side quest: `_test_try_jump_logic` (12 assertions — buffer×coyote AND condition,
  per-profile vy, timer zeroing, boundary) + `_test_assisted_params` (12 assertions
  — sticky params enabled on Assisted, disabled on others, coyote/buffer ordering).
  Net: 198 → 268 assertions. DECISIONS.md updated. Phase 2 (ledge magnetism + arc
  assist) awaits device feel.

- 2026-05-10 — Iteration 26. Two new test groups: `_test_horizontal_deceleration`
  (11 assertions — decel convergence from max_speed, no-overshoot, momentum-slower-
  than-snappy invariant, rest-at-rest edge case) and `_test_visual_facing_formula`
  (8 assertions — atan2(-vx,-vz) cardinal directions, lerp weight clamp, deadband).
  179 → 198 assertions. Side quest: `docs/ANDROID.md` signing env vars section
  (Pattern A: Godot 4.3+ env vars; Pattern B: local.properties + gradle patch);
  P2 TODO closed.

- 2026-05-10 — Iteration 25. Stale camera test cleanup + tripod model tests.
  Removed `_test_camera_yaw_recenter` and `_test_camera_lookahead_target` (13
  assertions total) — tested `_update_yaw_recenter` and `_update_lookahead` which
  were deleted in the 2026-05-11 tripod camera rewrite. Added `_test_tripod_placement`
  (6 assertions: placement formula y/z/x components, Pythagorean-identity distance
  check, above-horizontal invariant, elevation=0 edge case) and `_test_tripod_drag_orbit`
  (7 assertions: radius/phi derivation from position, pure-yaw orbit sphere invariant,
  pitch lower/upper clamp, _pitch_rad sign). Net assertion count unchanged: 179.
  Side quest: removed dead `pitch_min_degrees` @export from `camera_rig.gd` and
  its dev-menu "Pitch min deg" slider — the drag clamp's lower bound is hardcoded
  to 0.0 in `_apply_drag_input` (camera always stays above horizontal); only
  `pitch_max_degrees` is active. No behaviour change.

- 2026-05-11 — Human-direction session. Camera + UX overhaul on direct
  human input (not an autonomous iteration; PR opened off `main`). (1) Camera
  rewritten to a tripod-style follow (holds world position when player walks
  laterally; only translates along the camera→player axis). (2) Selective
  occlusion: new physics layer 7 = `CameraOccluder`; walls + pillars in
  `feel_lab.tscn` and `style_test.tscn` tagged with `collision_layer = 65`
  (World + CameraOccluder); the camera ignores everything else, so passing
  behind small platforms no longer pulls the camera in. (3) Sphere-cast probe
  (0.22 m default, configurable) replaces the thin raycast — kills frame-to-
  frame hit/miss flicker at wall edges. (4) Asymmetric position smoothing
  (`pull_in_smoothing = 28`, `ease_out_smoothing = 6`) + hysteresis latch
  (`occlusion_release_delay = 0.18 s`) — stops the camera bouncing in/out
  while walking around corners. (5) Airborne rigid translate: while
  `is_on_floor() == false`, the camera position copies the player's per-frame
  delta via a stored `_air_offset` and skips distance maintenance / occlusion
  / smoothing — camera follows the jumping player but does not rotate around
  them, locking the input frame from takeoff to landing. Drag still works
  mid-jump. (6) Dev menu scaled up for thumb use: panel anchored to right
  40% of viewport, full-height scroll; widget heights 64 px; font 24 pt
  applied via Theme; CheckBox toggles replaced with custom Button toggles
  (filled ●/open ○ + green/grey colour swap) since CheckBox icons don't
  follow font_size. (7) Touch overlay: jump button auto-anchors to
  bottom-right with `jump_button_margin`, recomputes on viewport resize;
  CFG_VERSION bumped to 2 to drop stale saves. (8) Lighting: `FillLight`
  (cool blue, energy 0.45, no shadows) added to both test scenes;
  ambient_light_energy 0.4 → 0.75; fog density 0.045 → 0.012 — the player
  is no longer a silhouette against the warm key. (9) Player visual rotates
  to face movement direction (`visual_turn_speed`, `visual_turn_min_speed`).
  (10) Strict-warning cleanup: typed Dictionaries, `@warning_ignore`
  annotations on autoload signals, `call(&"set_camera_yaw")` for the duck-
  typed Player call, `_player: Player` typing in the debug-draw script.
  Snappy max_speed 8 → 6.5 and floaty 6.5 → 5.5 (preserves the
  `floaty < snappy` test invariant). 3 new ADRs in `DECISIONS.md`. All 179
  controller-kinematics tests still pass post-merge.

- 2026-05-10 — Iteration 24. `_test_move_dir_rotation` (8 assertions) +
  `_test_gravity_band_selection` (12 assertions = 4 rules × 3 profiles) added to
  `tests/test_controller_kinematics.gd`. Covers: Basis(UP,yaw) formula at yaw=0,
  PI, PI/2; length preservation (orthogonal rotation invariant); Y=0 invariant;
  over-length guard; gravity band selection (falling → after_apex, rising+held →
  rising, rising+released → falling, apex frame → after_apex). ~137 → ~157 total.
  Side quest: `docs/research/assist_mechanics.md` — concrete Godot 4 implementation
  for ledge magnetism (ShapeCast at jump time, 2 rays), arc assist (20-step parabola
  simulation), sticky landing (2-frame speed reduction), edge-snap (post-slide
  position correction); 6 new ControllerProfile properties (all default 0 = off);
  implementation order; `_landed_this_frame` shared tracker proposal. INDEX.md updated.

- 2026-05-10 — Iteration 23. `_test_camera_yaw_recenter` (9 assertions) added
  to `tests/test_controller_kinematics.gd`. Covers: `wrapf` shortest-path
  rotation (175°→-175° = +10° not -350°; reverse = -10° not +350°), default
  lerp weight plausibility (>0, <0.1), no-overshoot guarantee (step < diff),
  high-speed weight clamp to 1.0, 30-frame convergence monotonicity, and >50%
  progress after 30 frames. ~128 → ~137 assertions.
  Side quest: `docs/research/compatibility_renderer.md` — Mobile vs Compatibility
  feature matrix (all Void features present in Compatibility), per-GPU-tier
  performance expectations (Adreno 506: +20-40%; Adreno 710: -5-15%), visual
  delta analysis (minimal in brutalist-fog aesthetic), recommendation (no switch;
  low-end APK preset viable at Gate 2+). P2 open item closed. INDEX.md updated.

- 2026-05-10 — Iteration 22. Camera pitch V-turn bug fixed: `absf(_pitch)` →
  `-_pitch` in `camera_rig.gd::_desired_camera_position`; clamp upper bound
  changed from `deg_to_rad(absf(pitch_max_degrees))` to `0.0` in
  `_apply_drag_input`. `_pitch` is now always ≤ 0 (camera above horizontal);
  V-shape on upward drag (~128 px to reach 0-crossing at default sensitivity)
  eliminated. Side quest: `_test_camera_pitch_formula` (5 assertions) added to
  `tests/test_controller_kinematics.gd` — documents monotonic elevation invariant.
  DECISIONS.md entry added. ~123 → ~128 assertions.

- 2026-05-10 — Iteration 21. Camera math unit tests: `_test_camera_vertical_pull`
  (6 assertions — rising/stopped→0, falling magnitude, zero-pull, terminal swing),
  `_test_camera_occlude_math` (6 assertions — typical hit, close clamp, margin=hit,
  zero margin, large margin, loop invariant), `_test_camera_lookahead_target`
  (5 assertions — below/above min_speed, diagonal direction, lerp weight clamp).
  +17 assertions total: ~106 → ~123. No behaviour change.
  Side quest: camera pitch V-turn issue added to refactor backlog — `absf(_pitch)`
  in `_desired_camera_position` creates a V-shape when `_pitch` crosses 0 via
  upward drag; reaches 0-crossing in ~128 px of drag at default sensitivity.

- 2026-05-10 — Iteration 20. Test suite expansion: `_test_horizontal_interpolation`,
  `_test_coyote_countdown`, and `_test_buffer_countdown` now loop over all three
  shipped profiles (was Snappy-only, matching iter 11's expansion of jump_cut and
  terminal_velocity). Net +20 assertions: +6 (interpolation, 3 assertions × 3
  profiles), +8 (coyote, 4 assertions × 3 profiles), +6 (buffer, 3 assertions ×
  3 profiles). Total: ~86 → ~106. No behaviour change.
  Side quest: `docs/research/touch_dead_zone_calibration.md` — truncating vs.
  remapping dead zones (formulae), Genshin observations (8–10% inner DZ, 90–95%
  outer DZ, safety band), Sky/Alto notes, HCI sizing guidance. 5 implications:
  current 15% truncating DZ is correct for Gate 0; Floaty may need remapping;
  outer DZ at 93% for sprint ergonomics; camera safety band; DZ belongs in
  touch_overlay not ControllerProfile. INDEX.md updated; Genshin open item closed.

- 2026-05-10 — Iteration 19. `dev_menu_overlay.gd::_build_controller_section` refactor:
  extracted `_build_controller_movement` (13 lines), `_build_controller_jump` (19 lines),
  `_build_controller_respawn` (7 lines), `_build_controller_slope` (5 lines). Dispatcher
  is now 7 lines. Every method in the file is under 40 lines. No behaviour change.
  Side quest: `_test_movement_params()` in `tests/test_controller_kinematics.gd` — 10
  new assertions: `ground_deceleration > 0` and `air_acceleration > 0` per profile;
  speed ordering (Momentum > Snappy, Floaty < Snappy); Momentum zero air-damping;
  Momentum loose-decel (decel < accel). Total assertions: ~76 → ~86.

- 2026-05-10 — Iteration 18. Touch slider display fix + respawn param tests:
  `TouchOverlay._ready()` adds itself to group `"touch_overlay"`.
  `DevMenuOverlay._build_touch_section()` queries that group to read actual
  `jump_button_radius` / `stick_zone_ratio` values as `initial_value` rather
  than hardcoded defaults. Closes refactor backlog item "Touch slider display
  doesn't reflect loaded layout." Side quest: `_test_respawn_params()` in
  `tests/test_controller_kinematics.gd` — reboot_duration range (0, 1.5],
  fall_kill_y sign/range, phase-fraction sum (0.12+0.35+0.35+0.18=1.0).
  +13 assertions, ~76 total. DECISIONS.md updated.

- 2026-05-09 — Iteration 17. `dev_menu_overlay.gd` silent-init fix + holistic level design research:
  `_make_slider` gets `initial_value: float = NAN` param — value is set before callbacks connect,
  so the slider's on_changed is never fired during init. `_make_cam_slider` passes `default_val`
  as `initial_value` (no post-return `.value =`). `_build_touch_section` and `_build_level_section`
  likewise. Touch layout persistence (user://input.cfg) now works correctly for returning users —
  previously the dev menu init overwrote loaded values silently on every startup.
  Side quest: `docs/research/holistic_level_design.md` — Steve Lee GDC 2017 holistic three
  dimensions + GMTK Kishōtenketsu 4-beat arc (Ki/Shō/Ten/Ketsu, ~5 min arc, discard after
  ketsu) + Odyssey density-over-span (compressed verticality, apex always visible). 6 implications
  for Gate 1. INDEX.md updated; open research items for Steve Lee and GMTK marked done.
  PLAN.md refactor backlog: "touch slider display doesn't reflect loaded layout value" added.

- 2026-05-09 — Iteration 16. Camera dev-menu tunables + debug draw perf (primary/side):
  6 camera `@export` params wired to new "Camera — Tuning" dev-menu sub-section
  (`aim_height`, `lookahead_lerp`, `lookahead_min_speed`, `pitch_min/max_degrees`,
  `recenter_min_speed`); `camera_rig.gd::_on_camera_param_changed` gains 6 match arms.
  `player_debug_draw.gd`: `_viz_active: bool` cached via `DevMenu.debug_viz_changed`
  signal; `_process` now returns early after `clear_surfaces()` when all overlays off,
  skipping the scene-tree group search. Hard throttle (16 iterations).

- 2026-05-09 — Iteration 15. `player.gd` respawn timer bug fix + slope tunable (primary):
  `respawn()` zeroes `_buffer_timer` and `_coyote_timer` before the reboot sequence —
  timers don't tick while `_is_rebooting`, so a buffered jump press at death-time would
  survive the full 0.5 s reboot and fire on the first frame back. `floor_max_angle` moved
  to `_physics_process` top so it refreshes every tick; "Controller — Slope / Max floor°"
  slider (20–70°) added to dev menu, registered in `_profile_sliders` for bulk-sync.
  Side quest: `_test_slope_params()` added to kinematics tests — 7 assertions (in-range
  check + floaty ≥ snappy accessibility invariant). ~56 → ~63 total assertions.

- 2026-05-09 — Iteration 14. `dev_menu_overlay.gd` bug fix + refactor (primary):
  Fixed `_on_save_confirmed` — after saving a profile, `OptionButton.selected = n` does
  NOT emit `item_selected`, so `_current_profile` was never updated; added `_select_profile(name)`
  at the end of `_on_save_confirmed` so subsequent slider edits affect the saved copy.
  Extracted 6 UI layout magic numbers to named class constants (`_PANEL_W`, `_SCROLL_H`,
  `_SECTION_SEP`, `_SL_LABEL_W`, `_SL_TRACK_W`, `_SL_TRACK_H`, `_SL_VAL_W`).
  Side quest: Christopher Alexander research note (`docs/research/alexander_pattern_language.md`)
  — parti pris, form synthesis, Pattern Language mapped to Void's level kit, 8 implications
  including parti-per-beat discipline, ≥ 3 forces per beat, compression–release as primary
  procession unit, structural (not decorative) landmarks, kit naming by pattern.

- 2026-05-09 — Iteration 13. `player.gd::_spawn_sparks` method-size refactor (primary):
  was 41 lines, now 15. Extracted `_build_spark_material` (10 lines), `_build_spark_mesh`
  (16 lines), `_fade_and_free_spark` (7 lines). No behaviour change. `_run_reboot_effect`
  (45 lines) remains in the backlog as "leave as-is" per sequential-await constraint.
  Side quest: juice density research note (`docs/research/juice_density.md`) — Astro's
  Playroom "layered receipt" model, SMB sparse-juice contrast, mobile haptics gap, draw-call
  budget per juice type, Gate 1 priority ranking (landing squash first).

- 2026-05-09 — Iteration 12. `touch_overlay.gd` method-size refactor (primary):
  `_handle_repo_input` (62 lines) replaced with lean dispatcher + `_parse_repo_event`,
  `_on_repo_press`, `_on_repo_move`, `_on_repo_release`. `_draw_reposition` (56 lines)
  replaced with lean dispatcher + 7 draw helpers; font-size magic numbers promoted to
  `_REPO_FONT_SM`/`_REPO_FONT_NM` constants. All methods now ≤ 15 lines. No behaviour
  change. Side quest: `DRAW_CALL_BUDGET` in `perf_budget.gd` corrected from 200 to 50
  (per `godot_mobile_perf.md` Gate 1 target). `over_budget()` now flags correctly.

- 2026-05-09 — Iteration 11. `perf_budget.gd` frametime bug fix (primary):
  `last_frametime_ms` was `1000.0 / Engine.get_frames_per_second()` (smoothed,
  hides spikes) → `delta * 1000.0` (actual frame time, catches hitches). Dead code
  removed: `touch_input.gd::set_camera_drag_delta` (never called; stale comment
  claimed it was the touch overlay's entry point but overlay uses
  `add_camera_drag_delta`). Side quest: kinematics tests expanded — `_test_jump_cut_math`
  and `_test_terminal_velocity` now loop over all three profiles (was Snappy only);
  ~40 → ~56 assertions total.

- 2026-05-09 — Iteration 10. `player.gd::_physics_process` refactor (primary):
  79 → 22 lines. Extracted 8 private sub-routines (`_tick_timers`, `_collect_jump_input`,
  `_was_jump_released`, `_camera_relative_move_dir`, `_apply_horizontal`, `_apply_gravity`,
  `_try_jump`, `_cut_jump`). No behaviour change — pure structural refactor; every
  sub-routine is under 40 lines. `_run_reboot_effect` (44 lines, await-chained) noted in
  refactor backlog. Side quest: ghost trail prototype research note
  (`docs/research/ghost_trail_prototype.md`) — SMB trail design, MultiMesh approach sketch,
  GDScript recorder + renderer sketch, 6 implications. INDEX.md updated.
  **Throttle: HARD (10 iterations).**

- 2026-05-09 — Iteration 9. Level design references research note (primary):
  `docs/research/level_design_references.md` — SMB grammar (short focused rooms,
  introduce-then-combine, instant respawn as information, ghost trails as core grammar),
  verticality principles (max 3 floor planes, down=discovery/up=challenge),
  flow/pacing (rhythm groups, rest areas, par-route-first authoring), Mario Odyssey
  density-over-sprawl + expressed-architecture-as-affordance, Kevin Lynch vocabulary
  applied to megastructure levels. 10 concrete implications including: one-idea-per-beat
  rule, shorten Snappy reboot_duration to ≤ 0.35 s, 3-floor-plane limit, landmark
  requirement, rhythm-group hazards, rest-area/checkpoint pairing.
  Side quest: `camera_rig.gd::_process()` refactored — 56 → 22 lines via 5 extracted
  sub-methods (`_apply_drag_input`, `_update_yaw_recenter`, `_update_lookahead`,
  `_vertical_pull_offset`, `_desired_camera_position`). No behaviour change.
  Magic number `0.05` in vertical pull now documented.
  **Throttle: HARD (9 iterations). Hardening only.**

- 2026-05-09 — Iteration 8. Style test scene greybox (P1):
  `scenes/levels/style_test.tscn` + `scripts/levels/style_test.gd` — compact
  display room with floor, platform sample, wall panel, scale pillar. Same
  fog/lighting as Feel Lab. Walk the Stray to each piece to answer the 5
  ART_PIPELINE.md fidelity questions. Side quest: brutalism/BLAME!/megastructure
  research note (`docs/research/brutalism_blame.md`) — BLAME! visual grammar,
  brutalist design principles, megastructure hierarchy, 10 implications for Void.

- 2026-05-09 — Iteration 7. Controller kinematics unit tests (P1):
  `tests/test_controller_kinematics.gd` + `tests/test_runner.tscn`. Standalone,
  no GUT dependency. ~40 assertions across 10 test groups. Runnable in editor
  (open test_runner.tscn, F5). Side quest: Godot Mobile renderer performance
  research note (`docs/research/godot_mobile_perf.md`) — TBDR, budgets, ASTC,
  lighting, Jolt. INDEX.md updated. P2 perf HUD marked done (was done in iter 3).

- 2026-05-09 — Iteration 6. Mobile touch UX research note
  (`docs/research/mobile_touch_ux.md`): Dadish 3D pain points, floating vs.
  fixed joystick research, thumb-reach analysis for 1920×1080 landscape,
  Genshin/Sky/Alto notes, Assisted profile design targets. INDEX.md updated.
  Concrete material kit (P1): `resources/materials/mat_concrete.tres` +
  `mat_concrete_dark.tres` extracted from feel_lab.tscn; scene now references
  external materials. `.tres` profile headers corrected from generic
  `type="Resource"` to `type="ControllerProfile"`.

- 2026-05-09 — Iteration 5. Reboot animation polish (P0 item 6) + save-as-profile
  side quest (P0 item 7). `_run_reboot_effect()` replaced: sparks burst
  (`_spawn_sparks` via `ImmediateMesh`, 12 lines, particles-toggled) → death
  squish (squash_stretch-toggled) → dark/teleport → scale-up with TRANS_BACK
  overshoot → glow settle. "Save as…" button in dev menu Profile section (inline
  form + `user://profiles/` persistence). `reboot_duration` + `fall_kill_y`
  sliders added to dev menu Controller — Respawn subsection. JUICE.md updated
  (reboot sparks → prototype, death squish → prototype).

- 2026-05-09 — Iteration 4. In-world debug viz (P0 item 5):
  `tools/debug/player_debug_draw.gd` (ImmediateMesh, `no_depth_test=true`);
  collision capsule / velocity arrow / ground normal / jump arc overlays;
  4 new dev-menu checkboxes (all default OFF). Side quest: character
  controllers research note (`docs/research/character_controllers.md`) —
  SMB grammar, Odyssey ledge magnetism, Pseudoregalia momentum rethink,
  Demon Turf custom-physics rationale; implications for Snappy tuning and
  Assisted profile design.
- 2026-05-09 — Iteration 3. Touch overlay polish: drag-to-place reposition
  mode, 3 thumb-zone presets (Default/Closer/Wider), jump-button resize
  handle, `stick_zone_ratio` replaces hardcoded 0.5 in `_classify`, layout
  persists to `user://input.cfg`. Dev menu gains Touch Controls section
  (Reposition button, Jump radius slider, Stick zone % slider). Iter-2
  carry-forward also landed: full controller slider coverage (13 sliders),
  always-on corner HUD (`hud_overlay.gd`), time-scale slider, debug viz
  section. PR #12 closed as superseded.
- 2026-05-09 — Process fix. Added `.github/workflows/auto-merge.yml`
  (squash-merges any non-draft PR with the `auto-merge` label). New
  "Iteration startup" rules in `docs/CLAUDE.md` require listing your
  own open PRs first and either iterating on an existing branch or
  skipping the item if work overlaps. Cleaned up 8 duplicate iter-1
  PRs (#3–#10) — merged #10, closed the rest. Root cause: every 2-hour
  run was starting from a stale `main` because the previous run's
  auto-merge step never fired (no GitHub Action existed; agent
  self-blocked on unticked README questions).
- 2026-05-09 — Iteration 1. Camera occlusion avoidance via
  `PhysicsDirectSpaceState3D` raycast in `camera_rig.gd` (script-only,
  no scene change). Camera params group added to dev menu (9 sliders:
  distance, pitch, lookahead, fall pull, yaw/pitch sensitivity, recenter
  delay/speed, occlusion margin). Floaty profile (smooth/generous) and
  Momentum profile (high top-speed, full velocity preservation) authored
  as `.tres` files and wired into the dev menu dropdown — dropdown now
  shows Snappy / Floaty / Momentum. Dev menu `_build_ui` refactored into
  section helpers; `_make_slider` now uses smart number formatting.
  `DECISIONS.md` entry for raycast-vs-SpringArm3D. See README entry.
- 2026-05-08 — Kickoff steps 1–10 (folder layout + project settings,
  Android preset + ANDROID.md, all doc files, Feel Lab scene, Stray
  controller + Snappy profile, dev menu skeleton, camera rig, touch
  overlay, ANDROID first-run checklist, README populated). See README's
  Updates section.

## Out of scope until next gate

- Enemy archetype work (Gate 1).
- Checkpoints + ghost trails (Gate 1).
- Level-select hub (Gate 2).
- Save/load (Gate 3).
- Final art direction (gate-locked behind human approval).

## How this file gets maintained

- Every iteration ends by editing this file: move completed items to
  "Recently completed", re-rank the queue, update "Blocked / needs
  human" to match README's open questions, and timestamp the iteration
  entry in README.
- Don't delete completed items wholesale — keep a short log so the next
  iteration can see what just happened. The full update log is in
  README.
- Don't re-rank without reason. If you bump an item up, leave a one-line
  note in the queue entry explaining why.

## Refactor backlog

- ~~**Touch slider display doesn't reflect loaded layout.**~~ Done (iter 18).
  `TouchOverlay` now adds itself to the `"touch_overlay"` group; `_build_touch_section`
  queries that group for actual values. DECISIONS.md updated.
- ~~**`_build_controller_section` over 40 lines.**~~ Done (iter 19). Extracted 4
  sub-builders; dispatcher now 7 lines. No behaviour change.
- ~~**`perf_budget.gd::active_particles` always 0.**~~ Done (iter 48). `register_particles`,
  `unregister_particles`, `reset_particles` API added. Gate 1 wires GPUParticles3D nodes
  at scene load; `Game.reset_run()` should call `PerfBudget.reset_particles()` at Gate 1.
  Remaining: wire callers when actual GPUParticles3D nodes exist (Gate 1+).
- Momentum profile speed ramp: add `speed_ramp_rate` + `ramp_max_speed`
  to `ControllerProfile`, add `_ramp_speed: float` to `player.gd`. Hold
  until after first on-device feel of current Momentum approximation.
- Camera occlusion upgrade to ShapeCast3D if point-ray poke-through
  observed in Gate 1 geometry.
- `player.gd::_run_reboot_effect` is 44 lines (just over threshold). The
  sequential `await` beats make sub-method extraction awkward in GDScript
  without coroutine indirection. Leave as-is; revisit if it grows further.
- ~~**Camera pitch manual override V-turn.**~~ Fixed (iter 22). Clamp upper
  bound → 0.0; `absf(_pitch)` → `-_pitch` in `_desired_camera_position`.
  DECISIONS.md entry logged.
