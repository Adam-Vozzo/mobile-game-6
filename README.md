# Project Void

A mobile 3D platformer. Brutalist megastructure inspired by *BLAME!*. Controller feel inspired by *Super Meat Boy*. Accessibility inspired by *Dadish 3D*. You play as the Stray — a small lost robot in a vast machine-built world. Godot 4.x, Android, landscape.

## Status

Current gate: **Gate 0 — Feel Lab**
Last iteration: [date/time] — [one-line summary]
Test device build: [date of last successful on-device run]
Performance: [frametime ms / draw calls] on Nothing Phone 4(a) Pro
Throttle level: [normal / soft / hard] — [N iterations since last human direction]

If you only read one section, read **Open questions waiting on you** below.

## Open questions waiting on you

Things Claude can't decide alone, or where it's stalled and needs direction. Each is blocking some piece of forward progress.

- [ ] [example: "Approve Snappy as default profile after device feel test?"]
- [ ] [example: "Pick Gate 2 biome focus from research/biome-options.md"]
- [ ] [example: "Hard throttle reached — choose next direction: A) start Gate 1 art pass, B) push controller variants, C) something else"]

## Roadmap

```
[ Gate 0: Feel Lab ]──[ Gate 1: Vertical Slice ]──[ Gate 2: Content Spine ]──[ Gate 3: Polish & Ship ]
       ▲
   you are here
```

### Gate 0 — Feel Lab

Goal: one scene, one character controller, fully instrumented and tunable.

- [ ] Feel Lab test arena (brutalist primitives, fog, single warm light)
- [ ] CharacterBody3D player (the Stray) with Snappy profile
- [ ] Coyote, buffer, variable jump, preserved horizontal velocity
- [ ] Dev menu skeleton with live tunables
- [ ] Spring-arm camera with lookahead and right-drag override
- [ ] Touch input: virtual stick + jump, repositionable
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

### [YYYY-MM-DD HH:MM] — `iter/<branch-name>`

- Primary: [what was done]
- Side quest: [or "none"]
- Perf: [frametime ms, draw calls, Δ from previous]
- Bugs fixed: [list or "none"]
- New dev-menu: [list or "none"]
- Assets acquired: [list or "none"]
- Research added: [list or "none"]
- Needs human attention: [list or "none"]
- Next likely focus: [1 line]

## How to run the current build

In editor: open `project.godot` in Godot 4.x, F5.
On device: see `docs/ANDROID.md` — keystore must be set up locally first.
Dev menu: 3-finger tap on device, F1 in editor.
Feel Lab: open `scenes/levels/feel_lab.tscn` and run.

## Repo map

- `docs/CLAUDE.md` — persistent context and conventions (Claude reads this every iteration)
- `docs/ITERATE.md` — the iteration loop prompt
- `docs/PLAN.md` — rolling work plan, updated each iteration
- `docs/DECISIONS.md` — log of significant choices and why
- `docs/JUICE.md` — catalogue of juice elements and their state
- `docs/LEVEL_DESIGN.md` — level design philosophy and principles
- `docs/ART_PIPELINE.md` — how to swap primitives for real art
- `docs/ANDROID.md` — Android build/export setup
- `docs/research/` — research notes by topic (`INDEX.md` lists them)
- `assets/ASSETS.md` — third-party asset licence and source log
