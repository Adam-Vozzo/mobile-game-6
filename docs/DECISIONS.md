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

## 2026-05-09 — SpringArm3D used as collision sensor, not child mover

Status: accepted
Context: PLAN.md called for wrapping the camera in SpringArm3D. Godot's
SpringArm3D repositions its children to the end of the arm in its own
internal _process notification — which fires AFTER the parent Node3D's
_process. Our CameraRig calls look_at() at the end of _process, which
runs before SpringArm3D moves the Camera3D, so depending on automatic
child repositioning would produce a 1-frame misaligned look_at.
Decision: Use SpringArm3D for collision sensing only (get_hit_length()).
Camera3D stays as a direct child of CameraRig and is positioned manually
using the hit length from the last frame. SpringArm3D has no Camera3D
child. This gives correct look_at every frame at the cost of a ~1-frame
lag on the collision distance, which is unnoticeable for camera avoidance.
Alternatives considered:
- Camera3D as SpringArm3D child, look_at via deferred call. Rejected:
  adds 1-frame visual lag to the camera rotation, noticeable during fast
  movement.
- Use RayCast3D with force_raycast_update() instead of SpringArm3D.
  Rejected: SpringArm3D's SphereShape cast catches edge geometry that a
  ray misses; consistent with PLAN.md wording.
Consequences: SpringArm3D rotation must be set to the correct orientation
for the cast. Rotation formula (Euler YXZ): Vector3(|pitch|, yaw + π, 0)
maps local -Z to the world-space camera direction. Derived: Ry(yaw+π)·Rx(|pitch|)·(0,0,-1)
= (cos|pitch|·sin(yaw), sin|pitch|, cos|pitch|·cos(yaw)), which equals
Ry(yaw)·(0, sin|pitch|, cos|pitch|) — the camera offset direction.

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
