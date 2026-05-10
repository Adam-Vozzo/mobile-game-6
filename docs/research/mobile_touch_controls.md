# Research: Mobile Touch Controls for 3D Platformers

**Date**: 2026-05-10
**Iteration**: 1
**Status**: Complete

---

## What I looked at

- Super Mario Run (Nintendo, 2016) — auto-run one-touch model
- Sky: Children of the Light (thatgamecompany, 2019) — virtual joystick + camera drag
- Alto's Odyssey: The Lost City (Snowman, 2022) — one-touch on-rail
- Minigore 2 / Oceanhorn (twin-stick arcade) — dual joystick reference
- GDC talks: "Making Satisfying Mobile Games" (various), Gamasutra articles on virtual joystick UX
- Dadish 3 (Thomas Young, 2023) — 2D but applicable joystick sizing/placement

---

## Key findings

### 1. Virtual joystick placement
- **Bottom-left, floating**: most comfortable. Fixed joystick (always same position) vs floating (appear where thumb lands). Floating reduces reaching but requires dead-zone to avoid accidental activation.
- Radius of 70–90 CSS px (at 1× density) is the sweet spot. Too small = miss inputs. Too large = overlaps action buttons.
- **The joystick knob should never exceed the rim** — visual cue that input is clamped, prevents "stretching" phantom inputs.

### 2. Jump button placement
- Bottom-right is universal convention. Sized larger than typical buttons (~80–100 px diameter).
- **One jump button is enough.** Multi-button layouts (jump + dodge + attack) require menu/tutorial investment. For Gate 0–1: single jump, single action.
- Jump should respond on `touch_down`, not `touch_up`, to minimize perceived latency.

### 3. Camera control
- Most 3D mobile platformers that do well **minimize required camera interaction**. Auto-frame is king.
- When manual camera is offered: drag on right side of screen (not joystick side). One-finger drag for yaw, two-finger drag for pitch (or no pitch).
- Sensitivity: ~0.3–0.5 degrees per pixel for yaw feels natural at 1080p. Lower for smaller screens.

### 4. Input feel & latency
- Touch input on Android has 16–50 ms latency depending on device. Can't beat it — minimize intermediate state.
- Don't use Godot's `InputEventAction` for virtual joystick — process `InputEventScreenTouch`/`InputEventScreenDrag` directly in the joystick script and write to an autoload. This removes one layer.
- **Jump buffer** (100–150 ms) is especially important on mobile because thumb lift/press is less precise than a keyboard key. Forgiveness windows feel better, not cheesier.

### 5. Game feel: gravity and jump arc
- All reference games surveyed use **asymmetric gravity**: slower rise, faster fall. Ratio 1:1.3 to 1:2.
- Super Mario 3D Land (3DS, 2011) used ~1:1.4. Widely cited as the gold standard for handheld 3D platforming.
- Coyote time (100–150 ms) is standard. Feels forgiving without being exploitable.
- **Hold-to-extend-jump** is optional but loved: releasing jump early cuts the arc. Slightly complex to implement cleanly; can be added in Gate 1.

### 6. Screen real estate
- At 1080×2400 (portrait) = 2400×1080 (landscape): safe thumb zone is roughly bottom 350 px on each side.
- Center 60% of screen should be unoccupied by persistent UI — that's the player's view.
- FPS counter and dev indicators: top-right corner (least thumb-trafficked area in landscape).

---

## Implications for Project Void

1. **Use floating joystick**: activates where the left thumb lands, within a defined zone. Reduces reaching fatigue during long sessions.
2. **Jump on touch_down**: implemented in InputManager directly from `InputEventScreenTouch`.
3. **Jump buffer = 100 ms, coyote = 120 ms**: implemented in player.gd. Both exposed in dev menu.
4. **Gravity ratio = 28 rise / 40 fall** (~1:1.43): matches Mario 3D Land ratio. Exposed in dev menu.
5. **Camera drag on right half**: yaw only, 0.3 deg/px sensitivity. No required camera input.
6. **Single jump button for Gate 0–1**: add action/dodge in Gate 2+ if needed.
7. **Joystick radius = 80 px at 1080px height**: scale with viewport height for DPI independence.

---

## Sources / further reading

- https://www.gamedeveloper.com/design/the-basics-of-mobile-game-controls (general)
- GDC 2019: "Physics-Based Character Controllers" (Valve) — coyote/buffer techniques
- "Game Feel" (Steve Swink) Ch. 5: input responsiveness
