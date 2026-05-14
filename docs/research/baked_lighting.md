# Baked Lightmapping — Godot 4 Mobile Renderer

Research for the Gate 1+ baked lighting pass on Threshold and subsequent levels.
Written 2026-05-14 (iter 73). No external source needed beyond Godot 4 docs and
engine behaviour known from the project so far.

---

## What LightmapGI gives you (and what it doesn't)

`LightmapGI` is Godot 4's scene-wide baked GI system. It pre-computes indirect
light, ambient occlusion, and multi-bounce colour bleeding into a texture atlas
at bake time, then reads that atlas at zero per-frame GPU cost.

**Works on Mobile renderer.** Unlike `VoxelGI` (Forward+ only) and `FogVolume`
(Forward+ only), `LightmapGI` is fully supported on the Mobile (Vulkan) and
Compatibility (GLES3) renderers — both of which Void uses.

**Does not capture:**
- Real-time dynamic objects (moving platforms, rotating hazards, DataShard lights)
- Per-zone WorldEnvironment ambient changes (see critical concern below)
- Reflections (that's `ReflectionProbe`, separate system)

---

## Setup workflow

1. **Add `LightmapGI` node** as a direct child of the scene root. One node controls
   the entire scene's bake. Name it `LightmapGI` by convention.

2. **Mark geometry static.** On each `MeshInstance3D` that should receive and cast
   baked light, set `GeometryInstance3D → GI Mode = Baked`. Leave moving geometry
   (`AnimatableBody3D` platforms, the IndustrialPress) at `GI Mode = Disabled`.

3. **Ensure UV2 channels.** Every mesh that participates in the bake needs a second
   UV channel (UV2) used exclusively for lightmap UVs. See "CSG blocker" below —
   this is the biggest practical hurdle.

4. **Set light bake modes.** Each `OmniLight3D` / `SpotLight3D` has a `Bake Mode`:
   - `Static` — folded into the lightmap. No runtime cost. Cannot change after bake.
   - `Dynamic` — always real-time. Unaffected by the bake. Keep for lights that
     move, toggle, or are too costly to bake accurately.
   - `Disabled` — ignored for baking.

5. **Bake.** Editor: select the `LightmapGI` node → top menu → LightmapGI → Bake.
   Produces a `.lkgd` binary file in `res://` (configurable via the `image_path`
   property). Re-bake after any geometry or static-light change.

---

## LightmapGI settings that matter for Void

| Setting | Recommended | Notes |
|---------|-------------|-------|
| Quality | Medium | Low for iteration; High for final only |
| Bounces | 2 | More bounces = richer GI, slower bake. Dark megastructure needs only 2 |
| Directional | false (initially) | Adds directional data for normal maps. Double the atlas size. Enable when normal-mapped concrete kit lands |
| Max Lightmap Size | 2048 | Safe mobile VRAM ceiling. 4096 risks overflow on Adreno 6xx / Mali G57 |
| Texel Density | 8–12 | Per-unit coverage. Large floor slabs (24×36 m Zone 1) consume atlas fast at density 16 |
| Denoiser | on | AI denoiser (OIDN if available) dramatically reduces speckle on low-quality bakes |
| Environment Mode | Disabled | See zone-atmosphere concern. Do not bake against a specific WorldEnvironment |
| Sky Energy | 0 | Void has no skybox; sky contribution would add incorrect ambient |

---

## Mobile VRAM budget for lightmaps

A 2048×2048 atlas at RGBA8 = 16 MB raw. ASTC 6×6 compression (default Godot ASTC
preset for mobile) = ~1.1 MB. Two lightmaps (if using per-zone approach) = ~2.2 MB.

Rule of thumb: stay at 2048 max, use Texel Density 8–12 for large Threshold geometry,
accept lower density on large flat surfaces (floors, ceilings) that read well at lower
resolution.

---

## Critical architectural concern: zone atmosphere vs baked lighting

**This is the most important implication of this research.**

Threshold's zone atmosphere system swaps `WorldEnvironment.environment` between three
resources (`Env_Z1` warm sodium / `Env_Z2` cold blue-white / `Env_Z3` amber) as the
player passes through `Area3D` trigger volumes. LightmapGI bakes once against the
ambient that is active at bake time — the resulting atlas encodes that zone's ambient
colour into every surface.

Consequence: if you bake with `Env_Z1` active, Zone 2 and Zone 3 surfaces bake with
warm-sodium ambient colouring even though they should be cold and amber. Re-entering
Zone 2 and swapping `WorldEnvironment` changes the skybox-derived ambient for new
real-time lighting, but the baked colours in the atlas are already wrong.

### Options

**Option A — Don't bake Threshold at Gate 1 (recommended).** Keep all zone lighting
real-time (OmniLights + emissives). The current light budget is 9 static + 4 dynamic
= 13 OmniLights, all shadow-disabled. This is acceptable for Gate 1 device testing.
Baking is a Gate 1+ optimisation step. Defer until the geometry is design-locked and
the zone atmosphere is validated.

**Option B — Bake three lightmaps, one per zone (complex but correct).** Set the
active environment, bake for that zone, repeat three times with three separate
`LightmapGI` nodes (only one active at a time). Swap the active `LightmapGI` in
`threshold.gd`'s `_apply_zone_env` alongside the `WorldEnvironment` swap.
Three 2048×2048 ASTC lightmaps = ~3.3 MB. Complex to author, correct at runtime.

**Option C — Bake with Environment Mode = Disabled (practical middle ground).** Set
`LightmapGI.environment_mode = Disabled` before baking — the lightmap captures only
OmniLight/SpotLight contributions, no ambient. Each zone's ambient colour comes
entirely from the real-time `WorldEnvironment` swap + zone OmniLights. One lightmap
covers the whole level; only real-time indirect light is wrong (minor). **This is the
most pragmatic approach for Gate 1+ if baking is needed — one bake, no per-zone
complexity, emissive surfaces still contribute correctly.**

**Plan: Option A for Gate 1, Option C for Gate 1+ polish.**

---

## CSG geometry — prerequisite blocker (major)

**All of Threshold's level geometry is currently `CSGBox3D` / `CSGMesh3D` nodes.
CSG nodes cannot participate in LightmapGI baking.** Godot 4 has no UV2 generation
for CSG — the merged CSGShape mesh is a runtime-generated `ArrayMesh` with no
lightmap UV channel. This is an engine limitation, not a project choice.

Before any bake pass, the following must happen:

1. **Finalize Threshold geometry on device** (no more major layout changes). Lock
   the design before converting — CSG conversion is not reversible without
   re-authoring.
2. **Convert CSGBox3D nodes → `MeshInstance3D` + `StaticBody3D` pairs.** Options:
   a. Export from Godot's CSG: `CSGShape → Mesh → Save as .res`. Reparent result as
      `MeshInstance3D`; add `StaticBody3D` with `BoxShape3D` or `ConvexPolygonShape3D`.
   b. Author box meshes directly in Blender/equivalent and import as `.glb`.
      Import setting: enable "Generate Lightmap UV2." This is the cleaner path for
      the Gate 1 art pass anyway (when real concrete textures land).
3. **Generate UV2** on all converted meshes. Editor: select `MeshInstance3D` →
   Mesh menu → Generate UV2. Or via import settings on `.glb` assets.
4. **Rebuild collision shapes** to match the new geometry.

This conversion is also the natural Gate 1 art pass action — when Poly Haven
concrete textures land, the CSG geometry will be replaced with properly UV-mapped
`.glb` kit pieces anyway. Baking and the art pass can share the same geometry prep.

---

## Which objects stay dynamic (never baked)

| Object | Setting | Reason |
|--------|---------|--------|
| `ServiceCart` (moving platform) | GI_MODE_DYNAMIC or Disabled | Moves; baked position would be wrong |
| `IndustrialPress` | GI_MODE_DISABLED | Moves; AnimatableBody3D |
| `MaintArm1` (rotating hazard) | GI_MODE_DISABLED | Rotates |
| DataShard OmniLights (× 4) | Bake Mode = Disabled | Move when shards collected; cosmetic |
| `HazardStripe` / `CartLight` / `ConduitLeft/Right` emissives | GI_MODE_STATIC | Static emissives; their light contribution bakes nicely into nearby surfaces |
| Zone OmniLights (Z1Light1/2/3, etc.) | Bake Mode = Dynamic | Must vary per zone; baking one zone's lights into all zones is wrong |
| Checkpoint WarmLight | Bake Mode = Static (Option C only) | Static position; fine to bake with Env Disabled |

---

## Performance delta to expect

Measured reference from `godot_mobile_perf.md`: each real-time shadow-disabled
`OmniLight3D` costs ~0.3–0.5 ms on Adreno 610-class. Threshold's 9 static
OmniLights = ~2.7–4.5 ms of the ~6.9 ms current frametime in editor. Baking
them would recover that headroom.

However: **only bake after on-device frametime measurement** (currently pending).
If the 13-light scene runs at 8–10 ms on the Nothing Phone 4(a) Pro (still within
budget), baking is a nice-to-have, not a necessity. Gate 1 is about design
correctness; optimisation follows.

---

## Implications for Project Void

1. **No baked lighting for Threshold at Gate 1.** Real-time OmniLights are
   architecturally correct for the zone atmosphere system. Baking deferred.
2. **CSG → MeshInstance3D conversion is required before any bake** and is also
   the art-pass prerequisite. These happen together — flag as a paired task in PLAN.
3. **When baking, use Option C (Env Disabled).** Avoids three-lightmap complexity
   while preserving zone OmniLight contributions in the atlas.
4. **Zone OmniLights must stay Dynamic** (not baked). They are the primary zone
   identity mechanism; baking them to the wrong zone would break the atmosphere.
5. **Emissive surfaces (Zone 2 HazardStripe, ConduitLeft/Right) contribute to the
   Option C bake** — their warm/cold glow will light nearby floors and walls in
   the atlas, reinforcing zone identity at zero runtime cost. This is a feature.
6. **Lightmap atlas target: 2048×2048 ASTC (~1.1 MB).** With Texel Density 8–12
   this comfortably covers Threshold's ~24×36 m plaza, ~16 m maintenance yard,
   and ~60 m gantry run.
7. **Profile first on device.** If frametime is within budget without baking, don't
   bake — every bake cycle is a development cost (minutes per bake, CSG conversion
   work, potential art regression).
