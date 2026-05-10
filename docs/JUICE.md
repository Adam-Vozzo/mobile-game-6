# JUICE — Project Void

Catalogue of juice elements: their state, a one-line description of intent,
and which dev-menu toggle (if any) controls them. Anything that costs a
draw call, particle, or audio voice should be listed here.

The dev menu has independent toggles for each top-level category. Code
should consult `DevMenu.is_juice_on(<key>)` before activating any element
in that category.

Status legend:

- `idea` — described, not yet implemented.
- `stub` — placeholder hook in code, no real effect.
- `prototype` — works at a basic level; tuning pending.
- `tuned` — locked-in; only revisit with reason in `DECISIONS.md`.

---

## Screen shake — toggle key `screen_shake`

| element | status | notes |
|---------|--------|-------|
| Hard land | idea | small vertical shake on landing after a >2 m fall |
| Death/respawn | idea | quick high-frequency burst before reboot animation |
| Hazard hit | idea | direction-biased toward the hazard source |

## Hitstop — toggle key `hitstop`

| element | status | notes |
|---------|--------|-------|
| Player damaged | idea | 50–80 ms freeze, audio ducks |
| Enemy hit by player | idea | Gate 1 once an enemy archetype exists |

## Particles — toggle key `particles`

| element | status | notes |
|---------|--------|-------|
| Footstep dust | idea | mobile-budget particle (4 quads) on grounded run |
| Jump puff | idea | radial burst at takeoff, larger if jump held to apex |
| Land impact | idea | scaled by fall velocity |
| Reboot sparks | prototype | 12 ImmediateMesh lines at death position, warm orange-yellow, fade 0.45 s; ~14 verts; gated behind `particles` toggle |
| Wall slide trail | idea | only if wall mechanic survives Snappy tuning |

## Motion trails — toggle key `motion_trails`

| element | status | notes |
|---------|--------|-------|
| Player after-image | idea | low-alpha trail when speed > threshold |
| Ghost trail (replay) | idea | Gate 1 attempt-replay overlay |

## Squash & stretch — toggle key `squash_stretch`

| element | status | notes |
|---------|--------|-------|
| Pre-jump anticipation | idea | slight Y squish in the buffer window |
| Apex hold | idea | brief stretch at jump apex |
| Land squish | idea | scaled by impact velocity, recovers on a curve |
| Death squish | prototype | scale(1.25, 0.25, 1.25) crush on death; scale-up with TRANS_BACK overshoot on spawn; gated behind `squash_stretch` toggle |

## Blob shadow — toggle key `blob_shadow`

| element | status | notes |
|---------|--------|-------|
| Ground-projected disc | prototype | `scripts/player/blob_shadow.gd`; 1 raycast/frame + 1 draw call; disc scales radius_at_ground→radius_at_height and alpha_max→0 as height increases; quadratic alpha falloff; default ON (gameplay-critical depth aid, not decoration) |

## Sound layers — toggle key `sound_layers`

| element | status | notes |
|---------|--------|-------|
| Servo whir under run | idea | looped, pitch-modulated by speed |
| Footstep impacts | idea | layered under whir |
| Jump anticipation hum | idea | starts in buffer window, fades out at apex |
| Land clank + dust puff | idea | scaled by impact velocity |
| Reboot chord | idea | sparks → power-on hum → boot chord |

## Camera juice — currently no toggle (always-on, polish later)

| element | status | notes |
|---------|--------|-------|
| Lookahead lerp | prototype | covered by camera_rig.gd; tunable via dev menu |
| Vertical pull on fall | prototype | same |
| Vista slowdown | idea | `CameraHint`-driven, Gate 1 |
| Recenter on idle | prototype | timer-based; tunable via dev menu |

## Debug HUD — not juice, but listed here for completeness

| element | status | notes |
|---------|--------|-------|
| Corner perf HUD | prototype | FPS + frametime; always-on, toggle via Debug viz section; zero draw-call overhead |
| Velocity + state | prototype | player velocity + floor/air state; toggled off by default |

## UI juice — currently no toggle

| element | status | notes |
|---------|--------|-------|
| Button press scale | idea | virtual stick + jump button visual feedback |
| Dev menu open/close | idea | slide-in, fast (<150 ms) |

---

## How to add a juice element

1. Append the element to the right table above with status `idea`.
2. When you implement it, gate the activation behind
   `DevMenu.is_juice_on(<key>)` using a key from the table above (or add a
   new toggle category and document it here first).
3. Update status to `prototype`.
4. Track perf cost in the entry's notes — particles, draw calls, audio
   voices used.
5. Promote to `tuned` only after the human has felt it on device and
   approved.

## Anti-patterns to avoid

- Juice that fires on every frame regardless of context (always-on after
  10 minutes feels like noise).
- Stacking juice on the same input (jump anticipation + screen shake +
  sound layer + particle burst = mushy. Pick the one or two that read
  cleanest).
- Particles on the Mobile renderer without checking `PerfBudget` — the
  particle budget is hard.
