# Level Design References — Project Void

Sources synthesised from: The Level Design Book (book.leveldesignbook.com), GMTK
(Game Maker's Toolkit), Mario Odyssey / New Donk City analysis (Gamedeveloper.com),
Super Meat Boy design discussion, academic analysis of precision platformer structure.

---

## The SMB grammar for level structure

Super Meat Boy is the primary precision-platformer ancestor for Void. Its level
design philosophy maps directly to our constraints:

- **Short, focused rooms.** Each level is completable in under a minute at skill.
  This enforces that each room has a single governing idea — one obstacle type,
  one spatial constraint, one mechanic — not a medley. Short rooms prevent the
  "spray-and-pray" regression where players survive through luck rather than
  mastery.
- **Introduce, then combine.** The classic structure: level A introduces obstacle
  X alone; level B introduces obstacle Y alone; level C combines X and Y. The
  combination is the climax. Never introduce and combine simultaneously in a room
  that's the player's first encounter with either element.
- **Instant respawn removes punishment; death becomes information.** The Team Meat
  design brief: "The time it takes for Meat Boy to die and respawn is almost
  instant — the player never waits to get back into the game, the pace never
  drops, the player doesn't even have time to think about dying before they are
  right back." Death is a tool for reading the level. The reboot animation must
  serve this — it should feel punchy (acknowledgement) not long (punishment). Our
  current `reboot_duration = 0.5 s` default is at the upper bound; tune toward
  0.3–0.35 s for precision-feel.
- **Ghost trails are the payoff, not just a stat.** SMB's end-of-level replay of
  every failed run isn't a progress tracker — it's a visualisation of the learning
  curve. Watching your clones pile up and then watching one make it through is
  the emotional arc of the level. This confirms: the Gate 1 attempt-replay overlay
  is not a nice-to-have; it is part of the core experience grammar.
- **No penalty for exploration.** Infinite lives + instant respawn = "try anything."
  Levels that punish exploration with setbacks kill the SMB feel. Avoid trap
  deaths (hazards the player can't see until they're already falling toward them).
  All hazards should be visible from the safe zone before the player commits.

**Source:** Super Meat Boy (2010), Team Meat; SMB level design discussion on Steam
(https://steamcommunity.com/app/40800/discussions/0/611698195162033804/); Wikipedia
(https://en.wikipedia.org/wiki/Super_Meat_Boy)

---

## Verticality principles (The Level Design Book)

The Level Design Book's verticality chapter (book.leveldesignbook.com/process/layout/flow/verticality)
is the most concise treatment of the rules. Key extractions:

- **Height conveys progression better than compass directions.** "Climb to the top"
  or "fall to the bottom" are unambiguous navigational goals. "Go north" fails in
  a complex 3D space. Void's vertical megastructure already exploits this — every
  level should have an unambiguous "up" and "down" as the primary axis of read.
- **Organise vertical space into floor planes, max three per area.** Players can
  track roughly three distinct height layers. More create redundant middle paths
  without new dynamics. Above three, vertical complexity reads as noise, not depth.
  For a section of a Void level: ground level / mid-structure / high ledge. That's
  the ceiling.
- **Downward flow is heavy; upward flow is earned.** Drops are mechanically easy —
  one-way, no effort, hard to reverse. Use drops for dramatic reveals, threshold
  moments, and the "fall into a new space" beat. Climbs are effort — they are the
  challenge. Climbing should correspond to the level's difficulty peaks.
- **Three types of vertical progression:**
  - *Ascending* — climbing toward a goal. Communicates challenge and achievement.
    Use for the main challenge path and the ending threshold.
  - *Descending* — falling toward a space. Communicates discovery, descent into
    the unknown. Use for level entry beats (the Stray drops in from above) and
    compression-into-void transitions.
  - *Mixed* (multi-elevation circuit) — the player rises, falls, rises again.
    Use sparingly; very powerful for "revisit with new perspective" sequences.
- **Upward vs. downward camera affordances.** On a gamepad/touch controller,
  players naturally hold the crosshair horizontal. Rapid vertical combat-style
  precision is awkward. For Void: vertical *platforming* is fine (you navigate to
  a floor plane, which is horizontal); vertical *aiming* or *reacting* to sudden
  vertical threats is hard. Prefer hazards with clear horizontal safe zones even
  if the platforming is vertical.

**Source:** The Level Design Book — Verticality
(https://book.leveldesignbook.com/process/layout/flow/verticality)

---

## Flow and pacing (The Level Design Book + academic sources)

- **Flow is the design of movement.** The key variables: speed, direction, clarity,
  and mechanics tuning. Void's levels are movement-centric (precision platforming),
  so every spatial decision must be tested against "does this move well?" before
  "does this look right?"
- **Critical path vs. desire line.** The critical path is the minimum route through
  the level. Desire lines are paths players actually try to take. Good design
  makes these converge by making the critical path feel natural, and makes the
  anti-path (the harder/faster alternate route) feel *visible but non-obvious*.
  Hidden par routes are frustrating; visible-but-hard par routes are inviting.
  Design the par route before the safe route, not after.
- **Rhythm groups.** Hazards placed in rhythmic patterns create rhythmic movement.
  Even if a section is hard, *rhythmic* difficulty is learnable in a way that
  arrhythmic difficulty is not. A sequence of three platforms at equal spacing with
  equal timing is learnable in three attempts; a sequence of three platforms with
  arbitrary spacing takes ten. Rhythm ≠ easy; rhythm = masterable.
- **Rest areas are mandatory in hard sequences.** After a long precision string,
  give the player a beat of safety — a wide platform, a stretch of no hazards, a
  checkpoint. Rest areas exist for two reasons: they prevent cognitive overload;
  and they make the next hard section feel harder by contrast. No rest area = flat
  difficulty = no peaks.
- **"Bad" flow has purpose.** Sharp turns, dead ends, and backtracking create drama
  and tension in specific contexts. A maze-like area communicates disorientation.
  A dead end with a collectible rewards exploration. Don't optimise every flow
  decision — intentional friction is legibility too.

**Source:** The Level Design Book — Flow (https://book.leveldesignbook.com/process/layout/flow);
academic: "Rhythm-based level generation for 2D platformers" (ResearchGate,
https://www.researchgate.net/publication/220795055); "A framework for analysis of 2D
platformer levels" (https://www.researchgate.net/publication/229039146)

---

## Mario Odyssey — density, variety, vertical momentum

New Donk City is the most-studied of Odyssey's stages for good reason: it is the
densest Odyssey level and the most structurally instructive.

- **Density over sprawl.** New Donk City is smaller than other kingdoms but has
  more distinct challenge categories. The vertical structure enables higher
  density: multiple floor planes within the same footprint. For Void, a compact
  level that uses three floor planes is almost always better than a sprawling
  horizontal level. Smaller footprint + more vertical = more interesting/m².
- **Recognisable form creates intuitive traversal.** The New York city-block
  structure lets players immediately understand traversal possibilities without
  tutorial — cars bounce, buildings can be climbed, rooftops are safe ground.
  For Void's megastructure: express structure tells players what they can do.
  A visible beam is a walkable surface. A visible shaft is a climbable space.
  Exposed pipes are obstacles. Architectural honesty = level-design legibility.
- **Mixed flow prevents monotony without adding features.** The storm sequence
  compresses the player into a focused mission; the post-boss city open phase
  releases into free exploration. This compression→release structure at the
  macro level (the whole stage arc) mirrors the micro-level compression→release
  rhythm. Both scales exist simultaneously in a well-designed level.
- **Vertical momentum is a structural tool.** The escalation from street → car
  trampolines → spark possession → rooftop isn't just difficulty escalation —
  it's a spatial ascent that changes what the player can see and where they
  can go. Ascent unlocks vistas. Use the player's vertical position to gate
  what's visible.

**Source:** "The Level Design of Super Mario Odyssey's Best Stage"
(https://www.gamedeveloper.com/design/the-level-design-of-super-mario-odyssey-s-best-stage);
additional: Goomba Stomp — Mario movement evolution
(https://goombastomp.com/mario-movement-evolution-3d-platformer/)

---

## Spatial legibility — Kevin Lynch vocabulary (applied)

Kevin Lynch's city-legibility vocabulary (from *The Image of the City*, 1960) is
already referenced in LEVEL_DESIGN.md. Applied concretely to Void's levels:

- **Path**: the Stray's critical-path route through the level. Should be the most
  lit, most open, most clearly continuous sequence of geometry. The player should
  be able to look down the path and see where it goes without turning.
- **Edge**: boundaries of traversable space. In a megastructure: the edge of a
  platform, the base of an impassable wall, the horizon of a void. Edges define
  the playfield; ambiguous edges cause player deaths that feel unfair. Make edges
  clear — geometry, lighting, fog-depth contrast, or colour.
- **District**: a section of the level with a consistent character. Within a
  single Void level, a district change is a threshold moment. Use it to mark
  the beginning of a new challenge type.
- **Node**: an intersection or convergence point. In Void, nodes are checkpoints,
  vista moments, or places where alternate routes rejoin. They're the natural
  placement for `CameraHint` nodes.
- **Landmark**: a visible, distinctive, non-traversable element that anchors
  spatial orientation. In a brutalist megastructure, a landmark might be a giant
  fallen column, a distant blinking machine, a stack of light shafts. Every Void
  level needs at least one — especially in enclosed dark spaces, because
  disorientation in darkness destroys the flow state instantly.

---

## Implications for Project Void

1. **Each level beat = one governing idea.** No beat should introduce two new
   hazard types simultaneously. Map levels as sequences of single-idea beats, then
   combine in later beats.

2. **Shorten the reboot.** SMB's analysis suggests `reboot_duration` should lean
   toward 0.3 s for precision feel. The current 0.5 s default errs toward "cinematic"
   — fine for Floaty, too slow for Snappy. Make this per-profile (or add a
   `reboot_duration` override to `ControllerProfile` and set Snappy's lower).

3. **Author the par route first.** For every level, identify the fastest skilled
   route before placing the safe route. The safe route is the padding around
   the par route, not vice versa. This prevents par routes that are hidden,
   accidental, or blocked by safe-route geometry.

4. **Max three floor planes per area.** When sketching level geometry, name the
   three planes before placing any detail. If a fourth is needed, it's a new
   district (new area, threshold between them).

5. **Every level needs a landmark.** Before greyboxing, name the landmark. Something
   visible from multiple positions that orients the player. In a fog-heavy dark
   megastructure, landmark placement is more critical than in a lit open world.

6. **Rhythm-group the hazards.** Group obstacles in consistent timings — even if
   timing varies across groups, each group should internally rhyme. A player who
   dies three times should be able to hum the timing of the sequence on attempt 4.

7. **Rest areas after every major string.** After any sequence requiring 3+ precision
   actions in a row, give the player a safe beat. This doubles as the natural
   checkpoint placement moment (threshold + rest = checkpoint).

8. **Downward entry beats.** Level starts with the Stray dropping in (descending
   flow). This is a free dramatic moment — the player sees the scope of the level
   on the way down. Design the entry view deliberately. What does the player see
   during that first fall?

9. **Confirm the ghost trail as Gate 1 P0.** The attempt-replay overlay is part of
   the SMB grammar, not decoration. Without it, the "teach through death" loop loses
   its emotional payoff. It should be in Gate 1's critical path.

10. **Brutalist architecture is already the legibility system.** Exposed structure
    tells players what is traversable. Expressed beams = walkable. Visible columns =
    climbable. Maintenance shafts = passable. Don't skin the geometry — let the
    architecture be the affordance language. This is free level design legibility.
