# Camera Systems in 3D Mobile Platformers

Researched 2026-05-08 while implementing SpringArm3D collision avoidance.

---

## Sources

- Dadish 3D Play Store reviews (2024–2026) — user complaints catalogue
- Super Mario Odyssey camera analysis, Digital Foundry + multiple GDC presentations
- Godot 4 SpringArm3D documentation
- GDC 2014 — "The Cameras of Dark Souls" (Taro Omiya)
- Mark Brown GMTK — "How Camera Work in World of Warcraft" (2015)
- Genshin Impact touch control community discussions

---

## Core problem: mobile 3D camera is the hardest single UX problem

The Dadish 3D reviews are the clearest data set. Exact quotes and paraphrases:

- "Camera is always unlocked outside of chase sequences, leading to the player fiddling constantly"
- "Touch controls are serviceable but you definitely want a controller"
- "I wish the camera just followed me more"

Pattern: players on mobile have limited cognitive bandwidth for camera management. A second virtual stick (right-stick camera) fails because it competes for the same thumb real estate as jump and action buttons. Dadish 3D's right-drag implemented as a *zone* (right half of screen) rather than a discrete stick is better, but still requires conscious input.

---

## What the best auto-cameras do

### Coyote follow / lazy follow (Super Mario Odyssey)

The camera doesn't track Mario 1:1. It trails behind with a dead zone. When Mario exits the dead zone (moved far enough in a direction), the camera catches up. This means casual running feels effortless. Only precision segments (narrow ledges, tight turns) ever require manual input.

**Implication for Void**: lookahead_lerp = 4.0 (current) is quite responsive. Could try a lower value (1.5–2.5) for a lazier, more cinematic feel on the test device. A two-tier system (lazy at low speed, responsive at high speed) might be optimal.

### Velocity-predictive framing (Dark Souls, Odyssey)

Camera leads the player's velocity direction, not just their position. Player feels like the camera "knows" where they're going. This is the lookahead_distance feature in our rig.

**Implication for Void**: current implementation is velocity-vector lookahead. More sophisticated version: also lerp toward a `CameraHint` node when the player enters a defined volume (already planned as a PLAN.md item for Gate 1).

### Hard-lock during key moments

Some games briefly lock the camera during a big jump, wall-slide initiation, or landing to frame the action. "Camera cinematic beat" as punctuation for player actions.

**Implication for Void**: at Gate 1, consider brief camera lock on large jumps (player is airborne and velocity exceeds threshold). Would eliminate most camera fiddle during precision sequences. Low-risk to add to `CameraHint` system.

### SpringArm occlusion avoidance — dos and don'ts

- **Do** exclude the player's own collision body from the spring arm. Without this, the capsule constantly reads as an obstacle and the arm shortens to zero when you run at walls.
- **Do** add a margin (0.1–0.3 m) so the camera doesn't sit flush against geometry.
- **Don't** use a large collision shape for the spring arm — it shortens prematurely when the player is near walls even if the line of sight is clear. A ray cast (default, no shape set on SpringArm3D) is best for third-person platformers. Reserve shapes for over-the-shoulder shooters where shoulder clipping matters.
- **Do** add a soft zoom-in (lerp distance to a closer value) when the arm is shortened so the camera transitions feel less abrupt than a sudden jerk. Queued in PLAN.md.

### Touch input specific

- Right-side drag zone (Dadish 3D approach): better than a second stick because it doesn't require a precise thumb target. The whole right 40% of the screen works.
- Auto-recenter after 1–2 seconds of no drag: critical. Users who stop manually adjusting should get a "snap back" so they stop thinking about the camera. Our current idle_recenter_delay = 1.2s is in the right range.
- Sensitivity slider (CLAUDE.md requirement): users have widely different sensitivity preferences. Build this in before first device test, not after. It's easy to forget.

---

## Genshin Impact touch camera

Genshin's right-stick equivalent is a dead zone circle that feels physically like an analog stick but is just a drag area. Their approach:
- Small dead zone at the touch point (prevents accidental micro-rotations)
- Acceleration curve: slow at low drag displacement, faster at high displacement
- Auto-recenter: slow, delay > 2s, only activates when both thumbs are off
- No camera collision avoidance in open world (too complex), but dungeons use scripted camera hints

**Implication for Void**: our drag sensitivity is linear. A small dead zone (< 5px) and a mild acceleration curve on the drag delta would feel more physical. Low priority but worth adding to the camera params as a tunable.

---

## Implications for Void (summary)

1. **Immediate** (done this iteration): SpringArm3D with ray cast (no shape), player excluded, margin = 0.2m. ✓
2. **Next camera iteration**: add soft distance lerp when arm is shortened (instead of instant jump). Log in PLAN.md.
3. **Gate 1**: `CameraHint` volumes with configurable yaw override and distance override. The level author can force a framing during key platforming sequences.
4. **Before first device test**: add touch drag dead zone + mild acceleration curve.
5. **Settings menu (Gate 3)**: sensitivity slider, invert-Y option.
6. **Consider**: lazy follow with two-tier lerp speed (slow below 2 m/s, fast above 6 m/s).
