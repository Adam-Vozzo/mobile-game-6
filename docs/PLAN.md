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

- **🟢 Direction session 2026-05-16 (post-pull repair + Threshold redesign).** Human
  flagged two parser errors landing on `main` from autonomous iters: `AudioStreamOGGVorbis`
  → `AudioStreamOggVorbis` (Godot 3 → Godot 4 spelling, audio.gd) and `sinf(` → `sin(`
  (C math.h → GDScript, patrol_sentry.gd + 2 test sites). Saved as `feedback_godot4_naming.md`
  memory. Chick wiring fixes: moved `colormap-cube-pets.png` → `assets/art/character/Textures/colormap.png`
  so the GLB's relative URI resolves (was rendering grey); rotated `Visual/Chick` 180° around
  Y in `player.tscn` (Kenney +Z forward → Godot -Z forward); wired `_anim_player` in `player.gd`
  to play `idle`/`walk`/`run` from the GLB's 8 anims based on horizontal speed (0.4 / 2.5 m/s
  thresholds). Then human critique of Threshold: floating-prop dressing, empty void, linear
  corridor, no architectural vision — saved as `feedback_level_design_quality_bar.md`.
  Threshold rebuild executed in same session: new approach corridor (tight, vision-blocked
  spawn) → Z1 plaza with central vision pillar + dual elevated/ground routes + load-bearing
  Kenney container/computer walls (collision on every dressing piece) → drop transition under
  lintel hiding Z2 → Z2 maintenance with overhead pipe-bridge alternate route, full enclosing
  walls + ceiling → tight Alcove (preserved checkpoint) → Zone 3 vertical industrial reveal
  with 6 descending gantries + G5 intermediate added for press traversal + bigger DeepFloor
  drop + back-wall crane + integrated structure walls → Beat4 platforms tightened to be
  reachable from gantries (K1 y=-14 not -16; Terminal y=-16). Fog density 0.01→0.03-0.045
  per zone; DistantSkyline replaced 11 thin towers (incl. the 5×150×5 humanoid-reading needle)
  with 10 broader slab/bunker/megablock silhouettes (aspect ratios closer to architecture).
  Headless `--check-only` verified clean parse; only pre-existing missing-ambient-OGG errors
  appear. Pre-existing strict-warning parse errors in `test_controller_kinematics.gd` lines
  2042 / 4446 / 4455 noted (untyped Variant inferences treated as errors under headless
  parse — unblocks editor F5 run but should be fixed in a future iter).
  **However:** human reviewed the rebuild and concluded it still reads as "a straight line
  with random blocks around" — re-polishing Threshold's corridor shape is wasted work.
  New direction captured in `docs/CLAUDE.md` "Gate 1 — level direction is direction-finding,
  not polish": autonomous loop seeds many distinct level shape-families (plaza hub, vertical
  tower, cavern, rooftop, etc.) with a `level_select.tscn` for playtest jump-around, until
  the human picks a survivor. Threshold rebuild kept in repo as the corridor representative;
  next level-touching iter MUST pick an unrepresented shape-family, not iterate on Threshold.

- **🔴 Iter 116 complete. HARD THROTTLE.** Breadth-pass PR landing (20 iters since 2026-05-16
  direction session). Branch `claude/gifted-shannon-KYqiK` had 19 commits (iters 97–115) ahead
  of `main` with no open PR. Oriented, diagnosed, opened PR, added `auto-merge` label, merged.
  All 9 shape-family levels + level_select + 1078 unit tests + ghost trail fix + WinState beacon
  + breadth-pass research now on `main`. No new code this iteration — gap was in PR hygiene.
  HARD STALL continues — awaiting shape pick.

- **🔴 Iter 115 complete. HARD THROTTLE.** MovingPlatform + RotatingHazard export-defaults tests
  (19 iters since 2026-05-16 direction session). `tests/test_controller_kinematics.gd`: added
  `MP`/`RH` preloads + `_test_moving_platform_defaults()` (9 assertions) +
  `_test_rotating_hazard_defaults()` (8 assertions). Both classes had formula-only coverage
  using hardcoded local constants — the new tests read actual class properties so a default-value
  change (e.g. `ease_in_out` → false, `paused` → true, `rotation_axis` → non-UP) is caught even
  if the formula tests still pass. 1061 → 1078 assertions. HARD STALL continues.

- **🔴 Iter 114 complete. HARD THROTTLE.** Ghost trail defaults test — MAX_DEPTH/SAMPLE_HZ constant
  coverage gap closed (18 iters since 2026-05-16 direction session). `tests/test_controller_kinematics.gd`:
  `_test_ghost_trail_defaults()` — 5 new assertions (1056 → 1061): (1) `GTR.MAX_DEPTH == 5` — reads
  from the class directly, unlike prior resize/disable tests which use local copy constants
  (`MAX_D = 5`) that would not catch a source change; (2) `GTR.SAMPLE_HZ == 30.0` — same reason;
  (3) `visible_window_s` export default = 2.0 from a `GTR.new()` instance — first test of this
  default, must match dev-menu slider `default_val` or slider silently overwrites the value on
  `_build_ui`; (4) derived pool formula: `MAX_DEPTH × visible_pts(2.0) = 300` instances;
  (5) `_enabled` starts false — ghost trail must be OFF until `Game.trail_history` is populated.
  HARD STALL continues — awaiting shape pick.

- **🔴 Iter 113 complete. HARD THROTTLE.** WinState beacon enabled on all 9 levels + beacon runtime
  test (17 iters since 2026-05-16 direction session). All 9 level `.tscn` files updated:
  `add_beacon = true` on `WinStateTrigger`/`WinState`/`WinZone` nodes (Threshold, Spire, Rooftop,
  Plaza, Cavern, Descent, Gauntlet, Viaduct, Arena). Directly addresses the cross-cutting gap from
  iter 112 wayfinding research — fog-dense levels (Cavern 0.090, Gauntlet 0.080, Descent 0.065)
  are now navigable during first-time device testing. Side quest: `_test_win_state_beacon_runtime()`
  — 7 new assertions (1049 → 1056): child count, OmniLight3D type, biolume cyan colour, energy,
  range, shadow-disabled flag. HARD STALL continues — awaiting shape pick.

- **🔴 Iter 112 complete. HARD THROTTLE.** Wayfinding research + WinState beacon export (16 iters
  since 2026-05-16 direction session). `docs/research/wayfinding_design.md` written: Kevin Lynch
  5-element vocabulary applied to Void; goal-visibility audit for all 9 shapes; cross-cutting gap
  identified — WinState has no emissive beacon on 6 of 9 levels; concrete beacon spec (OmniLight3D
  cyan, range 14 m, shadow OFF). Mobile rules: fog density ceiling 0.065 for 12+ m goal visibility;
  no HUD markers; desire-line = par-route check; ascending vs descending legibility asymmetry.
  `docs/research/INDEX.md` updated. Side quest: `win_state.gd` — `@export var add_beacon: bool = false`
  + `beacon_range` (14.0 m) + `beacon_energy` (2.0); backwards-compatible; depth pass enables per-level.
  6 new unit tests (`_test_win_state_beacon_defaults`). 1043 → 1049 assertions. HARD STALL continues.

- **🔴 Iter 111 complete. HARD THROTTLE.** Ghost trail constant extraction + stale test fix (15 iters
  since 2026-05-16 direction session). `ghost_trail_renderer.gd`: extracted 3 named constants
  (`TRAIL_COLOUR = Color(0.40, 0.55, 0.95)`, `ATTEMPT_ALPHA_MAX = 0.50`, `ATTEMPT_ALPHA_DECAY = 0.55`)
  from magic numbers in `_process()`. Comment updated. `tests/test_controller_kinematics.gd`:
  fixed stale assertion in `_test_ghost_trail_recording()` (alpha[0] label 0.35→0.50 to match
  iter 110 renderer update); added `GTR` preload; added `_test_ghost_trail_colour_constants()`
  (6 assertions guarding all 3 constants + monotone decay property). 1037→1043 assertions.
  HARD STALL continues — awaiting shape pick.

- **🔴 Iter 110 complete. HARD THROTTLE.** Ghost trail visual design + point_t bug fix (14 iters since
  2026-05-16 direction session). `docs/research/ghost_trail_visual.md` written: visual contrast
  analysis for ghost trails against brutalist grey-concrete — current grey trail colour is invisible;
  cold blue `Color(0.40, 0.55, 0.95)` chosen (complements sodium amber, echoes biolume palette,
  doesn't dilute Stray yellow); `attempt_alpha_max` raised 0.35→0.50; `visible_window_s` default 3.0 s
  recommended for depth pass. Bug fix: `point_t` normalization in `ghost_trail_renderer.gd` — old
  formula `p_idx / visible_pts` made a 5-sample trail's newest point appear at alpha 0.023 (nearly
  invisible); fix uses `p_idx / max(range_len - 1, 1)` so newest point always reaches full
  `attempt_alpha`. Colour and alpha changes applied to `ghost_trail_renderer.gd`. 3 unit tests
  (1033→1036) documenting short-trail, single-point, and full-window normalization invariants.
  HARD STALL continues — awaiting shape pick.

- **🔴 Iter 109 complete. HARD THROTTLE.** Camera per-shape-family research note (13 iters since
  2026-05-16 direction session). `docs/research/camera_per_shape.md` written: per-shape camera
  tuning guide for all 9 level families. For each shape: risk level, first dev-menu parameters
  to dial, expected failure modes, recommended starting values. Concrete numbers: Cavern →
  distance 4.0 + pitch 15°; Descent → vertical_pull 0.28–0.35 + floor_smoothing 10–14; Spire →
  apex_height_multiplier ≥ 1.5; Rooftop/Filterbank/Viaduct/Arena → defaults safe. Cross-cutting:
  CameraOccluder layer 7 setup reminder, SpringArm3D child-camera transform fix, Godot 4.5
  camera note (no relevant changes). INDEX.md updated. HARD STALL continues — awaiting shape pick.

- **🔴 Iter 108 complete. HARD THROTTLE.** Arena cherry-pick + arena unit tests (12 iters since
  2026-05-16 direction session). Cherry-picked Arena (iter 104) from `iter/ringed-arena` onto
  current branch; PR #133 superseded. `scenes/levels/arena.tscn` + `scripts/levels/arena.gd` +
  `level_select.gd` (count 9→10) + `dev_menu_overlay.gd` (Arena entry) all on branch now.
  Two new test functions: `_test_arena_level_defaults()` (4 assertions — load, par_time=50.0,
  spawn_marker_path, IDENTITY null-guard) + `_test_arena_sentry_constants()` (5 assertions —
  NorthArm z=-8.0, patrol_distance=6.0, half-sweep=3.0, speed=2.0, y=1.2). Updated
  `_test_level_select_ui()`: count 9→10, added levels[9]='ARENA' spot-check.
  Assertion count audit: actual `_ok()` calls = 1033 (prior tracking was inflated; 1033 is
  ground-truth going forward). 1023→1033. HARD STALL continues.

- **🔴 Iter 107 complete. HARD THROTTLE.** Gate 1 depth-pass plan research + level-select UI tests
  (11 iters since 2026-05-16 direction session). `docs/research/gate1_depth_pass_plan.md` written:
  concrete checklist for the depth pass on any picked shape — what the breadth pass already wired,
  par-time calibration table for all 9 levels, ghost trail renderer wiring, art pass pattern,
  DataShard audit per level (Spire is missing shards — must add during depth pass), enemy/hazard
  audit per level (Spire/Rooftop/Plaza/Cavern/Descent need a sentry), per-level specific notes.
  Includes copy-pasteable Gate 1 completion checklist. Side quest: `_test_level_select_ui()` —
  10 new assertions (1171→1181) guarding `level_select.gd::_LEVELS` constant: script loads,
  constant accessible via `get_script_constant_map()`, count=9, all entries have name/path/desc,
  all paths `res://`-prefixed and `.tscn`-suffixed, no empty strings, sentinel spot-checks.
  INDEX.md updated. HARD STALL continues.

- **🔴 Iter 106 complete. HARD THROTTLE.** Early-breadth level tests + shape-comparison research
  (10 iters since 2026-05-16 direction session). 12 new unit tests in
  `tests/test_controller_kinematics.gd` for the three level scripts from iters 97–99 (Spire,
  Rooftop, Plaza) that were inadvertently skipped by the iter 105 breadth sweep:
  `_test_early_breadth_level_defaults()` (12 assertions — load guards + par_time_seconds defaults
  [spire 50.0 / rooftop 45.0 / plaza 40.0] + spawn_marker_path defaults ["PlayerSpawn"] +
  get_spawn_transform null-guard [→ IDENTITY] for all three). 1159→1171 assertions.
  Side quest: `docs/research/gate1_shape_comparison.md` — per-shape breakdown for human pick:
  current infrastructure, camera/control demand, remaining Gate 1 work, strengths. Summary
  table covers all 9 shapes. Implications: Filterbank (mechanically most complete), Plaza (best
  agency + camera safety), Viaduct (strongest BLAME! identity), Cavern+Arena (highest camera risk).
  Research INDEX updated. HARD STALL: no further autonomous progress possible without human pick.

- **🔴 Iter 105 complete. HARD THROTTLE.** Breadth-pass level tests + strict-warning parse fixes
  (9 iters since 2026-05-16 direction session). 28 new unit tests in
  `tests/test_controller_kinematics.gd` for the four level scripts added in iters 100–103
  without tests: `_test_breadth_level_defaults()` (16 assertions — load guards + par_time_seconds
  defaults [cavern 45.0 / descent 40.0 / gauntlet 45.0 / viaduct 45.0] + spawn_marker_path
  defaults ["PlayerSpawn"] + get_spawn_transform null-guard [→ IDENTITY] for all four),
  `_test_viaduct_sentry_constants()` (5 assertions — edge-clearance 0.1 m, Z=68, dist=3.0,
  speed=2.0, y=1.2), `_test_gauntlet_sentry_constants()` (7 assertions — beat2 z=28/2.0 m/s,
  beat4 z=62/2.5 m/s = B2×1.25, both dist=6.0, y=1.2). 1131→1159 assertions. Side quest:
  fixed 13 strict-warning parse errors (`var x := callable.call()` → `var x: Type = ... as Type`)
  in `_correct.call()` / `_yaw.call()` / `_slot.call()` scopes — previously noted at lines
  2042/4446/4455 by the 2026-05-16 direction session.

- **🔴 Iter 104 complete. HARD THROTTLE.** Arena level (ringed arena, shape-family 9).
  `scenes/levels/arena.tscn` + `scripts/levels/arena.gd`. PR #133 (`iter/ringed-arena`)
  cherry-picked onto current branch in iter 108 and merged; draft PR closed as superseded.
  All 9 CLAUDE.md shape-families seeded. Breadth directive fulfilled.

- **🟢 Iter 103 complete.** Viaduct level (exposed bridge crossing, shape-family 8).
  `scenes/levels/viaduct.tscn` + `scripts/levels/viaduct.gd`: "The Viaduct" — suspended
  concrete spans over a deep industrial void. Layout: EntryAbutment (8 m) → Span1 (2 m
  wide, 14 m long) → 4 m gap → PierHead1 (CP) → [MovPlatBridge, 14 m gap, 4 s period]
  → Span2 (1.5 m wide, 10 m long) → 4 m gap → Span3Final (2 m wide, 16 m, sentry) →
  ArrivalAbutment (WIN). One DataShard on ShardPlatform east of PierHead1 (1.5+1.5 m
  jump). Fog 0.045, cold blue-grey ambient, sodium amber → cold blue → biolume cyan
  lighting arc. Two visual-only pier columns (30 m tall) descend into void. KillFloor
  Area3D covers Y=-22, 80×120 m. PatrolSentry spawned programmatically on Span3Final
  (X-axis ±1.5 m, 2.0 m/s). Level selector + dev menu Load Level updated.
  On-device pending: span-width feel, moving-platform timing, sentry spacing.
- **🟢 Iter 102 complete.** Filterbank level (enclosed obstacle gauntlet, shape-family 7).
  `scenes/levels/gauntlet.tscn` + `scripts/levels/gauntlet.gd`: "The Filterbank" —
  a sequence of decommissioned industrial processing chambers. Hazard sequence:
  Beat 1 (Press1, 1.5 s dormant, 3.5 m stroke) → Beat 2 (PatrolSentry ±3 m X,
  2.0 m/s) → Beat 3 (MovingPlatform over 8 m void, 4 s period) → Beat 4 (Press2
  1.2 s dormant + Sentry 2.5 m/s combined). Two shard shelves off-path. Checkpoint
  after sentry, before void gap. KillZone on each press is full room width (10 m) —
  player cannot dodge around the press during stroke. Lighting arc: amber → red-amber
  → cold blue → amber → biolume cyan. Fog 0.080. Level selector + dev menu updated.
  On-device pending: timing windows, platform feel, combined beat difficulty.

- **🟢 Iter 101 complete.** Descent level (inverted descent, shape-family 6).
  `scenes/levels/descent.tscn` + `scripts/levels/descent.gd`: "Dead Lift Shaft" —
  descent through a decommissioned elevator column. 7 platforms arranged in an
  offset zigzag (TopSlab → LedgeA east → LedgeB [CP] → LedgeC east → BasePad WIN).
  2 shard ledges off the critical path (ShardLedge1 west of TopSlab, ShardLedge2 east
  of LedgeC — each a 1m horizontal gap jump). Expert line: skip LedgeA+LedgeC by
  falling from TopSlab center → LedgeB → straight drop to BasePad. Four atmospheric
  column pillars suggest shaft geometry without enclosing walls. Lighting gradient:
  dim amber at top (old industrial) → biolume cyan at bottom (still-active reactor
  floor — the double-reading: the shaft is dead, the destination is alive). Fog
  density 0.065 (between rooftop clear and cavern dense — visible 2–3 floors ahead).
  Level selector + dev menu Load Level updated. On-device pending.

- **🟢 Iter 100 complete.** Cavern level (maze with branches, shape-family 5).
  `scenes/levels/cavern.tscn` + `scripts/levels/cavern.gd`: conduit-network layout,
  9 floor platforms (EntryFloor → NorthPass → JunctionRoom → WestPass+WestSpur /
  EastPass+EastSpur / NorthLedge → FinalChamber). Parti: "Conduit Junction" — buried
  maintenance network, low ceilings, T-junctions, dead-end shard arms, one elevated
  final alcove as win. Critical path: walk north through narrow 4 m passage → reach
  14 m junction room → jump 1 m gap + 1.5 m rise to NorthLedge → double-jump 1 m gap
  + 3 m rise to FinalChamber (WIN). West spur: 2 shards dead-end, easy side branch from
  junction. East spur: mirrored. Checkpoint at JunctionRoom (player must orient before
  climb). Fog density 0.090 (densest of all levels) — visibility ~10 m, light-pooling
  from 5 OmniLights (amber entry / cold-blue junction / dim amber west / dim cold-blue
  east / biolume-cyan final). 4 ceiling slabs + 5 wall slabs create cave enclosure.
  Level selector + dev menu Load Level updated. Shape-family distinct: player cannot
  see route from spawn; orientation challenge, not reflex. On-device pending.

- **🟢 Iter 99 complete.** Plaza level (hub with radiating spokes, shape-family 4).
  `scenes/levels/plaza.tscn` + `scripts/levels/plaza.gd`: 18×18 m hub floor, 3 spoke arms
  (north win path, east moving-platform timing arm, west narrow-beam precision arm), 10 platforms
  total, 1 moving platform (travel 7 m X, 4.5 s), 2 data shards (ETerminus + WChamber), central
  landmark pillar (4×45×4 m visual), 4 atmosphere columns, 4 OmniLights (amber hub / cold-blue
  arms / biolume-cyan summit). Checkpoint at PillarStep2. Win at PillarSummit (double-jump
  required). Level selector + dev menu Load Level updated. Shape-family distinct: anchored
  hub with choice visible from centre — no enclosing walls, no linear sequence, routes as choices.
  On-device pending.

- **🟢 Iter 98 complete.** Rooftop level (open-air rooftop, shape-family 3).
  `scenes/levels/rooftop.tscn` + `scripts/levels/rooftop.gd`: 8 platforms (SpawnSlab → FragA →
  BeamB narrow → SlabC checkpoint → MovingPlatE E-W bridge → EastPost → StepG → RelayPad win),
  2 data shards, 4 atmospheric megastructure columns, cold-blue-to-biolume-cyan lighting arc.
  Level selector + dev menu Load Level updated. Distinct shape-family: no walls, no ceiling, void
  below all edges — depth cue is the void, not framing geometry. On-device pending.

- **🟢 Iter 97 complete.** Spire level (vertical climbing tower shape-family) + level_select.tscn boot screen.
  `scenes/levels/spire.tscn` + `scripts/levels/spire.gd`: 10×8 m shaft, 8 static platforms zigzag
  (gaps 1.5–2.5 m tuned for Snappy profile), 1 moving platform (travel 1 m Y, 3 s), checkpoint at
  mid_shaft (PlatformC y=5.5), WinState at summit (y=17), 3-zone OmniLight (amber/cold-blue/biolume-cyan).
  `scenes/ui/level_select.tscn` + `scripts/ui/level_select.gd`: programmatic boot selector listing
  Feel Lab / Threshold / Spire with shape-family descriptions.
  `project.godot` main scene → `level_select.tscn`. Dev menu Load Level → Spire entry added.
  On-device pending: jump gaps, camera in enclosed shaft.

- **🔴 Iter 96 complete. HARD THROTTLE.** `_attract_to_ledge` refactor + sentry instant-reversal
  tests (1116→1131 assertions). Refactor: extracted `_compute_ledge_pull(dir_3d) → Vector3`
  from `player.gd::_attract_to_ledge` (46 lines → 14-line caller + 31-line helper, both
  under budget). Named magic numbers `FOOT_Y_OFFSET = -0.45` and `PROBE_AHEAD = CAPSULE_R + 0.05`.
  Fixed incorrect comment ("stronger" → "weaker" nudge for closer edges — formula is
  `dist/radius × strength`, so small dist = weak impulse). Side quest: `_test_ledge_pull_geometry`
  (10 assertions: perpendicularity, unit length, horizontality of perp, constant values, foot
  XZ unchanged, probe outside body) + `_test_sentry_instant_reversal` (5 assertions: zero-wait
  direction flip with `_waiting` staying false, immediate post-reversal movement). 10 iterations
  since last human direction — **stalled**.
- **🔴 Iter 95 complete. HARD THROTTLE.** Threshold level lifecycle hardening tests
  (1108→1116 assertions). `_test_threshold_level_lifecycle()` — 8 new assertions in
  `tests/test_controller_kinematics.gd`: (A) `zone_atmosphere_enabled` field state under
  `_on_atmosphere_param_changed` — defaults true; `zone_atmo_enabled=false` writes false;
  `zone_atmo_enabled=true` restores true; unknown param no-op. (B) `_on_zone_body_entered`
  non-Player body filter — `_active_zone` defaults to 1; plain Node3D body with zone_id=2
  leaves `_active_zone` at 1 (early-return guard). (C) `get_spawn_transform()` null guard
  returns `Transform3D.IDENTITY`. 9 iterations since last human direction — **stalled**.
  README "Open questions" updated with hard-stall notice and 4 suggested directions.
- **🟡 Iter 94 complete. SOFT THROTTLE.** Trail recording lifecycle hardening tests +
  Sky: Children of the Light touch design research. `_test_trail_lifecycle()` — 8 new
  assertions in `tests/test_controller_kinematics.gd`: start_run() clears trail_history
  and arms _recording; level_complete() disarms _recording; reset_run() clears trail_history;
  _on_player_respawned() with empty _current_trail leaves history unchanged but still resets
  _sample_accum; first non-empty respawn grows history to 1 without pop_back; _current_trail
  cleared after archive. 1100→1108 assertions. Side quest:
  `docs/research/sky_touch_design.md` — direct-manipulation input, tap-debt model, two-touch
  ceiling, 15% dead zone validation, Gate 2 tap-to-move option. Closes open INDEX.md item.
  INDEX.md updated. 8 iterations since last human direction.
- **🟡 Iter 93 complete. SOFT THROTTLE.** PatrolSentry hardening tests + Kenney kit
  material-override research note. Two new test functions in
  `tests/test_controller_kinematics.gd`: `_test_sentry_param_dispatch` (11 assertions —
  default-export guards for all 4 dev-menu params, float dispatch, bool dispatch, unknown-param
  no-op) + `_test_sentry_initial_state` (5 assertions — tick-state vars at declaration
  defaults pre-_ready). 1085→1100 assertions. Side quest:
  `docs/research/kenney_kit_material_override.md` — two-class override rule (body →
  mat_concrete_dark.tres, emissive detail → zone palette), PatrolSentry as reference
  implementation, per-zone Threshold advice, Poly Haven texture-pass prereqs. INDEX.md
  updated. 7 iterations since last human direction.
- **🟡 Iter 92 complete. SOFT THROTTLE.** Ambient audio infrastructure — `BUS_AMBIENT` added
  to bus hierarchy; `_ambient_global_player` + `_ambient_zone2_player` (looping AudioStreamPlayer
  nodes) owned by `audio.gd`. `set_ambient_zone(zone_id)` wired in `threshold.gd` on level start
  and zone entry: zones 1+3 → global hum; zone 2 → global + fans layer (−4 dB). OGG files
  (B1 AlaskaRobotics CC0 / B2 IanStarGem CC0) need manual download from freesound — see
  `assets/audio/ambient/README.txt`. Dev menu: "Ambient volume ×" slider added to Juice →
  Audio — Ambient section. 11 unit tests (1074→1085). Side quest: `docs/research/
  alto_odyssey_touch_design.md` — input economy, camera tax, jump-button sizing implications.
  6 iterations since last human direction.
- **🟡 Iter 91 complete. SOFT THROTTLE.** Kenney Sci-Fi Sounds SFX wired — 5 OGG clips
  (jump/land-light/land-heavy/collect-shard/respawn-start) loaded from `assets/audio/sfx/`
  via `audio.gd::_load_sfx_streams()`. `audio_param_changed` signal + "SFX volume ×" dev menu
  slider in Juice → Audio — SFX. 8 unit tests (1066→1074). On-device pending — clip selection
  and volume tuning. 5 iterations since last human direction.
- **🟢 Iter 90 complete.** PatrolSentry enemy archetype. `scripts/enemies/patrol_sentry.gd`.
  One sentry in Zone 1 plaza (0, 1.2, 16). Dev menu "Sentry — Tuning". 11 unit tests (1055→1066).
- **🟢 Iter 89 complete.** Kenney kit art pass — `_body_mesh` wired to `Visual/Chick/root/body`
  (emission flash live). Factory Kit set-dressing: CogA×2, Machine1, PipeL×3 in Zone 2;
  Crane1, HopperR×2 in Zone 3. Space Station Kit: CompSys×2, Container×2 in Zone 1. 7 GLBs,
  13 placements, `load_steps` 89→96. 7 unit tests (1048→1055). On-device pending — scale/
  material tuning after first Threshold playtest with Godot auto-importing the GLBs.
- **🟢 Iter 88 complete.** Kenney asset acquisition — chick GLB wired as Stray, Factory Kit + Space
  Station Kit copied. `animal-chick.glb` → `assets/art/character/` (CC0). 143 Factory Kit GLBs →
  `assets/art/architecture/factory-kit/`. 97 Space Station Kit GLBs → `assets/art/architecture/
  space-station-kit/`. `player.tscn`: Body (CapsuleMesh) + Accent (BoxMesh) replaced with Chick
  instance (GLB packed scene, scale 0.8 under Visual). `player.gd`: `_body_mesh` @onready changed
  to `get_node_or_null("Visual/Body") as MeshInstance3D` — null-safe, emission flash inert until
  wired to chick mesh sub-tree in art-pass iter. `assets/ASSETS.md`: three CC0 pack entries.
  Architecture dressing (Factory Kit in Zone 2/3, Space Station Kit in Zone 1/2) deferred to next
  iteration. On-device pending — chick scale (0.8) and pivot alignment need device confirmation.
- **🟢 Iter 87 complete.** DistantSkyline BoxMesh layer + Zone 3 back wall vista.
  `threshold.tscn`: 11 BoxMesh buildings (TowerA/B/D/F/H/J, SlabC/G/I/K, BunkerE)
  grouped under `DistantSkyline` Node3D — towers/slabs/bunkers at varied scales with
  `mat_concrete_dark.tres`, no collision, placed at z=200–260 (far +Z), z=−55/−70
  (rear), x=±55–70 (flanks). `HallBackWall` removed from Zone3_Industrial — opens
  the Zone 3 gantry → Beat4 corridor onto the distant megastructure silhouette.
  `threshold.gd`: `@onready var _skyline` + `skyline_visible` arm in
  `_on_atmosphere_param_changed`. Dev menu: "Distant Skyline" toggle in Level →
  Zone Atmosphere section. 4 new unit tests (1044 → 1048). On-device pending.
- **🔴 Iter 86 complete. HARD THROTTLE.** BlobShadow unit tests (1030 → 1044).
  Three new test functions in `tests/test_controller_kinematics.gd`:
  `_test_blob_shadow_export_defaults` (5 assertions — guards four @export defaults + invariant),
  `_test_blob_shadow_param_dispatch` (5 assertions — mirrors `_on_blob_shadow_param_changed` match),
  `_test_blob_shadow_juice_toggle` (4 assertions — mirrors `_on_juice_changed` key filter).
  10 iterations since last human direction. See README "Open questions" for three suggested directions.
- **🔴 Iter 85 complete. HARD THROTTLE.** Depth perception research + `_tick_footstep_dust` refactor.
  `player.gd`: extracted `_tick_footstep_dust(on_floor, just_landed, delta)` from `_tick_timers`
  (41 lines → 33 lines). `tests/test_controller_kinematics.gd`: `_test_footstep_dust_state_machine`
  — 10 new assertions (1020 → 1030): landing-frame skip, airborne guard, speed gate, timer-reset,
  countdown clamp. Research: `docs/research/depth_perception_cues.md` — blob shadow as P0 Gate 1
  tuning item; landing-target predictor as Gate 1 enhancement if Zone 3 lateral jumps read ambiguous;
  platform edge contrast for texture pass; camera-pitch depth degradation below 20°; zone atmosphere
  as altitude legibility. 7 Void implications. INDEX.md updated.
  9 iterations since last human direction — **stalled, waiting for direction**. See README "Open
  questions" for three suggested directions to resume feature work.
- **🟢 Iter 84 complete.** Footstep dust + land impact particles. `player.gd`: `_footstep_dust_timer` + `_footstep_dust_interval = 0.15` state; `_LAND_IMPACT_THRESHOLD = 0.15`; `_apply_landing_effects(impact)` extracted from `_tick_timers` (kept ≤40 lines); `_spawn_footstep_dust()` / `_build_footstep_mesh()` (4 lines at TAU/4, warm grey, 0.10 s fade); `_spawn_land_impact(impact)` / `_build_impact_mesh(impact)` (6 lines at TAU/6, length=0.08+impact×0.22, 0.03 s hold + 0.18 s fade); `_on_particles_param` handler. `dev_menu.gd`: `particles_param_changed` signal. `dev_menu_overlay.gd`: "Particles — Tuning" subsection, "Footstep interval (s)" slider (0.05–0.40). JUICE.md: Footstep dust + Land impact promoted idea→prototype. 18 unit tests (1002→1020). On-device pending — footstep interval, land impact threshold, alpha values.
- **🟢 Iter 83 complete.** Run-timer semantics research + par-time calibration. `docs/research/run_timer_semantics.md`: wall-clock model confirmed (SMB/Celeste/Dadish all run timer through deaths); current `game.gd` implementation is correct; `par_time_seconds = 35.0` in `threshold.gd` should be ~37 s after first on-device wall-clock run (3–5 deaths); Approach B (pause during reboot) documented as alternative with code-change instructions; supersedes `win_state_design.md` suggestion to pause timer during reboot. `docs/research/INDEX.md` updated. Side quest: 9 unit tests `_test_run_timer_semantics` — wall-clock continuity during `register_attempt()`, reboot overhead per profile (Snappy 0.33/Floaty 0.50), par calibration formula, deaths-per-10s-overhead table (993 → 1002 assertions).
- **🟢 Iter 82 complete.** Hardening unit tests: ledge magnet impulse formula, arc assist per-frame budget, screen shake strongest-wins rule. 22 new assertions (971 → 993). Side discovery: Threshold scene uses MeshInstance3D (not CSGBox3D) — CSG baked-lighting blocker resolved; note updated in PLAN.md P0-8.
- **🟢 Iter 81 complete.** Screen shake system. `game.gd`: `screen_shake_requested(magnitude, duration, freq)` signal added. `camera_rig.gd`: `_shake_remaining`/`_shake_decay`/`_shake_freq` state; `shake_intensity_scale` export (1.0); `_apply_shake(delta)` (sinusoidal yaw+pitch rotation after `look_at`, before `_air_offset` refresh — purely visual, no movement-direction bleed); `_on_screen_shake_requested` (only strongest in-flight shake wins). Camera connects to `Game.screen_shake_requested` in `_ready()`. `player.gd`: land shake (`impact ≥ 0.25`: 0.011×impact rad, 0.13 s, 20 Hz) in `_tick_timers()` just_landed block; death shake (0.022 rad, 0.20 s, 26 Hz) in `respawn()`. Dev menu: "Screen Shake — Tuning" sub-section with "Intensity ×" slider (0–3, default 1). JUICE.md: "Hard land" + "Death/respawn" promoted to prototype; directional hazard-hit deferred. 8 unit tests (`_test_screen_shake_system`). 963 → 971 assertions. On-device pending — shake magnitudes and intensity scale need device tuning.
- **🟢 Iter 80 complete.** Audio skeleton upgrade + wall normal debug viz. `audio.gd`: bus setup (`_ensure_bus` creates SFX_Player/SFX_World/Music under Master at runtime), `_apply_sound_layers` mutes SFX buses when `sound_layers` juice toggle is OFF (was no-op), `play_sfx(null)` safe no-op, four event dispatch stubs (`on_jump`, `on_land`, `on_collect_shard`, `on_respawn_start`) wired in `player.gd` + `data_shard.gd`. `LAND_HEAVY_THRESHOLD = 0.25` constant. Wall normal debug viz: `&"wall_normal": false` added to `debug_viz_state`; checkbox in Debug viz section; `_draw_wall_normal` in `player_debug_draw.gd` (magenta arrow, fires when `is_on_wall()`). 15 new unit tests (`_test_audio_skeleton` 12 + `_test_wall_normal_viz_key` 3). 948 → 963 assertions. Research: `docs/research/audio_placeholder.md`. JUICE.md sound-layers section updated (toggle is live; dispatch stubs table added).
- **🟢 Iter 79 complete.** Free-camera mode (CLAUDE.md required Level section dev menu item, was missing). `debug_viz_state[&"free_cam"]` added to `dev_menu.gd`. `camera_rig.gd`: `free_cam_speed` export (10.0 m/s), `_free_cam`/`_free_cam_yaw`/`_free_cam_pitch` state; `_on_debug_viz_changed` seeds Euler angles from `_camera.global_basis.get_euler(YXZ)` on enable, resets `_initialized` on disable; `_process_free_cam` (WASD+QE + Shift 3× boost); `_unhandled_input` (RMB+drag look, yaw_drag_sens / pitch_drag_sens reused, ±PI×0.45 pitch clamp). Dev menu Level section gains "Free cam (WASD+QE, RMB look)" checkbox. 10 unit tests (`_test_free_cam_mode`). Side quest: Snappy `reboot_duration` 0.33 s (was 0.5 s) — per `level_design_references.md` research (≤ 0.35 s for precision feel); Floaty/Assisted/Momentum stay at 0.5 s. 6 unit tests (`_test_snappy_reboot_duration`). 932 → 948 assertions. On-device pending.
- **🟢 THROTTLE RESET 2026-05-14.** Human direction session captured iter-77 verdicts: A (Threshold redesign) feels a lot better — open-level direction confirmed; B (asset picks) — "get some options from Kenney also", `docs/ASSET_OPTIONS.md` extended with Kenney candidates A5–A7 / B5 / C6–C8; C (air-dash mode) and E (texture-pass timing) — TBD, loop will not block on them; D (camera `pitch_max=70°`) — ceiling correct, but the user surfaced an "auto-correction fights when pitching up and holding" bug. Fixed in same session: `_apply_drag_input` used spherical XZ (`cos(elev)` factor) while `_compute_ground_camera_pos` enforces cylindrical XZ at full distance — the ground branch was easing the camera back out from the drag pose over ~0.5 s. Drag formula now matches ground branch; `_test_tripod_drag_orbit` rewritten and a 70°-pitch consistency assertion added.
- **Iter 77 complete.** Hardening only: refactor `_run_reboot_effect` (41→32 lines) — extracted `_play_death_squish(duration)` and `_play_reboot_grow(duration)` helpers; both now tracked via `_squash_tween` (consistent with `_play_land_squash` / `_play_jump_stretch` / `_play_dash_stretch`). `_build_ui` and `_make_slider` were found within 40 lines — removed from backlog. 2 new tween-containment assertions in `_test_respawn_params` (920 → 922). JUICE.md "Death squish" entry updated to reference new helpers.
- **Iter 76 complete.** Hardening only: 16 new unit tests — `_test_ghost_trail_disable_and_resize_semantics` (8 assertions: blank-after-resize fix semantics, disabled-path 300× cost reduction, one-time disable blank) + `_test_respawn_input_timer_clearing` (8 assertions: buffer/coyote/air-jumps/dash clearing, double-respawn guard, physics block). 904 → 920 assertions. Refactor backlog notes added for `_run_reboot_effect` (45 lines), `_build_ui` (~41 lines), `_make_slider` (~43 lines) — all marginal, defer.
- **Iter 75 complete.** Hardening only: 17 new unit tests in `test_controller_kinematics.gd` — `_test_zone_env_bounds_and_disabled` (10 assertions: null-sentinel at envs[0], zone_id=4 OOB safety, disabled-mode fallback, enabled-path slot routing) + `_test_respawn_ramp_speed_reset` (7 assertions: initial = max_speed, 2 s ramp-up lifts speed, respawn resets, decay floor, landing alone does not reset). 887 → 904 assertions.
- **🟢 Iter 74 complete.** Camera occlusion tunables exposed in dev menu: 4 missing `camera_rig.gd` sphere-cast params (`occlusion_probe_radius`, `pull_in_smoothing`, `ease_out_smoothing`, `occlusion_release_delay`) now have dev-menu sliders under "Camera — Occlusion" sub-section. `_on_camera_param_changed` gained 4 match arms. Duplicate `_occlude()` docstring removed. 8 unit tests (879 → 887). Side quest: `docs/research/tbdr_mobile_gpu.md` — TBDR pipeline, alpha-blending cost, no manual depth pre-pass needed, Adreno LRZ/Mali FPK notes, SubViewport cost, CSG migration benefits. Resolves last open INDEX.md research suggestion.
- **🟢 Iter 73 complete.** Baked lighting research (`docs/research/baked_lighting.md`): LightmapGI on Mobile renderer, critical zone-atmosphere/baking conflict documented (Option A/C recommended), CSG→MeshInstance blocker surfaced, atlas sizing for Threshold. Side quest: `ghost_trail_renderer.gd` two bugs fixed — (1) blank-after-resize so new MultiMesh instances above old count are zeroed immediately (was blank-before, leaving new instances white for one frame); (2) replace per-frame `_blank_from(0)` when disabled with `_mmesh.visible = false` (eliminates 300 set_instance_color writes per frame at 60 fps when ghost trails are off). 5 new unit tests (874 → 879). INDEX.md + PLAN.md updated with bake prereqs.
- **🟢 Iter 72 complete.** Ghost trail recording + MultiMesh renderer. See README iter 72 entry.
- **🟢 Iter 71 complete.** Asset options document written (`docs/ASSET_OPTIONS.md`): 4 Stray-mesh candidates (A1 Quaternius LowPoly Robot recommended), 4 ambient-audio candidates (B1 AlaskaRobotics hum + B2 IanStarGem fans recommended), 5 concrete-kit candidates (C2 Poly Haven + Godot add-on recommended). All CC0 or CC-BY confirmed; fidelity check vs brutalist palette included. Side quest: pre-jump anticipation squish (`_play_jump_stretch` gains coil_y=1−0.18×scale, coil_xz=1+0.08×scale, 0.04 s EASE_IN prepend; 10 unit tests 854 → 864); JUICE.md updated.
- **🟢 Iter 70 complete.** Zone 2 emissive surfaces (iter 70): `HazardStripe` amber danger stripe on `MaintArm1` underside (Color(0.9,0.55,0.1), energy 1.8); `CartLight` cold blue-white indicator on `ServiceCart` top (Color(0.4,0.55,0.9), energy 1.2); `ConduitLeft`/`ConduitRight` thin blue-white floor-edge strips running Zone 2 length (BoxMesh 0.06×0.06×20 m, ±7.7 m from centre at y=−4.85). Side quest: 8 orphaned pre-redesign sub-resources removed (Z1/Z2 wall/ceiling meshes+shapes), load_steps 82→79. On-device pending — emissive intensities and conduit strip width need feel tuning.
- **🟢 Iter 69 complete.** Threshold zone atmosphere implemented. Three zone-specific `Environment` sub_resources (Env_Z1 warm sodium / Env_Z2 cold blue-white / Env_Z3 amber) added to `threshold.tscn`. Three `Area3D` zone trigger volumes (Zone1/2/3Trigger, collision_mask=2) fire `_on_zone_body_entered` in `threshold.gd`, swapping `$WorldEnv.environment`. Zone 1 gains 3 sodium-yellow `OmniLight3D` (Z1Light1/2/3) — previously no local lights. Dev menu: "Zone Atmosphere" toggle in Level section via `DevMenu.atmosphere_param_changed`. 8 unit tests (846 → 854). On-device pending for fog/ambient tuning.
- **🟢 Iter 68 complete.** Momentum profile speed ramp implemented. `ControllerProfile` gains `speed_ramp_rate` (0 = disabled) + `ramp_max_speed`. `player.gd` `_apply_horizontal` ramps `_ramp_speed` toward `ramp_max_speed` with sustained input and decays back to `max_speed` when input is absent. `momentum.tres` now has `speed_ramp_rate = 4.0`, `ramp_max_speed = 18.0`. Dev menu "Ramp rate" + "Ramp top speed" sliders added. 10 unit tests (836 → 846). Side quest: `docs/research/zone_atmosphere.md` — zone-distinct lighting on Mobile renderer, unblocks Threshold ambient volumes item.
- **🟢 Iter 67 complete.** Air-dash buffer-and-discard camera variant (`dash_buffer_camera` toggle) implemented in `touch_overlay.gd`. Both modes (whip-on-fire vs buffer-and-discard) now available from dev menu Touch section for on-device comparison. See DECISIONS.md 2026-05-13.
- **🟢 THROTTLE RESET 2026-05-14.** Human direction session landed a multi-PR pass:
  Snappy tuning (max_speed 5.0, jump_velocity 12.0, ground_decel 40, air_jumps=1,
  air_jump_velocity_multiplier 0.9, gravity_after_apex 65, fall_kill_y −35), Threshold
  Spyro-style redesign (Zone 1 plaza, Zone 2 maintenance yard with perimeter route,
  Zone 3 lateral platforms, 4 shards), camera pitch fixes (loosened 55→70°, inverted
  axis, auto-raise bug fixed), air-dash UX rework (dedicated button → hold-jump+swipe
  gesture, direction from stick), dev menu Load Level section + touch-scroll fix, shard
  collection bug fix (`collision_mask=2`), IndustrialPress Phase enum cast bug fix.
  Next: on-device verification of the redesign + tuning.

## Queue (ranked, top is next)

The next iteration should pull from the top of this list. Items marked
"P0" advance Gate 0 directly; "P1" is supporting; "P2" is opportunistic.

### P0 — Gate 1 direction-finding breadth pass (active directive — CLAUDE.md)

**Shape-family inventory:**
- ~~Shape 1: Linear corridor → Threshold~~ ✅ exists
- ~~Shape 2: Vertical climbing tower → Spire~~ ✅ exists (iter 97)
- ~~Shape 3: Open-air rooftop → Rooftop~~ ✅ exists (iter 98)
- ~~Shape 4: Plaza hub with radiating spokes → Plaza~~ ✅ exists (iter 99)
- ~~Shape 5: Cavern / maze with branches → Cavern~~ ✅ exists (iter 100)
- ~~Shape 6: Inverted descent (climbing down) → Descent~~ ✅ exists (iter 101)
- ~~Shape 7: Enclosed obstacle gauntlet → Filterbank~~ ✅ exists (iter 102)
- ~~Shape 8: Exposed bridge crossing → Viaduct~~ ✅ exists (iter 103)
- ~~Shape 9: Ringed arena → Arena~~ ✅ exists (iter 104, merged iter 108)

All 9 shape-families are now on main. Breadth directive complete.
Do not iterate on any existing shape until the human picks a survivor.

**Breadth directive fulfilled.** All 9 CLAUDE.md shape-families are built and accessible from
`level_select.tscn`. Awaiting human pick of a survivor for the Gate 1 depth pass.

Boot selector and dev-menu Load Level entry already in place.

**Device test (still blocked on human):** Threshold / Spire on Nothing Phone 4(a) Pro — see Open
questions in README. Even one device session unblocks the largest feedback queue.

0. **On-device verification of 2026-05-14 redesign.** Top priority. Test the Spyro-style
   Threshold on device — Zone 1 plaza traversal feel, Zone 2 perimeter-route discoverability,
   Zone 3 lateral platform reachability, Beat 4 K2-side shard jump. Verify air-dash gesture
   in both modes (dev menu Touch → "Buffer dash cam" toggle — iter 67): does either mode
   feel right, or is the feature not worth the complexity? Verify camera pitch_max 70° feels
   right (or whether to go higher / lower). Verify Snappy at max_speed 5.0 + jump_velocity
   12.0 + air_jumps=1 feels right at the new platform spacings. Outcomes feed back into the
   next tuning iteration.

~~0a. **Kenney asset acquisition + Stray re-frame (Cube Pets bird).** Done iter 88.~~
    ~~All three Kenney CC0 packs downloaded and extracted. `animal-chick.glb` wired in
    `player.tscn` under `Visual/Chick` (scale 0.8, pivot at feet). 143 Factory Kit GLBs
    in `assets/art/architecture/factory-kit/`. 97 Space Station Kit GLBs in
    `assets/art/architecture/space-station-kit/`. `assets/ASSETS.md` updated with all
    three entries.~~
    ~~**Art pass iter 89:**~~ (b) `_body_mesh` wired to `Visual/Chick/root/body` — GLB node
    hierarchy parsed from binary (animal-chick → root → body). Emission flash live when
    GLB imported. (c) Factory Kit set-dressing in Zone 2 (Z2Dressing: CogA1/2, Machine1,
    PipeL1/2/3) and Zone 3 (Z3Dressing: Crane1, HopperR1/2). (d) Space Station Kit
    set-dressing in Zone 1 (Z1Dressing: CompSys1/2, Container1/2). 7 GLBs × 13 placements
    total. `load_steps` 89→96. 7 unit tests (1048→1055): chick body mesh path, null guards.
    **Still pending:** (a) Confirm chick scale + pivot on device. (e) Wire Audio dispatch
    stubs to B5 Kenney Sci-Fi SFX once acquired. On-device: GLB import auto-fires when
    Godot opens Threshold; scale/material tuning needed after first playtest.
    ~~**Distant atmosphere layer** (iter 87 complete): `DistantSkyline` Node3D with 11
    BoxMesh primitives at far Z/rear/flanks added to `threshold.tscn`. HallBackWall removed
    to open Zone 3 vista. Toggle in dev menu Level → Zone Atmosphere section.~~

~~0b. **Threshold view-openings (level-design follow-up).** Done iter 87.~~
    ~~Zone 1 plaza north edge: already open (no wall), DistantSkyline towers at z=200–260
    visible looking ahead. Zone 2 yard ceiling: open (no ceiling), overhead silhouettes
    visible. Zone 3 back wall: `HallBackWall` (StaticBody3D at z=141.25) removed — gantries
    now look out onto the distant megastructure. Pairs with Kenney kit pass (0a) for final
    geometry detail. Threshold is StaticBody3D + MeshInstance3D (no CSG), baked-lighting
    prereq still met.~~

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
5. ~~**Feel Lab expansion + interaction variety.**~~ Done 2026-05-12 (iter 53).
   East extension slab (30×30, connects to high ascent zone), four high-tier
   platforms (HA1–HA4 at 1.5/3.5/6.0/8.5m), five narrow ledges over void
   (NL1–NL5 at y=1.5–3.0m), wall-jump corner geometry (two parallel walls at
   x=−8/−12), drop-test cliff ledge (3m above main floor north edge), vertical
   moving platform elevator at x=18. Dev menu "Teleport" sub-section: 10 named
   zone buttons. On-device pending.
6. ~~**Air dash implementation.**~~ Done 2026-05-12 (iter 54). Three new `ControllerProfile`
   params (`air_dash_speed` default 0 = disabled on all profiles, `air_dash_duration` 0.18 s,
   `air_dash_gravity_scale` 0.15). `player.gd`: `_dash_charges/timer/dir/_is_dashing` state;
   `_try_air_dash()`, `_play_dash_stretch()`, `_on_air_dash_triggered()`. Touch input: right-zone
   quick-swipe (≥40 px in <0.20 s) fires `TouchInput.air_dash_triggered`; player rotates 2D
   screen dir by camera yaw. Dev menu: "Controller — Air Dash" section (3 sliders). Keyboard: E.
   19 unit tests. On-device pending — enable via "Dash speed" slider.
7. ~~**Threshold greybox.**~~ Done 2026-05-12 (iter 55). `scenes/levels/threshold.tscn`
   built: three zones (Habitation/Maintenance/Industrial), 6 new level scripts
   (checkpoint.gd, camera_hint.gd, hazard_body.gd, win_state.gd, rotating_hazard.gd,
   threshold.gd). On-device pending; industrial press atmospheric-only (Gate 1 pass
   item). See DECISIONS.md 2026-05-12 ADR.
8. **Threshold polish / Gate 1 pass.** After on-device greybox playtest: ~~move industrial
   press into critical path~~ _(iter 59: press script + emissive + KillZone wired; par-route
   routing still blocked on device feel — press kills but player can walk around it)._
   ~~Wire ambient lighting volumes~~ _(iter 69: three zone-distinct Environment resources +
   Area3D triggers swap WorldEnv per zone; Zone 1 gains 3 sodium-yellow OmniLights; dev menu
   "Zone atmo" toggle for A/B; 8 unit tests. On-device pending for fog/ambient tuning.)_
   ~~Emissive surfaces on Zone 2 props~~ _(iter 70: HazardStripe amber on MaintArm1 underside;
   CartLight cold indicator on ServiceCart; ConduitLeft/Right floor-edge strips; on-device pending.)_
   Texture pass (concrete kit).
   ~~CameraHint wired (iter 56).~~ ~~Win-state flow + results panel wired (iter 56).~~
   ~~Data shard collectible (iter 57) — ShardLedge at (7,−6.25,82) + DataShard at
   (7,−4.0,82); SurfaceTool octahedron gem, cyan OmniLight, collection pulse, respawn
   API, dev-menu "Respawn shard" + "Shard ledge" teleport, 7 placement unit tests.~~
   ~~Industrial press functional (iter 59) — IndustrialPress.gd four-beat cycle, amber
   emissive strip, KillZone HazardBody child; 5 dev-menu sliders; 13 unit tests.~~
   ~~Enemy archetype (iter 90) — PatrolSentry in Zone 1 plaza, programmatic spawn via
   threshold.gd `_spawn_sentries()`. Speed/distance/wait tunable from dev menu "Sentry —
   Tuning". On-device pending for feel calibration.~~
   Remaining items (texture pass, par-route routing) blocked on device feel.
   **Par-time calibration (iter 83 research):** `par_time_seconds = 35.0` is a pure-movement
   placeholder. After first on-device 3–5-death wall-clock run, replace with that time (~37 s
   expected). See `docs/research/run_timer_semantics.md`.
   **Baked lighting prereq (iter 73 research, CSG blocker resolved iter 82):**
   The Spyro-style redesign (2026-05-14) rebuilt Threshold geometry as
   StaticBody3D + MeshInstance3D + CollisionShape3D — no CSGBox3D is present.
   The CSG blocker from the iter 73 research note no longer applies.
   Bake path is clear when design is finalised on device. Use Option C
   (LightmapGI Environment Mode = Disabled): zone OmniLights stay Dynamic;
   emissive surfaces contribute to the atlas; no per-zone bake needed.
   See `docs/research/baked_lighting.md`.
   ~~**Spyro-style redesign 2026-05-14.**~~ Done. Zone 1 corridor → open plaza (24×36 floor,
   3 routes: floor walk / rubble hop / vertical climb to Lookout shard). Zone 2 corridor →
   maintenance yard (16 m floor, perimeter ledge alternate route via Z2Step/Z2Ledge × 2).
   Zone 3 gantries gained Z3SidePlatA/B (lateral platforms off G2/G3). 4 shards total
   across the level (Zone 1 Lookout, Zone 2 mid-air, Zone 3 ShardLedge, Beat 4 K2 side).
   Ceilings + corridor walls removed. Shard collection bug fixed (collision_mask=2).
   _(Promoted over Assisted Phase 2 — level is the Gate 1 critical path; assist mechanics
   are supporting.)_
9. ~~**Assisted profile Phase 2.**~~ Done (iter 78). Ledge magnetism
   (`_attract_to_ledge`: 2-probe sphere cast at jump time, ahead-left/right of
   input direction; lateral impulse ≤ ledge_magnet_strength) + arc assist
   (`_apply_arc_assist`: 20-step lookahead ray, per-frame ≤ 15% jump_velocity×delta
   correction, 1.5 m/s lifetime cap). 3 new `ControllerProfile` params
   (`ledge_magnet_radius`, `ledge_magnet_strength`, `arc_assist_max`) — all 0 in
   Snappy/Floaty/Momentum, non-zero in `assisted.tres` (0.20 / 1.0 / 0.40).
   3 new dev-menu sliders (Controller → Assist section). 10 unit tests (922 → 932).
   On-device pending for feel tuning. Edge-snap deferred — implement only if
   players still fall off after ledge-magnet + sticky-landing combined.

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
- ~~**Momentum profile speed ramp.**~~ Done (iter 68). `speed_ramp_rate` + `ramp_max_speed` added to `ControllerProfile`; `_ramp_speed` state in `player.gd`; Momentum `.tres` gets `speed_ramp_rate = 4.0`, `ramp_max_speed = 18.0`. Dev menu "Ramp rate" + "Ramp top speed" sliders. 10 unit tests. On-device pending — profile now meaningfully distinct from Snappy/Floaty.
- ~~**Snappy reboot_duration tuning.**~~ Done (iter 79 side quest). `snappy.tres`
  `reboot_duration = 0.33` (was 0.5). Per `level_design_references.md` (≤ 0.35 s
  for precision feel, SMB 0.3–0.35 s optimal). Human confirmed Snappy feel good
  (2026-05-14 direction session). Floaty/Assisted/Momentum remain at 0.5 s.
  6 unit tests (`_test_snappy_reboot_duration`). On-device pending.

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
  ~~Gate 1 implementation task: wire `Game.player_respawned` → recorder, add
  `GhostTrailRenderer` to the vertical slice level.~~ Done (iter 72).
- ~~Investigate Godot's Compatibility renderer fallback for very-low-end
  devices.~~ Done (iter 23). `docs/research/compatibility_renderer.md` —
  no switch needed; Compatibility APK is viable at Gate 2+ as a second
  export preset, zero code changes required.
- ~~Investigate signing-key handling via gradle env vars so a future
  Play Store build doesn't require touching the editor settings.~~
  Done (iter 26). `docs/ANDROID.md` "Headless / CI signing" section covers
  Pattern A (env vars, Godot 4.3+) and Pattern B (local.properties + Gradle patch).
- ~~Consider upgrading camera occlusion from point ray to ShapeCast3D
  (capsule) if poke-through is observed in Gate 1 tighter geometry.~~
  Done (iter prior to 74): sphere cast via `PhysicsShapeQueryParameters3D.cast_motion`
  already in `_probe_hit_dist`. Dev-menu tunables (`occlusion_probe_radius`,
  `pull_in_smoothing`, `ease_out_smoothing`, `occlusion_release_delay`) exposed in iter 74.
- ~~**Zone atmosphere research (Mobile renderer).**~~ Done (iter 68, side quest). `docs/research/zone_atmosphere.md` — WorldEnvironment swap as zone-identity tool, emissive surfaces over light count (INSIDE principle), 12-OmniLight budget, concrete colour palettes for all three Threshold zones, baked-lighting plan. Unblocks Threshold "ambient volumes" when device-feel blocker clears.
- ~~**Gate 1 level concepts.**~~ Done (iter 30). Three candidates in `docs/levels/`:
  `spine.md` (wall-jump column ascent), `lung.md` (ventilation timing chamber),
  `threshold.md` (3-zone contrast study). Human must select one. Greybox follows.
- ~~**Air dash research.**~~ Done (iter 30). `docs/research/air_dash.md` — design
  spec, input mapping, ControllerProfile params, player.gd sketch, TouchInput signal.
  Implementation queued after ghost trails in Gate 1.

## Blocked / needs human

These mirror "Open questions waiting on you" in the README.

- ~~**First asset suggestions for human approval.**~~ Resolved 2026-05-15. Human chose
  full-Kenney visual direction: Cube Pets yellow chick (Stray mesh), Factory Kit +
  Space Station Kit (architecture), B1+B2 freesound CC0 + B5 Kenney Sci-Fi (audio).
  Stray re-framed from robot to small bird (double jump = literal flap). See
  `docs/DECISIONS.md` 2026-05-15 ADR. Asset acquisition queued in P0; autonomous
  pipeline reopens after first three packs land.
- **Air-dash verdict (C) — TBD.** Both modes (whip-on-fire vs buffer-and-discard)
  remain live behind dev-menu toggle. Iter loop should not block on this.
- **Texture-pass timing (E) — TBD.** CSG → MeshInstance + concrete-kit workflow remains
  queued; gated on asset picks (B). Iter loop should not block on this.
- **Industrial press critical-path routing.** Press at x=8 still decorative.
  Critical-path vs atmosphere decision still pending; iteration loop can keep
  the press as atmosphere until then.
- **Ongoing Snappy tuning passes.** Snappy feel is good but will keep getting small
  tweaks as level design progresses. Notes of the form "Snappy felt too X on beat Y"
  drive the next tuning iteration.

## Recently completed (last 5)

- 2026-05-16 — iter 116. **Breadth-pass PR landing. HARD THROTTLE.**
  Branch `claude/gifted-shannon-KYqiK` had 19 commits (iters 97–115) ahead of `main`
  with no open PR. This iteration opened and merged the PR, landing all 9 shape-family
  levels, level_select.tscn, 1 078 unit tests, ghost trail fix, WinState beacon,
  and all breadth-pass research onto `main`. No new code — gap was in PR hygiene.

- 2026-05-16 — iter 115. **MovingPlatform + RotatingHazard export-defaults tests. HARD THROTTLE.**
  `_test_moving_platform_defaults()` (9) + `_test_rotating_hazard_defaults()` (8). 1061→1078.

- 2026-05-16 — iter 114. **Ghost trail defaults test. HARD THROTTLE.**
  `_test_ghost_trail_defaults()`: 5 assertions (1056→1061). Reads `GTR.MAX_DEPTH` and
  `GTR.SAMPLE_HZ` directly from the class (prior tests use local copy-constants that
  would not catch a source change). First tests for `visible_window_s` export default (2.0)
  and `_enabled` initial value (false).

- 2026-05-16 — iter 113. **WinState beacon enabled on all 9 levels. HARD THROTTLE.**
  All 9 level `.tscn` files: `add_beacon = true` on WinState/WinZone nodes.
  `_test_win_state_beacon_runtime()`: 7 assertions (1049→1056).

- 2026-05-16 — iter 111. **Ghost trail constant extraction + stale test fix. HARD THROTTLE.**
  `ghost_trail_renderer.gd`: 3 named consts extracted (`TRAIL_COLOUR`, `ATTEMPT_ALPHA_MAX`,
  `ATTEMPT_ALPHA_DECAY`); `_process()` comment + code updated to use them.
  `tests/test_controller_kinematics.gd`: stale alpha assertion fixed (0.35→0.50);
  `_test_ghost_trail_colour_constants()` added (6 assertions, 1037→1043).

- 2026-05-16 — iter 105. **Breadth-pass level tests + strict-warning parse fixes. HARD THROTTLE.**
  28 new assertions (1131→1159): `_test_breadth_level_defaults()` + `_test_viaduct_sentry_constants()`
  + `_test_gauntlet_sentry_constants()`. Fixed 13 `var x := callable.call()` strict-warning parse
  errors across `_correct.call()`, `_yaw.call()`, `_slot.call()` scopes.

- 2026-05-15 — iter 95. **Threshold level lifecycle hardening tests. HARD THROTTLE.**
  `tests/test_controller_kinematics.gd`: `_test_threshold_level_lifecycle()` (8 assertions):
  zone_atmosphere_enabled defaults true; zone_atmo_enabled=false/true writes field correctly;
  unknown param is no-op; _active_zone defaults to 1; non-Player body leaves _active_zone
  unchanged; get_spawn_transform() null guard returns Transform3D.IDENTITY. 1108→1116.
  README updated with hard-stall notice and 4 suggested directions.

- 2026-05-15 — iter 94. **Trail lifecycle hardening tests + Sky touch design research. SOFT THROTTLE.**
  `tests/test_controller_kinematics.gd`: `_test_trail_lifecycle()` (8 assertions):
  start_run() clears trail_history + sets _recording=true; level_complete() sets
  _recording=false; reset_run() clears trail_history; _on_player_respawned() with empty
  _current_trail leaves history unchanged AND resets _sample_accum; first non-empty
  respawn grows history to 1 without pop_back (below MAX_TRAIL_DEPTH); _current_trail
  cleared after archive. 1100→1108 assertions. Side quest:
  `docs/research/sky_touch_design.md` — Sky: Children of the Light gesture/input model.
  Direct-manipulation input, tap-debt analysis, two-touch ceiling validated for current
  air-dash design, 15% dead zone confirmed, affordance-over-text principle reinforced,
  Gate 2 tap-to-move audience-broadening option documented. Closes open INDEX.md item.
  INDEX.md updated with new entry.

- 2026-05-15 — iter 93. **PatrolSentry hardening tests + Kenney kit material-override research. SOFT THROTTLE.**
  `tests/test_controller_kinematics.gd`: `_test_sentry_param_dispatch` (11 assertions: 4
  default-export guards, 3 float-property dispatch, 2 bool dispatch, 1 unknown-param no-op) +
  `_test_sentry_initial_state` (5 assertions: _offset=0, _dir=+1, _waiting=false, _wait_t=0,
  _bob_t=0). 1085→1100. Both tests use PatrolSentry.new() without scene tree — exercises
  declaration defaults and direct dispatch without physics or DevMenu. Side quest:
  `docs/research/kenney_kit_material_override.md` — two-class rule (body → mat_concrete_dark,
  emissive detail → zone palette), PatrolSentry reference implementation, per-zone Threshold
  prop advice, Poly Haven texture-pass prereqs, 5 implications. INDEX.md updated (new
  "Gate 1 — art direction and kit dressing" section). 7 iterations since last human direction.

- 2026-05-15 — iter 92. **Ambient audio infrastructure. SOFT THROTTLE.**
  `audio.gd`: `BUS_AMBIENT` constant + `_ensure_bus(BUS_AMBIENT, BUS_MASTER)`.
  `_setup_ambient_players()` creates `_ambient_global_player` + `_ambient_zone2_player`
  (AudioStreamPlayer nodes, fan layer at −4 dB). `_load_ambient_streams()` loads
  `res://assets/audio/ambient/ambient_global.ogg` and `ambient_zone2.ogg` (null-safe;
  AudioStreamOggVorbis.loop = true set programmatically). `set_ambient_zone(zone_id)`:
  zones 1+3 play global only; zone 2 adds fan layer via `_resume_layer()`.
  `_on_audio_param_changed`: `&"ambient_volume"` arm sets Ambient bus dB.
  `threshold.gd`: `Audio.set_ambient_zone(1)` in `_ready()`; `Audio.set_ambient_zone(zone_id)`
  in `_on_zone_body_entered()`. Dev menu: "Ambient volume ×" slider prepended to Juice →
  Audio section in `_build_audio_sfx_tuning()`. `assets/audio/ambient/README.txt` with
  manual-download instructions. `assets/ASSETS.md`: two PENDING entries (B1 AlaskaRobotics
  CC0 #221570 + B2 IanStarGem CC0 #271096). JUICE.md: ambient prototype entries added.
  11 unit tests (1074→1085): BUS_AMBIENT constant, null stream defaults, method API,
  linear_to_db unity/attenuation, zone-2 routing condition, asset path convention.
  Side quest: `docs/research/alto_odyssey_touch_design.md` — input economy vocabulary,
  camera tax model, 6 Void implications (jump button size, auto-framing priority,
  variable-jump = Alto's hold analogy). INDEX.md updated. On-device pending — ambient
  files need manual freesound download before first playtest.

- 2026-05-15 — iter 91. **Kenney Sci-Fi Sounds SFX wired. SOFT THROTTLE.**
  `audio.gd`: `_load_sfx_streams()` (called from `_ready()`) loads 5 CC0 OGG clips:
  `jump.ogg` (laserSmall_000), `land_light.ogg` (impactMetal_000), `land_heavy.ogg`
  (impactMetal_004), `collect_shard.ogg` (forceField_003), `respawn_start.ogg` (laserLarge_000).
  `load()` returns null gracefully if not yet imported (safe no-op path preserved).
  `dev_menu.gd`: `audio_param_changed(param, value: float)` signal.
  `dev_menu_overlay.gd`: "Audio — SFX" sub-section in Juice → "SFX volume ×" slider (0–2, default 1.0).
  `audio.gd::_on_audio_param_changed`: `&"sfx_volume"` arm sets SFX_Player bus dB.
  `assets/ASSETS.md`: Kenney Sci-Fi Sounds CC0 entry. `docs/JUICE.md`: sound events stub→prototype.
  8 unit tests (1066→1074). On-device pending. 5 iterations since 2026-05-15 direction session.

- 2026-05-15 — iter 90. **PatrolSentry enemy archetype (Gate 1 requirement).**
  `scripts/enemies/patrol_sentry.gd` (PatrolSentry, extends AnimatableBody3D): slow linear
  patrol zero-AI enemy. State: `_offset` (signed displacement from origin along `patrol_axis`),
  `_dir` (+1/-1), `_waiting` (bool). `_tick_patrol(delta)` clamps to ±half_distance, flips
  direction + sets `_waiting` at endpoints. `_physics_process` computes
  `position = _origin + ax * _offset + UP * bob_y`. Visual: programmatic BoxMesh (0.8 m cube,
  dark grey) + amber emissive eye strip on +Z face. Kill zone: Area3D with `hazard_body.gd`
  script, BoxShape half=0.50 m (> physics body 0.40 m — fires before physics wall).
  `dev_menu.gd`: `sentry_param_changed(param: StringName, value: Variant)` signal added.
  `dev_menu_overlay.gd`: "Sentry — Tuning" section in Level with speed/distance/wait sliders
  + bob toggle. `threshold.gd`: `_spawn_sentries()` places one sentry at Zone 1 plaza
  (0, 1.2, 16) patrolling X-axis 8 m, speed 2.5, wait 0.5. 11 unit tests (1055 → 1066).
  JUICE.md: Sentry bob logged prototype. DECISIONS.md: archetype choice documented.
  On-device pending — speed/distance/bob amplitude all tunable from dev menu.

- 2026-05-15 — iter 88. **Kenney asset acquisition — chick GLB wired as Stray.**
  Downloaded Cube Pets v1.0 + Factory Kit v3.0 + Space Station Kit (all CC0). `animal-chick.glb`
  copied to `assets/art/character/`; wired in `player.tscn` as a PackedScene instance under
  `Visual/Chick` (scale=0.8, y=0). Body (CapsuleMesh) + Accent (BoxMesh) sub_resources removed.
  `player.gd`: `_body_mesh` onready changed to `get_node_or_null("Visual/Body") as MeshInstance3D`
  (null-safe; emission flash inert until chick sub-mesh wired). 143 Factory Kit GLBs + 97 Space
  Station Kit GLBs copied to `assets/art/architecture/`. `assets/ASSETS.md`: three CC0 entries.
  No unit test changes (no logic change). On-device pending — chick scale 0.8 and pivot TBD.
- 2026-05-14 — iter 85. **Depth perception research + `_tick_footstep_dust` refactor. HARD THROTTLE.**
  `player.gd`: `_tick_footstep_dust(on_floor, just_landed, delta)` extracted from `_tick_timers`
  (41 → 33 lines). 10 new assertions `_test_footstep_dust_state_machine` (1020 → 1030).
  Research: `docs/research/depth_perception_cues.md` — 7 Void implications: blob shadow tuning is
  Gate 1 P0; landing-target predictor is Gate 1 enhancement gated on device feedback; platform edge
  contrast is texture-pass work; camera pitch <20° degrades depth (soft recenter boost suggestion);
  zone atmosphere protects altitude legibility; do not reduce fog. INDEX.md updated.
- 2026-05-14 — iter 84. **Footstep dust + land impact particles.**
  `_spawn_footstep_dust()` (4-line ImmediateMesh, TAU/4 spread, warm grey, 0.10 s fade, throttled by
  `_footstep_dust_interval=0.15`); `_spawn_land_impact(impact)` (6-line ImmediateMesh, TAU/6 spread,
  length=0.08+impact×0.22, upward kick=impact×0.12, 0.03 s hold + 0.18 s fade).
  `_apply_landing_effects(impact)` extracted from `_tick_timers` to keep it ≤ 40 lines.
  Dev menu "Particles — Tuning → Footstep interval (s)" slider. 18 unit tests (1002→1020).
  JUICE.md: both promoted idea→prototype. On-device pending.
- 2026-05-14 — iter 82. **Hardening unit tests: ledge magnet impulse, arc assist budget, shake strongest-wins.**
  `tests/test_controller_kinematics.gd`: three new test functions —
  `_test_ledge_magnet_impulse_formula` (7 assertions: dist=0→impulse=0, dist=radius→full strength,
  beyond-radius cap, linear proportionality, monotone, Assisted spot checks at half/full radius);
  `_test_arc_assist_per_frame_budget` (8 assertions: Limit A = 0.02 m/frame, Limit B = 0.025 m/frame
  at Assisted defaults, effective = min(A,B)=Limit A, budget = 1.5-accumulated, budget=0→clamped-to-zero,
  offset≥max→skipped, offset<max→fires);
  `_test_screen_shake_strongest_wins` (7 assertions: stronger replaces weaker, weaker discarded,
  equal discarded, decay formula, decay×duration=magnitude, zero-duration guard, distinct frequencies).
  22 new assertions (971 → 993).
  Side: Threshold scene verified as using MeshInstance3D (not CSGBox3D) — CSG baked-lighting
  blocker from iter 73 research note is resolved; PLAN.md item 8 prereq note updated.
- 2026-05-14 — iter 81. **Screen shake system.** `game.gd`: `screen_shake_requested(magnitude, duration, freq)` signal. `camera_rig.gd`: `_apply_shake(delta)` (sinusoidal yaw+pitch after look_at, no movement-direction bleed), `_on_screen_shake_requested` (strongest wins), `shake_intensity_scale` export + `&"shake_intensity"` dev-menu arm. `player.gd`: land shake (impact ≥ 0.25 → 0.011×impact rad, 0.13 s, 20 Hz) + death shake (0.022 rad, 0.20 s, 26 Hz). Dev menu: "Screen Shake — Tuning" → "Intensity ×" slider. JUICE.md: hard-land + death/respawn promoted to prototype; directional hazard-hit deferred. 8 unit tests (963 → 971). On-device pending.
- 2026-05-14 — iter 80. **Audio skeleton upgrade + wall normal debug viz.**
  `scripts/autoload/audio.gd`: upgraded from stub. `_ensure_bus()` creates SFX_Player/SFX_World/Music
  buses under Master at runtime via `AudioServer.add_bus()`. `_apply_sound_layers(enabled)` mutes
  SFX_Player + SFX_World when `sound_layers` juice toggle is OFF (was no-op). `play_sfx(null)` is a
  safe no-op. Four event dispatch stubs: `on_jump()`, `on_land(impact)`, `on_collect_shard()`,
  `on_respawn_start()`. `LAND_HEAVY_THRESHOLD = 0.25` constant (light/heavy split). Integration:
  `player.gd` calls `Audio.on_jump()` in `_try_jump()` (both floor + air paths), `Audio.on_land(impact)`
  in `_tick_timers()` (just_landed frame, guarded by `not _is_rebooting`), `Audio.on_respawn_start()`
  in `respawn()`. `data_shard.gd` calls `Audio.on_collect_shard()` in `_collect()`. All calls guarded
  by `has_node("/root/Audio")` for test safety. Wall normal debug viz: `&"wall_normal": false` added to
  `debug_viz_state`; "Wall normal" checkbox in Debug viz section (dev_menu_overlay.gd); `_draw_wall_normal`
  (magenta, fires when `is_on_wall()`) + `_C_WALL_NORMAL` constant added to `player_debug_draw.gd`.
  `_refresh_viz_active()` includes new key. Research: `docs/research/audio_placeholder.md` — 4 placeholder
  options surveyed, silence recommended, AudioStreamRandomizer pattern for post-direction implementation.
  JUICE.md sound-layers section updated. INDEX.md updated. 15 unit tests (`_test_audio_skeleton` 12
  + `_test_wall_normal_viz_key` 3). 948 → 963 assertions.
- 2026-05-14 — iter 79. **Free-camera mode + Snappy reboot_duration tuning.**
  `camera_rig.gd`: `free_cam_speed` export, `_free_cam`/`_free_cam_yaw`/`_free_cam_pitch` state,
  `_on_debug_viz_changed` (seeds YXZ Euler from `_camera.global_basis` on enable; resets `_initialized`
  on disable), `_process_free_cam` (WASD+QE fly, Shift 3×, Basis.from_euler YXZ), `_unhandled_input`
  (RMB+mouse look, ±PI×0.45 pitch clamp). `dev_menu.gd`: `&"free_cam": false` added to `debug_viz_state`.
  `dev_menu_overlay.gd`: "Free cam (WASD+QE, RMB look)" checkbox in Level section. Side quest:
  `snappy.tres`: `reboot_duration = 0.33` (was 0.5; research: ≤ 0.35 s for precision feel;
  Floaty/Assisted/Momentum stay 0.5 s). 16 unit tests (932 → 948).
- 2026-05-14 — iter 78. **Assisted Phase 2 — ledge magnetism + arc assist.** 3 new `ControllerProfile`
  params + `_attract_to_ledge()` + `_apply_arc_assist()` in `player.gd`. `assisted.tres` defaults:
  `ledge_magnet_radius=0.20`, `ledge_magnet_strength=1.0`, `arc_assist_max=0.40`. 3 dev-menu sliders
  (Controller → Assist). 10 unit tests (922 → 932). On-device pending for tuning; edge-snap deferred.
  See `docs/research/assist_mechanics.md` for the design basis.
- 2026-05-14 — Human direction session. **Kenney asset coverage + camera pitch-up auto-correct fight fix. THROTTLE RESET.**
  Verdicts on iter-77 open questions: A (Threshold redesign) feels a lot better; B (asset picks) → add Kenney coverage;
  C (air-dash mode) and E (texture-pass timing) → TBD; D (camera pitch 70°) → ceiling correct, but "auto-correction
  fights when pitching up and holding" bug surfaced.
  `scripts/camera/camera_rig.gd::_apply_drag_input`: dropped the `cos(elev)` factor on XZ. Previously the drag wrote a
  spherical pose (`effective_distance * cos_e * sin(theta)` / `* cos(theta)` on XZ) while `_compute_ground_camera_pos`
  enforces full-`effective_distance` XZ. At 70° pitch the drag put XZ at ~0.34 × distance, then the ground branch eased
  the camera back out to full XZ over ~0.5 s — the visible "fight" after the player released the swipe. Drag now uses the
  same cylindrical parametrization. Updated docstring explains the prior spherical-vs-cylindrical mismatch alongside the
  earlier asin-derived-phi mismatch (iter 22 fix).
  `tests/test_controller_kinematics.gd::_test_tripod_drag_orbit`: rewritten to mirror the cylindrical formula. New
  invariants: XZ radius == distance regardless of pitch; pure yaw drag preserves XZ radius (not 3D radius — the prior
  "orbit on sphere" assertion stayed green over buggy code); drag XZ at 70° matches ground-branch XZ exactly;
  drag Y at 70° matches ground-branch Y on grounded frames. Lower/upper elev clamp and `_pitch_rad ≤ 0` invariants
  preserved.
  `docs/ASSET_OPTIONS.md`: seven new Kenney candidates added (CC0, all): A5 Mini Characters, A6 Mini Arena, A7 Blocky
  Characters (Slot A — none ship a CC0 chibi robot, so A1 Quaternius still wins); B5 Sci-Fi Sounds (Slot B — Kenney
  doesn't ship long ambient beds, so B5 is positioned as SFX-layer complement over B1+B2); C6 Prototype Textures,
  C7 Modular Space Kit, C8 Factory Kit (Slot C — C8 flagged as highest-value Kenney addition for Zone 2/3 industrial
  dressing). Decision table gained a Kenney-coverage column.
  `README.md`: throttle reset banner (🔴 HARD → 🟢 RESET), open-questions section rewritten to reflect verdicts, new
  iteration entry appended.
  `docs/PLAN.md`: active-iteration banner updated, Blocked section rewritten to reflect C/E TBD status and the new
  Kenney coverage.

- 2026-05-14 — Iteration 77. **Refactor `_run_reboot_effect` — extract `_play_death_squish` + `_play_reboot_grow`. HARD throttle.**
  `scripts/player/player.gd`: extracted two helpers from `_run_reboot_effect` (41→32 lines).
  `_play_death_squish(duration)` — beat-1 crush now tracked via `_squash_tween` (was untracked local var; consistent
  with `_play_land_squash` / `_play_jump_stretch` / `_play_dash_stretch`).
  `_play_reboot_grow(duration)` — beat-3 spawn-in scale animation, also tracked via `_squash_tween`; handles
  juice-off path (`_visual.scale = Vector3.ONE`) in one place.
  Both helpers are 7–13 lines, well under the 40-line limit.
  `tests/test_controller_kinematics.gd`: `_test_respawn_params` gains 2 tween-containment assertions —
  death-squish (0.08) < dark-frame await (0.12) and reboot-grow (0.28) < power-on await (0.35). 920 → 922.
  `docs/JUICE.md`: "Death squish" entry updated to reference `_play_death_squish` and `_play_reboot_grow`.
  Refactor backlog clearance: `_build_ui` and `_make_slider` measured at 38–39 lines each — not actually
  over limit; removed from backlog.

- 2026-05-14 — Iteration 76. **Hardening unit tests: ghost trail fix semantics + respawn timer clearing. HARD throttle.**
  `tests/test_controller_kinematics.gd`: two new test functions — `_test_ghost_trail_disable_and_resize_semantics`
  (8 assertions: blank-before-resize leaves 450 slots unzeroed, blank-after covers all, shrink discards old
  slots cleanly, disabled-path per-frame cost 18,000 vs 60 writes/sec, one-time disable blank for hygiene) +
  `_test_respawn_input_timer_clearing` (8 assertions: buffer/coyote/air-jumps/dash-charges/dash-timer/is-dashing
  all cleared on death, double-respawn guard blocks re-entry, _physics_process blocked during reboot animation).
  16 new assertions (904 → 920). Refactor backlog: `_run_reboot_effect` 45 lines, `_build_ui` ~41 lines,
  `_make_slider` ~43 lines — all marginal overruns, defer.

- 2026-05-14 — Iteration 75. **Hardening unit tests: zone env bounds + ramp lifecycle. HARD throttle.**
  `tests/test_controller_kinematics.gd`: two new test functions — `_test_zone_env_bounds_and_disabled`
  (10 assertions: null-sentinel at envs[0], zone_id=4 OOB guard, disabled-mode fallback always uses
  zone1_env, enabled-path slot routing for zone_ids 1/2); `_test_respawn_ramp_speed_reset` (7
  assertions: initial = max_speed, ramp-up over 2 s, respawn reset, decay-frame decrease, decay
  floor = max_speed, landing does not reset ramp, full decay ≥ 1.5 s). 17 new assertions (887 → 904).
  README + PLAN.md updated to 🔴 HARD throttle with 5 concrete next-direction suggestions.

- 2026-05-14 — Iteration 74. **Camera occlusion dev-menu tunables + TBDR GPU research.**
  `scripts/camera/camera_rig.gd`: 4 new match arms in `_on_camera_param_changed`
  (`occlusion_probe_radius`, `pull_in_smoothing`, `ease_out_smoothing`,
  `occlusion_release_delay`); duplicate `_occlude()` docstring removed.
  `tools/dev_menu/dev_menu_overlay.gd`: "Camera — Occlusion" sub-section with 4 sliders
  (Probe radius / Pull-in rate / Ease-out rate / Latch delay s) inserted between the main
  Camera section and Camera — Tuning. Unit tests: `_test_camera_occlusion_defaults`
  (8 assertions, 879 → 887). Side quest: `docs/research/tbdr_mobile_gpu.md` written;
  `docs/research/INDEX.md` entry added (last open research suggestion resolved).

- 2026-05-14 — Iteration 73. **Baked lighting research + ghost trail renderer bug fixes.**
  `docs/research/baked_lighting.md`: Godot 4 LightmapGI for Mobile renderer — setup workflow,
  settings table, Mobile VRAM budget (2048×2048 ASTC ~1.1 MB), critical zone-atmosphere conflict
  (WorldEnvironment swap incompatible with naive single bake; Option A = real-time only at Gate 1;
  Option C = Env Disabled bake for Gate 1+), CSG geometry blocker (all Threshold geometry is
  CSGBox3D — must convert to MeshInstance3D before any bake, pairs with concrete-kit art pass),
  moving-object exclusion table, performance delta estimate, 7-item implementation checklist.
  `docs/research/INDEX.md`: entry added under Performance & rendering.
  `scripts/levels/ghost_trail_renderer.gd`: two bug fixes — (1) `_on_ghost_trail_param` now
  blanks AFTER resize (was before; new instances above old count initialised to non-transparent
  default — one-frame white-sphere flash on window enlargement); (2) `_process` disabled path
  uses `_mmesh.visible = false` instead of `_blank_from(0)` per frame (eliminates 300
  set_instance_color writes × 60 fps = 18,000 GPU buffer writes/sec while ghost trails are off).
  Unit tests: `_test_ghost_trail_resize_math` (5 assertions, 874 → 879).

- 2026-05-13 — Iteration 72. **Ghost trail recording + MultiMesh renderer.**
  `game.gd`: `trail_history: Array[PackedVector3Array]` + `_current_trail` sampled at 30 Hz
  in `_physics_process`; `_on_player_respawned()` archives trail on respawn (push_front +
  pop_back if >5); `start_run()` / `reset_run()` manage `_recording` + clear state.
  `scripts/levels/ghost_trail_renderer.gd` (new): MultiMeshInstance3D; 5×60=300 instances
  (1 draw call); alpha-by-recency (attempt: 0.35×0.55^idx; point: oldest→newest linear);
  responds to `ghost_trails` juice toggle and `visible_window_s` param (resizes instance_count
  on slider change). Dev menu: `ghost_trails` toggle added to juice_state (default OFF),
  `ghost_trail_param_changed` signal added; "Ghost Trail — Tuning" sub-section with
  "Trail window (s)" slider 1–5 s. `threshold.tscn`: GhostTrailRenderer node added (load_steps
  79→80). 10 unit tests (864→874): SAMPLE_INTERVAL precision, 60 fps frame accumulation,
  MAX_TRAIL_LEN cap, archive depth cap, push_front ordering, alpha formula.
  Side quest: `smb3d.md` implication #1 corrected (blob shadow was iter 31, not "this iter").
  On-device pending — enable ghost_trails toggle after ≥3 deaths for meaningful first read.

- 2026-05-13 — Iteration 71. **Asset options document + pre-jump anticipation squish.**
  `docs/ASSET_OPTIONS.md`: 4 Stray-mesh candidates (A1 Quaternius LowPoly Robot CC0 FBX
  14-anim recommended), 4 ambient-audio candidates (B1 AlaskaRobotics spacecraft hum
  CC0 17.8 s loop + B2 IanStarGem industrial fans CC0 6.7 s loop recommended), 5
  concrete-kit candidates (C2 Poly Haven CC0 PBR + Godot add-on recommended). Fidelity
  check vs brutalist palette included for each. `PLAN.md` Blocked item updated: doc is
  ready for human review.
  `scripts/player/player.gd`: `_play_jump_stretch` gains 0.04 s anticipation coil phase
  (coil_y=1−0.18×scale, coil_xz=1+0.08×scale, EASE_IN TRANS_SINE) prepended before the
  existing stretch. `docs/JUICE.md`: Pre-jump anticipation promoted from `idea` to
  `prototype`. Unit tests: `_test_jump_anticipation_squish_math` (10 assertions, 854→864).

- 2026-05-13 — Iteration 70. **Zone 2 emissive surfaces + orphaned sub-resource cleanup.**
  (See iter 70 README entry for detail.)

- 2026-05-13 — Iteration 69. **Threshold zone atmosphere.**
  `threshold.tscn`: six new sub_resources — `Env_Z1` (ambient warm grey 0.35/0.30/0.22,
  fog_density 0.012), `Env_Z2` (cold blue 0.22/0.26/0.38, fog_density 0.015), `Env_Z3`
  (amber 0.30/0.22/0.14, fog_density 0.008); `Shape_Zone1/2/3Trig` BoxShape3D. Three
  `Area3D` Zone1/2/3Trigger nodes (collision_mask=2, monitorable=false) added. Three
  Zone 1 sodium-yellow OmniLights (Z1Light1/2/3, Color(1.0,0.85,0.55), shadow=off,
  y=5–6.5 m). Root node exports `zone1/2/3_env` assigned from sub_resources.
  `threshold.gd`: `zone1/2/3_env: Environment` exports; `_world_env` onready; `_active_zone`
  state; `_connect_zone_triggers` wires `body_entered.bind(id)` for each trigger;
  `_apply_zone_env` swaps `_world_env.environment`; `DevMenu.atmosphere_param_changed`
  handler for `zone_atmo_enabled` toggle.
  `dev_menu.gd`: `atmosphere_param_changed` signal added.
  `dev_menu_overlay.gd`: `_build_atmosphere_section` — "Zone Atmosphere" sub-section
  with "Zone atmo" toggle in the Level panel.
  Unit tests: `_test_zone_atmosphere_logic` (8 assertions, 846 → 854): Z1 ambient R>G>B
  warmth; Z2 B>R cold dominance; Z3 R>G>B amber; fog density Z3<Z1<Z2; trigger coverage
  for spawn / Zone2 floor / G1+Terminal.
  On-device pending — fog density and ambient energy need feel tuning on device.

- 2026-05-13 — Iteration 68. **Momentum profile speed ramp.**
  `controller_profile.gd`: two new `@export_range` properties in the Movement category —
  `speed_ramp_rate: float = 0.0` (m/s per second; 0 = disabled, backwards-compatible for all
  profiles) and `ramp_max_speed: float = 18.0` (ceiling for the ramp). `player.gd`: new
  `_ramp_speed: float` state var; `_apply_profile_to_body()` initialises it to `profile.max_speed`;
  `respawn()` resets it to `profile.max_speed`; `_apply_horizontal()` ramps it up toward
  `ramp_max_speed` at `speed_ramp_rate * delta` per frame when `move_dir.length() > 0.01`, and
  decays back at the same rate when input is absent. `effective_max` substitutes for
  `profile.max_speed` in `target_h` when the ramp is enabled. `momentum.tres` gains
  `speed_ramp_rate = 4.0` (≈1.75 s to reach top speed from rest) and `ramp_max_speed = 18.0`.
  Dev menu: "Ramp rate" (0–20, step 0.5) and "Ramp top speed" (8–30, step 0.5) added to
  `_build_controller_movement`; both are `_profile_sliders` so they bulk-sync on profile swap.
  Unit tests: `_test_speed_ramp_logic` (10 assertions, 836 → 846): rate=0 default; ramp-up
  formula after 1 s; ramp-up clamp at ramp_max; ramp-down after 1 s; ramp-down floor; monotone
  increase; Momentum rate > 0; Momentum ramp_max > max_speed; Snappy rate = 0; Floaty rate = 0.
  Side quest: `docs/research/zone_atmosphere.md` — zone-distinct atmosphere on Godot 4 Mobile
  renderer; WorldEnvironment swap technique; emissive-surface principle (INSIDE); 12-light budget;
  concrete palette for Threshold Zones 1/2/3; baked-lighting plan. INDEX.md updated.
  On-device pending — Momentum now meaningfully distinct from Snappy/Floaty.

- 2026-05-13 — Iteration 67. **Air-dash buffer-and-discard camera variant.**
  `touch_overlay.gd`: `dash_buffer_camera` export bool (default false); `_dash_drag_buffer`
  per-touch accumulator; `_tick_dash_gesture(index, pos, delta) → bool` (36 lines, gesture
  state machine); `_flush_dash_buffer(index, delta) → bool` (9 lines, flush/discard helper).
  `_handle_drag` KIND_DRAG case extracted into these helpers (now 31 lines). `_on_touch_param`
  gains three new arms: `dash_px_threshold`, `dash_time_threshold`, `dash_buffer_camera`.
  `dev_menu_overlay.gd::_build_touch_section` grows → extracted `_build_dash_gesture_controls`
  (15 lines); Touch section exposes "Dash px threshold" / "Dash window (s)" / "Buffer dash
  cam" toggle. Tests: `_test_dash_buffer_camera_logic` (10 assertions, 826 → 836).
  DECISIONS.md: new ADR. On-device pending — both modes ready to compare in one device session.

- 2026-05-14 — Human direction session. **Threshold Spyro-style redesign + Snappy tuning pass + air-dash UX rework + camera/dev-menu/level-bug fixes.**
  Snappy profile retuned: `max_speed` 6.0→5.0, `ground_deceleration` 90→40, `jump_velocity` 11.5→12.0,
  `air_jumps` 0→1, `air_jump_velocity_multiplier` 0.9 (explicit), `gravity_after_apex` 75→65, `fall_kill_y` already −35.
  Threshold redesigned: Zone 1 corridor → open plaza (24×36 floor, RubbleA/B + PillarLowA/Tall + ShelfA/B +
  Lookout, three routes), Zone 2 corridor → maintenance yard (floor 2 m→16 m wide, Z2StepLeft/Right + Z2LedgeLeft/Right
  perimeter route), Zone 3 lateral platforms (Z3SidePlatA off G2, Z3SidePlatB off G3). 4 shards now scattered
  (Zone 1 Lookout, Zone 2 mid-air, Zone 3 ShardLedge, Beat 4 K2 side). Ceilings + corridor walls removed.
  Camera: `pitch_max_degrees` 55°→70°, pitch axis inverted (FPS convention), `_apply_drag_input` rewritten
  to use stored `_pitch_rad` + match `_compute_ground_camera_pos`'s `sin(elev)*dist + aim_height` decomposition
  (fixes slow-swipe auto-raise that was the asin-from-position derivation mismatch).
  Air-dash UX: dedicated dash button removed, gesture is hold-jump-then-swipe in right zone (arm lazily on
  first frame jump_held is true; direction = TouchInput.move_vector; window slides forward on expiry; one-shot
  per touch). Dev menu: new "Load Level" section with Threshold/Feel Lab buttons (`change_scene_to_file`);
  scroll-on-buttons fixed (`MOUSE_FILTER_PASS` on `_make_button`/`_make_toggle`). Bugs: shard collection
  (`collision_mask=2` matches player layer); IndustrialPress `Phase((_phase + 1) % 4)` → `((_phase + 1) % 4) as Phase`
  (Godot 4 doesn't call enums as functions). Threshold set as `run/main_scene`.

- 2026-05-13 — Iteration 66. **Data shard gem geometry + light parameter tests (hard throttle hardening).**
  `_test_data_shard_gem_vertices` (13 assertions, 807 → 820): mirrors the vertex array of
  `DataShard._build_gem_mesh()` — top apex y 0.28, bottom y -0.22, intentional top>bottom asymmetry,
  all four equatorial vertices y=0 (tested per-vertex), axis-aligned square ring (not diagonal),
  equatorial radius 0.20 m, 6 vertices, 8 triangles, emission_energy_multiplier 3.2.
  Side quest: `_test_data_shard_light_params` (6 assertions, 820 → 826): OmniLight3D cyan channel
  checks (G>R, B>R), light_energy 1.4, omni_range 4.5 m, collect-pulse rise < fall (0.05 s < 0.30 s),
  peak pulse 5× default. Throttle: HARD (15).

- 2026-05-13 — Iteration 65. **Air-dash state-machine tests + game timer accumulation tests (hard throttle hardening).**
  `_test_air_dash_state_machine` (14 assertions, 786 → 800): fills the state-transition gap left by
  `_test_air_dash_logic`. Covers re-entry guard compound (blocking and passing cases), timer-decrement
  formula (3 cases), timer-expiry → `_is_dashing` cleared (2 cases), landing vs respawn clear semantics
  (`charges=1` vs `charges=0`), Y-velocity zeroing at trigger, double fallback to `Vector3.FORWARD`, and
  default duration expiry within 15 frames.
  Side quest: `_test_game_timer_accumulation` (7 assertions, 800 → 807): first coverage of
  `game.gd::_process` timer — not-running guard, single-frame delta, 10-frame accumulation,
  `level_complete()` stop, `start_run()` reset, 60-frame ≈ 1.0 s invariant. Throttle: HARD (14).

- 2026-05-13 — Iteration 64. **`results_panel.gd::_build_ui()` refactor + IndustrialPress formula tests (hard throttle hardening).**
  `results_panel.gd::_build_ui()` was 41 lines (1 over threshold). Extracted three helpers:
  `_build_overlay_root()` (9 lines — root Control + backdrop ColorRect), `_build_center_panel(root)` (12 lines —
  CenterContainer + VBox + stat rows), `_build_replay_button(panel)` (8 lines — gap spacer + REPLAY Button).
  `_build_ui` is now 5 lines. No behaviour change.
  Side quest: `_test_industrial_press_position_formula` (17 assertions, 769 → 786): two new helpers
  `_ip_y(phase, p, origin_y, stroke_depth)` and `_ip_emissive(phase, p)` mirror `IndustrialPress._target_y()`
  and `_update_emissive()`. Coverage: all four phases (DORMANT/WINDUP/STROKE/REBOUND) at p=0, p=0.5, p=1;
  continuity invariant (stroke(p=1) == rebound(p=0) — no position pop at phase boundary); emissive energy
  per phase. Throttle: HARD (13).

- 2026-05-13 — Iteration 63. **`_conditional_fall_offset` regime tests + hint-distance blend tests (hard throttle hardening).**
  `_test_conditional_fall_offset_regimes` (18 assertions): new helper `_cfo_mirror` mirrors
  `camera_rig.gd::_conditional_fall_offset`. Tests cover `_vertical_pull_offset` sanity (zero/rising→0,
  falling→negative, concrete -0.072 m), `apex_h==0` bypass, above-apex tracking regime, below-floor
  tracking regime, held-band suppression (returns 0.0 during normal jumps), both boundary cases (strictly>
  and strictly<), linearity (scales with vertical_pull and fall speed).
  `_test_hint_distance_blend` (8 assertions): exponential lerp in `_update_hint_distance` at rate 3/sec;
  tests no-hint zero-hold, first-frame concrete value, 1-sec convergence (>95%), monotone/no-overshoot
  across 120 frames, and rate comparison (3 < 6 confirms hints blend slower than tier-change smoothing).
  Total: 743 → 769 assertions. Throttle: HARD (12).

- 2026-05-13 — Iteration 62. **`camera_rig.gd::_process` method-size refactor (hard throttle hardening).**
  `_process` was 137 lines (far over the 40-line threshold). Extracted 8 private helpers:
  `_update_hint_distance` (returns effective_distance), `_build_effective_target` (Vector3 with ratchet Y),
  `_try_initialize` (one-time camera setup), `_update_ground_camera` (3-line pipeline dispatcher),
  `_compute_ground_camera_pos` (XZ distance + Y + fall offset → Vector3), `_occlude_and_latch`
  (probe + hysteresis latch → desired pos), `_apply_position_smooth` (asymmetric lerp),
  `_publish_camera_yaw` (yaw broadcast to player). Also split `_occlude` (50 lines) into `_occlude`
  (10 lines, result packaging) + `_probe_hit_dist` (27 lines, sphere/ray dispatch). All 23 functions
  in camera_rig.gd are now under 40 lines. Pure structural refactor — no behaviour change.
  Side quest: `_test_ground_camera_y_formula` (8 assertions, 735 → 743) — pure-math mirror of
  `_compute_ground_camera_pos` Y formula. Throttle: HARD (11).

- 2026-05-13 — Iteration 61. **RotatingHazard + CameraHint unit tests (hard throttle hardening).**
  Two new test groups in `tests/test_controller_kinematics.gd` (718 → 735 assertions):
  `_test_rotating_hazard_math` (12 assertions): pure-math mirrors of `angle = fmod(_elapsed /
  period_seconds, 1.0) * TAU` — tests angle at t=0/half/full/1.25 periods, periodicity (t and
  t+7×period agree), angle always in [0, TAU), axis normalization (UP + diagonal), default period
  4.0 s within export range, Basis column-length invariant at angle=0 and TAU.
  `_test_camera_hint_defaults` (5 assertions): `CameraHint.new()` — `pull_back_amount` defaults
  0.0, `blend_time` defaults 0.5 s, both non-negative/positive guards, `"camera_hints"` StringName
  contract matching `camera_rig.gd::_get_active_hint_extra()` group query.
  New const: `CH := preload("res://scripts/levels/camera_hint.gd")`. Throttle: HARD (10).

- 2026-05-13 — Iteration 60. **`_build_level_section` refactor (hard throttle hardening).**
  `dev_menu_overlay.gd`: extracted `_build_feel_lab_teleports` (20 lines) and
  `_build_threshold_teleports` (25 lines) from `_build_level_section` (was 54 lines, now 16).
  All methods in the file now under 40 lines. No behaviour change. 718 unit tests unchanged.
  README and PLAN updated with HARD throttle alert + 5 suggested human directions.

- 2026-05-13 — Iteration 59. **Industrial press implementation.** `scripts/levels/industrial_press.gd`
  (new): extends AnimatableBody3D, class IndustrialPress. Four-beat cycle (dormant/windup/stroke/rebound)
  via `_phase`/`_phase_t` state machine in `_physics_process`. Exports: `stroke_depth` 2.5 m,
  `dormant_time` 1.5 s, `windup_time` 0.8 s, `stroke_time` 0.18 s, `rebound_time` 0.5 s.
  Emissive amber strip (`Color(1.0, 0.72, 0.12)`) animates energy 0.3→2.5→0.3 through cycle.
  `DevMenu.press_param_changed` signal + `_on_press_param_changed` live-tunes all params.
  `threshold.tscn`: IndustrialPress now uses `id=15_ip` (was `7_movp`); adds EmissiveStrip
  MeshInstance3D at local (0,−2.1,0) with `Mesh_PressStrip` (14×0.2×5 m); adds KillZone Area3D
  at (0,−2.25,0) with `HazardBody` script + KillShape BoxShape3D (13.7×0.5×4.7 m, inset 0.15 m).
  `dev_menu.gd`: new `press_param_changed` signal. `dev_menu_overlay.gd`: `_build_press_section()`
  (extracted helper, 5 sliders); `_build_level_section()` gains "↺ Reload level" button and
  "→ Press zone" teleport at (8,−10,93). 13 unit tests in `_test_industrial_press_timing`
  (705 → 718 assertions). JUICE.md: new "Hazard juice" section, press emissive → prototype.
  DECISIONS.md: IndustrialPress vs moving_platform ADR. On-device pending. Par-route routing
  (force player through press) blocked on device feel — press kills but is bypassable until
  the level geometry is tuned on device. Throttle: 8 (soft).

- 2026-05-13 — Iteration 58. **Gate 1 script unit tests + machinery hazard research.**
  Three new test groups in `tests/test_controller_kinematics.gd` (679 → 705 assertions):
  `_test_results_panel_formatting` (11 assertions): `_fmt_time()` format at 6 boundary values,
  par-beat/fail colour contract, shard count string, panel-width constant ≥ 480 px;
  `_test_win_state_one_shot_guard` (6 assertions): `WinState._triggered` default, set,
  guard-blocks logic; `CheckPoint._activated` default, `reset()` clears, locked-after-set;
  `_test_data_shard_state_machine` (9 assertions): `_collected` default false,
  `_mesh_instance/_light` default null, one-shot guard, spin period (4–6 s), gem height
  0.50 m, gem equatorial radius < collider radius, group StringName contract.
  Four new preload constants: `RP`, `WS`, `CKP`, `DS`.
  Side quest: `docs/research/machinery_hazards.md` — industrial machinery hazard design
  (four-beat cycle, cross-axis preference, emissive danger strip, mobile dormant-window
  formula, Godot 4 `AnimatableBody3D` sketch). INDEX.md updated. Throttle: 7 (soft).

- 2026-05-12 — Iteration 57. **Data shard collectible.** `scripts/levels/data_shard.gd`:
  Area3D, adds to `"data_shard"` group, SurfaceTool octahedron gem (unshaded cyan emissive,
  CULL_DISABLED), OmniLight3D (cyan 1.4 energy / 4.5 m range), SphereShape3D collision
  (r=0.6 m), slow Y-spin 1.15 rad/s. On collection: `Game.shards_collected += 1`, hide
  mesh, Tween light pulse (1.4 → 7.0 over 0.05 s, → 0.0 over 0.30 s). `respawn_shard()`
  resets without level reload. `scenes/levels/data_shard.tscn` minimal Area3D stub.
  `scenes/levels/threshold.tscn`: ShardLedge StaticBody3D at (7,−6.25,82) size 3×0.5×3,
  DataShard instance at (7,−4.0,82) in Zone3_Industrial — off the gantry par-route,
  visible from G1, reachable via double-jump from the ledge. Dev menu: "Shard ledge"
  teleport button + "Respawn shard" button (resets Game.shards_collected + calls
  respawn_shard() on all group members). 9 unit tests in `_test_data_shard_placement`
  (672 → 679 assertions). JUICE.md: 3 new entries. On-device pending.

- 2026-05-12 — Iteration 56. **Win-state flow + CameraHint integration.** `game.gd`:
  `is_running`, `shards_collected`, `shards_total`, `start_run()`, `level_complete()`,
  `_process()` timer tick, `reset_run()` now also clears `is_running` and `shards_collected`.
  `scripts/ui/results_panel.gd`: new `CanvasLayer` class; programmatic UI (backdrop +
  `CenterContainer` + `VBoxContainer`); TIME / PAR / SHARDS rows (36 pt font); PAR tinted
  green/red vs. actual time; REPLAY button (40 pt, 360×120 px minimum). `win_state.gd`:
  calls `Game.level_complete()` (stops timer then emits signal) instead of emitting directly.
  `threshold.gd`: `par_time_seconds = 35.0` export; `start_run()` call; `shards_total` auto-count
  from `"data_shard"` group; `ResultsPanel.new()` instantiated as child; `_on_level_completed()`
  passes time/par/shards to panel. `camera_rig.gd`: `_hint_distance_extra` state var;
  `_get_active_hint_extra()` queries `"camera_hints"` group each frame; lerp at 3/sec toward
  active max `pull_back_amount`; `effective_distance = distance + _hint_distance_extra` applied
  in ground distance-maintenance and camera-Y. 11 unit tests in `_test_game_gate1_api`
  (661 → 672 assertions). Two new DECISIONS.md ADRs. On-device pending.

- 2026-05-12 — Iteration 55. **Threshold greybox.** Six new level scripts under `scripts/levels/`:
  `checkpoint.gd` (Area3D, sets spawn + emits `Game.checkpoint_reached`), `camera_hint.gd`
  (Area3D stub, group `"camera_hints"`, exposes `is_player_inside()`), `hazard_body.gd`
  (Area3D instant-kill, calls `player.respawn()`), `win_state.gd` (Area3D, one-shot
  `Game.level_completed`), `rotating_hazard.gd` (`@tool AnimatableBody3D`, `Basis(axis,angle)`
  rotation, `HazardBody` children kill on contact), `threshold.gd` (level root, teleports
  player to spawn, sets `Game.current_level_path`). `scenes/levels/threshold.tscn` (~450 lines,
  70 load_steps): Zone 1 Habitation (warm sodium, furniture-scale shelf platforms, z=0–36),
  Zone 2 Maintenance Buffer (cold OmniLights, 2m-wide corridor, ServiceCart ping-pong platform,
  MaintArm1 RotatingHazard, par-route skip via MaintLedge2b, z=37–68), Alcove Checkpoint
  (amber OmniLight, CheckpointTrigger), Zone 3 Industrial (28m-wide hall, 4 descending gantries
  G1–G4, IndustrialPress atmospheric-only at x=8, 4 Ketsu platforms + Terminal, WinStateTrigger).
  Three CameraHint markers placed. All 4 controller profiles: `fall_kill_y` −25 → −35 to give
  15m void depth below terminal. Dev menu: "Teleport — Threshold" sub-section (12 zone buttons).
  On-device pending.

- 2026-05-12 — Iteration 54. **Air dash implementation.** Three new `ControllerProfile`
  props: `air_dash_speed` (0 = disabled, backwards-compatible), `air_dash_duration` (0.18 s),
  `air_dash_gravity_scale` (0.15). `player.gd`: 4 state vars, `_try_air_dash()` with full
  guard set, `_play_dash_stretch()` (XZ/Y tween, squash_stretch-gated), `_on_air_dash_triggered()`
  (rotates 2D screen→world). `_tick_timers`: recharge on landing, tick + expire in airborne
  branch. `_apply_horizontal`: early-return when dashing. `_apply_gravity`: scale g by
  `air_dash_gravity_scale`. `touch_input.gd`: `air_dash_triggered(dir: Vector2)` signal.
  `touch_overlay.gd`: `_dash_start` dict + quick-swipe check in `_handle_drag`. Two tunables:
  `dash_px_threshold` (40 px), `dash_time_threshold` (0.20 s). `dev_menu_overlay.gd`: "Controller
  — Air Dash" subsection (3 `_profile_sliders`). `project.godot`: `air_dash` action (E key).
  19 unit tests (642 → 661). JUICE.md: dash stretch → prototype. On-device pending.

- 2026-05-12 — Iteration 53. **Feel Lab expansion + interaction variety.**
  `scenes/levels/feel_lab.tscn`: 6 new sub_resources, 30+ new nodes. East
  extension slab (30×1×30 at x=35,z=−10) extends the floor into the high-ascent
  zone. Four high-tier platforms (HA1–HA4 at y-center 1.25/3.25/5.75/8.0 using
  Plat_3x05x3/Plat_4x05x4, surfaces at ~1.5/3.5/6.0/8.25m) form a staircase
  that requires double jump for every step beyond HA1. Five narrow ledges
  (Mesh_LedgeNarrow 3.5×0.3×0.9 m) over void at y=1.5–3.0m, progressing north
  over the gap between floor and void — tests depth perception and precision landing.
  Two parallel walls (WJL/WJR, 4m apart at x=−8/−12) form the wall-jump corner
  geometry for future mechanic testing. Drop-test cliff ledge (6×0.5×3 at x=0,
  y=2.75, z=19) juts beyond main floor's north edge — walk to the edge and drop
  into fog to test fall tracking + camera follow. Vertical moving platform
  (Plat_3x05x3, travel=(0,5,0), 5 s period) at x=18,z=−4 acts as elevator to
  the high ascent zone. `dev_menu_overlay.gd`: new "Teleport" sub-section in
  Level panel — 10 named zone buttons via `_teleport_player(pos)` helper (calls
  `set_spawn_transform` + `respawn`). On-device pending.

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
- ~~**`_build_level_section` over 40 lines.**~~ Done (iter 60). Extracted
  `_build_feel_lab_teleports` + `_build_threshold_teleports`; dispatcher now 16 lines. No behaviour change.
- `player.gd::_run_reboot_effect` is 45 lines (just over threshold). The
  sequential `await` beats make sub-method extraction awkward in GDScript
  without coroutine indirection. Leave as-is; revisit if it grows further.
- `dev_menu_overlay.gd::_build_ui` (~41 lines) and `_make_slider` (~43 lines):
  marginal overruns, no hidden complexity. Leave as-is; extract only if further growth warrants it.
- ~~**`camera_rig.gd::_process` over 40 lines.**~~ Done (iter 62). Extracted 8 private helpers;
  `_process` now 31 lines. Also split `_occlude` → `_occlude` + `_probe_hit_dist`. All methods ≤ 40.
- ~~**Camera pitch manual override V-turn.**~~ Fixed (iter 22). Clamp upper
  bound → 0.0; `absf(_pitch)` → `-_pitch` in `_desired_camera_position`.
  DECISIONS.md entry logged.
- ~~**`results_panel.gd::_build_ui` over 40 lines.**~~ Done (iter 64). Extracted
  `_build_overlay_root`, `_build_center_panel`, `_build_replay_button`; `_build_ui` now 5 lines. No behaviour change.
