# Level Concept: "Spine"

> **Status: concept — awaiting human selection before greybox.**
> This is one of three Gate 1 candidates. The human picks; Claude builds.

---

## Parti

*A single vertical column, split open by a collapse, that the player ascends in three acts — each pass through the same shaft at a different elevation and from a different spatial relationship to the structure.*

---

## Genius loci

The load-bearing spine of a failed mega-column, cracked open along a structural seam aeons ago. It is not a shaft anyone was meant to enter — the interiors are for service robots, not the Stray. Cold condensate drips from corrugated metal ribs. Fans somewhere above push stale recycled air down through the crack. The column is so large it has its own micro-climate: fog collects at the base, thins toward the break at the top where grey outside light leaks in. The column still *functions* — load still runs through it — but the part the Stray traverses is the wound in its side.

---

## Double-reading

**Traversal reading**: a vertical gauntlet — climb through a dangerous broken structure, reach the top.

**Architectural reading**: the column is a spine. At the base the player sees only the inside surface of the crack (tight, claustrophobic, rib-like). By the midpoint, the player is climbing the inside of the column wall — they are between the ribs. From the open break near the top, looking back down, the column's repeating structural struts read unmistakably as vertebrae. The title is earned by the ending vantage, not the beginning.

Pick: **architectural double-reading** (same structure, two spatial meanings depending on elevation).

---

## Procession — 5 beats, ~20 s each

### Beat 1 — Ki: The Wound (compression entry)
- Entry through a narrow horizontal maintenance corridor that dead-ends at a drop.
- Player drops into the column base: sudden vertical expansion — a vista downward (fog obscures the bottom, CameraHint holds frame on the shaft depth before releasing).
- First platforms: close to the column wall, slow spacing, no hazards. Learning the shape of the space.
- Hazard: none — this is introduction.
- End condition: reach the first wall-jump strut pair.
- *Spatial note*: warm key light from behind the entry corridor, cold fill from above. The Stray is lit from behind entering a cool dark shaft.

### Beat 2 — Shō: The Ribs (wall-jump development)
- The shaft narrows. Structural ribs jut in from both sides, creating a natural wall-jump corridor.
- Platforms are minimal — this section is almost entirely wall-jump sustained.
- Pacing: find the rib, jump, find the opposite rib, keep climbing. Rhythm is predictable so the player can build speed.
- Hazard: occasional collapsed rib section forces a mid-air redirect.
- End condition: reach the maintenance alcove (checkpoint).
- *Spatial note*: ribs create regular pool-of-light / shadow alternation. Every rib is lit on the underside by the warm key.

### Rest — Checkpoint Alcove
- A maintenance platform bolted to the wall. Single warm amber bulb (the Stray's colour family). Slightly wider than needed — the first breath.
- Checkpoint placed here (threshold between Shō and Ten).

### Beat 3 — Ten: The Collapse (route-find twist)
- The usual wall-jump path is blocked — a collapsed section fills the rib corridor.
- Player must read the environment to find the alternate route: a gap in the opposite wall leads to a secondary passage (the outside shell of the column) running parallel to the crack.
- The secondary passage is more exposed but better lit. The player now sees the outside scale of the column for the first time — it is enormous. They have been climbing something incomprehensibly large.
- Hazard: exposed sections with no wall on one side; variable-height jumps required.
- End condition: re-enter the main crack at a higher level through a service hatch (threshold moment — sound and light change back).
- *Spatial note*: the exterior passage is CameraHint territory — pull back to show the column's outer surface against the grey megastructure sky.

### Beat 4 — Ketsu: The Break (precision finale + vista)
- The top section of the crack opens to outside light — the structural seam has fully split here, creating an exposed chimney.
- Platforms are rubble chunks lodged in the crack. Spacing is tight and irregular; the blob shadow is critical.
- Hazard: wind push (slight horizontal drift on airborne frames, representing pressure differential through the opening).
- Final jump: from the highest rubble chunk to a narrow ledge on the column's exterior.
- Win trigger: a service platform on the exterior, with a view back down the column's full height. The procession's full length is visible; the vertebrae shape reads.
- *Spatial note*: warm Stray light against grey megastructure exterior. Vista held by CameraHint for ~2 s before releasing to the win-state UI.

---

## Platforming verbs

| Verb | Role | Beat |
|------|------|------|
| Wall jump | Primary — drives the whole column ascent | Shō |
| Variable jump height | Secondary — rib clearance, rubble spacing | all |
| Long gap leap | Secondary — collapse reroute + Ketsu rubble | Ten, Ketsu |

No mechanics the controller doesn't already support. No new systems needed.

---

## Par route (skilled-player line)

The rib corridor in Beat 2 can be ascended continuously without stopping on intermediate ledges — a skilled player wall-jumps from rib to rib in a single unbroken chain, bypassing three rest-ledges. This line is *visible* from the safe route (the rest ledges are slightly inset from the rib face; a confident player can see the unbroken wall-jump angle) but requires precise timing. Par route saves ~8 s over safe route.

---

## Skill range (target times)

| Player | Target time | Route |
|--------|-------------|-------|
| New | ~3 min | Full safe route, two checkpoint resets |
| Skilled | ~60–75 s | Par route Beat 2 + fast Ketsu |
| Expert | ~45 s | Perfect wall-jump chain, no resets |

---

## Level kit requirements

- Wall-jump struts (pairs of flat vertical surfaces ~1.8 m apart)
- Maintenance platform / checkpoint anchor
- Rubble chunk platforms (irregular, 3–5 sizes)
- Collapsed section prop (static geometry)
- Service hatch threshold prop
- CameraHint × 3 (base vista, exterior reveal, win vantage)
- Wind push zone (simple Area3D applying constant horizontal force on overlap, any mobile-capable approach)

---

## Notes for greybox

- Column internal diameter at base: ~15 m (vast but not unreadable).
- Column wall thickness visible in exterior section: ~3 m.
- Total height: ~60 m (gives headroom for ~3 min traversal; elevator shaft scale).
- Fog: dense at base (visibility ~8 m), clears progressively toward the open break.
- Lighting key axis: warm from below (level entry) → cold ambient upper shaft → grey outside light at break.
- The exterior passage (Beat 3) should be brief — the agoraphobia contrast must land quickly, not wear out.
- Do not add enemies to this concept. The geometry and route-find in Beat 3 are the tension.
