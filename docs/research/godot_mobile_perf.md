# Godot 4 Mobile Renderer — Performance Notes

_Research for Project Void. Written 2026-05-09 before first on-device run._
_Primary concern: sustain 60 fps on Nothing Phone 4(a) Pro (Snapdragon → Adreno GPU)._

---

## What the Mobile renderer is (and isn't)

Godot 4 ships three render pipelines:

| Pipeline        | Notes |
|-----------------|-------|
| Forward+        | Full feature set. NOT suitable for mobile — high GPU cost. |
| Mobile          | **We use this.** Clustered-light subset. Most features work. |
| Compatibility   | GL-ES 3.0. Ultra-low-end fallback. Loses most PBR. |

Mobile renderer omissions relevant to us:
- No SDFGI (global illumination). We use baked lightmaps — fine.
- Volumetric fog: depth-based only (still works for our heavy-fog aesthetic).
- No real-time GI probes.
- MSAA: hardware-dependent; some Adreno drivers refuse it. Prefer FXAA or no AA.
- Screen-space ambient occlusion: off by default on Mobile, keep it off.
- Screen-space reflections: not available. Use reflection probes (baked) or none.

## Tile-Based Deferred Rendering (TBDR) — how Adreno works

Adreno (Snapdragon), Mali (Exynos/MediaTek), and Apple GPU all use TBDR.
The GPU divides the framebuffer into 16×16 px tiles and renders each tile
entirely in on-chip SRAM before flushing to main memory. Consequence:

**What this means for us:**

| Practice | Why |
|----------|-----|
| Keep transparent objects rare | Alpha blending forces a tile resolve → extra bandwidth. Our sparks (ImmediateMesh) fire ≤12 lines per respawn — fine. Avoid alpha on every-frame objects. |
| Avoid mid-frame render target switches | Switching FBO mid-frame forces a tile flush. One pass (shadow → main) is fine; more than two is expensive. |
| Baked shadows > real-time | Each shadow pass is an extra render, forcing tile flushes. One directional light shadow is OK; avoid OmniLight shadow maps entirely. |
| Overdraw matters | Pixels re-drawn within the same tile cost on-chip SRAM bandwidth. Fog + dark world reduces overdraw naturally (far geometry culled by fog). |
| Draw call count matters less than on desktop | TBDR is relatively tolerant of draw calls, but each call has CPU overhead in Godot. Keep under 100 for comfort. |

## Budgets (Nothing Phone 4(a) Pro target, 60 fps)

Frame time budget: **16.67 ms** total; target **8–10 ms** render (headroom for thermal throttle).

| Budget | Limit | Why |
|--------|-------|-----|
| Triangles on screen | 80k | Adreno rasterises fast but vertex shading is shared with fragment |
| Draw calls | ≤ 80 | CPU dispatch cost in Godot Vulkan Mobile |
| Dynamic lights (OmniLight/SpotLight, no shadow) | ≤ 4 | Clustered forward light loop |
| Dynamic lights WITH shadow maps | 0–1 | One shadow pass costs ~3 ms on mobile |
| Transparent draw calls | ≤ 10 | Tile resolve cost (see above) |
| VRAM (textures + meshes) | ≤ 200 MB | ASTC 4×4 compresses textures ~6× vs RGBA8 |

## ASTC texture compression

The project is already configured for ASTC (set in kickoff). Notes:
- Godot auto-selects between ASTC 4×4 (higher quality) and ASTC 6×6 (smaller) based on the import preset.
- For UI textures, ASTC 4×4; for world geometry, ASTC 6×6 is fine.
- Normal maps: use ASTC 4×4 for correct precision (or RG channels only).
- All textures must be power-of-two dimensions for correct ASTC packing.

## Lighting strategy

For Gate 0 (Feel Lab):
- One warm OmniLight/SpotLight — already in place. No shadow needed at this stage.
- Ambient from WorldEnvironment (already set: 0.4 energy). Bake it when adding real geometry.

For Gate 1+:
- **Bake all lighting** before building the level. LightmapGI with `bake_quality = Medium` is fine.
- Avoid adding dynamic OmniLights post-bake — each one re-enables the real-time path.
- The one exception: the player's "glow settle" emission on reboot is a material emission, not a light — zero cost.
- Directional sun light can stay dynamic if shadows are disabled (`shadow_enabled = false`). Enable shadow only if baking isn't an option.

## Particle systems

- Godot's GPUParticles3D: one draw call per emitter, vertex shader cost per particle.
  On Adreno, 100 particles per emitter is safe; 500+ starts to hurt at 60 fps.
- Our reboot sparks use ImmediateMesh LINE_PRIMITIVE — not a particle system.
  12 lines = 24 vertices, one draw call, frees after 0.5 s. Near-zero cost. ✓
- For Gate 1, if adding ambient dust/debris particles: keep emitters to ≤ 200 particles,
  set `transform_align = Y` (avoids per-particle sort), keep draw order consistent.

## Physics (Jolt 3D)

Jolt is set as the 3D physics engine. Key notes:
- Jolt's capsule-on-static-mesh queries are deterministic and fast — good.
- Avoid Trimesh collision shapes on moving objects (very expensive). Our moving platform uses BoxShape3D ✓.
- StaticBody3D with BoxShape3D/CapsuleShape3D: near-zero cost per collision query.
- If adding many enemies in Gate 1, profile physics separately (`Remote > Monitors > Physics 3D`).

## Profiling on device

When the build runs on device:
1. Enable `Remote` tab in editor, connect ADB.
2. Check `Profiler > Render thread` — look for `draw_calls`, `vertices_3d`.
3. Check `Monitors > GPU time` (Godot reports as ms on Vulkan Mobile).
4. Watch `Time > Frame` in the Remote monitor for spikes above 16 ms.
5. The always-on corner HUD (`hud_overlay.gd`) shows frametime in-game — use it.

Key warning signs at first run:
- Frame time > 10 ms at rest → investigate draw call count first.
- Jitter without consistent peak → physics tick overrun or GC pause.
- Sustained 20+ ms → likely a transparent/alpha overdraw problem.

## Implications for Project Void

1. **Keep alpha-blended objects exceptional.** The only current transparent draw is reboot sparks (rare, brief). If adding fog-particle ambience, use a mesh-based approach or vertex-alpha on geometry rather than alpha-blended quads.
2. **One shadow-caster maximum for Gate 1.** Either a baked sun or a single spotlight over the player. Not both.
3. **Bake lightmaps before Gate 1 review.** The brutalist palette (dark concrete + single warm light) bakes beautifully — we lose nothing and gain ~3 ms per frame.
4. **Draw call budget per level:** target ≤ 50 at Gate 1 mid-level view (player + platforms + UI ≈ 15–20 calls baseline; 30 budget for geometry).
5. **ASTC compression is already on** — don't disable it for "convenience" when bringing in real art.
6. **Profile Jolt separately.** If physics ticks spike above 3 ms, look at collision shape complexity first (trimesh vs primitives).
7. **No MSAA** — FXAA only. The brutalist low-saturation aesthetic hides aliasing better than colorful games anyway.
8. **OLED black already baked in** — background_color `(0.04, 0.04, 0.05)` reads as true black on OLED. Don't raise it for "atmosphere"; the fog handles depth.

## Sources

- Godot 4 docs: Rendering → Mobile renderer, Lights → LightmapGI.
- Arm Mali GPU Best Practices (2023): tile-based rendering, alpha blending cost.
- Qualcomm Adreno OpenGL ES Developer Guide: TBDR tile flush triggers.
- Godot community thread "Optimizing for Android" (2024): draw call heuristics.
- Project Void `docs/CLAUDE.md`: budget numbers confirmed at kickoff.
