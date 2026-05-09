# PLAN — Project Void

Rolling work plan. Each iteration reads this first, picks the highest-ranked
item it can advance, and updates the queue at the end. The README's "Open
questions waiting on you" is the human-facing twin of the **Blocked / needs
human** section below.

---

## Current gate

**Gate 0 — Feel Lab.** Goal: one scene, one character controller, fully
instrumented and tunable.

## Active iteration

- Branch: `iter/spawn-sparks-refactor`
- Focus: iter 13. `player.gd::_spawn_sparks` method-size refactor (primary) — 41 → 15 lines
  via 3 extracted helpers: `_build_spark_material`, `_build_spark_mesh`, `_fade_and_free_spark`.
  Juice density research note (side quest). Hard throttle (13 iterations since human direction).
  **Items 1–4 still blocked on human on-device action.**

## Queue (ranked, top is next)

The next iteration should pull from the top of this list. Items marked
"P0" advance Gate 0 directly; "P1" is supporting; "P2" is opportunistic.

### P0 — Gate 0 critical path

1. **On-device smoke test.** Open the project in Godot 4.6 Mobile, fix
   any import warnings (the kickoff was authored without a Godot binary,
   so all `.tscn`/`.tres` files were hand-written — there may be syntax
   nits the editor catches on first import), then run the Feel Lab in
   editor and on device via one-click deploy. Capture frametime, draw
   calls, and a 30-second gameplay clip if possible. Log results in
   README's Updates entry.
   _Blocked — needs human to open Godot 4.6._
2. **Tune Snappy on device.** Adjust `resources/profiles/snappy.tres`
   gravity / jump_velocity / accel / coyote / buffer based on first
   on-device feel. Avoid making more profiles until Snappy is felt.
   _Blocked — needs on-device feel; do after smoke test._
3. **First feel of Floaty + Momentum.** Now that Floaty and Momentum
   profiles are in the dev menu dropdown, the human can switch between
   all three on device and flag what needs adjusting.
   _Blocked — needs on-device feel._
4. **Author Assisted profile (`assisted.tres`)** — in-air steering
   toward likely landing target, generous ledge grab, edge-snap on
   landing. Requires new code in `player.gd` (target-detection, ledge
   cast). Scope for a dedicated iteration once the three base profiles
   have been felt on device.
5. ~~**Dev menu fleshing — in-world debug viz.**~~ Done (iter 4).
   `tools/debug/player_debug_draw.gd` — ImmediateMesh node in Feel Lab;
   collision capsule (cyan), velocity arrow (yellow), ground normal
   (green), jump arc (orange). Four new checkboxes in dev menu Debug viz
   section. All default OFF.
6. ~~**Reboot animation polish.**~~ Done (iter 5). Sparks (`ImmediateMesh`,
   12 lines, particles-toggle gated) + death squish/scale-pop
   (squash_stretch-toggle gated) + warm power-on glow. 2 new JUICE.md
   entries. Reboot dur + fall_kill_y now in dev menu sliders.
7. ~~**Save-as-new-profile button.**~~ Done (iter 5, side quest). "Save as…"
   button in Profile section opens an inline LineEdit + Save/Cancel row.
   Duplicate profile added to dropdown + saved to `user://profiles/<name>.tres`.

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
- Investigate Godot's Compatibility renderer fallback for very-low-end
  devices. Don't switch; just measure.
- Investigate signing-key handling via gradle env vars so a future
  Play Store build doesn't require touching the editor settings.
- Consider upgrading camera occlusion from point ray to ShapeCast3D
  (capsule) if poke-through is observed in Gate 1 tighter geometry.

## Blocked / needs human

These mirror "Open questions waiting on you" in the README.

- **First on-device verification (top README question).** Until the
  human runs the project in Godot 4.6 once, we don't know whether any
  hand-authored `.tscn`/`.tres` files have syntax mistakes. Iteration 2
  should be paused on its first task until the human confirms the
  project imports cleanly (or paste any errors so iteration 2 can fix
  them).
- **First feel verdict.** Once the build runs, the human should try
  Snappy → Floaty → Momentum in the dev menu dropdown and note any
  feel issues. Those notes drive iteration 2's tuning pass.

## Recently completed (last 5)

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

- Momentum profile speed ramp: add `speed_ramp_rate` + `ramp_max_speed`
  to `ControllerProfile`, add `_ramp_speed: float` to `player.gd`. Hold
  until after first on-device feel of current Momentum approximation.
- Camera occlusion upgrade to ShapeCast3D if point-ray poke-through
  observed in Gate 1 geometry.
- `player.gd::_run_reboot_effect` is 44 lines (just over threshold). The
  sequential `await` beats make sub-method extraction awkward in GDScript
  without coroutine indirection. Leave as-is; revisit if it grows further.
