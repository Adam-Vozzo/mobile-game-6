# Checkpoint and Respawn Design — Precision Platformers

**Focus:** How precision platformers handle checkpoint placement, respawn UX, and
the interaction between checkpoints and ghost-trail replay systems. Gate 1 prereq
for Void — checkpoints + instant respawn are P0 items for the vertical slice.

**Sources**
- Super Meat Boy 3D (Sluggerfly, 2026) — `smb3d.md` in this repo
- Super Meat Boy (Team Meat, 2010) — design retrospectives, GDC 2011 postmortem
- Dadish 3D (Thomas K Young, 2024) — Play Store reviews
- Celeste (Maddy Makes Games, 2018) — screen-boundary checkpoint model

---

## SMB / SMB 3D: no checkpoints, rooms as the atomic unit

SMB's core constraint: **the room is the retry unit.** Each room is short enough (~20 s
skilled per `smb3d.md`) that dying always resets the entire room. No mid-room
checkpoints. This works because of three mutually-reinforcing decisions:

1. **Rooms are designed around the retry budget.** "Short focused rooms" is a
   constraint, not a compromise. Each room introduces one idea. A full run is at
   most 20–40 s including any sub-optimal line.

2. **Ghost trails need a fixed anchor.** All ghosts start from the room entry point,
   so every trail is a comparable read: "other attempts at the same full run." A
   mid-room checkpoint would split the attempts into two incomparable populations.

3. **Death is information, not punishment.** Instant respawn (<0.5 s) with ghost
   trails makes each death a free data point. The ghost density map shows the player
   exactly which segment is the bottleneck.

SMB 3D follows the same model: ~20 s per level, no checkpoints, instant respawn.
The difficulty ramp is handled by level selection (world order), not by checkpoint
distance.

---

## Dadish 3D: mid-level checkpoints in longer levels

Dadish 3D's levels run 90–120 s and include star/signpost checkpoints scattered
through each level. Play Store feedback points to two recurring complaints:

- **Checkpoints too sparse** in some levels — late-level deaths cost 60+ s of
  replay, which frustrates mobile players (shorter sessions, thumb fatigue).
- **Inconsistent placement** — some beats have a checkpoint just before the hard
  part; others don't. Players feel the inconsistency as unfairness.

Key mobile observation from the reviews: the tolerance threshold for dead time
(death animation + respawn + travel to the hard part) is approximately **10 s**
before frustration spikes. Beyond that, players start skipping attempts or quitting.
This is lower than the 15–20 s threshold common in console/PC precision platformers.

---

## Celeste: screen-boundary as implicit checkpoint

Celeste uses screen transitions as the de-facto checkpoint boundary. Each screen is
a self-contained spatial puzzle; dying resets to screen entry. Screens are typically
15–25 s skilled.

The strawberry collectible system overlays a secondary "no-death" challenge per
screen without adding mid-screen checkpoints — players who want the collectible must
clear the screen clean; casual players just retry until they pass. This layering is
elegant and scales without checkpoint placement decisions.

Implication: **screen = checkpoint** works well when screens are short (≤ 30 s
skilled). It becomes the Dadish 3D problem at 60+ s.

---

## The ghost trail constraint

Ghost trails impose a structural constraint on checkpoint design:
**all replayed ghosts must start from the same point.**

In SMB, that's the room entry. If a mid-level checkpoint is introduced:

- Attempts that died before the checkpoint never reached it — their ghosts have no
  useful data for the segment after the checkpoint.
- Attempts that respawned from the checkpoint start from a different origin.
- The two populations are not comparable; the trail becomes noise.

**Two valid resolutions:**

### A — Per-segment ghost trails

Each checkpoint defines a new ghost trail segment. Segment 1 ghosts (room entry →
checkpoint) are only shown in segment 1. Segment 2 ghosts (checkpoint → exit) are
shown in segment 2. On death in segment 2, only segment-2 attempts are replayed.

Pro: Preserves the pedagogical value of the ghost trail within each segment.
Con: More complex to implement — the `GhostTrailRenderer` needs segment awareness,
and the `Game` recorder must know which segment is active. Adds state to respawn.

### B — No mid-level checkpoints (SMB model)

Commit to short enough levels that no checkpoint is needed. Design the level in
beats of ~20 s each; a 4-beat level is 80 s total. With ~0.35 s reboot:
- 50 deaths × 80 s restart = 66 min. That's demanding but within range for a
  precision platformer aimed at players who chose a "hard" mobile game.
- Ghost trails: trivially simple — one anchor, one population, full comparability.
- Mobile consideration: 80 s is near the 10-s-dead-time threshold if half the run
  is before a typical death point. Design so the hardest beat is beat 4 (near the
  end), not beat 2. This minimises average restart-to-action time.

---

## Design options for Void's 60–90 s levels

Given the planned 4–5 beats at ~15–20 s each:

### Option A — No checkpoints (SMB model)
- Respawn at level entry on every death.
- Ghost trail: one anchor, full comparability, trivial to implement.
- Risk: the hardest beats are at the end; late-level deaths are long restarts.
- Mitigation: design beats so average death occurs in beat 3–4, keeping restart
  travel time below 40 s. Fast Snappy reboot (0.35 s) and no cutscene helps.
- **Recommended for Gate 1's first level.**

### Option B — One mid-level checkpoint
- Place one checkpoint at the beat-2/beat-3 boundary.
- Ghost trail: per-segment implementation required (see Option A of the ghost
  trail constraint section above).
- This is the right model for longer or harder levels at Gate 2+.
- **Recommend deferring to Gate 2.** Keep the `CheckPoint` node architecture in
  place from Gate 1 so no re-architecting is needed.

### Option C — Checkpoints as optional collectibles (Celeste model)
- Not appropriate before Gate 2. Flag for future consideration.

---

## Respawn UX

- **Reboot duration target: 0.3–0.35 s for Snappy.** Current default is 0.5 s
  (logged as a tuning backlog item in `PLAN.md` under "Snappy reboot_duration
  tuning"). The 0.35 s upper bound comes from `level_design_references.md`.
  The 0.3 s lower bound is mobile-specific: 300 ms is just long enough for
  the player's thumb to re-settle after a surprised lift. Below 0.3 s, input
  resumes before the thumbs are back in position, leading to phantom inputs.
- **Floaty / Assisted: 0.5 s is acceptable.** Those profiles are played in a
  slower rhythm; the longer reboot fits the pacing.
- **No fade-to-black.** The Stray should be visibly rebooting at the spawn
  point immediately. A screen-fill transition adds dead time with no payoff.
- **No delay between reboot animation end and control return.** The reboot
  sequence already ends with the player upright and physics-enabled; this is
  correct. Do not add a "ready" hold.

---

## Implications for Void

1. **Gate 1 first level: use Option A (no mid-level checkpoint).** Design the
   level in 4 beats of 15–20 s. Total run ~65 s skilled. No checkpoint needed;
   ghost trail stays simple.

2. **Ghost trail anchor = level entry point.** The `GhostTrailRenderer` sketch
   in `ghost_trail_prototype.md` already assumes this. Keep it. Don't add
   per-segment complexity until Gate 2 requires longer levels.

3. **Ship a `CheckPoint` scene node in Gate 1 even though it isn't used for
   mid-level respawn.** Wire it so activation emits a signal (`Game.checkpoint_reached`)
   but respawn still targets the level entry. At Gate 2, changing the respawn
   target from entry to last-checkpoint is a one-line change if the architecture
   is in place.

4. **Mid-level checkpoints are a Gate 2 feature.** Log in PLAN.md under P2.
   When introduced, implement per-segment ghost trails simultaneously.

5. **Death hardest beat last.** When authoring the Gate 1 level, place the highest-
   skill beat at beat 4 (near the exit), not beat 2. This keeps average restart-
   to-action time below 40 s even with no checkpoint.

6. **Ghost trail memory: 5 attempts × 90 s × 30 samples/s = 13 500 samples.**
   At 12 bytes per `Vector3`, that is 162 KB per trail segment — comfortable. The
   5-attempt cap from the `ghost_trail_prototype.md` sketch remains appropriate.
