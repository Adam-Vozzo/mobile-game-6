# Project Void

A mobile 3D platformer. Brutalist megastructure inspired by *BLAME!*. Controller feel inspired by *Super Meat Boy*. Accessibility inspired by *Dadish 3D*. You play as the Stray — a small lost robot in a vast machine-built world. Godot 4.x, Android, landscape.

## Status

Current gate: **Gate 0 — Feel Lab**
Last iteration: 2026-05-08 — iter 1 (SpringArm3D camera collision avoidance, Floaty + Momentum profiles, camera dev-menu params, camera research note)
Test device build: not yet — first on-device build still pending human with Godot 4.6
Performance: not yet measured on Nothing Phone 4(a) Pro
Throttle level: normal — 1 iteration since last human direction

If you only read one section, read **Open questions waiting on you** below.

## Open questions waiting on you

Things Claude can't decide alone, or where it's stalled and needs direction. Each is blocking some piece of forward progress.

- [ ] **Open the project in Godot 4.6 and run the on-device first-run checklist in `docs/ANDROID.md`.** This is the only thing that will catch syntax mistakes in any of the hand-authored `.tscn`/`.tres` files. If anything fails, paste the Output panel error and Claude will fix it next iteration.
- [ ] **First feel of Snappy on device.** Once the build runs, hold the phone and play for 60 seconds. Note: does the jump arc feel right? Coyote forgiving enough? Buffer too sticky? Anything you flag goes into iteration 1's tuning pass.
- [ ] **Confirm the auto-merge git workflow is what you want long-term.** Decided already in `docs/DECISIONS.md` for kickoff after your "go ahead and feel free to merge" — flag here only because it's the kind of thing that's easy to forget about until it surprises you.

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
- [x] Dev menu with live tunables (controller + camera sections)
- [x] Spring-arm camera with lookahead and right-drag override, SpringArm3D collision avoidance
- [x] Touch input: virtual stick + jump, repositionable _(drag-to-place UI still queued)_
- [x] 3 controller profiles: Snappy, Floaty, Momentum _(Assisted queued — needs player.gd work)_
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

### [2026-05-08] — `claude/elegant-lamport-Nvnn3` — iter 1 — SpringArm camera + profiles

- Primary: **SpringArm3D collision avoidance on camera rig.** Camera was previously direct-positioned (no wall occlusion). Now uses a `SpringArm3D` (ray cast, World collision mask only, player excluded from cast, 0.2 m margin) so the camera never clips through walls or floors. The rig orients the spring arm's +Z toward the camera offset direction each frame; SpringArm3D shortens automatically on contact. Camera `look_at` timing is one frame behind the spring arm's position update (parent processes before child), which is imperceptible on smooth motion. `wall_margin` is now a dev-menu-wired export. Also added `wall_margin` to `_on_camera_param_changed` handler. `_spring_arm.add_excluded_object` called in `_ready` to prevent player capsule from triggering occlusion.
- Side quest: **(a) Floaty + Momentum profiles.** `resources/profiles/floaty.tres` — lower gravity (22/30/42 m/s²), slower acceleration, more generous coyote + buffer, slight air damping for Dadish-leaning feel. `resources/profiles/momentum.tres` — higher top speed (12 m/s), slow ground ramp (30 m/s²) to reward sustained input, tight coyote + buffer windows. True non-linear ramp (curve-based) noted as debt in DECISIONS.md and PLAN.md. **(b) Camera params section in dev menu** — 5 sliders: distance, pitch, lookahead, fall-pull, yaw sensitivity. Defaults mirror camera_rig.gd `@export` values. The overlay now wraps in a `ScrollContainer` so it doesn't overflow on small screens. **(c) Research note** — `docs/research/camera_mobile_3d.md`: Dadish 3D pain-point data, Odyssey lazy-follow analysis, SpringArm best practices (no collision shape on arm for platformers, exclude player, add margin), Genshin touch drag patterns. Implications noted for future iterations.
- Perf: not yet measured — on-device pending. No draw-call or geometry changes in this iteration; perf delta expected ~0 (spring arm does a physics ray each frame, negligible on mobile).
- Bugs fixed: none (preventive — camera would have clipped walls in any Gate 1 geometry).
- New dev-menu controls: Camera section → Distance (2–15), Pitch (0–80°), Lookahead (0–5), Fall pull (0–1), Yaw sens (0.0001–0.02). Profile dropdown now includes Floaty and Momentum.
- Assets acquired: none.
- Research added: `docs/research/camera_mobile_3d.md`.
- Needs human attention: see "Open questions waiting on you."
- Next likely focus: on-device build + first feel comparison of Snappy vs Floaty vs Momentum; dev menu debug-viz toggles; touch overlay drag-to-place reposition mode.

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
