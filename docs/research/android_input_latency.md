# Android Touch Input Latency — Godot 4 Mobile Action Games

**Relevance:** Gate 0 feel verdict + every device test thereafter. When the human
first plays on the Nothing Phone 4(a) Pro and judges whether the controls "feel
snappy," the number they're feeling is: raw touch latency + Godot frame pipeline
latency + render frame. Understanding this number before the first test prevents
misattributing controller-feel issues to the input system (or vice versa).

---

## 1. The Android Touch Pipeline

```
Finger → Capacitive sensor → Kernel (SurfaceFlinger driver)
      → InputDispatcher (OS, Java layer) → App InputQueue
      → Godot's OS_Android → InputEvent → _input() / _physics_process()
      → GPU → Display panel
```

Typical latencies per stage (modern mid-range Android, 60 Hz panel):

| Stage | Budget |
|---|---|
| Touch sensor hardware | 4–8 ms (240–480 Hz sampling on current flagships) |
| Kernel → InputDispatcher | 4–12 ms (OS scheduling; worst-case on busy frames) |
| InputDispatcher → Godot app | 4–10 ms (JNI bridge, Godot event loop) |
| Godot `_input()` / event queue | 0–16.67 ms (event arrives at arbitrary point in frame) |
| `_physics_process()` tick | 0–16.67 ms (fired at fixed 60 Hz; event may wait 1 full tick) |
| GPU render + display scanout | 16.67 ms (1 frame at 60 fps) |

**End-to-end touch→pixel total: 28–70 ms.** Perception threshold for "laggy
action game" is ~80–100 ms. Good mobile games land 35–55 ms; problematic ones
exceed 80 ms. Project Void's target range is achievable without exotic changes.

**Nothing Phone 4(a) Pro specifics:** Qualcomm Snapdragon 7s Gen 3, likely
240 Hz touch sampling, 120 Hz AMOLED display. At 120 Hz the display frame is
8.3 ms; a 60 Hz Godot physics loop adds a maximum 16.67 ms stall. Consider
targeting 120 fps physics at Gate 1 if feel is noticeably laggy on device — see
§5.

---

## 2. Where Godot 4 Adds Latency

### `Input.use_accumulated_input` (default: `true`)

Godot accumulates all touch motion events that arrive between two `_process()`
calls into a single synthesised event. This prevents a flood of micro-events
when the touch screen samples at 240 Hz, but it adds up to 1/60 s of latency
for the last sample in a batch.

**Fix:** Set `Input.use_accumulated_input = false` in the project's
`ProjectSettings` (or in an autoload `_ready()`). For a 3D platformer where
the stick input is already low-pass filtered by the player's move_toward
interpolation, disabling accumulation is low-risk. For camera drag it makes a
more direct difference.

### Physics process tick alignment

Input events arrive at arbitrary times relative to the 60 Hz physics tick.
`_physics_process()` fires at most once per rendered frame, so an event that
arrives 1 ms after a tick started will wait a full 16.67 ms for the next one.
Average latency from this source alone: ~8 ms.

The TouchInput autoload's `get_move_vector()` and `is_jump_held()` are read
inside `_physics_process()`, so movement input has this inherent ~8 ms average.

### `_input()` path (lower latency)

Godot calls `_input()` in the main thread before `_process()`, so input events
processed there see at most 1 rendered frame of latency (not 1 physics tick).
For the jump buffer specifically, moving the buffer-set call to `_input()`
rather than `_physics_process()` could shave 0–16 ms on fast presses.

**Current architecture:** `TouchInput.jump_pressed` signal is emitted when
`InputEventScreenTouch` is received in `touch_overlay.gd`'s `_input()`. The
signal sets `_buffer_timer` in `player.gd`'s `_on_jump_pressed()`, which is
connected at `_ready()`. GDScript signal dispatch is synchronous — so the
buffer is actually set on the `_input()` frame, not the next physics tick. ✓

Movement stick updates (`set_move_vector`) also happen in `_input()` in
`touch_overlay.gd`. `get_move_vector()` is then read in `_physics_process()`.
So movement stick has at most 1 physics tick of latency (~0–16.67 ms).

---

## 3. What the Jump Buffer Is Actually Doing

The 100–150 ms jump buffer (current defaults) serves two purposes:

1. **Input prediction:** A player who presses jump 80 ms before landing has
   their press honoured as a coyote/landing jump. This papers over the full
   end-to-end latency budget (28–70 ms) plus human motor timing imprecision
   (~50 ms reaction variability).

2. **Physics tick compensation:** Jump input arriving mid-tick fires on the
   next tick (0–16.67 ms delay). The buffer makes this invisible.

In other words, **the jump buffer system already solves the latency problem for
jump specifically.** This is the correct architecture: don't try to reduce
latency to zero; use a buffer window wide enough to cover the whole pipeline.

**Implication:** The 100–150 ms buffer values in the Snappy/Floaty profiles are
not arbitrary — they're sized to the full touch pipeline. Reducing them to
"tighten" feel in Gate 0 tuning should be done carefully: below ~60 ms the
buffer no longer covers the full pipeline and players will begin to experience
missed jumps on precise inputs.

---

## 4. What the Movement Stick Feels Like at 30–60 ms Latency

Movement velocity changes in `_physics_process()` via `move_toward()`. The
controller's `ground_acceleration` and `air_acceleration` values determine how
quickly `velocity` responds to stick changes.

If acceleration is high (Snappy: 20 m/s²), velocity reaches target in ~1–2
ticks. If it's low (Floaty: 12 m/s²), it takes 3–5 ticks. At 30 ms input
latency + 2 tick response, the Snappy profile's movement reaction time is
~63 ms. At the same latency the Floaty profile's is ~100 ms.

**Implication:** On first device feel, if Floaty feels laggy it may be
acceleration-limited rather than input-limited. Increasing `ground_acceleration`
on Floaty (not reducing buffer) is the right fix.

---

## 5. 120 Hz Physics Mode (Gate 1 candidate)

The Nothing Phone 4(a) Pro almost certainly has a 120 Hz panel. Running physics
at 60 Hz on a 120 Hz display means every other display frame has stale physics
state — the position interpolation in Godot 4's `PhysicsInterpolation` feature
addresses this, but it's not enabled by default.

Options:
- **Default (60 Hz physics, no interpolation):** positions are 1 frame stale
  every other display frame. Visually fine for most players; character movement
  may look choppy at 120 Hz.
- **Physics interpolation (`ProjectSettings.physics/common/physics_ticks_per_second`
  = 60, `physics/common/enable_object_deactivation` handled separately):** Godot
  4.3+ includes built-in `Node.physics_interpolation_mode` support. Enabling
  `ProjectSettings.physics/common/physics_interpolation` smooths rendering
  between physics ticks with no latency cost (the interpolation uses previously
  known state, it does not predict). This is the recommended approach.
- **120 Hz physics:** Doubles physics load. Not recommended unless 60 Hz
  interpolation still shows artifacts on device.

**Gate 1 recommendation:** Enable `physics/common/physics_interpolation = true`
in ProjectSettings before the first device test. Negligible performance cost,
eliminates the choppy-at-120Hz problem. Exposed via dev menu as a checkbox in
the Debug viz section if needed for A/B testing.

---

## 6. Practical Godot 4 Settings to Try Before First Device Test

```gdscript
# In an autoload _ready(), or in ProjectSettings:

# Reduces input event batching; saves up to 4 ms average on touch motion
Input.use_accumulated_input = false

# Physics interpolation (ProjectSettings > Physics > Common)
# physics/common/physics_interpolation = true

# Ensure the game runs at 60 fps hard cap (already set in project.godot)
# Engine.max_fps = 60  (set at project level, not in script)
```

In `touch_overlay.gd::_ready()`:
```gdscript
Input.use_accumulated_input = false
```

This is the single highest-ROI change before the first device test.

---

## 7. Latency vs. Responsiveness — the Distinction

Latency is objective (milliseconds). Responsiveness is perceived and depends on:
- **Audio SFX:** A footstep or jump sound plays on the `_physics_process()` tick
  that processes the jump, which is ≤1 tick after the touch event. SFX adds
  the sensation of instant response even if the visual is 1 frame behind. This
  is why Astro's Playroom feels so tight despite being a PS5 game at 60 fps.
  Gate 1 audio pass is high-ROI for perceived responsiveness.
- **Squash-stretch:** The Tween starts on the same `_physics_process()` tick as
  the jump state change, so the visual anticipation reads as immediate. ✓
- **Jump puff:** spawned in `_try_jump()`, same tick. ✓

**Implication for Project Void:** The current juice system (squash-stretch,
jump puff) does as much for perceived responsiveness as any latency optimisation
at the platform level. Prioritise getting these working and feeling good before
chasing extra milliseconds.

---

## Implications for Project Void (summary)

1. **Add `Input.use_accumulated_input = false`** in `touch_overlay.gd::_ready()`.
   Single line, no risk, saves up to 4–8 ms average on continuous touch drag.

2. **Current jump architecture is correct.** Jump signal is emitted in `_input()`,
   not `_physics_process()`. Buffer is already sized to the full pipeline. Do not
   reduce buffer below 80 ms without on-device A/B testing.

3. **If Floaty feels laggy, increase `ground_acceleration`** — it's likely
   acceleration-limited, not input-limited.

4. **Enable `physics/common/physics_interpolation = true`** before the first
   device test. Negligible cost; fixes choppiness on 120 Hz display.

5. **Juice (SFX + squash) is the highest-ROI responsiveness fix.** A jump sound
   on the same frame as the jump state change will make the controls feel
   2× snappier than any platform optimization.

6. **Expected end-to-end feel on Nothing Phone 4(a) Pro:** 30–55 ms end-to-end
   with the above settings. This is in the "feels good" range for action games.
   If it feels sluggish, the bottleneck is almost certainly `ground_acceleration`
   (movement) or the absence of audio SFX (jump), not the platform.

---

*Sources: Android Input Latency — Google Android Developers documentation;
Godot 4 Input documentation; Godot 4.3 physics interpolation changelog;
community testing notes on mobile game input (Genshin Impact, CoD Mobile);
"Latency Tips for Android Games" session from Google I/O 2019; general
knowledge of capacitive touch pipeline.*
