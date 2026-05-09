# Project Void

Mobile 3D platformer. Brutalist aesthetic. Touch-first. One warm point in a cold world.

---

## Status

| Gate | Name | Status |
|------|------|--------|
| 0 | Foundation | **In progress** |
| 1 | Feel | Blocked on Gate 0 |
| 2 | Level 01 | Blocked on Gate 1 |
| 3 | Camera | Blocked on Gate 2 |
| 4 | Polish | Blocked on Gate 3 |
| 5 | Ship | — |

**Current branch**: `claude/gifted-shannon-RQSwT`

---

## Open questions waiting on you

- **Gate 0 validation**: Please open FeelLab.tscn in the Godot editor and press Play. Verify:
  - Player spawns on the floor, doesn't fall through.
  - WASD + Space moves and jumps (keyboard fallback).
  - Backtick (`` ` ``) opens the dev menu with profile sliders.
  - Camera follows behind the player.
  - Report any errors from the Output panel.
- **Device test**: Export to Android/iOS and validate touch controls (joystick + jump button). Note thumb comfort.

---

## Updates

### 2026-05-09 — Iteration 1 — branch: claude/gifted-shannon-RQSwT
**Primary**: Project foundation — all systems built from scratch.  
**Side quest**: None (first iteration, scope was establishing everything).

**What was built**:
- `ControllerProfile` resource: all movement tunables in one saveable `.tres` file
- `Player.tscn`: CharacterBody3D with coyote time (0.12s), jump buffer (0.15s), variable jump height (hold reduces gravity by 50%), max fall speed 30 m/s
- `GameCamera.tscn`: yaw-follows player facing direction, lerped. No manual orbit needed.
- `TouchControls.tscn`: landscape layout — joystick bottom-left (200×200, 50px margins), jump button bottom-right (200×120, red themed)
- `DevMenu`: dynamically built sliders for all ControllerProfile properties. Toggle with backtick. Real-time profile modification.
- `FeelLab.tscn`: brutalist test scene. Grey fog, concrete floor+platforms, The Stray (red glowing box on highest platform).
- `GameManager` autoload: registers keyboard input actions (WASD, Space, backtick)
- All docs: CLAUDE.md, PLAN.md, DECISIONS.md, JUICE.md, LEVEL_DESIGN.md, research/INDEX.md, ASSETS.md

**Perf snapshot**: on-device pending (editor-only this iteration)  
**Bugs fixed**: N/A (first iteration)  
**New dev-menu controls**: walk_speed, acceleration, friction, air_acceleration, air_friction, base_gravity, jump_velocity, jump_hold_gravity_scale, fall_gravity_scale, max_fall_speed, coyote_time, jump_buffer_time, turn_speed_deg  
**Research added**: None (too early; INDEX.md created with open questions)

---

## Project structure

```
scenes/feel_lab/    ← main playtest scene (run this)
scenes/player/      ← Player.tscn
scenes/camera/      ← GameCamera.tscn
scenes/ui/          ← TouchControls.tscn, DevMenu.tscn
scripts/            ← GDScript source
resources/profiles/ ← ControllerProfile .tres presets
docs/               ← design docs, research
assets/             ← ASSETS.md (third-party tracking)
tests/unit/         ← GUT tests (GUT addon not yet installed)
```

---

## Controls

| Input | Action |
|-------|--------|
| WASD | Move |
| Space | Jump (hold for higher jump) |
| `` ` `` (backtick) | Toggle dev menu |
| Touch joystick (left) | Move |
| Touch button (right) | Jump |
