# Project Void

A mobile 3D platformer. Brutalist megastructure inspired by *BLAME!*. Controller feel inspired by *Super Meat Boy*. Accessibility inspired by *Dadish 3D*. You play as the Stray — a small lost robot in a vast machine-built world. Godot 4.x, Android, landscape.

## Status

Current gate: **Gate 0 — Feel Lab**
Last iteration: 2026-05-09 — process fix (auto-merge workflow + iteration-startup rules)
Test device build: not yet — hand-authored scenes pending first Godot 4.6 import; see Open questions
Performance: not yet measured on Nothing Phone 4(a) Pro
Throttle level: normal — 2 iterations since last human direction

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
