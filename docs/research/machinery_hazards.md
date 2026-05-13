# Machinery Hazard Design in 3D Platformers

Research note for Project Void — Gate 1 Threshold Zone 3 (industrial press).

Throttle note: written at throttle 6 (soft) to prepare for the Threshold polish pass
that is currently blocked on on-device feel from the Zone 3 greybox.

---

## The problem

Threshold Zone 3's industrial press (`IndustrialPress` at x=8, z≈100) is currently
atmospheric only. When the on-device greybox feel is validated the press needs to become:
1. A legible threat (player understands it kills before dying to it).
2. A timing window (predictable cycle the player can read and exploit).
3. A readable silhouette against a dark, cluttered industrial background.

---

## Reference survey

### Super Meat Boy / SMB 3D

- **Telegraph > danger > reset** is the universal machine cycle. The telegraph beat
  is at least as long as the danger beat so even a first-timer can react.
- SMB uses strong silhouette contrast (black/dark machinery, bright danger zone).
  In 3D the cycle is typically signalled by a sound cue + a clear "winding up" pose
  before the lethal stroke.
- Depth perception: even SMB 3D's heavy depth-aid suite (blob shadow, 8-dir input,
  ground circle, background geometry) still drew criticism. Machines that move toward
  the camera obscure depth badly — prefer machines that move *across* the view plane
  or *parallel to the floor* for clearest reading.

### Celeste

- Crushers/spikes always show the "compression chamber" clearly — the player sees
  where they will be crushed *before* they enter the zone.
- Spikes are bright white against dark rock — maximum contrast.
- "Safe zone" is telegraphed by the negative space: the player learns to read
  absence-of-danger as a platform, not just presence-of-danger as a hazard.

### Half-Life / Portal industrial chambers

- Slow machinery paired with bright yellow/orange safety striping (in a world of grey).
  The safety markings are legible affordance, not decoration.
- Even though Portal's test chambers are "modern", the principle transfers: a band of
  emissive orange/yellow on the press face signals both its role and its cycle phase.

### INSIDE (Playdead)

- Machines telegraph intent via sound and shadow before they move.
- Foreshadowing: the game shows you a *corpse* at the machine in its intro shot so
  you already know it kills.
- The "safe channel" (the path through the machine) is deliberately narrow but clearly
  lit so the player's eye is drawn to it automatically.

### Hollow Knight

- Machines are enemy-as-obstacle, not obstacle-as-machine: they have simple AI states
  (dormant → windup → attack → cooldown) but you read them as mechanisms.
- Color: the single emissive part (eye, belly lamp, vent glow) is the attack indicator.
  It brightens to full intensity just before the lethal stroke.

---

## Design principles extracted

### 1 — The four-beat machine cycle

Every machine hazard needs exactly four beats, each with a distinct audio + visual cue:

| Beat | Name | What player sees | Duration guidance |
|------|------|-----------------|-------------------|
| 1 | Dormant | At-rest position; safe to pass | ≥ 0.5 × player crossing time |
| 2 | Windup | Slow backward draw; warning sound | 0.6–1.0 s (long enough to start moving) |
| 3 | Stroke | Full-speed lethal transit | 0.15–0.25 s (fast = threat) |
| 4 | Rebound | Bounce back toward dormant | 0.4–0.6 s (not safe until fully back) |

For the Threshold press: a pneumatic "hiss + pressure-build" for windup, a loud
metallic "SLAM" for stroke, a reverberant "clank-settle" for rebound.

### 2 — Axis alignment

The press should move **perpendicular to the player's travel direction** so the player
sees the full stroke without depth-perception ambiguity:

- Player moves generally +Z (south through the zone).
- Press should move on the Y axis (vertical crush) or X axis (side-to-side sweep)
  rather than Z (toward camera / toward player).
- Vertical crush is the clearest read in 3D: player sees the press descend from above,
  safe zone is underneath or beside it.

### 3 — Emissive danger signal

Add a single emissive strip on the press face that cycles through the four beats:

| Beat | Emissive energy |
|------|----------------|
| Dormant | 0.3 (faint glow) |
| Windup | Ramp 0.3 → 2.5 over windup duration |
| Stroke | Hold 2.5 (bright) |
| Rebound | Ramp 2.5 → 0.3 over rebound duration |

Colour: use warm amber/orange (not red — red is the Stray's exclusive) or a
cold blue-white. Avoid the cyan biolume (reserved for data shards).
Recommendation: sodium-vapour **amber** (`Color(1.0, 0.72, 0.12)`) — fits the
brutalist palette, reads as "industrial warning light", doesn't compete with the Stray.

### 4 — Safe-zone legibility

The "don't stand here when I fire" zone should be:
- Clearly bounded in geometry (a recessed shaft, a shadow on the floor matching the
  press face area).
- Ideally, also brightly contrasted: a rectangle of floor in a different material
  (e.g., metal grating vs. concrete) under the press.

### 5 — First encounter affordance

The player's first view of the press (arriving from the gantry sequence) should include
a hint that tells them it's dangerous before they're in range:

Option A: A "crushed prop" (a crate or barrel) already pancaked under the press — the
player reads its fate immediately (INSIDE approach). Simple to author with a flattened
`MeshInstance3D` in the press's at-rest position.

Option B: Place the checkpoint *just before* the press so the player's first death is
cheap (Celeste approach). They see it fire once from respawn safety, then attempt.

**Recommendation for Threshold Gate 1**: Option B — the press zone already has a
`WinStateTrigger` nearby; place the `CheckpointTrigger` one beat before the press so
a player who dies to it restarts from the Alcove checkpoint, not Zone 1.

### 6 — Mobile-specific sizing

Mobile latency (28–70 ms end-to-end, see `android_input_latency.md`) means the
danger window must be generous:

- Minimum safe window (dormant duration): 1.5 × (press width / player max_speed)
  Using the Threshold press at ~2m wide and Snappy max_speed 6.0 m/s:
  1.5 × (2/6) = 0.5 s minimum dormant window. Recommend 0.8–1.2 s.
- HazardBody trigger shape should be slightly *inset* from the press mesh — 0.1–0.15 m
  tighter than the visual geometry so a near-miss feels like a win, not an invisible
  death. (Matches mobile hitbox generosity guidance in `enemy_archetypes.md`.)

---

## Godot 4 implementation sketch

### RotatingHazard vs AnimatableBody

The existing `rotating_hazard.gd` uses `AnimatableBody3D` and a `Basis` rotation tick.
For a vertical press (linear Y translation), prefer `AnimatableBody3D` + `move_and_collide`
to keep the `HazardBody` children moving with the mesh:

```gdscript
extends AnimatableBody3D
class_name IndustrialPress

@export var stroke_depth: float  = 2.5   # metres down
@export var windup_time: float   = 0.80
@export var stroke_time: float   = 0.18
@export var rebound_time: float  = 0.50
@export var dormant_time: float  = 1.00

var _t: float        = 0.0
var _phase: int      = 0   # 0=dormant 1=windup 2=stroke 3=rebound
var _phase_t: float  = 0.0
var _origin_y: float = 0.0
var _emissive: StandardMaterial3D  # set in _ready()

const _PHASE_TIMES := [0, 0, 0, 0]  # filled from exports in _ready()

func _ready() -> void:
    _origin_y = global_position.y
    _PHASE_TIMES[0] = dormant_time
    _PHASE_TIMES[1] = windup_time
    _PHASE_TIMES[2] = stroke_time
    _PHASE_TIMES[3] = rebound_time

func _physics_process(delta: float) -> void:
    _phase_t += delta
    if _phase_t >= _PHASE_TIMES[_phase]:
        _phase_t -= _PHASE_TIMES[_phase]
        _phase = (_phase + 1) % 4

    var target_y: float
    match _phase:
        0:  # dormant — up
            target_y = _origin_y
        1:  # windup — slow draw back (upward for a descending press)
            var p := _phase_t / windup_time
            target_y = _origin_y + p * 0.3  # small retraction
        2:  # stroke — fast down
            var p := _phase_t / stroke_time
            target_y = _origin_y - p * stroke_depth
        3:  # rebound — back up
            var p := _phase_t / rebound_time
            target_y = (_origin_y - stroke_depth) + p * stroke_depth

    global_position.y = target_y
    _update_emissive()

func _update_emissive() -> void:
    if _emissive == null:
        return
    var energy: float
    match _phase:
        0: energy = 0.3
        1: energy = lerpf(0.3, 2.5, _phase_t / windup_time)
        2: energy = 2.5
        3: energy = lerpf(2.5, 0.3, _phase_t / rebound_time)
    _emissive.emission_energy_multiplier = energy
```

Wire a `HazardBody` (Area3D, calls `player.respawn()`) as a child with a BoxShape3D
inset ~0.12 m from the press mesh bounds.

### Emissive material setup in code

```gdscript
func _setup_emissive_strip() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.15, 0.08, 0.01)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.72, 0.12)   # amber
    mat.emission_energy_multiplier = 0.3
    _emissive = mat
    $PressBody/EmissiveStrip.set_surface_override_material(0, mat)
```

---

## Implications for Project Void — Threshold Zone 3

1. **Axis**: Make the industrial press a vertical descending crush (Y axis) so it's
   unambiguous in 3D — visible from the gantry approach and from the landing zone.

2. **Critical path**: Route the player under or beside the press (not around it — too
   easy to skip) after G4. The only way to reach the WinStateTrigger/Terminal is
   through the press timing window. Par route goes through; exploration route doesn't.

3. **Emissive strip**: Add a 2 m wide × 0.2 m tall amber strip to the underside of the
   press mesh. Ramps from dim to bright during windup; bright during stroke. No cost in
   draw calls (same material, same mesh).

4. **Dormant window**: 1.0 s dormant, 0.8 s windup, 0.18 s stroke, 0.5 s rebound.
   Total cycle ≈ 2.5 s. At Snappy 6.0 m/s, the player crosses 2 m in 0.33 s — the
   1.0 s dormant window is 3× their crossing time. Generous for a first encounter.

5. **Hitbox inset**: `HazardBody` BoxShape3D at `(1.7, 0.8, 1.7)` vs. press visual
   at `(2.0, …)` — 0.15 m inset on each horizontal side.

6. **First-encounter prop**: Add a flattened `MeshInstance3D` (0.5 m tall box, same
   concrete material, slightly darker) in the dormant press position — a crushed
   barrier that communicates "this descends and crushes things" before the player
   ever sees it fire.

7. **Dev menu**: Expose `stroke_depth`, `dormant_time`, `windup_time`, `stroke_time`,
   `rebound_time` as dev menu sliders. Label them "Press — Stroke depth", "Press —
   Dormant s", etc. Essential for on-device cycle-feel tuning.

---

## Sources / reading

- INSIDE (2016) — crushing machine first encounter (chapter 1, factory section)
- Hollow Knight — False Knight arena (windup + emissive indicator); Hive (saw hazards)
- SMB 3D (2026) — level 1 saw hazards (see `smb3d.md`)
- Celeste — Chapter 2 old site crusher sequence (four-beat cycle well-documented in
  community analysis)
- `docs/research/android_input_latency.md` — mobile-specific window sizing
- `docs/research/enemy_archetypes.md` — hitbox generosity guidance (0.1–0.15 m inset)
- `docs/research/smb3d.md` — depth-perception difficulty; cross-axis preference
