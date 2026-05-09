# Holistic Level Design & 3D Platformer Pacing
## Steve Lee (GDC 2017) + GMTK synthesis

Sources:
- Steve Lee, "An Approach to Holistic Level Design" (GDC 2017, Vault: gdcvault.com/play/1024301)
- Mark Brown / GMTK, "Super Mario 3D World's 4-Step Design" (youtube.com/watch?v=dBmIkEvEBtA)
- Mark Brown / GMTK, "The Design Behind Super Mario Odyssey" (youtube.com/watch?v=z_KVEjhT4wQ)

---

## Steve Lee — Holistic Level Design

Core claim: level design fails when **gameplay, presentation, and narrative** are authored
independently. All three must resolve the same design intent simultaneously.

**Three integrated dimensions:**

- **Gameplay:** What can the player do? What are the challenge vectors?
- **Presentation:** What does the space look like? What does it signal?
- **Narrative:** What does this space mean in the world?

Good level design means every asset serves all three simultaneously.
A ledge isn't just a platform — it's a platforming challenge *and* a visual
affordance *and* a material expression of the world's logic.

**Affordances and intentionality:**
Lee uses "intentionality" to mean: the player should understand, without
instruction, what the space is asking them to do. Architectural features should
self-explain their mechanic purpose. If you need a UI arrow to explain a jump,
the geometry is failing. Visual language must carry the mechanical intent.

The design pipeline implication: **decide the mechanic first (gameplay intent),
then design the geometry that makes that intent self-evident (presentation),
then give it a world-reason (narrative/lore)**. Reversing this order produces
either confusing affordances or decorative geometry that doesn't play.

---

## GMTK — Kishōtenketsu pacing (Mario 3D World, Koichi Hayashida)

The four-beat structure applied per level/room:

1. **Ki (Intro):** Introduce the mechanic in a safe, low-stakes context. Player
   learns the rule without punishment.
2. **Shō (Development):** Apply the same mechanic in escalating contexts. Difficulty
   rises; core rule remains constant.
3. **Ten (Twist):** Recontextualise or flip the mechanic. Unexpected angle, reversal,
   or combination forces genuine relearning of something the player thought they
   mastered.
4. **Ketsu (Resolution):** Mastery demonstration. Apply full understanding; reward
   optional depth for skilled players (collectibles, speed path).

Key property: **there is no conflict at the structural level** (Kishōtenketsu is not
problem-solution). The twist recontextualises rather than adds difficulty. The
difficulty curve comes from complexity, not from enemy count or obstacle density.

Hayashida's execution rule: each 4-beat arc should complete in ~5 minutes. Throw
away the mechanic after resolution; the next room gets a new one. Variety without
bloat — which matches the SMB "introduce-then-combine" room grammar but adds the
explicit Twist beat as a required element.

---

## GMTK — Density and compressed verticality (Mario Odyssey)

Odyssey's best level (New Donk City) succeeds because the **vertical range is
compressed**: you can see the top of the skyline from street level, and you can
reach it in 30 seconds. This means:

- Progress feels fast even when the objective is high up.
- The player is constantly oriented (Lynch: landmark visible from everywhere).
- Multiple paths (ground, facade, rooftop) read in parallel, making re-runs faster.

The failure mode in 3D platformers is **monotonic verticality**: one path, one
floor plane, climb for 3 minutes without seeing a goal. Odyssey avoids this via
density (geometry is packed, not sparse) and by keeping the apex in the player's
field of view throughout the ascent.

---

## Implications for Project Void

**1. Holistic affordance pipeline for Gate 1:**
Author each beat in this order: (a) name the mechanic the beat teaches, (b) shape
geometry that makes the mechanic visually obvious without UI prompts, (c) give the
geometry a world-plausible reason (service duct, structural overhang, drainage grate).
If step (b) requires a tutorial popup, the geometry shape is wrong.

**2. Each beat follows the Ki–Shō–Ten–Ketsu arc:**
Even micro-beats (3–5 precision jumps) should have a Twist — the element that
recontextualises what the player just learned. Without it, a beat is a test not a
lesson. The Ten beat is what makes SMB rooms feel fair: you thought you understood,
then you didn't, then you did again.

**3. Brutalist affordances are already honest:**
Béton brut surfaces express structure, which means the structural element IS the
mechanic signal. A ledge edge on a concrete overhang reads as "graspable" in a way
that a floating island does not. Exploit this: expressed structure = free affordances
(doesn't require coloured arrows or glowing outlines).

**4. Keep the megastructure's apex visible:**
Void's verticality risks monotonic ascent (long shaft, no reference). Design each
ascent beat so the destination is visible from the start. Column arrays and distant
floor slabs (per the BLAME! grammar) naturally provide this — they are landmarks at
multiple scales simultaneously (Lynch node + edge + district in one shot).

**5. The Twist beat for a precision platformer:**
In SMB-style rooms, the Ten beat is often a **direction reversal** (the hazard that
was going left now goes right) or a **layering** (the moving platform from beat 2
now appears while the gap-sequence from beat 1 is also active). Void's equivalent:
combine the one mechanic the player mastered in Shō with a gravity/momentum
reversal — e.g., a moving platform that was stationary in the intro now moves
during the precision jump sequence.

**6. Intentionality check before committing any kit piece:**
Ask: can a player who has never played Void identify what this geometry is asking
them to do? If no, change the geometry's silhouette until yes. The brutalist
palette (concrete, dark, sparse) has no affordance budget for decorative shapes.

**Synthesis with existing research:**
- Lee's holistic pipeline = Alexander's parti pris, operationalised as a production
  sequence (mechanic → geometry → narrative reason).
- Kishōtenketsu Twist beat = the "introduce-then-combine" in SMB grammar, made
  explicit and required rather than optional.
- Odyssey density-over-span = confirms the 3-floor-plane limit from level_design_references.md;
  adds the specific mechanic of keeping the apex visible throughout ascent.
