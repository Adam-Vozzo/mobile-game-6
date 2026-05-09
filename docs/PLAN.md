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

- Branch: `claude/gifted-shannon-bchl4`
- Focus: iter 5 complete. Reboot animation fully specced (P0 item 6) +
  save-as-profile button (P0 item 7, side quest).
  **Items 1–4 are still blocked on human on-device action.**
  Next: GUT unit tests for controller kinematics (P1) or concrete kit (P1).

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

- Add unit tests for the controller (kinematics integration only — no
  scene-dependent tests yet) using GUT.
- Greybox a `scenes/levels/style_test.tscn` with the Stray + a
  representative environment kit chunk so we can run the style fidelity
  check from `ART_PIPELINE.md` the moment we get a real asset.
- ~~Research notes: Mario Odyssey / Demon Turf / A Hat in Time / Pseudoregalia~~
  Done (iter 4): `docs/research/character_controllers.md`.
- Convert Feel Lab platforms into a small reusable "concrete kit" of
  primitives (`mat_concrete.tres`, `scenes/levels/kit/*`) so Gate 1 has
  a starter vocabulary.
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

### P2 — Opportunistic

- Add an always-on perf HUD visible in a corner when the dev menu is
  closed (frametime + fps) so on-device sessions don't need the menu open.
- Research a "ghost trail" prototype (point-based polyline that fades)
  for the Gate 1 attempt-replay overlay. Don't ship; just sketch.
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
