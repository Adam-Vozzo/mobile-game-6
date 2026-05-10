# PLAN.md — Project Void

_Rolling plan. Newest gate first. Done items at bottom._

---

## Current Gate: 0 — Foundation

Goal: player moves, camera follows, Feel Lab runs without errors, dev menu live with tunables.

### Queue (priority order)

1. **[DONE — iter 1]** Bootstrap project: docs, player prototype, feel lab, dev menu skeleton
2. **Tune player feel** — coyote time, jump arc, ground friction. Add more Feel Lab platforms.
3. **Camera polish** — test auto-frame on edge cases (narrow corridor, under platform). Tune spring length.
4. **Touch input hardening** — test joystick dead zone, multi-touch correctness, screen edge cases.
5. **On-device test pass** — export to Android, check frametime, touch input latency.

### Refactor backlog

- DevMenu: replace hardcoded registrations with generic registration API (already done in iter 1, but needs broader adoption)
- Consider `ControllerProfile.tres` resource for grouping feel tunables — needed before Gate 1

### Blocked / needs human

- Gate 0 → Gate 1 transition: **needs human feel verdict**

---

## Upcoming: Gate 1 — Core Feel

- Human approves movement + jump feel
- All tunables exposed in dev menu with sensible ranges
- `ControllerProfile.tres` per named feel preset (at least: Default, Floaty, Snappy)
- On-device latency test documented

## Upcoming: Gate 2 — Level 1 Draft

- First level: 3–5 minute play-through
- Platforms, voids, at least one CameraHint volume
- Level design guided by LEVEL_DESIGN.md principles
- Brutalist set dressing (grey CSG + fog, no textures yet)

## Upcoming: Gate 3 — Polish & Juice

- Juice pass (landing squash, trail, footstep dust)
- Ambient sound layer
- Death / respawn flow
- UI polish

## Upcoming: Gate 4 — Ship Ready

- Performance certified: stable 60 fps on mid-tier Android
- Store assets (icon, screenshots, description)
- Export presets finalised

---

## Done

### Iteration 1 — 2026-05-10
- Bootstrapped project documentation (CLAUDE.md, PLAN.md, DECISIONS.md, JUICE.md, LEVEL_DESIGN.md)
- Implemented player CharacterBody3D with coyote time, jump buffering, variable gravity
- Implemented InputManager autoload (touch + keyboard fallback)
- Implemented VirtualJoystick + jump button UI
- Implemented CameraRig (SpringArm3D, auto-follow, manual yaw swipe)
- Implemented DevMenu with registration API (float, bool, action)
- Implemented HUD (FPS, velocity)
- Created Feel Lab scene
- Research note: mobile touch controls for 3D platformers
