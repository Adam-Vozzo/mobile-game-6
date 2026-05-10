# Project Void

Mobile 3D platformer — Godot 4.6 — Android/iOS.
Guide **The Stray** through cold brutalist megastructures.

**Current gate**: Gate 0 — Foundation

---

## Status

| Area | Status |
|------|--------|
| Player movement | ✅ Implemented (iter 1) |
| Touch input | ✅ Implemented (iter 1) |
| Camera rig | ✅ Implemented (iter 1) |
| Dev menu | ✅ Implemented (iter 1) |
| Feel Lab scene | ✅ Implemented (iter 1) |
| Player feel tuned | ⏳ Pending human review |
| Level 1 | ⏳ Gate 2 |
| Juice / Polish | ⏳ Gate 3 |

---

## Roadmap

- [x] Gate 0 — Foundation _(in progress — iter 1 complete, needs on-device test + feel verdict)_
- [ ] Gate 1 — Core Feel
- [ ] Gate 2 — Level 1 Draft
- [ ] Gate 3 — Polish & Juice
- [ ] Gate 4 — Ship Ready

---

## Open questions waiting on you

1. **Feel verdict needed (Gate 0 → Gate 1)**: Once you run the Feel Lab on device, does the jump arc / movement feel right? The key tunables are all in the dev menu (Physics section). Let me know what to change or confirm it feels good.
2. **The Stray's appearance**: Currently a capsule placeholder. What should The Stray look like? A rough description or reference image is enough for me to design a simple placeholder mesh.
3. **On-device test**: I cannot export to Android/iOS from this environment. Please export and test, then report back frametime from the in-game dev menu HUD.

---

## Updates

### 2026-05-10 — Iteration 1 — branch: `claude/gifted-shannon-cm8r3`

**Primary**: Bootstrap — project documentation, player prototype, feel lab, dev menu
**Side quest**: Research note — mobile touch controls for 3D platformers
**Perf snapshot**: No on-device data yet (on-device test pending)
**Draw calls**: N/A (not measured)
**Bugs fixed**: N/A (first iteration)
**New dev-menu controls**:
  - Physics / Walk Speed (player walk_speed)
  - Physics / Jump Velocity (player jump_velocity)
  - Physics / Gravity Rise (player gravity_rise)
  - Physics / Gravity Fall (player gravity_fall)
  - Physics / Coyote Time (player coyote_time)
  - Physics / Jump Buffer Time (player jump_buffer_time)
  - Camera / Spring Length (camera spring_length)
  - Camera / Follow Speed (camera follow_speed)
  - Camera / Height Offset (camera height_offset)
  - Camera / Pitch Angle (camera pitch_angle)
  - Camera / Yaw Sensitivity (camera yaw_sensitivity)
  - Debug / Show Velocity (HUD toggle)
  - Debug / Show FPS (HUD toggle)
**Research added**: `docs/research/mobile_touch_controls.md`
**Needs human attention**:
  - Feel verdict (run Feel Lab, report if jump/movement feels right)
  - The Stray appearance (placeholder capsule — confirm or redirect)
  - On-device export test (frametime, touch latency report)

---

## Dev setup

1. Open `project.godot` in Godot 4.6
2. Open `scenes/levels/feel_lab.tscn` and run (F5 or play button)
3. On desktop: WASD to move, Space to jump, F1 to toggle dev menu
4. On mobile: virtual joystick (left) + jump button (right)
5. Triple-tap top-left corner to toggle dev menu on device

## Project structure

```
docs/               Design docs, plans, decisions, research
scenes/             Godot scenes (.tscn)
scripts/            GDScript source
resources/          Godot resources (.tres)
assets/             Binary assets (models, audio, textures)
tests/              GUT tests
```
