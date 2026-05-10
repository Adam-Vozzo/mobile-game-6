# Christopher Alexander — Parti, Pattern Language, and Form Synthesis
## Applied to Project Void Level Design

Sources consulted: *Notes on the Synthesis of Form* (1964), *A Pattern Language* (1977),
*The Timeless Way of Building* (1979); secondary sources: architectural education writing
on parti pris; Game Maker's Toolkit / Mark Brown on level-structure as design language.

---

## The core ideas

### 1. Notes on the Synthesis of Form — design as requirement satisfaction

Alexander's argument: every design problem is a network of requirements (he calls them
"forces"). A good form resolves the most forces with the fewest conflicts. Bad design
tries to satisfy requirements sequentially; good design finds the organizing move that
satisfies many forces simultaneously.

Applied to level beats: a platform spanning a gap over a void satisfies "challenge",
"read-ahead visibility", "verticality", and "forward momentum" at once. A platform
inside a sealed box satisfies "challenge" alone. One is architecturally rich; the other
is obstacle-course padding.

Design test: for each beat in a level, list the forces it must satisfy. If it only
satisfies one, it's doing too little work.

### 2. Parti pris — the generative concept

"Parti" is the organizing idea of a design — the single decision that gives coherent
form to all the parts. In architecture school: before you draw a floor plan, state your
parti. "This building is organized around a compressed entry that releases into light"
is a parti. "This building has rooms" is not.

For a level beat: the parti is the mechanic that governs all platform placement in that
beat. "This beat is a vertical gauntlet where the player must control apex hang-time to
read the landing ahead" is a parti. "Three platforms in a row" is not.

Parti and the SMB grammar align: SMB's "one governing idea per room" rule *is* parti
thinking applied to level design. Alexander got there from architecture in 1964; Team
Meat got there from platformer design in 2010. The convergence is evidence the principle
is real.

### 3. A Pattern Language — named solutions to recurring design problems

Patterns are named solutions to forces that recur across many designs. Alexander's
patterns are architectural (e.g., "Light on Two Sides of Every Room", "Entrance
Transition"), but the concept transfers directly.

A Pattern Language for a brutalist platformer:

| Pattern name | Forces satisfied | Void kit element |
|---|---|---|
| **Compression–Release** | Tension, pacing, awe | Tight service-run corridor → column-array void |
| **Threshold** | Orientation, zone boundary, anticipation | Doorframe, shaft rim, bridge entrance |
| **Landmark in Darkness** | Navigation, orientation, goal-legibility | Glowing column, warm-lit platform, red beacon |
| **Rest Alcove** | Pacing, safety, breath after effort | Checkpoint platform, wider ledge, lit recess |
| **Gauntlet Ascent** | Challenge, verticality, progressive difficulty | Rising shaft, timed hazard columns |
| **Overlook** | Spectacle, anticipation, spatial legibility | Vista past fog, balcony over void |
| **Desire Line** | Flow, player agency, risk/reward | Visible shortcut platform slightly off the par route |

Each pattern is a reusable kit arrangement. Composing patterns (Compression–Release →
Overlook → Gauntlet Ascent) produces level structure with emergent flow.

### 4. The whole and its parts — coherence before decoration

Alexander is explicitly against surface decoration that isn't load-bearing. In *The
Timeless Way of Building* he argues that living structure arises from centres that
reinforce each other: each part makes the others more themselves. In level design: a
platform that is also a landmark is more alive than a platform with a decorative prop
placed next to it.

For Void: every prop, light, and material variation should reinforce the spatial idea
of the beat. A warm light source that is also the goal beacon ("reach the glow") is
better than a warm light placed for visual interest that happens to be near the goal.
The distinction is: does this element reinforce the parti, or is it decoration?

---

## Implications for Project Void

1. **Write a parti for every level beat before placing geometry.** One sentence: what
   mechanic governs this beat, and what spatial quality makes it readable? This replaces
   ad-hoc platform placement with intentional structure.

2. **Use the pattern table above as a vocabulary.** Every Gate 1 beat should name at
   least one pattern from the table (or add a new named pattern). This keeps the level
   kit modular and the design communicable between iterations.

3. **Compression–Release is the primary procession unit for a brutalist megastructure.**
   Service run (tight, dark, fog close) → column-array void (open, distant, overwhelming
   scale). Repeat with variation. The existing `brutalism_blame.md` note identified this
   independently; Alexander's framework explains *why* it works: the release satisfies
   many forces (awe, orientation, pacing) that the compression had been holding in
   tension.

4. **Every beat must satisfy ≥ 3 forces.** List them: at minimum — challenge,
   navigation, and one of (spectacle / pacing / orientation). Beats that only satisfy
   "challenge" are obstacle-course padding.

5. **Landmarks must be structural, not decorative.** The landmark that orients the
   player through fog must also be the goal, the checkpoint beacon, or the silhouette
   of the next challenge. Decorative landmarks (a prop placed for visual interest near
   a checkpoint) are weaker than structural ones.

6. **The Stray's red as a structural centre.** Alexander's "centres" concept: the
   player character is the warm centre of the cold world. Every lighting and colour
   decision should reinforce this. The level is a field of dark greys; the Stray is
   the living point that gives the field its meaning. This aligns with CLAUDE.md's
   "red is precious — don't dilute it."

7. **Desire-line pattern → par route design.** Alexander's observation that people
   route via desire lines (diagonals, shortcuts) rather than designed paths is exactly
   the par-route principle from `level_design_references.md`. The par route is the
   desire line for skilled play; the safe route is the designed path. Author the desire
   line first, then add the safe surround.

8. **Pattern vocabulary → `scenes/levels/kit/` pieces.** When kit geometry is built
   in Gate 1, name each piece after its pattern (e.g., `kit_rest_alcove.tscn`,
   `kit_compression_run.tscn`, `kit_overlook_platform.tscn`). Naming enforces that
   each kit piece is a pattern, not just a shape.

---

## What Alexander does NOT solve

- Pacing over time (dynamic difficulty, rhythm groups) — use `level_design_references.md`
  for that.
- Player feel (input latency, jump arc satisfaction) — felt empirically on device only.
- Mobile-specific legibility (what reads at camera distance, on a small screen, at 60 fps)
  — use `mobile_touch_ux.md` and the `style_test.tscn` fidelity check.

Alexander gives the *structure* of levels; the other research notes give the *feel* and
*execution*.
