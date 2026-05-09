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

- [`mobile_touch_ux.md`](mobile_touch_ux.md) — Dadish 3D pain points, fixed vs. floating joystick research, thumb-reach analysis for 1920×1080 landscape, Genshin/Sky/Alto design notes. Implications: floating stick + dead zone correct; no UI in top 25% of screen; ledge magnetism is highest-ROI assist; `stick_dead_zone_ratio` param needed before Gate 1.

Suggested:
- Genshin Impact touch layout postmortem (dead zone tuning specifics).
- Sky: Children of the Light gesture system (covered briefly above; more detail on social-game input philosophy worth a deeper read for Gate 2+ UX decisions).

## Brutalism / *BLAME!* / megastructure

- [`brutalism_blame.md`](brutalism_blame.md) — Nihei's *BLAME!* visual grammar (scale ambiguity, darkness as material, recursion, navigation-by-infrastructure), brutalist architecture principles (béton brut, expressed structure, mass over surface), megastructure hierarchy (mega-column → floor slab → service run → habitation volume), Kevin Lynch legibility vocabulary. 10 concrete implications for Project Void: cold grey palette, darkness as architecture, Stray red as sole warm accent, multi-scale kit pieces, expressed structure in geometry, service-run compression sequences, column-array depth shots, "failed program" landmark props, no skybox, vertical axis primary.

Suggested:
- Christopher Alexander on parti and pattern (to reinforce LEVEL_DESIGN.md principles in practice).
- Deeper *BLAME!* volume-by-volume architectural analysis (each volume of the manga has a distinct spatial character worth mapping).

## Ghost trail / attempt-replay overlay

- [`ghost_trail_prototype.md`](ghost_trail_prototype.md) — SMB ghost trail design (what it
  actually does, why it works pedagogically), four Godot 4 implementation options
  (MultiMesh recommended, ImmediateMesh fallback, GPU ring-buffer advanced, physics-replay
  discarded), concrete GDScript sketch for `game.gd` recorder + `GhostTrailRenderer` using
  300-instance MultiMesh (1 draw call), alpha-by-recency formula, open questions (colour
  palette, temporal window, checkpoint anchoring), 6 implications for Project Void including
  `Game.player_respawned` signal already wired.

## Level design references

- [`level_design_references.md`](level_design_references.md) — SMB grammar for level structure
  (short focused rooms, introduce-then-combine, death as information, ghost trails as core grammar),
  verticality principles (max 3 floor planes, descend=discovery/ascend=challenge), flow/pacing
  (rhythm groups, rest areas, par-route-first authoring), Mario Odyssey density-over-sprawl and
  expressed-architecture-as-affordance, Kevin Lynch vocabulary (path/edge/district/node/landmark)
  applied to megastructure levels. 10 concrete implications for Void including: one-idea-per-beat,
  shorten Snappy reboot to ≤ 0.35 s, 3-floor-plane rule, landmark requirement, rhythm hazards,
  rest areas at checkpoints. Sources: The Level Design Book, Gamedeveloper.com, Team Meat / SMB.

Suggested (still open):
- Mark Brown / Game Maker's Toolkit — specific 3D platformer level-design episodes.
- Steve Lee (doublefunction.co.uk) — GDC talk "An Approach to Holistic Level Design."
- Christopher Alexander on parti and pattern (reinforce LEVEL_DESIGN.md principles).

## Performance & rendering

- [`godot_mobile_perf.md`](godot_mobile_perf.md) — Godot 4 Mobile renderer capabilities/limits, TBDR tile-based GPU architecture (Adreno/Mali), draw call and triangle budgets, ASTC texture notes, baked vs dynamic lighting tradeoffs, Jolt physics profiling tips, in-game profiling steps. Implications: bake lights before Gate 1; keep alpha-blended objects exceptional; target ≤ 50 draw calls at Gate 1; no MSAA; profile Jolt separately.

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
