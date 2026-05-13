# Asset Options — Project Void
## First-pick candidates for human approval

Three asset slots are blocking Gate 1 art direction: the **Stray mesh**, the
**ambient audio bed**, and the **concrete texture kit**. Each section below
lists 3–5 candidates with source, licence, fidelity notes, and a
recommended pick. After the human approves ~3 choices the autonomous asset
pipeline reopens.

Style fidelity benchmark: does it read in the brutalist palette under fog at
gameplay camera distance? The world is cold, dark, and vast. The Stray is the
only warm bright thing in it.

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

### Recommendation
**A1 (Quaternius LowPoly Robot)** — best fidelity-to-effort ratio, CC0 confirmed,
animations cover all Gate 1 requirements, FBX imports cleanly into Godot 4.
If the style feels too "cute" after device review, A2 is the backup.

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

### Recommendation
**B1 as global bed + B2 as Zone 2 layer.** B1's deep hum nails "vast machine-built
world"; B2 adds specificity in the maintenance yard. Both CC0. If B1 proves too
featureless after device testing, swap in B3 (CC-BY) for the longer natural
variation. All three can be acquired now and compared on device; they're small
file sizes.

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

#### C4 — Kenney Modular Buildings kit
- **Source:** <https://kenney.nl/assets/modular-buildings>
- **Licence:** CC0
- **Count:** 100 models; walls, floors, roofs, stairs, windows
- **Format:** GLTF/OBJ. No PBR textures — solid colour with basic geometry detail.
- **Fidelity:** Low for surface detail, but the **geometry** is useful. These
  modular pieces could be used as Zone 1 building-block shapes, with
  ambientCG/Poly Haven materials applied over them. Rough brutalist volumes
  without surface noise.
- **Use:** Modular architecture geometry, not texture source.

#### C5 — Kenney City Kit Industrial
- **Source:** <https://kenney.nl/assets/city-kit-industrial>
- **Licence:** CC0
- **Count:** 25 models; factory/warehouse themed
- **Fidelity:** Same as C4 — geometry layer, not texture layer. Zone 2/3
  contextual props.

### Recommendation
**C1 (ambientCG) or C2 (Poly Haven)** for the texture maps — both are best-in-class
CC0 PBR. C2 + the Poly Haven Godot add-on is the fastest path to import. Acquire
3 sets from either source (one per zone tone: light/neutral, cold/stained,
rough/industrial) and apply over the existing `mat_concrete.tres` material.
C4/C5 (Kenney geometry kits) are worth a look for Zone 2/3 prop blocking —
no art direction needed, just layout.

---

## Decision table

| Slot | Recommended pick | Fallback | Licence | Est. import time |
|------|-----------------|---------|---------|-----------------|
| A — Stray mesh | A1 Quaternius LowPoly Robot | A2 Godot Asset #1467 | CC0 | 30–60 min |
| B — Ambient audio | B1 AlaskaRobotics hum + B2 fans layer | B3 InspectorJ (CC-BY) | CC0 | 10 min |
| C — Concrete kit | C2 Poly Haven + Godot add-on | C1 ambientCG | CC0 | 20 min |

Once you approve the picks above (or redirect to alternates), autonomous asset
acquisition resumes. Each acquired asset will get an `assets/ASSETS.md` entry
before commit, and a style-fidelity check: "does it read in the brutalist palette
under fog at gameplay camera distance?"

If the answer to any is "wrong style but good quality" the options doc for that
slot gets expanded before committing. If the answer is "needs modification,"
the modification is documented in `DECISIONS.md`.
