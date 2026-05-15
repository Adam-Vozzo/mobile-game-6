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

Toggle is live (iter 81): `camera_rig.gd._on_screen_shake_requested` mutes all shakes when
off. Intensity multiplier tunable in dev menu Juice → Screen Shake — Tuning ("Intensity ×").
Signal path: emitters call `Game.screen_shake_requested.emit(mag, dur, freq)`;
`camera_rig.gd` connects in `_ready()` and applies after `look_at()` so movement direction
is not affected. Only the strongest in-flight shake wins (weaker arrivals are discarded).

| element | status | notes |
|---------|--------|-------|
| Hard land | prototype | impact ≥ 0.25 (Audio heavy-land threshold): 0.011×impact rad, 0.13 s, 20 Hz; fired in player.gd `_tick_timers()` just_landed block. Light landings produce no shake. |
| Death/respawn | prototype | 0.022 rad, 0.20 s, 26 Hz; fired in player.gd `respawn()` alongside `Game.player_respawned`. |
| Hazard hit (directional) | idea | direction-biased toward the hazard source — deferred; requires knowing hazard world-pos at hit time. Death shake fires on all kills as a non-directional substitute. |

## Hitstop — toggle key `hitstop`

| element | status | notes |
|---------|--------|-------|
| Player damaged | idea | 50–80 ms freeze, audio ducks |
| Enemy hit by player | idea | Gate 1 — PatrolSentry now exists; hitstop would fire on Player.respawn() caused by sentry contact. |
| Sentry bob | prototype | Gentle Y-axis sine oscillation on PatrolSentry (BOB_AMPLITUDE 0.08 m, BOB_PERIOD 2.0 s). Toggle: "Sentry bob" in dev menu Level → Sentry — Tuning (not in Juice toggles — enemy behaviour, not a player response). On-device pending — amplitude may need reduction. |

## Particles — toggle key `particles`

| element | status | notes |
|---------|--------|-------|
| Footstep dust | prototype | `_spawn_footstep_dust()` throttled by `_footstep_dust_interval` (default 0.15 s); fires when `on_floor`, h_speed > 0.5 m/s, not on landing frame; 4 ImmediateMesh lines at TAU/4 increments, warm grey (0.80/0.77/0.72, α=0.50), slight upward kick, 0.10 s fade; dev menu "Footstep interval (s)" slider (Particles — Tuning, 0.05–0.40). On-device pending — interval and alpha need feel tuning. |
| Jump puff | prototype | `_spawn_jump_puff()` on jump fire (inside `_try_jump`); 8 ImmediateMesh lines radiating horizontally from takeoff point, warm grey (0.80/0.77/0.72), slight upward kick per line; 0.04 s hold then 0.16 s fade; ~14 verts; gated behind `particles` toggle |
| Land impact | prototype | `_spawn_land_impact(impact)` in just_landed block; suppressed below `_LAND_IMPACT_THRESHOLD = 0.15`; 6 ImmediateMesh lines radially outward, length = 0.08 + impact×0.22, upward kick = impact×0.12 (heavier landings spray higher); warm grey, 0.03 s hold then 0.18 s fade; gated behind `particles` toggle. On-device pending — threshold and length formula need feel tuning. |
| Reboot sparks | prototype | 12 ImmediateMesh lines at death position, warm orange-yellow, fade 0.45 s; ~14 verts; gated behind `particles` toggle |
| Wall slide trail | idea | only if wall mechanic survives Snappy tuning |

## Motion trails — toggle key `motion_trails`

| element | status | notes |
|---------|--------|-------|
| Player after-image | idea | low-alpha trail when speed > threshold |
| Ghost trail (replay) | prototype | `scripts/levels/ghost_trail_renderer.gd` + `game.gd` trail recording; MultiMeshInstance3D (1 draw call, 300 instances at default 2 s window); 30 Hz sampling in `game.gd::_physics_process`; archive on `player_respawned`; max 5 attempts; alpha-by-recency (newest=0.35 × 0.55^attempt); point_t fade oldest→newest; "Trail window (s)" slider 1–5 s in dev menu Juice → Ghost Trail. Default OFF — enable in dev menu once level has meaningful ghost data. 10 unit tests. |

## Squash & stretch — toggle key `squash_stretch`

| element | status | notes |
|---------|--------|-------|
| Pre-jump anticipation | prototype | coil squish prepended to `_play_jump_stretch`: coil_y=1−0.18×scale, coil_xz=1+0.08×scale over 0.04 s EASE_IN TRANS_SINE, then the existing stretch fires; gated by `squash_stretch` toggle + `_jump_stretch_scale` slider |
| Apex hold | idea | brief stretch at jump apex — needs apex-state signal, deferred |
| Land squish | prototype | `_play_land_squash(impact)` on `just_landed` frame; impact = `clamp(-last_fall_speed / terminal, 0, 1)`; squash_y = 1 − impact×0.45×scale, squash_xz = 1 + impact×0.20×scale; TRANS_SPRING recovery in 0.25 s; tunable via "Impact scale" dev-menu slider (0–1, default 0.5); zero draw-call cost |
| Jump stretch | prototype | `_play_jump_stretch()` on takeoff (inside `_try_jump`); stretch_y = 1 + 0.30×scale, stretch_xz = 1 − 0.15×scale; TRANS_QUAD out + TRANS_SINE in settle over 0.23 s; tunable via "Stretch scale" dev-menu slider (0–1, default 0.5); zero draw-call cost |
| Death squish | prototype | `_play_death_squish(dur*0.08)` on reboot beat 1: scale(1.25, 0.25, 1.25) crush tracked via `_squash_tween`; `_play_reboot_grow(dur*0.28)` on beat 3: scale-up from (0.05) with TRANS_BACK overshoot; both gated behind `squash_stretch` toggle |
| Dash stretch | prototype | `_play_dash_stretch()` on air dash trigger; XZ stretch + Y squish (1.25, 0.75, 1.25) via TRANS_QUAD out over 0.05 s, settles back to (1,1,1) over 0.15 s; gated behind `squash_stretch` toggle; zero draw-call cost |

## Blob shadow — toggle key `blob_shadow`

| element | status | notes |
|---------|--------|-------|
| Ground-projected disc | prototype | `scripts/player/blob_shadow.gd`; 1 raycast/frame + 1 draw call; disc scales radius_at_ground→radius_at_height and alpha_max→0 as height increases; quadratic alpha falloff; default ON (gameplay-critical depth aid, not decoration). 4 tunables now live in dev menu Juice → Blob Shadow — Tuning (radius ground/height, fade height, max alpha). |

## Sound layers — toggle key `sound_layers`

**Toggle is now live** (iter 80): mutes `SFX_Player` + `SFX_World` AudioServer buses.
Bus hierarchy: Master → Music / SFX_Player / SFX_World. Dispatch points wired in
`player.gd` (jump, land, respawn) and `data_shard.gd` (collect). All streams `null`
until audio direction confirmed — toggle mutes cleanly even with no assets loaded.
See `docs/research/audio_placeholder.md` for placeholder strategy.

| element | status | notes |
|---------|--------|-------|
| Jump SFX (`on_jump`) | prototype-stub | dispatch wired; stream null until direction confirmed |
| Land SFX (`on_land`) | prototype-stub | light/heavy split at impact=0.25; stream null |
| Collect shard SFX (`on_collect_shard`) | prototype-stub | dispatch wired; stream null |
| Respawn start SFX (`on_respawn_start`) | prototype-stub | dispatch wired; stream null |
| Servo whir under run | idea | looped, pitch-modulated by speed |
| Footstep impacts | idea | layered under whir |
| Jump anticipation hum | idea | starts in buffer window, fades out at apex |
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

## Collectible juice — no top-level toggle (individual element always-on while shard exists)

| element | status | notes |
|---------|--------|-------|
| Shard idle glow | prototype | OmniLight3D (cyan 0.12/0.90/0.95, energy 1.4, range 4.5 m) on DataShard; casts a subtle cyan pool onto nearby geometry; 1 draw call, no shadow |
| Shard collect pulse | prototype | On `_collect()`: energy spikes 1.4 → 7.0 over 0.05 s, fades 7.0 → 0.0 over 0.30 s via Tween; mesh hidden immediately; light fades independently so the pulse reads even on low-refresh displays |
| Shard slow spin | prototype | `rotate_y(delta * 1.15)` in `_process` — ~66 deg/s, readable at camera distance |

## Hazard juice — no global toggle (individual hazard owns its signal)

| element | status | notes |
|---------|--------|-------|
| Industrial press emissive strip | prototype | Amber strip (14 × 0.2 × 5 m) on underside of press body; `StandardMaterial3D` emission_energy_multiplier animated through four-beat cycle: dormant=0.3 (dim), windup ramps 0.3→2.5, stroke holds 2.5 (bright), rebound ramps 2.5→0.3; color `Color(1.0, 0.72, 0.12)` (sodium-vapour amber — not red, not cyan); 1 material, 0 extra draw calls; `_emissive_mat` cached in `_ready()` |

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
