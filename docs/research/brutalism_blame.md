# Research — Brutalism, *BLAME!*, and the Megastructure Vocabulary

**Date**: 2026-05-09  
**Scope**: Tsutomu Nihei's architectural visual language in *BLAME!*; brutalist design
principles and how they generate level geometry; implications for Project Void's
environments.

---

## Part 1 — *BLAME!* (Nihei, 1998–2003)

### What the City is

The Netsphere megastructure is a planet-spanning, recursively self-replicating building.
It has no outside. Navigation is orientation by infrastructure — pipes, shafts, duct lines,
column forests. The City is hostile to human comprehension at every scale: individual
"floors" contain geological formations; corridors run for panels without arriving anywhere;
vistas appear, briefly, then are swallowed back into darkness.

### Visual grammar

- **Scale is always ambiguous.** Nihei deliberately withholds scale anchors — there is no
  consistent human figure for reference, doors are missing or wrong-sized. You often cannot
  tell whether a space is 5 m wide or 500 m wide until Killy appears in frame.
- **Darkness as architectural material.** Panels are often 60–80% black ink.
  Geometry exists as bright edges against void, not as illuminated surfaces.
  Godot equivalent: *ambient light low, shadows hard, geometry catches the key light on
  one face only*.
- **Fog as depth.** Nihei uses an ink-wash aerial perspective that reads as fog:
  distant elements desaturate and lighten toward the background grey. Essential for
  communicating the vertical scale of shafts and columns.
- **Recursion and self-similarity.** The same structural elements — I-beams, cable runs,
  hexagonal panels, column arrays — appear at vastly different scales. A floor tile pattern
  at 1 m pitch recurs at 20 m pitch in the next chamber. Designing a small set of pieces
  that tile at multiple scales is the correct approach.
- **Diagonal panel composition.** Nihei uses extreme perspective, diagonal geometry, and
  off-axis framing to suggest depth and disorientation. In 3D: CameraHints at non-standard
  angles (Dutch tilt, extreme low-angle) at threshold moments.
- **No horizon, no sky.** The player should *never* see sky unless it is a deliberate
  reveal moment. The world is enclosed. Ceiling geometry (even implied, via fog cut-off)
  is always present.
- **Navigation logic: follow the infrastructure.** Characters in BLAME! navigate by
  following structural elements — a cable run leads to a junction; a column array implies
  a load path that implies a floor above. Levels should work the same way: architecture
  tells the player which direction is forward.

### Colour palette (derived from the manga)

The manga is black-and-white, but Nihei and licensees have described a consistent palette
for coloured readings:

- Structure: cold mid-grey (blue-grey cast, not warm)
- Shadows: near-black with slight blue or violet tint
- The rare warm light source: sodium orange or industrial halogen — precious precisely
  because of its rarity
- Bioluminescence in deeper layers: sickly cyan/green, suggests something living has grown
  into the infrastructure

Mapping to Void's palette: concrete greys (slightly blue-cast) are correct.
`mat_concrete` at 0.55/0.55/0.58 and `mat_concrete_dark` at 0.32/0.32/0.35 both carry
a slight blue-grey cast. ✓ The key light at `Color(1, 0.85, 0.55)` is sodium-warm. ✓

---

## Part 2 — Brutalist Architecture

### Core principles

**Béton brut** (raw concrete): the name comes from Le Corbusier's description of
board-formed concrete left unpainted, showing the texture of the formwork.
The principle is *honesty of material* — the thing is what it looks like.

**Mass over surface**: brutalist buildings read as sculptural objects at a distance,
not as decorated surfaces. Surface variation is texture and shadow, not applied ornament.
Implication: platform geometry should have readable silhouettes at gameplay distance;
surface detail (normal maps, trim sheets) is secondary.

**Expressed structure**: beams, columns, load-bearing walls, floor slabs — all visible
on the facade. There is no skin hiding the skeleton. Level geometry should suggest its
own structural logic: a platform supported by visible columns "reads" differently from
a platform floating unsupported. The latter feels wrong; use it deliberately for
uncanny moments.

**Geometric repetition, but not uniformity**: the same bay rhythm repeated, but with
subtle variation in depth, setback, shadow profile. A column grid that marches into fog
is brutalist. A column grid where every column is identical and equidistant reads as
placeholder art.

**Monumental scale and civic ambition**: brutalism was designed for institutions —
universities, government buildings, housing blocks. It carries an ideological weight
(often utopian, often failed). The Stray is a small fragment of someone's vast,
abandoned utopia.

### Key reference buildings (for visual vocabulary)

- **Unité d'Habitation, Le Corbusier (1952)**: repetitive window bays, pilotis lifting
  the mass off the ground (Stray could run *under* a building), exposed concrete.
- **Paul Rudolph, Yale A&A Building (1963)**: corduroy concrete texture (ribbed vertical
  channels), aggressive cantilevers, interlocking split-level sections — strong 3D
  platforming affordance.
- **Lasdun, National Theatre London (1976)**: horizontal strata, wide terraces, the
  building as landscape. Good for wide-open awe moments.
- **The Barbican, Chamberlin Powell & Bon (1976)**: walkways at multiple levels,
  bridges, water features, residential towers. The closest built analog to the game's
  navigational logic.
- **Tricorn Centre, Owen Luder (1966, dem. 2004)**: raw concrete, car park ramps as
  architecture, now mostly known as the BLAME!-looking building.

### Surface texture vocabulary

- Board-formed concrete: the grain of the wood form is cast into the surface.
  In Godot: a normal map with horizontal or angled line texture, scale 0.5–1.0 m pitch.
- Ribbed/corduroy: deep vertical grooves every 20–40 cm. Casts strong shadow on the
  lit face. In Godot: geometry-level ribs on hero surfaces or a strong normal map.
- Bush-hammered or exposed aggregate: roughened surface, slightly sparkly.
  In Godot: high roughness (0.85–0.95), slight grain in the albedo.

---

## Part 3 — How megastructure logic generates levels

### The infrastructure hierarchy

Real megastructures (Nakagin Capsule Tower, the Metabolist proposals, BLAME! City) have
a structural hierarchy:

1. **Mega-column / core spine**: the primary load path. Massive. Rarely encountered
   directly; present as background.
2. **Floor slab**: the horizontal datum. Sets the "layer" the player is on.
3. **Service run / mechanical floor**: the in-between layer where infrastructure is
   concentrated. Dense, complex, low-ceiling. Ideal for claustrophobic traversal sequences.
4. **Habitation / open volume**: where human activity was meant to happen.
   Now empty. Large, echoing. Ideal for vista moments.

A level procession that moves: service run → open volume → climb a mega-column → new
service run → habitation vista — is architecturally coherent and produces the right
rhythm (compression → release → compression → release/climax).

### Voids and the missing program

In BLAME! the building was built without humans but for humans. Programs that should be
there (apartments, offices, transit hubs) are present as infrastructure but not as
habitation. This is the source of the horror and the poetry:

- A corridor that has the structural bays of an apartment block but no doors, no
  windows, no interior divisions.
- A transit platform with the platform edge and the track and the overhead wires but
  no trains, no arrivals board, no turnstiles.
- A factory floor with the cranes and the assembly bays and the feed lines but no
  product, no workers, no waste.

Designing levels with this "failed program" logic makes them feel inhabited and abandoned
simultaneously. Every space has a *legible intent* and a *missing use*.

### Navigational legibility

Kevin Lynch's "Image of the City" vocabulary applies even in a megastructure:
- **Paths**: the column forest shows you where to run.
- **Edges**: a wall that blocks and defines the boundary of a floor slab.
- **Landmarks**: a different-coloured element (rust? biolume?) that orients you.
  The Stray's red functions as a self-landmark — the player always knows where they are
  because the Stray is always visible.
- **Nodes**: junctions where multiple paths meet. Place checkpoints here.
- **Districts**: the character of one floor vs. another. Mechanically: a biome transition.

---

## Implications for Project Void

1. **Cold grey is correct, but add the blue cast.** The concrete materials have a slight
   blue-grey tint in the albedo already. Don't drift warm — warm concrete reads suburban,
   not megastructure.

2. **Darkness is architectural.** The ambient at 0.4 energy and the fog are doing the right
   work. Resist adding fill lights "to see better." The player should sometimes feel lost
   in shadow; the key light is the reward.

3. **The Stray's red is the ONLY warm accent.** If any environment piece has rust orange,
   sodium yellow, or biolume cyan, it must earn its place in the palette as a *landmark*,
   not decoration. The style test scene should make this visible immediately — the Stray
   should pop against the grey.

4. **Design pieces at multiple scales.** A 2×0.5×2 platform tile, a 4×1×4 floor slab,
   an 8×2×8 landing pad — all using the same material, all reading as the same type of
   surface at different scales. Kit pieces should tile at 0.5 m grid.

5. **Express structure in geometry, not just texture.** A platform supported by visible
   column stubs reads as credible infrastructure. A floating platform should be a
   deliberate design choice (for uncanny / late-game moments), not a default.

6. **Service-run sequences for compression.** The tight corridor / low ceiling / dense
   pipe section is the brutalist equivalent of a cave — use it for the claustrophobic
   beat before a vast release.

7. **Column arrays into fog = the brutalist long shot.** A row of 2×8×2 pillars
   diminishing into fog at 10 m spacing creates depth without geometry. One of the
   cheapest and most effective environment elements available.

8. **"Failed program" objects as landmarks.** When Gate 1 geometry needs props beyond
   box primitives, choose objects that imply a program that is no longer functioning:
   a control console with no screen, a sealed vault door with no controls, a pipe
   junction that connects to nothing. These are readable and thematically correct.

9. **No sky box.** The background_color at near-black and the fog at near-black are
   correct. Don't add an HDRI — the megastructure has no outside.

10. **Vertical first, horizontal second.** Every level design should ask: what is the
    player's vertical journey? Falling shafts, climbing towers, and traversal across
    column tops are all genre-correct. Wide horizontal traversal without vertical change
    reads wrong.
