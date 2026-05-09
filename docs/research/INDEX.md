# Research Index — Project Void

Notes accumulated on adjacent topics: 3D platformer character controllers,
mobile touch UX, brutalist architecture and *BLAME!* readings, level
design references, perf practices on Mobile renderer.

Each note lives at `docs/research/<slug>.md`. Append entries below as
they're written.

---

## Character controllers

- [`character_controllers.md`](character_controllers.md) — SMB grammar, Mario Odyssey assists (ledge magnetism, coyote), A Hat in Time homing-attack model, Pseudoregalia momentum rethink, Demon Turf custom-physics rationale. Implications: Snappy profile values are in the right range; Assisted profile should prioritise ledge magnetism; Momentum ramp should reduce deceleration not increase max speed.

Suggested early reads (from CLAUDE.md):
- Astro's Playroom — juice density (not yet covered).

## Mobile touch UX

_(none yet)_

Suggested:
- Genshin Impact touch layout postmortem.
- Sky: Children of the Light gesture system.
- Alto's Odyssey one-tap design.

## Brutalism / *BLAME!* / megastructure

_(none yet)_

Suggested:
- Tsutomu Nihei interviews and *BLAME!* art reference.
- Christopher Alexander on parti and pattern.
- Kevin Lynch on legibility.

## Level design references

_(none yet)_

Suggested:
- Mark Brown / Game Maker's Toolkit.
- Steve Lee on level-design intent.

## Performance & rendering

_(none yet)_

Suggested:
- Godot Mobile renderer best practices.
- Tile-based deferred mobile GPU costs (PowerVR/Mali/Adreno).

---

## How to add a research note

1. Create `docs/research/<slug>.md` with a short intro, the source(s),
   and the takeaways relevant to Project Void (not a transcript).
2. Add a one-line entry under the right section above linking to the
   file.
3. If a note materially changes a design direction, also append a
   `DECISIONS.md` entry referencing it.
