# Research Index — Project Void

Notes accumulated on adjacent topics: 3D platformer character controllers,
mobile touch UX, brutalist architecture and *BLAME!* readings, level
design references, perf practices on Mobile renderer.

Each note lives at `docs/research/<slug>.md`. Append entries below as
they're written.

---

## Super Meat Boy 3D — live reference

- [`smb3d.md`](smb3d.md) — Released March 2026 (Sluggerfly + Team Meat). Closest live reference to Project Void. Key findings: (1) blob shadow is mandatory for depth perception — even SMB 3D's full spatial-aid suite still drew depth-perception criticism; (2) fixed-per-level camera chosen explicitly because dynamic camera "couldn't keep up with the pace" — Void's tripod model is aligned; (3) level length ~20 s skilled — each Void beat should be ~20 s; (4) air dash as one-shot depth-error correction is a strong mobile candidate for Assisted/Gate 1; (5) ghost trail attempt-replay confirmed as the pedagogical core mechanic, not optional; (6) style loss (SMB 3D's biggest failure) reinforces: protect the brutalist/BLAME! identity through the 3D transition.

- [`air_dash.md`](air_dash.md) — Gate 1 mechanic candidate: air dash as depth-error correction. Design spec (duration ~0.18 s, single airborne charge, recharges on landing), input mapping (Option A: right-zone swipe with gesture disambiguation; Option B: double-tap jump), ControllerProfile integration (3 new params: `air_dash_speed`, `air_dash_duration`, `air_dash_gravity_scale`; default 0 = disabled, backwards-compatible), player.gd integration sketch, TouchInput signal approach, juice hooks, and universal-vs-profile-exclusive analysis. Recommendation: implement with speed=0 default (disabled), enable on Assisted first, let device testing drive per-profile tuning. Key implication: blob shadow (read) + air dash (recovery) = Void's complete answer to SMB 3D's depth-perception problem.

## Character controllers

- [`character_controllers.md`](character_controllers.md) — SMB grammar, Mario Odyssey assists (ledge magnetism, coyote), A Hat in Time homing-attack model, Pseudoregalia momentum rethink, Demon Turf custom-physics rationale. Implications: Snappy profile values are in the right range; Assisted profile should prioritise ledge magnetism; Momentum ramp should reduce deceleration not increase max speed.

- [`assist_mechanics.md`](assist_mechanics.md) — Godot 4 implementation approaches for the Assisted controller profile (PLAN P0 item 4). Covers: ledge magnetism (ShapeCast at jump time, 2 rays, ≤ 1.0 m/s impulse, new ControllerProfile properties), arc assist (20-step parabola simulation, ≤ 15% jump_velocity correction, per-frame), sticky landing (2-frame speed reduction × 20%, `_was_on_floor_last_frame` tracker), edge-snap on landing (post-move_and_slide position correction, implement last). 6 new ControllerProfile properties (all default 0 = off, backwards-compatible). Implementation order: sticky landing → ledge magnetism → arc assist → edge-snap. Key implication: `_was_on_floor_last_frame` doubles as the landing-squash trigger for the juice system — extract to `_landed_this_frame` in `_physics_process`.

## Gate 1 — enemies and hazards

- [`enemy_archetypes.md`](enemy_archetypes.md) — Gate 1 prerequisite: one enemy archetype. How SMB / SMB 3D (hazards before creatures), Dadish 3D (slow linear patrollers), and Celeste (enemy-as-timing-window) approach first-enemy design. Mobile constraints: touch correction latency favours static/timed hazards over patrollers at Gate 1; hitbox generosity required; palette separation (cold hazards vs Stray red). Godot 4 options: Option A (static kill zone — recommended for Gate 1), Option B (timed hazard), Option C (linear patroller — Gate 2). **Void recommendation:** `HazardBody.tscn` (Area3D + configurable radius) covers Gate 1; zero AI, one skin, no state machine. Gate 2 adds a slow linear patroller.

## Juice density

- [`juice_density.md`](juice_density.md) — Astro's Playroom / Astro Bot "layered receipt" model (audio+visual+world per action), comparison with SMB sparse-juice approach, mobile considerations (UI feedback compensates for no haptics), draw-call cost of each juice type. Gate 1 priority ranking: landing squash > jump stretch > jump puff > pre-jump anticipation. Key implication: Void should sit closer to SMB density than Astro Bot given the brutalist tone.

- [`squash_stretch_animation.md`](squash_stretch_animation.md) — Godot 4 implementation approaches for squash-stretch. Recommendation: `Tween` on `$Visual.scale` (zero draw-call cost, procedural impact magnitude). `just_landed` flag already present (`_was_on_floor_last_frame`); impact factor = `clamp(-velocity.y / terminal_velocity, 0, 1)`. Guard against reboot-sequence conflict (`_is_rebooting`). TRANS_SPRING for recovery overshoot. Full integration checklist: `_play_land_squash` + `_play_jump_stretch` in `player.gd`, both gated behind `squash_stretch` juice toggle, `impact_scale` slider in dev menu. Apex-hold deferred (needs apex-state signal). Pre-jump anticipation best as `AnimationPlayer` fixed clip.

Suggested early reads (from CLAUDE.md) — now covered:
- ~~Astro's Playroom — juice density~~ Done (iter 13, `juice_density.md`).

## Mobile touch UX

- [`mobile_touch_ux.md`](mobile_touch_ux.md) — Dadish 3D pain points, fixed vs. floating joystick research, thumb-reach analysis for 1920×1080 landscape, Genshin/Sky/Alto design notes. Implications: floating stick + dead zone correct; no UI in top 25% of screen; ledge magnetism is highest-ROI assist; `stick_dead_zone_ratio` param needed before Gate 1.

- [`touch_dead_zone_calibration.md`](touch_dead_zone_calibration.md) — truncating vs. remapping dead zones (formulae + tradeoffs), Genshin Impact observations (8–10% inner dead zone, outer dead zone at 90–95%, floating stick, camera safety band), Sky and Alto notes, HCI sizing guidance (10–20% for touch). 5 concrete implications: current 15% truncating dead zone is correct for Gate 0; Floaty profile may need remapping later; outer dead zone at 93% for sprint ergonomics; camera safety band note; dead zone belongs in touch_overlay not ControllerProfile.

Suggested:
- ~~Genshin Impact touch layout postmortem (dead zone tuning specifics).~~ Done (iter 20, `touch_dead_zone_calibration.md`).
- Sky: Children of the Light gesture system (covered briefly above; more detail on social-game input philosophy worth a deeper read for Gate 2+ UX decisions).

## Brutalism / *BLAME!* / megastructure

- [`brutalism_blame.md`](brutalism_blame.md) — Nihei's *BLAME!* visual grammar (scale ambiguity, darkness as material, recursion, navigation-by-infrastructure), brutalist architecture principles (béton brut, expressed structure, mass over surface), megastructure hierarchy (mega-column → floor slab → service run → habitation volume), Kevin Lynch legibility vocabulary. 10 concrete implications for Project Void: cold grey palette, darkness as architecture, Stray red as sole warm accent, multi-scale kit pieces, expressed structure in geometry, service-run compression sequences, column-array depth shots, "failed program" landmark props, no skybox, vertical axis primary.

Suggested:
- ~~Christopher Alexander on parti and pattern~~ Done (iter 14, `alexander_pattern_language.md`).
- Deeper *BLAME!* volume-by-volume architectural analysis (each volume of the manga has a distinct spatial character worth mapping).

## Checkpoint and respawn design

- [`checkpoint_design.md`](checkpoint_design.md) — Gate 1 prereq. How SMB / SMB 3D (no
  checkpoints, room-as-unit), Dadish 3D (sparse mid-level checkpoints, mobile tolerance
  ~10 s dead time), and Celeste (screen-boundary as implicit checkpoint) handle checkpoints.
  Key constraint: ghost trails require all replayed attempts to share one anchor point —
  mid-level checkpoints break this unless per-segment trails are implemented (Gate 2 work).
  **Void recommendation:** Gate 1 uses Option A (no mid-level checkpoint, level entry as
  ghost-trail anchor, single `CheckPoint` node that signals but doesn't change respawn
  target yet). Mid-level checkpoints + per-segment ghost trails deferred to Gate 2.
  Mobile-specific reboot UX: 0.3–0.35 s for Snappy (thumb re-settle floor), 0.5 s for
  Floaty/Assisted acceptable. Design hardest beat last to minimise restart-to-action time.

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

- [`alexander_pattern_language.md`](alexander_pattern_language.md) — Alexander's *Notes
  on the Synthesis of Form* (form resolves a network of forces; each beat must satisfy ≥ 3),
  parti pris (the organizing concept of every beat, which aligns with SMB's one-idea-per-room
  rule), *A Pattern Language* (named reusable solutions mapped to a Void kit: Compression–
  Release, Threshold, Landmark, Rest Alcove, Gauntlet Ascent, Overlook, Desire Line). 8
  concrete implications: write a parti per beat, use pattern vocabulary for `kit/` naming,
  Compression–Release as primary procession unit, ≥ 3 forces per beat, structural landmarks
  not decorative, Stray-red as structural centre, desire line = par route, kit naming.

- [`holistic_level_design.md`](holistic_level_design.md) — Steve Lee GDC 2017 holistic level design
  (three integrated dimensions: gameplay / presentation / narrative; affordances and intentionality;
  authoring pipeline: mechanic → geometry → world-reason). GMTK synthesis: Kishōtenketsu 4-beat arc
  (Ki/Shō/Ten/Ketsu — intro / development / twist / resolution, ~5 min per arc, throw mechanic away
  after ketsu), Odyssey density-over-span (compressed verticality, apex always visible, no monotonic
  ascent). 6 concrete implications: holistic affordance pipeline, Ten beat required per beat, brutalist
  expressed structure = free affordances, apex visibility rule, Twist beat for precision platformers,
  intentionality check before committing a kit piece.

Suggested (still open):
- ~~Mark Brown / Game Maker's Toolkit — specific 3D platformer level-design episodes.~~ Covered above (holistic_level_design.md).
- ~~Steve Lee (doublefunction.co.uk) — GDC talk "An Approach to Holistic Level Design."~~ Done (iter 17, holistic_level_design.md).

## Performance & rendering

- [`godot_mobile_perf.md`](godot_mobile_perf.md) — Godot 4 Mobile renderer capabilities/limits, TBDR tile-based GPU architecture (Adreno/Mali), draw call and triangle budgets, ASTC texture notes, baked vs dynamic lighting tradeoffs, Jolt physics profiling tips, in-game profiling steps. Implications: bake lights before Gate 1; keep alpha-blended objects exceptional; target ≤ 50 draw calls at Gate 1; no MSAA; profile Jolt separately.

- [`compatibility_renderer.md`](compatibility_renderer.md) — Feature comparison: Mobile (Vulkan) vs Compatibility (GLES3) for every feature Void uses. Key finding: all current Void features are present in Compatibility; visual delta is minimal given the brutalist-fog-darkness aesthetic. Performance: Compatibility is faster on Adreno 506-era hardware (20–40%), comparable or slower on modern Adreno 710 (test device). Recommendation: keep Mobile as primary; a secondary Compatibility export preset is viable at Gate 2+ for low-end Android market expansion, zero code changes required, just a second export preset.

Suggested:
- ~~Godot's Compatibility renderer fallback for very-low-end devices.~~ Done (iter 23, `compatibility_renderer.md`).
- Tile-based deferred mobile GPU costs (PowerVR/Mali/Adreno).

---

## How to add a research note

1. Create `docs/research/<slug>.md` with a short intro, the source(s),
   and the takeaways relevant to Project Void (not a transcript).
2. Add a one-line entry under the right section above linking to the
   file.
3. If a note materially changes a design direction, also append a
   `DECISIONS.md` entry referencing it.
