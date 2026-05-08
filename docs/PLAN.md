# Project Void — Rolling Plan

## Current Gate: Gate 0 — Feel Lab

### In Progress

- [x] Project initialised: Godot 4.6, Mobile renderer, ASTC, arm64 Android preset
- [x] Folder structure created
- [x] ControllerProfile resource (Snappy, Floaty, Momentum, Assisted)
- [x] CharacterBody3D player — coyote time, jump buffer, variable jump, horizontal velocity preservation, instant respawn
- [x] Spring-arm camera — lookahead, right-drag manual override, auto-recenter
- [x] Touch input — virtual stick (left), jump button (right)
- [x] Dev menu skeleton — profile dropdown, live sliders, juice toggle stubs, debug viz toggles
- [x] Feel Lab scene — brutalist primitives, fog, warm light, varied platforms, slope, wall, moving platform
- [ ] Android export build verified on test device (Nothing Phone 4(a) Pro)
- [ ] Controller feel approved by human on device

### Gate 0 Queue (remaining)

1. **On-device test** — export APK, install, verify touch controls and feel on Nothing Phone 4(a) Pro. Blocked until device is available.
2. **Camera polish** — CameraHint nodes for Feel Lab, auto-recenter timing tuning.
3. **Profile variants** — complete Floaty, Momentum, Assisted profiles with tuned values (needs on-device feel data from Snappy first).
4. **Reboot animation** — Stray placeholder reboot effect: red flash → dark frame → fade in. Currently a stub.
5. **Touch repositioning** — UI to drag/resize virtual stick and jump button.

### Gate 1 Queue (not started — needs Gate 0 green-light)

- Style guide approval (primitive → real art)
- Level design doc for Vertical Slice level (parti, procession, double-reading)
- Greybox level in Feel Lab primitives
- Checkpoint system
- Attempt-replay ghost trails (SMB-style)
- One enemy archetype
- One collectible type
- Win state / results screen

### Refactor Backlog

- Touch input: move from polling to event-driven InputEvent handling
- Dev menu: extract slider factory into a helper to reduce duplication
- ControllerProfile: add curve resources for gravity arcs (replaces multiplier pair)

### Done

- Initial Godot 4.x project
- Android export preset for arm64-v8a
- ETC2/ASTC VRAM compression enabled
- Design docs committed (CLAUDE.md, LEVEL_DESIGN.md, ART_PIPELINE.md)
- PLAN.md, DECISIONS.md, JUICE.md, ANDROID.md, ASSETS.md, research/INDEX.md created
- ControllerProfile resource class + four profile .tres files
- Player CharacterBody3D: coyote, buffer, variable jump, horiz vel, respawn
- Spring-arm camera with lookahead
- Touch input: virtual joystick + jump button
- Dev menu: profile dropdown + sliders + debug toggles
- Feel Lab scene: brutalist arena
- project.godot: autoloads, input map, landscape, 60fps
