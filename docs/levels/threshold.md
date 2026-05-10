# Level Concept: "Threshold"

> **Status: concept — awaiting human selection before greybox.**
> This is one of three Gate 1 candidates. The human picks; Claude builds.

---

## Parti

*Three architecturally distinct zones separated by abrupt thresholds; the level is a study in contrast — the Stray moves from the human scale of an abandoned habitation layer through a punishing maintenance buffer into the inhuman scale of active industrial machinery, and only after completing all three does the spatial grammar reveal itself as a story of wrong-scale belonging.*

---

## Genius loci

The vertical border region between Habitation Layer 7-sub and Industrial Tier 3. Nobody designed it as a *level* — it is the accumulated mess of three different building programmes from three different eras, bodged together where they collide. Habitation was built for people: wide corridors, rounded edges, vestigial signage in a language nobody reads. The maintenance buffer was built for machines: tight, rectilinear, efficient, hostile. The industrial tier was built for production, not transit: everything is enormous, and the Stray is navigating the *gaps* between equipment sized for freight robots.

The level is a kind of accidental autobiography of the megastructure: you can read its history in its layers.

---

## Double-reading

**Traversal reading**: three zones of increasing difficulty, separated by dramatic spatial shifts.

**Architectural reading**: three scales of belonging. Habitation (human scale, warm) → Maintenance (machine scale, neutral) → Industrial (production scale, hot). The Stray fits *none* of them — too small for human corridors (designed for people who are gone), too soft for machine passages (designed for robots with no fear), too fragile for the industrial tier (designed for heavy equipment). The level is not about reaching the other side; it is about the Stray's complete spatial alienation from every layer it passes through. This reading emerges on completion, when the player has experienced all three scales.

Pick: **narrative double-reading** (the spatial contrast tells a story about belonging the traversal alone doesn't).

---

## Procession — 5 beats, ~15–20 s each

### Beat 1 — Ki: The Habitation Layer (introduction)
- Zone: wide, crumbling pedestrian corridors at human scale (~3 m ceilings, ~4 m wide).
- Geometry: rubble-blocked paths, broken floor sections, a collapsed wall creating a platform sequence. Some platforms are furniture at unexpected angles (shelving units as ledges — the Stray is tiny relative to them; the furniture reads as architecture at this scale).
- Atmosphere: warm sodium key, dust in the light beams, vestigial signage (abstract — no legible text). Fog is thicker here (habitation layers are lower, damper).
- Hazard: none — falling floor sections that are structurally *obvious* before stepping. Introduction only.
- Mechanic: straightforward platform hop, one-idea-per-beat: *learn the Stray's relative size in each zone*.
- End condition: reach the service hatch threshold to Zone 2.

### Threshold 1 — The Service Hatch
- A vertical drop through a narrow circular hatch in the floor (the architectural kind, not player-designed).
- The drop is 5 m — survivable, scripted to be safe (floor below is close enough). Audio changes on pass-through: warm ambient cuts to mechanical hum. Light shifts from sodium warm to cool fluorescent blue-white. Temperature (implied by ambient audio) drops.
- This threshold is *felt*, not just crossed.

### Beat 2 — Shō: The Maintenance Buffer (development)
- Zone: tight, rectilinear corridors (~2 m ceilings, ~1.8 m wide — the Stray barely fits). Everything is the same grey. No decoration.
- Geometry: precision platform sequences — moving service carts on rails (simple back-and-forth, predictable), narrow ledges between pipe banks, a section where the Stray must time movement between cycling maintenance arms.
- Atmosphere: cold blue-white fluorescent. No warmth at all. The Stray's red is extremely visible against this palette — it reads as an error, an intruder.
- Hazard: maintenance arms (rotating geometry, scripted period — not random). Contact respawns the Stray at section start.
- Mechanic: timing + precise movement. The buffer is the hardest zone.
- End condition: reach the alcove before the second threshold.

### Rest — Checkpoint Alcove (between buffer and industrial)
- A maintenance nook with a single warm indicator light — amber, the Stray's family.
- This is the most dramatic lighting contrast in the level: the nook is one warm light in an otherwise entirely cold zone.
- Checkpoint placed here. The Stray stops here and we hold for a beat.
- Sound: the industrial tier is audible through the wall — a low, deep, rhythmic mechanical pulse.

### Threshold 2 — The Expansion
- The maintenance corridor opens without warning into the industrial tier — a sudden 10× scale increase.
- The ceiling is 30 m up. The floor below is 20 m down. The Stray emerges onto a narrow service gantry halfway up.
- CameraHint pulls the camera back to show the full scale for ~2 s. The Stray is a red speck on a grey gantry in a vast machinery hall. This is the awe beat.

### Beat 3 — Ten: The Industrial Tier (scale twist)
- Zone: huge machinery components the Stray navigates between. Platforms are gantries, maintenance ledges, equipment tops — all sized for freight-robot access, therefore generous in width but requiring long jumps between them.
- Geometry: large horizontal gaps (requiring committed long jumps), descending gantry sequences (the Stray is navigating *down* between equipment), occasional moving conveyors (slower than the baffles in Lung, but the gap distances are larger).
- Atmosphere: amber-warm industrial light (different warmth from habitation — this is heat, not home). Distant machinery sounds in layers.
- Hazard: one industrial press (large periodic geometry, obvious animation, generous timing window). Contact respawns.
- Mechanic: committed long-gap jumps. The blob shadow is critical here — landing targets are platforms at the same height as or below the Stray's takeoff; depth judgement matters.
- End condition: reach the terminal platform.

### Beat 4 — Ketsu: The Apex (finale)
- The terminal platform is 15 m below the entry gantry but 60 m horizontally. A final sequence of 4 large platforms leads to it.
- Each jump is the longest in the level — but the platforms are wide and the timing windows are generous. This is not the hardest beat; it is the most *spectacular*.
- Win trigger: a control pedestal on the terminal platform. Activating it halts the press and dims the amber lights to a single warm spot on the Stray. A brief hold, then the win-state UI.
- *Spatial note*: CameraHint at the terminal platform frames the exit corridor of Zone 1 — the warm habitation corridor — visible far above and behind through the intervening machinery. All three zones visible in one frame. The spatial autobiography closes.

---

## Platforming verbs

| Verb | Role | Beat |
|------|------|------|
| Standard precision jump | Primary — habitation and buffer sections | Ki, Shō |
| Timing (maintenance arms) | Primary — buffer section | Shō |
| Long-gap committed jump | Primary — industrial section | Ten, Ketsu |
| Variable jump height | Secondary — furniture-platform clearances in habitation | Ki |
| Blob shadow depth read | Secondary (critical) — industrial gap landings | Ten, Ketsu |

No new systems needed. Industrial section stresses the blob shadow specifically — deliberately designed to showcase it.

---

## Par route (skilled-player line)

In the maintenance buffer (Beat 2), a skilled player can skip two intermediate platforms by timing a longer cross-cart jump rather than using the cart as a stepping stone. This is visible: the far platform is in sightline across the cart's travel path; the cart passing temporarily creates the jump window.

In the industrial tier (Beat 3), two of the four gantry transitions have a direct lower line that a skilled player can commit to by jumping early (before reaching the far edge of the current platform), trading safety for speed. The direct line is *shorter* in distance but requires a shallower angle.

---

## Skill range (target times)

| Player | Target time | Route |
|--------|-------------|-------|
| New | ~3 min | Full safe route, checkpoint reset in buffer |
| Skilled | ~70 s | Par routes in buffer + industrial |
| Expert | ~50 s | All par routes, no resets |

---

## Level kit requirements

- Habitation rubble chunk platforms (irregular, furniture-scale)
- Service cart on rail (AnimationPlayer, ping-pong motion, configurable speed)
- Maintenance arm (rotating geometry, period-configurable, collision layer World)
- Industrial gantry (wide flat platform, no railing — gap to below is always visible)
- Industrial conveyor belt (slow continuous motion, optional surface velocity for interesting landing physics)
- Industrial press (large descending/ascending geometry, generous period, obvious telegraph)
- Checkpoint × 1 (alcove between zones 2 and 3)
- CameraHint × 3 (habitation intro, industrial scale-reveal, win terminal finale)
- Zone-specific ambient lighting: warm sodium (Zone 1), cold fluorescent (Zone 2), amber industrial (Zone 3)
- Service hatch prop (Threshold 1 — circular hatch, transition marker)

---

## Notes for greybox

- Habitation zone: 3 m ceilings, 4 m wide corridors. Keep it feeling "meant for people" — slightly generous dimensions for a precision platformer.
- Maintenance buffer: deliberately tight. 1.8 m ceiling means the Stray's jump arc clips the ceiling if they jump at full height — crouch the ceiling on purpose. This is oppressive by design.
- Industrial tier: 30 m ceiling minimum. Equipment scale should make the Stray look like a bug. Don't hold back on scale.
- The Threshold 2 expansion is the money shot. The geometry transition needs to be abrupt — the buffer corridor opens *directly* onto the gantry with no ramp-up. The scale shock must be instant.
- Maintenance arms: rotate slowly, telegraph clearly. No instant-kill gotchas in a first-level concept.
- Industrial press: should be visible for at least 2 s before the player reaches it (enough time to read the period). Wide enough that running under it at mid-cycle is clearly the intended action.
- Do not use biolume cyan in this level — that's Lung's palette accent. Threshold's accent is the single amber light in the checkpoint alcove, making it precious.
