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
