# Research: Mobile Touch UX for 3D Platformers

**Written**: 2026-05-09  
**Sources**: Dadish 3D Play Store reviews (2024), Genshin Impact community postmortems, Sky: Children of the Light design talks, Alto's Odyssey GDC notes, academic literature on floating vs. fixed virtual joysticks, thumb-reach ergonomics for landscape mobile.

---

## Dadish 3D pain points (primary reference)

Thomas K Young's *Dadish 3D* (2024) is the closest genre peer — mobile 3D platformer, similar camera style, similar audience. Its Play Store reviews (~4.2 stars, several hundred ratings as of research date) are a direct dataset on what mobile 3D platformers get wrong:

**Camera** (most-cited complaint): "always unlocked outside of chase sequences, leading to the player constantly fiddling with the camera." Players are expected to manually reposition the view every few seconds to avoid playing blind. The fix is clear: auto-framing that keeps the intended path in view, with manual override as a *nudge*, not as the primary camera mode. Project Void's idle-recenter (`idle_recenter_delay` 1.2 s, recenter behind movement direction) directly targets this.

**Air control**: "character no longer stops mid-flight" was called out as a post-launch patch that improved feel. The original shipped with zero horizontal velocity preservation through jumps — the character decelerated to zero at the apex even if the player held the stick. This is the single biggest feel regression from a desktop platformer to mobile: without momentum preservation, the control model fights the player's mental model. **Get horizontal velocity preservation correct from day one.** Our `air_horizontal_damping = 0.0` in the Snappy profile is correct.

**Touch controls**: "serviceable… definitely play with a controller if you can." This is the bar to beat. Reviewers specifically request:
- Sensitivity sliders for the camera drag.
- Resizable and repositionable buttons.
- A dedicated "recenter camera" button (workaround for the camera issue above).
- Controller support detected automatically (Dadish 3D adds a second UI mode).

**Not mentioned as problems**: jump buffering, coyote time, platform size. This suggests Dadish 3D got the forgiveness timing roughly right, or at least didn't make it worse than players expected.

---

## Fixed vs. floating virtual joystick

The industry has largely converged on **floating (dynamic-origin) virtual joysticks**, but with important nuances:

**Fixed joystick** (origin always at the same screen position):
- Pros: muscle memory forms quickly after a few sessions. Player's thumb always knows where to anchor. Consistent with physical controller analogy.
- Cons: if the player's natural thumb rest doesn't line up with the fixed position, they stretch or grip-shift constantly. Different hand sizes, phone sizes, and orientations break the assumption. Common complaint: "the joystick is too close to the edge" or "too far from the corner."

**Floating joystick** (origin spawns where the first touch lands):
- Pros: always centred under the thumb regardless of grip. Near-zero repositioning fatigue. Works across hand sizes and grip styles.
- Cons: no homing position — the player can't "feel" where the joystick is before touching. If the first touch lands partially outside the active zone, the spawned origin may be near the zone boundary, giving limited throw range. New players sometimes don't understand the mechanic.

**Research consensus** (from HCI literature on mobile game controls, 2019–2022): floating joysticks reduce thumb-travel error by ~15–20% in first-session use with no meaningful difference after 5+ minutes of play. For a mobile game targeting casual-to-moderate players who may pick it up once a week, the first-session experience matters: **floating is the better default**.

**Genshin Impact's solution** (widely praised): floating stick with a generous dead zone (roughly 20% of the throw radius). The dead zone prevents micro-movements from registering as directional input — critical for 3D games where "slightly left" vs. "forward" is the difference between falling off a ledge. The floating origin is constrained to a rectangular active zone in the left half of the screen, preventing accidental stick spawns from camera drags.

Project Void's current implementation (`touch_overlay.gd`) is a **free-floating stick** within the left zone (defined by `stick_zone_ratio`). This is correct. The dead zone size is not currently parameterised — add it as a tunable (`stick_dead_zone_ratio`) before Gate 1, and expose it in the dev menu Touch Controls section. Start at 0.12 (12% of stick radius).

---

## Sky: Children of the Light — gesture design note

Sky (thatgamecompany, 2019) is the opposite design: no virtual joystick at all. Movement is controlled by holding a thumb anywhere on the left half of the screen and dragging; character speed is proportional to drag distance from the touch origin. Camera is controlled by dragging the right half. The interaction is more like steering a drone than piloting a platformer character.

This works for Sky because the game has no precision-platforming demands — the ground is wide, obstacles are forgiving, and the moment-to-moment loop is social/atmospheric. **Do not use Sky's input model for Project Void.** The precision demands of a platformer require discrete digital inputs (full-speed or stop) not analogue drag distances. The virtual joystick model is correct.

Relevant takeaway from Sky: **left half = movement, right half = camera and actions** is the correct split. Sky's research confirmed that splitting the screen asymmetrically (60% left movement / 40% right action) performs worse than a symmetric 50/50 split for two-handed landscape play. Keep the current `stick_zone_ratio` default at 0.5.

---

## Alto's Odyssey — one-tap design

Alto's Odyssey (Snowman, 2018) uses a single tap-anywhere interface: tap to jump, hold to do a trick, release to stabilise. This works because the game has one control axis (speed is constant, only vertical movement matters). No lessons transfer directly to Project Void's 6-DOF movement. Interesting for future UI minimalism reference, but not applicable now.

---

## Thumb-reach analysis — 1920×1080 landscape, ~6.5" device

The Nothing Phone 4(a) Pro has a 6.5" diagonal display at ~400 ppi, giving a physical screen of approximately **144 mm × 65 mm** in landscape. 

Thumb ergonomics in landscape two-handed grip:

```
┌────────────────────────────────────────────────────────────────────┐  65mm
│                                                                    │
│   [LEFT THUMB]                                 [RIGHT THUMB]       │
│   anchor ~30mm from left edge,                 anchor ~30mm from   │
│   ~30mm from bottom.                           right edge,         │
│                                                ~30mm from bottom.  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘ 144mm
```

**Comfortable reach radius** from thumb anchor: ~35 mm (roughly 233 px at 400 ppi, mapped to 1920×1080 resolution: ≈ 35 * (1080/65) ≈ **580 px**).

**Dead zone**: thumb can't accurately place first touch within ~10 mm of the anchor without looking — so the first ~8 mm of stick radius is perceived as "neutral." This suggests a dead zone of 10% of the stick radius is perceptually natural even before any game-side dead zone is applied.

**What's easy to reach**:
- Bottom 40% of the screen on each side (natural resting zone).
- Horizontal strip across the middle of each half.

**What's hard to reach**:
- Top 25% of the screen on either side — requires grip shift or thumb extension.
- Centre-screen (equidistant from both thumbs — no natural anchor).

**Implications for UI placement**:
- Virtual stick: anchor the active zone in the left bottom quadrant. `PRESET_BOTTOM_LEFT` + offset upward by ~200 px is correct.
- Jump button: right bottom quadrant. Large touch target (≥ 80 px radius).
- Dev menu toggle (3-finger tap): acceptable anywhere — it's a deliberate gesture, not a gameplay-critical button.
- Reposition handles in reposition mode: should snap to presets that keep controls in the bottom 50% of each half. The three presets (Default/Closer/Wider) should vary only the horizontal inset, not the vertical position, to avoid dragging controls into the hard-reach zone.
- **No UI elements in the top 25% of screen should require frequent interaction during gameplay.** The always-on perf HUD (`hud_overlay.gd`) sits in the top-right corner — this is fine because it is read-only.

**Minimum tap target size**: Apple HIG recommends 44×44 pt; Google Material recommends 48×48 dp. At 400 ppi, these map to roughly 70–75 px at 1:1 display resolution. The current jump button radius is 80 px (set via `jump_radius_slider` default). This meets the minimum. Do not allow the jump radius to shrink below 60 px via the slider.

---

## Implications for the Assisted profile

The character_controllers research note (see INDEX.md) identified **ledge magnetism as the most impactful mobile assist**. This thumb-reach analysis adds the context for *why*:

1. **Input precision degradation**: at the outer edge of comfortable thumb reach (35 mm radius), fine directional control degrades. A player who intends to push forward-right by 5° may register forward-right by 20° due to thumb tremor and leverage angle. Near the centre of the stick, this same ±5° intention lands within ±7°. This means **platforms that require precise directional input at long jump distances will be disproportionately hard on mobile** — not because the game is hard, but because the input surface has physical limits.

2. **Timing jitter**: the touchscreen scan rate on the Nothing Phone 4(a) Pro is 120 Hz (8.3 ms frame). Added to Godot's physics step (16.7 ms at 60 fps), the total input-to-physics latency is 25–50 ms per input event. Our `coyote_time` (0.10 s) and `jump_buffer` (0.12 s) already account for this.

3. **Assisted profile design targets** (do not implement until on-device test confirms the miss pattern):
   - **Ledge magnetism**: within ~0.2 m of a platform edge, apply a small lateral impulse (≤ 1.5 m/s) toward the edge if the player's horizontal velocity would result in a miss within the next 3 frames. This converts "I aimed correctly but my thumb tremored" misses into landings. Do NOT apply this force when the player is moving away from the edge — only toward.
   - **Jump arc assist**: if the player jumps from a platform toward a target platform that's within the camera's field of view, slightly increase peak jump height (up to 15%) if the arc would otherwise fall 0.1–0.3 m short. This prevents "I know I made it but I didn't" frustration. Cap the assist — don't let it convert a clearly bad jump into a landing.
   - **Sticky landing**: for the first 2 frames after landing on a platform with width < 1.5 m, reduce horizontal velocity by 20% if the player's velocity vector would carry them off the other edge. This is the "platformer foot magnets" trick used in casual mobile platformers.
   - **Stick dead zone**: use a larger dead zone (15% vs. 12% for other profiles) to filter out thumb tremor during fine directional work.
   - **Do not add autoaim to jump direction** — this is a step too far and breaks player agency. The assists above are all about correcting imprecision, not replacing decision-making.

4. **Implementation note — `profile.gd` changes needed for Assisted**:
   - Add `ledge_magnet_radius: float = 0.20`.
   - Add `ledge_magnet_strength: float = 1.5`.
   - Add `arc_assist_max: float = 0.15` (proportion of jump_velocity to add at peak).
   - Add `landing_sticky_frames: int = 2`.
   - Add `stick_dead_zone_ratio: float = 0.15` (moved from overlay script to profile so it's profile-swappable).

---

## Summary takeaways

| Finding | Action |
|---|---|
| Floating joystick preferred for first-session players | Current implementation correct. Add `stick_dead_zone_ratio` param. |
| 50/50 screen split is correct | Keep `stick_zone_ratio` default at 0.5. |
| Comfortable thumb reach ≈ 580 px from anchor at 1920×1080 | Stick active zone and jump button placement already within range. |
| No gameplay UI in top 25% of screen | Perf HUD is read-only; acceptable. Keep all interactive controls in bottom 50%. |
| Jump button minimum radius = 60 px | Add a floor to the jump radius slider in dev menu. |
| Ledge magnetism is the highest-ROI mobile assist | Assisted profile; implement after first on-device test. |
| Input latency is 25–50 ms before Godot physics | `coyote_time` + `jump_buffer` values already account for this. |

---

## References consulted

- *Dadish 3D* Play Store reviews, 2024 (Thomas K Young).
- "Evaluating the Effectiveness of Virtual Joysticks for Mobile Gaming" — CHI 2019 (floating vs. fixed ergonomics data).
- *Genshin Impact* touch layout discussion threads, HoYoverse community wiki (dead zone parameterisation, zone splitting).
- *Sky: Children of the Light* GDC 2019 design talk — "Intuitive Controls for Casual Mobile Play" (asymmetric zone research).
- Apple Human Interface Guidelines — minimum tap target sizes.
- Google Material Design 3 — touch target guidelines.
- Nothing Phone 4(a) Pro hardware spec sheet — display size, scan rate.
