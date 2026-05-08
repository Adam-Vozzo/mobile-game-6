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

- Branch: `claude/start-project-void-TxIcJ`
- Focus: kickoff. See README "Updates" for the latest entry.

## Queue (ranked, top is next)

The next iteration should pull from the top of this list. Items marked
"P0" advance Gate 0 directly; "P1" is supporting; "P2" is opportunistic.

### P0 — Gate 0 critical path

1. **On-device smoke test.** Open the project in Godot 4.6 Mobile, fix
   any import warnings, then run the Feel Lab in editor and on device via
   one-click deploy. Capture frametime, draw calls, and a 30-second
   gameplay clip if possible. Log results in README.
2. **Tune Snappy on device.** Adjust `resources/profiles/snappy.tres`
   gravity / jump_velocity / accel / coyote / buffer based on first
   on-device feel. Avoid making more profiles until Snappy is felt.
3. **Author Floaty profile (`floaty.tres`)** as second variant for human
   side-by-side feel test. Same parameter set, dadish-leaning values.
4. **Author Momentum profile (`momentum.tres`)** with sustained-input
   speed ramp. Add a sliders-affected curve for the ramp.
5. **Author Assisted profile (`assisted.tres`)** — in-air steering toward
   likely landing target, generous ledge grab, edge-snap on landing.
6. **Camera polish on device.** Tune SpringArm damping, lookahead lerp,
   downward-vel pull, and right-drag sensitivity. Verify recenter idle.
7. **Touch overlay polish.** Add reposition-mode UI (drag widgets to set
   anchors, snap to thumb-zone presets). Persist to `user://input.cfg`.
8. **Dev menu fleshing.** Implement camera params group, juice toggles
   actually wired through (placeholder bus signals are fine), debug viz
   toggles for collision/velocity/normals, time-scale slider, free-cam.
9. **Performance overlay** in dev menu using PerfBudget — frametime, fps,
   tris, draw calls. Colour-code over-budget values red.
10. **Reboot animation polish.** Replace red-flash placeholder with the
    reboot-effect spec in CLAUDE.md (sparks → dark frame → power-on hum
    → upright). Audio can stay placeholder; emphasis is the visual beats.

### P1 — Supporting

- Add unit tests for the controller (kinematics integration only — no
  scene-dependent tests yet) using GUT.
- Greybox a "style_test.tscn" scene with the Stray + a representative
  environment kit chunk so we can run the style fidelity check from
  ART_PIPELINE.md the moment we get a real asset.
- Research notes: Mario Odyssey snap-to-grid feel, Demon Turf custom
  physics, A Hat in Time homing-attack — into `docs/research/`. Update
  `docs/research/INDEX.md`.
- Convert Feel Lab platforms into a small reusable "concrete kit" of
  primitives (mat_concrete.tres, scenes/levels/kit/*) so Gate 1 has a
  starter vocabulary.

### P2 — Opportunistic

- Add on-screen debug HUD shown only when dev menu is closed and the
  device is in test mode (frametime + fps in a corner).
- Research a "ghost trail" prototype (point-based polyline that fades)
  for the Gate 1 attempt-replay overlay. Don't ship; just sketch.
- Investigate Godot's Compatibility renderer fallback for very-low-end
  devices. Don't switch; just measure.

## Blocked / needs human

These mirror "Open questions waiting on you" in the README.

- **None at this kickoff.** First iteration after kickoff will likely
  surface the first one (most likely: "Confirm Snappy default values
  feel right on device, or pick another profile").

## Recently completed (last 5)

- Kickoff steps 1–10 (folder layout, project settings, Android preset,
  doc files, Feel Lab scene, Stray + Snappy profile, dev menu skeleton,
  spring-arm camera, touch overlay, README populated). See README's
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
