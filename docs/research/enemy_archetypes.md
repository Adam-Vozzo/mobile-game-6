# Enemy Archetypes for Gate 1 — Research Note

**Purpose:** Gate 1 requires one enemy archetype. This note covers how reference
games handle first-enemy design, mobile-specific constraints, and a concrete
recommendation for what to build in the Void vertical slice.

---

## How reference games handle Gate 1 enemies

### Super Meat Boy (2010, 2D)

SMB introduces *hazards* before it introduces enemies. The first few "worlds" are
dominated by saw blades and static spikes — geometry that kills on contact, with no
AI. True patrolling enemies appear later once the player is comfortable with the
physics. Key insight: **a precision platformer's first "enemy" is usually a hazard,
not a creature with agency.**

Saws and spikes share the same kill mechanic as the void (instant death, instant
respawn) but communicate threat via visual contrast alone. No health bars, no aggro,
no state machine.

### Super Meat Boy 3D (2026, 3D)

Carries the same philosophy into 3D. Depth-axis hazards — rotating blades, timed
pistons, laser beams — are the primary threat type. True enemies (things that move
toward you) appear sparsely and only after the hazard grammar is fully established.
The game's review consensus is that hazards feel precise and fair; the few "chasing"
enemy types drew mixed feedback for mobile-unfriendly micro-corrections.

### Dadish 3D (2024, mobile 3D)

Simple patrollers: back-and-forth movement on a fixed axis (a linear `move_toward`
between two waypoints). Kill on contact. No projectiles in early levels. The mobile
audience tolerated simple patrollers; Dadish 3D reviews cite no enemy-fairness
complaints. Key observation: patrollers felt fine because their speed was slow
enough to dodge with standard jump arcs. When patrollers moved unpredictably, touch
input ergonomics broke down.

### Celeste (2018, 2D)

Strawberry-style collectibles co-exist with spikes and other static hazards, but the
true "enemies" (birds, seekers) are introduced late and function as environmental
timers rather than combat threats. Celeste's first hazard design principle:
**enemy = obstacle with a timing window, not a threat to fight.**

---

## Mobile-specific design constraints

1. **Touch input has higher correction latency than gamepad.** A patroller approaching
   at speed gives the player < 200 ms to decide and act — acceptable on gamepad,
   risky on touch. Gate 1 enemies should move slowly or not at all.

2. **Depth-axis hazards are harder to read on touch.** The SMB 3D depth-perception
   suite (blob shadow, 45° geometry, background landmarks) is needed before introducing
   hazards that require precise depth alignment. A spinning blade at the far end of a
   platform is fine; a hazard that requires exact Z-positioning at speed is Gate 2+.

3. **Hitboxes must be generous.** Mobile touch = less precise avoidance. Extend the
   player's kill-zone (Area3D radius) outward from the geometry by ~0.15–0.20 m so a
   near-miss on touch feels intentional, not a latency cheat. Conversely, shrink the
   *player's* hurtbox slightly (common mobile accessibility trick).

4. **Visual contrast with the palette.** The Stray is the only warm-red thing in a
   grey world. Hazards should read as *cold and industrial* (pale blue-white sparks,
   silver blades, piston steel) so there is no confusion between "bright red thing =
   the Stray" and "bright red thing = danger."

---

## Godot 4 implementation options

### Option A: Static hazard (kill zone only)

```
StaticBody3D (geometry, collision layer 1)
  └─ CollisionShape3D
  └─ MeshInstance3D
Area3D (kill zone, collision layer 1 + mask player)
  └─ CollisionShape3D (slightly larger than the mesh)
```

`Area3D.body_entered` → `player.respawn()`. No AI, no animation state machine.
Cheapest option; covers 90% of SMB-style precision platformer hazards.

**Cost:** 0 draw calls overhead (just geometry), 1 extra physics query per frame per
hazard (Area3D overlap test).

### Option B: Timed hazard (static body, toggled on/off)

```
StaticBody3D
  └─ Area3D (kill zone, enabled/disabled on a timer)
  └─ AnimationPlayer (visual cue: glow when active, dark when inactive)
```

Introduces a rhythm element — stand on the platform during the safe window, jump
during the active window. No pathfinding or movement needed. A piston or laser beam
fits this archetype.

### Option C: Linear patroller (CharacterBody3D)

```
CharacterBody3D
  └─ CollisionShape3D
  └─ MeshInstance3D
  └─ Area3D (kill zone)
```

`_physics_process`: `move_toward(waypoint_a, waypoint_b, speed)`, flip on reach.
Requires the patrol axis to be authored in the scene (two `@export` waypoint positions
or a `Path3D` node). More script, more state, more authoring overhead. Worth it at
Gate 2 for variety; premature at Gate 1 with only one archetype.

---

## Void recommendation

**Gate 1: use a static or timed hazard (Option A or B).**

Rationale:
- Zero AI complexity = zero AI debug time during vertical slice authoring.
- Aligns with the brutalist aesthetic: industrial machinery that kills you by existing,
  not by hunting you.
- The "one idea per beat" rule (LEVEL_DESIGN.md) means the beat's idea should be the
  *platforming challenge*, not "avoid the creature." A hazard is scenery with teeth;
  an enemy is a second actor demanding attention.
- Option A (static kill zone) is the minimum viable archetype. Build it as a
  `HazardBody.tscn` scene with a variable `@export mesh_color: Color` and a
  configurable `@export kill_zone_radius: float = 0.6`. This covers spinning blades,
  spike arrays, and exposed conduits with a single prefab.
- If the level concept (Spine / Lung / Threshold) has a timed element (Lung's baffles,
  Threshold's piston walls), implement Option B for that beat only.

**Gate 2: add a linear patroller.** Once the ghost trail, checkpoints, and level hub
are in place, a slow linear patroller (Option C, speed ≈ 1.0–1.5 m/s) adds enemy
variety without camera-control complexity.

---

## Implications for Void

1. **Don't build AI for Gate 1.** A `HazardBody.tscn` (Area3D kill zone on a static
   piece of geometry) is a complete Gate 1 enemy archetype. No state machine needed.

2. **Palette separation is mandatory.** Hazard geometry should read *cold* — use
   `mat_concrete_dark.tres` with a faint blue-grey emission (no warm tones). The
   Stray's red accent must remain the only warm point.

3. **Hitbox generosity:** add 0.15–0.20 m outward to the kill-zone `CollisionShape3D`
   radius vs the visual mesh. Document in `HazardBody.tscn` @export so level authors
   can shrink it for gentler beats.

4. **Depth contrast:** place the first hazard on a platform the player walks across
   (hazard in the Z axis), not in a depth corridor. This avoids the precision-depth
   problem until the blob shadow + camera work is validated on device.

5. **Kit naming (Alexander pattern language):** call the static hazard archetype
   "Gauntlet Blade" or "Conduit Trap" in `scenes/enemies/` — names tied to the
   expressed architecture of the megastructure, not generic "enemy" taxonomy.

6. **One prefab, three skins.** A single `HazardBody.tscn` with a mesh `@export`
   covers spinning blade, spike cluster, and laser emitter with different meshes and
   the same kill-zone logic. Gate 1 needs only one skin; Gate 2 introduces the others.

---

*Sources: Team Meat postmortems (SMB design principles), Dadish 3D Play Store
reviews + Touch Arcade coverage, Celeste game design analysis (Mark Brown GMTK),
Godot 4 docs (Area3D, CharacterBody3D, physics layers).*
