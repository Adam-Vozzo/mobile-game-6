# Art Pipeline — Project Void

How to take an authored or acquired 3D asset (mesh, texture, animation, audio) and replace a placeholder primitive with it, without breaking gameplay, performance, or art direction.

## Style guardrails (read before authoring or acquiring)

- World: brutalist megastructure. Heavy concrete, exposed structure, geometric repetition, industrial decay. Vast scale.
- Palette: concrete greys, charcoal, rust orange, sodium-vapour yellow. Biolume cyan as rare accent. Deep blacks. The Stray's red is the only constant warm bright element. Use red sparingly elsewhere.
- Lighting: baked, sparse. Pools of warm light in vast darkness. Heavy fog.
- Detail density: low to mid. Empty silhouettes and good proportions over busy surface detail. Brutalism is mass and shape, not micro-detail.
- Performance budget: every asset competes for the on-screen 80k tri budget and the particle/draw-call budgets.

## Asset sources you can use freely

No approval needed for any of these. Just acquire, run the style-fidelity check, and log in `assets/ASSETS.md`.

### 3D models

- Kenney (kenney.nl) — CC0, low-poly, often style-friendly to brutalist with palette swaps.
- Quaternius (quaternius.com) — CC0, low-poly, large kits.
- Sketchfab — filter by CC0 or CC-BY licences. Rich source for hero props but verify polycount before downloading.
- Mixamo — character animations and rigs. Free for commercial use, attribution not required, but read the EULA when committing.
- Polyhaven (polyhaven.com) — CC0 PBR textures, HDRIs, props.
- OpenGameArt — mixed licences; filter carefully.
- Itch.io asset packs — many free, mixed licences.
- AI-generated (any tool you have access to) — check the tool's licence terms; most generated content is usable.

### Audio

- freesound.org — CC0/CC-BY/CC-Sampling+; check per-file licence.
- Sonniss GDC bundles (royalty-free game audio) — check current bundle.
- OpenGameArt audio section.
- Pixabay audio — royalty-free, attribution not required.

### Shaders / VFX

- Godot Shaders (godotshaders.com) — community shaders, mostly MIT or CC0.
- Built-in Godot resources.

### Avoid

- GPL-licensed assets (force the project to be GPL if shipped).
- "Non-commercial only" assets (we don't know yet if the project will ship — easier to stay clean).
- Anything where the licence is unclear or unstated. If you can't find it, don't commit it.

## Logging — `assets/ASSETS.md`

Every third-party asset committed gets an entry. Format:

```
- assets/art/character/mesh_stray.glb
  Source: https://example.com/asset-page
  Author: <name or "n/a">
  Licence: <CC0 / CC-BY-4.0 / Mixamo EULA / etc.>
  Date acquired: 2026-05-08
  Notes: <attribution string if required, modifications made>
```

For CC-BY assets, paste the exact attribution string the licence requires. We'll surface these in an in-game credits screen later.

## Style fidelity check (mandatory before committing)

Run this for every asset before committing it. Open the style test scene (`scenes/levels/style_test.tscn` — create one if missing — that places the asset alongside the Stray and existing environment kit at typical camera distance, with the project's fog and lighting). Then ask:

1. **Palette fit**: do the asset's colours sit within the brutalist palette, or pull attention away from the Stray's red?
2. **Silhouette**: does it read clearly against fog at gameplay distance?
3. **Detail density**: is it appropriately restrained for the world's "mass and shape" aesthetic, or does it look like surface noise?
4. **Tonal fit**: does it carry the right mood — oppressive, industrial, mysterious — or does it import a different tone (cartoonish, fantasy, sci-fi-glossy)?
5. **Scale**: is it correctly sized relative to the Stray (~0.8 m)?

If it fails any of these, modify it (palette swap, decimate, retexture) or decline. Asset-flip drift is the failure mode.

## Format and import conventions

### Format

- Meshes: glTF 2.0 binary (`.glb`) preferred. Single-file, includes textures, embeds animations and skins cleanly. Godot 4 imports glTF natively.
- Textures (standalone): `.png` or `.webp` for editing source; Godot will compress on import. Avoid `.jpg` for hard edges.
- Audio: `.ogg` for music and longer SFX, `.wav` for short impact SFX.

### Scale convention

- 1 Godot unit = 1 metre. Always.
- The Stray is ~0.8 metres tall.
- A standard platform tile is 2 m × 2 m × 0.5 m (W × D × H).
- Author at correct scale. Don't fix scale in Godot — breaks physics and animation predictability.

### Pivot conventions

- Characters/actors: pivot at the feet, centred horizontally.
- Static props: pivot at the base, centred horizontally.
- Modular environment pieces: pivot at the corner that snaps to the world grid (snap unit: 0.5 m).
- Animated mechanisms: pivot at the rotation/translation axis.

### Naming

- Files: `snake_case`, type-prefixed.
  - Meshes: `mesh_<thing>.glb` — e.g. `mesh_stray.glb`, `mesh_platform_2x2.glb`.
  - Textures: `tex_<thing>_<channel>.png` — e.g. `tex_concrete_albedo.png`, `tex_concrete_orm.png` (Occlusion-Roughness-Metallic packed).
  - Materials: `mat_<thing>.tres`.
  - Audio: `sfx_<thing>.wav`, `mus_<thing>.ogg`.

### Texture sizes

- Stray (hero): 1024² max.
- Hero environment props: 1024² max, 512² preferred.
- Modular tiles: 512², heavily reused.
- UI: as needed, but pack into atlases.
- Compression: ASTC on Android target. "Detect 3D" off for UI textures.

### Material setup

- Standard 3D material with ORM packing (Occlusion in R, Roughness in G, Metallic in B). Halves texture sample count.
- For brutalist concrete: high roughness (0.7–0.95), zero metallic, normal map for surface variation, optional detail tile for close-ups.
- For rust/metal accents: roughness 0.4–0.7, metallic 0.6–1.0 only on actual metal.
- For the Stray's red accent: emissive layer, low base colour, mild bloom permitted.
- Avoid translucency on Mobile renderer. Fake glow with emissive + bloom (sparingly).

## Swapping a primitive for a real mesh — step by step

Scenario: the Stray is currently a `MeshInstance3D` with a `BoxMesh`. We want to replace it with a custom rigged robot.

1. Acquire or author the mesh at correct scale (the Stray is ~0.8 m). Apply scale and rotation before export. Pivot at feet.
2. Set up the armature if rigged. Name bones consistently. Keep bone count modest (<40 for chibi character).
3. Bake animations with clear action names: `idle`, `run`, `jump_start`, `jump_apex`, `jump_land`, `reboot`. Set looping flags correctly.
4. Export as glb: include selected, +Y up, apply modifiers, include animations and skinning.
5. Drop the `.glb` into `assets/art/character/`. Append entry to `assets/ASSETS.md`.
6. Open the import dock for the file:
   - Generate physics shapes: off (we use a separate `CollisionShape3D` on the player root).
   - Compress: on.
   - Use Named Skins: on.
   - Material location: Material.
   - Animation import: ensure clips appear with correct loop modes.
7. New Inherited Scene from the `.glb` → save as `scenes/player/player_visual.tscn`.
8. Open `scenes/player/player.tscn`:
   - Add `player_visual.tscn` as a child under the `CharacterBody3D` root.
   - Position it so feet sit at local Y = 0.
   - Delete the placeholder `MeshInstance3D`.
9. Verify the `CollisionShape3D` still wraps the visual. The collider should match the gameplay silhouette (close to a capsule), not the visual silhouette — don't grow it for an antenna or chest accent.
10. Hook animations: `AnimationPlayer` reference in the player script, driven from controller state via signals. Cross-fade durations: 0.05–0.15 s.
11. Run the style fidelity check in `scenes/levels/style_test.tscn`.
12. Test in Feel Lab. Check: silhouette readable against fog, animation transitions don't stutter, collider feels right, no T-pose flashes between clips.
13. Performance check: dev menu's perf overlay. Within budget? If not, decimate.
14. Commit with the asset, scene, and `ASSETS.md` entry in the same commit. Note in `README.md` that the Stray's visual was promoted from primitive.

## Swapping environment primitives

Same shape, with these differences:

- Author a small kit of pieces (5–10 wall variants, 3–5 floor types, a few trims and pillars) rather than one-off geometry.
- Use `MultiMeshInstance3D` for any piece that repeats more than ~20 times.
- Snap to the 0.5 m grid in scenes. If a piece doesn't snap cleanly, fix the source asset.
- For brutalist concrete, lean on trim sheets and detail normal maps. One 1024² trim sheet can clothe an entire level.
- Bake lighting after placement. Mobile renderer: lightmaps only.

## Swapping in audio

- Drop `.ogg` (music) or `.wav` (SFX) into `assets/audio/`. Log in `ASSETS.md`.
- Verify Godot's import dock picked the right loop / 3D / streaming settings.
- Use Audio Buses for grouping (`SFX_Player`, `SFX_World`, `Music`) for central mixing.
- For the Stray's movement: layer servo whirs (looped, pitch-modulated by speed) under footstep impacts. Jump: anticipation hum + impact + air ring-out. Land: clank + dust puff. Reboot: sparks + power-on hum + boot chord.
- Keep peak loudness consistent across the SFX set.

## Performance gotchas to watch

- Transparent materials on Mobile renderer are expensive. Use alpha-tested cutout where possible.
- Real-time lights are limited. Bake everything that doesn't need to move. Reserve real-time for the Stray's accent or a few key dynamic spots.
- Particle systems stack costs fast. Each new system needs a `JUICE.md` entry and a budget check.
- Shadows on Mobile are costly. Use sparingly; rely on baked AO and contact shadows.
- High-poly imports are the most common budget killer. If a `.glb` lands and the perf overlay spikes, decimate.

## When the human approves a style direction

- Generate (or commission) a style guide doc in `docs/style/` with: silhouette tests for hero assets, material reference, palette swatches, lighting key examples, fog density samples.
- Update `CLAUDE.md` style direction with any refinements.
- Maintain `scenes/levels/style_test.tscn` — hero asset + environment kit + Stray in one frame, used as the regression scene for art changes.

## Quick pre-flight before promoting any primitive

- [ ] Asset is at correct scale (1 unit = 1 m, Stray ~0.8 m tall).
- [ ] Pivot is correct for the asset type.
- [ ] Naming follows convention.
- [ ] Texture sizes are within budget; ASTC compression on.
- [ ] Material uses ORM packing where applicable.
- [ ] Imported into Godot, "New Inherited Scene" created and saved.
- [ ] Collision shape preserved or rebuilt to match gameplay silhouette.
- [ ] Animations transition cleanly (if rigged).
- [ ] Style fidelity check passed in `style_test.tscn`.
- [ ] Tested in Feel Lab at full speed; no perf regression.
- [ ] `assets/ASSETS.md` entry added with source and licence.
- [ ] Committed with associated scene changes.
