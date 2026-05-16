# Gate 1 Depth Pass Checklist

*Written iter 107 — 2026-05-16. For use immediately after the human picks a shape-family
survivor. Open this note alongside the chosen level's `.tscn`/`.gd` and work through
it top to bottom.*

---

## What the breadth pass already gave every level

Every level built in iters 97–104 (Spire through Arena) ships with:

- `_ready()` positioning player from `PlayerSpawn` Marker3D
- `Game.current_level_path`, `Game.shards_total`, `Game.level_completed` signal wired
- `Game.start_run()` called on enter
- `ResultsPanel` instantiated and wired to `_on_level_completed`
- `Audio.set_ambient_zone(1)` called on enter
- `get_spawn_transform()` with null guard → `Transform3D.IDENTITY`
- `KillFloor` Area3D at appropriate Y (varies per level)
- `WinState` Area3D → `Game.level_completed` → results panel
- Ghost trail: `game.gd` recorder is always running; `GhostTrailRenderer` is in `threshold.tscn`
  (the Gate 1 level will need the renderer node added if the picked level is not Threshold)

None of these need touching on the depth pass.

---

## Cross-cutting items (apply to whichever level is picked)

### A. Par-time calibration

All breadth-pass levels use placeholder par times. After the first on-device run:

1. Do a 3–5-death wall-clock run (start timer at level load, stop at win).
2. Set `par_time_seconds` in the level script = that wall-clock time × 1.05
   (5 % buffer; see `run_timer_semantics.md` for the full formula).
3. Update the corresponding `_ok` assertion in `_test_early_breadth_level_defaults`
   or `_test_breadth_level_defaults` to match the calibrated value (or add a new test).

**Current placeholders:**
| Level | Placeholder | Expected after calibration |
|-------|-------------|--------------------------|
| Threshold | 35.0 s | ~37 s |
| Spire | 50.0 s | ~52 s |
| Rooftop | 45.0 s | ~47 s |
| Plaza | 40.0 s | ~42 s |
| Cavern | 45.0 s | ~47 s |
| Descent | 40.0 s | ~42 s |
| Filterbank | 45.0 s | ~47 s |
| Viaduct | 45.0 s | ~47 s |
| Arena (PR #133) | 40.0 s | ~42 s |

### B. Ghost trail renderer

`GhostTrailRenderer` lives in `threshold.tscn` as a child node. If the picked level is
not Threshold, add a `GhostTrailRenderer` instance to the chosen `.tscn`:

1. Open the chosen level `.tscn` in Godot.
2. Add a Node3D named `GhostTrailRenderer` at the scene root.
3. Assign `scripts/levels/ghost_trail_renderer.gd` to it.
4. Set `instance_count = 300`, `tail_seconds = 6.0` in the Inspector.

`game.gd` already records position samples and writes them to `GhostTrailRenderer` by
node name — no code change needed. See `ghost_trail_prototype.md`.

### C. Art pass (one day of work)

Pattern from `kenney_kit_material_override.md`:

1. **Structural bodies → `mat_concrete_dark.tres`:** Select each MeshInstance3D that
   forms walls, floors, or platforms. In Material slot 0, assign
   `resources/materials/mat_concrete_dark.tres`. Do NOT override emissive detail pieces.

2. **Emissive details → zone palette:** Zone 1 sodium amber, Zone 2 cold blue-white,
   Zone 3 biolume cyan (or the level's equivalent zones). Each zone OmniLight stays in
   Godot's Dynamic bake mode.

3. **Set-dressing from Kenney kits:** Drop Factory Kit or Space Station Kit pieces from
   `assets/art/architecture/` as decorative geometry at structural pinch-points and
   transition areas. Rule: every piece must have collision if it's within player reach;
   purely atmospheric pieces (distant background) can omit it.

4. **Distant skyline:** BoxMesh towers at Z ≥ 200 m (see Threshold's `DistantSkyline`
   group). Not mandatory for every shape but strongly recommended for any level with
   open sightlines.

5. **Style check:** fog density, ambient colour, and OmniLight positions against the
   brutalist palette. Reference: `brutalism_blame.md` 10 implications. Cold ≠ warm;
   Stray yellow is the only saturated warm anchor; reds stay on hazards only.

### D. Level-length audit (target ~60–90 s skilled)

After art pass: time the critical path deathlessly on device. If < 55 s:
- Add one more platforming beat between existing beats.
- Or add a tighter sentry or press window to an existing beat (forces slowing down
  and timing, adds 5–10 s naturally).
- Do NOT add a new zone if the shape-family is about a single spatial idea.

If > 100 s: compress one beat (raise a platform, widen a span, shorten a patrol path).

### E. DataShard audit (min 1, target 2 per Gate 1 level)

Shards must be:
- Off the par route (never on the critical path — they are optional).
- Reachable with a known jump (≤ 2.5 m gap, or clearly telegraphed by platform position).
- Placed in `data_shard` group in the `.tscn` (required for `Game.shards_total` count).
- Using `DataShard` scene or equivalent (Area3D + emissive OmniLight).

**Current shard state per level:**
| Level | Shards in scene | Notes |
|-------|----------------|-------|
| Threshold | 4 | Over-spec for breadth pass; keep 2 off critical path |
| Spire | 0 | **Missing — must add at least 1 during depth pass** |
| Rooftop | 2 | Good |
| Plaza | 2 | Good |
| Cavern | 2 (WestSpur + EastSpur) | Good; shard arms are the branch incentive |
| Descent | 2 (ShardLedge1 + ShardLedge2) | Good |
| Filterbank | 2 | Good |
| Viaduct | 1 (ShardPlatform) | Acceptable minimum |
| Arena (PR #133) | 1 | Acceptable minimum |

### F. Enemy/hazard audit (one archetype present)

Gate 1 spec: "one enemy archetype." `PatrolSentry` satisfies this. Check:

| Level | PatrolSentry | IndustrialPress | Hazard status |
|-------|-------------|----------------|--------------|
| Threshold | ✓ Z1 plaza | ✓ Z2 | Over-spec — both present |
| Spire | ✗ | ✗ | **Add 1 sentry mid-shaft to guard easy zigzag** |
| Rooftop | ✗ | ✗ | **Add 1 sentry on EastPost or MovPlatE landing** |
| Plaza | ✗ | ✗ | **Add 1 sentry on one spoke arm** |
| Cavern | ✗ | ✗ | **Consider sentry at NorthLedge approach** |
| Descent | ✗ | ✗ | **Consider vertical press or sentry on LedgeB** |
| Filterbank | ✓×2 | ✓×2 | Well-spec'd; no addition needed |
| Viaduct | ✓ Span3 | ✗ | Good — single sentry on final span is correct |
| Arena (PR #133) | ✓ NorthArm | ✗ | Acceptable for Gate 1 |

For any level that needs a sentry, follow `patrol_sentry.gd` spawn pattern from
`gauntlet.gd::_spawn_sentries()` — spawn programmatically in `_ready()`, set patrol
axis/distance/speed via `.set()`. Expose in dev menu under "Sentry — Tuning" if a
sentry is newly added.

---

## Per-level specific notes

### Spire (vertical tower)

Unique requirement: the enclosed shaft tests the camera ratchet hardest. After adding
a sentry, check that the sentry's patrol axis is X (not Z) to avoid blocking the only
vertical path. Sentry should guard a wide platform mid-shaft, not a narrow one.

Art note: the three-zone OmniLight arc (amber/cold-blue/biolume-cyan) is already
placed. The art pass is mostly material overrides — the geometry is already in place.
Biggest win: add wall-panel dressing from Space Station Kit to suggest the shaft is
a functional infrastructure element.

### Rooftop (open-air)

Blob shadow is most critical here — the only depth cue over the void. Verify blob
shadow is visible and sized correctly (see `depth_perception_cues.md`). Without a
shadow the player will struggle to judge gap clearances over open darkness.

Consider a wind-drift CameraHint at BeamB (the narrow beam) to pull the camera to a
wider side-angle view — it makes the beam width legible without requiring the player
to fight the camera manually.

### Plaza (hub)

The central 45 m pillar is the landmark. Art pass should prioritise making the pillar
read as significant: darker concrete, biolume accent at the top, possibly a slow
rotating light sweep. This is the "node" in Lynch vocabulary — everything else in the
level orients around it.

One sentry on the east or west arm is the single most effective difficulty addition —
the arm becomes a timing challenge in addition to its existing spatial grammar.

### Cavern (maze)

Camera in tight corridors is the highest risk. Test specifically whether the spring-arm
`pull_in_smoothing` setting causes jarring snaps in the 4 m-wide NorthPass. Raise
`occlusion_release_delay` if the camera pops back too fast after a tight corner.

Navigation legibility: add at least one OmniLight at the WestPass and EastPass
entrances in a distinctive colour (sodium amber vs cold blue) to make the two dead-end
arms distinguishable without relying on the player remembering which side they explored.

### Descent (inverted)

The camera ratchet was designed for upward movement. During the depth pass, test
whether it fights when descending. If it does: lower `floor_snap_threshold` in dev
menu → Camera tab, which makes the reference floor update faster on downward movement.
Document the tuned value in dev menu and PLAN.md.

Expert line (TopSlab → LedgeB → BasePad direct drop) is the ghost-trail payoff — the
second attempt ghost shows the player the shortcut. This is the cleanest expression
of the SMB "death as information" grammar in any current prototype.

### Filterbank (gauntlet)

Most mechanically complete of all breadth-pass levels. The depth pass is almost
entirely art: material overrides, industrial press emissive strip colour per zone,
and Factory Kit prop dressing on the chamber walls to break up the grey concrete.
Beat 4's combined Press2+Sentry2 is the precision spike — calibrate the dormant window
after on-device testing (see `machinery_hazards.md` for the 1.5× crossing-time rule).

### Viaduct (bridge crossing)

The narrow spans (1.5–2 m) are the precision grammar. Art pass: add visual
differentiation between the three spans — slightly different concrete surface colour,
or a different structural element (exposed rebar, partial collapse, industrial conduit
alongside). This makes it easier to re-orient after respawn.

The sentry on Span3 is at ±1.5 m patrol, leaving 0.1 m span-edge clearance. This was
designed to be tight (see `_test_viaduct_sentry_constants`). On device: if it feels
unfair, raise `patrol_distance` from 3.0 to 2.8 — gives 0.2 m clearance.

### Arena (PR #133 — pending review)

Merge PR #133 once the human picks Arena as the survivor. The arena adds a ringed
arc layout (circular perimeter, central elevated altar as win target). The moving
platform crosses the western arc void (most demanding timing segment).

If Arena is NOT the pick: the PR stays as a draft reference scene; consider merging
it to main anyway so the level selector shows all 9 options.

---

## Gate 1 completion checklist (copy-paste into PLAN.md when you start depth pass)

```
- [ ] GhostTrailRenderer node added to chosen level .tscn (if not Threshold)
- [ ] DataShard count ≥ 1, ≤ 4; all off critical path; all in data_shard group
- [ ] At least 1 PatrolSentry spawned programmatically via _spawn_sentries()
- [ ] Art pass: mat_concrete_dark.tres on structural bodies
- [ ] Art pass: Kenney kit props at structural pinch-points (with collision if reachable)
- [ ] Art pass: zone OmniLights in appropriate palette (sodium/cold-blue/biolume-cyan)
- [ ] Level length ~60–90 s skilled verified on device
- [ ] Par-time calibrated from 3–5-death wall-clock run
- [ ] KillFloor Area3D covers full out-of-bounds Y
- [ ] CameraHint node added at primary traversal challenge (optional but recommended)
- [ ] Distant skyline layer (BoxMesh atmosphere) present if level has open sightlines
- [ ] Results panel shows correct shard count (verify shards_total ≥ 1)
- [ ] Win state one-shot guard fires correctly (verify with _test_win_state_one_shot_guard)
- [ ] On-device: sentry speed/distance/par-time/blob-shadow all tuned and committed
- [ ] PLAN.md par_time_seconds updated from placeholder to calibrated value
- [ ] Unit test for calibrated par_time_seconds value updated
```

---

## What stays out of scope for Gate 1

Don't start these until Gate 2:

- Per-segment ghost trails (mid-level checkpoint anchoring) — Gate 2
- Baked lighting (LightmapGI) — Gate 2 (requires finalised geometry)
- Compatibility renderer second export preset — Gate 2
- Multiple biomes / level-select with par-time leaderboard — Gate 2
- PatrolSentry detection radius / speed variation — Gate 2 enemy upgrade
- Momentum and Assisted profile feel verdicts — Gate 2 (Gate 1 = Snappy on device)

---

## Sources synthesised

- `gate1_scene_lifecycle.md` — Game autoload wiring and reload strategy
- `checkpoint_design.md` — checkpoint placement philosophy and ghost trail anchor
- `collectible_design.md` — DataShard placement rules and collect zone radius
- `run_timer_semantics.md` — par-time calibration formula
- `enemy_archetypes.md` — PatrolSentry as Gate 1 archetype
- `ghost_trail_prototype.md` — GhostTrailRenderer wiring
- `kenney_kit_material_override.md` — art pass pattern
- `baked_lighting.md` — why baking stays out of Gate 1
- `gate1_shape_comparison.md` — per-level infrastructure state
- `depth_perception_cues.md` — blob shadow priority on open levels
- `machinery_hazards.md` — IndustrialPress dormant-window sizing
