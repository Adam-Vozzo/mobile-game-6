# Asset Options — Project Void
## First-pick candidates for human approval

> **DECISION 2026-05-15** — Human selected full-Kenney visual direction. Selections:
> A8 Cube Pets yellow chick (Stray re-framed from robot to bird), B1+B2 freesound CC0
> ambient bed + B5 Kenney Sci-Fi Sounds for accents, C8 Factory Kit + C9 Space Station
> Kit for architecture/set-dressing. **Distant-atmosphere layer (Dadish 3D-inspired)**
> authored from `BoxMesh` primitives with dark material override — C4 Modular Buildings
> considered but rejected as too detailed for fog-blurred far Z. Photoreal concrete
> (C2 Poly Haven) dropped to avoid clash with chibi Kenney silhouettes. See `docs/DECISIONS.md`
> 2026-05-15 ADRs. Candidates A1–A7, B3/B4, C1–C7 remain below for traceability but are
> superseded.

Three asset slots were blocking Gate 1 art direction: the **Stray mesh**, the
**ambient audio bed**, and the **concrete texture kit**. Each section below
lists 3–5 candidates with source, licence, fidelity notes, and a
recommended pick.

Style fidelity benchmark: does it read in the brutalist palette under fog at
gameplay camera distance? The world is cold, dark, and vast. The Stray is the
only saturated warm thing in it.

---

## Slot A — Stray Mesh

The Stray is a small stray robot: chibi proportions, single bright-red accent,
readable silhouette. Low poly is correct for the brutalist aesthetic — it keeps
the character as a simple warm shape against complex dark geometry. The mesh
needs at minimum: idle, run, jump, land, death/reboot animations.

### Candidates

#### A1 — Quaternius LowPoly Robot
- **Source:** <https://quaternius.itch.io/lowpoly-robot>
- **Author:** Quaternius
- **Licence:** CC0 (public domain, no attribution required)
- **Format:** FBX
- **Animations:** 14 — idle, jump, dance, punch, run, death, sitting, standing,
  thumbs-up, wave, yes, no. Covers Gate 1 requirements completely.
- **Style / fidelity:**
  Cute chibi low-poly, smooth silhouette, single-colour body. Very few polys —
  reads clearly at distance against dark backgrounds. Body colour is light grey
  by default; easy to override with a `StandardMaterial3D` for the brutalist
  palette. Red accent needs a second material surface (small mesh element) or a
  post-import tweak to isolate one section. The style is slightly too "friendly"
  in isolation but should feel right once dropped into the fog-heavy megastructure
  context — the contrast is the point.
- **Fidelity risk:** Low. This is the closest available off-the-shelf option to
  the CLAUDE.md description.
- **Import path for Godot 4:** FBX → import as `.glb` via Blender re-export, or
  import FBX directly in Godot 4.4+ (FBX importer is production-ready).

#### A2 — 3D Platformer Robot (Godot Asset Library #1467)
- **Source:** <https://godotengine.org/asset-library/asset/1467>
- **Author:** CaptainRipley
- **Licence:** CC0
- **Format:** Godot `.res` / scene (authored in Godot 3.5)
- **Animations:** 20, including platformer-specific ones; 3 alternate colour
  palettes.
- **Style / fidelity:**
  Made for exactly this use case (3D platformer robot). Slightly more angular
  and mechanical than A1. Reads well as a gameplay character.
- **Fidelity risk:** Medium. Designed for Godot 3.5 — conversion to Godot 4 is
  straightforward (open in Godot 4, accept migration) but needs a quick
  verification pass. Visual style is slightly more generic / "game-kit" feeling.
- **Import path:** Download, run through Godot 4 migration wizard.

#### A3 — 3D Animated Robot (Godot Asset Library #344)
- **Source:** <https://godotengine.org/asset-library/asset/344>
- **Licence:** CC0
- **Format:** Godot scene
- **Animations:** Several; simpler geometry.
- **Style / fidelity:**
  More primitive / placeholder-grade. Acceptable for prototyping but lower
  silhouette appeal. Body geometry is closer to a cylinder-with-limbs than a
  recognisable character. Would need more material work to read as "the Stray."
- **Fidelity risk:** Medium-high. Visual identity is thin; the Stray needs to
  feel like a character, not a debug placeholder.

#### A4 — AI-generated custom (Meshy.ai or equivalent)
- **Source:** AI-generated via Meshy.ai text-to-3D or image-to-3D
- **Author:** n/a
- **Licence:** CC0 (Meshy.ai output, unless plan restricts — verify TOS)
- **Format:** GLB / OBJ
- **Animations:** None out of box — needs Mixamo retarget or manual rigging.
- **Style / fidelity:**
  Can be prompted to spec: "small chibi robot, single red visor, grey metal
  body, low poly, game-ready." Output quality varies run-to-run; the best
  outputs rival hand-made assets. Requires a review pass and possible topology
  cleanup before use.
- **Fidelity risk:** Variable. Rigging/animation gap is a real time cost.
  Best used if A1/A2 fail the device-feel pass and a custom silhouette is
  needed. Leave this as a fallback.

#### A5 — Kenney Mini Characters
- **Source:** <https://kenney.nl/assets/mini-characters>
- **Author:** Kenney (kenney.nl)
- **Licence:** CC0
- **Format:** FBX / GLTF / OBJ, pre-rigged + animated on Kenney's "1.1 Character" rig
- **Animations:** Shared rig set — idle / walk / run / jump / sit etc.
- **Style / fidelity:**
  Chibi proportions match the Stray and the shared rig gives a clean animation
  set for free. Catch: the pack is humanoid civilians, no robot variant. To
  use as the Stray you would have to swap the mesh and reuse the rig, or
  re-skin one civilian model concrete-grey with a red accent. Animation
  quality is good (Kenney's animation pipeline is reliable).
- **Fidelity risk:** Medium — rig is reusable but no robot mesh; either rig
  retarget or custom mesh work needed before this beats A1.

#### A6 — Kenney Mini Arena
- **Source:** <https://kenney.nl/assets/mini-arena>
- **Author:** Kenney
- **Licence:** CC0
- **Format:** Same Mini-series rig as A5 (FBX / GLTF)
- **Animations:** Compatible with A5 — shared Mini character rig
- **Style / fidelity:**
  20 gladiator/Roman-themed chibi characters on the same rig as A5. Theme is
  irrelevant; only value is as a rig donor with extra animation variations.
  Only listed as a fallback if A5 turns out to be unavailable or insufficient.
- **Fidelity risk:** Medium — rig donor only, no usable Stray mesh.

#### A8 — Kenney Cube Pets (SELECTED 2026-05-15)
- **Source:** <https://kenney.nl/assets/cube-pets>
- **Author:** Kenney
- **Licence:** CC0
- **Format:** FBX / GLTF, rigged + animated
- **Animations:** Shared cube-pet rig (idle / walk / run / jump / sit)
- **Style / fidelity:**
  Tiny chibi cube-pet creatures — cat, dog, chicken, etc. Yellow chick variant
  selected: bright lemon yellow against grey concrete gives strong focal-point
  contrast. Re-frames the Stray from robot to small bird — double jump becomes a
  literal wing-flap. The cube-pet silhouette is unmistakable at distance and
  reads "small living thing" cleanly against the inhuman megastructure.
- **Fidelity:** High *with palette shift*. Existing world palette's sodium-vapour
  yellow needs to read more amber/muted (Zone 1 Environment resource) to keep
  tonal separation from the chick's saturated lemon yellow. Cyan accents in
  deeper layers unchanged.
- **Consequences:** Mechanical SFX vocabulary (servo whirs, soft clanks, reboot
  hum) shifts to bird vocabulary (chirps, footfalls, wing flap, feather-poof).
  Player code (`_run_reboot_effect` squash/grow) maps to feather-poof → settle →
  flap without script changes; rename deferred to art-pass iteration. See
  `DECISIONS.md` 2026-05-15.

#### A7 — Kenney Blocky Characters
- **Source:** <https://kenney.nl/assets/blocky-characters>
- **Author:** Kenney
- **Licence:** CC0
- **Format:** FBX / GLTF, rigged + animated (v2.0 remake)
- **Animations:** Shared character animation set
- **Style / fidelity:**
  Blocky/cubic silhouettes (think Minecraft toy aesthetic). Reads "voxel
  playful" and will visually fight the brutalist concrete megastructure —
  the cubic look undercuts the cold/austere tone of Project Void. Listed
  only for completeness; lower fit than A1 / A5.
- **Fidelity risk:** High — stylistic clash with the brutalist mood.

### Recommendation
**A8 (Kenney Cube Pets yellow chick) — SELECTED 2026-05-15.** Original recommendation
was A1 (Quaternius LowPoly Robot) but the human chose full-Kenney visual consistency
over a robot brief: A8 ships a chibi creature with shared rig + animations and pairs
cleanly with Kenney C8/C9 architecture kits, avoiding the cartoon-vs-photoreal clash
that A1+C2 would have produced. A1/A2 remain on the shelf as fallback if the bird
re-framing fails on-device feel.

---

## Slot B — Ambient Audio Bed

The audio design calls for: "Echoing footsteps and servo whirs, sparse industrial
ambience, hum of distant machinery, occasional far-off mechanical groan." The
ambient bed is the always-playing layer — it sets the tone of the megastructure.
It must loop seamlessly, sit under SFX without masking them, and feel cold /
oppressive.

### Candidates

#### B1 — AlaskaRobotics "ambient spacecraft hum" (freesound #221570)
- **Source:** <https://freesound.org/people/AlaskaRobotics/sounds/221570/>
- **Author:** AlaskaRobotics
- **Licence:** CC0 (no attribution required)
- **Duration / loop:** 17.8 s, explicitly loopable
- **Sound:** Deep bass-heavy hum with layered subtle complexity. Designed for
  dramatic sci-fi / spaceship scenes. Low drone, no sharp spectral content —
  sits cleanly under SFX.
- **Fidelity:** Very high. "Distant machinery hum" is almost exactly the target
  tone for the megastructure. The bass weight gives the world inhuman scale.
  Neutral enough to work across all three Threshold zones without zone-specific
  mixing (though Zone 2 could layer B2 on top).
- **Use:** Main global ambient layer, always playing.

#### B2 — IanStarGem "Industrial/Factory Fans Loop" (freesound #271096)
- **Source:** <https://freesound.org/people/IanStarGem/sounds/271096/>
- **Author:** IanStarGem
- **Licence:** CC0
- **Duration / loop:** 6.7 s, loopable, designed as a seamless loop
- **Sound:** Mechanical fan/machinery soundscape — buzzing industrial fans,
  droning hum, FL Studio construction. Clear industrial identity.
- **Fidelity:** Good. Slightly busier spectrally than B1; better as a
  secondary/zone-specific layer (Zone 2 maintenance yard) than a global bed.
  The short loop (6.7 s) could become noticeable if used alone.
- **Use:** Zone 2 layer played on top of B1, or as a standalone Zone 2 ambient.

#### B3 — InspectorJ "Ambience, Machine Factory" (freesound #385943)
- **Source:** <https://freesound.org/people/InspectorJ/sounds/385943/>
- **Author:** InspectorJ
- **Licence:** CC BY 4.0 (attribution required — use the credit string:
  "Machine Factory Ambience by InspectorJ (freesound.org)")
- **Duration / loop:** 73.7 s, not confirmed loopable (may need trimming)
- **Sound:** Artificially constructed industrial factory ambience — printer and
  reverb layering. More "presence" than B1/B2. Richer spectral texture.
- **Fidelity:** High. The longer loop reduces repetition fatigue. Attribution
  requirement is simple (one string, no ongoing fee). The CC-BY licence is
  commercially fine.
- **Use:** Alternative global bed or Zone 3 (industrial) layer.

#### B4 — Signature Sounds "Loops of Ambience" (signaturesounds.org)
- **Source:** <https://signaturesounds.org/store/p/loops-of-ambience>
- **Licence:** CC0
- **Sound:** Curated ambient texture loop collection. Multiple tracks; specific
  industrial-fit tracks need individual review.
- **Fidelity:** Unknown without listening — varies by track. Treat as a browseable
  library; select 2–3 tracks for A/B testing.
- **Use:** Secondary sourcing if B1/B2/B3 don't satisfy on device.

#### B5 — Kenney Sci-Fi Sounds
- **Source:** <https://kenney.nl/assets/sci-fi-sounds>
- **Author:** Kenney
- **Licence:** CC0
- **Format:** ~70 audio files (Kenney standard: OGG + WAV)
- **Sound:** Sci-fi SFX one-shots — engine stings, lasers, computer blips,
  UI bleeps. Short clips, not long-form ambient loops.
- **Fidelity:** Low for the *ambient bed* role — Kenney does not ship long
  seamlessly-loopable ambient audio packs. High as a complementary SFX
  source: punchy sci-fi/mechanical clanks and engine stings that sit
  cleanly over the B1+B2 bed. Treat as additive, not substitutive.
- **Use:** Optional supplementary layer for one-shot accents (terminal
  activation, hazard windup stings, ambient mechanical "groans"). Acquire
  alongside B1/B2, not instead of.

> **Kenney ambient-bed gap.** Kenney has no dedicated atmospheric/room-tone
> pack — their audio catalogue is SFX-focused (Interface, Impact, Sci-Fi,
> UI Audio are all short clips). For the always-playing ambient layer the
> recommendation stays on B1/B2 (freesound CC0). B5 is the most useful
> Kenney audio for Project Void but it's a complement, not a replacement.

### Recommendation
**B1 as global bed + B2 as Zone 2 layer.** B1's deep hum nails "vast machine-built
world"; B2 adds specificity in the maintenance yard. Both CC0. If B1 proves too
featureless after device testing, swap in B3 (CC-BY) for the longer natural
variation. Layer B5 (Kenney Sci-Fi Sounds) over the bed for one-shot mechanical
SFX punctuation. All four can be acquired now and compared on device; they're
small file sizes.

---

## Slot C — Concrete Texture Kit

Current state: two flat-colour `StandardMaterial3D` resources
(`mat_concrete.tres` light, `mat_concrete_dark.tres` dark). For Gate 1 the
surfaces need at minimum a roughness/albedo variation; a normal map is the
highest-ROI addition. PBR (albedo + normal + roughness + AO) is the target.

ASTC constraint: Godot's import pipeline compresses textures to ASTC on Android
export automatically. Import at 2K (2048×2048) — sufficient quality at
gameplay-camera distances. 4K is wasteful on mobile.

### Candidates

#### C1 — ambientCG Concrete series
- **Source:** <https://ambientcg.com/list?category=Concrete>
- **Licence:** CC0 (the site's entire library; confirmed)
- **Count:** 40+ concrete texture variants
- **Maps:** Albedo, Normal (OpenGL), Roughness, AO, Displacement, Metallic (where applicable)
- **Resolutions:** 1K–8K JPG/PNG. Use 2K import.
- **Recommended variants for the three Threshold zones:**
  - **Zone 1 (habitation / warm):** Search "Concrete" → look for smooth/worn variants
    with neutral grey tones (e.g., `Concrete003`, `Concrete009`, `Concrete031`).
  - **Zone 2 (maintenance / cold industrial):** Look for stained or aggregate-exposed
    variants (`Concrete020`, `Concrete034`).
  - **Zone 3 (industrial / amber):** Rough, structural, possibly with form-tie holes
    (`Concrete016`, `Concrete040`).
- **Fidelity:** Excellent. These are photogrammetry-based PBR maps used commercially
  worldwide. They're what most "brutalist" indie/AA 3D games use.
- **Acquisition time:** Download 3–6 individual texture sets (the page is
  browseable without login). ~20 min.

#### C2 — Poly Haven Concrete category
- **Source:** <https://polyhaven.com/textures?c=plaster-concrete>
- **Licence:** CC0
- **Maps:** Albedo (Diffuse), Normal (both DirectX and OpenGL), Roughness, AO,
  ARM (combined), Displacement. Also EXR, glTF, and a Blender `.blend` file.
- **Resolutions:** 1K–8K. Godot add-on available for direct import.
- **Standout option:** `concrete_wall_001` — white painted concrete with trim lines,
  chipped paint, cracks, and subtle worn plaster. Reads as habitation-layer
  (Zone 1) brutalist surface.
- **Fidelity:** Excellent, comparable to ambientCG. Poly Haven textures are generally
  higher in physical accuracy; the Godot add-on (`polyhaven_asset_browser` from
  the Asset Library) streamlines import directly into the project.
- **Recommendation:** The Godot add-on makes this the lowest-friction option.

#### C3 — 3D Textures (3dtextures.me/tag/concrete/)
- **Source:** <https://3dtextures.me/tag/concrete/>
- **Licence:** CC0
- **Maps:** Color, Normal, Roughness, AO, Height (Displacement)
- **Fidelity:** Good, slightly lower resolution/quality than C1/C2 in some
  entries, but smaller file sizes. Good as a supplemental source for variants.

#### C4 — Kenney Modular Buildings kit (considered, rejected 2026-05-15)
- **Source:** <https://kenney.nl/assets/modular-buildings>
- **Licence:** CC0
- **Count:** 100 models; walls, floors, roofs, stairs, windows
- **Format:** GLTF/OBJ. No PBR textures — solid colour with basic geometry detail.
- **Rejection rationale (2026-05-15):** Initially selected for the distant-atmosphere
  layer, then reversed. Window/roof/door detail is wasted at fog-blurred far Z, and
  risks reading "suburban houses" if fog lifts during atmospheric tuning. Brutalist
  megastructure silhouettes need to be pure mass — architectural detail works against
  the aesthetic at distance. Replaced by `BoxMesh` primitives with dark material
  override (zero download cost, pure silhouette). See `DECISIONS.md` 2026-05-15
  "Distant-atmosphere layer revision."
- **When to revisit:** If BoxMesh uniformity reads flat on device, consider
  hand-authored simple `.glb` silhouettes before reconsidering C4.

#### C5 — Kenney City Kit Industrial
- **Source:** <https://kenney.nl/assets/city-kit-industrial>
- **Licence:** CC0
- **Count:** 25 models; factory/warehouse themed
- **Fidelity:** Same as C4 — geometry layer, not texture layer. Zone 2/3
  contextual props.

#### C6 — Kenney Prototype Textures
- **Source:** <https://kenney.nl/assets/prototype-textures>
- **Licence:** CC0
- **Count:** 75 tiling textures, PNG
- **Maps:** Diffuse-only / tiling (no PBR normal/roughness/AO maps).
- **Fidelity:** Useful as a greyboxing/blockout layer while the C1/C2 PBR
  pipeline is being set up — muted grid greys read fine as placeholder
  concrete under fog. Not a final-quality option: the lack of normal maps
  means lighting on these surfaces is flat, which kills the dramatic
  sodium-yellow / cold-blue / amber zone lighting. Acquire if you want a
  fast first-pass material upgrade without the PBR setup; replace with
  C1/C2 during the art pass.
- **Use:** Greybox upgrade layer, swap-out target.

#### C7 — Kenney Modular Space Kit
- **Source:** <https://kenney.nl/assets/modular-space-kit>
- **Licence:** CC0
- **Count:** 40 modular meshes (FBX / GLTF / OBJ)
- **Fidelity:** Closest Kenney has to a modular megastructure-interior kit.
  Clean snap-grid geometry — useful for laying out internal corridors and
  rooms. Caveat: silhouettes read "sci-fi space station" (panelled walls,
  rounded greebles, vent grates), not "raw poured-concrete brutalism." With
  C2 Poly Haven concrete materials applied the surface fits the palette, but
  the underlying topology will still feel more "ship interior" than
  "monolithic concrete slab." Worth holding for Zone 2 maintenance-yard
  blockouts rather than primary Zone 1/3 architecture.
- **Fidelity risk:** Medium-high — geometry feel is sci-fi; needs material
  override to read concrete, and even then the panelling will telegraph.

#### C8 — Kenney Factory Kit (SELECTED 2026-05-15)
- **Source:** <https://kenney.nl/assets/factory-kit>
- **Licence:** CC0
- **Count:** 140 modular industrial pieces (pipes, conveyors, machinery,
  structural), multiple formats, with animation + colour variations
- **Fidelity:** Best Kenney source for *set-dressing* inside brutalist halls
  — pipes, vents, catwalks, dormant machinery to scatter through Zone 2/3.
  Pairs with C9 Space Station Kit for modular architecture and the existing
  flat-colour `mat_concrete*.tres` materials for surface treatment. The
  "playful Kenney" silhouettes read fine at distance under heavy fog and
  amber rim-light, and stay tonally consistent with the chibi A8 Stray.
  Fills out Zone 2 maintenance yard / Zone 3 industrial hall quickly.
- **Use:** Zone 2/3 prop layer + Industrial Press / hazard machinery
  silhouette upgrades. CSG → MeshInstance conversion of Threshold geometry
  pairs naturally with this pass (baked-lighting prereq, see iter 73 research).

#### C9 — Kenney Space Station Kit (SELECTED 2026-05-15)
- **Source:** <https://kenney.nl/assets/space-station-kit>
- **Licence:** CC0
- **Count:** Modular sci-fi/space-station pieces — walls, floors, doors,
  corridor segments, structural beams. Multiple formats (FBX/GLTF/OBJ).
- **Fidelity:** Dark, modular, versatile — pairs cleanly with C8 Factory Kit.
  Slightly more "habitable interior" than C7 Modular Space Kit; together with
  C8 covers Zone 1 (habitation) and Zone 2 (maintenance) wall/floor needs.
  Existing flat-colour concrete materials apply over Kenney geometry without
  a PBR pass — Gate 1 surface fidelity met without ambientCG/Poly Haven import.
- **Use:** Primary modular architecture across all three Threshold zones.
  Supersedes C7 Modular Space Kit for Zone 2; supersedes C2 Poly Haven texture
  pipeline for Gate 1 (PBR texturing deferred — Kenney silhouettes do the work).

### Recommendation
**C8 Factory Kit + C9 Space Station Kit — SELECTED 2026-05-15.** Both CC0 Kenney.
Pair with the existing flat-colour `mat_concrete.tres` / `mat_concrete_dark.tres`
materials over the geometry; no PBR texture pass needed for Gate 1. C9 covers Zone
1/2 modular walls/floors/corridors; C8 covers Zone 2/3 industrial set-dressing and
the Industrial Press silhouette upgrade. C2 Poly Haven photoreal concrete dropped
to avoid clash with chibi A8 Stray + chibi Kenney architecture.

Superseded candidates kept for traceability:
- C1 ambientCG, C2 Poly Haven — photoreal PBR textures, dropped per visual-consistency
  decision. Reopen if Kenney coverage is later judged insufficient.
- C4 Modular Buildings, C5 City Kit Industrial, C6 Prototype Textures, C7 Modular
  Space Kit — Kenney alternatives, not needed given C8+C9 coverage.

---

## Decision table (resolved 2026-05-15)

| Slot | Selected pick | Fallback | Notes | Licence | Est. import time |
|------|--------------|---------|-------|---------|-----------------|
| A — Stray mesh | **A8 Kenney Cube Pets** (yellow chick) | A1 Quaternius LowPoly Robot | Stray re-framed robot → bird; double jump = literal flap | CC0 | 30–60 min |
| B — Ambient audio | **B1 AlaskaRobotics hum + B2 IanStarGem fans + B5 Kenney Sci-Fi** | B3 InspectorJ (CC-BY) | Kenney has no ambient-bed pack; freesound fills gap | CC0 | 10 min |
| C — Architecture / set-dressing | **C8 Factory Kit + C9 Space Station Kit** | C2 Poly Haven (photoreal, dropped) | Existing flat-colour concrete materials apply over Kenney geometry; no PBR pass for Gate 1 | CC0 | 20 min |
| D — Distant atmosphere | **BoxMesh primitives + `mat_concrete_dark.tres`** | Custom `.glb` silhouettes if uniformity reads flat | C4 Modular Buildings rejected (too detailed). Pure blocky volumes at varied scales beyond play bounds; no collision; fog does the silhouette work. | n/a | trivial |

Autonomous asset acquisition now reopens per CLAUDE.md. Each acquired asset gets
an `assets/ASSETS.md` entry before commit, and a style-fidelity check:
"does it read in the brutalist palette under fog at gameplay camera distance?"

If the answer to any is "wrong style but good quality" the options doc for that
slot gets expanded before committing. If the answer is "needs modification,"
the modification is documented in `DECISIONS.md`.
