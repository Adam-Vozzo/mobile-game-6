# Zone Atmosphere — Godot 4 Mobile Renderer

**Research date:** 2026-05-13  
**Relevant to:** Threshold "ambient volumes" polish item (PLAN.md P0-8, blocked on device feel)

---

## The problem

Threshold has three zones with distinct intended feels:
- Zone 1 Habitation — warm sodium yellow, human scale, lived-in compression
- Zone 2 Maintenance — cold blue-white, industrial clutter, active machinery
- Zone 3 Industrial — harsh amber/orange, vast hall, machine-god scale

The greybox handles this with a few coloured OmniLights, but the transitions are abrupt and the floor fog is uniform. The question: how do we make these zones feel genuinely different without Forward+ features and without baked lightmaps (not yet at baking stage)?

---

## What the Mobile renderer can and cannot do

**Not available in Mobile (Forward+ only):**
- `FogVolume` nodes — per-region volumetric fog variation
- Volumetric light shafts
- Decals with falloff
- Screen-space ambient occlusion (SSAO) per-volume

**Available in Mobile:**
- Multiple OmniLight3D / SpotLight3D nodes with coloured light and shadow
- WorldEnvironment `fog_color`, `fog_density`, `ambient_light_color` (one set globally)
- StandardMaterial3D `emission` and `emission_energy` per surface
- `SubViewport` with its own `WorldEnvironment` (drastic, not worth it for zones)
- AnimationPlayer-driven WorldEnvironment transitions (global only)
- Multiple WorldEnvironment nodes with enable/disable swapping (per-zone)

**Key constraint:** Godot 4 Mobile renderer supports exactly one active `WorldEnvironment`. You cannot blend two environments simultaneously. Zone atmosphere differentiation therefore falls to per-zone *light placement* and *surface material* decisions, not fog variation.

---

## How reference games differentiate zones without volumetric fog

### Hollow Knight
Zones use **light color temperature as the primary identifier**: Forgotten Crossroads is warm amber; City of Tears is cold blue-white with simulated rain; Deepnest is pitch black with bioluminescent accents. The trick: each zone has a distinct dominant light hue applied to 3–4 large OmniLights that wash the geometry. Transitions are **camera-cut based** (loading screen between zones), so there's no real-time blend requirement.

**Applicable to Void:** Threshold can cut between zones at corridor narrows (already present at Zone 1→2 and Zone 2→3). A WorldEnvironment swap (enable new node, disable old) during the corridor crossing is possible with zero scene change.

### Celeste
Chapter 2 (Old Site) uses cool blue fog to contrast with the warm interior rooms. The technique: `fog_color` is set per-chapter to a cool desaturated blue globally, but warm interior scenes add 2–3 warm OmniLights that locally override the perceived ambient. The player perceives the scene as "warm room inside cold exterior" without any volumetric system.

**Applicable to Void:** Threshold's Zone 1 warm feel can be achieved with dense warm OmniLights even under a cold global fog — the eye integrates local light colour over the global sky.

### INSIDE (Playdead)
Extremely polished zone lighting. Key observation: **emissive surfaces carry zone identity** more than light count. Bright emissive strips on machinery (Zone 3 analogue) make the zone read as industrial even in extreme darkness. Low-count direct lights + high emissive surfaces = cheap Mobile budget + strong identity.

**Applicable to Void:** Zone 3's IndustrialPress amber emissive strip already does this correctly. Extend the principle: add emissive yellow-green strips to Zone 2 ServiceCart and MaintArm; add warm sodium emissive haze to Zone 1 pillars.

---

## Practical approach for Threshold on Mobile renderer

### Zone 1 — Habitation warmth
- 2–3 `OmniLight3D` at y=3–4 m, `light_color = Color(1.0, 0.85, 0.55)` (sodium yellow), energy 1.2–1.8, range 10–12 m, no shadow (budget)
- Add subtle `emission` to the ShelfA/B surfaces: `Color(0.9, 0.75, 0.45)` at energy 0.15 — gives the "warm glow from below" feel
- WorldEnvironment `ambient_light_color = Color(0.35, 0.30, 0.22)` (warm grey) — this is global but sets the baseline

### Zone 2 — Maintenance cold
- 4–5 `OmniLight3D` spaced along the corridor, `light_color = Color(0.65, 0.80, 1.0)` (cold blue-white), energy 0.8, range 8 m
- MaintArm1 gets an emissive joint strip: `Color(0.4, 0.85, 1.0)` at energy 0.6 (cyan machinery)
- ServiceCart adds a dim emissive underside: `Color(0.5, 0.7, 0.9)` at energy 0.2

### Zone 3 — Industrial amber
- IndustrialPress amber strip already present (energy cycles 0.3–2.5 — correct)
- 2 `SpotLight3D` aimed down at the gantries from above: `light_color = Color(1.0, 0.65, 0.20)` (amber/sodium), tight angle (25°), energy 2.5, shadow off
- Gantry floor mesh gets a subtle orange emission tint at energy 0.08 — "hot metal" read

### WorldEnvironment: per-zone swap via enable/disable
Add three sibling `WorldEnvironment` nodes to `threshold.tscn` (Zone1Env, Zone2Env, Zone3Env). In `threshold.gd`, connect `CheckpointTrigger` to a `_on_zone_changed(zone_id)` handler that enables the matching environment and disables the others. Each has slightly different `fog_color` (warm grey / cold blue / amber grey) and `ambient_light_color`.

```gdscript
# threshold.gd
func _on_zone_changed(zone_id: int) -> void:
    $Zone1Env.current = (zone_id == 1)
    $Zone2Env.current = (zone_id == 2)
    $Zone3Env.current = (zone_id == 3)
```

This gives true per-zone atmosphere with zero rendering cost — the environment swap takes effect on the next frame without a hitch.

**Gotcha:** Godot 4 requires exactly one `WorldEnvironment` to have `current = true` at all times. Use `_enter_tree` to set Zone1 as default.

---

## Implementation order (when the device-feel blocker clears)

1. Add Zone1/2/3 WorldEnvironment nodes to `threshold.tscn`, wire `_on_zone_changed`.
2. Place warm OmniLights in Zone 1 (sodium), cold OmniLights in Zone 2 (blue-white).
3. Add emissive tint to MaintArm1 joint + ServiceCart underside.
4. Add Zone 3 amber SpotLights above gantries; extend gantry emission slightly.
5. Playtest the Z1→Z2 corridor transition — confirm the atmosphere cut reads without a loading screen.
6. Tune in dev menu once on-device light counts are confirmed within budget.

**Budget target:** ≤ 12 OmniLights total in Threshold (Godot Mobile deferred lights add ~1 draw call per light per shadow caster). Zone 1: 3, Zone 2: 5, Zone 3: 2 spots + IndustrialPress strip = 10 total — within budget.

---

## Implications for Project Void

1. **WorldEnvironment swap is the zone identity tool.** One node per zone, current = toggle. Zero cost, no blend (acceptable for zone transitions in a platformer — the corridor is the transition moment).
2. **Emissive surfaces carry more zone identity than light count.** Zone 3's amber press already does this right. Apply the same logic to Zones 1 and 2.
3. **FogVolume is never needed** for Threshold's zone differentiation. The zones are sequential, not spatially overlapping — there's nothing to blend.
4. **Light count ceiling: 12 OmniLights.** Above this, draw call pressure from shadow casters appears. Keep Zone 2's corridor lights shadow-disabled (no shadow casting geometry in a narrow corridor anyway).
5. **Baked lighting (Gate 1+):** When the level is baked, the WorldEnvironment swaps become cosmetic only (the bake captures one environment). Plan for Zone 1 to be the bake environment; Zones 2 and 3 get their identity from emissive surfaces + a few dynamic OmniLights layered over the bake.
6. **Dadish 3D pain point mitigation:** Threshold's three-zone structure gives the player consistent orientation cues ("I'm in the warm zone / the cold zone / the machine zone") without any HUD or map — a navigation layer through atmosphere alone.
