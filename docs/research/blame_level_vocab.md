# BLAME! Spatial Vocabulary — Gate 1 Level Reference

> Written for iteration 49. Purpose: map each Gate 1 candidate level concept
> (Spine / Lung / Threshold) to specific spatial archetypes in Tsutomu Nihei's
> *BLAME!* so that when the human selects a candidate, Claude has concrete visual
> precedents for every kit piece and lighting decision in greybox.
>
> This is not a plot summary — it is an architectural reference catalogue.

---

## What BLAME! gives us

*BLAME!* (10 volumes, 1998–2003) is one of the most sustained explorations of a
living megastructure in any medium. Each volume takes place in a spatially
distinct zone of the Megastructure, and Nihei communicates those zones almost
entirely through geometry, scale, and light — very little exposition. This makes
it a direct reference for a game that also communicates through geometry.

Four recurring spatial types appear throughout the series and map directly onto
our three Gate 1 candidates:

1. **The Structural Wound** — an unintended interior created by a failure (collapse,
   rupture, separation) in an otherwise impenetrable structural member. Tight,
   rib-like, full of exposed infrastructure. Scale is ambiguous — you can't see
   both ends at once.

2. **The Functional Interior** — a chamber still performing its designed purpose
   for an absent population. Machinery is active, rhythmic, possibly slow.
   Bioluminescent or industrial lighting. The horror is not the machine, it is
   the absence of the purpose it serves.

3. **The Layer Boundary** — the transition zone between two megastructure
   programmes from different eras or functions. Materials change abruptly.
   Scale changes abruptly. The corridor that connects them is the wrong size for
   both sides.

4. **The Exterior Glimpse** — a moment when the interior traveller sees the outside
   of the structure they are climbing, and the scale of what they are inside
   becomes legible for the first time. Usually a single panel in BLAME!; should
   be a single CameraHint in Void.

---

## Spine → The Structural Wound

**Primary BLAME! archetype:** Vol. 2–3. Kyrii and Cibo traversing inside the
structural sections of the Megastructure — corridors that run between load-bearing
elements, lit by nothing but bioluminescence seeping through cracks.

**Key spatial characteristics:**
- Interior of a structural member, not a habitable space. The geometry is
  functional in a structural sense (it holds load) but hostile to traversal.
- Rib-like cross-section: repeating transverse members at regular intervals,
  creating a rhythm the traveller navigates rather than ignores.
- Scale ambiguity: the bottom cannot be seen from the top. Fog or darkness
  absorbs the far end. This is critical — the shaft should never be readable as
  a single contained space.
- Cold ambient light from above, warm point-sources (structural heat leakage,
  bioluminescence at joints) from below. This lights the *undersides* of the
  ribs and puts the tops in shadow — important for depth reading from above.
- The "wound" detail: the crack or collapse that makes traversal possible should
  read as a clean geometry break (not rubble), because BLAME!'s megastructure
  doesn't crumble the way stone does — it shears, buckles, separates.

**Greybox implications for Spine:**
- Rib pieces: rectangular extrusions from the wall, not organic curves. The
  pattern is regular until the Beat 3 twist breaks it.
- The "exterior glimpse" at Beat 3 is the single most important BLAME! moment
  in the level — the Stray exits the wound and sees the outside of the column.
  This needs a long CameraHint pan to the exterior surface.
- Lighting key: single warm source behind the entry (warm = origin zone);
  cold blue ambient from above (cold = structural interior); the Stray's red
  visible against both.
- Fog: thick at base (bottom of the wound), clearing toward the break. Fog is
  the structural "atmosphere" of the column's micro-climate.

---

## Lung → The Functional Interior

**Primary BLAME! archetype:** Vol. 4–5, the Silicon Creatures' production zones
and the Safeguard-controlled industrial sections. Vast horizontal chambers
where machinery still operates — fans cycle, conveyors move, pressure systems
equalise — for a population that has been absent for centuries.

**Key spatial characteristics:**
- The chamber is *active*. The horror in BLAME! is not that the machine is
  broken — it is that the machine is *working correctly* and nobody required it.
  This is what gives the Lung its emotional texture: the baffles are not broken
  platforms, they are functioning ventilation equipment.
- Horizontal scale: BLAME!'s functional interiors are typically elongated in
  the horizontal axis, wider than they are tall. Ceilings are visible but
  distant; the floor is far below.
- Bioluminescent trim as infrastructure: in BLAME!, active machinery carries
  bioluminescent accents — cyan and cool-white — not as decoration but as
  functional indicators. The biolume strips on the Lung's baffles are correct
  BLAME! grammar.
- The rhythm of machinery is a temporal beat, not a spatial one. The Lung's
  platform timing *is* the music of the space.
- The "trachea" vista at the far end (where the ducts converge) is the
  architectural climax — BLAME! frequently ends a chamber sequence with a
  convergence point that re-contextualises the space traversed.

**Greybox implications for Lung:**
- Baffles: flat rectangular slabs, not bevelled. They move on a vertical axis
  only. No wobble, no tilt — they are precision equipment.
- The biolume strips should run the full length of each baffle's underside.
  One draw call per baffle as an emissive material, no additional light sources
  from the baffles themselves (baked lighting only).
- The wind column (Beat 2's updraft) is a vertical duct mouth. The geometry
  should make the source legible — a circular aperture in the floor, or a
  visible grating, not an invisible zone.
- Fog: lighter than Spine (ventilation chambers are cleared). Biolume cyan
  light scatters against fog particles — keep density low enough that the
  biolume reads from across the chamber.

---

## Threshold → The Layer Boundary

**Primary BLAME! archetype:** Vol. 1, Kyrii's initial traversal through stacked
megastructure layers. The opening chapters of BLAME! are almost entirely about
layer boundaries: every time Kyrii reaches a structural boundary between zones,
the visual language resets. Material, scale, lighting, sound — all change at
once. This abruptness is intentional and narratively meaningful.

**Key spatial characteristics:**
- The threshold itself is more important than the zones it connects. In BLAME!,
  transition corridors between zones are always the *wrong size* — too small
  for the industrial layer, too utilitarian for the habitation layer. This
  wrongness is the architectural signal that you are between-things.
- Habitation layer spatial vocabulary: wide, with evidence of human intent —
  rounded edges, vestigial signage geometry (even if unreadable), ceiling
  height scaled to people (~3 m), horizontal emphasis.
- Maintenance buffer vocabulary: rectilinear, dense, pipe-banks and conduit
  runs visible. Nothing decorative. Scale compressed (~2 m ceiling). Hostile to
  anything larger than the robot it was designed for.
- Industrial layer vocabulary: everything is large. Structural members are the
  same size as the Stray's traversal space. The Stray navigates *between* pieces
  of machinery, not *on* surfaces designed for navigation.

**Greybox implications for Threshold:**
- The three-zone contrast is the entire level design thesis: each zone must be
  immediately readable as a different programme. Don't let the zones bleed into
  each other — BLAME!'s layer boundaries are abrupt, not gradual.
- The service hatch between Zones 1 and 2 (Threshold 1) is a genuine
  BLAME! threshold moment: physical constriction + complete audio and lighting
  change on pass-through. This is worth a brief animation cue or CameraHint.
- The industrial tier (Beat 4–5) requires the largest geometry in the game
  so far. At minimum one structural element should be taller than the camera's
  full vertical range. The Stray should look *very small* against it.
- Lighting grammar per zone:
  - Habitation: sodium warm (orange-yellow), dispersed, dust-diffused.
  - Maintenance: cool fluorescent (blue-white), point-source, no fill.
  - Industrial: sodium warm again but hard and directional — industrial
    lights are high-power, not ambient.

---

## The Exterior Glimpse — notes for all three candidates

BLAME! repeatedly uses a single panel where the reader sees the outside of the
megastructure from an interior vantage. The effect is vertigo: you understand,
for the first time, the scale of what you have been inside.

All three Gate 1 candidates have a built-in exterior-glimpse moment:
- **Spine**: Beat 3 exit to the column's outer shell.
- **Lung**: the epilogue overhang (looking back into the chamber from outside).
- **Threshold**: Beat 3/4 transition through the industrial tier's outer wall.

For each: the exterior glimpse should be a dedicated CameraHint that pulls back
further than the camera normally allows, held for 2–3 seconds, then released.
The visual should show enough exterior geometry to establish megastructure scale.
This is the single moment in each level where the game's world-scale thesis lands.

---

## Implications for Void

1. **Spine rib geometry**: use rectangular box CSG extrusions, not curves. BLAME!
   structural ribs are straight and machined, not organic.

2. **Lung baffles**: flat-face slabs with emissive underside strip (single material,
   no geometry for the light itself). The machinery is *clean* — no rust, no
   organic growth in a still-functioning zone.

3. **Threshold zone materials**: `mat_concrete.tres` (warm, rougher) for
   Habitation; `mat_concrete_dark.tres` (cold, smoother) for Maintenance;
   a third material (industrial — higher roughness, darker, with occasional
   surface normal variation) for Industrial. Three materials, three zones,
   no blending at zone boundaries.

4. **The exterior glimpse needs its own lighting state**: warm natural grey
   (overcast megastructure sky, no direct sun) versus whatever the interior
   key is. The contrast between interior darkness and exterior grey light
   is the core of the reveal.

5. **Structural wound geometry (Spine)**: shear planes, not rubble. The collapse
   that opens the Spine should read as a clean break at a stress boundary. Box
   geometry with a flat cut face communicates this better than scattered pieces.

6. **Scale checklist for Threshold industrial tier**: at least one object taller
   than 6 m (human scale × 3); at least one object the Stray navigates *between*
   not *on top of*. If everything is a platform, the zone doesn't read as industrial.

7. **Biolume cyan is exclusive to Lung (for Gate 1)**. Spine and Threshold use
   only the base palette (warm sodium, cold blue-white, concrete grey). If
   biolume appears in Spine or Threshold, the Lung loses its signature accent.
