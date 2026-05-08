# Level Design Philosophy — Project Void

A level in this game is not a playground decorated with concrete textures. It is **architecture authored under principles** that the player moves through. The Stray is a small, lost thing in a world built for something else; every level should make that legible without saying it. Read this before authoring any new spatial layout.

---

## The core idea

> *Every level should be readable in at least two ways. One is the obvious traversal. The other emerges from architecture, lighting, sound, or vantage — a second meaning that rewards a player who looks twice.*

This is the hook. A staircase that's also a tomb. A factory floor that's also a cathedral. A maintenance shaft that's also a spine. The Stray runs through the first reading; the world tells you the second.

The player will not always notice. That's fine. Levels designed under this principle still feel better than levels that aren't, because the architectural logic creates internal coherence — every piece feels like it belongs to the same place because it actually does.

---

## Architectural principles

These are the working tools. Each level should consciously use a handful of them.

### Parti

**The single organising idea of the level.** Before you place anything, name the parti in one sentence:

- "A descent through a collapsing column."
- "A circuit around a frozen machine."
- "A rising spiral that the player keeps re-encountering from different elevations."
- "Two parallel paths separated by a wall, never quite the same."

If you can't state the parti in one line, the level doesn't have one yet. Keep working on the idea before laying down geometry. Levels without a parti read as corridors strung together.

### Procession

**The sequence of spaces and reveals.** A good procession has a rhythm: compression and release, anticipation and payoff. Tight corridor → open chamber → narrow ledge → vista. Don't put the climax at the start. Don't make every space the same scale.

Brutalism specifically rewards the **compression-then-vast-release** procession. A claustrophobic shaft that suddenly opens onto a void is the *BLAME!* signature. Use it sparingly — once or twice per level — and earn it.

### Hierarchy

**What reads as important.** Scale, light, axis, and isolation all confer importance. The player's eye goes first to the brightest, biggest, most isolated, or most axially-framed thing. Use that. Place checkpoints on hierarchy. Place vistas on hierarchy. Place hazards *off* hierarchy if you want them to feel ambient and *on* hierarchy if you want them to feel deliberate.

### Threshold

**How transitions between spaces are marked.** Doorways, drops, light shifts, sound shifts. A threshold tells the player they've moved from one thing to another. In a megastructure, thresholds are often vertical: descending through a hole, climbing through a hatch. Make thresholds *felt* — change the camera framing, change the audio bed, change the lighting key. Don't let the player walk from cathedral to factory without a moment of "where am I now."

### Vista

**Composed views that are paid for.** A vista is a moment where the player stops and looks. Brutalism is built for vistas — it's the "vast scale" payoff. Vistas need framing: an aperture, a foreground anchor, a focal landmark, atmospheric perspective. Place a `CameraHint` to slow the camera and frame the view.

A level should have at least one vista. Probably not more than three. Vistas that aren't paid for (no procession leading to them, no aperture framing them) read as just "a big space."

### Genius loci

**Distinct sense of place.** Even within one biome, each level should feel like a *somewhere*. Not "concrete level 3" but "the spine of a fallen elevator core" or "the underside of a ventilation cathedral." The genius loci is named in your design notes for the level. If the level doesn't have one, find it before authoring.

### Multiple readings

**The same space, two meanings.** This is the core idea, expanded:

- **Architectural double-reading**: the same form is both X and Y. A descending shaft is also a throat. A row of pillars is also a graveyard. An assembly line is also a procession.
- **Path double-reading**: the player's traversal route reveals one meaning; an alternate vantage (back-glance, mirror reflection, distant view) reveals another. They saw the level *as a labyrinth*; from the climbing tower they later see it *was a face*.
- **Lighting double-reading**: under one light condition the space reads industrial; the level's climax shifts the lighting and the same space reads sacred.

Pick one form of double-reading per level and commit to it.

### Frame and aperture

**Controlling what the camera sees.** In 3D, the camera is the frame. Use scenery, shadow, and geometry to compose what's in view. Brutalist architecture's geometric repetition is your friend — pillars, lintels, slots, beams all crop the camera's view naturally.

Use `CameraHint` nodes to lock or pull framing at key moments. Don't fight the camera; use the camera.

### Path and anti-path

**The obvious route vs. the discoveries off it.** Every level has a critical path the player will follow. Anti-path is everything *adjacent* to that critical path that rewards looking and exploring — sightlines into other parts of the level, accessible side rooms with collectibles, alternate routes for skilled play (faster, harder).

In a precision-platforming game, anti-path often equals **par-time route** — the experts' line through the level, harder but faster. Author this deliberately, not by accident.

### Scale contrast

**The Stray vs. the world.** Always design with the Stray's silhouette in mind. The world should *occasionally* dwarf the Stray to a single red pixel against vast structure — those are the awe moments. But not constantly, or the player loses the character. Default to mid-scale; reserve dwarfing moments for procession peaks.

### Vertical axis as primary

**This world climbs and falls.** Inherited from *BLAME!*. Most levels should have meaningful vertical structure — multiple elevations the player traverses or perceives. A purely horizontal level in this game feels off-genre. When designing, ask: where's up? where's down? what's the player's vertical relationship to the rest of the structure?

---

## Translating principles into 3D platformer mechanics

Architecture and platforming have to serve each other, not compete.

### Platforming verbs ↔ architectural moments

- **Long jump** ↔ vista crossing, aperture-to-aperture leap.
- **Wall jump / wall ride** ↔ shaft descent or ascent; procession through verticality.
- **Tight precision sequence** ↔ compression, claustrophobia, threshold approach.
- **Rolling momentum descent** ↔ release after compression; spectacle moment.
- **Hover / fall control** ↔ vista contemplation; "look around" beats.

### Hazards ↔ architectural meaning

Hazards aren't placed for difficulty alone — they read as the world's character. A spinning blade is a factory; a crumbling pillar is decay; a downward beam is a security system; a sudden electrical arc is the world's hostility to the Stray. Make sure the hazard fits the genius loci.

### Checkpoints ↔ thresholds

Place checkpoints at thresholds — moments where the player has clearly transitioned to a new space. Don't drop them mid-corridor. Pair checkpoint placement with a small visual or audio shift the player will subconsciously recognise as "saved."

### Par routes ↔ anti-path

The skilled-player route should be visible *as a possibility* from the safe route — a glimpse of a higher ledge, a corner cut that an attentive player notices. Hidden par routes are frustrating; visible-but-difficult par routes are inviting.

---

## Authoring workflow

For every new level:

1. **Write the parti** in one sentence in `docs/levels/<level_name>.md`.
2. **Write the genius loci** — what is this place, in-world?
3. **Write the double-reading** — what's the second meaning?
4. **Sketch the procession** as a sequence of beats: compression / chamber / threshold / vista / climb / release / etc. Five to ten beats is typical.
5. **Identify the platforming verbs** the level features. One or two primary, two or three secondary. Don't try to feature every mechanic.
6. **Greybox** in primitives matching the procession. Don't dress yet.
7. **Place `CameraHint` nodes** at thresholds and vistas.
8. **Place checkpoints** at thresholds.
9. **Test the procession** by playing through. Does compression-release land? Does the vista pay off? Does the genius loci read?
10. **Identify par route** as a separate critical path.
11. **Iterate**, then move to art dressing only after the architecture is right.
12. **Update `docs/levels/<level_name>.md`** with the final parti, procession, and any deviations from intent.

---

## Anti-patterns to avoid

- **Corridor sausage**: one space after another with no rhythm, no procession, no parti.
- **Dressed gymnasium**: a flat platforming arena with brutalist textures slapped on top. Architecture is structure, not skin.
- **Vista glut**: every space tries to be the climax. Climaxes need quiet around them.
- **Random hazards**: hazards placed for difficulty curve alone, without fitting the genius loci.
- **Invisible par routes**: skilled-player paths nobody can find without a guide.
- **Single-reading levels**: a tomb that's only a tomb. Boring. Find the second meaning.
- **Horizontal sprawl**: the wide-open horizontal level. Off-genre. Re-read "Vertical axis as primary."

---

## A worked example

**Level: "Throat"**

- **Parti**: a single descending shaft the player falls and climbs through three times, each time at a different scale.
- **Genius loci**: a collapsed ventilation column in a deep maintenance layer. Old air still moves through it slowly.
- **Double-reading**: the shaft is a throat — wider at the top (mouth/aperture), narrowing in the middle (oesophagus/precision section), opening at the bottom into a stomach-chamber with a final breath of warm air. Once the player reaches the bottom and looks back up, the shape is unmistakable.
- **Procession**: 1) wide aperture entry (vista down) → 2) controlled descent past industrial ribs (procession compression begins) → 3) precision wall-jump through the narrowing (compression peak) → 4) sudden release into a humid chamber where the Stray sees scale of where they've been (vista up, double-reading lands) → 5) climb back up via alternate spiral (revisit, new perspective) → 6) checkpoint at threshold to next area.
- **Verbs**: wall jump (primary), long jump (secondary), variable-height jump (secondary).
- **Hazards**: occasional steam vents fitting "ventilation column" theme.
- **Par route**: a continuous wall-jump descent skipping the central platforms, available to confident players.

The same principles applied to "Cathedral," "Lung," "Spine," "Eye," etc. The biome's vocabulary becomes recognisably anatomical/industrial — a deeper-layer parti emerges across levels.
