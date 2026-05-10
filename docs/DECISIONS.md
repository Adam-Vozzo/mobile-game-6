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
