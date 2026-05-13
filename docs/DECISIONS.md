# DECISIONS — Project Void

ADR-lite log. One entry per significant choice. Format:

```
## YYYY-MM-DD — <decision title>
Status: <accepted / superseded / reverted>
Context: <what problem prompted this>
Decision: <what we chose>
Alternatives considered: <what we didn't choose, briefly>
Consequences: <what changes downstream>
```

Append, don't rewrite. Supersession adds a new entry referencing the old.

---

## 2026-05-13 — Air-dash gesture: buffer-and-discard camera variant as toggleable option

Status: accepted (pending on-device verdict)
Context: The 2026-05-14 direction session shipped the hold-jump+swipe air-dash gesture and
left an open question: "Is the camera-whip on the firing swipe bad enough to need the
buffer-and-discard variant?" A comment in `touch_overlay.gd::_handle_drag` already documented
the fix: "buffer the drag delta during the gesture window and discard it on fire." The human
needs to compare both behaviours on device before deciding.
Decision: Implement buffer-and-discard as `dash_buffer_camera: bool = false` on TouchOverlay
(default off = existing behaviour). When true: camera deltas are held in `_dash_drag_buffer`
(per-touch accumulator) during the active gesture window; discarded on dash fire; flushed to
TouchInput on window expiry or jump release (max latency = `dash_time_threshold`, 0.20 s
default). When false: deltas are forwarded unconditionally each frame (previous behaviour —
swipe pans camera AND fires dash simultaneously). Both modes exposed in dev menu (Touch →
"Buffer dash cam" toggle) so the human can compare in one device session.
Alternatives considered:
- Always buffer (no toggle): removes the option to observe the old behaviour; premature
  until the human has confirmed the whip is actually a problem on device.
- Always forward (no buffer): keeps existing code; leaves the open question unanswered.
- Buffer but don't discard (flush on fire instead): camera still pans, just delayed — does
  not actually prevent the whip, only shifts it. Rejected.
- Discard only on fire, no buffer: camera doesn't move during the window AND doesn't receive
  any accumulated pan. This is what "discard" means here — accepted.
Consequences: `_tick_dash_gesture` encapsulates the full gesture state machine; `_flush_dash_buffer`
centralises flush/discard logic. `touch_param_changed` now handles `dash_px_threshold`,
`dash_time_threshold`, and `dash_buffer_camera`. The human can clean up by: (a) deleting the
`dash_buffer_camera` export and always buffering, (b) removing it and always forwarding, or
(c) keeping the toggle for per-profile experimentation. Gate-locked on device feel.

## 2026-05-13 — Industrial press: new IndustrialPress script replaces moving_platform for Threshold Zone 3

Status: accepted
Context: The IndustrialPress node in Threshold Zone 3 was "atmospheric only" (using
moving_platform.gd with a simple triangle-wave back-and-forth). The machinery_hazards.md
research (iter 58) specified a four-beat cycle (dormant/windup/stroke/rebound) with an
emissive amber danger strip. Gate 1 requires at least one functioning hazard beyond the
RotatingHazard in Zone 2.
Decision: New `scripts/levels/industrial_press.gd` (extends AnimatableBody3D, class
IndustrialPress) owns the four-beat cycle. Direct `position.y` mutation in
`_physics_process` moves the body; child KillZone (HazardBody Area3D) + KillShape
(BoxShape3D inset 0.15 m) kill on contact. Emissive strip is a child MeshInstance3D
(amber StandardMaterial3D with animated `emission_energy_multiplier`). Five export
params tunable live via DevMenu.press_param_changed signal + "Industrial Press — Tuning"
dev-menu section. Par-route routing through the press NOT wired yet — blocked on
on-device feel from Threshold Zone 3 greybox.
Alternatives considered:
- Extend moving_platform.gd: rejected — moving_platform uses a triangle-wave, not a
  four-beat state machine; the code would have diverged too far from the base.
- AnimatableBody3D + move_and_collide: considered but direct position mutation is
  simpler and matches rotating_hazard.gd precedent. Revisit if tunnelling observed.
- @tool annotation: skipped — the press only needs to animate at runtime, not in the
  editor. RotatingHazard uses @tool for its spin preview; the press's vertical motion
  would be disorienting in the editor without a pause toggle.
Consequences: moving_platform.gd (id="7_movp") remains for the ServiceCart in Zone 2.
IndustrialPress now uses id="15_ip" (industrial_press.gd). Future levels can reuse
IndustrialPress by instancing the script on any AnimatableBody3D with EmissiveStrip and
KillZone children.

## 2026-05-12 — Win-state flow: Game.level_complete(), ResultsPanel as instantiated CanvasLayer

Status: accepted
Context: Gate 1 requires a results panel (time / par / shards) and a replay button.
Three integration options: (a) instantiate ResultsPanel in the level script's _ready(),
(b) add as a static child in the .tscn, (c) make it a second autoload. Option (a) keeps
the panel's lifetime tied to the level scene (auto-freed on reload) and avoids editing the
450-line threshold.tscn. Option (b) is correct but requires text-editing a complex .tscn
which is error-prone without the editor. Option (c) is wrong — the panel is level-local.
Decision: `ResultsPanel.new()` in `threshold._ready()` (programmatic instantiation). Panel
is a CanvasLayer with all UI built in `_ready()` — no .tscn dependency. `Game.level_complete()`
(new method) stops the timer then emits `level_completed`; `WinState` calls `level_complete()`
rather than emitting the signal directly so the timer always stops before listeners fire.
Alternatives considered:
- Static .tscn child: rejected for this iteration — error-prone without the editor.
  Correct architecture for Gate 1+ when the editor is available.
- Separate autoload for results: rejected — panel is level-local data, not global.
Consequences: All future levels should use the same pattern (`ResultsPanel.new()` in
`_ready()`, connect to `Game.level_completed`, call `show_results()`). If a design revision
wants a shared results scene, extract to a `.tscn` — the `show_results()` API is stable.
`reset_run()` now also zeroes `is_running` and `shards_collected` (backwards-compatible).

## 2026-05-12 — CameraHint integration: lerp extra distance, ground branch only

Status: accepted
Context: `camera_hint.gd` stubs were placed in threshold.tscn with `pull_back_amount`
values (2, 3, 5 m), but camera_rig.gd ignored them entirely.
Decision: `_get_active_hint_extra()` queries the `"camera_hints"` group each frame,
returns the max `pull_back_amount` among hints containing the player. `_hint_distance_extra`
lerps toward this at 3/sec (≈95% blend in 1 s) every frame regardless of floor state.
In the ground branch, `effective_distance = distance + _hint_distance_extra` replaces the
raw `distance` in horizontal maintenance and camera-Y calculations.
Alternatives considered:
- Per-hint blend_time: too complex for Gate 1; max-of-active is simpler and sufficient.
- Airborne branch: skipped — the rigid-translate model locks camera position during jumps;
  hint effect would be invisible mid-air. Blend starts anyway while airborne so it's ready
  on landing.
Consequences: Level authors now get working pull-back by setting `pull_back_amount` on any
CameraHint volume. The three existing hints in threshold.tscn (pull_back 2/3/5) are live.
At Gate 1 the values should be tuned on device.

## 2026-05-12 — Air dash: all profiles default to speed = 0; enable per device session

Status: accepted
Context: The air dash research note (`docs/research/air_dash.md`) identified two schools of
thought: (a) enable universally on all profiles (mobile players always need depth-error recovery),
or (b) profile-exclusive to preserve SMB-feel purity on Snappy. A third option — enable only on
Assisted — was considered as a middle ground.
Decision: `air_dash_speed = 0.0` default on all four profiles (Snappy, Floaty, Momentum, Assisted).
The human must turn it on per profile via the dev menu "Dash speed" slider during on-device tuning.
This is not a deferral — the feature is fully implemented and charges/timer/gravity all work. The
default-off state simply preserves the existing on-device feel verdict until the human has felt
the dash and chosen per-profile values. The research note recommends starting with Assisted only.
Alternatives considered:
- Enable on all profiles by default (universal). Rejected: would change the feel of existing
  profiles before the human has had a chance to evaluate them on device. Throttle rule: don't
  pick feel winners autonomously.
- Enable only on Assisted. Rejected: arbitrary pre-selection; all profiles should get an equal
  evaluation pass.
Consequences: the first device session after this PR should test dash on each profile and set
the "Dash speed" slider to a non-zero value for any profile where it improves play. The human
then confirms the per-profile values before they get baked into the .tres files.

## 2026-05-12 — Air dash touch gesture: right-zone quick swipe (Option A)

Status: accepted
Context: Two input options from `docs/research/air_dash.md`: Option A (right-zone horizontal swipe,
directional) vs Option B (double-tap jump button, forward-only). Option A requires gesture
disambiguation in `touch_overlay.gd` (swipe vs camera drag); Option B avoids disambiguation but
sacrifices direction and conflicts with variable-jump-height touch release.
Decision: Option A. A quick swipe (≥ 40 px in ≤ 0.20 s) on the right zone is classified as a
dash gesture and fires `TouchInput.air_dash_triggered`. Anything else falls through to camera drag
as before. Both thresholds are `@export` vars tunable from the dev menu (future: expose in Touch
Controls section if device testing shows misfire rate). The swipe direction is emitted as a 2D
screen-space vector; `player.gd` rotates it into world space by the camera yaw, consistent with
how the virtual stick's move vector is transformed.
Alternatives considered:
- Option B (double-tap). Rejected: forward-only; double-tap conflicts with jump-cut timing.
- Both A and B with a Settings toggle. Deferred: adds complexity before device validation.
  Revisit at Gate 3 settings pass if players request it.
Consequences: camera drag on the right zone is unaffected for slow/long touches. Fast swipes
trigger a dash. If misfire rate is too high on device, `dash_px_threshold` can be raised via the
dev menu; if misses are common, `dash_time_threshold` can be raised.

## 2026-05-08 — Autoload named `TouchInput`, not `Input`

Status: accepted
Context: CLAUDE.md's autoload list calls for an autoload named `Input`.
Godot already exposes a global singleton named `Input` (`Input.is_action_pressed`,
etc.). Naming an autoload `Input` shadows the engine singleton everywhere
in script, breaking idiomatic input checks.
Decision: Register the touch-input aggregator autoload as `TouchInput`
instead. Internal API unchanged.
Alternatives considered:
- Keep the name `Input` and prefix calls with the autoload's class
  reference. Rejected: surprises every reader, and `Input.is_action_pressed`
  is too embedded in the language to retrain.
- Drop the autoload and put touch-state on a node inside the scene.
  Rejected: cross-scene access would need a singleton anyway.
Consequences: gameplay code uses `TouchInput.get_move_vector()` and
`TouchInput.is_jump_held()`; built-in `Input.is_action_pressed(...)`
remains usable. CLAUDE.md style line still reads "Input" but should be
treated as "the touch-input autoload, named TouchInput."

## 2026-05-08 — Sensor-landscape orientation (not fixed-landscape)

Status: accepted
Context: CLAUDE.md says "landscape locked." Strict landscape (one fixed
orientation) prevents the player from flipping the phone end-for-end when
swapping hands or charging on the right.
Decision: `display/window/handheld/orientation = 4` (sensor_landscape),
which accepts both landscape orientations but never portrait. Functionally
"landscape locked" from the UI's perspective; convenient for the player.
Alternatives considered:
- `0` (Landscape) strict. Rejected: unnecessary friction.
- `6` (Sensor) any orientation. Rejected: portrait would break thumb
  zones and we have no portrait UI.
Consequences: touch overlay must lay out symmetrically and not assume a
single orientation; fine because thumb zones flip with the device.

## 2026-05-08 — Stretch mode `canvas_items` + aspect `expand`

Status: accepted
Context: phones range from ~16:9 to ~21:9. We need a stretch policy that
keeps the 3D viewport native and flexes the UI to phone aspect.
Decision: `canvas_items` mode with `expand` aspect. Reference resolution
1920×1080.
Alternatives considered:
- `keep` aspect with letterboxing. Rejected: looks broken on mobile.
- `viewport` mode. Rejected: forces the 3D scene into a fixed-resolution
  buffer; mobile GPUs prefer native res.
Consequences: UI authors must put repositionable UI in safe-area aware
anchors, since phone bezels and notches eat the corners.

## 2026-05-08 — Jolt Physics for 3D

Status: accepted
Context: project.godot already had `3d/physics_engine="Jolt Physics"` from
the initial commit. Jolt is faster and more deterministic than Godot's
default 3D physics for capsule-vs-static-mesh queries, which matter for
a precision platformer.
Decision: keep Jolt as the 3D physics engine for the project.
Alternatives considered:
- Default Godot 3D physics. Rejected: slower, less deterministic.
Consequences: capsule-on-slope behaviour will need a tuning pass on
device — Jolt's sliding/snapping characteristics differ subtly from the
default and can affect "feel."

## 2026-05-08 — Auto-merge PR workflow per CLAUDE.md

Status: accepted (after human confirmation)
Context: CLAUDE.md's git workflow section calls for opening a PR and
auto-merging (squash) without waiting for human approval. The session
environment briefing said the opposite (draft PR, no auto-merge). Real
contradiction surfaced at kickoff.
Decision: follow CLAUDE.md — push to a feature branch, open the PR
(non-draft), squash-merge. Exceptions listed in CLAUDE.md ("What requires
the human" + workflow/history/paid/release changes) still apply and stop
for review.
Alternatives considered:
- Default to draft + human review. Rejected by human ("go ahead and feel
  free to merge").
Consequences: faster iteration loop; PRs serve as traceability artefacts,
not gates. If we ever want a stricter mode, the change is one line in
CLAUDE.md.

## 2026-05-09 — _make_slider: initial_value set before callbacks, not after

Status: accepted
Context: `_build_touch_section` and `_build_level_section` were setting slider values
via `slider.value = x` AFTER connecting `value_changed` callbacks. This emitted
`DevMenu.touch_param_changed` / `time_scale_changed` on init, routing back to
`touch_overlay._on_touch_param` and overwriting whatever `_load_layout()` had
loaded from `user://input.cfg`. Touch layout persistence was silently broken.
Decision: Added `initial_value: float = NAN` to `_make_slider`. When provided, the
value is set on the Range node BEFORE callbacks are connected, so `value_changed`
fires internally but no listeners receive it. The val_label is then initialised from
`slider.value` (which now reflects the initial_value). All callers that need a
specific start display pass it as `initial_value`; profile sliders still get set by
`_select_profile` after build (correct: they need to fire the callback to sync the
display label).
Alternatives considered:
- `Range.set_value_no_signal` after connecting: would suppress the label update too,
  requiring a separate manual label refresh.
- Deferred emit from touch_overlay after load: requires the overlay to exist first
  (another deferred frame), and the signal goes to _on_touch_param (self-loop).
  More complex, addressed in refactor backlog under "touch slider display."
Consequences: Camera rig and dev menu defaults must stay in sync by convention (no
longer auto-corrected by broadcast on init). Touch layout persistence now works.

## 2026-05-09 — Camera occlusion via PhysicsDirectSpaceState3D raycast, not SpringArm3D

Status: accepted
Context: PLAN.md P0 #2 called for "wrapping the camera in a SpringArm3D." The
goal is to pull the camera forward when world geometry sits between the player
and the desired camera position (wall clip, tight corridors).
Decision: implemented occlusion as a per-frame `intersect_ray` call in
`camera_rig.gd::_occlude()` rather than restructuring the scene with a
SpringArm3D node.
Alternatives considered:
- SpringArm3D child node: idiomatic Godot pattern, but requires restructuring
  the existing yaw/pitch maths (SpringArm3D uses its local transform for the
  arm direction, which conflicts with our procedural placement). Also adds a
  .tscn change that can't be runtime-verified without a Godot binary present.
- ShapeCast3D node: capsule cast gives better clearance than a point ray, but
  the added complexity (orientation, shape sizing) isn't justified for a Feel
  Lab with no tight geometry yet. Can revisit if point-ray occluder poke-through
  becomes an issue in Gate 1 geometry.
Consequences: `_occlude(aim, desired)` is a pure script function, easy to
unit-test. Tunable via `occlusion_margin` and `occlusion_min_distance` exports,
both now in the Camera section of the dev menu. Player RID is excluded from the
query so the capsule doesn't occlude its own camera.

## 2026-05-10 — Touch slider display: group-query approach

Status: accepted
Context: After the iter-17 silent-init fix, touch sliders correctly do not fire
DevMenu.touch_param_changed during init — but they displayed hardcoded defaults
(95 / 0.5) even when user://input.cfg had different values. The overlay itself
was correct; only the slider display label was stale. A "loaded params" signal
was the obvious fix but would require connecting before the signal fires, adding
a new autoload signal that DevMenuOverlay would need to observe before build.
Decision: TouchOverlay adds itself to the "touch_overlay" group in _ready().
DevMenuOverlay._build_touch_section() queries that group just before building
sliders and passes the actual loaded values as initial_value. Since
DevMenuOverlay._ready() is triggered by call_deferred("_install_overlay") in
DevMenu._ready(), the full scene tree — including TouchOverlay._ready() and its
_load_layout() call — has already completed before the group query runs.
Alternatives considered:
- New DevMenu.touch_layout_loaded signal: requires knowing exact load timing;
  adds a new autoload signal surface for a cosmetic fix.
- Store params in DevMenu autoload: DevMenu doesn't own touch layout state;
  creates confusing ownership. Also doubles as stale-on-scene-swap risk.
- set_value_no_signal + manual label refresh: requires storing (slider, label)
  pairs per row; more invasive refactor than the problem warrants.
Consequences: DevMenuOverlay reads from the scene tree during _build_ui().
Falls back to hardcoded defaults (95 / 0.5) if no "touch_overlay" group member
exists — correct for editor scenes without touch UI. Relies on the
call_deferred ordering guarantee, which is stable in Godot 4.x.

## 2026-05-10 — Camera pitch clamp restricted to ≤ 0 (above-horizontal only)

Status: accepted
Context: `camera_rig.gd::_desired_camera_position` used `absf(_pitch)` for the
elevation angle. `_pitch` starts at -0.384 rad (-22°) and the clamp formerly
allowed it to go up to +deg_to_rad(pitch_max_degrees). Dragging the camera
upward pushes `_pitch` from -0.384 toward 0 (camera drops to horizontal), then
past 0 into positive values — `absf` then rises again. This created a V-shape:
the camera dips to horizontal and rebounds, with the 0-crossing reachable in
~128 px of upward drag at default pitch_drag_sens 0.003 on a 1080p phone.
Decision: (a) Restrict the clamp upper bound to 0.0 so `_pitch` stays ≤ 0 at all
times (camera always above horizontal), and (b) change `absf(_pitch)` to
`-_pitch` (equivalent when _pitch ≤ 0; monotonically correct). The camera can
still tilt from horizontal (p=0) up to `pitch_min_degrees` (default 55°). The
`pitch_max_degrees` export and its dev-menu slider are now inactive as guards
(their original meaning — "how far below horizontal" — is no longer reachable).
Alternatives considered:
- Use `maxf(0.0, -_pitch)`: fixes the V-shape while keeping the clamp symmetric;
  camera bottoms at horizontal instead of clamping there. Rejected as less clean —
  the formula would silently pass meaningless positive _pitch values without the
  clamp fix, and having two guards is confusing.
- Allow below-horizontal (camera looking up at player): never useful in a
  precision platformer — gives no landing information, clips through floors, and
  is disorienting. Would require a complete sign-convention refactor.
Consequences: `pitch_max_degrees` @export and dev-menu slider are retained for
potential future use (e.g., minimum-elevation-above-horizontal constraint) but
have no runtime effect. The V-turn bug is eliminated. The unit test group
`_test_camera_pitch_formula` (~5 assertions) documents the invariant.

## 2026-05-09 — Camera model: tripod follow (rotates in place; doesn't translate with lateral motion)

Status: accepted
Context: The original "rig + offset" camera (camera_rig.gd before this date)
followed the player rigidly — every metre the player walked sideways translated
the camera one metre sideways. Combined with auto-recenter that orbited the
camera around the player's heading, this caused continuous lateral background
slide during normal play and was reported as motion-sick on phone. Auto-recenter
itself had a sign bug (atan2 of velocity rather than negated velocity) that
spun the rig unboundedly when the player moved straight forward.
Decision: Replace the rig+offset model with a tripod camera. Each frame the
camera holds its current world position; distance-maintenance only translates
the camera *along* the camera→player horizontal axis, so the camera's distance
to the player is preserved but lateral player motion is absorbed by the
look_at re-orientation rather than by translation. Auto-recenter is deleted
(was the source of the spinning bug, and the tripod doesn't need it). Lookahead
is deleted (its purpose — biasing the rig toward velocity — is anti-correlated
with what motion-sick users want). Manual right-drag still orbits the camera
around the player's spherical-coords pose; pitch is clamped ≤ 0 so the camera
stays at-or-above horizontal (see 2026-05-10 V-turn entry).
Alternatives considered:
- Reduce the lookahead/recenter rates to mask the slide. Rejected: the slide is
  proportional to player walking speed, not to rate; turning rates down only
  delays the same total motion.
- Keep the rig+offset model but lerp the rig position toward the player. Same
  problem at the limit: the camera ends up translating with the player.
- Camera-on-rails / locked angles. Rejected: precision platformer needs
  arbitrary headings.
Consequences: `_yaw`, `_pitch`, `_lookahead`, `_last_drag_time`, the recenter
state and the lookahead state are gone. New state is just `_pitch_rad` (drag
overrides) and the camera's own world position. Player input frame
(`_camera_yaw` published to player.gd) is now derived live from the
camera→player horizontal vector each frame, so "stick up" always means "move
away from the camera in the current view". On the ground, lateral player
motion produces a slow look_at rotation as the player drifts off the camera's
forward axis; that rotation is intentional (it's how the camera "tracks" the
player without translating with them). Lookahead/recenter dev-menu sliders
are dropped from the Camera section.

## 2026-05-11 — Selective camera occlusion: dedicated layer + sphere cast + asymmetric smoothing + hysteresis latch

Status: accepted
Context: The first-pass camera occlusion (raycast from aim_point to the desired
camera position, snap to hit minus margin) had three observable failures on
mobile: (a) every wall, pillar, and small platform blocked the camera equally
— passing behind a 2 m platform produced the same hard pull-in as ducking
behind a real wall, which is visually busy; (b) ray casts through a wall edge
hit/miss alternated frame-by-frame because a ray is infinitely thin, producing
a one-frame flicker the user described as "spazzing"; and (c) walking around a
corner toggled the occlusion state on the way past the edge, bouncing the
camera in/out as the geometry came in and out of cover.
Decision: Three layered fixes, all in `camera_rig.gd::_occlude` and
`_process`.
1. **Selective occluder layer**: new physics layer 7 = `CameraOccluder`. The
   camera's `occlusion_mask` defaults to that layer only (`1 << 6 = 64`). Big
   architectural pieces (walls, pillars, megastructure shells) get
   `collision_layer = 65` (1 = World + 64 = CameraOccluder); small gameplay
   obstacles (platforms, slopes, moving platforms) keep the default `1`. The
   camera ignores the small ones; the player still collides with everything
   normally because player collision is layer-1-based.
2. **Sphere cast instead of raycast**: `direct_space_state.cast_motion` of an
   `occlusion_probe_radius` (0.22 m default) sphere from aim_point toward the
   desired camera position. A volume sweep doesn't toggle hit/miss at thin
   wall edges the way a thread-thin ray does. `occlusion_probe_radius = 0`
   falls back to the old ray, kept as an opt-out.
3. **Asymmetric smoothing + hysteresis**: position-follow rate is
   `pull_in_smoothing` (28 / sec, fast) when the camera should move *toward*
   the player and `ease_out_smoothing` (6 / sec, slow) when moving away.
   On top of that, a frame-counted hysteresis latch: any sphere-hit re-arms
   `_is_occluded = true` for `occlusion_release_delay` (0.18 s default), and
   the camera holds at `_last_occluded_pos` even if the probe momentarily
   clears during the latch window. Latch only releases after a sustained run
   of clear frames, so a one-frame peek-through at a corner edge can't bounce
   the camera back to full distance.
Alternatives considered:
- One global "everything blocks" layer with stronger smoothing alone:
  rejected — small platforms producing constant micro-pull-ins read as
  jitter no matter how heavily damped.
- ShapeCast3D node attached to the rig: viable but adds a permanent extra
  query per frame and binds the occluder geometry to a node-based filter;
  the `cast_motion` script call is equivalent and keeps everything in the
  rig script.
- State-machine approach (separate "free" / "approaching wall" / "behind
  wall" states): more lines for the same observable behaviour. The
  hit-counter latch is the simplest hysteresis that handles corner bounces.
Consequences: New project setting `3d_physics/layer_7="CameraOccluder"`. Two
scenes updated (`feel_lab.tscn`: pillars × 4, walls × 2; `style_test.tscn`:
WallPanel, ScalePillar). New @export knobs in the rig: `occlusion_probe_radius`,
`pull_in_smoothing`, `ease_out_smoothing`, `occlusion_release_delay`. Future
levels should tag any geometry larger than ~3 m in any horizontal dimension
on layer 7; gameplay obstacles stay on layer 1 only. The earlier
`follow_smoothing` single-rate export is gone — split into the two asymmetric
rates above.

## 2026-05-11 — Airborne camera: rigid translation, no rotation

Status: accepted
Context: Once the tripod model was settled, the camera still rotated visibly
during jumps because look_at tracked the player along their parabolic arc:
`_camera_yaw` published to the player drifted while airborne, so a stick
direction held at takeoff would steer slightly differently mid-flight as the
camera angle shifted. This is a known footgun in 3D platformers (the player's
"forward" should be locked to the takeoff frame for the duration of the jump).
A first attempt — freeze cam.x and cam.z while airborne and let look_at
pitch-only — was actually the *opposite* of what the user wanted: it stopped
the camera following the player's translation entirely. The camera should
follow the player's position so they stay framed, and only the rotation
should freeze.
Decision: Each frame, after running the full position-update pass, store
`_air_offset = camera.global_position - target_pos` (camera offset relative to
player). On airborne frames, the very first thing in `_process` is
`camera.global_position = target_pos + _air_offset` — a rigid translation
that copies the player's per-frame delta onto the camera and preserves the
camera→player vector exactly. Distance maintenance, occlusion, and the
asymmetric lerp are all skipped while airborne. look_at and `pub_yaw` still
run because the rigid translate keeps the camera→player vector identical to
the previous frame, so both produce the same basis / angle frame after frame
— effectively no-ops *unless* drag has changed the offset, which is the only
source of intentional rotation mid-jump. On landing, the ground branch
resumes; the offset captured during the jump may be at an oblique angle
(player jumped sideways), and the existing asymmetric lerp eases the camera
back to the canonical 6 m radius without a hard snap.
Alternatives considered:
- Freeze only the published yaw, keep look_at running: stops the input-frame
  drift but leaves the visible camera rotation, which the user reported as
  the more disorienting half of the problem.
- Freeze cam.x / cam.z, follow Y only: misreads the request — leaves the
  player floating out of horizontal frame on long jumps.
- Detect the airborne window via velocity rather than `is_on_floor()`:
  `is_on_floor()` already accounts for slope-snap and frame-of-grace cases
  the controller cares about; routing through velocity would create a
  second source of truth.
Consequences: `_air_offset: Vector3` added to camera state. The `_process`
body splits cleanly into "ground branch (full tripod logic)" and "air
branch (rigid translate only)" with shared look_at and yaw publish. Drag
input still works mid-jump — it modifies the camera's orbital position
after the rigid translate; that change propagates into `_air_offset` at
end-of-frame and the camera persists the dragged orientation through
subsequent air frames. Coyote-time grace is inherited from the controller's
`is_on_floor()` semantics, which is the desired behaviour (camera doesn't
snap-freeze the instant the player runs off a ledge — it freezes once the
controller actually treats the player as airborne).

## 2026-05-10 — Assisted profile: Phase 1 = sticky landing only; Phase 2 deferred

Status: accepted
Context: PLAN.md P0 item 4 calls for a full Assisted profile including in-air
steering toward likely landing targets, generous ledge grab, and edge-snap.
`docs/research/assist_mechanics.md` defines the complete implementation (sticky
landing → ledge magnetism → arc assist → edge-snap in that order). The profile
requires no device feel to implement Phase 1 since all new properties default to
0 on non-Assisted profiles, preserving all existing behaviour.
Decision: Implement Phase 1 this iteration: (a) add `landing_sticky_factor` and
`landing_sticky_frames` to `ControllerProfile` (both default 0 = disabled,
backwards compatible); (b) add `_was_on_floor_last_frame` + `_sticky_frames_remaining`
to `player.gd`; (c) apply the damping multiplier in `_apply_horizontal` when the
sticky counter is live; (d) author `assisted.tres` with generous timing windows and
sticky landing enabled; (e) add Assisted to the dev menu dropdown. Phase 2 (ledge
magnetism via ShapeCast, arc assist) deferred until the human feels all four profiles
on device — those mechanics require tuning against real tactile feedback.
Alternatives considered:
- Wait for device feel before implementing anything: the Assisted dropdown entry
  would be absent for the first device run, losing the opportunity to compare all
  four profiles. Since Phase 1 is backwards-compatible, there is no cost to shipping
  it now.
- Implement full Phase 2 now: ledge magnetism requires ShapeCast at jump time, arc
  assist requires per-frame parabola simulation. Both are non-trivial and their
  parameter values are meaningless without device feel. Premature implementation
  would be guesswork.
Consequences: Dev menu dropdown now has four entries: Snappy / Floaty / Momentum /
Assisted. All existing tests pass (non-Assisted profiles have sticky params == 0).
`_was_on_floor_last_frame` is also the correct place for the juice system's
landing-squash trigger (per `assist_mechanics.md` implication) — extracted here so
future juice work doesn't need to add a second `is_on_floor()` call.

## 2026-05-12 — Gate 1 first level: Threshold (Lung and Spine queued)

Status: accepted
Context: Three Gate 1 candidate level concepts were authored in iter 30 — `spine.md`
(vertical wall-jump column ascent), `lung.md` (horizontal ventilation chamber with
moving baffles), `threshold.md` (3-zone contrast study: habitation → maintenance →
industrial). Per CLAUDE.md, level concept selection is a human call. Human direction
session 2026-05-12 surveyed all three and picked Threshold to build first, noting
that "all level concepts sound really awesome" and that the others should be built
if Threshold is feature-complete.
Decision: Build Threshold as the first Gate 1 level greybox. Lung and Spine are not
discarded — they queue behind Threshold and ship in the same Gate 1 if Threshold
proves the kit + controller. Authoring proceeds per `docs/LEVEL_DESIGN.md` workflow
(parti / genius loci / double-reading / procession / verbs / par route / skill range
/ kit requirements / greybox) and the `threshold.md` design doc; design-on-paper is
already through step 5 there.
Alternatives considered:
- Build Spine first to validate wall-jump (which doesn't exist yet). Rejected:
  wall-jump as a mechanic isn't yet planned for Gate 0; Threshold's contrast study
  works with the existing movement set + the approved double jump (see ADR below).
- Build all three simultaneously. Rejected: human explicitly asked for sequencing
  ("let's start with threshold") and the team-of-one cadence makes parallel level
  authoring an iteration-coverage trap.
Consequences: `docs/PLAN.md` P0 queue now contains Threshold greybox as item 7,
dependent on the camera vertical-follow rewrite (item 2) and double jump (item 4)
landing first. Lung and Spine remain in `docs/levels/` as ready-to-author specs but
do not have queue slots until Threshold's verdict is in. The Gate 1 success criterion
"At least 2 controller profiles to compare on device" can still be evaluated against
Threshold alone — controller comparison is mechanic-level, not level-count-level.

## 2026-05-12 — Double jump approved as expected Gate 1 mechanic

Status: accepted
Context: Project Void's CharacterBody3D player ships with single jump only (per
`character_controllers.md` SMB-grammar baseline). The human direction session
2026-05-12 surfaced double jump as a likely-necessary mechanic ("Double jump will
likely be necessary; build levels with double jump in mind"). This is a craft-pillar
decision — controller feel and level design are the two non-negotiable pillars per
CLAUDE.md, and adding a second airborne jump changes both the controller's response
surface and the level designer's vertical vocabulary materially.
Decision: Implement double jump as a `ControllerProfile`-resourced mechanic with the
same default-off-on-current-profiles pattern used for sticky landing in iter 27.
Three new `ControllerProfile` properties (all default 0 = disabled, backwards
compatible): `air_jumps: int` (number of jumps available while airborne), `air_jump_velocity_multiplier: float`
(multiplier on `jump_velocity` for non-grounded jumps; lets the second jump be weaker
than the first if a profile wants that feel), and `air_jump_horizontal_preserve: float`
(0..1, how much horizontal velocity carries through the air jump; mirrors the
preserved-horizontal-velocity-through-jumps invariant from CLAUDE.md). Player state:
`_air_jumps_remaining: int` decremented per air jump, reset to `profile.air_jumps`
on `is_on_floor()`. Dev menu sliders for all three params. Unit tests for the state
machine (initial count, decrement, reset on land, no-air-jump-when-zero, boundary).
Threshold and any subsequent Gate 1 level should be authored with double jump in mind
— beats can include heights only reachable via double jump, or via single-jump-plus-
wall-context once wall-jump exists.
Alternatives considered:
- Implement double jump as a hardcoded player.gd state (not profile-resourced).
  Rejected: violates CLAUDE.md's "All tunable values live in `Resource` files" rule
  and would block per-profile feel experimentation (e.g. Snappy gets one air jump,
  Floaty gets two, Momentum gets zero).
- Defer double jump to Gate 1 and start Threshold without it. Rejected: the human
  explicitly asked for levels authored *with double jump in mind*, so the mechanic
  needs to exist (even if disabled per-profile) before greybox starts.
- Conflate double jump with air dash. Rejected: they're distinct mechanics with
  different feel signatures and different `ControllerProfile` parameter surfaces;
  air dash is also approved (see `air_dash.md`) and they'll coexist as separate
  toggleable profile properties.
Consequences: Three new profile properties bump the profile resource format —
existing `.tres` files keep working because the props default to 0. Dev menu's
Controller section gains a "Double Jump" subsection (3 sliders). Test count grows
by ~10 assertions. Gate 1 levels are now allowed to design around 2-jump heights;
single-jump-only levels remain authorable by setting `air_jumps = 0` on the active
profile during a beat-by-beat playtest.

## 2026-05-12 — Ghost trail (SMB attempt-replay) deferred to speedrunning track

Status: accepted (supersedes the implicit "Gate 1 ghost trail" expectation from
`docs/research/ghost_trail_prototype.md` and CLAUDE.md Gate 1 success criteria)
Context: `docs/research/ghost_trail_prototype.md` (iter 10) sketches a MultiMesh-
based attempt-replay overlay (1 draw call, 300 instances, alpha-by-recency).
CLAUDE.md's Gate 1 success criteria include "Attempt-replay overlay (SMB-style ghost
trails)". The human direction session 2026-05-12 reviewed this and concluded ghost
trail is "on-hold. makes sense if the game becomes about speedrunning, otherwise
likely unnecessary."
Decision: Ghost trail / attempt-replay is **on hold** as a Gate 1 deliverable.
The MultiMesh prototype work in `ghost_trail_prototype.md` is shelved, not deleted —
research and implementation sketches stay in the repo for future revival. The Gate 1
checklist item "Attempt-replay (ghost trails)" remains in `README.md`'s roadmap but
should be treated as soft (not blocking Gate 1 close-out). The mechanic returns if
playtesting drives the game toward a speedrunning identity — at which point the
trail comes back along with par-time tracking, leaderboards, and any other
speedrun-coded surface.
Alternatives considered:
- Build ghost trail at minimum fidelity now to keep the option open. Rejected: a
  half-built trail with no pedagogical purpose is worse than no trail; commitment
  is what makes the SMB trail feel essential rather than gimmicky.
- Strike the Gate 1 checklist item entirely. Rejected: leaving it as a soft item
  preserves the design history of considering it, in case the speedrunning direction
  emerges later.
Consequences: PLAN.md Gate 1 critical path no longer routes through trail
implementation. `Game.player_respawned` signal stays wired for whatever future
consumer comes along (currently just used for telemetry). Checkpoint design
(`checkpoint_design.md`) had recommended Option A partly because mid-level
checkpoints break the ghost-trail-anchor invariant; that recommendation stands
on its own merits (mobile reboot UX, level pacing) so the recommendation does
not change with this ADR.

## 2026-05-12 — Camera vertical-follow ratchet (hold Y unless above default apex or on higher ground)

Status: accepted
Context: First on-device verification (2026-05-12, Nothing Phone 4(a) Pro)
surfaced the existing camera's full-vertical-tracking behaviour as motion-sickness
inducing on phone — every normal jump pumped the camera up and down by the full
arc, and on a small handheld screen that constant Y motion against a foggy
brutalist background reads as visual chop rather than scene motion. The user's
ask: "Camera should not move vertically until the character moves above the
default max jump height, or walks on a higher level of ground. Stops the camera
moving so much." The principle is sound for the megastructure aesthetic too —
the world's verticality should feel monumental against a held horizon, not
chased by a tracking one.
Decision: Add a vertical-follow ratchet to `camera_rig.gd`. Two new pieces of
state:
- `_reference_floor_y: float` — the Y of the floor the player most recently
  stood on. Updated every grounded frame (so stairs, slopes, and platform-to-
  platform hops flow into the camera); held while airborne.
- `apex_height_multiplier: float` — `@export_range(0, 5, 0.05)` default `1.0`.
  Multiplies the active profile's max jump apex (`v² / 2g`) to form the held-Y
  band. `0` disables the ratchet entirely (legacy always-track-Y fallback for
  non-Player targets).
The ratchet is one pure function, `_compute_effective_y(player_y)`:
```
band = profile_apex * multiplier
if band <= 0: return player_y    # fallback
apex_y = reference_floor_y + band
if player_y > apex_y: return player_y - band
return reference_floor_y
```
All camera-position math now derives from `effective_target = (player.x,
_compute_effective_y(player.y), player.z)` rather than raw player position.
Below apex, Y is pinned to the reference floor; above apex, the camera lifts
1:1 with the player so double-jumps / wall-jumps / vertical traversal still
keep the player in frame. The airborne `_air_offset` rigid-translate is now
captured relative to `effective_target`, so it composes correctly — below-apex
jumps don't leak into the offset and re-apply as Y motion the next frame.
Fall-pull (`_vertical_pull_offset`) is now gated through `_conditional_fall_offset`:
disabled while the player is below the apex band (where the camera is held by
design — a fall pull there would yank it down and reintroduce the motion we're
removing), enabled above the band where the player needs to see the ground.
The apex height is queried live from the active controller profile via a new
`Player.get_default_apex_height()` method (camera duck-types via `has_method`).
That way profile hot-swaps from the dev menu auto-rescale the band — no manual
sync slider needed for the apex itself, only the multiplier.
Alternatives considered:
- A simpler Y dead-band ("don't move Y unless player.y delta exceeds N
  metres"). Rejected: a fixed-metre dead-band doesn't adapt to the active
  profile's jump height; Floaty (2.5 m apex) and Snappy (1.74 m apex) need
  different bands or the rule breaks for one profile while feeling right
  for the other. Deriving from `v² / 2g` solves this automatically.
- Camera-on-rails / fixed-per-level Y like SMB 3D. Rejected: too constraining
  for a level-design vocabulary that ranges from a wall-jump column (Spine)
  to a 3-zone horizontal contrast (Threshold). The ratchet gives most of the
  same calmness while preserving the tripod model's adaptiveness.
- Reference-floor smoothing toward player.y (continuous lerp rather than
  discrete update). Rejected for now: the existing asymmetric position-
  smoothing on the camera already smooths the transition when the reference
  jumps to a new tier, and adding a second smoothing layer would dilute the
  "camera moves immediately to the new tier when you arrive there" feel that
  works in SMB 3D / Odyssey.
- Camera position holds Y but `look_at` keeps tilting toward the player on
  below-apex jumps. Rejected: the user's complaint was specifically about
  "the camera moving so much"; pitching the camera up on every hop reads as
  exactly the same motion as translating it. Both must be pinned for the
  feel to land.
Consequences: One new `@export` (`apex_height_multiplier`), one new dev-menu
slider ("Apex multiplier", 0–5, default 1.0), two new state vars, four new
private methods on the camera (`_update_reference_floor`, `_compute_effective_y`,
`_get_target_apex_height`, `_conditional_fall_offset`), one new public method
on `Player` (`get_default_apex_height`). Tests: 21 new assertions in
`_test_vertical_follow_ratchet` (effective-Y math, multiplier scaling, boundary
continuity, monotonicity above apex) plus 14 in `_test_default_apex_height_formula`
(per-profile sanity bounds + edge cases of `v² / 2g`). The four shipped profiles
all stay within a [0.8, 4.0] m apex band; Assisted is highest at ~3.3 m which is
intentional for accessibility. Future double-jump implementation should NOT
reset the reference floor or modify the apex band — air jumps that exceed the
band are exactly the case where the camera *should* track Y, so the ratchet
handles the second jump's height-gain naturally.

## 2026-05-13 — Camera reference-floor smoothing (follow-up to 2026-05-12 ratchet)

Status: accepted (refines, does not supersede, the 2026-05-12 vertical-follow ratchet)
Context: First on-device session with the vertical-follow ratchet (PR #65)
exposed a follow-up issue: when the player lands on a new floor tier
(higher or lower), the camera "snaps too fast vertically." The ratchet was
working correctly on the input side — `_reference_floor_y` updated instantly
on each grounded frame — and the asymmetric position-smoothing was easing
the camera through the resulting Y delta, but the combined effect still
read as a hard cut. Two contributors: (a) `effective_target.y` jumps the
full tier delta in a single frame, so the *target* the camera is chasing
slams to its new value even though the camera position eases; (b) the
asymmetric smoothing's ease-out rate (6 / sec, ~10% closure per 60 fps
frame) was tuned for occlusion-recovery distances of a few centimetres,
not multi-metre Y deltas.
Decision: Smooth `_reference_floor_y` itself on grounded frames at a
configurable rate, with a snap-threshold escape hatch for very large
deltas. Two new `@export`s on `camera_rig.gd`:
- `reference_floor_smoothing: float = 6.0` (range 0..30 per second). Default
  6 / sec gives an ~400 ms settle on a 1–2 m platform-tier shift (3 time
  constants ≈ 0.5 s to 95%). 0 disables smoothing → instant snap (the
  pre-fix behaviour, kept as an opt-out).
- `reference_floor_snap_threshold: float = 8.0` (range 0.5..30 m). Y deltas
  above this still snap directly to the player. Covers respawn (player
  teleports to spawn) and very long falls (10 m+ drops where a slow ease
  would visibly lag and read as broken).
`_update_reference_floor` now takes a `delta` parameter and applies a
frame-rate-independent exponential ease toward `player_y` when the delta is
inside the snap threshold; outside it, snaps as before. The first-frame
(`not _initialized`) and not-on-floor branches are unchanged — initial
camera pose still snaps to spawn, airborne frames still hold the reference
to keep below-apex jumps from leaking Y motion.
The smoothing composes cleanly with the existing asymmetric position lerp
on top: the *target* now eases too, so the position lerp ends up easing a
slowly-moving target rather than racing to a sudden one. End-to-end this
turns the tier-change feel from "cut" into "follow".
Alternatives considered:
- Slow `ease_out_smoothing` further (was 6 / sec → 3 / sec). Rejected:
  slows ALL camera ease-out (occlusion-recovery too), which felt
  unresponsive in tight geometry; also doesn't fix the fundamental issue
  (`effective_target` still jumps a full tier in one frame).
- Reset asymmetric smoothing thresholds based on Y delta magnitude.
  Rejected: more state, harder to predict, doesn't solve the design issue
  (the *target* should ease, not the *follower*).
- Listen for `Game.player_respawned` to snap the reference (instead of a
  snap threshold). Rejected: the signal-based approach only handles
  respawn — long falls / very tall jumps would still feel laggy. A delta-
  magnitude threshold handles both with one knob.
- Smooth `_reference_floor_y` continuously (every frame, not just
  grounded). Rejected: would leak airborne motion into the reference,
  defeating the ratchet's whole point of holding Y during normal jumps.
Consequences: Two new `@export`s, two new dev-menu sliders ("Floor
smoothing" and "Floor snap thresh") in the Camera — Tuning sub-section, one
new test group (`_test_reference_floor_smoothing`, 13 assertions) covering
single-frame lift, multi-frame convergence (10 / 30 frames), monotonicity
+ asymptote, descent symmetry, snap-threshold boundary, rate-0 fallback,
rate-ordering, and initial-frame snap. The previous PR-#65 invariants
(effective-Y math, multiplier scaling, etc.) are unchanged. Future double-
jump implementation does not need to know about this — air jumps that
exceed the apex band still lift the camera via the ratchet's player.y-
tracking branch (no reference update mid-jump, by design).

## 2026-05-13 — Camera follows the fall (track Y below reference floor)

Status: accepted (refines the 2026-05-12 vertical-follow ratchet)
Context: After the reference-floor smoothing fix landed (PR #67), on-device
feedback surfaced another asymmetry: when the player starts falling onto
lower ground, the camera waits for them to touch the new floor before
moving. While airborne, `_reference_floor_y` is held (correct — we don't
want jumps to lift the camera under apex) and `_compute_effective_y`
returned `reference_floor_y` whenever `player.y` was below the apex band.
That covers normal jumps (player.y between reference and apex) but treats
falls below the reference identically, so the camera stayed pinned to the
old tier while the player dropped through the frame. On a deep drop the
player exits the bottom of the frame before the camera catches up.
Decision: Extend `_compute_effective_y` with a third regime — when
`player.y < reference_floor_y`, return `player.y`. The camera now tracks
the descent 1:1 the instant the player drops below the held floor (walking
off a ledge, falling into a pit, descending past the ledge after a jump).
The existing position lerp on top still smooths the actual camera motion;
this change makes the *target* descend, so the camera follows.
The above-apex track-up branch is untouched. The held band (reference ≤
player.y ≤ apex_y) is also untouched — normal jumps still don't move the
camera. The check at the lower boundary is strict `<` so a player landed
exactly at reference stays in the held branch (no one-frame hold/track
oscillation when resting on the floor).
`_conditional_fall_offset` is extended in parallel: vertical-pull now
fires whenever the camera is in *any* Y-tracking regime (above apex OR
below reference). Inside the held band fall-pull stays disabled — pulling
the camera below the pinned floor there would re-introduce the vertical
motion the ratchet removes.
Alternatives considered:
- Only track down when velocity.y < 0 (i.e. the player is actively falling
  rather than just standing below their reference). Rejected: requires
  threading velocity through one more code path for negligible benefit —
  the rare case where the player is below reference and moving upward
  (e.g. jumping back toward the ledge they fell from) lasts a fraction
  of a second and the smoothed asymptotic catch-up looks the same either
  way; "below reference → track" is the simpler invariant.
- Add a "drop look-ahead" — track at `player.y - some_offset` so the
  camera leads the fall. Rejected: `vertical_pull` already handles the
  "see what's below" intent via the now-enabled fall_offset; introducing
  a second mechanism would duplicate that and conflict with manual drag.
- Wait until player.y drops below `reference - threshold` (e.g. 0.5 m)
  before triggering. Rejected: introduces a dead-band that would either
  feel sticky (camera lags small drops) or be silently invisible
  (thresholds below the typical "fall" speed are never reached before
  the player is already deep into the descent).
Consequences: One added branch in `_compute_effective_y`, parallel branch
in `_conditional_fall_offset`. 9 new test assertions in
`_test_vertical_follow_ratchet` covering the below-reference regime
(small drop tracking, deep drop, descent from non-zero reference, descent
into negative Y, boundary strictness, continuity at the reference
boundary, monotonicity + 1:1 rate below reference). Composition with the
2026-05-12 ratchet, 2026-05-13 reference-floor smoothing, and the
asymmetric position lerp is unchanged — only the *target* the camera
chases has a new branch; the smoothing layers downstream apply
identically.

## 2026-05-13 — Camera apex multiplier default 1.0 → 1.15 (peak-jitter headroom)

Status: accepted (refines the 2026-05-12 ratchet)
Context: On-device feedback after PRs #65 / #67 / #68: "at the peak of the
player's jump the camera is moving up and down slightly. It shouldn't be
moving vertically until above the player's max single jump height."
Tracing the math through `_compute_effective_y`, the analytic peak of a
Snappy jump is `v²/(2g) = 1.740 m`. With `apex_height_multiplier = 1.0`
the held-band ceiling is at the same value, and the strict-`>` check
should keep a player at peak in the held branch. In practice though, two
contributors push `player.global_position.y` over the threshold for a
frame or two at the apex:
1. Jolt's capsule-vs-static-mesh resolution can nudge the player's Y up
   by a few millimetres on certain ticks (penetration-correction
   artefacts that are usually invisible but become observable at the
   exact moment vy crosses zero).
2. Semi-implicit Euler with a variable-rate physics step occasionally
   overshoots the analytic apex by sub-mm before the next gravity step
   pulls velocity negative.
Either contributor flicks `player.y > apex_y` from false → true → false
for a frame or two. Each tracking frame, `effective_y = player.y - apex_h
≈ a few mm above 0`, which the airborne rigid-translate carries straight
into the camera Y. Tiny but visible vertical jitter at peak.
Decision: Bump `apex_height_multiplier` default from `1.0` to `1.15`. The
held-band ceiling is now at `1.15 × v²/(2g) = 2.001 m` for Snappy — 26 cm
above the analytic peak. Floor-physics jitter can't reach this. The
threshold is still well below any double-jump reachable height (a second
jump from peak with full `jump_velocity` reaches roughly `2.0 × v²/(2g)`,
i.e. 3.48 m or about 200% of the held-band ceiling), so above-apex
traversal still triggers tracking as designed. Slider range unchanged
(0..5); users who want strict-at-max can drop to 1.0 manually.
Alternatives considered:
- Add hysteresis: once in hold mode, require `player.y > apex_y + buffer`
  to enter tracking; once in tracking, require `player.y < apex_y -
  buffer` to return. Rejected as more state for the same observable
  behaviour — the buffer multiplier on its own gives the same boundary
  separation with a single tunable.
- Quantise `effective_y` (snap to nearest cm) so sub-cm noise is
  filtered. Rejected: above-apex tracking would feel stair-stepped
  rather than smooth.
- Move camera updates into `_physics_process` and rely on
  `physics_interpolation` for visual smoothing. Worth doing eventually
  (cleaner sync between player and camera tick rates), but a larger
  surgical change than this issue needs.
- Filter `player.y` through a low-pass before comparing to apex_y.
  Rejected: introduces latency on real above-apex events (double jump,
  wall jump), where the camera should react immediately.
Consequences: One default value change in `camera_rig.gd`, matching slider
default in `dev_menu_overlay.gd`, 5 new test assertions in
`_test_vertical_follow_ratchet` documenting the 1.15 buffer behaviour
(player at analytic max still held; 5 cm above max still held; 14% above
still held; 30% / 50% above clear the band as designed). No other code
paths affected. If the user reports the camera now feels "too lazy" about
following genuine high jumps, the multiplier slider is the single knob to
adjust.

## 2026-05-13 — Camera reference snap on takeoff (interrupts mid-smoothing)

Status: superseded 2026-05-13 by the apex-anchor / reference split (see entry below).
Original status was "accepted (refines the 2026-05-13 reference-floor smoothing in PR #67)"
Context: After PRs #67 / #68 / #69 all landed, on-device feedback surfaced one
more case: "if you jump too soon after landing on a new surface level the
camera will do a little vertical movement." Tracing the math:
- Player jumps onto a higher tier at Y=1.5 from Y=0. Reference was 0
  pre-jump (held during airborne), and on landing starts smoothing
  0 → 1.5 at 6/sec (≈400 ms settle).
- Player jumps again ~100 ms after landing, before smoothing completes.
  Reference is mid-transit at ~0.5.
- Reference is held during the airborne phase (no update on non-grounded
  frames, as designed).
- `apex_y = reference + apex_band` = 0.5 + 2.0 = **2.5**.
- The player's actual peak during a normal jump from Y=1.5 is roughly
  1.5 + 1.646 (Euler) = **3.15**, which **exceeds** apex_y.
- Track-up branch fires for the part of the jump where player.y > 2.5 —
  `effective_y` lifts, the airborne rigid translate carries it into the
  camera, and the camera rises then drops as the player crests and
  descends. Visible vertical motion during a "normal" jump.
The held-band check should be calibrated to the floor the player is
**actually jumping from**, not to whatever the smoothing was mid-
transitioning to at the moment of takeoff.
Decision: On the grounded → airborne transition (takeoff), snap
`_reference_floor_y = player.y` and recompute `_air_offset` against the
fresh `effective_target` in the same frame. The snap makes the airborne
apex check use the takeoff position as its anchor; the offset recompute
keeps the camera's world position continuous (no vertical pop on the
takeoff frame). Implementation:
```
var just_took_off := _was_on_floor and not on_floor
if just_took_off:
    _reference_floor_y = target_pos.y
_update_reference_floor(target_pos.y, on_floor, delta)
_was_on_floor = on_floor

# ... compute effective_target from the snapped reference ...

if just_took_off:
    _air_offset = _camera.global_position - effective_target
```
The smoothing semantics resume after landing: on the next grounded frame
after the snap+jump, `_update_reference_floor` continues smoothing
toward the player's current floor as before. If the player lands back at
the same tier, smoothing converges instantly (ref already equals player.y);
if they land on a different tier, smoothing eases the camera to the new
floor exactly as PR #67 designed.
Alternatives considered:
- Track `_airborne_anchor_y` separately, distinct from `_reference_floor_y`,
  and use it for apex calculations during airborne frames. Rejected: two
  pieces of state with overlapping semantics, plus the offset recompute is
  still needed to avoid the pop, so no real simplicity gain over the
  one-state snap approach.
- Increase `reference_floor_smoothing` rate to make the smoothing finish
  before a jump could be timed during it (e.g. 20/sec → 100 ms settle).
  Rejected: the original PR #67 problem was the smoothing being too
  *abrupt*; bumping the rate back up re-introduces that. The snap-on-
  takeoff approach keeps the gentle smoothing for landings (where it's
  visible motion) and only bypasses it at takeoff (where it would
  otherwise leak into the airborne arc).
- Use velocity to detect takeoff (vy > 0 + previously grounded). Rejected:
  `is_on_floor()` is already the controller's authoritative grounded
  state, and `_was_on_floor` is one more frame of state; threading
  velocity through the camera adds a second source of truth.
- Apply the snap on every grounded-frame edge case (e.g. detect mid-
  smoothing and snap eagerly). Rejected: the smoothing during grounded
  frames is *desired behaviour* (PR #67) for landings on new tiers; only
  the airborne phase needs the snapped value.
Consequences: One new state variable (`_was_on_floor`), one takeoff-
detection block in `_process`, one new test group (`_test_takeoff_reference_snap`,
10 assertions) covering the snap itself, idempotence, offset recompute
math, camera-position continuity, held-branch behaviour at Euler peak and
analytic peak, the pre-fix track-up contrast, and the same-tier no-op
case. No other code paths affected. The previous PR #67 / #68 / #69
behaviours (smoothing on landings, track-down on falls, apex-multiplier
headroom) all compose unchanged on top of this fix.

## 2026-05-13 — Camera apex anchor split from smoothed reference (supersedes takeoff snap)

Status: accepted (supersedes the 2026-05-13 takeoff-snap ADR above)
Context: PR #71's takeoff snap fixed the "jump-too-soon-after-tier-change"
spurious track-up — but on-device it introduced **two new artefacts** the
user described as "camera snapping, both on flat ground and on recent new
height jumps":
1. On the takeoff frame, snapping `_reference_floor_y` to `player.y`
   instantly changes `effective_target.y` (from the mid-smoothing value
   to the takeoff Y). The `_air_offset` recompute keeps the camera's
   *position* continuous, but `aim_point.y = effective_target.y + aim_height`
   also jumps in the same frame — and `look_at(aim_point)` therefore
   rotates by a small angle (~atan(Δaim/tripod_radius), a couple of
   degrees on a typical mid-smoothing case). Every jump showed a
   one-frame tilt.
2. After landing back at the same tier, the camera position is at the
   pre-takeoff (mid-smoothing) value but the on-floor branch's target is
   the new tier's settled position. The asymmetric lerp "restarts" the
   smoothing — perceptually a delayed motion after the jump finishes.
The fundamental issue: PR #71 conflated two distinct concepts under the
single `_reference_floor_y` variable:
- The **threshold** for the apex check (should reflect the *actual*
  takeoff floor — instant on grounded, held on airborne).
- The **target** for the camera's vertical position (should *smooth*
  toward the player's tier so landings glide).
Snapping one updates the other; smoothing one breaks the threshold check.
Decision: Split them.
- `_reference_floor_y` (existing): smoothed toward `player.y` on grounded
  frames at `reference_floor_smoothing` per second, held during airborne.
  Drives the *target* — hold-branch return and track-down threshold in
  `_compute_effective_y`. PR #67's smoothing behaviour preserved exactly.
- `_apex_anchor_y` (new): **instant** tracking of grounded `player.y` (no
  smoothing), held during airborne. Drives the *threshold* — the apex
  check `player.y > anchor + apex_band` in `_compute_effective_y` and
  `_conditional_fall_offset`.
Implementation:
```
if on_floor:
    _apex_anchor_y = target_pos.y
_update_reference_floor(target_pos.y, on_floor, delta)

# In _compute_effective_y:
var apex_y := _apex_anchor_y + apex_h         # threshold uses instant-anchor
if player_y > apex_y: return player_y - apex_h  # track up
if player_y < _reference_floor_y: return player_y  # track down (smoothed ref)
return _reference_floor_y                        # hold (smoothed ref)
```
Across the takeoff transition, `effective_target.y` is **unchanged**
(both anchor and reference were held from the same grounded value
moments before; only the *update* of anchor stops, but the held value
is correct). No `aim_point` jump, no `look_at` rotation, no `_air_offset`
recompute needed. Smoothing of `_reference_floor_y` continues across
takeoff (held), through airborne (held), and resumes on landing (toward
the new tier) — the lerp is uninterrupted.
The PR #71 takeoff snap and `_was_on_floor` tracking are removed.
Alternatives considered:
- Keep PR #71 + add aim_point hysteresis to suppress the one-frame
  rotation. Rejected: piling fix on fix, and the lerp-restart-on-landing
  artefact would remain.
- Snap reference *and* recompute aim_point so the camera shifts to keep
  cam-to-aim vector constant. Rejected: introduces a position pop (1m+
  on the mid-smoothing case) which is exactly what PR #71 set out to
  avoid.
- Use only the instant anchor (drop the smoothed reference entirely).
  Rejected: re-introduces PR #67's "camera snaps too fast vertically
  when landing on a new floor level" — the smoothing was specifically
  added to fix that, and removing it would regress.
- Use only the smoothed reference (drop the apex anchor). This is the
  PR #67–#71 design; it's what caused all the on-device artefacts to
  begin with. Rejected.
Consequences: One new state variable (`_apex_anchor_y`), one trivial
instant-track update at the top of `_process`, two callsite changes in
`_compute_effective_y` and `_conditional_fall_offset` (reference →
anchor for the threshold). The takeoff-snap branch and `_was_on_floor`
variable are removed. Tests: `_test_takeoff_reference_snap` removed;
new `_test_apex_anchor_split` (10 assertions) verifies that the split
eliminates the spurious track-up at the bug scenario peak, that the
held branch + track-up + track-down branches still fire correctly with
the split, and that the original `_eff_y` (anchor == reference) is
equivalent to `_eff_y_split` when both anchor arguments match. PR #67's
reference smoothing, PR #68's track-down on falls, PR #69's apex-band
headroom all compose unchanged on top of this split.

## 2026-05-12 — Threshold: industrial press atmospheric-only for greybox

Status: accepted (Gate 1 pass item — will be revisited)
Context: The `threshold.md` spec calls for one industrial press hazard on the critical path
in Zone 3 (Beat 3). During greybox construction, placing a moving press hazard directly in
the player's Z-axis path introduced too many design variables simultaneously: press period,
player corridor width, timing window legibility, and interaction with the gantry jump
sequence all need calibration against device feel. Adding a mandatory timed hazard to an
uncalibrated jump sequence could make the level frustrating before any part of it is fun.
Decision: `IndustrialPress` (`AnimatableBody3D`, 14×4×5 m, travel=(0,−5,0), period=5s) is
placed at `(8, −12, 99)` — offset 8 m to the side of the player's primary traversal axis
(z-corridor centred at x=0). At this position the press is visible and atmospheric (period
motion reads in peripheral vision), but the player cannot collide with it on the default
path. No `HazardBody` child is needed in this configuration. The critical path through Zone
3 is gantry G1–G4 + Ketsu K1–K3 + Terminal, all along x=0.
Alternatives considered:
- Place press in-path with a generous timing window. Rejected: the timing window can't
  be calibrated without device feel — a "generous" window designed blind is often either
  trivial (players run through without thinking) or invisible (players don't see the
  telegraph). Greybox should isolate the jump-sequence variable first.
- Omit the press entirely. Rejected: the press is specified in `threshold.md` as the
  Zone 3 atmosphere mechanic; removing it entirely loses the "active machinery" reading
  of the industrial tier.
Consequences: Gate 1 pass will reposition the press into the critical path after the
gantry sequence is confirmed playable on device. At that point add a `HazardBody` child
and tune the period for a 2 s minimum telegraph window per `threshold.md`'s spec.

## 2026-05-12 — fall_kill_y: all profiles −25 → −35

Status: accepted
Context: The Threshold level's terminal platform is at y=−20. With `fall_kill_y = −25.0`
on all profiles, a player falling off the terminal platform respawns after 5 m of descent
— too shallow for an industrial-scale void to read as meaningful depth. The habitation
zone (y=0) and maintenance buffer (y=−5) are fine at −25, but Zone 3 descends to y=−20
and the void must extend beyond the screen's visible depth to feel bottomless.
Decision: Update all four controller profiles (`snappy.tres`, `floaty.tres`,
`momentum.tres`, `assisted.tres`) from `fall_kill_y = −25.0` to `fall_kill_y = −35.0`.
This gives 15 m of void below the terminal platform before respawn — enough to see the
`IndustrialFloorVisual` MeshInstance3D (at y=−30.5) during a fall before respawning.
That visual is pure decorative geometry (no physics — `IndustrialFloorVisual` is a plain
`MeshInstance3D`, not a `StaticBody3D` child). The player never lands on it; it reads as
a floor far below, reinforcing the industrial-scale reading of Zone 3.
Alternatives considered:
- Leave at −25 and make the terminal platform higher. Rejected: would require raising
  the entire Zone 3 Y-stack, conflicting with the 4 m × 4-step gantry descent physics.
- Set −35 only on the level root (not in the profiles). Rejected: no per-level override
  mechanism exists yet (profiles are the only source of truth for this param).
- Set −50 for extra depth. Rejected: at 30 m of fall before respawn, the reboot
  animation plays for an uncomfortable duration (0.5 s reboot + fall time = >1 s
  before resuming play on a bottom-of-level fall). 15 m below terminal = ~0.55 s fall
  at terminal velocity, keeping the respawn within the 1 s felt-responsiveness window.
Consequences: All existing feel-lab tests are unaffected (Feel Lab platforms are at
y=0 and y=0 to +8.25 m; a fall off the highest platform still respawns at ≈−8 m
which is above −35). `_test_respawn_params` assertions for `fall_kill_y` sign/range
remain valid (the test only checks sign and rough range, not exact value).

## 2026-05-12 — CameraHint: Area3D stub; camera_rig.gd integration deferred to Gate 1

Status: accepted
Context: `docs/LEVEL_DESIGN.md` and `threshold.md` call for `CameraHint` nodes at three
beat markers to pull the camera back and frame the scene. `camera_rig.gd` currently has
no logic to query or respond to these nodes.
Decision: Implement `CameraHint` as an `Area3D` stub (`scripts/levels/camera_hint.gd`).
The script adds itself to the `"camera_hints"` group in `_ready()`, exports
`pull_back_amount` and `blend_time`, and exposes `is_player_inside()` (iterates
`get_overlapping_bodies()` for a `Player` match). Three `CameraHint` nodes are placed in
the Threshold scene at the three spec beats (habitation intro pull_back=2, checkpoint
alcove pull_back=3, terminal pull_back=5). The camera rig does NOT query them yet —
they are authoring scaffolding only.
Gate 1 implementation: `camera_rig.gd::_process` will query the `"camera_hints"` group
each frame, find any hint where `is_player_inside()` is true, and lerp `distance` toward
`desired_distance + pull_back_amount` over `blend_time` seconds. This is deferred because
(a) the camera feel must be stable before adding blend-distance state, and (b) the hint
positions need to be tuned against the actual greybox geometry on device.
Alternatives considered:
- Implement the camera-rig query now. Rejected: premature — cannot calibrate hint
  pull_back values before seeing the level on device. Stub is sufficient for authoring.
- Use a different signal / callback approach. Rejected: group query is idiomatic for
  "how many of these exist in the scene" queries; no node reference management needed.
Consequences: `CameraHint.gd` is live but passive. Authoring the three hints in the
Threshold scene now means the Gate 1 pass only needs to add logic to `camera_rig.gd`,
not touch the level scene again.

## 2026-05-12 — Threshold Zone 2 ceiling height: 2.35 m (deliberately oppressive)

Status: accepted
Context: `threshold.md` specifies "1.8 m ceiling means the Stray's jump arc clips the
ceiling if they jump at full height — crouch the ceiling on purpose. This is oppressive
by design." The Stray's player capsule is ~1.46 m tall. With `jump_velocity = 11.5 m/s`
and `gravity_rising = 38 m/s²`, Snappy's analytic apex is ≈1.74 m above takeoff.
Decision: Set Zone 2 floor at y=−5.5 and ceiling at y=−3.15, giving a physical gap of
2.35 m. The Stray's apex (1.74 m) fits within the 2.35 m gap — the player can full-jump
without physics clipping — but the visual ceiling is only 0.89 m above the capsule top
at rest, making it feel claustrophobically low. This matches the design intent ("oppressive
by design") without requiring a ceiling-clip mechanic. The Wall/Ceiling nodes are
`StaticBody3D` with BoxShape, so they are genuine physics surfaces: a player who
manages to push the capsule against the ceiling (e.g. with a double jump near a wall)
will experience a slide, not a clip-through.
Alternatives considered:
- Strict 1.8 m ceiling (1.3 m above capsule). Would cause the capsule to collide
  with the ceiling on full jump — not implemented because clipping punishes exploration
  on a first level and Jolt's capsule-ceiling resolution can cause unexpected horizontal
  deflection that feels unfair. The spec's intent is "feeling" oppressive, not
  mechanically punishing overhead.
- 2 m ceiling (flat number). Rejected in favour of the physics-derived 2.35 m which
  gives exactly spec_intent_height = apex + small_clearance without arbitrary magic numbers.
Consequences: Zone 2 ceiling at y=−3.15 is documented here; level authors should not
raise it above −2.5 (which would lose the oppressive reading) or lower it below
`floor_y + player_capsule_height + 0.1` (which would block standing).

## 2026-05-12 — Snappy reboot_duration stays at 0.5 s

Status: accepted (closes out the `level_design_references.md` recommendation)
Context: `docs/research/level_design_references.md` (iter 9) recommends Snappy
`reboot_duration` ≤ 0.35 s for precision feel based on SMB grammar. The current
default is 0.5 s ("cinematic"). Human direction session 2026-05-12 evaluated the
recommendation on-device and chose to keep 0.5 s ("let's try 0.5").
Decision: Snappy `reboot_duration` stays at 0.5 s. Other profiles unchanged.
The research recommendation is closed out as evaluated-and-rejected; the door is
open to revisit if level-design playtesting suggests respawn cadence is too slow
for the precision/momentum feel pattern.
Alternatives considered:
- Drop to 0.35 s per research. Rejected by human after on-device feel.
- Drop to 0.3 s (the precision-floor in SMB analysis). Rejected for the same reason.
Consequences: No code change. `level_design_references.md` open implication
"shorten Snappy reboot_duration to ≤ 0.35 s" should be marked as evaluated and
rejected in the next research-doc update.
