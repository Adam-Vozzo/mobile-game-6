# Alto's Odyssey — Touch Input Design Notes

**Written:** 2026-05-15 (iter 92)
**Sources:** game design analysis from training knowledge; Alto's Odyssey (Snowman / noodlecake, 2018)

---

## What the game is

Alto's Odyssey is a 2D side-scrolling endless runner / snowboarder. The player travels
right automatically; the only variable is rider movement. Widely regarded as one of the
best-feeling mobile games — cited in CLAUDE.md as a mobile touch design reference.

---

## Touch input model

**One zone, one gesture type.**

- **Tap / hold — the entire screen.** There is no virtual joystick, no D-pad, no UI
  widget to hit. Tap anywhere → jump. Hold longer → backflip. The whole display
  surface is the input target.
- **Release timing = variable outcome.** Short tap = small hop. Long hold (≥~0.4 s) =
  backflip with scoring bonus. The same physical gesture at different durations produces
  meaningfully different gameplay outcomes — "one input, many outcomes" design.
- **No camera control whatsoever.** The camera auto-follows the rider at a fixed
  left-to-right framing with gentle parallax. The player never touches the camera.
  Ever.

---

## Why it works on mobile

1. **Zero mis-tap surface.** Every tap lands on a valid input zone. Precision
   platformers with small virtual buttons guarantee a percentage of failed inputs; Alto
   eliminates the failure mode entirely by making the whole screen the button.

2. **No cognitive split.** The player's full attention goes to world-reading and timing.
   There is no mental overhead from "which button do I press" or "did my thumb miss."
   Contrast Dadish 3D, where players reported fiddling with the camera while also
   trying to navigate — two parallel tasks fighting for attention.

3. **Touch latency is invisible.** A 40–70 ms touch delay on a tap-to-jump is
   imperceptible because the player's mental model is "I press → character responds."
   Continuous stick input makes latency legible (character lags behind thumb). Alto's
   discrete tap model hides the platform's worst characteristic.

4. **Horizontal auto-scroll removes the navigation problem.** Players never have to
   steer left-right in 3D; the camera does it. This concentrates all of the "is this
   the right time?" cognitive load on vertical timing — exactly one decision at a time.

---

## Design vocabulary

| term | definition |
|------|-----------|
| input economy | number of distinct gestures / buttons the player must track simultaneously |
| tap debt | accumulated wrong-tap rate when buttons are smaller than ~9 mm |
| camera tax | player attention cost of managing the 3D camera while also navigating |
| flow corridor | the arc of actions the game funnels the player toward next; constrains decisions without the player noticing |

---

## Implications for Project Void

Alto's model cannot be adopted directly — Void is 3D and requires directional stick
input. But its principles are instructive.

1. **Reduce input economy wherever possible.** Void currently has: stick + jump + optional
   dash gesture. That is three simultaneous mental tracks. Each additional axis of player
   attention raises the cost of every touch latency miss. Double-check that nothing
   requires the player to manage all three at once except in the hardest beats.

2. **Jump button hitbox should be generous, not precise.** Alto's full-screen tap zone
   is not available in Void (the stick needs screen area) but the jump button should be
   no smaller than 14–16% of the screen height — and repositionable (CLAUDE.md). Err
   larger. A large jump button approaching the right 40% of the screen is closer in
   spirit to Alto's model than a small circular button.

3. **Camera auto-framing is the single highest-ROI touch-UX investment.** Alto eliminates
   the camera tax entirely. Void can't do that, but auto-framing (lookahead, CameraHint
   nodes, auto-recenter) is the closest equivalent. Every degree of camera work the player
   doesn't need to do is a direct improvement to touch feel. Dadish 3D's top review
   complaint — "always unlocked outside chase sequences" — is the camera tax made
   visible. Void's spring-arm + CameraHint architecture is the correct answer; don't
   undermine it by requiring manual pan in normal play.

4. **Variable jump height (hold to cut) is the closest Void equivalent to Alto's
   hold-for-backflip.** "One input, many outcomes" via duration already exists in the
   jump system. This is a strength — reinforce it in level design (beats that reward
   precise release timing vs. beats that just need "any jump") rather than adding new
   button types.

5. **Release timing as the precision axis.** Alto's core skill is backflip timing.
   Void's core skill is jump timing. This structural similarity is why Void's mobile
   controls can feel as precise as a desktop platformer — the precision axis is
   duration-of-press, not joystick angle, so latency is less destructive.

6. **Avoid multi-touch simultaneous combinations.** Alto uses one touch at a time.
   Void's current model (stick + jump) requires simultaneous two-touch — unavoidable
   for a 3D platformer. Any mechanic that requires three simultaneous touches (stick +
   jump + dash at once, for example) should be redesigned as sequential or one-and-hold.
   The current hold-jump+swipe air dash is correct; dedicated-button air dash was right
   to be rejected.

---

## What this changes for Void

No immediate design changes needed — the current architecture already follows these
principles. This note is a calibration reference for when Gate 1 touch controls are
evaluated on device:

- If "jump button missed" is a feedback theme → increase button size before anything else.
- If "couldn't navigate AND watch the path" → reduce platform complexity, not input surface.
- If "camera always in the way" → add more CameraHint nodes before reaching for manual
  override as a solution.

The metric to watch: how often does the player pause to adjust the camera vs. how often
they die to a misjudged jump? The first number should approach zero.
