# Gate 1 Shape-Family Comparison

*Written iter 106 — 2026-05-16. Intended for the human's use when picking a Gate 1 survivor.*

Nine shape-families are now playable from `level_select.tscn`. This note
summarises what each currently is, what makes it distinct, what camera/control
demands it places on the player, and how much work remains to bring it to
Gate 1 completion. Use it alongside a device session to make the pick.

---

## Gate 1 completion requirements (recap)

From `docs/CLAUDE.md`:

- One full level (~60–90 s skilled, ~3 min new player)
- Brutalist art direction roughed in
- Checkpoints, instant respawn, reboot animation ✅ already in every level
- Attempt-replay (ghost trail) ✅ already wired in `game.gd`
- One enemy archetype ✅ PatrolSentry available
- One collectible type ✅ DataShard available
- Win state + results screen ✅ already in every level
- At least 2 controller profiles to compare on device

The heavy per-level delta is: **level length / beat density** and **art direction**.

---

## Shape-by-shape breakdown

### 1. Threshold — linear corridor *(Iter direction session)*

**What it is:** Three connected zones along a Z axis. Zone 1 plaza (open, visible
routes), Zone 2 maintenance (enclosed, overhead route), Zone 3 industrial (vertical
gantry descent). 6 descending gantries, 1 PatrolSentry, 1 IndustrialPress, distant
skyline vista.

**Camera demand:** Automatic Z-follow handles it well. Zone transitions require
the camera to track a descending Z axis — the hardest spring-arm test in any level.

**Control demand:** Platform widths vary 2–6 m; the Z-descent in Zone 3 is the
precision spike. No void below early zones — tolerant on-ramp, hard payoff.

**Art infrastructure:** Most developed of all levels. Kenney Factory Kit + Space
Station Kit set-dressing placed (13 props). Zone atmosphere zones wired. Distant
skyline BoxMesh layer present. PatrolSentry live. IndustrialPress live. DataShard
placed.

**What's left for Gate 1:** Beaten length already ~35 s; needs 1–2 more beats
or a harder Z3 to push to ~60 s skilled. Material overrides on dressing props
(kenney_kit_material_override research note). Par-time calibration. The shape
itself was rejected as "reads as a straight line" — the fix would be routing that
forces a non-obvious turn, or a much more interesting Z3 obstacle.

**Verdict note (human, 2026-05-16):** Rejected after two passes. Corridor
shape-family is represented; do not polish further without an explicit reversal.

---

### 2. Spire — vertical climbing tower *(Iter 97)*

**What it is:** 10×8 m shaft, 8 static platforms in a zigzag, 1 moving platform
(1 m Y, 3 s), 8 m rise to summit (y=17). Gaps 1.5–2.5 m, tuned for Snappy.

**Camera demand:** Vertical ascent is the camera's hardest case — the spring-arm
must manage the ratchet up without constant resets. `vertical_follow_ratchet` was
specifically designed for this. Worth testing on device.

**Control demand:** Tight vertical jumps demand reliable double-jump (literal flap)
timing. Gaps tuned for Snappy — may feel cramped on Floaty. The summit pitch is a
double-jump requirement; first failure is informative.

**Art infrastructure:** Minimal — grey CSG/MeshInstance primitives only. No props,
no sentry, no press. Moving platform is a plain BoxMesh.

**What's left for Gate 1:** More beats (current ~50 s skilled, nearly at target).
Art pass (concrete material, atmospheric OmniLights already present as 3-zone arc).
Optional sentry on a mid-platform to block the simple zigzag solve. Par-time
calibration. The enclosed shaft geometry naturally limits camera fighting — worth
testing on device for camera feel.

**Strength:** Verticality is the primary design dimension in BLAME!-inspired spaces.
The tower communicates scale directly. If the camera handles it cleanly, this is a
strong candidate.

---

### 3. Rooftop — open-air void traversal *(Iter 98)*

**What it is:** 8 platforms (SpawnSlab → FragA → BeamB → SlabC [CP] →
MovPlatE → EastPost → StepG → RelayPad [WIN]). 2 DataShards. No enclosing walls
or ceiling. Cold void below all edges.

**Camera demand:** Open sky means the spring-arm has nothing to clip against. The
void below is the only depth cue. Blob shadow becomes critical here — without
it, jumps across open space read as ambiguous.

**Control demand:** Narrow beams (BeamB is the first precision spike) with a void
penalty. The moving platform crossing is a timing challenge over an open gap. Wind
effects (not yet implemented) could add difficulty without adding hazards.

**Art infrastructure:** Minimal primitives. No props, no sentry, no press. Moving
platform live.

**What's left for Gate 1:** Current ~45 s skilled — borderline at minimum. Needs
1–2 more beats. Optional sentry on EastPost. Art pass (concrete + brutalist edge
language). The "megastructure columns" in atmosphere are BoxMesh atmospherics —
dressing them with Factory Kit pieces would add identity quickly. Par-time
calibration.

**Strength:** The Stray is most legible against the void — it's the scene that
most strongly communicates "small bird in a vast machine world." The open
rooftop is the closest to the exterior-glimpse archetype from `blame_level_vocab.md`.

---

### 4. Plaza — hub with radiating spokes *(Iter 99)*

**What it is:** 18×18 m hub floor, 3 radiating arms (north critical path,
east moving-platform timing, west narrow-beam precision). Central monitoring
pillar (4×45×4 m) is the landmark and win target. 1 moving platform,
2 DataShards, 4 OmniLights.

**Camera demand:** Open hub means the camera must track the player across a wide
horizontal plane. When the player turns from hub to arm, the lookahead pulls the
camera early — good for clarity. The 45 m pillar is always visible as a landmark
(Lynch vocabulary — node + landmark combined).

**Control demand:** Branching choice is visible from hub centre — this is the
"orientation platform." Each arm introduces a different skill: timing, precision,
or route-finding. The summit vault (PillarSummit) requires a committed double-jump.

**Art infrastructure:** Minimal primitives. No props, no sentry, no press.

**What's left for Gate 1:** Current ~40 s skilled on critical path. East/West arms
add ~10–15 s for 100% completion. Needs a sentry or press on one arm to add hazard
interest. Art pass. The central pillar is a natural anchor for art — a massive
concrete column with biolume conduits at the summit aligns directly with
`brutalism_blame.md` (column-array depth shots, expressed structure).

**Strength:** The hub grammar is the strongest for player agency. All three routes
are visible simultaneously — the player makes a choice rather than following a path.
The central pillar as a permanent visual landmark solves the "where am I" problem
from the start. Closest to the Spyro PS1 grammar that works on mobile (no camera
fighting required when the hub is the anchor).

---

### 5. Cavern — maze with branches *(Iter 100)*

**What it is:** Conduit network. EntryBay → NorthPass (narrow, 4 m) → JunctionRoom
(14 m wide) [CP] → three exits: WestSpur (shard dead-end), EastSpur (shard dead-end),
NorthLedge (climb) → FinalChamber [WIN]. Fog 0.090 (densest — ~10 m visibility).

**Camera demand:** Low ceilings and narrow passages create the highest spring-arm
pressure of any level. Occlusion avoidance (raycast implemented) may pull the camera
sharply in tight corridors. Worth testing on device specifically for this.

**Control demand:** Orientation is the core challenge, not reflex. The player cannot
see the route from spawn. Exploration grammar rather than precision grammar. May
feel slow for an SMB-inspired game — the genre expects rapid death/retry loops, not
exploration pauses.

**Art infrastructure:** 4 ceiling slabs + 5 wall slabs create enclosure. 5 OmniLights.
No sentry, no press, no props.

**What's left for Gate 1:** Level length is borderline (~45 s skilled). The
exploration-vs-precision tension may need a design resolution: either add explicit
route signage (breadcrumbs of light) or embrace the disorientation as a design
beat. Art pass is the largest project here — enclosing a full cavern space readably
in brutalist materials is significant work. Low-fog visibility is the most hostile
environment for the spring-arm camera.

**Strength:** Unique spatial grammar; no other level forces a navigation decision
before a motor-skill test. If the human enjoys exploration as well as precision,
this is the distinctive candidate.

---

### 6. Descent — inverted descent *(Iter 101)*

**What it is:** Decommissioned elevator shaft. 7 platforms in offset zigzag
(TopSlab → LedgeA east → LedgeB [CP] → LedgeC east → BasePad [WIN]).
Expert line: skip two platforms by dropping straight to BasePad. 2 DataShard
side ledges. Fog 0.065. Lighting gradient dim amber → biolume cyan (dead shaft,
active destination).

**Camera demand:** Downward traversal. The spring-arm's `vertical_follow_ratchet`
was designed for upward-only; descent may cause the camera to lag the player or
fight as the player drops. Needs device testing.

**Control demand:** Falling-as-progress is the unique grammar. The expert line
(skip platforms by controlled fall) is a learnable skill that rewards mastery —
exactly the SMB "ghost trail shows the better route" mechanic. Each LedgeA/C is
also a trap that can slow the player.

**Art infrastructure:** Minimal. 4 atmospheric column pillars. No props, no sentry.

**What's left for Gate 1:** Current ~40 s skilled. Adding a vertical hazard (a
falling press or sentry at BasePad approach) is the natural beat escalation.
Art pass: the shaft geometry is the key — factory-kit vertical pipes running down
the shaft walls would immediately read as an elevator column. Par-time calibration.
Camera behaviour during descent is the biggest unknown and needs device testing.

**Strength:** Expert-line golf is a distinct skill ceiling — the gap between the
beginner and expert route is clearly readable (ghost trails will make this explicit).
The "falling equals winning" inversion of typical platformer grammar is a memorable
design hook.

---

### 7. Filterbank — enclosed obstacle gauntlet *(Iter 102)*

**What it is:** 4-beat machine sequence in sealed chambers. Press1 (1.5 s dormant)
→ Sentry B2 (2.0 m/s) → MovingPlatform (8 m void gap, 4 s) → Press2 + Sentry B4
(combined, 1.2 s dormant, 2.5 m/s). 2 DataShard shelves. Fog 0.080. 76 m total.

**Camera demand:** Enclosed walls + ceiling mean the camera rarely clips. The
forward-Z progression makes lookahead effective. Most camera-friendly level.

**Control demand:** Sequential hazard gauntlet — introduce-then-combine. Highest
mechanical density of all levels. Beat 4 (combined press + sentry) is the hardest
beat currently in the project. This is closest to the SMB grammar (one mechanic per
room, then twist).

**Art infrastructure:** Enclosed walls and ceiling are in place (MeshInstance3D slabs).
AnimatableBody3D press mechanics live. PatrolSentry live. 2 DataShards live.
The enclosure means the art pass is primarily material overrides on walls and ceilings.

**What's left for Gate 1:** Level is the most mechanically complete of all — 4 distinct
beats, combined final challenge. Current ~45 s skilled. Art pass (concrete walls,
amber emissive conduits per `machinery_hazards.md`). Par-time calibration. The
press animations are currently visual only (position lerp in script) — a full
windup anticipation flash (amber emissive strip warning) would be high-value juice.
This level is closest to "done" mechanically.

**Strength:** Most mechanically developed. Introduce-then-combine is the correct
SMB grammar. Closed geometry means camera feels solid. If the human wants the
level that's closest to Gate 1 done, this is it.

---

### 8. Viaduct — exposed bridge crossing *(Iter 103)*

**What it is:** Suspended concrete spans over deep void. EntryAbutment → Span1
(2 m wide, 14 m) → gap → PierHead1 [CP] → [moving platform, 14 m gap] → Span2
(1.5 m) → Span3Final (2 m, sentry at Z=68) → ArrivalAbutment [WIN]. 1 DataShard
on a side spur. Fog 0.045 (lightest — far shore visible).

**Camera demand:** Open span means unobstructed sky and void. Similar to Rooftop
but with less surface area — the camera's lateral range is larger than any platform
width. Blob shadow is critical on spans.

**Control demand:** Stay-on-path or fall. The narrowest gameplay corridor of all
levels (Span2 is 1.5 m — ~5 player widths). The sentry on Span3Final forces a
rhythm-read on a narrow surface simultaneously. The highest-consequence single-beat
of all levels.

**Art infrastructure:** Minimal primitives. Moving platform live. PatrolSentry live.
2 pier columns (visual-only, 30 m tall) descend into void — strongest atmospheric
geometry of any level.

**What's left for Gate 1:** Current ~45 s skilled. Beat sequence already introduce-
then-spike (wide span → moving platform → narrow span + sentry). Art pass:
concrete spans + railing geometry (or deliberately no railing — the void is
the edge language). Par-time calibration. Second DataShard opportunity exists
off Span2 if level extension is needed.

**Strength:** The Stray on a narrow bridge over a dark void is the most direct
visual expression of the BLAME! scale disparity — tiny creature on infrastructure
not built for it. The two pier columns descending into darkness are already the
best atmospheric geometry in the project. Unique risk-curve: every step on a span
carries terminal consequences.

---

### 9. Arena — ringed arena *(Iter 104 — PR #133 draft, not yet on main)*

**What it is:** Decommissioned pressure containment ring. SpawnSlab → SWCorner →
WestArm → [moving platform, 9 m void, 4.5 s] → NWCorner [CP] → NorthArm (sentry,
±3 m X, 2.0 m/s) → vault (3.5 m horizontal + 4.0 m rise) → CentralAltar [WIN].
1 DataShard from NorthArm inner edge.

**Camera demand:** Circular traversal. The player rotates around a central void —
the camera must track a clockwise or counterclockwise heading. Auto-framing will
pull the lookahead perpendicularly to the ring; this may fight the player's
intended direction at corners. Most unusual camera demand of all levels.

**Control demand:** Circuit-board-reading grammar. The player must understand the
ring is a path, not a choice space. The CentralAltar vault (running double-jump
required) is the skill spike. Moving platform on the 9 m gap forces patience.
The ring grammar is unusual — likely needs signage (emissive floor arrow?) to
prevent confusion at SWCorner.

**Art infrastructure:** Minimal. Not yet on main (PR #133 draft).

**What's left for Gate 1:** The most uncertain. Camera behaviour on circular
traversal needs device testing before committing. If camera handles it, the
unique grammar (circuit the arena, then strike the centre) is compelling. If
camera fights, the shape breaks. Art pass deferred. Needs to be merged to main
before a depth pass can begin.

---

## Summary table

| # | Shape | Skilled par | Mech depth | Art done | Sentry? | Press? | Camera risk |
|---|-------|-------------|------------|----------|---------|--------|-------------|
| 1 | Threshold | ~35 s | High | Most | ✅ | ✅ | Low |
| 2 | Spire | ~50 s | Medium | Low | ❌ | ❌ | Medium (vertical) |
| 3 | Rooftop | ~45 s | Low | Low | ❌ | ❌ | Low-medium |
| 4 | Plaza | ~40 s | Low-med | Low | ❌ | ❌ | Low |
| 5 | Cavern | ~45 s | Low | Low | ❌ | ❌ | High (tight walls) |
| 6 | Descent | ~40 s | Medium | Low | ❌ | ❌ | Medium (downward) |
| 7 | Filterbank | ~45 s | High | Med | ✅ | ✅ | Low |
| 8 | Viaduct | ~45 s | Medium-hi | Low | ✅ | ❌ | Medium (open spans) |
| 9 | Arena | ~45 s | Medium | Low | ✅ | ❌ | High (circular) |

---

## Implications for Void

1. **Filterbank is mechanically the most complete** — introduce-then-combine
   structure is already correct for Gate 1, and the enclosed geometry is
   camera-safe. If the human wants the fastest path to Gate 1 done, Filterbank
   is the pick.

2. **Plaza is the strongest for player agency and camera clarity** — the hub
   grammar gives simultaneous visible choice; the central pillar is a permanent
   landmark. Mechanically thin right now but the grammar is the most onboarding-
   friendly for a mobile player encountering 3D platforming for the first time.

3. **Viaduct has the strongest BLAME! visual identity** — pier columns descending
   into the void, narrow spans, fog-diffused far shore. The emotional register
   matches the source material more than any other level. Risk: narrow spans
   may punish mobile imprecision more than any other level.

4. **Spire is best for testing the camera's vertical ratchet** — the vertical
   tower is the most direct test of the system that was built specifically for
   this game. If it works on device, Spire demonstrates the core technical
   investment.

5. **Threshold is the most art-developed but was rejected twice** — unless the
   human explicitly reverses the direction, do not re-invest here.

6. **Cavern and Arena carry the highest camera risk** — both have unusual spatial
   grammars that the spring-arm was not explicitly tuned for. Do not pick these
   for Gate 1 without a device session confirming camera behaviour first.

7. **Any pick except Cavern and Arena can be brought to Gate 1 in 2–3 depth
   iterations** — art pass, 1–2 more beats, par-time calibration. Filterbank
   may need only 1 iteration for Gate 1 minimum viable.
