# TBDR Mobile GPU Costs — PowerVR / Mali / Adreno

Research for Project Void. Written 2026-05-14, iter 74.
Audience: informs draw-call strategy, CSG → MeshInstance migration, and
the upcoming Gate 1 texture/bake pass.

---

## The TBDR pipeline

Desktop GPUs (and Vulkan on PC) use an **Immediate Mode Rendering (IMR)**
pipeline: draw calls execute in submission order, writing directly to DRAM.
Mobile GPUs (PowerVR, Mali, Adreno) use **Tile-Based Deferred Rendering
(TBDR)**:

1. **Binning pass** — each draw call's geometry is sorted into small screen
   tiles (typically 16×16 or 32×32 px). The GPU writes a lightweight "tile
   list" (vertex positions only) to on-chip SRAM.
2. **Rendering pass** — each tile is rendered fully in fast on-chip memory
   before being written out to DRAM once. No per-pixel DRAM round-trips
   mid-frame.

**Key consequence for Void:** DRAM bandwidth, which is the primary power and
latency bottleneck on Android, is massively reduced versus IMR. TBDR is why
the Nothing Phone 4(a) Pro can sustain 60 fps with reasonable battery life.

---

## Cost structure differences from PC

### Draw calls are cheap (but not free)

Each draw call adds a new entry in the binning pass. On TBDR this costs far
less than on IMR because the GPU doesn't flush caches between submissions.
**Rule of thumb for target SoC class (Snapdragon 7s Gen 3 / Adreno 720):**
~500–1000 draw calls before the CPU cost of emitting them becomes the
bottleneck, not the GPU. Godot 4 Mobile renderer's GLES-style batching is
appropriate; don't stress the < 50 draw-call target for fill-rate reasons
— stress it because *CPU submission cost* is real even if GPU TBDR cost is low.

### Alpha blending is expensive

TBDR on-chip memory is used once per tile, then flushed. **Any alpha-blended
surface forces the GPU to read back the existing tile before blending**, which
breaks the "write once" model and costs an extra tile read per fragment.

**Implication:** Keep alpha-blended objects minimal. Godot's particles, ghost
trail MultiMesh (`set_instance_color` with alpha), and the DataShard emissive
pulse are the three current alpha-blended objects in Threshold. All are
acceptable; avoid adding more without measuring.

### Depth pre-pass tradeoff

TBDR hardware (especially PowerVR Imagination) has a **Hidden Surface
Removal (HSR)** stage built into the binning pass. It discards occluded
fragments *before* the fragment shader runs — effectively a free depth pre-pass.
Godot 4 Mobile renderer does not emit a separate depth pre-pass for opaque
objects; HSR on the GPU handles this instead. **Do not add a manual depth
pre-pass** — it adds CPU overhead and binning cost with no benefit on TBDR.

### Framebuffer loads / render target switches

Each time Godot switches render targets (e.g. SubViewport, post-processing
ping-pong, shadow map pass) the TBDR must *flush* the on-chip tile buffer to
DRAM. This is expensive. The Mobile renderer avoids most of these.

**Implication:** Avoid SubViewport-based UI or effects in Gate 1. The dev
menu is a CanvasLayer — that's fine, one tile-flush at UI blit time. A
second SubViewport for a minimap would be two per-frame flushes. Skip it.

---

## Architecture-specific notes

### Adreno (Qualcomm — our test device)

- Adreno 720 (Snapdragon 7s Gen 3): TBDR with hardware binning, HSR
  equivalent called **LRZ (Low Resolution Z)**. LRZ performs early-Z
  rejection before the main rasterizer.
- LRZ works best when opaque draw calls are submitted **front-to-back**. Godot
  4 sorts opaque objects front-to-back automatically when
  `rendering/driver/depth_prepass/enable` is false (the Mobile renderer
  default). Don't override this.
- Adreno **does not** benefit from the manual "depth pre-pass trick" that
  helps Mali in some scenarios. LRZ is already doing that job.
- Adreno has a relatively generous vertex throughput. The ~80k tri budget is
  set by thermal throttle and fill rate, not geometry cost.

### Mali (ARM — common mid-range)

- Uses a **Forward Pixel Kill (FPK)** mechanism similar to Adreno LRZ. Also
  benefits from front-to-back draw submission.
- Mali's tile size is configurable (16×16 default). Larger tiles increase
  on-chip memory reuse but can overflow SRAM and cause spills to DRAM on
  complex scenes. Godot 4 Mobile renderer uses Vulkan's default tile
  configuration; leave it alone.
- Mali benefits more than Adreno from explicit Vulkan render pass load/store
  `DONT_CARE` hints, which Godot 4's Vulkan backend emits correctly.

### PowerVR (Imagination — older mid-range, budget devices)

- The original TBDR architecture. HSR is PowerVR's term; it is the most
  aggressive of the three — fully deferred fragment shading means the
  fragment shader only runs once per visible pixel.
- PowerVR drivers on Android are often older and less optimized for Vulkan.
  If targeting PowerVR devices (budget market), test with the Godot 4
  **Compatibility renderer (GLES3)** — it has better PowerVR compatibility
  than Vulkan. See `compatibility_renderer.md`.
- Not relevant for the test device (Adreno). Relevant if Gate 2+ adds a
  Compatibility export preset for low-end market.

---

## Implications for CSG → MeshInstance3D migration

The upcoming Gate 1 work converts all Threshold `CSGBox3D` nodes to
`MeshInstance3D + StaticBody3D`. TBDR implications:

1. **MeshInstances are statically batched** by Godot's multimesh and surface
   system; CSG nodes are not. The migration will reduce draw calls, which
   lowers CPU binning submission cost.
2. **UV2 generation** (required for LightmapGI baking) is possible on
   MeshInstance3D via `ArrayMesh.lightmap_unwrap()` but impossible on CSG.
   This is the blocker documented in `baked_lighting.md`.
3. **Static bodies** from CSG are exact collision meshes; after migration,
   use `StaticBody3D` with a matching `ConvexPolygonShape3D` or
   `BoxShape3D` per surface — do not use `ConcavePolygonShape3D` for dynamic
   objects (Jolt concave vs convex constraint).
4. **No draw-call regression expected** — MeshInstance3D surfaces can share
   materials (mat_concrete / mat_concrete_dark), allowing Godot's surface
   batch pass to merge them into fewer calls than the current one-CSG-per-
   node pattern.

---

## Implications for Project Void (summary)

1. **Draw-call budget is a CPU budget, not a GPU budget** on TBDR. Keep
   Threshold under ~50 calls not because the GPU is limited but because
   reducing CPU submission cost buys frametime headroom on the logic thread.
2. **Alpha blending is the real TBDR cost driver.** Ghost trail MultiMesh
   (alpha), DataShard pulse (alpha), particles (alpha) — keep these togglable
   and off by default until the device frametime is measured. Already the case.
3. **No manual depth pre-pass needed.** Adreno LRZ handles early-Z rejection
   automatically. Adding one would waste CPU and binning time.
4. **SubViewports = tile flushes = avoid.** Every SubViewport is an extra
   DRAM write per frame. CanvasLayer UI is fine; SubViewport UI is not.
5. **CSG → MeshInstance migration reduces CPU binning cost and enables baking.**
   Both benefits align; do this migration in the same pass as the texture art.
6. **Front-to-back opacity submission** (Godot's default) is correct for both
   Adreno LRZ and Mali FPK. Don't override Godot's sort order for opaque draws.
7. **Compatibility renderer** (GLES3) is the right choice for PowerVR/budget
   devices if Gate 2+ adds a low-end export preset. Zero code changes required.

---

## Sources

- Arm Developer: "Mali GPU Architecture" whitepaper
- Qualcomm Developer Network: "Adreno GPU Best Practices"
- Imagination Technologies: "PowerVR Performance Recommendations"
- Google Android GPU Inspector documentation (TBDR concepts)
- Godot 4 source: `drivers/vulkan/rendering_device_vulkan.cpp` render pass hints
- `docs/research/compatibility_renderer.md` (cross-reference: GLES3 vs Vulkan)
- `docs/research/baked_lighting.md` (cross-reference: CSG blocker)
- `docs/research/godot_mobile_perf.md` (baseline mobile perf research)
