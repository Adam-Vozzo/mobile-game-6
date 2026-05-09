# Project Void

A mobile 3D platformer. Brutalist megastructure inspired by *BLAME!*. Controller feel inspired by *Super Meat Boy*. Accessibility inspired by *Dadish 3D*. You play as the Stray — a small lost robot in a vast machine-built world. Godot 4.x, Android, landscape.

## Status

Current gate: **Gate 0 — Feel Lab**
Last iteration: 2026-05-09 — iter 8: style test scene greybox + brutalism/BLAME! research
Test device build: not yet — hand-authored scenes pending first Godot 4.6 import; see Open questions
Performance: not yet measured on Nothing Phone 4(a) Pro
Throttle level: soft — 8 iterations since last human direction

If you only read one section, read **Open questions waiting on you** below.

## Open questions waiting on you

Things Claude can't decide alone, or where it's stalled and needs direction. Each is blocking some piece of forward progress.

- [ ] **Open the project in Godot 4.6 and run the on-device first-run checklist in `docs/ANDROID.md`.** This is the only thing that will catch syntax mistakes in any of the hand-authored `.tscn`/`.tres` files. If anything fails, paste the Output panel error and Claude will fix it next iteration.
- [ ] **First feel verdict — Snappy vs Floaty vs Momentum.** Once the build runs, open the dev menu (F1 in editor, 3-finger tap on device), switch the Profile dropdown between Snappy / Floaty / Momentum and play each for 30–60 seconds. Note: jump arc, air momentum feel, landing, coyote forgiveness. Any notes you give go straight into the next tuning pass.
- [x] **Auto-merge git workflow confirmed and instrumented.** Now enforced by `.github/workflows/auto-merge.yml` — PRs labeled `auto-merge` are squash-merged automatically. Iteration-startup rules in `docs/CLAUDE.md` require checking your own open PRs before opening a new branch, to prevent the duplicate-PR loop that ate iter 1.

## Roadmap

```
[ Gate 0: Feel Lab ]──[ Gate 1: Vertical Slice ]──[ Gate 2: Content Spine ]──[ Gate 3: Polish & Ship ]
       ▲
   you are here
```

### Gate 0 — Feel Lab

Goal: one scene, one character controller, fully instrumented and tunable.

- [x] Feel Lab test arena (brutalist primitives, fog, single warm light)
- [x] CharacterBody3D player (the Stray) with Snappy profile
- [x] Coyote, buffer, variable jump, preserved horizontal velocity
- [x] Dev menu skeleton with live tunables
- [x] Spring-arm camera with lookahead and right-drag override _(occlusion avoidance via raycast added iter 1; camera params live in dev menu)_
- [x] Touch input: virtual stick + jump, repositionable _(positions exposed as `@export`s; drag-to-place UI queued)_
- [ ] Android export pipeline verified on test device

### Gate 1 — Vertical Slice

Goal: one full level that proves the game is the game.

- [ ] Brutalist art direction roughed in (style guide approved)
- [ ] One full level (~60–90 s skilled, ~3 min new player), authored under `LEVEL_DESIGN.md` principles
- [ ] Checkpoints, instant respawn, reboot animation
- [ ] Attempt-replay (ghost trails)
- [ ] One enemy archetype
- [ ] One collectible type
- [ ] Win state and results screen
- [ ] At least 2 controller profiles to compare on device

### Gate 2 — Content Spine

Goal: enough levels in one biome to prove the formula scales.

- [ ] 8–12 levels
- [ ] Level-select hub
- [ ] Par-time tracking
- [ ] Title → select → play → results flow

### Gate 3 — Polish & Ship

Goal: store-ready build.

- [ ] Audio pass (music + SFX)
- [ ] Juice pass (every toggleable element evaluated and locked)
- [ ] Settings menu (camera sensitivity, button resize/reposition, accessibility toggles)
- [ ] Save/load
- [ ] Final controller profile chosen and locked
- [ ] Play Store build & listing assets

## Updates

The full iteration log lives here, newest first. Every iteration appends an entry. Skim the dates to find where you last left off.

<!-- ITERATION ENTRIES BELOW — DO NOT REMOVE OLDER ENTRIES -->

### [2026-05-09] — `claude/gifted-shannon-9IpbZ` — iter 8: style test scene greybox + brutalism/BLAME! research

- Primary: **Style test scene greybox (PLAN P1).** `scenes/levels/style_test.tscn` +
  `scripts/levels/style_test.gd`. A compact display room for art fidelity checks —
  required by `docs/ART_PIPELINE.md` § Style fidelity check before any real asset is
  committed. Layout: 20×20 floor (mat_concrete_dark), a 2×0.5×2 platform (mat_concrete)
  to the right, a 1×4×4 wall panel (mat_concrete_dark) to the left, a 2×8×2 scale pillar
  in the background (6 m right, 7 m forward). Identical fog (density 0.045) and key light
  (warm sodium, 1.5 energy) to Feel Lab. Player + camera + touch overlay all wired in —
  walk the Stray to each piece and answer the 5 fidelity questions in ART_PIPELINE.md.
  DisplayRoom node group makes it easy to swap in candidate assets.
- Side quest: **Brutalism / *BLAME!* / megastructure research note** —
  `docs/research/brutalism_blame.md`. Covers:
  - *BLAME!* visual grammar: scale ambiguity, darkness as material, fog-as-depth,
    recursive self-similarity, navigation-by-infrastructure logic.
  - Colour palette derived from the manga (cold blue-grey concrete, rare sodium warm,
    biolume cyan in deep layers). Confirms the current `mat_concrete` / `mat_concrete_dark`
    albedo values are correct.
  - Brutalist architecture: béton brut honesty, mass over surface, expressed structure,
    geometric repetition with subtle variation.
  - Megastructure hierarchy: mega-column → floor slab → service run → habitation volume
    — maps directly to the compression/release procession pattern in LEVEL_DESIGN.md.
  - 10 concrete implications for Project Void (cold palette, darkness as architecture,
    Stray red as sole warm anchor, multi-scale kit, expressed structure, service-run
    claustrophobia, column-array depth shots, "failed program" props, no skybox, vertical
    axis primary).
  - INDEX.md updated; "Brutalism / BLAME! / megastructure" section populated.
- Throttle note: 8 iterations since last human direction (soft throttle). Both items
  are non-destructive and produce infrastructure for the next stage (style checking,
  level design) rather than new feature surfaces.
- Perf: no runtime change this iteration.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/brutalism_blame.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-YdzrG` — iter 7: controller kinematics unit tests + mobile perf research

- Primary: **Controller kinematics unit tests (PLAN P1).** `tests/test_controller_kinematics.gd`
  + `tests/test_runner.tscn`. Standalone (no GUT plugin required): open
  `test_runner.tscn`, press F5, read Output panel.
  - 10 test groups, ~40 assertions:
    **Profile defaults** (8 sanity checks on `CP.new()`),
    **Jump height** (h = v₀²/2g in 1.5–5.0 m; floaty ≥ snappy),
    **Gravity band ordering** (after_apex ≥ falling ≥ rising on all 3 profiles),
    **Jump cut math** (threshold checks, boundary conditions),
    **Horizontal interpolation** (move_toward convergence ≤ 30 frames),
    **Air damping** (zero = SMB preservation; floaty > snappy),
    **Terminal velocity** (maxf clamp holds at and past limit),
    **Coyote countdown** (expires, never negative, within 2× expected frames),
    **Buffer countdown** (expires; buffer ≥ coyote across all profiles),
    **Cross-profile invariants** (buffer≥coyote, ratio<1, accel>0 on every shipped profile).
  - GUT migration path documented in file header (`_ready` → `before_all`, `_test_*` → `test_*`).
  - Cannot be run in CI without a Godot binary — marked "on-device pending" for runner integration.
- Side quest: **Godot Mobile renderer performance research** — `docs/research/godot_mobile_perf.md`.
  TBDR tile-based GPU architecture (Adreno/Mali), transparency cost, baked vs dynamic
  lighting tradeoffs, ASTC texture notes, draw-call/triangle budgets, Jolt profiling tips,
  in-game profiling workflow. 8 concrete "Implications for Project Void" (bake lights before
  Gate 1; ≤ 50 draw calls; no alpha on every-frame geometry; no MSAA; etc.).
  INDEX.md updated; "Performance & rendering" section now populated.
- Plan drift fixed: P2 "always-on perf HUD" marked done (was completed iter 3 but still
  listed as open). P2 "Mobile renderer research" marked done.
- Perf: no runtime change this iteration (tests + docs only).
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/godot_mobile_perf.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `iter/touch-ux-research` — iter 6: mobile touch UX research + concrete material kit

- Primary: **Mobile touch UX research note** — `docs/research/mobile_touch_ux.md`.
  Synthesises Dadish 3D Play Store pain points (camera, air control, touch controls
  bar), fixed vs. floating joystick HCI research (floating wins first-session, neutral
  at 5 min), Genshin Impact dead zone parameterisation, Sky: Children of the Light
  zone-split study (50/50 confirmed), Alto's Odyssey one-tap note (not applicable).
  Thumb-reach analysis for 1920×1080 landscape on Nothing Phone 4(a) Pro: comfortable
  reach radius ≈ 580 px from each anchor; no gameplay UI in top 25% of screen;
  jump button minimum radius = 60 px. Assisted profile design targets articulated:
  ledge magnetism (≤ 1.5 m/s impulse within 0.2 m of edge), arc assist (≤ 15% of
  jump_velocity at peak), sticky landing (20% speed reduction for 2 frames on narrow
  platforms), `stick_dead_zone_ratio` = 0.15. New `ControllerProfile` properties
  needed for Assisted: `ledge_magnet_radius`, `ledge_magnet_strength`,
  `arc_assist_max`, `landing_sticky_frames`, `stick_dead_zone_ratio`.
- Side quest A: **Concrete material kit** — `resources/materials/mat_concrete.tres`
  (albedo 0.55/0.55/0.58, roughness 0.85) and `mat_concrete_dark.tres` (0.32/0.32/0.35,
  roughness 0.9) extracted from inline `[sub_resource]` in `feel_lab.tscn` to
  standalone `.tres` files. `feel_lab.tscn` updated to reference them as
  `[ext_resource]`. Gate 1 level authors can now `@export` a material slot and drag
  these in. Remaining: `scenes/levels/kit/` prebuilt platform scenes — deferred to
  art direction approval iteration.
- Side quest B: **`.tres` profile type headers** — all three controller profiles
  (`snappy.tres`, `floaty.tres`, `momentum.tres`) updated from `type="Resource"` to
  `type="ControllerProfile"`. Godot editor now correctly identifies the resource type
  in the inspector.
- Perf: no change — material extraction is load-time reorganisation only.
- Bugs fixed: none.
- New dev-menu controls: none.
- Assets acquired: none.
- Research added: `docs/research/mobile_touch_ux.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-bchl4` — iter 5: reboot animation polish + save-as-profile

- Primary: **Reboot animation fully specced (PLAN P0 item 6).** `_run_reboot_effect()`
  in `player.gd` replaced from scratch:
  - **Step 1 — Death beat**: `_spawn_sparks(death_centre)` fires 12 `ImmediateMesh` line
    segments in random hemispherical directions from the capsule centre, warm orange-yellow
    (`Color(1.0, 0.78, 0.12)`), fade out over 0.45 s via tween, then `queue_free`.
    Gated behind `DevMenu.is_juice_on("particles")`. Material uses
    `TRANSPARENCY_ALPHA` + `no_depth_test = true` so sparks are always visible.
    A death-squish tween (`scale(1.25, 0.25, 1.25)`) fires simultaneously, gated
    behind `DevMenu.is_juice_on("squash_stretch")`.
  - **Step 2 — Dark frame**: hide visual, reset scale to `ONE`, teleport.
  - **Step 3 — Power-on**: scale from `(0.05, 0.05, 0.05)` → `ONE` using
    `EASE_OUT` / `TRANS_BACK` (overshoot then settle = "upright" beat), plus warm
    glow emission. Squash_stretch-gated; falls back to instant-show if off.
  - **Step 4 — Settle**: confirm scale, clear emission, clear `_is_rebooting`.
  - Timing: 12 % / 35 % / 35 % / 18 % of `profile.reboot_duration` (sums to 100 %).
- Side quest: **Save-as-profile button (PLAN P0 item 7).** Dev menu Profile section now
  has a "Save as…" button that reveals an inline `LineEdit + Save + ✕` row.
  On confirm: `_current_profile.duplicate(true)` → add to `_profiles` dict and
  dropdown → select new item → persist to `user://profiles/<name>.tres` via
  `ResourceSaver`. Works in-session; copied `.tres` can be promoted to `res://profiles/`
  manually.
- Dev menu additions: Controller — Respawn subsection with **Reboot dur (s)** and
  **Fall kill Y** sliders (both wired into `_profile_sliders` for bulk-sync on
  profile switch). Now 15 profile sliders total.
- Perf: `_spawn_sparks` creates one `MeshInstance3D` + `ImmediateMesh` + `StandardMaterial3D`
  per respawn (~24 verts × one frame), freed after 0.45 s. Zero draw-call cost at
  rest (all default-OFF in the Juice section). Squash tween runs on `_visual`
  (one Node3D transform), no GPU cost.
- Bugs fixed: none.
- New dev-menu controls: "Reboot dur (s)" and "Fall kill Y" sliders (Controller — Respawn);
  "Save as…" button + inline form (Profile section).
- Assets acquired: none.
- Research added: none this iteration.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-k7sgn` — iter 4: in-world debug viz + character-controller research

- Primary: **In-world debug visualizations (PLAN P0 item 5).** New
  `tools/debug/player_debug_draw.gd` — a `Node3D` added to the Feel Lab that
  draws all overlays with `ImmediateMesh` (`no_depth_test=true`, unshaded,
  vertex-coloured). Four overlays, all default OFF, toggled from Dev Menu →
  Debug viz:
  - **Collision capsule** (cyan) — wireframe capsule matching the physics shape
    (r=0.28, h=0.9). Two rim circles + 4 verticals + XY/ZY hemisphere arcs.
  - **Velocity arrow** (yellow) — line from player centre in velocity direction,
    length proportional to speed (×0.15 scale), chevron arrowhead. Handles
    near-vertical velocity (wall jumps) without divide-by-zero.
  - **Ground normal** (green) — 1.2 m arrow along `get_floor_normal()` when on
    floor, with tick at tip. Hidden when airborne.
  - **Jump arc** (orange) — simulated parabola at 1/30 s steps × 60 frames.
    On floor: preview of a jump from current position. Airborne: shows remaining
    trajectory. Switches gravity band at apex (gravity_rising → gravity_after_apex).
  - Four new dev-menu checkboxes: "Collision capsule", "Velocity arrow",
    "Ground normal", "Jump arc".
- Side quest: **Character controllers research note.** `docs/research/character_controllers.md`.
  Covers SMB grammar (instant accel, velocity preservation, variable jump),
  Mario Odyssey ledge magnetism, A Hat in Time homing-attack as Assisted profile
  model, Pseudoregalia momentum rethink (reduce deceleration, don't raise cap),
  Demon Turf custom-physics rationale (Jolt likely avoids same issue). Key
  implication: Snappy profile values are in the right ballpark; Assisted profile
  should prioritise ledge magnetism (~0.15 m snap radius) over mid-air steering.
- Perf: no new draw calls added to the main render pass. `ImmediateMesh` with
  ≤332 vertices/frame when all four overlays are on, all off by default.
  On-device baseline still pending first human build.
- Bugs fixed: none new.
- New dev-menu controls: Debug viz section — "Collision capsule", "Velocity arrow",
  "Ground normal", "Jump arc" (4 new checkboxes).
- Assets acquired: none.
- Research added: `docs/research/character_controllers.md`; INDEX.md updated.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/gifted-shannon-6LHK6` — iter 3: touch overlay polish + iter-2 carry

- Primary: **Touch overlay polish (PLAN P0 item 5).** `scripts/ui/touch_overlay.gd` fully
  rewritten. Drag-to-place reposition mode (`enter_reposition_mode()` / "Reposition
  controls…" button in dev menu Touch section): drag the red circle to move the jump button,
  drag the yellow handle at its edge to resize, tap a preset button to snap to a thumb-zone
  configuration. Three presets: Default (1720×900, r=95), Closer (1580×900, r=90), Wider
  (1830×950, r=100). Reposition mode also shows the stick-zone divider line live. All
  changes are written to `user://input.cfg` (ConfigFile) on Done and reloaded on startup.
  Dev menu gains a "Touch Controls" section: Reposition button, Jump radius slider, Stick
  zone % slider. `stick_zone_ratio` replaces the hardcoded 0.5 fraction in `_classify()`.
- Bundled: **Carry-forward of iter-2 code from stranded PR #12** (`claude/elegant-lamport-VlWlA`,
  draft with merge conflicts). Iter-2 work now lands cleanly on current main:
  — `tools/debug/hud_overlay.gd` (new): always-on layer-98 CanvasLayer. Perf HUD (FPS +
    frametime) on by default in top-right corner; Velocity+state readout off by default.
    Controlled by `DevMenu.debug_viz_state` and toggled from the Debug viz section.
  — Dev menu controller section expanded from 4 to 13 sliders covering every
    `ControllerProfile` property (gravity bands, air accel/damping, release ratio). Profile
    switching bulk-syncs all sliders via `_profile_sliders` dict — switching Snappy ↔ Floaty
    ↔ Momentum now shows each profile's distinct values immediately.
  — Level section: Time scale × slider (0.25×–2.0×) sets `Engine.time_scale` live.
  — Debug viz section in dev menu: "Perf HUD" and "Velocity + state" checkboxes.
  — Stale "until step 7" camera-frame comment removed from `player.gd`.
- PR #12 closed as superseded by this PR.
- Perf: no new geometry or draw calls. HUD is a Label in a CanvasLayer — CPU cost is
  negligible. On-device baseline still pending first human build.
- Bugs fixed: profile slider mismatch (sliders always showed Snappy values regardless of
  selected profile — now bulk-synced on switch).
- New dev-menu controls: Touch section (Reposition button, Jump radius, Stick zone %);
  Controller section now 13 sliders; Level section (Time scale); Debug viz section (2
  checkboxes); corner HUD always-on.
- Assets acquired: none.
- Research added: none.
- Needs human attention: see "Open questions waiting on you."

### [2026-05-09] — `claude/fix-scheduled-runs-WjNm9` — process fix: auto-merge workflow

- Primary: **Auto-merge GitHub Action.** Added
  `.github/workflows/auto-merge.yml`. Squash-merges any non-draft PR
  carrying the `auto-merge` label, on `opened` / `labeled` /
  `ready_for_review` / `synchronize` / `reopened`. The agent now adds
  the label on PR creation; if the session dies before merge, the
  workflow finishes the job. Removes the dependency on the agent
  staying alive past `gh pr create`.
- Primary: **Iteration startup rules in `docs/CLAUDE.md`.** New
  required sequence at the top of "Git workflow": list your own open
  PRs first; if one already targets the item you'd have picked, check
  out that branch and iterate on it (don't fork a new one) or skip the
  item; if multiple PRs cover the same item, merge the most complete
  one and close the rest. Also added an "End-of-iteration update"
  reminder that PLAN.md + README.md updates ride in the same PR — that
  was the silent failure mode of iter 1.
- Cleanup: 8 duplicate iter-1 PRs (#3–#10) all attacked the same P0
  items (camera occlusion + Floaty profile) because every 2-hour run
  started from a stale `main`. PR #10 was the most complete — squash-
  merged. PRs #3–#9 closed with comments linking to #10.
- Perf: n/a (workflow + docs only).
- Bugs fixed: scheduled-runs duplicate-PR loop.
- Needs human attention: merge **this** PR. It alters the Git workflow
  and so is opened as a draft per the existing exception rule.
- Next likely focus: once on `main`, the next 2-hour run picks the
  current top of `PLAN.md` (smoke test or, if still blocked on human,
  Touch overlay polish / dev-menu debug viz).

### [2026-05-09] — `claude/elegant-lamport-c9ZE9` — iter 1: camera occlusion + profiles

- Primary: **Camera occlusion avoidance** — `camera_rig.gd` now casts a ray from the
  look-at point to the desired camera position each frame
  (`PhysicsDirectSpaceState3D.intersect_ray`); if world geometry blocks the shot the
  camera snaps forward to the hit minus `occlusion_margin` (0.3 m default), floored
  at `occlusion_min_distance` (0.8 m). Player capsule is excluded from the query.
  Script-only change — no `.tscn` restructuring required. Rationale for not using
  `SpringArm3D` logged in `DECISIONS.md`.  
  **Camera params dev-menu section** — 9 new live sliders in the dev menu (distance,
  pitch, lookahead, fall pull, yaw/pitch drag sensitivity, recenter delay/speed,
  occlusion margin). `_build_ui` refactored into per-section helpers; number display
  uses smart precision formatting.
- Side quest: **Floaty + Momentum profiles** — `floaty.tres` (smooth accel,
  generous air, long hang, wide coyote/buffer) and `momentum.tres` (high top speed,
  near-zero ground decel, full horizontal velocity preservation, tighter coyote).
  Both wired into the dev menu Profile dropdown → dropdown now shows
  **Snappy / Floaty / Momentum**. Momentum speed-ramp mechanic (sustained-input
  speed increase) deferred to a later iteration; logged in PLAN.md refactor backlog.
- Perf: no change — no new geometry or draw calls; physics ray cast is O(1).
  On-device baseline still pending first human build.
- Bugs fixed: none new (occlusion was a missing feature, not a bug).
- New dev-menu controls: Camera section — distance, pitch (deg), lookahead,
  fall pull, yaw sens, pitch sens, recenter delay, recenter speed, occl. margin.
  Profile dropdown now shows 3 entries.
- Assets acquired: none.
- Research added: none this iteration.
- Needs human attention: see "Open questions waiting on you."
- Next likely focus: once human opens in Godot 4.6 and fixes any import errors,
  iterate on Snappy feel tuning based on first-feel feedback; then first contrast
  of Floaty vs Momentum.

### [2026-05-08] — `claude/start-project-void-TxIcJ` — kickoff

- Primary: scaffolded the entire Gate 0 surface — folder layout per `CLAUDE.md`, project settings (Mobile renderer, sensor-landscape, ASTC, 60 Hz physics, Jolt 3D, autoloads, input map), Android export preset, docs (PLAN, DECISIONS, JUICE, ASSETS, research INDEX, ANDROID), Feel Lab scene with brutalist primitives + fog + single warm key light + moving platform + four corner pillars for scale, Stray `CharacterBody3D` with the Snappy `ControllerProfile` (coyote 100ms, buffer 120ms, three-band gravity, variable-jump cut, preserved horizontal velocity), dev menu skeleton (profile dropdown + 4 live sliders + juice toggle grid + perf line), camera rig (lookahead, fall pull, drag override, idle recenter), touch overlay (free-floating left stick + right jump button + right-half camera drag, mouse fallback in editor). Everything wired into Feel Lab and runnable from F5.
- Side quest: none (kickoff scope only).
- Perf: not measured — no Godot binary in the kickoff environment; first on-device run is iteration 1's top task.
- Bugs fixed: none (greenfield).
- New dev-menu: profile dropdown, max_speed / jump_velocity / coyote / buffer sliders, six juice checkboxes, fps + frametime + tris + draw-call line.
- Assets acquired: none (placeholders only).
- Research added: `docs/research/INDEX.md` seeded with sections + suggested reads from `CLAUDE.md`.
- Needs human attention: see "Open questions waiting on you."
- Next likely focus: open in Godot 4.6, fix any import errors, run the device checklist in `docs/ANDROID.md`, capture first frametime on Nothing Phone 4(a) Pro, then begin Snappy tuning based on first-feel feedback.

## How to run the current build

In editor: open `project.godot` in Godot 4.x, F5.
On device: see `docs/ANDROID.md` — keystore must be set up locally first.
Dev menu: 3-finger tap on device, F1 in editor.
Feel Lab: open `scenes/levels/feel_lab.tscn` and run.

## Repo map

- `docs/CLAUDE.md` — persistent context and conventions (Claude reads this every iteration)
- `docs/PLAN.md` — rolling work plan, updated each iteration
- `docs/DECISIONS.md` — log of significant choices and why
- `docs/JUICE.md` — catalogue of juice elements and their state
- `docs/LEVEL_DESIGN.md` — level design philosophy and principles
- `docs/ART_PIPELINE.md` — how to swap primitives for real art
- `docs/ANDROID.md` — Android build/export setup
- `docs/research/` — research notes by topic (`INDEX.md` lists them)
- `assets/ASSETS.md` — third-party asset licence and source log
