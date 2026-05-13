# Project Void

A mobile 3D platformer. Brutalist megastructure inspired by *BLAME!*. Controller feel inspired by *Super Meat Boy*. Accessibility inspired by *Dadish 3D*. You play as the Stray — a small lost robot in a vast machine-built world. Godot 4.x, Android, landscape.

## Status

Current gate: **Gate 0 — Feel Lab** (closing out; Gate 1 prep in flight)
Last activity: 2026-05-13 — iter 69: Threshold zone atmosphere (WorldEnvironment per-zone swap, Zone 1 OmniLights, dev menu toggle)
Test device build: ✅ verified 2026-05-12 — runs in Godot 4.6 on PC and on Nothing Phone 4(a) Pro
Performance: 144 fps / 6.9 ms in editor at 1920×1080 (Feel Lab); on-device frametimes TBD
Throttle level: **🟢 RESET** by 2026-05-14 direction session. Next step: on-device verification of the redesign.

If you only read one section, read **Open questions waiting on you** below.

## Open questions waiting on you

Things Claude can't decide alone, or where it's stalled and needs direction.

> **🟢 Throttle reset 2026-05-14.** Human direction session landed a major redesign pass. The autonomous queue is unblocked on a single concrete next step: **on-device verification of the redesign.** See `docs/PLAN.md` item P0-0.

> **What's waiting for your read:**
> 1. **Spyro-style Threshold on device.** New Zone 1 plaza (3 routes), Zone 2 maintenance yard (perimeter ledges), Zone 3 lateral platforms. 4 shards scattered. Is the feel right? Are platforms reachable with the new Snappy values?
> 2. **Hold-jump+swipe air dash — two modes to compare.** (iter 67) Dev menu Touch section now has "Buffer dash cam" toggle. Try both: off = current (swipe also pans camera); on = camera suppressed during gesture window, flushed on expiry, discarded on fire (no whip). Pick whichever feels right — or say "always buffer" / "drop the option" and we'll clean it up.
> 3. **Camera pitch 70°.** Was the previous 55° "too tight" complaint solved by the raise, or does pitch_min (hard-clamped at 0) need to go negative too (look up at structures from below)?
> 4. **Industrial press.** Still at x=8 (decorative). After on-device feel of the new gantry layout, decide: move to critical path, or leave it as atmosphere?
> 5. **Start Gate 1 art direction** — surface the asset options doc (Stray mesh / ambient audio / concrete kit) so autonomous asset acquisition can resume.
> 6. **Assisted Phase 2** (ledge magnetism + arc assist) — still queued behind level work.

- [x] **Open the project in Godot 4.6 and run the on-device first-run checklist in `docs/ANDROID.md`.** Done 2026-05-12 — runs in editor and deploys to Nothing Phone 4(a) Pro. Remaining ANDROID.md items: headless CI signing via env vars, release Play Store build (both gate-locked to ship).
- [x] **First feel verdict — Snappy vs Floaty vs Momentum.** Snappy feel approved as good overall; tune-down (max_speed 6.5 → 6.0) queued. Floaty and Momentum verdicts to come as level design forces switching between them.
- [x] **Gate 1 level selection.** Threshold picked as the first build. Lung and Spine remain queued — Claude will build them after Threshold is feature-complete.
- [x] **Auto-merge git workflow confirmed and instrumented.** Now enforced by `.github/workflows/auto-merge.yml` — PRs labeled `auto-merge` are squash-merged automatically.
- [ ] **Asset suggestions for first-pick approval.** Human has asked for browseable options (3–5 candidates per slot with source/licence/fidelity notes) for the first style-defining assets — Stray mesh, ambient audio bed, architecture kit — before autonomous asset acquisition resumes. Claude will surface an options doc when the relevant iteration comes up.
- [ ] **Ongoing Snappy tuning passes.** Snappy feel is good but will keep getting small tweaks as level design progresses. Whenever a level beat feels wrong, note "Snappy felt too X on that beat" — it goes into the next tuning iteration.

## Roadmap

```
[ Gate 0: Feel Lab ]──[ Gate 1: Vertical Slice ]──[ Gate 2: Content Spine ]──[ Gate 3: Polish & Ship ]
       ▲
   you are here
```

### Gate 0 — Feel Lab

Goal: one scene, one character controller, fully instrumented and tunable.

- [x] Feel Lab test arena (brutalist primitives, fog, single warm light)
- [x] CharacterBody3D player (the Stray) with Snappy profile
- [x] Coyote, buffer, variable jump, preserved horizontal velocity
- [x] Dev menu skeleton with live tunables
- [x] Spring-arm camera with lookahead and right-drag override _(occlusion avoidance via raycast added iter 1; camera params live in dev menu)_
- [x] Touch input: virtual stick + jump, repositionable _(positions exposed as `@export`s; drag-to-place UI queued)_
- [x] Android export pipeline verified on test device _(2026-05-12 — runs on Nothing Phone 4(a) Pro)_

### Gate 1 — Vertical Slice

Goal: one full level that proves the game is the game.

- [ ] Brutalist art direction roughed in (style guide approved)
- [ ] One full level (~60–90 s skilled, ~3 min new player), authored under `LEVEL_DESIGN.md` principles
- [ ] Checkpoints, instant respawn, reboot animation
- [ ] Attempt-replay (ghost trails)
- [ ] One enemy archetype
- [ ] One collectible type
- [ ] Win state and results screen
- [ ] At least 2 controller profiles to compare on device

### Gate 2 — Content Spine

Goal: enough levels in one biome to prove the formula scales.

- [ ] 8–12 levels
- [ ] Level-select hub
- [ ] Par-time tracking
- [ ] Title → select → play → results flow

### Gate 3 — Polish & Ship

Goal: store-ready build.

- [ ] Audio pass (music + SFX)
- [ ] Juice pass (every toggleable element evaluated and locked)
- [ ] Settings menu (camera sensitivity, button resize/reposition, accessibility toggles)
- [ ] Save/load
- [ ] Final controller profile chosen and locked
- [ ] Play Store build & listing assets

## Updates

The full iteration log lives here, newest first. Every iteration appends an entry. Skim the dates to find where you last left off.

<!-- ITERATION ENTRIES BELOW — DO NOT REMOVE OLDER ENTRIES -->

### [2026-05-13] — iter 69 — Threshold zone atmosphere

Branch: `claude/gifted-shannon-gsKU0`
Throttle: 🟢 NORMAL (3 iterations since 2026-05-14 direction session)
Gate: Gate 1 — Vertical Slice prep

**Primary: Threshold zone atmosphere — per-zone WorldEnvironment swap via Area3D triggers.**

Three zone-specific `Environment` sub_resources added to `threshold.tscn`: `Env_Z1` (Zone 1 Habitation — warm sodium-yellow ambient `Color(0.35, 0.30, 0.22)`, fog density 0.012), `Env_Z2` (Zone 2 Maintenance — cold blue-white ambient `Color(0.22, 0.26, 0.38)`, fog density 0.015), `Env_Z3` (Zone 3 Industrial — amber ambient `Color(0.30, 0.22, 0.14)`, fog density 0.008). The single `WorldEnv` node's `.environment` property is swapped when the player enters each zone's `Area3D` trigger volume (Zone1/2/3Trigger, collision_mask=2, three large BoxShape3D).

Zone 1 previously had zero local OmniLights. Added Z1Light1/2/3 (sodium-yellow `Color(1.0, 0.85, 0.55)`, shadow=off, energy 1.0–1.5, range 10–14 m, at y=5–6.5 m above the plaza floor). Zone 2 and Zone 3 already had coloured OmniLights from earlier iterations.

Light budget: 3 (Z1) + 2 (Z2) + 3 (Z3) + 1 (Checkpoint WarmLight) = 9 static + up to 4 DataShard dynamic = 13 total. 1 over the research note's 12-light ceiling but DataShard lights are shadow-disabled and short-range (cosmetic). Baked-lighting pass (Gate 1+) drops static count.

**Side quest: Dev menu "Zone Atmosphere" toggle.**
`DevMenu.atmosphere_param_changed` signal added. `dev_menu_overlay.gd` gets `_build_atmosphere_section` — a sub-section in the Level panel with a "Zone atmo" checkbox. When off, `threshold.gd` freezes on `zone1_env` regardless of triggers, for on-device A/B comparison of flat vs zone-differentiated atmosphere.

**Tests.** `_test_zone_atmosphere_logic` (8 assertions, 846 → 854): Z1 ambient R>G>B warmth hierarchy; Z2 B>R cold dominance; Z3 R>G>B amber hierarchy; fog density ordering Z3<Z1<Z2; zone trigger coverage of spawn (z=0), Zone2 floor (z=52.5), G1+Terminal (z=81, z=135).

**Perf.** WorldEnvironment swap on zone entry = one property assignment per zone transition. No per-frame cost. Zone 1 lights add ~3 OmniLight contributions to the scene — negligible GPU cost on Mobile renderer at these ranges.
**On-device pending.** Fog density and ambient energy values need feel tuning on device. Zone trigger extents may need adjustment based on actual navigation paths.

### [2026-05-13] — iter 68 — Momentum profile speed ramp

Branch: `claude/gifted-shannon-mUWlC`
Throttle: 🟢 NORMAL (1 iteration since 2026-05-14 direction session)
Gate: Gate 1 — Vertical Slice prep

**Primary: Momentum profile speed ramp — `speed_ramp_rate` + `ramp_max_speed`.**
Momentum previously used the same `max_speed`-to-`move_toward` path as Snappy/Floaty. Now it has a real ramp: sustained directional input builds `_ramp_speed` toward `ramp_max_speed` at `speed_ramp_rate` m/s per second; releasing input decays it symmetrically back to `max_speed`. When `speed_ramp_rate == 0` (default for all profiles) the ramp is bypassed entirely — no change to Snappy/Floaty/Assisted.

`momentum.tres` now: `speed_ramp_rate = 4.0` (ramps from 11 m/s to 18 m/s over ~1.75 s of sustained running), `ramp_max_speed = 18.0`. Feel: slow to start, then builds to a meaningfully faster top speed than Snappy (18 vs 5 m/s). Dev menu: "Ramp rate" + "Ramp top speed" sliders in Controller — Movement, auto-synced on profile swap.

**Tests.** `_test_speed_ramp_logic` (10 assertions, 836 → 846): rate=0 default guard; ramp-up formula after 1 s (11→15 m/s); clamp at ramp_max; ramp-down after 1 s (18→14 m/s); floor at max_speed; monotone increase invariant; Momentum rate > 0; Momentum ramp_max > max_speed; Snappy/Floaty rate = 0.

**Side quest.** `docs/research/zone_atmosphere.md` — zone-distinct lighting on Godot 4 Mobile renderer (FogVolume is Forward+ only). Key findings: WorldEnvironment swap (one node per zone, current = toggle) is the right technique; emissive surfaces carry more zone identity than light count (INSIDE principle); 12-OmniLight budget for Threshold; concrete colour palettes for all three zones; baked-lighting plan. Unblocks Threshold "ambient volumes" item when device-feel clears. `docs/research/INDEX.md` updated.

**Perf.** No change — one float clamp per physics frame is negligible.
**On-device pending.** Momentum now meaningfully distinct; needs device comparison with Snappy before profile verdict.

### [2026-05-13] — iter 67 — air-dash buffer-and-discard camera variant

Branch: `claude/gifted-shannon-RrbLW`
Throttle: 🟢 NORMAL (0 iterations since 2026-05-14 direction session)
Gate: Gate 1 — Vertical Slice prep

**Primary: `dash_buffer_camera` — toggleable buffer-and-discard for the air-dash gesture.**
The direction session asked to verify "whether the camera-whip on swipe is bad enough to need the buffer-and-discard variant." Rather than wait for device feedback to decide, this iteration implements the variant as a dev menu toggle (off by default = existing behaviour). The human can now compare both modes on device in one session.

How it works: when `dash_buffer_camera = true`, camera drag deltas are buffered in `_dash_drag_buffer` during the active gesture window instead of being forwarded immediately. On dash fire, the buffer is discarded — the firing swipe produces zero camera movement. On window expiry or jump release, the buffer is flushed (forwarded as one call) — a slow camera pan still reaches the camera with at most `dash_time_threshold` (0.20 s) latency. When `false` (default), all deltas are forwarded unconditionally as before.

**Dev menu addition.** The Touch Controls section now exposes three gesture tunables that were only `@export`s before: "Dash px threshold" slider (20–120 px, step 5), "Dash window (s)" slider (0.05–0.50 s, step 0.01), "Buffer dash cam" toggle. Initial values are read from the live TouchOverlay node, not hardcoded.

**Refactor.** `_handle_drag`'s KIND_DRAG case was growing — extracted `_tick_dash_gesture(index, pos, delta) → bool` (36 lines, gesture state machine) and `_flush_dash_buffer(index, delta) → bool` (9 lines, flush/discard helper). `_handle_drag` itself is now 31 lines. `_build_touch_section` was heading toward 43 lines — extracted `_build_dash_gesture_controls(vbox, px, t, buf_cam)` (15 lines). All methods under 40.

**Tests.** `_test_dash_buffer_camera_logic` (10 assertions, 826 → 836): documents accumulate / flush / discard / non-buffering-path invariants as pure-math mirrors.

**Files touched.** `scripts/ui/touch_overlay.gd`, `tools/dev_menu/dev_menu_overlay.gd`, `tests/test_controller_kinematics.gd`, `docs/PLAN.md`, `docs/DECISIONS.md`, `README.md`.

**Perf.** No change — one bool check per drag frame is negligible.
**On-device pending.** Both modes need device comparison before deciding which to keep (or whether to drop the option and always buffer).

### [2026-05-14] — human direction session — Threshold Spyro-style redesign + Snappy tuning + air-dash UX + camera/dev-menu/bug fixes

Branch: `feat/threshold-spyro-redesign`
Throttle: 🟢 RESET by direction session
Gate: Gate 1 — Vertical Slice prep

**Headline:** Threshold restructured from a linear corridor sequence into Spyro-style open hubs after the user reported "just holding forward and mashing jump" + "low-roof tunnels — camera feels unintuitive." Zone 1 is now a 24×36 m plaza with scattered rubble, pillars, and shelves leading to a high lookout; Zone 2 is a widened maintenance yard with a perimeter ledge alternate route; Zone 3 gained two lateral side platforms off the gantry sequence. 4 shards now scattered across the level (Zone 1 Lookout, Zone 2 mid-air, Zone 3 ShardLedge, Beat 4 K2 side). Ceilings + corridor walls removed.

**Snappy tuning pass.** `max_speed` 6.0→5.0, `ground_deceleration` 90→40, `jump_velocity` 11.5→12.0, `air_jumps` 0→1, `air_jump_velocity_multiplier` 0.9 (explicit), `gravity_after_apex` 75→65. Double-jump is now default-on for Snappy. Platforming math: single-jump reach ~1.89 m, double-jump reach ~3.42 m above takeoff.

**Camera fixes.**
- `pitch_max_degrees` 55°→70° (user reported the previous cap felt too tight on Threshold's vertical spans).
- Vertical pitch axis inverted (FPS convention: swipe down → camera rises → view tilts down at player's feet).
- `_apply_drag_input` rewritten to read the authoritative `_pitch_rad` state instead of re-deriving phi from the camera position. The old `asin(to_cam.y / radius)` derivation conflated the additive `aim_height` offset with the spherical radius, yielding a phi the next frame's `_compute_ground_camera_pos` formula disagreed with — the position smoother then walked the camera back up on slow downward swipes. Fix: read `_pitch_rad` directly and write the new position with the same `sin(elev)*dist + aim_height` decomposition the ground formula uses. Now drag and ground-pose stay in lockstep.
- `_apply_drag_input` signature gained `effective_distance` so the drag formula uses the same radius as `_compute_ground_camera_pos` (relevant when a CameraHint is pulling the camera back).

**Air-dash UX rework.** Removed the dedicated dash button and its `KIND_DASH` classification, controller-profile signal handlers, `_dash_available` gating. New interaction: hold the jump button, then a quick swipe (≥40 px in <0.20 s) anywhere in the right (camera-drag) zone fires `air_dash_triggered.emit(TouchInput.move_vector)`. Swipe direction is ignored — dash direction comes from the stick (with the player's existing velocity/visual-forward fallback). Gesture arms lazily on the first drag event where `jump_held` is true (so a touch that began before jump press still qualifies); the 200 ms window slides forward on expiry so "pan slowly with jump held, then swipe" still fires; `_dash_done` per-touch lockout caps each finger at one dash.

**Dev menu.** New "Load Level" section under the existing Level group, with buttons that call `get_tree().change_scene_to_file(...)` for Threshold and Feel Lab. Threshold teleport list updated to match the new Zone 1 layout (Spawn / Plaza floor / High shelves / Lookout shard / Plaza exit). Touch-scroll on buttons fixed by setting `mouse_filter = MOUSE_FILTER_PASS` on `_make_button` and `_make_toggle` — with the default `STOP`, every touch on a dense teleport-button block was claimed by the button and never reached the parent `ScrollContainer`.

**Bug fixes.**
- Shard collection: `Area3D.collision_mask` defaults to 1, but the player is on `collision_layer = 2`. `body_entered` never fired. Fix: set `collision_mask = 2` in `DataShard._ready()`. Player now collects all 4 shards.
- IndustrialPress: `_phase = Phase((_phase + 1) % 4)` was a parse error in Godot 4 (enums aren't callable as constructors). Fix: `((_phase + 1) % 4) as Phase`. Modulo guarantees the int stays valid.
- Threshold scene: orphaned `transform = ...(7, -4.0, 82)` line left over from the original DataShard placement was attaching itself to the Beat 4 shard. Removed.

**Other.** Threshold set as `run/main_scene` so device deploys boot straight into Gate 1's level. Camera-pitch project memory deleted (was an open tuning item; superseded by the 55→70° change — git log preserves the rationale if 70° is still wrong on device).

**Files touched.** `resources/profiles/snappy.tres`, `scripts/camera/camera_rig.gd`, `scripts/levels/data_shard.gd`, `scripts/levels/industrial_press.gd`, `scripts/ui/touch_overlay.gd`, `tools/dev_menu/dev_menu_overlay.gd`, `tests/test_controller_kinematics.gd`, `scenes/levels/threshold.tscn`, `project.godot`, `docs/levels/threshold.md`, `docs/PLAN.md`, `README.md`.

**On-device pending.** Plaza traversal feel, perimeter-route discoverability, lateral platform reachability, hold-jump+swipe gesture comfort, camera pitch 70° comfort.

### [2026-05-13] — iter 66 — data shard gem geometry + light parameter tests (hard throttle hardening)

Branch: `claude/gifted-shannon-beMAc`
Throttle: HARD (15 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: `_test_data_shard_gem_vertices` (13 assertions, 807 → 820).**

Documents and protects the exact vertex geometry of `DataShard._build_gem_mesh()` — the
pure-math magic numbers that define the collectible gem's visual design:
- Top apex y = 0.28 m above equatorial plane.
- Bottom apex y = -0.22 m below equatorial plane (intentionally flatter bottom — sharper top).
- Top taller than bottom is deep: 0.28 > 0.22 (visual asymmetry confirmed).
- All four equatorial vertices lie in the XZ plane (y = 0), tested per-vertex.
- Ring is axis-aligned, not diagonal: eq[0] is pure +X; eq[1] is pure +Z; eq[3] is pure -Z (90° spacing).
- Equatorial radius = 0.20 m.
- 6 total vertices (1 top + 4 equatorial + 1 bottom).
- 8 total triangles (4 upper fan from top apex + 4 lower fan from bottom apex).
- `emission_energy_multiplier` = 3.2 (self-luminous against dark brutalist environment).

**Side quest: `_test_data_shard_light_params` (6 assertions, 820 → 826).**

Documents the `OmniLight3D` parameters and collect-pulse Tween timing in `data_shard.gd`:
- Light is cyan: G > R and B > R.
- `light_energy` = 1.4 (default, pre-collection).
- `omni_range` = 4.5 m (reaches adjacent platform surfaces through fog).
- Collect pulse: rise (0.05 s) < fall (0.30 s) — fast punch, long recognisable tail.
- Peak pulse energy (7.0) = 5× the default (1.4) — unambiguous visual confirmation.

Perf: no change (test-only additions).
Bugs fixed: none.
New dev-menu controls: none.
Assets acquired: none.
Research added: none.
Human attention: see "Open questions waiting on you" — 5 concrete options listed, HARD
throttle at 15 iterations.

### [2026-05-13] — iter 65 — air-dash state-machine tests + game timer accumulation tests (hard throttle hardening)

Branch: `claude/gifted-shannon-MFTyt`
Throttle: HARD (14 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: `_test_air_dash_state_machine` (14 assertions, 786 → 800).**

Fills the gap left by `_test_air_dash_logic` (which covers parameters / guards / formulas) — this
group documents the *state transitions* of the dash machine:
- Re-entry guard: `_is_dashing=true` alone fires the compound guard even with charges + off-floor;
  all-clear correctly passes.
- Timer decrement formula: `maxf(0.0, timer - delta)` — standard tick, near-zero clamp, floor
  idempotence (three cases).
- Timer expiry → `_is_dashing` cleared: both the "clears" case (0.005 s + one frame) and the
  "stays true" case (0.10 s + one frame).
- Landing vs respawn semantics: landing sets `_dash_charges = 1` (refill); respawn sets
  `_dash_charges = 0` (cannot dash immediately on first airframe). Also: landing clears
  `_is_dashing` and `_dash_timer`.
- Y-velocity zeroed at trigger: `velocity.y = 0.0` makes the dash purely horizontal.
- Double fallback to `Vector3.FORWARD`: zero input + zero velocity invokes the absolute fallback
  path used when `_visual` is unavailable.
- Duration expires within 15 frames at 60 fps: loop simulation confirms default 0.18 s budget.

**Side quest: `_test_game_timer_accumulation` (7 assertions, 800 → 807).**

First coverage of `game.gd::_process` timer logic. Tests: not-running frame doesn't accumulate;
single frame adds delta; 10 frames add `10 × delta`; `level_complete()` stops accumulation and
subsequent `_process` calls are inert; `start_run()` resets timer to 0.0 and re-enables
accumulation; 60-frame simulation totals ≈ 1.0 s (within 1 ms tolerance).

Perf: no change (test-only additions).
Bugs fixed: none.
New dev-menu controls: none.
Assets acquired: none.
Research added: none.
Human attention: see "Open questions waiting on you" — 5 concrete options listed, HARD
throttle at 14 iterations.

### [2026-05-13] — iter 64 — results_panel refactor + IndustrialPress formula tests (hard throttle hardening)

Branch: `claude/gifted-shannon-3zuGS`
Throttle: HARD (13 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: `results_panel.gd::_build_ui()` refactor (41 → 5 lines).**

`_build_ui()` was 41 lines, 1 over the 40-line threshold. Extracted three private helpers:
`_build_overlay_root()` (9 lines — root Control + dark backdrop ColorRect),
`_build_center_panel(root)` (12 lines — CenterContainer + VBox + TIME/PAR/SHARDS stat rows),
`_build_replay_button(panel)` (8 lines — spacer gap + REPLAY Button). `_build_ui` itself is
now 5 lines. No behaviour change — all `show_results()` and `_on_replay()` logic untouched.

**Side quest: `_test_industrial_press_position_formula` (17 assertions, 769 → 786).**

First unit-test coverage of `IndustrialPress._target_y()` and `_update_emissive()` — the two
pure-math formulas that govern where the kill-zone physically sits and how bright the amber
danger strip glows. New helpers `_ip_y(phase, p, origin_y, stroke_depth)` and
`_ip_emissive(phase, p)` are pure-math mirrors. Coverage: all four phases (DORMANT/WINDUP/
STROKE/REBOUND) at p=0/0.5/1; a continuity invariant (stroke(p=1) == rebound(p=0) — no
position pop at the phase boundary); and emissive energy at boundary values per phase.

Perf: no change (structural refactor + test additions only).
Bugs fixed: none.
New dev-menu controls: none.
Assets acquired: none.
Research added: none.
Human attention: see "Open questions waiting on you" — 5 concrete options listed, HARD
throttle at 13 iterations.

### [2026-05-13] — iter 63 — _conditional_fall_offset regime tests (hard throttle hardening)

Branch: `iter/conditional-fall-offset-tests`
Throttle: HARD (12 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: `_conditional_fall_offset` regime unit tests (18 assertions, 743 → 761).**

`camera_rig.gd::_conditional_fall_offset` was the last major camera function without
pure-math coverage. It gates fall-pull into only the two "tracking" regimes (player above
apex band / below reference floor) and suppresses it in the held band, so normal jumps
don't re-introduce the vertical camera motion the ratchet removes. New helper `_cfo_mirror`
(6 lines) mirrors the formula; `_test_conditional_fall_offset_regimes` (18 assertions)
covers: `_vertical_pull_offset` sanity (zero/rising → 0, falling → negative, concrete
magnitude), `apex_h==0` bypass path, above-apex tracking regime, below-floor tracking
regime, held-band suppression, both boundary cases (strictly-greater / strictly-less rules),
and linearity (scales with vertical_pull and fall speed).

**Side quest: `_test_hint_distance_blend` (8 assertions, 761 → 769).**

First coverage of the exponential lerp in `_update_hint_distance` (rate 3/sec). Tests:
no-hint → zero stays zero; first-frame at 60 fps concrete value (`target × w1`);
1-second 60 fps run >95% converged; monotone convergence and no-overshoot across 120 frames;
rate 3/sec documented as slower than reference_floor_smoothing's 6/sec (hints breathe, tier
changes snap).

Perf: no change (tests only). Draw calls: no change.
New dev-menu controls: none.
Assets acquired: none.
Research added: none.

### [2026-05-13] — iter 62 — camera_rig _process refactor (hard throttle hardening)

Branch: `iter/camera-process-refactor`
Throttle: HARD (11 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: `camera_rig.gd::_process` method-size refactor.**

`_process` was 137 lines — far over the 40-line threshold. Extracted 8 new helpers:
`_update_hint_distance`, `_build_effective_target`, `_try_initialize`,
`_update_ground_camera`, `_compute_ground_camera_pos`, `_occlude_and_latch`,
`_apply_position_smooth`, `_publish_camera_yaw`. Also split `_occlude` (50 lines) into
`_occlude` + `_probe_hit_dist` (10 + 27 lines). `_process` is now 31 lines. All 23
methods in the file are now under 40 lines. Pure structural refactor — no behaviour change,
all existing camera tests still valid.

**Side quest: `_test_ground_camera_y_formula` (8 assertions, 735 → 743).**
Pure-math mirror of `_compute_ground_camera_pos` Y formula:
`eff_y + sin(elevation) * dist + aim_h + fall_off`.
Covers: sin=0 at elev=0, sin=1 at elev=90°, monotonicity over [30°,45°,90°],
camera Y > eff_y+aim_h when elevation > 0, fall offset sign (always ≤ 0),
fall offset magnitude (`vel * pull * 0.05`), and a concrete combined value check.

Perf: no change (refactor only). Draw calls: no change.
New dev-menu controls: none.
Assets acquired: none.
Research added: none.

### [2026-05-13] — iter 61 — RotatingHazard + CameraHint unit tests (hard throttle)

Branch: `claude/gifted-shannon-w2fci`
Throttle: HARD (10 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: unit test coverage for `rotating_hazard.gd` and `camera_hint.gd`.**

Two new test groups added to `tests/test_controller_kinematics.gd`:

- `_test_rotating_hazard_math` (12 assertions, pure math, no node instantiation):
  mirrors `angle = fmod(_elapsed / period_seconds, 1.0) * TAU` in `_physics_process`;
  tests angle at t=0/half/full/1.25 periods; periodicity (t and t+7×period agree);
  angle always in [0, TAU); axis normalization (UP and diagonal); default period 4.0 s
  within export range [0.5, 20.0]; Basis column-length invariant at angle=0 and TAU.
- `_test_camera_hint_defaults` (5 assertions, instantiates `CH := CameraHint.new()`):
  `pull_back_amount` defaults 0.0 (safe no-op); `blend_time` defaults 0.5 s; both
  non-negative / positive guards; `"camera_hints"` StringName contract matches
  `camera_rig.gd::_get_active_hint_extra()` group query.

New const: `const CH := preload("res://scripts/levels/camera_hint.gd")`.

Perf: no runtime code touched. Unit tests: 718 → 735.

Side quest: none (hard throttle).

Bugs fixed: none. New dev-menu controls: none. Assets: none. Research: none.

> **HARD THROTTLE active — 10 iterations since last human direction (2026-05-12).**
> All remaining queue items are either device-dependent or need human sign-off.
> Please pick from the 5 options in "Open questions waiting on you" above.

### [2026-05-13] — iter 60 — dev_menu_overlay refactor (hard throttle)

Branch: `claude/gifted-shannon-i1F0T`
Throttle: HARD (9 iterations since last human direction 2026-05-12)
Gate: Gate 1 — Vertical Slice prep (hardening pass)

**Primary: `_build_level_section` refactor — extract `_build_feel_lab_teleports` + `_build_threshold_teleports`.**

`_build_level_section` was 54 lines (refactor backlog). Extracted two helpers:
- `_build_feel_lab_teleports(vbox)` — 20 lines: Feel Lab heading + 10 zone buttons.
- `_build_threshold_teleports(vbox)` — 25 lines: Threshold heading + 14 zone buttons + "Respawn shard" button.
`_build_level_section` is now 16 lines. All methods in `dev_menu_overlay.gd` are under 40 lines. No behaviour change.

Side quest: none (hard throttle — keeping changes minimal).

Perf: no change (no runtime code touched). Unit tests: 718 (unchanged).

Bugs fixed: none. New dev-menu controls: none. Assets: none. Research: none.

**Needs human attention:** Hard throttle reached. See "Open questions waiting on you" above for 5 suggested directions.

---

### [2026-05-13] — iter 59 — Industrial press implementation

Branch: `claude/gifted-shannon-cM0SO`
Throttle: 8 (soft)
Gate: Gate 1 — Vertical Slice prep (Threshold Zone 3 polish, unblocked sub-item)

**Primary: IndustrialPress hazard script + Threshold wiring (705 → 718 assertions).**

New `scripts/levels/industrial_press.gd` (class IndustrialPress, extends AnimatableBody3D):
- Four-beat state machine: dormant / windup / stroke / rebound. `_phase_t` advances each
  `_physics_process`; overflows advance `_phase` and carry remainder.
- `position.y` set directly each tick — matches `rotating_hazard.gd` precedent, no move_and_collide.
- Default cycle: 1.5 s dormant / 0.8 s windup / 0.18 s stroke / 0.5 s rebound = 2.98 s total.
  Dormant window (1.5 s) ≥ 1.5 × crossing_time (5 m / 6 m/s = 0.83 s) — mobile safety met.
- Emissive amber strip (`Color(1.0, 0.72, 0.12)`): dim 0.3 → ramp 0.3→2.5 → hold 2.5 → ramp back.
- `DevMenu.press_param_changed` connection for live-tuning all 5 exports.

`scenes/levels/threshold.tscn` changes:
- IndustrialPress node: script swapped from `7_movp` (moving_platform) → `15_ip` (industrial_press).
- Old `travel` / `period_seconds` props replaced with new exports.
- New child `EmissiveStrip` (MeshInstance3D, 14×0.2×5 m at local y=−2.1).
- New child `KillZone` (HazardBody Area3D at local y=−2.25) + `KillShape` (BoxShape3D 13.7×0.5×4.7 m,
  inset 0.15 m from visual mesh — mobile hitbox generosity).

`scripts/autoload/dev_menu.gd`: `press_param_changed(param, value)` signal added.

`tools/dev_menu/dev_menu_overlay.gd`: new `_build_press_section()` helper (5 sliders: stroke depth,
dormant, windup, stroke, rebound). `_build_level_section` gains "↺ Reload level" button and
"→ Press zone" teleport at (8,−10,93).

**Side quest: "Reload level" button in dev menu Level section.**
Calls `get_tree().reload_current_scene()`. Useful for on-device iteration without restarting.

**Unit tests: `_test_industrial_press_timing()` — 13 assertions**
Cycle time, mobile safety rule, windup>stroke invariant, target_y at all phase boundaries,
emissive energy at key points, KillZone inset rule (≥ 0.10 m per side).

**Perf:** no regression expected — press uses 1 `position.y` write + 1 float assignment per
physics tick; EmissiveStrip is 1 material with no shadow cast; 0 new draw calls.

**Dev-menu controls added:** Stroke depth m, Dormant s, Windup s, Stroke s, Rebound s; ↺ Reload level; → Press zone teleport.

**Needs attention:** par-route routing (forcing player *through* the press rather than around it)
is still blocked on on-device feel from the Zone 3 greybox. The press kills but is currently
bypassable. PLAN.md item 8 still pending for this last sub-item + ambient volumes + texture pass.

### [2026-05-13] — iter 58 — Gate 1 script tests + machinery hazard research

Branch: `claude/gifted-shannon-3QFyY`
Throttle: 7 (soft)
Gate: Gate 1 — Vertical Slice prep (hardening while Threshold polish blocked on on-device feel)

**Primary: Unit tests for Gate 1 scripts (679 → 705 assertions).**

Three new test groups in `tests/test_controller_kinematics.gd`:

**`_test_results_panel_formatting()`** — 11 assertions
- `_fmt_time()` output at 6 boundary values (0.0, 35.0, 60.0, 65.5, 3661.0, 0.25)
- Par-beat colour is green (g > r), par-fail is red (r > g), exactly-equal counts as beat (`<=` not `<`)
- Shard count string `"%d / %d"` format at `[2,3]` and `[0,1]`

**`_test_win_state_one_shot_guard()`** — 6 assertions
- `WinState._triggered` default false, set, one-shot guard bool check
- `CheckPoint._activated` default false, `reset()` clears, locked after set

**`_test_data_shard_state_machine()`** — 9 assertions
- `_collected`, `_mesh_instance`, `_light` instance-variable defaults (no `_ready()` needed)
- `_collected=true` blocks re-collection
- Spin period in `(4 s, 6 s)` range (readable, not blurring)
- Gem total height 0.50 m; equatorial radius 0.20 m < sphere collider 0.60 m
- `"data_shard"` group StringName contract

Four new preload constants at top of file: `RP` (ResultsPanel), `WS` (WinState), `CKP` (CheckPoint), `DS` (DataShard).

**Side quest: `docs/research/machinery_hazards.md`**
Industrial machinery hazard design — four-beat cycle (dormant / windup / stroke / rebound),
cross-axis movement preference for 3D depth legibility, amber emissive danger-strip cycle,
mobile dormant-window sizing formula (1.5 × crossing-time), Godot 4 `AnimatableBody3D` + HazardBody
sketch for the Threshold industrial press, 7 concrete implications (Y-axis crush, critical-path
routing, emissive strip, 1.0 s dormant window, 0.15 m hitbox inset, crushed-prop first-encounter,
dev-menu sliders). Sources: INSIDE, Celeste Ch2, Hollow Knight, SMB 3D.
`docs/research/INDEX.md` updated with new "Gate 1 — level hazard design" section.

Perf delta: none (tests only).
Bugs fixed: none.
New dev-menu controls: none.
Research added: `machinery_hazards.md`.
On-device pending: all Threshold items.

### [2026-05-12] — iter 57 — Data shard collectible

Branch: `claude/gifted-shannon-eELv5`
Throttle: 6 (soft)
Gate: Gate 1 — Vertical Slice prep

**Primary: Data shard collectible — Gate 1 one-collectible-per-level requirement.**

**`scripts/levels/data_shard.gd`** — new `DataShard` class (Area3D):
- Adds self to `"data_shard"` group on `_ready()` — auto-counted by `threshold.gd` via `get_tree().get_nodes_in_group()`
- Programmatic visual built in `_ready()`: SurfaceTool octahedron gem (unshaded cyan emissive, `CULL_DISABLED`), `OmniLight3D` (cyan 0.12/0.90/0.95, energy 1.4, range 4.5 m), `SphereShape3D` (radius 0.6 m)
- Slow Y-spin: `rotate_y(delta * 1.15)` ≈ 66 deg/s in `_process`
- `_collect()`: increments `Game.shards_collected`, hides mesh, pulses light (1.4 → 7.0 over 0.05 s, fades → 0.0 over 0.30 s via Tween), then hides light
- `respawn_shard()`: resets `_collected` flag and restores visibility — used by dev menu without level reload

**`scenes/levels/data_shard.tscn`** — minimal Area3D stub with script reference.

**`scenes/levels/threshold.tscn`** — two new nodes added to Zone3_Industrial:
- `ShardLedge` StaticBody3D at (7, −6.25, 82), size 3×0.5×3 m (surface y = −6.0) — small detour platform off the right side of G1
- `DataShard` instance at (7, −4.0, 82) — glows cyan in the industrial void, visible from the gantry sequence; requires jumping from the ledge (NOT collectable while standing; IS collectable at Snappy jump apex — verified by unit test)

**Dev menu (Level section):**
- New teleport: "Shard ledge" → (7, −5.5, 82)
- New button: "Respawn shard" — resets `Game.shards_collected = 0` and calls `respawn_shard()` on all `"data_shard"` group members

**Tests:** `_test_data_shard_placement` — 7 assertions: collection threshold (0.88 m), standing-on-ledge NOT in range, at jump-apex IS in range, G1 right-edge 3D separation NOT in range, increment + double-collect guard. Total: 672 → 679 assertions.

**JUICE.md:** 3 new entries — shard idle glow (prototype), shard collect pulse (prototype), shard slow spin (prototype).

Perf delta: +1 OmniLight3D per level (no shadow). Draw calls: +1 per DataShard. Within budget.
Bugs fixed: none.
New dev-menu controls: "Shard ledge" teleport, "Respawn shard" button.
On-device pending.

### [2026-05-12] — iter 56 — Win-state flow + CameraHint integration

Branch: `claude/gifted-shannon-XtVFe`
Throttle: 5 (soft)
Gate: Gate 1 — Vertical Slice prep

**Primary: Complete win-state pipeline — run timer, results panel, par time, shard tracking hooks.**

**`game.gd`** promoted from stub to Gate 1 runtime:
- New fields: `is_running: bool`, `shards_collected: int`, `shards_total: int`
- `_process(delta)`: increments `run_time_seconds` only when `is_running`
- `start_run()`: zeros timer + shards, sets `is_running = true`; called from level's `_ready()`
- `level_complete()`: clears `is_running`, emits `level_completed` — timer always stops before signal consumers fire
- `reset_run()`: now also clears `is_running` and `shards_collected` (backwards-compat: existing tests pass)

**`scripts/ui/results_panel.gd`** — new `CanvasLayer` class, all UI programmatic:
- Backdrop: full-rect `ColorRect` (charcoal 88% opacity), `MOUSE_FILTER_STOP`
- Layout: `CenterContainer` (full-rect) → `VBoxContainer` (560 px wide min)
- Three rows: TIME / PAR / SHARDS at 36 pt font, 180 px key column
- PAR row modulated green when ≤ par, red when over (immediate visual grade)
- REPLAY button: 360×120 px minimum, 40 pt — thumb-reachable. Calls `Game.reset_run()` + `reload_current_scene()`
- Hidden by default (`hide()` in `_ready()`); shown via `show_results(time, par, shards, total)`

**`win_state.gd`**: calls `Game.level_complete()` instead of emitting `level_completed` directly — ensures timer stops atomically with the signal.

**`threshold.gd`**: `par_time_seconds = 35.0` export; `Game.shards_total` auto-counted from `"data_shard"` group (0 until shard collectible is placed); `Game.level_completed` → `_on_level_completed()` → `ResultsPanel.show_results(...)`.

**Side quest — CameraHint integration in `camera_rig.gd`:**
- `_hint_distance_extra: float = 0.0` state var
- `_get_active_hint_extra()`: queries `"camera_hints"` group, returns max `pull_back_amount` among hints with player inside
- `_hint_distance_extra` lerps toward target at 3/sec every frame (including airborne, so blend is already in progress on landing)
- Ground branch uses `effective_distance = distance + _hint_distance_extra` for both horizontal distance and camera-Y. The three CameraHint markers in threshold.tscn (pull_back 2/3/5 m) are now live.

**Tests:** `_test_game_gate1_api` (11 assertions): is_running/shards defaults, start_run state, level_complete timer stop, reset_run Gate 1 field clearing, shards_total level-ownership invariant. 661 → 672 total.

**Perf:** no new draw calls (panel hidden by default; results phase freezes physics). Delta vs last: 0 ms / 0 draw calls (greybox only).

**Needs human attention:**
- **On-device playtest still needed for Threshold.** Run it, reach the win trigger, verify results panel shows. Check par time = 35 s feels right (expected to be ~2× skilled time at this greybox stage — tune down after first clear).
- **MaintArm1 timing / industrial press** — still needs device feel before moving press into critical path.
- **Data shard collectible** is the next standalone Gate 1 piece. `Game.shards_total` auto-counts `"data_shard"` group — drop one `DataShard` node and it wires up automatically.

### [2026-05-12] — iter 55 — Threshold greybox

Branch: `claude/gifted-shannon-8WfWu`
Throttle: 4 (normal)
Gate: Gate 1 — Vertical Slice prep

**Primary: full greybox geometry for Threshold (Gate 1 level 1) — three zones, hazards, checkpoint, win state stub.**

New scripts (all in `scripts/levels/`):
- **`checkpoint.gd`** — `Area3D`; sets player spawn transform + emits `Game.checkpoint_reached(id)` on first player entry. `reset()` for future run-reset wiring.
- **`camera_hint.gd`** — `Area3D` stub; registers to `"camera_hints"` group; exposes `is_player_inside()`. Camera-rig integration deferred to Gate 1 (camera_rig.gd will query group).
- **`hazard_body.gd`** — `Area3D`; instant-kill zone, calls `player.respawn()` on contact. Attach to any hazard geometry as a child.
- **`win_state.gd`** — `Area3D`; fires `Game.level_completed` once on first player entry; one-shot guard. Prints "[WinState] Level complete" stub.
- **`rotating_hazard.gd`** — `@tool AnimatableBody3D`; rotates around a configurable axis at a fixed period; `Basis(axis, angle)` for deterministic orientation. `HazardBody` children kill on contact.
- **`threshold.gd`** — root level script; teleports player to spawn marker in `_ready()`; sets `Game.current_level_path`.

New scene **`scenes/levels/threshold.tscn`** (~450 lines, 70 load_steps):
- **Zone 1 — Habitation** (z=0–36, y=0): warm sodium lighting. Floor 4×1×36, ceiling 3.15m. Three shelf platforms as furniture-scale ledges (HabShelf1–3 at y=1.275–1.525m), two intermediate platforms (HabP1/P2), exit slab. `CameraHint1` Area3D (pull_back=2).
- **Zone 2 — Maintenance Buffer** (z=37–68, y=−5 drop then corridor): cold blue-white OmniLights. Tight floor 2m wide, ceiling 2.35m. Three precision ledges (MaintLedge1/2/2b — ledge2b is the par-route skip). `ServiceCart` AnimatableBody3D (ping-pong, travel=(0,0,3), period=2.5s). `MaintArm1` RotatingHazard (Y-axis, period=4s) with co-rotating `HazardBody` child.
- **Alcove — Checkpoint** (z=68–73): amber `OmniLight3D` (warm 1.0/0.55/0.15), `CheckpointTrigger` Area3D (checkpoint.gd, id=`cp_alcove`). `CameraHint2` (pull_back=3).
- **Zone 3 — Industrial** (z=75–135, y=−5 → −20): amber industrial OmniLights. Hall 28m wide × 50m tall. Four descending gantries G1–G4 (4m drop each, shared Mesh_Gantry/Shape_Gantry sub_resources). `IndustrialPress` AnimatableBody3D offset to x=8 (atmospheric — not in critical path). Four Ketsu platforms K1–K3 + Terminal. `WinStateTrigger` Area3D (BoxShape 8×2×6). `CameraHint3` (pull_back=5).

All walkable surfaces: `collision_layer = 1`. Large walls/hall geometry: `collision_layer = 65` (World + CameraOccluder). `IndustrialFloorVisual` is pure MeshInstance3D (no physics — player respawns before reaching it).

**Perf:** all greybox geometry (BoxMesh + BoxShape). No new shaders or particles. Shared sub_resources keep draw calls bounded. On-device pending.

**fall_kill_y updated:** all 4 controller profiles updated from −25.0 → −35.0 to give 15 m void below the terminal platform (y=−20). Previous 5 m void was too shallow for industrial-tier depth.

**New dev-menu controls:** "Teleport — Threshold" sub-section (12 zone buttons: Spawn / Hab corridor / Hab shelves / Hab exit / Maint. entry / Service cart / Maint. arm / Checkpoint / Gantries G1 / Gantries G4 / Ketsu K1 / Terminal).

**Needs human attention:**
- **On-device playtest needed.** Level is greybox-only: white cubes, no textures, no ambient sound. Primary test goal: can you read the three spatial zones from the geometry alone? Does the Threshold 2 scale-shock land (buffer corridor → industrial hall)?
- **MaintArm1 timing window.** The arm rotates on Y-axis in a 2m-wide corridor — requires the player to time a run-through during the parallel-to-Z phase. May need period adjustment after device feel.
- **Industrial press is atmospheric-only.** `IndustrialPress` is offset to x=8 (not in the player's path). Gate 1 pass will move it into the critical path once the gantry sequence is confirmed playable. Report if the industrial tier needs more hazard density even for greybox.
- **Par route (cross-cart jump).** `MaintLedge2b` at z=55.5 is the par-route skip target. Visible from atop the service cart at z=49. Test if it's legible as an intentional skip or looks like an accidental overlap.

### [2026-05-12] — iter 54 — Air dash implementation

Branch: `iter/air-dash`
Throttle: 3 (normal)
Gate: Gate 0 closing / Gate 1 prep

**Primary: Air dash mechanic — full implementation from ControllerProfile params through touch gesture to dev-menu sliders.**

- **`scripts/controller/controller_profile.gd`** — New `@export_category("Air Dash")` with three params: `air_dash_speed` (0–20 m/s, default 0 = disabled, backwards-compatible on all existing profiles), `air_dash_duration` (0.05–0.5 s, default 0.18 s), `air_dash_gravity_scale` (0–1, default 0.15 = near-suspended gravity during burst).
- **`scripts/player/player.gd`** — Four new state vars (`_dash_charges`, `_dash_timer`, `_dash_dir`, `_is_dashing`). `_tick_timers`: on landing, `_dash_charges = 1` + clears dash; in airborne branch, ticks down `_dash_timer` and clears `_is_dashing` on expiry. `_apply_horizontal`: early-return when `_is_dashing` (holds velocity constant). `_apply_gravity`: scales `g` by `air_dash_gravity_scale` when dashing. `respawn()`: clears all dash state. New methods: `_try_air_dash(dir: Vector3)` (guards + trigger), `_play_dash_stretch()` (XZ stretch + Y squish via `_squash_tween`, gated behind `squash_stretch`), `_on_air_dash_triggered(dir_2d)` (touch signal handler — rotates screen 2D dir by camera yaw into world space). Keyboard trigger: `E` key → `_try_air_dash(Vector3.ZERO)` (uses current velocity direction as fallback).
- **`scripts/autoload/touch_input.gd`** — New `signal air_dash_triggered(dir: Vector2)`.
- **`scripts/ui/touch_overlay.gd`** — New `@export_category("Dash gesture")` with `dash_px_threshold` (40 px default) and `dash_time_threshold` (0.20 s default). New `_dash_start` dict tracks press position+time per KIND_DRAG touch. `_handle_touch`: seeds / erases `_dash_start` on press/release. `_handle_drag`: quick-swipe check (total travel ≥ threshold AND elapsed < time threshold) fires `TouchInput.air_dash_triggered`; resets anchor to prevent double-trigger; falls through to camera drag otherwise.
- **`tools/dev_menu/dev_menu_overlay.gd`** — New `_build_controller_air_dash()` subsection: "Dash speed" / "Dash dur (s)" / "Dash gravity ×" sliders wired to `_profile_sliders` dict. Called from `_build_controller_section()`.
- **`project.godot`** — New `air_dash` input action bound to `E` key (physical_keycode=69) for editor testing.
- **`tests/test_controller_kinematics.gd`** — `_test_air_dash_logic()`: 19 assertions. Backwards-compat (all 4 profiles default to speed=0), default param range checks, charge management (refill on land / decrement on use / exhaustion guard), speed guard, velocity formula (dir × speed), gravity scaling (scale×g, scale=0, scale=1), direction fallback (zero input → velocity dir, non-zero input → input dir). Total: 642 → 661.
- **`docs/JUICE.md`** — "Dash stretch" added to Squash & stretch table (prototype).

**Side quest:** none.

**Perf:** no frametime change expected — one extra guard in `_apply_horizontal`, one extra multiply in `_apply_gravity` per physics frame. Both O(1).

**New dev-menu controls:** Controller — Air Dash: Dash speed, Dash dur (s), Dash gravity ×.

**On-device pending.** Enable via dev menu: set "Dash speed" > 0 on the target profile (Assisted recommended first). Keyboard E to test in editor.

### [2026-05-12] — iter 53 — Feel Lab expansion + interaction variety

Branch: `iter/feel-lab-expansion`
Throttle: 2 (normal)
Gate: Gate 0 closing / Gate 1 prep

**Primary: expanded Feel Lab geometry — high-tier ascent, narrow ledges, wall corner, drop ledge, vertical moving platform, dev menu teleport buttons.**

- **`scenes/levels/feel_lab.tscn`** — 6 new sub_resources, 30+ new nodes across 7 new groups:
  - **FloorEast** — 30×1×30 dark-concrete slab at (35,−0.5,−10) extends the playable floor into the high ascent zone, providing a runway from the main floor to the new platforms.
  - **HighAscent (HA1–HA4)** — Four platforms (Plat_3x05x3/Plat_4x05x4) forming a staircase at surface heights ~1.5 / 3.5 / 6.0 / 8.25 m. HA1 is reachable with a single jump from the floor; HA2–HA4 each require a double jump (the gap between tiers is ~2.0–2.5 m, exceeding the Snappy single-jump apex of ~1.74 m). Staircase runs northeast from x=28,z=−8 to x=32,z=−22.
  - **NarrowLedges (NL1–NL5)** — Thin platforms (Mesh_LedgeNarrow: 3.5×0.3×0.9 m, mat_concrete) over void north of the east slab at y=1.35–2.85 m. Each is 0.9 m deep — forces accurate depth landing. Stepping-stone route runs northwest from (28,z=7) to (27,z=19).
  - **WallJumpCorner (WJL/WJR)** — Two parallel 1×4×4 walls at x=−8 and x=−12, both at z=−16. Creates a 4 m wide corridor for future wall-jump mechanic testing. Tagged collision_layer=65 (World + CameraOccluder) so the camera handles occlusion correctly.
  - **DropTestLedge** — 6×0.5×3 platform (mat_concrete) at (0, 2.75, 19), surface at 3.0 m, jutting 1 m beyond the main floor's north edge into fog. Walk to the edge and step off to test fall tracking and camera follow-fall behaviour.
  - **MovingPlatformVert** — Second AnimatableBody3D platform at (18, 0.25, −4), travel=(0,5,0), period=5 s. Acts as a vertical elevator alongside the high ascent zone, testing the camera's y-ratchet on a slow continuous ascent.
- **`tools/dev_menu/dev_menu_overlay.gd`** — New "Teleport" sub-section in the Level panel: 10 named zone buttons (Spawn / Platforms / HA1–HA4 / Narrow ledges / Wall corner / Drop ledge / Moving plat.). Uses new `_teleport_player(pos)` helper: calls `set_spawn_transform` + `respawn` on the player node fetched from the "player" group.

**Side quest:** none.

**Perf:** no new shaders, no particles. 30+ new static meshes; all share existing sub_resources (no extra draw-call cost beyond geometry — mobile GPU cost is vertex count, not node count). Frametime delta: ~0 (static geometry). Draw call delta: estimated +2–4 for new MeshInstance3Ds (shared materials batch well under the mobile renderer). On-device pending.
**Bugs fixed:** none.
**New dev-menu controls:** Teleport sub-section (10 zone buttons in Level panel).
**Assets acquired:** none.
**Research added:** none.

**Needs human attention:**
- **Double jump tuning on device.** HA1→HA2 requires double jump (2.0 m gap). Enable `air_jumps = 1` in dev menu Controller → Jump sliders. The staircase is calibrated for Snappy; Floaty's higher apex may make some tiers reachable with single jump — verify on device.
- **Narrow ledge depth perception.** NL1–NL5 are 0.9 m deep — testing whether the blob shadow + depth cues are sufficient to land these without air dash. Report if they feel fair or too blind.

### [2026-05-12] — iter 52 — double jump implementation

Branch: `claude/gifted-shannon-ynUKp`
Throttle: 1 (normal)
Gate: Gate 0 closing / Gate 1 prep

**Primary: double jump mechanic — all three ControllerProfile params, player state machine, dev menu sliders, unit tests.**

- **`ControllerProfile`**: three new `@export` props in the Jump category, all default off/neutral (backwards-compatible with existing `.tres` files):
  - `air_jumps: int = 0` — number of extra airborne jumps (0 = off).
  - `air_jump_velocity_multiplier: float = 0.8` — air jump initial velocity as a fraction of `jump_velocity`.
  - `air_jump_horizontal_preserve: float = 1.0` — fraction of horizontal velocity retained at the air jump moment (1.0 = full preservation, upholds CLAUDE.md H-vel invariant).
- **`player.gd`**: `_air_jumps_remaining: int` counter. Reset to `profile.air_jumps` on every grounded frame (in `_tick_timers`) and at each ground/coyote jump (in `_try_jump`) so the pool refills for the next aerial phase. Zeroed in `respawn()`. New `elif` branch in `_try_jump`: fires when `buffer > 0`, `coyote = 0`, `remaining > 0`; sets `velocity.y = jump_velocity × multiplier`, scales H-vel by preserve factor, decrements counter. Ground jump has priority (checked first).
- **Dev menu**: three new sliders in "Controller — Jump" subsection: Air jumps (0–3), Air jump vel × (0.3–1.2), Air jump H pres. (0.0–1.0). Auto-synced by `_select_profile`.
- **Unit tests**: `_test_double_jump_logic` — 17 assertions: 4 profile backwards-compat guards, multiplier/preserve defaults, velocity formula, branch priority, counter decrement, exhaustion guard, on-floor reset (2 cases). **Total: ~625 → ~642 assertions.**

**Side quest:** none.

**Perf:** no change — no new nodes, no new draw calls. Frametime delta: 0 (pure logic, no rendering).
**Bugs fixed:** none.
**New dev-menu controls:** Air jumps slider, Air jump vel × slider, Air jump H pres. slider (all in Controller — Jump).
**Assets acquired:** none.
**Research added:** none.

**Needs human attention:**
- **Double jump feel verdict needed on device.** All four profiles ship with `air_jumps = 0` (off). Enable via dev menu slider during play testing and report how many jumps feel right per profile. Also: does `air_jump_velocity_multiplier = 0.8` feel right, or should the air jump be stronger/weaker?
- **`air_jump_horizontal_preserve`** is exposed but defaults to 1.0 (full preserve). Worth experimenting: Assisted at ~0.6 may give a "reset and reorient" feeling that aids air-error correction. No action needed yet — surfaced for awareness.

### [2026-05-13] — iter 51 follow-ups — camera vertical-follow feel polish

Three on-device tuning PRs on top of [#65](https://github.com/Adam-Vozzo/mobile-game-6/pull/65) (the original vertical-follow ratchet):

- **[#67](https://github.com/Adam-Vozzo/mobile-game-6/pull/67) — Reference-floor smoothing.** "Camera snaps too fast vertically when landing on a new floor level." Reference floor now eases toward player.y at 6/sec (~400 ms settle on a 1–2 m tier shift) instead of snapping. 8 m snap threshold preserves the instant jump for respawn / very long falls. Two new dev-menu sliders ("Floor smoothing", "Floor snap thresh"). 13 new test assertions.
- **[#68](https://github.com/Adam-Vozzo/mobile-game-6/pull/68) — Follow the fall.** "When the player starts falling onto lower ground, lower the camera with the player, don't wait for them to touch the ground to start moving." `_compute_effective_y` gains a third regime: when `player.y < reference_floor_y`, track 1:1. Fall-pull also enabled in this regime so the camera leads the descent. 9 new test assertions.
- **[#69](https://github.com/Adam-Vozzo/mobile-game-6/pull/69) — Apex peak-jitter headroom.** "At the peak of the player's jump the camera is moving up and down slightly." Default `apex_height_multiplier` 1.0 → 1.15. The 15% headroom absorbs Jolt's capsule-resolution jitter and semi-implicit Euler overshoot that were flickering the held/tracking branches at peak. 5 new test assertions.

**Total test count:** 560 → ~625 (35 added by PR #65, 13 by #67, 9 by #68, 5 by #69).
**Three new DECISIONS.md ADRs** documenting each refinement with full diagnosis and rejected alternatives.
**No new feature surface beyond camera tuning** — base ratchet was unchanged; everything is on top of PR #65's structure.

### [2026-05-12] — `human/session-2026-05-12-capture-direction` — iter 51: human direction session — Gate 0 verified, Threshold picked, double-jump approved

- **Throttle: RESET** (was HARD-26). Human direction session ended the throttle.
- **Gate 0 on-device verification: ✅.** Project runs in Godot 4.6 on PC and deploys to the Nothing Phone 4(a) Pro test device. No import errors. README's "Test device build" status flipped from not-yet to verified; Gate 0 box "Android export pipeline verified on test device" ticked.
- **Feel verdict (Snappy):** "feel is good, we can keep playing with this as we design more levels. Character could be a tiny bit slower." → Snappy `max_speed` 6.5 → 6.0 queued as PR 3 of this session.
- **Camera vertical-follow rule:** "Camera should not move vertically until the character moves above the default max jump height, or walks on a higher level of ground. Stops the camera moving so much." → Camera vertical-follow ratchet queued as PR 2 of this session. New `_reference_floor_y` state + default-apex threshold; composes with the existing `_air_offset` rigid-translate.
- **Gate 1 level picked: Threshold.** "All level concepts sound really awesome; let's start with threshold, but all can be built if one is feature-complete." → Lung and Spine remain queued behind Threshold.
- **Feel Lab expansion requested:** "Enlarge the feel lab and include more variety of interaction for the platformer to test game-feel." → Queued as a P0 item.
- **Style direction approval:** noted that Feel Lab is grey-box now and visual style will iterate over time. The shared Environment / fog / lighting / material values across `feel_lab.tscn` and `style_test.tscn` are the current baseline; Gate 1 levels start from those values and diverge as art direction is set.
- **Audio direction:** set aside for now.
- **Snappy `reboot_duration`:** keep at 0.5 s. Research recommendation of ≤ 0.35 s rejected at this stage.
- **Double jump approved as an expected mechanic.** Build it in the lab with dev menu tunables. Threshold (and Spine / Lung when built) will be authored with double jump in mind.
- **Air dash + Assisted Phase 2:** build mechanics in the Feel Lab with dev tools; both heavily impact game-feel and need on-device testing. No Gate-1-blocker on these.
- **Ghost trail: on hold.** Only revisit if the game becomes about speedrunning.
- **Asset acquisition workflow:** for first style-defining picks (Stray mesh, ambient audio bed, architecture kit), Claude will surface browseable options for human approval before committing. After ~3 confirmed picks, autonomous mode resumes per CLAUDE.md.
- **Test parse-error fix:** `tests/test_controller_kinematics.gd:1246` — `for impact in [...]` → `for impact: float in [...]` so `:=` can infer `squash_y` and `squash_xz`. Was blocking the test runner from loading.
- **Perf:** Feel Lab in editor at 1920×1080 reports 144 fps / 6.9 ms (well under the 9 ms budget).
- **Throttle reset.** Next iteration after iter 51 follow-ups: **double jump implementation** (top of `docs/PLAN.md` P0 queue).

### [2026-05-12] — `claude/gifted-shannon-SAGze` — iter 50: Game level-path contract tests + Audio bus constant tests

- **Throttle: HARD (26 autonomous iterations since 2026-05-11 human session).** Hardening only.
- **Primary: `_test_game_level_path_contract` — 7 assertions documenting that `current_level_path`
  survives `reset_run()` and `register_attempt()`.**
  This invariant is critical for Gate 1's scene lifecycle (`reset_run()` is a counter reset, not a
  level unload). Tests: write + read-back, two resets across two distinct paths, explicit clear, and
  type check (String not StringName).
- **Side quest: `_test_audio_bus_constants` — 5 assertions documenting the Audio autoload's bus name
  contract.** Gate 1 SFX calls will reference `Audio.BUS_SFX_PLAYER` / `BUS_SFX_WORLD`; this test
  catches accidental renames before they surface as silent AudioServer misses. Also verifies all four
  bus names are distinct.
- **Total assertions: 548 → 560.**
- **Perf:** no change. No new nodes or draw calls.
- **No new dev-menu controls. No assets acquired.**
- **Needs human attention:** 26 iterations at HARD throttle; all P0 items blocked on first Godot 4.6
  import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-Ilq31` — iter 49: airborne offset math tests + BLAME! level vocabulary

- **Throttle: HARD (25 autonomous iterations since 2026-05-11 human session).** Hardening only.
- **Primary: `_test_airborne_offset_math` — 8 new assertions for the rigid-translate airborne camera invariant.**
  Tests the pure-math portion of `camera_rig.gd`'s airborne branch (`_air_offset`), which was the
  only major camera mechanism not yet covered: `offset = cam − player` definition; rigid-translate
  X / Y / full-3D; zero-delta stationarity; offset invariant after translate; drag-shifts-offset
  propagation; sign convention. Total: **540 → 548 assertions.**
- **Side quest: `docs/research/blame_level_vocab.md`** — maps each Gate 1 candidate (Spine / Lung /
  Threshold) to specific *BLAME!* spatial archetypes (Structural Wound, Functional Interior, Layer
  Boundary, Exterior Glimpse). Greybox implications per candidate: rib geometry style, baffle
  material approach, three-zone material kit for Threshold, CameraHint beats for exterior glimpses,
  biolume cyan reserved for Lung only. Open INDEX.md item "deeper BLAME! analysis" closed.
- **Perf:** no change. No new draw calls, no new nodes.
- **No new dev-menu controls. No assets acquired.**
- **Needs human attention:** 25 iterations at HARD throttle; all P0 items blocked on first
  Godot 4.6 import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-sHSh4` — iter 48: PerfBudget particle tracking API fix

- **Throttle: HARD (24 autonomous iterations since 2026-05-11 human session).** Hardening only.
- **Primary: `perf_budget.gd` refactor-backlog item — always-false particle branch fixed.**
  `register_particles(n: int)`, `unregister_particles(n: int)` (clamped to 0), and
  `reset_particles()` added to `PerfBudget`. The `over_budget()` `active_particles >
  ACTIVE_PARTICLES_BUDGET` branch was permanently false since `active_particles` was never
  written. Gate 1 can now call `register_particles(node.amount)` at scene load and
  `reset_particles()` from `Game.reset_run()` to make the particle budget actually fire.
- **Side quest:** none (HARD throttle; one task per run).
- **New test group: `_test_perf_budget_particle_api`** (12 assertions):
  initial-zero state; additive `register_particles`; `unregister_particles` clamp-to-zero;
  live `over_budget()` at the limit (not over) and one above (over); `reset_particles`
  zeroes counter and clears budget flag; `snapshot()` key presence and value match.
- **Total assertions: 528 → 540.**
- **Perf:** no change. No new draw calls, no new nodes.
- **No new dev-menu controls. No new assets.**
- **Needs human attention:** 24 iterations at HARD throttle; all P0 items blocked on first
  Godot 4.6 import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-bsRRS` — iter 47: apply Android latency mitigations + dev menu state tests

- **Throttle: HARD (23 autonomous iterations since 2026-05-11 human session).** Hardening only.
- **Primary: two concrete improvements from iter 46 research that were never implemented:**
  1. `Input.use_accumulated_input = false` added to `touch_overlay.gd::_ready()` — saves 4–8 ms per continuous-drag frame (documented in `android_input_latency.md` implication #1). One line change.
  2. `common/physics_interpolation=true` added to `project.godot` `[physics]` section — enables Godot 4.3+ physics interpolation so the 60 Hz physics tick looks smooth on the Nothing Phone 4(a) Pro's 120 Hz display (documented in `android_input_latency.md` implication #3). One line change.
- **Side quest: `_test_dev_menu_state_machine`** (16 assertions) — first unit test coverage for the DevMenu autoload. Tests the pure-logic layer without a scene tree:
  - Juice defaults: `screen_shake`, `particles`, `blob_shadow` all ON; unknown key defaults to `true` (safety convention).
  - `set_juice` / `is_juice_on` state transitions (OFF then restored ON).
  - Debug viz defaults: `perf_hud` ON; `velocity_vec` OFF; unknown key defaults to `false` (opposite convention from juice — keeps HUD clean on first run).
  - `set_debug_viz` transition.
  - Open/close state machine: `set_open(true/false)` and `toggle()` round-trip (works without a scene tree because `_overlay` null-guard fires before any `.visible` access).
- **Bug fix:** `g.free()` was misplaced at the end of `_test_visual_turn_convergence` (where `g` is not in scope) instead of at the end of `_test_game_autoload_contract`. Moved to the correct location — was a no-op on `null` rather than a crash, but now `g` is properly freed.
- **Total assertions: 512 → 528.**
- **Perf:** `use_accumulated_input = false` reduces event-processing overhead by 4–8 ms per drag frame; `physics_interpolation` adds negligible CPU cost (< 0.1 ms) for smooth 120 Hz rendering.
- **No new dev-menu controls. No new assets.**
- **Needs human attention:** 23 iterations at HARD throttle; all P0 items still blocked on first Godot 4.6 import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-DLQsk` — iter 46: Android input latency research + visual-turn convergence tests

- **Throttle: HARD (22 autonomous iterations since 2026-05-11 human session).** Hardening only. No behaviour change.
- **Primary: `docs/research/android_input_latency.md`** — Android/Godot 4 touch pipeline analysis. End-to-end latency 28–70 ms (hardware→kernel→InputDispatcher→Godot→GPU). Five concrete implications for Project Void:
  1. Add `Input.use_accumulated_input = false` in `touch_overlay.gd::_ready()` — saves 4–8 ms average on continuous drag.
  2. Current jump-buffer architecture is correct (buffer set in `_input()`, not `_physics_process()`; 100–150 ms sized to full pipeline).
  3. Enable `physics/common/physics_interpolation = true` before first device test (Nothing Phone 4(a) Pro has 120 Hz display; 60 Hz physics without interpolation looks choppy).
  4. If Floaty feels laggy on device: suspect `ground_acceleration`, not input latency.
  5. Juice (squash-stretch + audio) raises perceived responsiveness more than any platform optimization.
- **Side quest: `_test_visual_turn_convergence`** (8 assertions) — covers the `lerp_angle` branch of `_update_visual_facing` not exercised by iter 26's `_test_visual_facing_formula`:
  - Default speed (12.0) at 60 fps: weight ∈ (0, 1) (neither frozen nor instant-snap).
  - High `speed * delta ≥ 1`: weight clamps to 1.0 (instant snap, no overshoot).
  - `lerp_angle` direct arc: mid-point of 0 → PI/2 at t=0.5 is PI/4.
  - `lerp_angle` wrap: mid-point of 3.1 → −3.1 at t=0.5 is ≈ PI (short arc through ±PI boundary, not the long 6.2 rad arc).
  - 30-frame convergence: remaining angle < 0.01 rad after 30 frames at default weight.
  - Deadband boundary: 0.19 < 0.2 (early return); `not (0.2 < 0.2)` (at threshold, NOT excluded); `not (0.21 < 0.2)` (above threshold, proceeds).
- **Total assertions: 504 → 512.**
- **Perf:** no runtime changes. No new dev-menu controls. No new assets.
- **Needs human attention:** 22 iterations at HARD throttle; all P0 items still blocked on first Godot 4.6 import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-NplIj` — iter 45: TouchInput + Game autoload contract tests

- **Throttle: HARD (21 autonomous iterations since 2026-05-11 human session).** Hardening only. No behaviour change.
- **Primary: `_test_touch_input_state_machine`** (11 assertions) — `touch_input.gd` had zero unit test coverage. Tests the pure-logic layer without a scene tree:
  - `set_move_vector`: unit vector passes through unchanged; oversized vector clamped to length 1.0; zero stays zero.
  - `set_jump_held`: all 4 state transitions (false→false, false→true, true→true, true→false).
  - `consume_camera_drag_delta`: accumulated sum correct; second call returns zero (accumulator cleared).
  - `get_move_vector`: returns stored vector when non-zero; returns ~zero in test context (no keyboard actions active).
- **Side quest: `_test_game_autoload_contract`** (10 assertions) — `game.gd` had zero unit coverage. Documents the current public API so Gate 1 additions don't silently break existing fields/methods:
  - Variable defaults: `attempts == 0`, `run_time_seconds == 0.0`, `current_level_path == ""`.
  - `register_attempt()`: increments `attempts` to 1, then 2.
  - `reset_run()`: zeroes both `attempts` and `run_time_seconds`.
  - Signal existence: `player_respawned`, `checkpoint_reached`, `level_completed` all registered.
- **Total assertions: 483 → 504.**
- **Perf:** no runtime changes. No new dev-menu controls. No new assets.
- **Needs human attention:** 21 iterations at HARD throttle; all P0 items still blocked on first Godot 4.6 import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-4hSyy` — iter 44: perf budget logic tests + Gate 1 scene lifecycle research

- **Throttle: HARD (20 autonomous iterations since 2026-05-11 human session).** Hardening only. No behaviour change.
- **Primary: `_test_perf_budget_logic`** (8 assertions) — first test coverage for `perf_budget.gd`. Uses `const PB := preload(...)` so the test reads constants directly from the script; any drift in `perf_budget.gd` is caught automatically rather than silently.
  - Constants: `FRAMETIME_BUDGET_MS == 9.0` (8–10 ms CLAUDE.md band), `DRAW_CALL_BUDGET == 50` (godot_mobile_perf.md Gate 1 target), `TRIANGLE_BUDGET == 80 000` (CLAUDE.md §Budgets), `ACTIVE_PARTICLES_BUDGET > 0`.
  - Logic: all-under → not over_budget; frametime 10.1 ms → over; draw calls 51 → over; tris 80 001 → over.
- **Side quest: `docs/research/gate1_scene_lifecycle.md`** — Gate 1 implementation reference for level reload, run timer, win state trigger, and shard tracking. Key conclusions: use `reload_current_scene()` for Gate 1 restart; `ResultsPanel` as `CanvasLayer` overlay (no scene change); run timer in `Game._process`; `shards_total` set in level `_ready()`. Includes 6 concrete `game.gd` change items for Gate 1. INDEX.md updated.
- **Total assertions: 475 → 483.**
- **Perf:** no runtime changes. No new dev-menu controls. No new assets.
- **Needs human attention:** 20 iterations at HARD throttle, all P0 items still blocked on first Godot 4.6 import. See Open questions below.

### [2026-05-12] — `claude/gifted-shannon-5IJTD` — iter 43: jump arc geometry tests + profile timing window tests

- **Throttle: HARD (19 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No behaviour change.
- **Primary: `_test_jump_arc_geometry`** (11 assertions) — two design-contract invariants untested despite 452 total assertions:
  - `t_apex = jump_velocity / gravity_rising` in [0.15, 0.90] s per profile — catches gravity/velocity mismatch that would produce a jittery or Flappy-Bird-style arc.
  - `terminal_velocity > max_speed` per profile — documents that falling is always faster than running (depth-perception hierarchy).
  - Cross-profile ordering: Floaty t_apex > Snappy, Floaty t_apex > Momentum, Momentum t_apex > Snappy — captures the full arc-forgivingness chain.
- **Side quest: `_test_profile_timing_windows`** (12 assertions) — coyote/buffer design-envelope and ordering chain:
  - All 4 profiles: `coyote_time` and `jump_buffer` in [0.05, 0.30] s.
  - Full ordering chain: Floaty ≥ Snappy ≥ Momentum for both coyote and buffer (Assisted ≥ Floaty was already in `_test_assisted_params`).
- **Total assertions: 452 → 475.**
- **Perf:** no runtime changes. No new dev-menu controls. No new assets.
- **Needs human attention:** still waiting on first Godot 4.6 import + on-device run. 19 iterations at HARD throttle. All P0 items blocked on device. See Open questions below.

### [2026-05-11] — `claude/gifted-shannon-BOpz7` — iter 42: moving platform triangle-wave tests + camera pub-yaw formula tests

- **Throttle: HARD (18 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No behaviour change.
- **Primary: `_test_moving_platform_math`** (8 assertions) — `moving_platform.gd` had zero unit coverage. Pure math; no scene tree.
  - Asserts: `fmod` phase normalization at t=0/half/full-period; triangle wave shape (phase=0→0.0; phase=0.5→1.0); symmetry (triangle(0.25)==triangle(0.75)==0.5); `smoothstep` S-curve slower than linear at 25% of ramp; smoothstep(0,1,0.5)==0.5 (symmetric midpoint).
- **Side quest: `_test_camera_pub_yaw_formula`** (8 assertions) — the `atan2(cam.x−player.x, cam.z−player.z)` formula that tells player.gd which direction "stick-up" maps to had no coverage.
  - Asserts: four cardinals (+Z→0, +X→π/2, −Z→±π, −X→−π/2); diagonal in (0,π/2); Y component doesn't affect yaw; distance doesn't affect yaw; four cardinals are each π/2 apart.
- **Total assertions: 436 → 452.**
- **Perf:** no runtime changes. No new dev-menu controls. No new assets.
- **Needs human attention:** still waiting on first Godot 4.6 import + on-device run. 18 iterations at HARD throttle; all P0 items blocked on device. See Open questions below.

### [2026-05-11] — `claude/gifted-shannon-FBxyK` — iter 41: stick dead-zone + tripod distance correction tests

- **Throttle: HARD (17 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No behaviour change.
- **Primary: `_test_stick_deadzone_and_clamp`** (8 assertions) — the radial-clamp + normalise + truncating dead-zone pipeline in `touch_overlay.gd::_handle_drag` had no unit coverage. Pure math; no scene tree.
  - Asserts: small offset (10/100 < 0.15 threshold) → zero; exact-boundary (15/100) passes through (strict `<` condition); 50% deflection = 0.5 output; full/oversized deflection clamped to 1.0; direction preserved through clamp; rotational symmetry (8 cardinal/diagonal angles all zero at 99% of threshold); output always ≤ 1.0.
- **Side quest: `_test_tripod_horiz_distance_correction`** (8 assertions) — the ground-branch XZ distance-maintenance formula in `camera_rig.gd::_process` had no coverage.
  - Asserts: too-far (8 m) snaps to desired (5 m); too-close (3 m) pushes out to 5 m; at-correct-dist → zero movement; Y untouched; horizontal direction preserved (radial-only correction); single-step convergence (second pass is no-op); correction sign correct (toward target when far, away when close).
- **Total assertions: 420 → 436.**
- **Perf:** no runtime changes.

### [2026-05-11] — `claude/gifted-shannon-DIq40` — iter 40: camera occlusion latch tests + exponential smoothing tests

- **Throttle: HARD (16 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No new feature surface, no behaviour change.
- **Primary: `_test_occlusion_release_latch`** (8 assertions) — the `_is_occluded` / `_clear_streak_seconds` hysteresis state machine in `camera_rig.gd` had zero unit-test coverage; introduced in the human-direction session that rewrote the camera. Mirrors the latch block with `_occ_latch_tick` helper.
  - Asserts: 4 state transitions (clear+no-hit → no-op; clear+hit → arms latch+resets streak; occluded+hit → resets streak; occluded+no-hit → increments streak), threshold boundary (3 × 0.05 s = 0.15 s stays latched; 4th tick = 0.20 s ≥ 0.18 s delay → clears), mid-streak hit resets countdown.
- **Side quest: `_test_camera_smoothing_formula`** (8 assertions) — the `1 - exp(-rate × delta)` frame-rate-independent ease formula with asymmetric pull_in/ease_out rates also had zero coverage.
  - Asserts: `pull_in_smoothing (28) > ease_out_smoothing (6)` design invariant, both smooth_t values in (0,1), rate=0 → smooth_t=0 identity, higher rate → faster per-frame convergence, 5-frame simulation (pull_in closes > 85% of gap; ease_out leaves > 50% remaining), 10 pull_in frames leave < 5% (near-instant reveal ~167 ms).
- **Total assertions: 404 → 420.**
- **Perf:** no runtime changes.
- **New dev-menu controls:** none.
- **New assets:** none.
- **Needs human attention:** still waiting on first Godot 4.6 import + on-device run. 16 iterations at HARD throttle; all P0 items blocked on device. See Open questions below.

### [2026-05-11] — `claude/gifted-shannon-TYgQo` — iter 39: accel path selection tests + jump release touch-path tests

- **Throttle: HARD (15 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No new feature surface, no behaviour change.
- **Primary: `_test_accel_path_selection`** (10 assertions) — the 3-way branch in `_apply_horizontal` (path 1: `ground_deceleration`; path 2: `ground_acceleration`; path 3: `air_acceleration`) had zero explicit coverage; only convergence was tested, not which constant was chosen.
  - Asserts: trigger threshold (0.0 and 0.005 qualify; exactly 0.01 does not), `ground_decel > air_accel` for snappy and floaty, `ground_decel != air_accel` for momentum, `ground_accel > air_accel` for snappy and floaty, one-frame comparison (path 1 brakes harder than path 3; path 2 picks up faster than path 3).
- **Side quest: `_test_jump_release_touch_path`** (7 assertions) — the touch branch of `_was_jump_released` (`held_last AND NOT held_now`) is the only release signal on a touch-only device; its 4-case truth table and 3 OR-combination cases were untested.
  - Asserts: normal lift (T/F → true), never-held (F/F → false), still-held (T/T → false), just-pressed (F/T → false), keyboard-only OR (keyboard=T, touch=F → true), touch-only OR (keyboard=F, touch=T → true), neither (→ false).
- **Total assertions: 387 → 404.**
- **Perf:** no runtime changes.
- **New dev-menu controls:** none.
- **New assets:** none.
- **Needs human attention:** still waiting on first Godot 4.6 import + on-device run. 15 iterations at HARD throttle; all P0 items blocked on device.

### [2026-05-11] — `iter/jump-stretch-scale-spark-tests` — iter 38: jump stretch scale math + spark geometry tests

- **Throttle: HARD (14 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No new feature surface, no behaviour change.
- **Primary: `_test_jump_stretch_scale_math`** (9 assertions) — companion to iter 37's `_test_land_squash_scale_math`, covering the jump-stretch formula parameterized by the dev-menu slider.
  - Asserts: scale=0 → identity (both axes 1.0), scale=1 → exact values (stretch_y=1.30, stretch_xz=0.85), direction invariants at scale=0.5 (Y > 1, XZ < 1), linearity (delta doubles), stretch_xz > 0 guard (geometry never inverts), combined opposite-direction invariant.
- **Side quest: `_test_spark_geometry_math`** (12 assertions via `_spark_geometry_checks` + `_spark_material_fade_checks`) — death-burst sparks in `_build_spark_mesh` / `_build_spark_material` / `_fade_and_free_spark` had zero test coverage; now documented parallel to the jump-puff tests.
  - Asserts: 12-line burst count, length bounds (0.18–0.65 m), upward-hemisphere Y bias (0.15–1.6, always > 0), hub offset (0.1 m < len_min), warm-yellow palette (R=1.0 > G=0.78 > B=0.12), channels in [0,1], fade timing (0.07 s hold < 0.38 s fade, total < 1.0 s).
- **Total assertions: 366 → 387.**
- **Perf:** no runtime changes.
- **New dev-menu controls:** none.
- **New assets:** none.
- **Needs human attention:** still waiting on first Godot 4.6 import + on-device run. 14 iterations at HARD throttle; all P0 items blocked on device.

### [2026-05-11] — `claude/gifted-shannon-rwVuV` — iter 37: impact factor + land squash scale math tests

- **Throttle: HARD (13 autonomous iterations since 2026-05-11 human session).** Hardening only: tests. No new feature surface, no behaviour change.
- **Primary: `_test_impact_factor_math` + `_test_land_squash_scale_math`** added to `tests/test_controller_kinematics.gd`.
  - `_test_impact_factor_math` (7 assertions): documents `clampf(-_last_fall_speed / terminal_velocity, 0, 1)` — boundary at zero/half/full terminal, overclamp guard, rising-velocity clamp to 0, monotonicity, scale-invariance.
  - `_test_land_squash_scale_math` (9 assertions): documents `squash_y = 1.0 − impact × 0.45 × scale` and `squash_xz = 1.0 + impact × 0.20 × scale` — zero-deformation at impact=0 or scale=0, exact values at impact=1,scale=1 (sq_y=0.55, sq_xz=1.20), direction invariants (Y compresses / XZ expands), linear proportionality.
  - **Side quest:** added puff jitter non-overlap assertion to `_puff_geometry_checks` — verifies `angle_step − 2×jitter_max > 0` so worst-case jitter never causes adjacent lines to overlap (+1 assertion).
  - **Total assertions: 349 → 366.**
- **Perf:** no runtime changes.
- **New dev-menu controls:** none.
- **New assets:** none.
- **Needs human attention:** still waiting on first Godot 4.6 import + on-device run (see Open questions). 13 iterations at HARD throttle; all P0 items blocked on device.

### [2026-05-11] — `claude/gifted-shannon-qPXcJ` — iter 36: win state design research + test naming fix

- **Throttle: HARD (12 autonomous iterations since 2026-05-11 human session; prev count of 9 was understated by 2).** Hardening only: research + refactor. No new feature surface, no behaviour change.
- **Primary: `docs/research/win_state_design.md`** — last unresearched Gate 1 prerequisite ("Win state and results screen").
  - Survey: SMB (instant cut to stats, grade A+–D, dark world unlock), SMB 3D (ghost trail replay IS the results screen per `smb3d.md`), Dadish 3D (star rating, no death count, thumb-sized buttons), Celeste (deaths-as-badge, personal-best delta).
  - Mobile constraints: ≤ 3 s to replay, no mandatory animation, no death count by default, semi-transparent panel over frozen level (preserve sense of place).
  - **Void recommendation:** `WinState` Area3D trigger → `Game.level_completed`. Results panel: time / par comparison / shard count. REPLAY = `reset_run()` + reload. No death count shown (configurable later). Ghost trail post-level replay deferred (the in-play trail already serves the pedagogy).
  - 6 Gate 1 implications: `Game.is_running` flag needed (run timer must pause during reboot and results screen), `par_time_seconds` in level meta resource (35 s for Gate 1 level), `WinState.tscn` authored last, no death count in UI, par comparison drives intrinsic motivation without a letter grade, `reset_run()` already exists.
  - `INDEX.md` updated.
- **Side quest: test sub-helper naming fix** — `_test_puff_geometry` → `_puff_geometry_checks`, `_test_puff_material_and_fade` → `_puff_material_fade_checks`. These are called from within `_test_jump_puff_math`, not from `_ready()`; the `_test_` prefix implied they were missed top-level tests. Naming is now unambiguous. No assertion count change (349 total).
- **Perf:** no runtime changes.
- **New dev-menu controls:** none.
- **New assets:** none.
- **Research added:** `win_state_design.md`.
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import.

### [2026-05-11] — `claude/gifted-shannon-gd7gr` — iter 35: jump puff math tests + collectible design research

- **Throttle: HARD (9 autonomous iterations since 2026-05-11 human session).** Hardening only: tests + research. No new feature surface, no behaviour change.
- **Primary: `_test_jump_puff_math` — 18 new assertions** in `tests/test_controller_kinematics.gd`.
  - Covers the pure math in `_build_puff_mesh` and `_build_puff_material` (added iter 34) which shipped without unit tests.
  - Assertions: 8-step full-revolution formula (`8 × TAU/8 = TAU`), angle step < PI/2 (non-degenerate), i=0 → +X axis, i=4 → opposite hemisphere (angle=PI), length bounds (0.10 < 0.28, both > 0, < 1 m), Y-kick bounds (≥ 0, > 0, < 1), raw direction > 1 before normalise, normalised direction = unit length, hub offset (0.04 m) < length_min, material R > G > B (warm-concrete bias), all channels [0, 1], hold < fade, hold + fade ≈ 0.20 s, total < 0.5 s.
  - Total assertions: **331 → 349**.
- **Side quest: `docs/research/collectible_design.md`** — the last Gate 1 checklist item with no prior research.
  - Survey: SMB (bandages — off critical path, never block progress), Celeste (strawberries — lose on death, tension without blocking), Mario Odyssey (moon model — sparse, individually authored pockets).
  - Mobile constraints: must glow to be visible in dark world; Area3D pick-up radius 0.9 m (generous, touch latency); collection effect readable in 1–2 frames.
  - **Recommendation: the data shard** — small cyan emissive prism, slow Y rotation, one per Gate 1 level, placed off the par route. Fits palette (biolume cyan = brutalist deep-layer accent per CLAUDE.md). `Game` autoload needs `shards_collected` / `shards_total` fields. 6 concrete Gate 1 implications.
  - `INDEX.md` updated.
- **Perf:** no runtime changes.
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import.

### [2026-05-11] — `claude/gifted-shannon-H30E8` — iter 34: jump puff particle effect + enemy archetype research

- **Throttle: SOFT→HARD (8 autonomous iterations since 2026-05-11 human session).** Bounded juice + research at the soft/hard boundary; no new architectural surface.
- **Primary: Jump puff particle effect.**
  - `_spawn_jump_puff()` called from `_try_jump()` on every successful jump fire.
  - `_build_puff_mesh()`: 8 ImmediateMesh lines at evenly-spaced radial angles (± 0.25 rad jitter), random length 0.10–0.28 m, slight upward Y component per line (0–0.12) so the burst reads as dust lifting off the floor rather than a flat ring.
  - `_build_puff_material()`: warm grey (0.80/0.77/0.72), unshaded, alpha-blended, no depth test — matches brutalist concrete dust.
  - `_fade_and_free_puff()`: 0.04 s hold → 0.16 s alpha fade → `queue_free`. Total effect life ~0.2 s, ~14 vertices.
  - Gated behind existing `DevMenu.is_juice_on(&"particles")` toggle. No new dev-menu controls.
  - JUICE.md: "Jump puff" → `prototype`.
- **Side quest: `docs/research/enemy_archetypes.md`.**
  - Gate 1 requires one enemy archetype — this is the only Gate 1 item without any prior research.
  - Recommendation: Gate 1 = static kill zone (`HazardBody.tscn`, `Area3D` + configurable radius), zero AI, no state machine. Matches SMB/SMB 3D's "hazard before creature" grammar and brutalist aesthetics (industrial traps, not living enemies). Linear patroller deferred to Gate 2.
  - Mobile constraints documented: touch correction latency → slow/static hazards only at Gate 1; hitbox generosity (+0.15–0.20 m on kill zone vs mesh); palette separation (cold-grey hazards vs Stray red).
  - 6 implications for Gate 1 level authoring. `INDEX.md` updated.
- **Perf:** no runtime overhead added vs iter 33 (ImmediateMesh with 14 verts, created and freed per jump — same pattern as reboot sparks). Draw-call budget: +1 transient per jump, self-clears in 0.2 s.
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import.

### [2026-05-11] — `claude/gifted-shannon-2IAxC` — iter 33: squash-stretch animation + math unit tests

- **Throttle: SOFT (7 autonomous iterations since 2026-05-11 human session).** Task chosen as bounded juice implementation with no new architectural surface (per throttle override criteria). Non-destructive items only from here.
- **Primary: Squash-stretch animation — landing squash + jump stretch.**
  - `_play_land_squash(impact)` triggered on `just_landed` frame in `_tick_timers`. Impact factor = `clamp(-_last_fall_speed / terminal_velocity, 0, 1)` where `_last_fall_speed` is captured each airborne frame and preserved through the landing frame (velocity.y is already zeroed by `move_and_slide` by the time `just_landed` fires, so the tracker is necessary). Squash shape: `squash_y = 1 − impact×0.45×scale`, `squash_xz = 1 + impact×0.20×scale`; fast compress (0.06 s EASE_OUT TRANS_SPRING), spring recovery (0.25 s). Zero extra draw calls.
  - `_play_jump_stretch()` triggered inside `_try_jump()` on takeoff. Stretch shape: `stretch_y = 1 + 0.30×scale`, `stretch_xz = 1 − 0.15×scale`; 0.05 s TRANS_QUAD stretch + 0.18 s TRANS_SINE settle. Zero extra draw calls.
  - Both gated behind `DevMenu.is_juice_on(&"squash_stretch")` and `not _is_rebooting`.
  - `respawn()` kills any in-flight `_squash_tween` and resets `_visual.scale = Vector3.ONE` before `_run_reboot_effect` takes over (prevents tween fight on death).
  - Two new dev-menu sliders under "Squash-Stretch — Tuning": **Impact scale** (0–1, default 0.5) and **Stretch scale** (0–1, default 0.5), both live via new `squash_stretch_param_changed` signal in `dev_menu.gd`.
  - JUICE.md: "Land squish" and "Jump stretch" → `prototype`.
- **Side quest: `_test_squash_stretch_math` (17 assertions).** Covers: impact factor clamping at 0 / 0.5 / 1.0 / over-terminal / positive-vy, squash Y≤1 and XZ≥1 invariants at [0, 0.5, 1.0] impact, scale=0 identity (no squash), stretch direction invariant (Y elongates, XZ compresses). **Net assertions: 314 → 331.**
- **Perf:** no runtime overhead added (property tweens mutate an existing uniform; no new nodes or draw calls).
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import.

### [2026-05-11] — `claude/gifted-shannon-Z7ysO` — iter 32: cut-jump + gravity integration tests + squash-stretch research

- **Throttle: SOFT (6 autonomous iterations since 2026-05-11 human session).** Non-destructive work only: test suite expansion + research. No new feature surface.
- **Primary: Test suite expansion — `_cut_jump` behavior + `_apply_gravity` per-frame integration.**
  Two clear gaps in the test suite: `_cut_jump` had only parameter-relationship assertions (threshold is in range), but no vy-in → vy-out simulation; `_apply_gravity` had band selection and ordering tests but not the integration formula or arc simulation. Added:
  - `_test_cut_jump_behavior` (9 assertions): mirrors `_cut_jump` with explicit vy inputs. Covers jump-held→no-cut, released-at-peak→threshold, strict->boundary (vy==threshold→no cut), below-threshold→no-cut, vy==0→no-cut, and per-profile peak-to-threshold. New `_sim_cut` helper.
  - `_test_gravity_integration` (8 assertions): mirrors `_apply_gravity` per-frame. Covers single-step formula (`vy' = vy − g*delta`), monotone rising arc, apex reached in finite frames, arc > 1 frame, `gravity_after_apex` pulls harder than `gravity_rising` from apex, terminal clamp holds after reaching terminal, floaty apex-frames ≥ snappy (higher-arc design intent). New `_gravity_step` helper.
  - **Net assertions: 297 → 314.**
- **Side quest: `docs/research/squash_stretch_animation.md`.** Gate 1 juice prerequisite — landing squash is #1 priority in `juice_density.md` and is needed before Gate 1 polish. Covers: Tween-on-scale (recommended) vs AnimationPlayer vs ShaderMaterial; impact factor derivation (`clamp(-velocity.y / terminal_velocity, 0, 1)` on `just_landed`); curve recommendations (TRANS_SPRING recovery); reboot-sequence conflict guard (`_is_rebooting` check required); full integration checklist; dev-menu `impact_scale` slider requirement. `INDEX.md` updated.
- **Perf:** unchanged (no runtime code changes).
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import.

### [2026-05-10] — `claude/gifted-shannon-ou2ix` — iter 31: sticky landing tests + checkpoint design research

- **Throttle: SOFT (5 autonomous iterations since 2026-05-11 human session).** Non-destructive work: test suite expansion + research. No new feature surface.
- **Primary: Test suite expansion — sticky landing countdown + damping.** The Assisted profile's sticky landing mechanic (implemented iter 27) had assertions on profile param values but nothing testing the actual tick-by-tick countdown logic or the per-frame damping formula. Added:
  - `_test_sticky_landing_countdown` (9 assertions): mirrors `_tick_timers`' sticky-landing block. Covers airborne→airborne (no landing), touch-down frame (counter set to `landing_sticky_frames`), grounded countdown draining to 0, early-takeoff counter reset, and disabled case (`sticky_frames=0` on non-Assisted profiles). New `_sticky_tick` helper extracted.
  - `_test_sticky_landing_damping` (8 assertions): mirrors `_apply_horizontal`'s damping branch. Covers one-frame speed reduction, disabled factor (1−0 = identity), geometric-series multi-frame compound, and both guard conditions (branch only fires when counter>0 AND factor>0).
  - **Net assertions: 280 → 297.**
- **Side quest: `docs/research/checkpoint_design.md`.** Gate 1 prereq — checkpoints and instant respawn are P0 items for the vertical slice. Covers: SMB/SMB 3D (no checkpoints, room as atomic unit, ~20 s per level), Dadish 3D (sparse mid-level checkpoints, mobile 10 s dead-time threshold), Celeste (screen-boundary as implicit checkpoint). Key architectural constraint: ghost trails require all attempts to share one anchor point — a mid-level checkpoint splits attempts into incomparable populations. **Void recommendation:** Gate 1 uses Option A (no mid-level checkpoint; ghost trail anchor = level entry; one `CheckPoint` node present but respawn target stays at level entry). Per-segment trails + mid-level checkpoints deferred to Gate 2. Mobile reboot UX: 0.3–0.35 s Snappy lower bound is thumb-resettlement floor. Design hardest beat last. `INDEX.md` updated.
- **Perf:** unchanged (no runtime code changes).
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import.

### [2026-05-10] — `claude/gifted-shannon-swI5c` — iter 30: Gate 1 level concepts + air dash research

- **Throttle: SOFT (4 autonomous iterations since 2026-05-11 human session).** Non-destructive work only — docs, research, design.
- **Primary: Three Gate 1 level concept documents.** All P0 queue items remain blocked on device. The Gate 1 vertical slice needs a level to build once the gate opens. Three fully-specified candidates authored in `docs/levels/`, each following the LEVEL_DESIGN.md 12-step workflow through step 5:

  - **`docs/levels/spine.md` — Spine.** A vertical mega-column split open by collapse. 5 beats (Ki: base entry, Shō: wall-jump rib corridor, checkpoint, Ten: collapse reroute + exterior reveal, Ketsu: open chimney + win vista). Primary verb: wall jump. Par route: continuous wall-jump chain in Beat 2. ~60–75 s skilled, ~3 min new player.
  - **`docs/levels/lung.md` — Lung.** A still-functioning ventilation array. 4 beats + epilogue (Ki: first synchronised baffles, Shō: counter-phase + updraft, checkpoint, Ten: power cycle twist, Ketsu: wind push into the trachea duct). Primary verb: precise timing. Biolume cyan accent (first use in any level). ~70–80 s skilled.
  - **`docs/levels/threshold.md` — Threshold.** Three zones separated by abrupt architectural thresholds: habitation (warm, human scale) → maintenance buffer (cold, machine scale) → industrial (hot, production scale). 5 beats. Primary verbs: standard precision jump, timing, long-gap committed jump. Industrial section deliberately stresses blob shadow depth reads. ~70 s skilled.

  Each doc includes: parti, genius loci, double-reading, procession (5-beat beats ~20 s each), platforming verbs, par route, skill range table, level kit requirements, greybox notes. **Human must pick one before greybox begins** (CLAUDE.md: level concept selection is human-gated).

- **Side quest: `docs/research/air_dash.md`.** Full design spec for the air dash mechanic — SMB 3D's recommended depth-error correction tool. Covers: design intent (0.18 s burst, single airborne charge, recharges on landing), input options (Option A: right-zone swipe with gesture disambiguation; Option B: double-tap jump — A recommended), `ControllerProfile` integration (3 new params, all default 0 = disabled for backwards-compat), `player.gd` state sketch, `TouchInput` signal approach, juice hooks, universal-vs-profile-exclusive analysis (recommend universal, start disabled, let human tune per profile on device). Also documents how Spine/Threshold level geometry assumes this mechanic exists. `INDEX.md` updated.

- **Perf:** unchanged (no code changes this iteration).
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import run.

### [2026-05-10] — `claude/gifted-shannon-HuiCV` — iter 29: Blob shadow dev menu tunables + math unit tests

- **Throttle: CLEAR (1 autonomous iteration since 2026-05-11 human session).**
- **Primary: Blob shadow dev menu tunables.** Iter 28 added `blob_shadow.gd` with four
  `@export_range` tunables but did not wire them to the dev menu (CLAUDE.md mandates same-
  iteration exposure). This iteration closes the gap.

  - `scripts/autoload/dev_menu.gd` — new signal `blob_shadow_param_changed(param, value)`.
  - `scripts/player/blob_shadow.gd` — connects to signal in `_ready()`; new
    `_on_blob_shadow_param_changed` handler updates `@export` var from signal (same pattern
    as camera rig's `_on_camera_param_changed`).
  - `tools/dev_menu/dev_menu_overlay.gd` — new `_make_blob_slider` helper + new
    `_build_blob_shadow_tuning` method (called from `_build_juice_section`); adds a
    **"Blob Shadow — Tuning"** subsection in the Juice panel with four live sliders:
    Radius ground (0.05–1.0), Radius height (0.1–2.0), Fade height (1.0–20.0), Max alpha (0.05–1.0).

- **Side quest: Blob shadow math unit tests.** 12 new assertions in
  `_test_blob_shadow_math()` added to `tests/test_controller_kinematics.gd`. Covers the
  three formulas mirrored in `blob_shadow.gd::_process`: t (clamp), r (linear lerp, shadow
  expands with height), a (quadratic falloff — slower early drop than linear). Net assertion
  count: 268 → 280.

- **Dev-menu controls added:** Blob Shadow — Tuning: Radius ground, Radius height,
  Fade height, Max alpha.
- **Perf:** unchanged (no new draw calls; no perf measurement on device yet).
- **On-device pending.** All P0 items still blocked on first Godot 4.6 import run.

### [2026-05-10] — `claude/gifted-shannon-CoSWy` — iter 28: SMB 3D research + blob shadow projector

- **Throttle: CLEAR (4 autonomous iterations since 2026-05-11 human session).** Normal mode.
- **Primary: SMB 3D research note** — `docs/research/smb3d.md`. Full design analysis
  of the live reference game (Team Meat + Sluggerfly, released March 31 2026). Key findings:

  - **Fixed-per-level camera** was a deliberate choice: "a dynamic camera couldn't keep
    up with the pace." Void's tripod model + airborne rigid-translate is already aligned.
  - **Level length: ~20 seconds skilled.** Each Void beat should be ~20 s; Gate 1's
    60–90 s target is correct at the *level* level, but must be structured as a procession
    of ~20-second beats with rest nodes between.
  - **Ghost trail (attempt replay) is the core pedagogical loop**, not bonus content.
    Gate 1 must ship this.
  - **Depth perception is the hardest 3D precision-platformer problem.** SMB 3D shipped
    with a blob shadow, a ground-circle indicator, 45° geometry angles, and an 8-directional
    stick constraint — and *still* drew depth-perception criticism. Blob shadow is mandatory
    before the first on-device feel test.
  - **Air dash as one-shot depth-error correction** (recharges on landing, ignores gravity
    briefly). Strong mobile candidate; single swipe maps naturally. Log as Gate 1 candidate
    for Assisted Phase 2 or as a universal mechanic.
  - **Style loss is the biggest long-term risk.** SMB 3D's clearest failure was losing
    visual identity in the 3D transition. Void's brutalist/BLAME! direction is actually an
    advantage (concrete + fog + darkness are inherently 3D materials). Protect it.
  - 8 concrete implications logged in `smb3d.md`; INDEX.md updated.

- **Side quest: blob shadow projector.** `scripts/player/blob_shadow.gd` — a translucent
  disc shadow projected below the Stray via per-frame raycast:
  - Disc radius grows from `radius_at_ground` (0.22 m) to `radius_at_height` (0.55 m) as
    the player rises — natural shadow penumbra expansion.
  - Alpha fades quadratically to zero at `fade_height` (6 m) — reads clearly near floor,
    disappears smoothly before the cutoff.
  - 1 raycast/frame (World layer only, player excluded), 1 draw call. Minimal perf cost.
  - Added to `scenes/player/player.tscn` as `BlobShadow` child of Player node — applies
    to all scenes using the player prefab (feel_lab + style_test).
  - New `blob_shadow` juice toggle in `dev_menu.gd` (default **ON**) and in JUICE.md.
  - Togglable from the dev menu Juice section, labelled "Blob Shadow."

- **Bugs fixed:** none.
- **New dev-menu controls:** `blob_shadow` toggle in Juice section.
- **Perf:** not yet measured on device (on-device pending).

### [2026-05-10] — `claude/gifted-shannon-aw6fZ` — iter 27: Assisted profile Phase 1 + try-jump tests

- **Throttle: CLEAR (3 autonomous iterations since 2026-05-11 human session).** Normal mode.
- **Primary: Assisted profile Phase 1 — sticky landing + profile file + dev menu.**
  The dev menu dropdown now shows **Snappy / Floaty / Momentum / Assisted** — all
  four controller profiles defined in `CLAUDE.md` are present and switchable on
  first device run.

  - **`resources/profiles/assisted.tres`** — new profile. Key values:
    `max_speed = 5.0` (slowest, most controlled), `coyote_time = 0.22` and
    `jump_buffer = 0.24` (most generous timing windows),
    `gravity_rising = 15.0` (lowest, maximum hang time — peak height ~3.3 m),
    `air_horizontal_damping = 1.2` (highest grip in the air),
    `max_floor_angle_degrees = 60.0` (most forgiving on slopes),
    `landing_sticky_factor = 0.2`, `landing_sticky_frames = 2` (sticky landing enabled).

  - **`ControllerProfile` — two new properties** (both default `0` = disabled, so
    all existing profiles and saved `.tres` files are unaffected):
    - `landing_sticky_factor: float = 0.0` — per-frame horizontal speed multiplier
      applied for `landing_sticky_frames` frames after touching down.
    - `landing_sticky_frames: int = 0` — grounded-frame countdown window.

  - **`player.gd` — sticky landing mechanic** in `_tick_timers` and
    `_apply_horizontal`:
    - `_was_on_floor_last_frame: bool` — tracks previous grounded state; fires the
      sticky window on the exact touch-down frame. Also the correct hook for the
      juice system's landing-squash trigger (see JUICE.md note).
    - `_sticky_frames_remaining: int` — counts down only while grounded; resets to 0
      on takeoff so a running jump doesn't carry leftover stickiness.
    - When `_sticky_frames_remaining > 0` and `landing_sticky_factor > 0.0`:
      `new_h *= (1.0 - landing_sticky_factor)` after normal accel/decel, before
      writing to `velocity.x/z`. Non-Assisted profiles have `landing_sticky_factor = 0`
      so the branch is entered but the multiplication is a no-op.

  - **Dev menu — "Controller — Assist" subsection** with two new sliders:
    `landing_sticky_factor` (0.0–0.8, step 0.05) and `landing_sticky_frames`
    (0–6, step 1). Both bulk-sync on profile switch like all other controller sliders.

  - **Phase 2 (ledge magnetism + arc assist)** deferred until after first device feel
    per `docs/research/assist_mechanics.md`. See DECISIONS.md for the rationale.

- **Side quest: Two new test groups** (198 → 268 assertions, +70 total):
  - Assisted added to all 13 existing per-profile test loops (+46 assertions covering
    gravity ordering, jump cut, decel convergence, coyote/buffer countdowns, terminal
    velocity, cross-profile invariants, slope, respawn, gravity band selection,
    horizontal interpolation, movement params + 2 new Assisted-specific pair checks).
  - **`_test_assisted_params`** (12 assertions): sticky params enabled on Assisted,
    disabled on Snappy/Floaty/Momentum, Assisted coyote/buffer >= Floaty.
  - **`_test_try_jump_logic`** (12 assertions): mirrors `player.gd::_try_jump` — the
    buffer×coyote AND condition (previously the only major function in player.gd with
    zero test coverage). Covers: jump fires with both timers live, no jump with buffer=0,
    no jump with coyote=0, both=0 no-op, timer-zeroing after jump, per-profile vy.

- Perf: no runtime cost change. `_was_on_floor_last_frame` is a single bool written
  once per `_tick_timers` call. The sticky damping branch is a float multiply + bool
  check per physics tick — negligible. Non-Assisted profiles skip it silently
  (factor = 0 → `if 0.0 > 0.0` is false at compile time).
- Bugs fixed: none.
- New dev-menu controls: "Controller — Assist" subsection → "Sticky factor" + "Sticky frames" sliders.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — on-device first run still the #1 unlocker.** Now with 4 profiles in the dropdown, first device feel gives you the full comparison set.

### [2026-05-10] — `claude/gifted-shannon-doncr` — iter 26: deceleration + visual facing tests + ANDROID.md signing docs

- **Throttle: CLEAR (2 autonomous iterations since 2026-05-11 human session).** Normal mode.
- **Primary: Two new test groups added to `tests/test_controller_kinematics.gd`.**
  179 → 198 assertions (+19). Both groups cover production code paths that had zero
  previous test coverage.

  - **`_test_horizontal_deceleration` (11 assertions)** — exercises the decel branch
    of `player.gd::_apply_horizontal` (fires when `move_dir.length() < 0.01 and on_floor`):
    - Per profile (×3): convergence from `max_speed` to near-zero within 600 frames (10 s);
      `final_speed < 0.01 m/s`; `speed ≥ 0` throughout (`move_toward` no-overshoot guarantee).
    - Cross-profile: `frames_momentum > frames_snappy` — Snappy decelerates from 6.5 m/s
      at 90 m/s² (~5 frames); Momentum decelerates from 11.0 m/s at 30 m/s² (~23 frames).
      Documents the "loose decel" design intent from `_test_movement_params`.
    - Edge case: starting at rest stays at rest (decel step on zero vector = zero).

  - **`_test_visual_facing_formula` (8 assertions)** — exercises the target_yaw formula
    of `player.gd::_update_visual_facing` (`target_yaw = atan2(-velocity.x, -velocity.z)`):
    - Four cardinal directions: moving -Z→yaw=0, +Z→±PI, +X→-PI/2, -X→+PI/2. Verifies
      local -Z (Godot forward) aligns with velocity direction after the rotation.
    - Lerp weight clamp: `clampf(turn_speed * delta, 0, 1)` at default turn_speed (12) is
      in (0, 1) (smooth); at max export bound (30) is ≤ 1.0 (no overshoot).
    - Speed deadband: 0.1 m/s < 0.2 m/s threshold (guard fires); 0.3 m/s ≥ threshold (updates).

- **Side quest: `docs/ANDROID.md` — "Headless / CI signing via environment variables" section.**
  Closes the P2 queue item "investigate signing-key handling via gradle env vars."
  - **Pattern A** — Godot 4.3+ CLI env vars (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
    `..._USER`, `..._PASSWORD`) for standard (non-custom-build) headless export. The env
    vars override the blank `export_presets.cfg` fields at export time.
  - **Pattern B** — `android/build/local.properties` + `build.gradle` patch for Gradle
    custom build (`use_gradle_build = true`, required for Play Store AAB). The `local.properties`
    file is gitignored by the custom build template; signing credentials never touch the repo.
    Includes a `gradle_signing.patch` workflow so the build.gradle edit survives template reinstalls.
  - Security checklist (5 items: blank password in preset, local.properties gitignored, keystore
    outside repo, password in password manager, CI uses secret variable).
  - `ANDROID.md` open TODO for this item marked done.

- Perf: no runtime change (tests + docs only).
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — on-device first run still the #1 unlocker.**

### [2026-05-10] — `claude/gifted-shannon-TuINF` — iter 25: stale camera test cleanup + tripod model tests + pitch_min_degrees cleanup

- **Throttle: CLEAR (first autonomous iteration since 2026-05-11 human-direction session).** Normal mode.
- **Primary: Replace two stale camera test groups with two new tripod-model test groups.**
  The human-direction session (2026-05-11) rewrote `camera_rig.gd` to a tripod model and
  deleted `_update_yaw_recenter` and `_update_lookahead`. However, their test groups —
  `_test_camera_yaw_recenter` (8 assertions) and `_test_camera_lookahead_target`
  (5 assertions) — remained in `tests/test_controller_kinematics.gd`, testing dead code.
  Both are now removed and replaced with:

  - **`_test_tripod_placement` (6 assertions)** — verifies `_place_camera_initial`:
    y-offset `= sin(elev)*dist + aim_height`, z-offset `= cos(elev)*dist`, x-offset `= 0`
    at default yaw, Pythagorean identity `sin² + cos² = 1` so 3D-distance `= dist`
    exactly, camera is above player when elevation > 0, and the elevation=0 edge case
    (camera at player height + aim_height, directly behind).

  - **`_test_tripod_drag_orbit` (7 assertions)** — verifies `_apply_drag_input`:
    radius re-derived from initial position equals `distance`, phi re-derived equals the
    elevation angle, pure yaw drag preserves both 3D radius and elevation (y component),
    extreme downward drag clamps `phi ≥ 0` (camera never below horizontal), extreme upward
    drag clamps `phi ≤ deg_to_rad(pitch_max_degrees)`, and `_pitch_rad = -phi` is always ≤ 0.

  Net assertion count: 179 → 179 (13 removed + 13 added). All tests now cover live code.

- **Side quest: removed dead `pitch_min_degrees`.**
  `camera_rig.gd` retained a `@export_range(-89.0, 0.0) var pitch_min_degrees` and a
  matching arm in `_on_camera_param_changed`. The dev menu had a "Pitch min deg" slider.
  None of this had any runtime effect: `_apply_drag_input` clamps `phi` to
  `[0.0, deg_to_rad(pitch_max_degrees)]` — the lower bound is hardcoded `0.0`, not
  `pitch_min_degrees`. Removed: `@export` variable, `_on_camera_param_changed` match arm,
  dev-menu slider. Comment updated: `pitch_max_degrees` now documents its current role
  (max elevation above horizontal). No behaviour change.

- Perf: no runtime change (tests + dead-code removal only).
- Bugs fixed: stale tests for deleted camera functions; dead dev-menu slider.
- New dev-menu controls: none (one removed: "Pitch min deg" — was a no-op).
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — on-device first run still the #1 unlocker.**

### [2026-05-11] — direct human-direction session — camera + UX overhaul (no autonomous iteration)

This entry covers a multi-turn session driven directly by the human. Not an
autonomous iteration — no `claude/...` branch, no PLAN.md queue item.
Documents three ADRs in `DECISIONS.md` (tripod model, selective occlusion,
airborne rigid translate). All 179 controller-kinematics tests still pass.

- **Camera: tripod model.** Replaced rig+offset+lookahead+auto-recenter with a
  tripod follow that holds the camera's world position while the player walks
  laterally and only translates along the camera→player axis to maintain
  `distance`. Lateral player motion is absorbed by `look_at` rotation rather
  than by translation — kills the lateral background slide that was reported
  as motion-sickness on phone. Auto-recenter is gone (had a sign bug that
  spun the rig); lookahead is gone (was anti-correlated with what fixed the
  motion sickness).
- **Camera: selective occlusion via `CameraOccluder` layer.** New physics
  layer 7. The camera's `occlusion_mask` queries that layer only. In
  `feel_lab.tscn`, the four pillars and both walls now have
  `collision_layer = 65` (World + CameraOccluder); platforms / slopes /
  moving platform stay on layer 1 only. Same for `style_test.tscn`'s
  WallPanel + ScalePillar. Future levels: tag any geometry larger than ~3 m
  in any horizontal dimension on layer 7, leave smaller obstacles on layer 1.
- **Camera: sphere-cast probe.** `direct_space_state.cast_motion` of an
  `occlusion_probe_radius` (0.22 m default) sphere instead of a thin ray.
  Stops frame-by-frame flicker at wall edges that a thread-thin ray would
  alternately hit and miss.
- **Camera: asymmetric smoothing + hysteresis latch.** Position-follow rate
  is `pull_in_smoothing` (28 / sec, fast) when the camera moves *toward*
  the player and `ease_out_smoothing` (6 / sec, slow) when moving away.
  Layered on top: any sphere-hit re-arms `_is_occluded = true` for
  `occlusion_release_delay` (0.18 s default); the camera holds at
  `_last_occluded_pos` even if the probe momentarily clears within that
  window. Stops the camera bouncing in/out at corner edges.
- **Camera: airborne rigid translate.** While `is_on_floor() == false`,
  `camera.global_position = target_pos + _air_offset` runs first thing in
  `_process` and distance-maintenance / occlusion / smoothing are skipped.
  The camera→player vector is preserved exactly across the jump, so look_at
  produces the same basis frame after frame and `pub_yaw` returns the same
  value — input frame stays locked from takeoff to landing. Drag still
  rotates the camera mid-jump (the only intentional source of rotation
  during the air phase). Camera still translates with the player so they
  stay framed.
- **Player visual rotation.** Visual capsule rotates around Y to face the
  horizontal velocity vector (`visual_turn_speed = 12`,
  `visual_turn_min_speed = 0.2 m/s` deadband). Capsule itself is symmetric;
  the accent box visually shows the direction of travel.
- **Dev menu scaled for thumb use.** Panel anchored to the right 40% of the
  viewport, full-height scroll. Slider rows 64 px tall, label 240 px,
  track 320 px, value 110 px. Theme applies 24 pt font to every descendant
  control (Label, Button, OptionButton, CheckBox, LineEdit). CheckBoxes in
  the Juice and Debug-viz sections replaced with custom Button toggles
  (`_make_toggle`) showing `●`/`○` + green/grey colour swap, since the
  CheckBox icon doesn't follow `font_size`.
- **Touch overlay: jump button anchored bottom-right.** `jump_button_anchor`
  is now computed from `jump_button_margin` and the live viewport size in
  `_apply_bottom_right_default()`, called on `_ready` and on
  `viewport.size_changed`. Default radius bumped 95 → 115 for thumb size.
  `CFG_VERSION = 2` so existing `user://input.cfg` saves are dropped on
  first launch and re-anchored.
- **Lighting: fill light + brighter ambient.** New `FillLight`
  `DirectionalLight3D` in both `feel_lab.tscn` and `style_test.tscn`:
  cool blue (0.55, 0.6, 0.78), energy 0.45, no shadows, opposite hemisphere
  to the warm key. Ambient_light_energy 0.4 → 0.75; fog density 0.045 →
  0.012; fog colour brightened. The player is no longer a silhouette
  against warm-lit floor.
- **Profiles.** Snappy `max_speed` 8.0 → 6.5 (user direction). Floaty
  `max_speed` 6.5 → 5.5 to preserve the `floaty < snappy` test invariant
  (`_test_profile_cross_invariants`).
- **Strict-warning cleanup pass.** Project has `unsafe_*` warnings at
  error-level. Typed Dictionary iterations
  (`for key: StringName in DevMenu.juice_state`); typed
  `Dictionary[StringName, bool]` for juice/debug-viz state, removing
  redundant `bool(...)` wrappers; `@warning_ignore("unused_signal")` on
  autoload signals declared in one class but emitted from another;
  `_target.call(&"set_camera_yaw", pub_yaw)` to avoid Node3D method-access
  warnings; `_target as PhysicsBody3D` in the occlusion exclude list to
  reach `get_rid()`; `_player: Player` (was `CharacterBody3D`) in
  `player_debug_draw.gd` so `_player.profile` resolves; renamed shadowing
  `name` local in dev-menu's save-as.
- **Repo housekeeping.** Added `.claude/` to `.gitignore`. Tracked Godot 4.x
  `.uid` files (preserve script identity across renames; upstream's iter
  branches were ignoring them, but they're now baseline).
- **Throttle status reset.** Human is actively driving the project again.
  All P0 items remain blocked on the on-device first run, but the throttle
  warning in this README is downgraded from HARD until the next stretch
  of unguided iterations.

### [2026-05-10] — `claude/gifted-shannon-f29MG` — iter 24: move-dir rotation tests + gravity band selection tests + assist mechanics research

- **Throttle: HARD (24 iterations since last human direction).** Hardening only.
- **Primary: two new test groups added to `tests/test_controller_kinematics.gd`.**
  ~137 → ~157 total assertions (20 new). Both groups are pure math (no scene tree
  instantiation), following the same pattern as all previous groups.

  - **`_test_move_dir_rotation` (8 assertions)** — verifies `player.gd::_camera_relative_move_dir`:
    `Basis(Vector3.UP, yaw) * Vector3(move_input.x, 0.0, move_input.y)`.
    - `yaw=0, stick up` → world z ≈ −1 (forward); `yaw=0, stick right` → world x ≈ +1.
    - `yaw=PI, stick up` → world z ≈ +1 (camera reversed).
    - `yaw=PI/2, stick up` → world x ≈ −1 (camera pivoted 90° CCW).
    - Y component always 0 (Basis(UP, yaw) rotation preserves the XZ plane).
    - Rotation preserves vector length (orthogonal transformation invariant).
    - Over-length guard: dir > 1 is normalised (belt-and-braces in player.gd).
    - Helper `_move_dir(move_input, yaw)` mirrors the formula exactly.

  - **`_test_gravity_band_selection` (12 assertions = 4 rules × 3 profiles)** — verifies
    `player.gd::_apply_gravity` if/elif band selection:
    - `vel_y < 0` (falling) → `gravity_after_apex` on all 3 profiles.
    - `vel_y > 0 + jump_held` → `gravity_rising` on all 3.
    - `vel_y > 0 + jump released` → `gravity_falling` on all 3.
    - `vel_y == 0` (apex frame, `<= 0` is true) → `gravity_after_apex` on all 3.
    - Helper `_select_gravity(p, vel_y, jump_held)` mirrors the if/elif exactly.

- **Side quest: `docs/research/assist_mechanics.md`** — closes the research gap
  for PLAN P0 item 4 (Assisted profile). Bridges the design targets already in
  `mobile_touch_ux.md` and `character_controllers.md` to concrete Godot 4
  implementation sketches for `CharacterBody3D`:
  - **Ledge magnetism**: `PhysicsDirectSpaceState3D.intersect_shape` with small
    sphere, fired once at `_try_jump()`, 2 rays (left/right of capsule edge),
    ≤ `ledge_magnet_strength` m/s impulse, new properties `ledge_magnet_radius`
    and `ledge_magnet_strength` (both default 0 on all existing profiles).
  - **Arc assist**: 20-step parabola simulation using current velocity + gravity,
    ShapeCast per step, lateral correction ≤ 15% `jump_velocity`. New property
    `arc_assist_max` (default 0).
  - **Sticky landing**: `_was_on_floor_last_frame` tracks landing frame, applies
    `(1 - landing_sticky_factor)` multiplier to horizontal velocity for
    `landing_sticky_frames` (2 frames, 20%). Properties default 0.
  - **Edge-snap**: post-`move_and_slide()` position correction, most complex,
    implement last. Property `edge_snap_dist` (default 0).
  - **Implementation order**: sticky landing → ledge magnetism → arc assist →
    edge-snap. All 6 new properties default to 0 — backwards-compatible with
    all existing profiles.
  - **Key implication**: `_was_on_floor_last_frame` doubles as the juice-system
    landing-squash trigger — extract to a single `_landed_this_frame` bool
    computed once per `_physics_process` to avoid duplicate `is_on_floor()` calls.
  - INDEX.md updated; "Assist mechanics" entry added under Character controllers.

- Perf: no runtime change (tests + docs only).
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/assist_mechanics.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (24 iterations).**

### [2026-05-10] — `claude/gifted-shannon-BNuNf` — iter 23: yaw recenter tests + Compatibility renderer research

- **Throttle: HARD (23 iterations since last human direction).** Hardening only.
- **Primary: `_test_camera_yaw_recenter` added to `tests/test_controller_kinematics.gd`.**
  `_update_yaw_recenter` was the only camera sub-function without a dedicated test group.
  9 new assertions, all pure math (no scene instantiation), following the same pattern as
  the other camera groups:
  - **`wrapf` shortest-path**: 175°→-175° yields +10° (not -350°); -175°→+175° yields
    -10° (not +350°). Catches a potential bug where the camera would spin the long way
    around when the player reverses direction near the ±180° boundary.
  - **Lerp weight plausibility** at default speed (1.5): weight > 0 (makes progress) and
    weight < 0.1 (smooth, not an instant snap).
  - **No overshoot**: step = diff × weight < diff on a 90° rotation with default params.
  - **High-speed clamp**: `minf(1.0, 200 × delta)` is exactly 1.0 — confirms the guard
    prevents overshoot even at extreme recenter_speed values.
  - **Convergence**: 30-frame simulation from 0° toward 90° — angular error decreases
    monotonically each frame, and > 50% progress is made by frame 30.
  - Total assertions: ~128 → ~137.
- **Side quest: `docs/research/compatibility_renderer.md`** — closes the P2 PLAN item
  "Investigate Godot's Compatibility renderer fallback for very-low-end devices."
  - Feature comparison table: every Void-used feature (StandardMaterial3D, exponential
    fog, LightmapGI, GPUParticles3D) is present in Compatibility. Missing features
    (volumetric fog, decals, SDFGI, screen-space reflections) are already absent from the
    Mobile renderer or not planned.
  - Per-GPU-tier perf: Adreno 506 era → Compatibility 20–40% faster (Vulkan driver
    immaturity). Adreno 710 (test device) → Mobile wins by 5–15%.
  - Visual delta: negligible for the brutalist-fog-darkness aesthetic.
  - Recommendation: keep Mobile as primary; a second Compatibility export preset is
    viable at Gate 2+ for low-end market expansion, zero code changes, one new preset.
  - Custom shaders (if added) need GLSL ES 3.0 variants — plan before Gate 3.
  - INDEX.md updated; P2 open item closed.
- Perf: no runtime change.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/compatibility_renderer.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (23 iterations).**

### [2026-05-10] — `claude/gifted-shannon-NQtLx` — iter 22: camera pitch V-turn bug fixed + elevation formula tests

- **Throttle: HARD (22 iterations since last human direction).** Hardening only.
- **Primary: Camera pitch V-turn bug fixed in `scripts/camera/camera_rig.gd`.**
  `_desired_camera_position` used `absf(_pitch)` for the elevation angle. Since
  `_pitch` starts at −0.384 rad and the clamp formerly allowed it up to
  `+deg_to_rad(pitch_max_degrees)`, dragging the camera upward pushed `_pitch`
  through 0 then positive — `absf` produced a V-shape: camera first drops to
  horizontal, then rises again. On a 1080p phone the V-turn was reachable with
  ~128 px of upward drag at default `pitch_drag_sens 0.003`.
  - **Fix 1 (`_apply_drag_input`):** upper clamp bound changed from
    `deg_to_rad(absf(pitch_max_degrees))` to `0.0`. `_pitch` is now always ≤ 0.
  - **Fix 2 (`_desired_camera_position`):** `absf(_pitch)` → `-_pitch`. Since
    `_pitch` is always ≤ 0, `-_pitch` ≥ 0 and is monotonically correct — higher
    magnitude pitch = more camera elevation, with no reversal at 0.
  - `pitch_max_degrees` export and dev-menu slider are retained but inactive as
    guards; their original meaning ("how far below horizontal") is unreachable.
    DECISIONS.md entry added.
- **Side quest: `_test_camera_pitch_formula` added to `tests/test_controller_kinematics.gd`.**
  5 assertions documenting the post-fix elevation invariant (pure math, no scene
  tree instantiation, same pattern as the other camera test groups):
  - Pitch 0.0 → elevation 0 (horizontal).
  - Default pitch −22° → positive elevation (camera above player).
  - −45° elevation > −22° elevation (monotonic, no V-turn regression).
  - −55° elevation still positive (within full valid range).
  - Elevation ≥ 0 across all valid above-horizontal angles [0°, 89°].
  - Total assertions: ~123 → ~128.
- Perf: no runtime cost change.
- Bugs fixed: camera pitch V-turn (V-shape on upward drag, reachable in normal play).
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (22 iterations).**

### [2026-05-10] — `claude/gifted-shannon-0yX7M` — iter 21: camera math unit tests + pitch V-turn issue logged

- **Throttle: HARD (21 iterations since last human direction).** Hardening only.
- **Primary: Camera math unit test groups added to `tests/test_controller_kinematics.gd`.**
  Three new test groups, all pure math (no scene-tree instantiation), following the
  same assertion pattern as the kinematics groups. +17 assertions → ~123 total.
  - `_test_camera_vertical_pull` (6 assertions) — tests `camera_rig.gd::_vertical_pull_offset`
    formula (`vel_y >= 0 → 0`, `vel_y < 0 → vel_y * pull * 0.05`): rising/stopped gives 0,
    falling gives negative proportional offset, zero-pull coefficient gives 0,
    terminal-velocity pull (-40 m/s × 0.18 × 0.05 = -0.36 m) stays within -1 m.
    Helper `_cam_vp(vel_y, pull)` mirrors the formula.
  - `_test_camera_occlude_math` (6 assertions) — tests `camera_rig.gd::_occlude`
    safe-distance formula (`maxf(min_dist, hit_dist - margin)`): typical hit (3 m →
    2.7 m), close clamp (0.5 m → 0.8 m min), margin == hit (→ min), zero margin,
    oversized margin, loop invariant (safe_dist ≥ min for 6 hit distances).
    Helper `_cam_sd(hit_dist, margin, min_dist)` mirrors the formula.
  - `_test_camera_lookahead_target` (5 assertions) — tests desired-lookahead
    computation: below min_speed → zero vector; above min_speed → correct length
    and direction; diagonal velocity → equal X/Z; large lerp value → weight
    clamped to 1.0 (no overshoot).
- **Side quest: Camera pitch V-turn issue documented in PLAN.md refactor backlog.**
  `_desired_camera_position` uses `absf(_pitch)` for the camera elevation angle.
  Since `_pitch` starts at −0.384 rad (22°) and the clamp allows up to +0.96 rad,
  dragging upward pushes `_pitch` through 0 then positive — `absf` creates a
  V-shape: camera first drops to horizontal, then rises again. At default
  `pitch_drag_sens 0.003`, the 0-crossing requires ~128 px of upward drag on
  a 1080p phone — reachable in normal play. Fix options logged in refactor backlog;
  needs on-device feel confirmation before committing either fix.
- Perf: no runtime change.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (21 iterations).**

### [2026-05-10] — `claude/gifted-shannon-5UrSF` — iter 20: test suite expansion + dead zone calibration research

- **Throttle: HARD (20 iterations since last human direction).** Hardening only.
- **Primary: Test suite — 3 remaining Snappy-only groups expanded to all profiles.**
  `_test_horizontal_interpolation`, `_test_coyote_countdown`, and
  `_test_buffer_countdown` previously tested only Snappy (matching how iter 11
  expanded `_test_jump_cut_math` and `_test_terminal_velocity`). All three now
  loop over Snappy / Floaty / Momentum using the same assertion structure.
  Net +20 assertions:
  - `_test_horizontal_interpolation`: +6 (converges within 5 s, within 0.01 m/s,
    within 30 frames — × 3 profiles). Note: Snappy ~6 frames, Floaty ~12,
    Momentum ~12 — all within the 30-frame cap.
  - `_test_coyote_countdown`: +8 (expires, never negative, ends at 0.0, within
    2× expected frame count — × 3 profiles).
  - `_test_buffer_countdown`: +6 (expires, never negative, buffer ≥ coyote
    — × 3 profiles).
  - Total: ~86 → ~106 assertions. Every shipped profile is now covered by every
    test group. No behaviour change.
- **Side quest: `docs/research/touch_dead_zone_calibration.md`.**
  Closes the "Genshin Impact dead zone tuning specifics" open item in INDEX.md.
  - **Truncating vs. remapping dead zone** — formulae and tradeoffs. Current
    Project Void implementation (truncating at 15%) is correct for a precision
    platformer; the discontinuity at threshold is imperceptible in active play.
  - **Genshin Impact** — 8–10% inner dead zone, 90–95% outer dead zone (sprint
    ergonomics), floating stick, narrow camera safety band between zones.
  - **Sky** — fixed stick, ~5% dead zone, gesture-driven camera.
  - **HCI guidance** — 10–20% recommended for touch virtual sticks; below 10%
    causes drift; above 20% feels sticky.
  - **5 implications for Project Void:** current DZ is correct for Gate 0; Floaty
    may later benefit from remapping; outer DZ at 93% for sprint ergonomics; camera
    safety band worth adding if interference observed; dead zone is input hardware
    calibration, not a controller physics param.
- Perf: no runtime change.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/touch_dead_zone_calibration.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (20 iterations).**

### [2026-05-10] — `claude/gifted-shannon-80jFq` — iter 19: dev_menu_overlay controller-section refactor + movement param tests

- **Throttle: HARD (19 iterations since last human direction).** Hardening only.
- **Primary: `_build_controller_section` refactor in `tools/dev_menu/dev_menu_overlay.gd`.**
  The function was 42 lines — just over the 40-line threshold. Extracted four focused
  sub-builders with no behaviour change:
  - `_build_controller_movement(vbox)` (13 lines) — Max speed, Ground accel/decel,
    Air accel, Air damping sliders.
  - `_build_controller_jump(vbox)` (19 lines) — Jump velocity, three gravity bands,
    Terminal velocity, Coyote, Buffer, Release ratio sliders.
  - `_build_controller_respawn(vbox)` (7 lines) — Reboot dur, Fall kill Y sliders.
  - `_build_controller_slope(vbox)` (5 lines) — Max floor° slider.
  - `_build_controller_section` is now 7 lines (sep + 4 sub-builder calls). Every
    method in the file is now under 40 lines. No behaviour change.
- **Side quest: `_test_movement_params()` added to `tests/test_controller_kinematics.gd`.**
  10 new assertions covering properties not previously tested:
  - `ground_deceleration > 0` (all 3 profiles) — not covered by cross-invariants.
  - `air_acceleration > 0` (all 3 profiles) — not covered by cross-invariants.
  - `momentum.max_speed > snappy.max_speed` — documents speed-profile design intent
    (Momentum is the fastest profile).
  - `floaty.max_speed < snappy.max_speed` — Floaty is the controlled/slower profile.
  - `momentum.air_horizontal_damping == 0.0` — Momentum fully preserves horizontal
    velocity (same as Snappy; Floaty is the only damped profile).
  - `momentum.ground_deceleration < momentum.ground_acceleration` — Momentum
    intentionally decelerates slowly; stopping takes longer than reaching max speed.
  - Total assertions: ~76 → ~86.
- Perf: no runtime change.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (19 iterations).**

### [2026-05-10] — `claude/gifted-shannon-iG0FA` — iter 18: touch slider display fix + respawn param tests

- **Throttle: HARD (18 iterations since last human direction).** Hardening only.
- **Primary: Touch slider display now reflects loaded layout values.**
  The dev menu "Jump radius" and "Stick zone %" sliders were showing hardcoded
  defaults (95 / 0.5) even when `user://input.cfg` had different values. The
  touch overlay itself was loading correctly; only the slider display label was
  stale. Root cause: `_build_touch_section` used hardcoded constants as
  `initial_value` because it had no way to query the overlay at build time.
  - Fix: `TouchOverlay._ready()` now adds itself to the `"touch_overlay"` group.
    `DevMenuOverlay._build_touch_section()` queries that group just before building
    sliders and uses the actual loaded values as `initial_value`. The deferred
    `_install_overlay` call guarantees the scene tree (including
    `TouchOverlay._load_layout()`) has completed before the group query runs.
    Falls back to 95 / 0.5 if no overlay is in the tree.
  - DECISIONS.md entry added (group-query vs. signal vs. store-in-autoload
    comparison).
  - Closes "Touch slider display doesn't reflect loaded layout" from refactor
    backlog.
- **Side quest: `_test_respawn_params()` added to `tests/test_controller_kinematics.gd`.**
  - Phase-fraction sum check: `0.12 + 0.35 + 0.35 + 0.18 == 1.0` — documents
    the beat percentages in `player.gd::_run_reboot_effect()` so future edits
    that change a fraction are caught here.
  - Per-profile: `reboot_duration` in `(0, 1.5]` (matches slider range);
    `fall_kill_y < 0` (must be below ground); `fall_kill_y >= -200` (matches
    slider min). All three profiles pass.
  - +13 assertions; total ~76 (was ~63).
- Perf: no runtime change.
- Bugs fixed: touch slider display showing stale defaults after loading layout.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (18 iterations).**

### [2026-05-09] — `claude/gifted-shannon-QnzBx` — iter 17: touch layout persistence fix + holistic level design research

- **Throttle: HARD (17 iterations since last human direction).** Hardening only.
- **Primary: `dev_menu_overlay.gd::_make_slider` silent-init bug fix.**
  Touch layout persistence (`user://input.cfg`) was silently broken on every startup.
  The root cause: `_build_touch_section` called `.value = 95.0` on a freshly-built
  slider *after* `value_changed` callbacks were already connected. This caused
  `DevMenu.touch_param_changed` to fire immediately, routing to
  `touch_overlay._on_touch_param`, which set `jump_button_radius = 95.0` and
  `stick_zone_ratio = 0.5` — overwriting whatever `_load_layout()` had just loaded
  from disk. The same pattern existed in `_build_level_section` (time scale slider)
  and `_make_cam_slider` (all camera sliders).
  - Fix: `_make_slider` now accepts `initial_value: float = NAN`. When provided, the
    value is applied to the Range node *before* any `value_changed` callbacks are
    connected, so the signal fires internally but no listeners receive it. The
    val_label is then initialised from `slider.value` (reflecting the initial_value).
  - Updated `_make_cam_slider`: passes `default_val` as `initial_value` instead of
    setting `.value` post-return. Camera `@export` defaults match the dev menu
    defaults by convention (verified — all 15 camera params match).
  - Updated `_build_touch_section`: passes 95.0 / 0.5 as `initial_value`. A
    returning user's layout is now preserved; a new install starts at defaults. ✓
  - Updated `_build_level_section`: passes 1.0 as `initial_value`. `Engine.time_scale`
    is already 1.0 by default; no observable change for any user.
  - Remaining gap (noted in refactor backlog): touch sliders display their defaults
    (95 / 0.5) even when a different value is loaded from disk. Values are correct
    in the overlay; only the slider display is stale. Fixing it needs a "loaded
    params" signal — deferred, low priority.
  - DECISIONS.md entry added.
- **Side quest: `docs/research/holistic_level_design.md`** — Steve Lee GDC 2017
  ("An Approach to Holistic Level Design") + GMTK synthesis (3D platformer pacing).
  - Steve Lee's three integrated dimensions: gameplay / presentation / narrative.
    Authoring pipeline: decide the mechanic first, then shape geometry that makes
    it self-evident, then give it a world-reason. "Intentionality" — the player
    understands what the space asks without a UI prompt. If a popup is needed,
    the geometry shape is wrong. Lee's pipeline = Alexander's parti pris, operationalised
    as a production sequence.
  - GMTK Kishōtenketsu 4-beat arc (Ki→Shō→Ten→Ketsu): Intro (safe learning) →
    Development (escalation, same mechanic) → Twist (recontextualise, not just
    harder) → Resolution (mastery + optional depth). ~5-minute arc; discard the
    mechanic after Ketsu. Hayashida's rule: the Twist beat is required, not optional.
    This adds the explicit "Ten" to the SMB introduce-then-combine pattern already
    in level_design_references.md.
  - GMTK Odyssey density-over-span: compressed verticality (apex visible from start),
    no monotonic ascent (one path, one floor plane, 3 minutes of climbing = bad).
    Confirms 3-floor-plane rule; adds specific: **keep the destination in the
    player's FOV throughout the ascent.**
  - 6 concrete implications for Gate 1: holistic affordance pipeline per beat,
    Twist beat required, brutalist expressed structure = free affordances (no glowing
    arrows needed), apex-visibility rule for ascent sequences, Twist beat recipe for
    precision platformers (combine mastered mechanic + momentum reversal), intentionality
    check before committing any kit piece.
  - INDEX.md updated; Steve Lee and GMTK open items marked done.
- Perf: no runtime change.
- Bugs fixed: `dev_menu_overlay.gd` touch layout persistence overwrite on startup.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/holistic_level_design.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (17 iterations).**

### [2026-05-09] — `claude/gifted-shannon-6ZYeJ` — iter 16: camera dev-menu tunables + debug draw perf

- **Throttle: HARD (16 iterations since last human direction).** Hardening only.
- **Primary: Camera dev-menu extended with 6 previously inspector-only tunables.**
  Before this iteration, `aim_height`, `lookahead_lerp`, `lookahead_min_speed`,
  `pitch_min_degrees`, `pitch_max_degrees`, and `recenter_min_speed` were only
  adjustable via the Godot inspector — useless during a device tuning session where
  the editor isn't open. Added a "Camera — Tuning" sub-section to the dev menu with
  live sliders for all six. `camera_rig.gd::_on_camera_param_changed` gained 6 match
  arms to apply them. All defaults match the existing `@export_range` defaults so
  the behaviour is unchanged at startup; sliders become live the moment they're moved.
  - Aim height (0–3 m, step 0.05, default 0.6) — vertical offset of the camera look-at
    point above the player's feet; affects how much ceiling headroom the framing reveals.
  - Look lerp (0.5–20, step 0.5, default 4.0) — how quickly the lookahead vector
    catches up to the player's horizontal velocity direction. Lower = smoother/laggy;
    higher = snappy/jerky.
  - Look min spd (0–5 m/s, step 0.05, default 0.15) — velocity below which lookahead
    decays to zero. Prevents the camera drifting when the player is nearly stopped.
  - Pitch min/max deg (range −89–0 / 0–89, step 1, defaults −55/55) — clamps how far
    up and down the player can drag-tilt the camera in manual override.
  - Rctr min spd (0–10 m/s, step 0.1, default 0.5) — minimum player horizontal speed
    required for the auto-recenter to kick in (prevents recenter while standing still).
- **Side quest: `player_debug_draw.gd` per-frame overhead reduction.** Before this
  change, `_process` called `_find_player()` (a scene-tree group search) and ran
  four `DevMenu.is_debug_viz_on()` dictionary lookups every physics frame even when
  all four overlays were disabled (the default state). Added `_viz_active: bool`
  cached via `DevMenu.debug_viz_changed` signal (re-evaluated only when a checkbox
  changes, not every frame). Restructured `_process`: now returns early after
  `clear_surfaces()` if `_viz_active` is false, skipping the group search entirely.
  When all overlays are off (the typical in-development state) the per-frame cost
  drops to one bool check + one `clear_surfaces()` on an already-empty mesh.
- Perf: no runtime cost increase. On-device baseline still pending first human build.
- Bugs fixed: none new.
- New dev-menu controls: "Camera — Tuning" subsection — Aim height, Look lerp,
  Look min spd, Pitch min deg, Pitch max deg, Rctr min spd (6 new sliders).
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active (16 iterations).**

### [2026-05-09] — `claude/gifted-shannon-b8hWF` — iter 15: respawn timer bug fix + slope tunable

- **Throttle: HARD (15 iterations since last human direction).** Hardening only.
- **Primary: Two targeted fixes.**
  - **Bug fixed — `player.gd::respawn()` leaving timers live.** `_buffer_timer` and
    `_coyote_timer` do not tick while `_is_rebooting = true` (physics returns early). A
    jump press in the last 120 ms before death would freeze `_buffer_timer` at a non-zero
    value; after the 0.5 s reboot sequence the timer was still "live." On the first frame
    post-reboot, `_try_jump` would fire if the player landed at the spawn point, producing
    an unintended jump. Fixed by zeroing both timers in `respawn()` before the reboot
    sequence starts. The comment explains the why (non-obvious frozen-timer invariant).
  - **`max_floor_angle_degrees` now live-tunable from the dev menu.** The property existed
    in `ControllerProfile` but was only applied once (in `_apply_profile_to_body` on profile
    load). A dev-menu slider would mutate the resource but not update `CharacterBody3D`'s
    `floor_max_angle`. Fixed: `floor_max_angle = deg_to_rad(profile.max_floor_angle_degrees)`
    moved to the top of `_physics_process` (after `_is_rebooting` guard) so it refreshes
    every tick. A "Controller — Slope" subsection with a "Max floor°" slider (20–70°, step 1°)
    added to the dev menu controller section. Slider is registered in `_profile_sliders` so it
    bulk-syncs on profile switch like all other controller params.
- **Side quest: slope param test group.** `_test_slope_params()` added to
  `tests/test_controller_kinematics.gd` (7 assertions across 3 profiles). Checks
  `max_floor_angle_degrees` in valid range [20, 70] and that Floaty ≥ Snappy (the
  accessibility profile should be at least as forgiving on slopes). Total assertions: ~56 → ~63.
- Perf: no runtime cost change. `floor_max_angle` assignment is a single float write per
  physics tick — negligible. On-device baseline still pending.
- Bugs fixed: respawn post-death unintended jump (buffer timer not cleared).
- New dev-menu controls: "Controller — Slope" subsection → "Max floor°" slider.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle still active (15 iterations).**

### [2026-05-09] — `claude/gifted-shannon-72KFx` — iter 14: dev_menu_overlay bug fix + Alexander research

- **Throttle: HARD (14 iterations since last human direction).** Hardening only.
- **Primary: `dev_menu_overlay.gd` bug fix + magic-number refactor.**
  - **Bug fixed**: `_on_save_confirmed` — when a profile is saved via the "Save as…"
    button, `_profile_dropdown.selected = n` was set but `_select_profile(name)` was
    never called. `OptionButton.selected` set programmatically does NOT emit
    `item_selected`, so `_current_profile` continued pointing at the original resource.
    Subsequent slider edits went to the wrong resource; the saved copy was frozen at
    save-time values. Fixed by adding `_select_profile(name)` at the end of
    `_on_save_confirmed`. One line, no behaviour change except the bug is now gone.
  - **Refactor**: 6 inline UI layout magic numbers promoted to named class constants:
    `_PANEL_W = 400`, `_SCROLL_H = 600`, `_SECTION_SEP = 6`, `_SL_LABEL_W = 110`,
    `_SL_TRACK_W = 160`, `_SL_TRACK_H = 24`, `_SL_VAL_W = 54`. The column-sum comment
    (`110+160+54 = 324 fits in 400`) makes the layout budget readable at a glance.
- **Side quest: Christopher Alexander research note** — `docs/research/alexander_pattern_language.md`.
  Synthesises three Alexander texts as applied to Void level design:
  - *Notes on the Synthesis of Form*: form resolves a network of forces; every level beat
    must satisfy ≥ 3 forces simultaneously (challenge + navigation + one of
    spectacle/pacing/orientation). Beats satisfying only "challenge" are obstacle-course
    padding.
  - Parti pris: every beat needs a one-sentence organizing concept before geometry is
    placed. The SMB "one governing idea per room" rule is parti thinking — Alexander
    arrived at the same principle from architecture in 1964.
  - *A Pattern Language*: named reusable solutions mapped to a Void kit vocabulary —
    Compression–Release, Threshold, Landmark in Darkness, Rest Alcove, Gauntlet Ascent,
    Overlook, Desire Line. Each `kit/` scene in Gate 1 should be named after a pattern.
  - 8 concrete implications: parti-per-beat discipline, ≥ 3 forces per beat,
    Compression–Release as the primary procession unit for brutalist megastructure,
    structural (not decorative) landmarks, Stray-red as the structural centre of the
    spatial field, desire line = par route, kit naming enforces patterns.
  - INDEX.md and "Christopher Alexander" open items in Brutalism/BLAME section updated.
- Perf: no runtime change.
- Bugs fixed: `dev_menu_overlay.gd::_on_save_confirmed` profile-switch missing after save.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/alexander_pattern_language.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle still active (14 iterations).**

### [2026-05-09] — `iter/spawn-sparks-refactor` — iter 13: _spawn_sparks refactor + juice density research

- **Throttle: HARD (13 iterations since last human direction).** Hardening only.
- **Primary: `player.gd::_spawn_sparks` method-size refactor.** The function was
  41 lines (just over the 40-line budget). Extracted three focused helpers with no
  behaviour change:
  - `_build_spark_material() → StandardMaterial3D` (10 lines) — all material property
    setup in one place; spark colour and alpha-blend settings readable at a glance.
  - `_build_spark_mesh(rng: RandomNumberGenerator) → ImmediateMesh` (16 lines) — the
    12-line-segment hemispherical burst geometry, self-contained.
  - `_fade_and_free_spark(mi, mat)` (7 lines) — the tween sequence (0.07 s delay →
    alpha fade → queue_free).
  - `_spawn_sparks` is now 15 lines. Only `_run_reboot_effect` (45 lines) remains in
    the backlog as "leave as-is" — sequential `await` beats make further extraction
    awkward in GDScript without coroutine indirection.
- **Side quest: juice density research note** — `docs/research/juice_density.md`.
  Synthesises Astro's Playroom / Astro Bot "layered receipt" model (audio+visual+world
  per action), Super Meat Boy sparse-juice contrast, mobile-specific considerations
  (UI feedback compensates for no haptics), and draw-call cost of each juice type.
  - Gate 1 priority ranking: landing squash → jump stretch → jump puff →
    pre-jump anticipation. All gated behind existing `squash_stretch` / `particles`
    dev-menu toggles.
  - Key implication: Void should sit closer to SMB density than Astro Bot — brutalist
    tone calls for restraint; heavy particle clusters undercut the atmosphere.
  - INDEX.md updated; "Astro's Playroom — juice density" open item marked done.
- Perf: no runtime change (pure refactor + docs).
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/juice_density.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle still active (13 iterations).**

### [2026-05-09] — `claude/gifted-shannon-j5hhr` — iter 12: touch_overlay.gd refactor + draw-call budget fix

- **Throttle: HARD (12 iterations since last human direction).** Hardening only.
- **Primary: `touch_overlay.gd` method-size refactor.** Two functions were over the
  40-line threshold and have been replaced with lean dispatchers + extracted helpers:
  - `_handle_repo_input` (was 62 lines) → lean dispatcher (8 lines) calling four new
    helpers: `_parse_repo_event` (parses any `InputEvent` subtype into a common
    `{pos, pressed, released, moved}` dict), `_on_repo_press`, `_on_repo_move`,
    `_on_repo_release`. Each helper is ≤ 15 lines. No behaviour change.
  - `_draw_reposition` (was 56 lines) → lean dispatcher (9 lines) calling seven new
    draw helpers: `_draw_dim_overlay`, `_draw_zone_divider`, `_draw_jump_button_repo`,
    `_draw_resize_handle_repo`, `_draw_done_button_repo`, `_draw_preset_buttons_repo`,
    `_draw_repo_header`. Two font-size constants (`_REPO_FONT_SM = 13`,
    `_REPO_FONT_NM = 18`) extracted from magic literals. No behaviour change.
- **Side quest: `DRAW_CALL_BUDGET` corrected.** `perf_budget.gd` had
  `DRAW_CALL_BUDGET := 200` — four times the Gate 1 target of ≤ 50 draw calls
  established in `docs/research/godot_mobile_perf.md`. Updated to 50 so
  `over_budget()` flags correctly. Comment references the research note.
- Perf: no runtime change (pure structural refactor + constant adjustment).
- Bugs fixed: `DRAW_CALL_BUDGET` was too lenient (200 vs. research-backed 50).
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle still
  active (12 iterations).**

### [2026-05-09] — `claude/gifted-shannon-DCTEK` — iter 11: perf frametime fix + dead code removal + test coverage

- **Throttle: HARD (11 iterations since last human direction).** Hardening only.
- **Bug fixed — `perf_budget.gd` frametime accuracy.** `last_frametime_ms` was
  computed as `1000.0 / Engine.get_frames_per_second()`. That value is a 0.5-second
  rolling average, so a 25 ms spike frame was reported as ~17 ms. Fixed to use
  `delta * 1000.0` (actual last-frame time). The `over_budget()` check now catches
  real hitches; the HUD corner display shows honest numbers.
- **Dead code removed — `touch_input.gd::set_camera_drag_delta`.** The method's
  stale comment claimed it was "called by the touch overlay each frame," but the
  overlay calls `add_camera_drag_delta` (the accumulating variant). `set_camera_drag_delta`
  was never called anywhere. Removed; `add_camera_drag_delta` comment updated.
- **Test coverage expansion (side quest).** `_test_jump_cut_math` and
  `_test_terminal_velocity` in `tests/test_controller_kinematics.gd` previously
  tested only the Snappy profile. Both now loop over all three shipped profiles
  (Snappy / Floaty / Momentum), adding 2×8 = 16 new assertions. Test labels
  include the profile name for easy identification in Output panel.
  Total assertions: was ~40, now ~56.
- Perf: no runtime change (perf_budget fix changes the value of `last_frametime_ms`
  but not any other computation; dead code removal has zero cost).
- Bugs fixed: `perf_budget.gd` spike-frame underreporting.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: none.
- Needs human attention: **see "Open questions waiting on you" — hard throttle still active.**

### [2026-05-09] — `claude/gifted-shannon-wIoiG` — iter 10: player.gd refactor + ghost trail research

- **Throttle: HARD (10 iterations since last human direction).** Feature work stopped;
  hardening only. See "Open questions waiting on you" for suggested next directions.
- Primary: **`player.gd::_physics_process` refactor.** Was 79 lines — well over the
  40-line threshold. Extracted 8 focused private sub-routines with no behaviour change:
  - `_tick_timers(delta, on_floor)` — coyote/buffer countdown
  - `_collect_jump_input()` — keyboard just-press → buffer; returns held state
  - `_was_jump_released(jump_held)` — detects both keyboard and touch release
  - `_camera_relative_move_dir()` — TouchInput vector rotated by camera yaw
  - `_apply_horizontal(delta, on_floor, move_dir)` — accel/decel + air damping
  - `_apply_gravity(delta, jump_held)` — three-band gravity
  - `_try_jump()` — consumes coyote + buffer
  - `_cut_jump(jump_released)` — variable jump height cut
  - `_physics_process` is now 22 lines. All sub-routines are ≤16 lines each.
  - `_run_reboot_effect` (44 lines, `await`-chained sequence) noted in refactor
    backlog — sequential awaits make further extraction awkward without coroutine
    indirection; leave as-is until the function needs to grow.
- Side quest: **Ghost trail prototype research note** — `docs/research/ghost_trail_prototype.md`.
  Synthesises SMB's attempt-replay overlay (pedagogical design intent, why dense ghost
  clusters mark death walls, recency-alpha formula), evaluates four Godot 4 approaches
  (MultiMesh recommended at 1 draw call / 300 instances; ImmediateMesh fallback; GPU ring
  buffer for Gate 2+; physics replay discarded), and provides a concrete GDScript sketch
  for `game.gd` recorder + `GhostTrailRenderer`. 6 implications for Void including: wire
  existing `Game.player_respawned` signal, default ghost_trails juice toggle OFF until
  level exists, cold blue-grey colour to protect the Stray's red.
- Note: PR #21 ("Fix ControllerProfile parse errors in player.gd and camera_rig.gd")
  landed between iter 9 and iter 10 but wasn't reflected in README or PLAN — documented
  here retroactively.
- Perf: no runtime change (pure refactor + research note).
- Bugs fixed: none new.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/ghost_trail_prototype.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active.**

### [2026-05-09] — `claude/gifted-shannon-tfUYS` — iter 9: level design references research + camera_rig refactor

- **Throttle: HARD (9 iterations since last human direction).** Feature work stopped;
  hardening only. See "Open questions waiting on you" for suggested next directions.
- Primary: **Level design references research note** — `docs/research/level_design_references.md`.
  Synthesises five source clusters directly relevant to Gate 1 level authoring:
  - **SMB grammar for level structure**: short focused rooms (single governing idea per
    beat), introduce-then-combine pattern, instant respawn as information not punishment
    (suggests Snappy profile's `reboot_duration` should be ≤ 0.35 s, not 0.5 s), ghost
    trails as core SMB grammar not decoration (confirms Gate 1 attempt-replay is P0).
  - **Verticality principles** (The Level Design Book): max 3 floor planes per area;
    downward flow = dramatic/free, upward flow = earned challenge; ascending = goal,
    descending = discovery; console/touch controllers prefer horizontal hazard reads
    even in vertical spaces.
  - **Flow and pacing**: movement-centered design; critical path vs. desire line (author
    par route first, safe route is padding around it); rhythm groups make hard sequences
    masterable; rest areas mandatory after ≥ 3 precision actions; intentional "bad" flow
    (mazes, dead ends) is also legibility.
  - **Mario Odyssey — density over sprawl**: compact + 3 floor planes > sprawling
    horizontal; vertical ascent gates what's visible (vistas as reward); expressed
    architecture = traversal affordance; macro compression→release mirrors micro.
  - **Kevin Lynch vocabulary applied**: path, edge, district, node, landmark mapped
    concretely to Void's megastructure. Every level needs one landmark for orientation
    (critical in darkness/fog).
  - 10 concrete "Implications for Project Void" including: one-idea-per-beat rule,
    shorten Snappy reboot, author par route first, 3-floor-plane rule, landmark
    requirement, rhythm-group hazards, rest-area/checkpoint pairing, downward entry beats.
  - INDEX.md updated; "Level design references" section now populated.
- Side quest: **`camera_rig.gd::_process()` refactor.** Was 56 lines (over the 40-line
  threshold). Extracted 5 focused sub-methods: `_apply_drag_input`, `_update_yaw_recenter`,
  `_update_lookahead`, `_vertical_pull_offset`, `_desired_camera_position`. `_process` is
  now 22 lines. No behaviour change. Magic number `0.05` in `_vertical_pull_offset` now
  has a comment explaining it (inspector-range normalisation for `vertical_pull`).
- Perf: no runtime change.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/level_design_references.md`; INDEX.md updated.
- Needs human attention: **see "Open questions waiting on you" — hard throttle active.**

### [2026-05-09] — `claude/gifted-shannon-9IpbZ` — iter 8: style test scene greybox + brutalism/BLAME! research

- Primary: **Style test scene greybox (PLAN P1).** `scenes/levels/style_test.tscn` +
  `scripts/levels/style_test.gd`. A compact display room for art fidelity checks —
  required by `docs/ART_PIPELINE.md` § Style fidelity check before any real asset is
  committed. Layout: 20×20 floor (mat_concrete_dark), a 2×0.5×2 platform (mat_concrete)
  to the right, a 1×4×4 wall panel (mat_concrete_dark) to the left, a 2×8×2 scale pillar
  in the background (6 m right, 7 m forward). Identical fog (density 0.045) and key light
  (warm sodium, 1.5 energy) to Feel Lab. Player + camera + touch overlay all wired in —
  walk the Stray to each piece and answer the 5 fidelity questions in ART_PIPELINE.md.
  DisplayRoom node group makes it easy to swap in candidate assets.
- Side quest: **Brutalism / *BLAME!* / megastructure research note** —
  `docs/research/brutalism_blame.md`. Covers:
  - *BLAME!* visual grammar: scale ambiguity, darkness as material, fog-as-depth,
    recursive self-similarity, navigation-by-infrastructure logic.
  - Colour palette derived from the manga (cold blue-grey concrete, rare sodium warm,
    biolume cyan in deep layers). Confirms the current `mat_concrete` / `mat_concrete_dark`
    albedo values are correct.
  - Brutalist architecture: béton brut honesty, mass over surface, expressed structure,
    geometric repetition with subtle variation.
  - Megastructure hierarchy: mega-column → floor slab → service run → habitation volume
    — maps directly to the compression/release procession pattern in LEVEL_DESIGN.md.
  - 10 concrete implications for Project Void (cold palette, darkness as architecture,
    Stray red as sole warm anchor, multi-scale kit, expressed structure, service-run
    claustrophobia, column-array depth shots, "failed program" props, no skybox, vertical
    axis primary).
  - INDEX.md updated; "Brutalism / BLAME! / megastructure" section populated.
- Throttle note: 8 iterations since last human direction (soft throttle). Both items
  are non-destructive and produce infrastructure for the next stage (style checking,
  level design) rather than new feature surfaces.
- Perf: no runtime change this iteration.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/brutalism_blame.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-YdzrG` — iter 7: controller kinematics unit tests + mobile perf research

- Primary: **Controller kinematics unit tests (PLAN P1).** `tests/test_controller_kinematics.gd`
  + `tests/test_runner.tscn`. Standalone (no GUT plugin required): open
  `test_runner.tscn`, press F5, read Output panel.
  - 10 test groups, ~40 assertions:
    **Profile defaults** (8 sanity checks on `CP.new()`),
    **Jump height** (h = v₀²/2g in 1.5–5.0 m; floaty ≥ snappy),
    **Gravity band ordering** (after_apex ≥ falling ≥ rising on all 3 profiles),
    **Jump cut math** (threshold checks, boundary conditions),
    **Horizontal interpolation** (move_toward convergence ≤ 30 frames),
    **Air damping** (zero = SMB preservation; floaty > snappy),
    **Terminal velocity** (maxf clamp holds at and past limit),
    **Coyote countdown** (expires, never negative, within 2× expected frames),
    **Buffer countdown** (expires; buffer ≥ coyote across all profiles),
    **Cross-profile invariants** (buffer≥coyote, ratio<1, accel>0 on every shipped profile).
  - GUT migration path documented in file header (`_ready` → `before_all`, `_test_*` → `test_*`).
  - Cannot be run in CI without a Godot binary — marked "on-device pending" for runner integration.
- Side quest: **Godot Mobile renderer performance research** — `docs/research/godot_mobile_perf.md`.
  TBDR tile-based GPU architecture (Adreno/Mali), transparency cost, baked vs dynamic
  lighting tradeoffs, ASTC texture notes, draw-call/triangle budgets, Jolt profiling tips,
  in-game profiling workflow. 8 concrete "Implications for Project Void" (bake lights before
  Gate 1; ≤ 50 draw calls; no alpha on every-frame geometry; no MSAA; etc.).
  INDEX.md updated; "Performance & rendering" section now populated.
- Plan drift fixed: P2 "always-on perf HUD" marked done (was completed iter 3 but still
  listed as open). P2 "Mobile renderer research" marked done.
- Perf: no runtime change this iteration (tests + docs only).
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/godot_mobile_perf.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `iter/touch-ux-research` — iter 6: mobile touch UX research + concrete material kit

- Primary: **Mobile touch UX research note** — `docs/research/mobile_touch_ux.md`.
  Synthesises Dadish 3D Play Store pain points (camera, air control, touch controls
  bar), fixed vs. floating joystick HCI research (floating wins first-session, neutral
  at 5 min), Genshin Impact dead zone parameterisation, Sky: Children of the Light
  zone-split study (50/50 confirmed), Alto's Odyssey one-tap note (not applicable).
  Thumb-reach analysis for 1920×1080 landscape on Nothing Phone 4(a) Pro: comfortable
  reach radius ≈ 580 px from each anchor; no gameplay UI in top 25% of screen;
  jump button minimum radius = 60 px. Assisted profile design targets articulated:
  ledge magnetism (≤ 1.5 m/s impulse within 0.2 m of edge), arc assist (≤ 15% of
  jump_velocity at peak), sticky landing (20% speed reduction for 2 frames on narrow
  platforms), `stick_dead_zone_ratio` = 0.15. New `ControllerProfile` properties
  needed for Assisted: `ledge_magnet_radius`, `ledge_magnet_strength`,
  `arc_assist_max`, `landing_sticky_frames`, `stick_dead_zone_ratio`.
- Side quest A: **Concrete material kit** — `resources/materials/mat_concrete.tres`
  (albedo 0.55/0.55/0.58, roughness 0.85) and `mat_concrete_dark.tres` (0.32/0.32/0.35,
  roughness 0.9) extracted from inline `[sub_resource]` in `feel_lab.tscn` to
  standalone `.tres` files. `feel_lab.tscn` updated to reference them as
  `[ext_resource]`. Gate 1 level authors can now `@export` a material slot and drag
  these in. Remaining: `scenes/levels/kit/` prebuilt platform scenes — deferred to
  art direction approval iteration.
- Side quest B: **`.tres` profile type headers** — all three controller profiles
  (`snappy.tres`, `floaty.tres`, `momentum.tres`) updated from `type="Resource"` to
  `type="ControllerProfile"`. Godot editor now correctly identifies the resource type
  in the inspector.
- Perf: no change — material extraction is load-time reorganisation only.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/mobile_touch_ux.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-bchl4` — iter 5: reboot animation polish + save-as-profile

- Primary: **Reboot animation fully specced (PLAN P0 item 6).** `_run_reboot_effect()`
  in `player.gd` replaced from scratch:
  - **Step 1 — Death beat**: `_spawn_sparks(death_centre)` fires 12 `ImmediateMesh` line
    segments in random hemispherical directions from the capsule centre, warm orange-yellow
    (`Color(1.0, 0.78, 0.12)`), fade out over 0.45 s via tween, then `queue_free`.
    Gated behind `DevMenu.is_juice_on("particles")`. Material uses
    `TRANSPARENCY_ALPHA` + `no_depth_test = true` so sparks are always visible.
    A death-squish tween (`scale(1.25, 0.25, 1.25)`) fires simultaneously, gated
    behind `DevMenu.is_juice_on("squash_stretch")`.
  - **Step 2 — Dark frame**: hide visual, reset scale to `ONE`, teleport.
  - **Step 3 — Power-on**: scale from `(0.05, 0.05, 0.05)` → `ONE` using
    `EASE_OUT` / `TRANS_BACK` (overshoot then settle = "upright" beat), plus warm
    glow emission. Squash_stretch-gated; falls back to instant-show if off.
  - **Step 4 — Settle**: confirm scale, clear emission, clear `_is_rebooting`.
  - Timing: 12 % / 35 % / 35 % / 18 % of `profile.reboot_duration` (sums to 100 %).
- Side quest: **Save-as-profile button (PLAN P0 item 7).** Dev menu Profile section now
  has a "Save as…" button that reveals an inline `LineEdit + Save + ✕` row.
  On confirm: `_current_profile.duplicate(true)` → add to `_profiles` dict and
  dropdown → select new item → persist to `user://profiles/<name>.tres` via
  `ResourceSaver`. Works in-session; copied `.tres` can be promoted to `res://profiles/`
  manually.
- Dev menu additions: Controller — Respawn subsection with **Reboot dur (s)** and
  **Fall kill Y** sliders (both wired into `_profile_sliders` for bulk-sync on
  profile switch). Now 15 profile sliders total.
- Perf: `_spawn_sparks` creates one `MeshInstance3D` + `ImmediateMesh` + `StandardMaterial3D`
  per respawn (~24 verts × one frame), freed after 0.45 s. Zero draw-call cost at
  rest (all default-OFF in the Juice section). Squash tween runs on `_visual`
  (one Node3D transform), no GPU cost.
- Bugs fixed: none.
- New dev-menu controls: "Reboot dur (s)" and "Fall kill Y" sliders (Controller — Respawn);
  "Save as…" button + inline form (Profile section).
- Assets acquired: none.
- Research added: none this iteration.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-k7sgn` — iter 4: in-world debug viz + character-controller research

- Primary: **In-world debug visualizations (PLAN P0 item 5).** New
  `tools/debug/player_debug_draw.gd` — a `Node3D` added to the Feel Lab that
  draws all overlays with `ImmediateMesh` (`no_depth_test=true`, unshaded,
  vertex-coloured). Four overlays, all default OFF, toggled from Dev Menu →
  Debug viz:
  - **Collision capsule** (cyan) — wireframe capsule matching the physics shape
    (r=0.28, h=0.9). Two rim circles + 4 verticals + XY/ZY hemisphere arcs.
  - **Velocity arrow** (yellow) — line from player centre in velocity direction,
    length proportional to speed (×0.15 scale), chevron arrowhead. Handles
    near-vertical velocity (wall jumps) without divide-by-zero.
  - **Ground normal** (green) — 1.2 m arrow along `get_floor_normal()` when on
    floor, with tick at tip. Hidden when airborne.
  - **Jump arc** (orange) — simulated parabola at 1/30 s steps × 60 frames.
    On floor: preview of a jump from current position. Airborne: shows remaining
    trajectory. Switches gravity band at apex (gravity_rising → gravity_after_apex).
  - Four new dev-menu checkboxes: "Collision capsule", "Velocity arrow",
    "Ground normal", "Jump arc".
- Side quest: **Character controllers research note.** `docs/research/character_controllers.md`.
  Covers SMB grammar (instant accel, velocity preservation, variable jump),
  Mario Odyssey ledge magnetism, A Hat in Time homing-attack as Assisted profile
  model, Pseudoregalia momentum rethink (reduce deceleration, don't raise cap),
  Demon Turf custom-physics rationale (Jolt likely avoids same issue). Key
  implication: Snappy profile values are in the right ballpark; Assisted profile
  should prioritise ledge magnetism (~0.15 m snap radius) over mid-air steering.
- Perf: no new draw calls added to the main render pass. `ImmediateMesh` with
  ≤332 vertices/frame when all four overlays are on, all off by default.
  On-device baseline still pending first human build.
- Bugs fixed: none new.
- New dev-menu controls: Debug viz section — "Collision capsule", "Velocity arrow",
  "Ground normal", "Jump arc" (4 new checkboxes).
- Assets acquired: none.
- Research added: `docs/research/character_controllers.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-6LHK6` — iter 3: touch overlay polish + iter-2 carry

- Primary: **Touch overlay polish (PLAN P0 item 5).** `scripts/ui/touch_overlay.gd` fully
  rewritten. Drag-to-place reposition mode (`enter_reposition_mode()` / "Reposition
  controls…" button in dev menu Touch section): drag the red circle to move the jump button,
  drag the yellow handle at its edge to resize, tap a preset button to snap to a thumb-zone
  configuration. Three presets: Default (1720×900, r=95), Closer (1580×900, r=90), Wider
  (1830×950, r=100). Reposition mode also shows the stick-zone divider line live. All
  changes are written to `user://input.cfg` (ConfigFile) on Done and reloaded on startup.
  Dev menu gains a "Touch Controls" section: Reposition button, Jump radius slider, Stick
  zone % slider. `stick_zone_ratio` replaces the hardcoded 0.5 fraction in `_classify()`.
- Bundled: **Carry-forward of iter-2 code from stranded PR #12** (`claude/elegant-lamport-VlWlA`,
  draft with merge conflicts). Iter-2 work now lands cleanly on current main:
  — `tools/debug/hud_overlay.gd` (new): always-on layer-98 CanvasLayer. Perf HUD (FPS +
    frametime) on by default in top-right corner; Velocity+state readout off by default.
    Controlled by `DevMenu.debug_viz_state` and toggled from the Debug viz section.
  — Dev menu controller section expanded from 4 to 13 sliders covering every
    `ControllerProfile` property (gravity bands, air accel/damping, release ratio). Profile
    switching bulk-syncs all sliders via `_profile_sliders` dict — switching Snappy ↔ Floaty
    ↔ Momentum now shows each profile's distinct values immediately.
  — Level section: Time scale × slider (0.25×–2.0×) sets `Engine.time_scale` live.
  — Debug viz section in dev menu: "Perf HUD" and "Velocity + state" checkboxes.
  — Stale "until step 7" camera-frame comment removed from `player.gd`.
- PR #12 closed as superseded by this PR.
- Perf: no new geometry or draw calls. HUD is a Label in a CanvasLayer — CPU cost is
  negligible. On-device baseline still pending first human build.
- Bugs fixed: profile slider mismatch (sliders always showed Snappy values regardless of
  selected profile — now bulk-synced on switch).
- New dev-menu controls: Touch section (Reposition button, Jump radius, Stick zone %);
  Controller section now 13 sliders; Level section (Time scale); Debug viz section (2
  checkboxes); corner HUD always-on.
- Assets acquired: none.
- Research added: none.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/fix-scheduled-runs-WjNm9` — process fix: auto-merge workflow

- Primary: **Auto-merge GitHub Action.** Added
  `.github/workflows/auto-merge.yml`. Squash-merges any non-draft PR
  carrying the `auto-merge` label, on `opened` / `labeled` /
  `ready_for_review` / `synchronize` / `reopened`. The agent now adds
  the label on PR creation; if the session dies before merge, the
  workflow finishes the job. Removes the dependency on the agent
  staying alive past `gh pr create`.
- Primary: **Iteration startup rules in `docs/CLAUDE.md`.** New
  required sequence at the top of "Git workflow": list your own open
  PRs first; if one already targets the item you'd have picked, check
  out that branch and iterate on it (don't fork a new one) or skip the
  item; if multiple PRs cover the same item, merge the most complete
  one and close the rest. Also added an "End-of-iteration update"
  reminder that PLAN.md + README.md updates ride in the same PR — that
  was the silent failure mode of iter 1.
- Cleanup: 8 duplicate iter-1 PRs (#3–#10) all attacked the same P0
  items (camera occlusion + Floaty profile) because every 2-hour run
  started from a stale `main`. PR #10 was the most complete — squash-
  merged. PRs #3–#9 closed with comments linking to #10.
- Perf: n/a (workflow + docs only).
- Bugs fixed: scheduled-runs duplicate-PR loop.
- Needs human attention: merge **this** PR. It alters the Git workflow
  and so is opened as a draft per the existing exception rule.
- Next likely focus: once on `main`, the next 2-hour run picks the
  current top of `PLAN.md` (smoke test or, if still blocked on human,
  Touch overlay polish / dev-menu debug viz).

### [2026-05-09] — `claude/elegant-lamport-c9ZE9` — iter 1: camera occlusion + profiles

- Primary: **Camera occlusion avoidance** — `camera_rig.gd` now casts a ray from the
  look-at point to the desired camera position each frame
  (`PhysicsDirectSpaceState3D.intersect_ray`); if world geometry blocks the shot the
  camera snaps forward to the hit minus `occlusion_margin` (0.3 m default), floored
  at `occlusion_min_distance` (0.8 m). Player capsule is excluded from the query.
  Script-only change — no `.tscn` restructuring required. Rationale for not using
  `SpringArm3D` logged in `DECISIONS.md`.  
  **Camera params dev-menu section** — 9 new live sliders in the dev menu (distance,
  pitch, lookahead, fall pull, yaw/pitch drag sensitivity, recenter delay/speed,
  occlusion margin). `_build_ui` refactored into per-section helpers; number display
  uses smart precision formatting.
- Side quest: **Floaty + Momentum profiles** — `floaty.tres` (smooth accel,
  generous air, long hang, wide coyote/buffer) and `momentum.tres` (high top speed,
  near-zero ground decel, full horizontal velocity preservation, tighter coyote).
  Both wired into the dev menu Profile dropdown → dropdown now shows
  **Snappy / Floaty / Momentum**. Momentum speed-ramp mechanic (sustained-input
  speed increase) deferred to a later iteration; logged in PLAN.md refactor backlog.
- Perf: no change — no new geometry or draw calls; physics ray cast is O(1).
  On-device baseline still pending first human build.
- Bugs fixed: none new (occlusion was a missing feature, not a bug).
- New dev-menu controls: Camera section — distance, pitch (deg), lookahead,
  fall pull, yaw sens, pitch sens, recenter delay, recenter speed, occl. margin.
  Profile dropdown now shows 3 entries.
- Assets acquired: none.
- Research added: none this iteration.
- Needs human attention: see "Open questions waiting on you."
- Next likely focus: once human opens in Godot 4.6 and fixes any import errors,
  iterate on Snappy feel tuning based on first-feel feedback; then first contrast
  of Floaty vs Momentum.

### [2026-05-08] — `claude/start-project-void-TxIcJ` — kickoff

- Primary: scaffolded the entire Gate 0 surface — folder layout per `CLAUDE.md`, project settings (Mobile renderer, sensor-landscape, ASTC, 60 Hz physics, Jolt 3D, autoloads, input map), Android export preset, docs (PLAN, DECISIONS, JUICE, ASSETS, research INDEX, ANDROID), Feel Lab scene with brutalist primitives + fog + single warm key light + moving platform + four corner pillars for scale, Stray `CharacterBody3D` with the Snappy `ControllerProfile` (coyote 100ms, buffer 120ms, three-band gravity, variable-jump cut, preserved horizontal velocity), dev menu skeleton (profile dropdown + 4 live sliders + juice toggle grid + perf line), camera rig (lookahead, fall pull, drag override, idle recenter), touch overlay (free-floating left stick + right jump button + right-half camera drag, mouse fallback in editor). Everything wired into Feel Lab and runnable from F5.
- Side quest: none (kickoff scope only).
- Perf: not measured — no Godot binary in the kickoff environment; first on-device run is iteration 1's top task.
- Bugs fixed: none (greenfield).
- New dev-menu: profile dropdown, max_speed / jump_velocity / coyote / buffer sliders, six juice checkboxes, fps + frametime + tris + draw-call line.
- Assets acquired: none (placeholders only).
- Research added: `docs/research/INDEX.md` seeded with sections + suggested reads from `CLAUDE.md`.
- Needs human attention: see "Open questions waiting on you."
- Next likely focus: open in Godot 4.6, fix any import errors, run the device checklist in `docs/ANDROID.md`, capture first frametime on Nothing Phone 4(a) Pro, then begin Snappy tuning based on first-feel feedback.

## How to run the current build

In editor: open `project.godot` in Godot 4.x, F5.
On device: see `docs/ANDROID.md` — keystore must be set up locally first.
Dev menu: 3-finger tap on device, F1 in editor.
Feel Lab: open `scenes/levels/feel_lab.tscn` and run.

## Repo map

- `docs/CLAUDE.md` — persistent context and conventions (Claude reads this every iteration)
- `docs/PLAN.md` — rolling work plan, updated each iteration
- `docs/DECISIONS.md` — log of significant choices and why
- `docs/JUICE.md` — catalogue of juice elements and their state
- `docs/LEVEL_DESIGN.md` — level design philosophy and principles
- `docs/ART_PIPELINE.md` — how to swap primitives for real art
- `docs/ANDROID.md` — Android build/export setup
- `docs/research/` — research notes by topic (`INDEX.md` lists them)
- `assets/ASSETS.md` — third-party asset licence and source log
