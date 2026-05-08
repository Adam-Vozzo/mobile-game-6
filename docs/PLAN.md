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

- Branch: `main` (kickoff branch `claude/start-project-void-TxIcJ`
  squash-merged at session end).
- Focus: ready for iteration 1. Pull from the queue below.

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
2. ~~**SpringArm collision on the camera rig.**~~ **Done** (iteration 1,
   2026-05-08). `SpringArm3D` with sphere probe (r=0.2) + World-only
   collision mask. Camera3D is now a child of the arm; occlusion handled
   automatically.
3. **Tune Snappy on device.** Adjust `resources/profiles/snappy.tres`
   gravity / jump_velocity / accel / coyote / buffer based on first
   on-device feel. Avoid making more profiles until Snappy is felt.
4. ~~**Author Floaty profile (`floaty.tres`)**~~ **Done** (iteration 1,
   2026-05-08). Added to dev menu Profile dropdown.
5. **Author Momentum profile (`momentum.tres`)** with sustained-input
   speed ramp. Add a sliders-affected curve for the ramp.
6. **Author Assisted profile (`assisted.tres`)** — in-air steering toward
   likely landing target, generous ledge grab, edge-snap on landing.
7. **Camera params group in dev menu.** Wire sliders to the rig's
   distance, pitch, lookahead_distance, vertical_pull, yaw/pitch drag
   sensitivities, idle recenter delay/speed. Hot-swap during play.
8. **Touch overlay polish.** Drag-to-place reposition mode invoked from
   the dev menu (handles per control, snap-to-thumb-zone presets,
   resize on jump button). Persist anchors + radii to `user://input.cfg`.
9. **Dev menu fleshing.** Debug-viz toggles (collision shapes, velocity
   vector, ground normal, jump prediction arc), time-scale slider,
   free-camera mode, save-as-new-profile button.
10. **Reboot animation polish.** Replace the red-flash placeholder with
    the spec in CLAUDE.md (sparks → dark frame → power-on hum → upright).
    Visual beats first; audio can stay placeholder.

### P1 — Supporting

- Add unit tests for the controller (kinematics integration only — no
  scene-dependent tests yet) using GUT.
- Greybox a `scenes/levels/style_test.tscn` with the Stray + a
  representative environment kit chunk so we can run the style fidelity
  check from `ART_PIPELINE.md` the moment we get a real asset.
- Research notes: Mario Odyssey snap-to-grid feel, Demon Turf custom
  physics, A Hat in Time homing-attack → `docs/research/`. Update
  `docs/research/INDEX.md`.
- Convert Feel Lab platforms into a small reusable "concrete kit" of
  primitives (`mat_concrete.tres`, `scenes/levels/kit/*`) so Gate 1 has
  a starter vocabulary.
- Wire the player's `controller_param_changed` signal from the dev menu
  to actually mutate the live profile values (kickoff already mutates
  the resource directly via slider callbacks; the signal is currently
  decorative — confirm both paths agree).

### Refactor backlog

- `CameraRig._process` is 62 lines (over the 40-line guide). It is a
  sequential pipeline with no bad smells, but a future iteration could
  split into `_update_drag_and_recenter(delta)`, `_update_lookahead(delta)`,
  and `_place_arm_and_camera()` helper methods if the function grows
  further.

### P2 — Opportunistic

- Add an always-on perf HUD visible only when the dev menu is closed
  (frametime + fps in a corner) so on-device sessions don't need the
  menu to read perf.
- Research a "ghost trail" prototype (point-based polyline that fades)
  for the Gate 1 attempt-replay overlay. Don't ship; just sketch.
- Investigate Godot's Compatibility renderer fallback for very-low-end
  devices. Don't switch; just measure.
- Investigate signing-key handling via gradle env vars so a future
  Play Store build doesn't require touching the editor settings.

## Blocked / needs human

These mirror "Open questions waiting on you" in the README.

- **First on-device verification (top README question).** Until the
  human runs the project in Godot 4.6 once, we don't know whether any
  hand-authored `.tscn`/`.tres` files have syntax mistakes. Iteration 1
  should be paused on its first task until the human confirms the
  project imports cleanly (or paste any errors so iteration 1 can fix
  them).

## Recently completed (last 5)

- 2026-05-08 — Iteration 1: SpringArm3D camera collision avoidance
  (P0 #2) + Floaty profile (P0 #4 side quest). Camera rig now uses a
  SpringArm3D with sphere probe; Floaty added to Profile dropdown.
  Logged in DECISIONS.md; README updated.
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
