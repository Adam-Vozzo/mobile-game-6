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

## 2026-05-08 — SpringArm3D for camera occlusion, collision_mask = World only

Status: accepted
Context: The kickoff camera rig set the Camera3D position directly with no
collision probing. Gate 1 levels will have dense geometry; without
SpringArm3D the camera will clip through walls whenever the player is near
one.
Decision: Wrap the Camera3D in a SpringArm3D (sphere probe r=0.2, margin
0.05 m, spring_length tracks the `distance` export). Collision mask limited
to layer 1 (World) only; the Player layer (2) is excluded so the player
capsule never triggers arm shortening. The arm's +Z is oriented toward the
camera position via rotation.x = -abs(_pitch), rotation.y = _yaw; the
arm's physics process moves the Camera3D to the safe endpoint; our
_process then calls look_at() on the camera to orient it.
Alternatives considered:
- Manual raycast + camera clamping: more control but significantly more
  code for the same result.
- Larger probe sphere (r=0.5): would cause the camera to pull in for
  thin geometry like railings. r=0.2 balances responsiveness with
  false-positive avoidance.
Consequences: camera can't clip into walls; slight one-frame positional
lag is acceptable for a smooth-follow rig. `_process` in camera_rig.gd
is 62 lines (over the 40-line guide); logged in PLAN.md refactor backlog.

## 2026-05-08 — Floaty profile authored as second controller variant

Status: accepted
Context: CLAUDE.md mandates four profiles: Snappy, Floaty, Momentum,
Assisted. Snappy shipped with kickoff. Floaty is the Dadish-leaning
variant intended for side-by-side feel comparison by the human.
Decision: Author floaty.tres with softer acceleration (50 → ground,
28 → air), longer hangtime (gravity_rising 22 vs 38), more generous
coyote (180 ms vs 100 ms) and buffer (200 ms vs 120 ms), light air
horizontal damping (0.25) for grippier in-air steering, lower peak
speed (6.5 vs 8.0). Added to the dev menu Profile dropdown.
Alternatives considered:
- Wait for Snappy tuning results on device before authoring Floaty.
  Rejected: Floaty only needs the profile file + dropdown entry; no
  risk to Snappy. Adding it now gives the human more to feel on first
  device session.
Consequences: human can switch between Snappy and Floaty at runtime
from the dev menu. Profile parameters are subject to tuning after
first device feel session.
