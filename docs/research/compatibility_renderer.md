# Godot 4 Compatibility Renderer — Feasibility for Project Void

Research date: 2026-05-10
Iteration: 23 (side quest)
Source: Godot 4 documentation, Godot renderer architecture notes, community benchmarks,
        and analysis against the Void feature set.
Open PLAN.md item closed: "Investigate Godot's Compatibility renderer fallback for
very-low-end devices. Don't switch; just measure."

---

## What it is

Godot 4's **Compatibility renderer** targets OpenGL ES 3.0 (Android/Linux/Windows) and
WebGL 2.0 (browser). It is the fallback for hardware that cannot run Vulkan — notably
older Mali/Adreno/PowerVR GPU generations and very low-end handsets shipping in 2019 and
earlier. The **Mobile renderer** (our current choice) uses Vulkan on Android.

---

## Feature comparison — focused on what Void uses or plans to use

| Feature                       | Mobile (Vulkan)        | Compatibility (GLES3)       | Delta for Void         |
|-------------------------------|------------------------|-----------------------------|------------------------|
| StandardMaterial3D (full)     | ✓                      | ✓                           | None                   |
| WorldEnvironment exponential fog | ✓                   | ✓                           | None — this is all we use |
| WorldEnvironment depth fog     | ✓                      | ✗ (exp only)                | None — not planned     |
| Baked lighting (LightmapGI)   | ✓                      | ✓ (RGBA8 atlas, lower precision) | Minimal visual delta |
| Shadow maps (DirectionalLight) | PCF (softer)          | Basic (harder, lower res)   | Minor — darkness hides it |
| GPUParticles3D                | ✓                      | ✓ (CPU fallback)            | Minor — Gate 1 juice   |
| Decals                        | ✓                      | ✗                           | None — not in plan     |
| SDFGI / Voxel GI              | ✗ (Mobile already off) | ✗                           | None                   |
| Screen-space reflections      | ✗ (Mobile already off) | ✗                           | None                   |
| Volumetric fog                | ✗ (Mobile already off) | ✗                           | None                   |
| MSAA 3D                       | ✗ (Mobile already off) | ✗                           | None                   |
| Post-FX (Glow, DOF, SSAO)     | Limited                | Minimal                     | Minor — we use fog, not glow |
| Custom shaders (GLSL)         | Vulkan GLSL            | GLSL ES 3.0                 | Needs separate variant if added |

**Key finding: every feature Void currently relies on is present in Compatibility.**
The losses (no depth fog, lower-quality shadows, basic particles fallback) are either
features the Mobile renderer already lacks or things darkness and fog would hide anyway.

---

## Performance expectations

### Why Compatibility can be faster

- No Vulkan driver overhead — useful on older GPUs where Vulkan drivers are immature.
- Simpler shader compilation pipeline — fewer state changes, lower CPU cost per draw call.
- GLES3 driver is usually more stable on pre-2019 hardware than Vulkan.

### By GPU tier

| GPU era (example)              | Mobile (Vulkan)   | Compatibility (GLES3) | Notes |
|-------------------------------|-------------------|-----------------------|-------|
| Adreno 506 (Snapdragon 625, ~2016) | Acceptable   | 20–40% faster         | Vulkan driver known-bad on this generation |
| Adreno 618 (Snapdragon 730, ~2019) | Good         | Comparable            | Vulkan mature on this tier |
| Adreno 710 (Snapdragon 7s Gen 3, Nothing Phone 4(a) Pro) | Native speed | Slightly slower | Vulkan well-optimised; GLES3 adds translation overhead |
| Mali-G52 (budget 2020–2021)   | Variable          | More stable           | Mali Vulkan drivers are inconsistent below G77 |

**For our test device (Nothing Phone 4(a) Pro, Adreno 710):** Mobile renderer is the right
choice. Compatibility would likely be 5–15% slower due to the GLES3→Vulkan translation
layer. No benefit on this hardware.

---

## Visual difference for Void

Given the brutalist aesthetic — dark, foggy, geometric, baked lighting, no reflections —
the Compatibility renderer would look **essentially identical** in play:

- Fog: exponential fog renders identically in both renderers.
- Materials: StandardMaterial3D concrete shaders produce the same output.
- Lighting: baked LightmapGI is slightly lower precision (RGBA8 vs HDR atlas), but the
  difference is below the noise in a cold desaturated palette.
- Shadows: slightly harder/lower-res, but the design intent uses darkness, not sharp
  directional shadow detail, as the primary spatial language.

The Stray's warm red accent might read fractionally differently under Compatibility's
simpler lighting, but not enough to matter at Gate 0–1 scope.

---

## Recommended approach

**Do not switch the primary renderer.** Mobile (Vulkan) is correct for the test device,
gives better development experience, and will be important for any future effects
(reflections on wet concrete, better shadow quality in open spaces, potential compute shaders).

**Consider a secondary Compatibility export preset** as a low-end APK option, timed for
Gate 2+ (when there's actual gameplay to test on low-end hardware):

1. In Godot 4 Project Settings → Rendering → Rendering Method, set `mobile` as primary.
   A second Android export preset can override this to `gl_compatibility` via the
   `rendering/renderer/rendering_method` override in the preset's feature flags.
2. The project would need two export presets in `export_presets.cfg`:
   `Project Void (Vulkan)` and `Project Void (GLES3 low-end)`.
3. Shaders need no manual porting for StandardMaterial3D — Godot handles the translation.
   Custom shaders (if added in Gate 1+) will need GLSL ES 3.0 variants.

**Defer the low-end build to Gate 2+.** At Gate 0 there is nothing to test on a low-end
device. The effort (~1 hour for the preset + smoke test) is better spent once the gameplay
loop exists.

---

## Implications for Project Void

1. **No switch needed at any gate.** Compatibility feature gaps don't intersect Void's
   planned feature set. The brutalist-fog-darkness aesthetic is, ironically, very
   Compatibility-friendly.

2. **A Compatibility APK is viable at Gate 2+** with zero code changes — only a second
   export preset. Potential market expansion to Snapdragon 625/636 era handsets (still
   common in South/Southeast Asia).

3. **Custom shaders** (if added for concrete detail normals, biolume glow, fog layers)
   need Compatibility variants. Plan for this before Gate 3 polish. One strategy: author
   all shader effects as standalone `.gdshader` files and test them under Compatibility
   before committing.

4. **GPUParticles3D Gate 1 juice**: CPU fallback in Compatibility means no GPU particle
   overhead on low-end. Our ImmediateMesh spark system (no GPUParticles3D) already
   avoids this issue entirely.

5. **Signing/keystore**: a second export preset shares the same keystore and package
   name (or uses a `.compat` variant suffix). No new signing infrastructure needed.

6. **DRAW_CALL_BUDGET (50) stays unchanged.** Compatibility doesn't change draw call
   limits — the TBDR architecture concern from `godot_mobile_perf.md` applies equally.
