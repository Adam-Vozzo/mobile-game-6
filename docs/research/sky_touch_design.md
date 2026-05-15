# Sky: Children of the Light — Gesture & Touch Design

**Source**: thatgamecompany (2019). iOS/Android/PC/Console. Third-person flight/exploration.
**Why relevant**: Sky is the most studied example of minimal-gesture 3D navigation on mobile.
Its design principles map directly to Project Void's camera and input architecture choices.

---

## How Sky's input works

Sky uses what interaction designers call **direct manipulation**: instead of a virtual joystick
that represents a direction, you tap-and-hold anywhere on the play surface and the character
walks *toward* your finger in world space. Lift and re-tap to redirect.

- **Movement**: single tap-and-hold on any screen area.
- **Camera**: swipe (not tap-and-hold) on the movement area rotates the camera; two-finger
  pinch/rotate also works. The camera auto-returns behind the character when input stops.
- **Jump/fly**: dedicated button (top-right corner, large).
- **Social gestures**: hold the social button + swipe in a direction. Never required; always
  discoverable. The game *never* requires more than two simultaneous touch points.
- **UI**: minimal floating icons at screen edges. Nothing in the centre 60% of screen.

## Key design principles

### 1. Input economy (the tap-debt model)

Sky charges players *zero taps per second* to navigate in a straight line — once you
place your finger, the character follows without re-input. The only ongoing cost is camera
rotation. This is the "input economy" principle from Alto's Odyssey applied in 3D.

Implication: any design that requires frequent re-tapping to maintain a direction is charging
tap debt. Virtual joysticks charge continuous re-correction debt when deadzone drift is bad.

### 2. Camera tax is real but manageable

Sky accepts that players will occasionally adjust the camera (rotating, not pinching). The
game works around this in two ways:
- Auto-return: the camera eases back behind the character within ~1 s of last input.
- Route design: levels are authored so the *critical path* is straight ahead at a fixed camera
  angle. Manual camera adjustment is optional for exploration, not required for survival.

Implication for Void: **design each Threshold beat so the critical path is visible at the
default camera angle**. Players who never touch the right-side drag should still complete
the level. CameraHint nodes that push the camera toward the correct beat angle = Sky's
route-design principle in explicit form.

### 3. The two-simultaneous-touch ceiling

Sky never requires three touch points simultaneously. All social interactions (the most
complex gestures) require exactly two fingers at most. On phone-sized screens, a three-touch
chord requires finger crossing or wrist rotation — players drop the device.

Implication: Void's current air-dash input (hold jump + right-side swipe) is exactly at the
ceiling. It works as two sequential touches (jump registers, then swipe on the right zone)
rather than simultaneous, which is fine. Watch for the moment these feel simultaneous on
device — if the jump fires early and kills the swipe window, reduce the timing threshold
before the gate, not after.

### 4. Dead zones as stillness affordance

Sky uses a large finger-position dead zone (estimated 12–15% of the total play surface)
at the point of initial contact. Touch tremor and micro-adjustments within that zone are
treated as "hold still." Players can keep their finger nominally stationary without the
character drifting. This reduces correction-touch debt.

Implication: Void's current 15% dead-zone (from `touch_dead_zone_calibration.md`) is in the
right range. Do not shrink it below 10% to chase "precision" — that trades stillness
affordance for jitter.

### 5. No tutorial text → spatial pedagogy

Sky teaches everything through affordance and curiosity. The warm glow of a collectible, a
path of stepping stones, a hovering other-player silhouette. No word appears on screen during
the first 10 minutes.

Implication: Project Void's "likely zero dialogue" principle is fully achievable at Gate 1.
The PatrolSentry's amber eye strip, the amber danger-stripe on hazards, the fog that obscures
depth before CameraHint beats — these are all affordances that Sky would approve of. The
brutalist palette works *for* readability here: the only things that glow amber or cyan are
dangerous or collectible; everything else is grey.

### 6. Social layer adds gesture complexity safely because it is *opt-in*

Sky's most complex gestures (candle lighting, hand-holding) require deliberate multi-touch.
They work because failure has no penalty — players discover them out of curiosity, not
necessity. If a social gesture fails, nothing bad happens.

Implication: the air-dash hold-jump+swipe gesture follows this same safety rule — at Gate 1
the player can complete the level without ever using the dash (all Threshold beats are
traversable without it). This means dash can stay at the current complexity level without
blocking new players. The gate for dash-required design is Gate 2, after device testing
confirms the gesture is learnable.

---

## Implications for Project Void

1. **Auto-framing is non-negotiable**: Sky proves players will not manually rotate a camera
   if the route is authored to not require it. Every Threshold beat should be solvable at the
   auto-framed angle. CameraHints are the enforcement mechanism.

2. **Right-side drag (not second stick) validated**: Sky's two-point camera rotation gesture
   is less ergonomic than Void's one-swipe drag on a dedicated zone. Void's approach is
   *better* than Sky's camera model — don't second-guess it.

3. **Two-touch ceiling — watch the air dash on device**: the hold-jump + swipe gesture must
   be tested for timing window feel before Gate 2. If players complain the dash "doesn't fire"
   it's a timing window problem, not a gesture problem.

4. **15% dead zone is correct**: do not reduce.

5. **No tutorial text is viable**: the amber eye + amber danger strips + cyan collectibles
   system already follows Sky's affordance palette. Trust it on device.

6. **Gate 2 UX: consider tap-to-move as an alternate input mode** (Sky's default). Void's
   virtual stick is better for precision platforming; tap-to-move is better for explorers and
   casual players. A second input mode (with a toggle) could open the game to a wider audience
   at Gate 2+ without touching any gameplay mechanics.

---

## Sources

- Sky: Children of the Light (iOS App Store, 2019) — direct observation
- thatgamecompany developer interviews (GDC 2020, design team)
- Touch Arcade review thread player feedback (gesture discoverability discussion)
- The `alto_odyssey_touch_design.md` note for the tap-debt / camera-tax vocabulary
- `mobile_touch_ux.md` and `touch_dead_zone_calibration.md` for Void-specific dead-zone data
