# Project Void — Juice Catalogue

All juice elements are listed here with their current state. Each has an independent dev-menu toggle.

Format: **Name** | State | Dev-menu toggle | Notes

---

## Motion

| Element | State | Toggle | Notes |
|---|---|---|---|
| Squash-stretch on land | STUB | `juice/squash_stretch` | Scale Y on landing based on fall velocity |
| Motion trail on player | STUB | `juice/motion_trail` | Trailing mesh or particles behind fast-moving player |
| Lean/tilt into movement | STUB | `juice/lean` | Player mesh tilts forward when accelerating |

## Impact

| Element | State | Toggle | Notes |
|---|---|---|---|
| Screen shake on hard land | STUB | `juice/screen_shake` | Shake camera offset; magnitude = fall velocity delta |
| Hitstop on death | STUB | `juice/hitstop` | Time scale dip on contact with lethal hazard |
| Land particles | STUB | `juice/land_particles` | Dust/spark burst on landing, scaled by fall velocity |
| Jump puff | STUB | `juice/jump_puff` | Small particle burst at feet on jump |

## Visual FX

| Element | State | Toggle | Notes |
|---|---|---|---|
| Reboot flash | STUB | `juice/reboot_flash` | Red flash → dark frame → fade in on respawn |
| Player red pulse | STUB | `juice/power_pulse` | Stray's red accent pulses on idle after a beat |
| Damage flicker | STUB | `juice/damage_flicker` | Electrical flicker on taking damage |

## Audio

| Element | State | Toggle | Notes |
|---|---|---|---|
| Footstep clank | STUB | `juice/footstep_sound` | Servo-clank on each step; pitch-modulated by speed |
| Jump anticipation hum | STUB | `juice/jump_sound` | Hum on jump start, air ring-out on apex |
| Land clank | STUB | `juice/land_sound` | Impact clank on landing; louder with higher fall |
| Reboot SFX | STUB | `juice/reboot_sound` | Sparks + power-on hum + boot chord |

---

## Notes

- All stubs currently do nothing. Dev-menu toggles are wired to boolean flags the future implementation will read.
- Gate 1 target: squash-stretch, land particles, jump puff, reboot flash implemented and on by default.
- Gate 3: full audio pass; all stubs evaluated and either implemented or deleted.
