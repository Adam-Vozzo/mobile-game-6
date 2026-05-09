# Project Void — Rolling Plan

Last updated: 2026-05-09

---

## Current gate: Gate 0 — Foundation

**Done when**: Player moves, jumps, lands in FeelLab. Touch controls functional. Dev menu exposed.

### In progress
- [ ] Human validates FeelLab opens without errors (on-device pending)
- [ ] Human validates touch controls responsive on actual device

### Next up (Gate 0 completion)
1. **GUT addon setup** — install GUT, write `test_player_jump.gd` (coyote time, buffer)
2. **FeelLab polish** — add platform edge markers (thin red edge trim?), spawn indicator
3. **Performance baseline** — run profiler, capture frametime/draw-calls in FeelLab

### Gate 1 queue (feel approval)
1. **Juice pass** — implement land squash, jump stretch, trail (see JUICE.md)
2. **Variant profiles** — save `floaty.tres` and `snappy.tres` for human comparison
3. **Profile dropdown** — add profile selector to dev menu top
4. **Camera feel** — expose distance/height/lerp_speed in dev menu camera section

### Gate 2 queue (Level 01)
1. Level 01 blocked geometry pass (human approves layout first)
2. CameraHint system (Area3D triggers scripted camera position)
3. Stray collectible interaction (player enters area → collected)
4. Goal trigger (Stray collected + reach exit → win)

### Refactor backlog
- Extract platform builder helper (avoid duplicating StaticBody+Collision+Mesh nodes per platform)
- Consider `CameraRig` wrapper if camera needs orbit for non-auto sections

---

## Done

### Iteration 1 — 2026-05-09 (branch: claude/gifted-shannon-RQSwT)
- Project foundation: directory structure, all docs, project.godot configured
- `ControllerProfile` resource + `default.tres`
- `Player.tscn` + `player.gd`: CharacterBody3D, coyote time, jump buffer, variable jump height
- `GameCamera.tscn` + `game_camera.gd`: yaw-follow camera
- `TouchControls.tscn` + `virtual_joystick.gd` + `touch_controls.gd`: landscape touch layout
- `DevMenu.tscn` + `dev_menu.gd`: dynamic sliders, toggled with backtick
- `FeelLab.tscn` + `feel_lab.gd`: full test scene with brutalist geometry, fog, The Stray
- `game_manager.gd` autoload: registers keyboard input actions
- All documentation: CLAUDE.md, PLAN.md, DECISIONS.md, JUICE.md, LEVEL_DESIGN.md, research/INDEX.md, ASSETS.md

---

## Blocked / needs human
- Gate 0 → Gate 1 transition: human must test feel on actual device
- Level 01 layout: human approves before implementation
