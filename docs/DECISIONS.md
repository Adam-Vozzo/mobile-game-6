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

## 2026-05-09 — SpringArm3D for camera collision avoidance

Status: accepted
Context: The kickoff camera rig set Camera3D's global position directly with
no collision avoidance. This is fine for the open Feel Lab but will clip the
camera into any wall in Gate 1's tighter geometry.
Decision: Introduce a SpringArm3D as an intermediate child of CameraRig (with
Camera3D as a child of the SpringArm). The CameraRig _process sets the
SpringArm's global basis (yaw × pitch) and spring_length, then calls
look_at on the Camera3D. SpringArm3D's internal _physics_process casts a
shape from its origin along +Z and shortens the arm on collision, moving the
Camera3D to the hit-corrected distance. The player's RID is added to the
SpringArm's exclusion list so the Stray's capsule doesn't trigger shortening.
Alternatives considered:
- Keep direct-position approach and rely on level design to avoid clipping.
  Rejected: PLAN.md explicitly queued this as P0; it's needed before Gate 1
  geometry gets dense.
- Manual raycast in camera_rig.gd. Rejected: SpringArm3D is a battle-tested
  first-party solution requiring less code and matching the standard Godot
  pattern for this problem.
Consequences: Camera-to-wall clipping is handled automatically. One
known caveat: camera_rig.gd runs in _process while SpringArm3D uses its
internal _physics_process. On frames where the arm length changes significantly
(wall corner transition), look_at may be computed from the previous frame's
camera position, causing a single-frame rotation wobble. Acceptable for Gate
0 (open arena). If visible in Gate 1, migrate camera_rig to _physics_process
and call look_at there.

## 2026-05-09 — Floaty controller profile authored

Status: accepted
Context: CLAUDE.md mandates four swappable profiles (Snappy, Floaty, Momentum,
Assisted). Only Snappy existed after kickoff. The human needs at least two
profiles to do a meaningful feel comparison on device.
Decision: Added floaty.tres — Dadish-leaning values: lower gravity_rising (22
vs 38) for hangtime, larger coyote/buffer windows (0.18 vs 0.1/0.12), slower
ground acceleration (45 vs 80), light air horizontal damping (0.8) for feel of
mass, lower jump_velocity (10 vs 11.5). Registered in dev_menu_overlay.gd.
Alternatives considered: Tuning on device first, then authoring Floaty from
feel data. Deferred — the human hasn't had a device run yet. These are
starting values derived from the Dadish-3D pain-point notes in CLAUDE.md.
They will need a tuning pass after first feel feedback.
Consequences: Dev menu now offers Snappy / Floaty comparison. Human can
switch between them on first device session and flag which direction to favour.
