# Level Concept: "Lung"

> **Status: concept — awaiting human selection before greybox.**
> This is one of three Gate 1 candidates. The human picks; Claude builds.

---

## Parti

*A vast horizontal chamber where the floor breathes — the Stray must learn the rhythm of a still-functioning ventilation array to cross it, and only from the far end does the double-reading land: the whole space was a lung.*

---

## Genius loci

A primary ventilation array for a buried habitation district. The machinery still runs — nobody shut it off because nobody remains to do so. Great diaphragm-fans cycle at 40-second intervals, pushing air through ducts the diameter of buildings. The moving platforms *are* the ventilation baffles: massive metal slabs riding on pneumatic columns, rising and falling on a timed programme written for machines, not the Stray. The air is slightly warmer than the column exterior — stale but breathable. The ambient sound is the whole level's character: low-frequency hum, the creak of metal on metal, the slow exhale of a system still performing its function for a population that isn't there.

---

## Double-reading

**Traversal reading**: a timing gauntlet — read the moving platform cycles, jump accurately, cross the chamber.

**Architectural reading**: the chamber is a lung. The baffles are a diaphragm. The ducts branching off the far wall are bronchi. The converging duct at the far end (the win threshold) is a trachea. Only visible from the far side, looking back: the geometry the player just crossed resolves into a recognisable anatomical form. The sound retrospectively clicks into place as breathing.

Pick: **architectural double-reading** (mechanical system reads as biological organ from a specific vantage).

---

## Procession — 4 beats + epilogue, ~20 s each

### Beat 1 — Ki: First Breath (introduction)
- Entry: a small pressurised lock chamber the Stray is blown out of (the exhale). The chamber's door seals behind them — no going back.
- The chamber is revealed in full on exit: vast, horizontal, lit by bioluminescent strips running the duct edges (cool cyan accent — first appearance of the biolume palette from the BLAME! brief).
- First section: three wide baffles moving slowly in sync, generous spacing, same phase. One-idea-per-beat: *learn that the platforms move*.
- Hazard: none — only the drop to the chamber floor below if you fall.
- End condition: reach the first fixed platform between sections.
- *Spatial note*: baffles lit from below by the biolume strips; tops lit by the cooler ambient. The Stray's red reads against both.

### Beat 2 — Shō: Counter-Phase (development)
- Fixed rest platform marks the section boundary (no checkpoint — earned only at the end of this section).
- Second section: baffles now split into two groups, moving counter-phase. Adjacent baffles alternately rise and fall; the player must time transfers across a gap where the platforms briefly align at mid-height.
- Pacing: two easy counter-phase gaps, then a sequence of three rapid ones that demand committed jumps.
- Hazard: wind column — one section of the chamber has a vertical updraft (duct underneath blowing) that briefly extends airborne time. The Stray must compensate for the float.
- End condition: reach the checkpoint platform at the chamber midpoint.
- *Spatial note*: the midpoint platform has a duct vista — looking down through a grate at the machinery below. The scale of what's beneath reads here.

### Rest — Checkpoint (midpoint platform)
- Wide platform. View forward (more baffles) and back (the section just cleared). The rhythm of the first section continues behind them — the pattern is now readable as a pattern.
- Checkpoint placed here.

### Beat 3 — Ten: Power Cycle (twist)
- The system cycles: all baffles stop at once. The chamber falls silent for 3 seconds — then restarts in a *different* rhythm, faster, asymmetric.
- Player must re-learn the rhythm under pressure. The familiar pattern is wrong now.
- Additional hazard: horizontal air current in the second half of this section pushes the Stray sideways (Area3D constant velocity push), requiring movement correction mid-jump.
- End condition: reach the final fixed platform before the terminal duct.

### Beat 4 — Ketsu: The Trachea (finale)
- A single narrow bridge of three small fixed platforms leading to a massive duct opening in the far wall — the trachea.
- No moving platforms here. The hazard is the wind: strong outward pressure from the duct (against the player's direction) requires constant horizontal input to maintain forward momentum. Jumps into the wind arc back.
- Final jump: from the last fixed platform into the duct threshold.
- Win trigger: inside the duct, 5 m in, a single control terminal. The Stray reaches it; the ventilation system exhales — all baffles descend simultaneously, holding position. Sound: a long resonant exhale.
- *Spatial note*: CameraHint at the duct threshold pulls the camera back to frame the full chamber. The baffle geometry, the duct branches, the fan shapes — from this angle, the lung reads.

---

## Platforming verbs

| Verb | Role | Beat |
|------|------|------|
| Precise horizontal jump | Primary — all cross-platform transfers | all |
| Timing / pattern reading | Primary — the whole level is a timing puzzle | all |
| Variable jump height | Secondary — wind float compensation, baffle height variations | Shō, Ketsu |
| Air control (preserved H velocity) | Secondary — wind current correction mid-air | Ten, Ketsu |

No new mechanics. The level stresses timing and air control already in the controller.

---

## Par route (skilled-player line)

In Beat 2, the counter-phase gap sequence can be traversed without stopping on intermediate ledges by reading the 2-beat alignment window and jumping *into* the gap rather than waiting for full rise. This line requires committing before the platform fully rises, shaving ~10 s off the safe route. Visible: the alignment gap is perceptible from the prior platform.

In Beat 3 (after power cycle), a skilled player who anticipates the cycle reset can start moving during the 3-second pause, arriving at the next platform as it rises rather than waiting for its first full cycle.

---

## Skill range (target times)

| Player | Target time | Route |
|--------|-------------|-------|
| New | ~3 min | Full wait-for-platform, two checkpoint resets |
| Skilled | ~70–80 s | Par route Shō + anticipate cycle |
| Expert | ~50 s | Perfect reads, no resets |

---

## Level kit requirements

- Moving baffle platform (large flat slab, AnimationPlayer-driven Y translation, configurable period and phase offset)
- Fixed mid-section platform (static geometry)
- Upward wind zone (Area3D with `gravity_point = false`, `gravity_direction = Vector3.UP`, mild force)
- Horizontal wind zone (Area3D constant velocity, configurable direction + magnitude)
- Biolume strip light (OmniLight3D, cyan tint, very low energy — accent only)
- Pressurised lock chamber prop (entry)
- Large duct opening prop (trachea threshold)
- CameraHint × 2 (chamber reveal, duct threshold lung-reveal)
- Checkpoint × 1 (midpoint platform)

---

## Notes for greybox

- Chamber dimensions: ~60 m wide × ~8 m tall × ~80 m long. Horizontal scale is the spectacle; vertical is tight (ceiling is low, amplifies claustrophobia).
- Baffle size: ~4 m × 4 m. Wide enough to stand confidently; narrow enough that falling off is plausible.
- Platform travel: ~2.5 m vertical stroke. Player stays well within the chamber ceiling even on a risen baffle.
- Baffle period (Beat 1): 4 s per cycle, slow. (Beat 2): adjacent pairs 2 s out of phase. (Beat 3 post-cycle): 3 s period, random phase offsets (seed the AnimationPlayer offsets, don't make them truly random per-frame).
- Biolume strips: strip lights along the lower duct edges only. Never bright. They define edges, not illuminate.
- Do not use the biolume palette except here — it is the rare accent from the BLAME! brief; overuse dilutes it.
- The lung double-reading requires the final CameraHint to be placed precisely inside the duct opening, looking back: the fan blades frame the bottom like a diaphragm; the duct branches fork like bronchi; the baffles read as the lung surface. Test this angle before committing to geometry.
