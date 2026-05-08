# Project Void

A mobile 3D platformer. Brutalist megastructure inspired by *BLAME!*. Controller feel inspired by *Super Meat Boy*. Accessibility inspired by *Dadish 3D*. You play as the Stray — a small lost robot in a vast machine-built world. Godot 4.x, Android, landscape.

## Status

Current gate: **Gate 0 — Feel Lab**
Last iteration: 2026-05-08 — iter/profiles-camera-devmenu (Floaty + Momentum profiles, camera collision avoidance, full dev menu expansion, mini perf HUD)
Test device build: not yet — hand-authored files; first on-device build remains the top priority
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
- [x] Dev menu skeleton with live tunables
- [x] Spring-arm camera with lookahead and right-drag override _(collision avoidance: ray-cast arm shortening)_
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

### [2026-05-08] — `claude/elegant-lamport-mZ1ip` — profiles, camera collision, dev menu expansion

- Primary: (a) **Floaty + Momentum controller profiles** (`resources/profiles/floaty.tres`, `momentum.tres`) — both ready in the dev menu dropdown for human side-by-side feel test. Floaty: low gravity (22/38/48 m/s²), generous coyote/buffer, slow accel; Momentum: high top speed (14 m/s), slow decel, tight windows. (b) **Camera collision avoidance** — replaced the direct-position camera with a `PhysicsRayQueryParameters3D` ray cast each frame in `_process`; if the ray hits world geometry the camera pulls forward by `collision_margin` (0.15 m). No SpringArm3D node needed — all in GDScript, one process step, no frame delay. Also added `fov` as a live camera export. (c) **Dev menu expansion** — added full Camera section (distance, pitch, FOV, lookahead, vertical pull, yaw/pitch sensitivity, recenter delay/speed); expanded Controller section with gravity-rising, gravity-falling, gravity-apex, and release-ratio sliders; all three profiles in the profile dropdown; wrapped the panel in a ScrollContainer for small screens. (d) **Mini perf HUD** — always-visible top-right corner label (fps, frametime, tris, draw calls) managed by DevMenu autoload, independent of dev menu open/close; toggled via "Toggle Perf HUD" button.
- Side quest: Fixed `feel_lab.gd` spawn transform coordination — now calls `player.set_spawn_transform()` after repositioning so respawns go to the marker, not the player's .tscn origin.
- Perf: not measured — no Godot binary in environment; on-device pending.
- Bugs fixed: spawn transform not propagated from feel_lab → player (silent in Gate 0 since marker == .tscn origin, but would break if marker moved).
- New dev-menu controls: Camera section (9 sliders), additional controller sliders (gravity × 3, release ratio), Toggle Perf HUD button, Floaty + Momentum in profile dropdown, mini always-visible perf HUD.
- Research added: none this iteration.
- Needs human attention: see "Open questions waiting on you."
- Next likely focus: open in Godot 4.6, fix any import errors, run the device checklist in `docs/ANDROID.md`, then feel Snappy vs Floaty vs Momentum on the Nothing Phone 4(a) Pro.

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
