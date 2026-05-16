# Ghost Trail Visual Design — Project Void

Iter 110 — written after the ghost trail renderer was built (iter 72)
and the recording lifecycle was hardened (iter 94).  The renderer
works; the open question is what it should *look like* against the
brutalist grey-concrete palette.

---

## The core problem: grey-on-grey

The current implementation uses `Color(0.55, 0.55, 0.60)` — a cool
mid-grey — as the trail colour.  Void's platforms are `mat_concrete_dark`
(albedo 0.32/0.32/0.35) lit by sodium amber.  The contrast ratio between
the trail spheres and the floor surface is near-zero.  Trails are
effectively invisible.

Additionally, there is a normalization bug in the fade formula (see
**The point_t bug** below) that makes fresh trails (early in a new
attempt) nearly transparent even if the colour were correct.

Both problems must be solved before the first human playtest of the
ghost trails.

---

## How reference games handle it

### Super Meat Boy (Team Meat, 2010)
White trails against a highly saturated, low-contrast background
(candy-coloured foreground art).  The white reads everywhere because
it is brighter than the environment, not more saturated.  The key
insight: **luminance contrast beats hue contrast**.  SMB levels are
also dark relative to the white trails, which is similar to Void's
dark-concrete world.

### Super Meat Boy 3D (Sluggerfly, 2026)
Per the `smb3d.md` research note, "ghost trail attempt-replay confirmed
as the pedagogical core mechanic."  The visual design appears to use a
bright, slightly tinted near-white that reads against both dark and
mid-grey surfaces.

### Celeste (Maddy Makes Games, 2018)
Madeline's ghost (Chapter 8 / Crystal Heart grabs) uses a blue-purple
tint with a translucent shimmer.  The Celeste colour palette is warm
(pinks, oranges) so cold-blue ghosts have immediate hue contrast, not
just luminance contrast.

### Trackmania / Source-engine ghost races
Consistent finding: ghost trails use a hue that is **complementary or
opposite to the dominant environment hue**.  Warm world → cold trail;
cold world → warm trail.

---

## Void's palette constraints

- **Dominant surface**: mat_concrete_dark — cool grey (0.32–0.35 albedo),
  slightly cold.
- **Dominant light**: sodium amber (Zone 1 warm, Zone 2 cold-blue, Zone 3
  amber-orange).  The *visual reading* of the concrete is warm in Zones
  1/3 and cool in Zone 2.
- **Player**: lemon yellow — the one warm saturated accent.  Must not
  be diluted.
- **Biolume accent**: cyan — "rare" per CLAUDE.md.  Reserved for depth
  signal (deeper zones) and data-shard highlights.
- **Hazard**: red/amber emissive strips on hazards.

**What doesn't work:**
- Grey (current): washes into the concrete. Invisible.
- Warm yellow: competes with the Stray; the ghost reads as a copy of the
  player rather than as a past attempt.  Confusing spatially.
- Red: reads as hazard/danger — wrong semantic.  Player gets confused
  about whether the trail is something to avoid.
- Warm amber: matches Zone 1/3 lighting; washes out against the sodium
  wash.

**What works:**

**Option A — Cold blue-purple (recommended):**
`Color(0.40, 0.55, 0.95)` or near `Color(0.35, 0.50, 0.85)`.

Reasoning:
- Complements the sodium-amber dominant light (Zones 1/3 → immediate
  hue contrast).
- In Zone 2 (cold-blue environment), the ghost is slightly lighter and
  more saturated than the ambient — still legible as a distinct object.
- Cold blue echoes the biolume palette.  A dead past-attempt reading as
  a cold biolume shimmer has a narrative coherence with Void's
  "depth-as-discovery" grammar (see `blame_level_vocab.md`).
- Does not dilute Stray yellow.

**Option B — Near-white:**
`Color(0.85, 0.88, 0.95)` — slightly blue-tinted white.

Reasoning:
- Purely luminance-contrast approach (same strategy as SMB).
- Reads in *all* zones because it is brighter than any surface.
- No hue identity; "ghost" reading is purely from the alpha fade.
- Risk: in Zones where the ambient is bright (Zone 2 cold-blue wash),
  the ghost washes slightly.  Requires higher attempt_alpha_max to
  compensate.

**Option C — Pure white:**
`Color(1.0, 1.0, 1.0)`.
Too bright against dark surfaces; creates a "swarm of bright pixels"
artefact when multiple trails overlap.  Avoid.

**Recommendation: Option A.**  The cold blue-purple provides both
luminance and hue contrast, carries palette coherence, and does not
introduce a new unanchored hue into the world.

---

## Opacity parameters

### attempt_alpha_max (current: 0.35)
0.35 is borderline with the correct colour; it was tuned for a
hypothetical visible grey, which it isn't.  Starting target: **0.50**
for the newest attempt.  Tune down on device if it becomes visually
noisy.

Falloff per older attempt (current: ×0.55):
- Attempt 0 (newest): 0.50
- Attempt 1: 0.28
- Attempt 2: 0.15
- Attempt 3: 0.085
- Attempt 4: 0.047

This keeps only the newest 2–3 runs visually meaningful, which aligns
with the SMB pedagogical model (players learn from the last death, not
from deaths 5 runs ago).

The 0.55 falloff factor is fine.  Increasing to 0.60 would make older
trails slightly more visible; decrease to 0.50 to fade them faster.

### visible_window_s (current: 2.0 s)
At 30 samples/s, 2 s = 60 points.  Platforms in the breadth-pass
levels are 2–6 m apart at typical Snappy traversal (~5 m/s horizontal),
meaning the player crosses a platform gap in 0.4–1.2 s.  A 2 s window
shows only the last 1–2 platform gaps.  This may be insufficient for
the player to understand *how* the previous attempt traversed a 3-gap
sequence.

**Recommended starting value: 3.0 s (90 points).**  Tune down to 2.0
on device if the trail looks cluttered.  The dev-menu slider already
covers 1.0–5.0 s; expose default=3.0.

### Sphere radius (current: 0.12 m)
0.12 m is fine for open-world levels (Rooftop, Viaduct, Plaza).  In
enclosed low-ceiling levels (Cavern, Filterbank), the trail spheres may
feel dense.  No code change needed — the current tuning is appropriate
as a starting default.

---

## The point_t bug

The current fade formula:

```gdscript
var point_t := float(p_idx) / float(visible_pts)
```

For a short trail (a fresh attempt with fewer recorded samples than
`visible_pts`), the newest point gets `point_t < 1.0`.  Example: a
5-point trail with visible_pts=60 gives the newest point
`point_t = 4/60 ≈ 0.067`, so `alpha = attempt_alpha * 0.067 ≈ 0.023`.
Essentially invisible.

This defeats the purpose: the most important thing to show after a
respawn is *where the Stray died*, which is the newest point of the
just-archived trail.  But that point is nearly invisible until the
player accumulates 30+ samples (about 1 second of play).

**Fix:**

```gdscript
var range_len := trail.size() - start
var point_t := float(p_idx) / float(maxi(range_len - 1, 1))
```

This normalises over the actual visible range length rather than the
maximum window.  The invariant becomes: oldest visible point → alpha 0,
newest visible point → alpha `attempt_alpha`.  For full-window trails
the behaviour is identical (59/59 ≈ 1.0 vs 59/60 ≈ 0.983 — negligible
delta).

The fix has been applied to `ghost_trail_renderer.gd`.

---

## Mobile rendering cost

The `ghost_trail_renderer.md` research note covers the MultiMesh cost:
1 draw call for all instances.  Alpha-blended objects break TBDR tile
reuse (see `tbdr_mobile_gpu.md`), so the trail is a real GPU cost when
enabled.  Current MAX_DEPTH × visible_pts:
- Default (5 × 60 = 300 instances): acceptable.
- If visible_window_s = 3.0 s: 5 × 90 = 450 instances.

450 alpha-blended instances in 1 draw call is the practical ceiling
before measurable frametime impact on the Nothing Phone.  Keep the
juice toggle OFF by default; measure impact when enabled on device.

---

## Dev-menu depth-pass checklist

On the first depth-pass day, in this order:

1. Change `Color(0.55, 0.55, 0.60, ...)` → `Color(0.40, 0.55, 0.95, ...)`
   in `ghost_trail_renderer.gd`.  (Already done — see fix above.)
2. Enable ghost trails from the dev menu (Juice → Ghost Trails toggle).
3. Play through one level with 3+ deaths.  Verify trails read.
4. Adjust `visible_window_s` (default 2.0 → try 3.0).
5. Adjust `attempt_alpha_max` if too bright (target: visible but not
   distracting during live play).
6. **Do not expose attempt_alpha_max and trail_color as dev-menu sliders
   until the human asks** — those are feel parameters, not tuning
   parameters.  The current point_t fix and colour change are the
   engineering fix; the final colour is a feel verdict.

---

## Implications for Void

1. **Change trail colour to cold blue `Color(0.40, 0.55, 0.95)` before
   first human playtest of ghost trails.**  Grey trails are invisible.
2. **Raise attempt_alpha_max to 0.50** (from 0.35) for the corrected
   colour; tune down on device if noisy.
3. **The point_t bug is fixed** in `ghost_trail_renderer.gd`: short
   trails now show at full brightness from the first visible point.
4. **Default visible_window_s to 3.0 s** in the depth pass; expose the
   existing dev-menu slider for device tuning.
5. Ghost trails are the **single highest-value teach mechanic** for
   precision 3D platforming on mobile.  Prioritise making them visually
   clear before calibrating other juice parameters.
6. **Leave the juice toggle OFF by default** for the device session.
   Measure frametime delta when enabling on device; if < 0.5 ms, enable
   by default; if > 1 ms, keep it toggle-only.
