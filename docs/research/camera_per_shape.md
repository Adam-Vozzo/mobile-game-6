# Camera Tuning Per Shape-Family

*Written iter 109 — 2026-05-16. For use immediately after the human picks a shape-family
survivor. Open the picked level in Godot, consult this note alongside the dev menu
Camera section, and dial in the parameters before any other depth-pass work.*

---

## Why camera tuning is shape-dependent

The camera rig uses a SpringArm3D + ShapeCast3D occlusion avoidance system with a
vertical-follow ratchet (holds Y within the normal jump band, tracks Y above it). Every
parameter has a correct default for flat open spaces, but each level shape applies
different pressure:

- **Enclosed geometry**: ceiling and wall colliders force the occlusion system to
  pull the camera inward. If the default distance (6 m) puts the camera inside a wall,
  the ShapeCast snaps to `occlusion_min_distance` (0.8 m), which feels broken.
- **Vertical traversal**: the ratchet's behaviour at large Y deltas (> `reference_floor_snap_threshold`
  = 8 m) becomes visible — it snaps rather than eases, which reads as a camera glitch.
- **Directional movement**: the camera has no lookahead arm, so the player must lead with
  movement input to keep the camera facing where they are going. In shapes with abrupt
  direction changes (ring, hub) this matters more than in straight shapes (corridor, gauntlet).

---

## Dev-menu parameter reference

| Slider | Effect | Risk direction |
|--------|--------|----------------|
| Distance | Spring arm length | Too long → clips enclosures; too short → cramped |
| Pitch (deg) | Base elevation of camera | Too high → clips low ceilings |
| Fall pull | Extra Y drop when player falls | Too low → camera lags on descent levels |
| Aim height | Target aim offset (above feet) | Higher → camera leads verticality |
| Apex multiplier | Ratchet band height (× jump apex) | >1 = lazier; <1 = tracks every hop |
| Floor smoothing | Speed of tier-change easing (s⁻¹) | Low → camera lags at new platform tier |
| Floor snap thresh | Y delta (m) that forces instant snap | Too low → snap on every jump |
| Probe radius | ShapeCast sphere radius for occlusion | 0 = flicker at edges |
| Pull-in rate | Speed of occlusion inward snap | Low → player hidden behind wall |
| Ease-out rate | Speed of occlusion recovery | High → camera bounces at corners |
| Latch delay | Seconds to hold occlusion pose | Low → flicker at wall edges |

---

## Per-shape tuning guide

### 1. Threshold — linear corridor ⚠️ medium risk

Z-follow is the base case. Zone 2 has a ceiling; Zone 3 descends through gantries.
Zone 2 ceiling test: pitch × distance vertically ≈ 6 × sin(22°) + 0.6 ≈ 2.85 m above
player. If Zone 2 ceiling is at ~4 m, clearance is 1.15 m — tight but normally fine.
If it clips: lower `distance` to 5.0 or `pitch_degrees` to 15.

Z3 gantry descent: `reference_floor_snap_threshold = 8` handles the first large drop;
subsequent short drops (< 8 m) ease in. If the camera lags, raise `reference_floor_smoothing`
from 6 to 10–12.

### 2. Spire — vertical climbing tower ⚠️ medium risk

Player ascends 17 m through a 10×8 m shaft. Camera is behind-in-Z, not in-the-shaft.
Shaft walls are at X = ±5 m; with `distance = 6`, camera Z offset ≈ −5.6 m — this
clears the shaft's Z extent only if the shaft is deeper than 5.6 m in Z. Check by
running free-cam in the shaft with debug viz on.

Ratchet ascent: the camera ratchets upward correctly as each new platform becomes the
reference floor. Raise `apex_height_multiplier` to 1.5 so the camera doesn't try to
track every normal jump during the ascent (reduces vertical noise). Lower it back for
the descent if testing Descent shape.

If occlusion is choppy inside the shaft, increase `occlusion_release_delay` to 0.30–0.35
so the camera doesn't bounce between occluded and clear every time the shaft edge passes
the probe.

### 3. Rooftop — open-air void ✅ low risk

No ceiling, no enclosing walls. Occlusion system rarely fires. Main challenge: player
can step off any edge. The camera does NOT warn the player about the void edge ahead —
there's no lookahead. This is intentional (void as constant context) but may read as
unfair on first attempt.

If depth perception is poor: raise `pitch_degrees` to 28–32 (shows more of the
platform surface and its edge) and slightly lower `distance` to 5.0. See
`depth_perception_cues.md` — blob shadow is the highest-ROI cue here.

### 4. Plaza — hub with radiating spokes ⚠️ medium risk

Player faces multiple directions from the central hub. Camera auto-recenters behind
the player (yaw tracks movement direction). The recentering is driven by player input
direction, so abrupt pivots (hub to spoke entry) will lag by ~1–2 frames.

If the camera lag feels wrong on spoke entry: increase `yaw_drag_sens` slightly so
manual overrides feel more responsive for the on-device test. No code fix needed —
this is a feel question.

### 5. Cavern — maze with branches ⛔ highest risk

Ceilings at ~4 m, walls at ~2 m on each side of passage. At default distance (6 m),
the camera will clip into every ceiling within two steps. **Reduce `distance` to 3.5–4.0**
and `pitch_degrees` to 15 before running in the cavern.

Camera geometry check: at distance 4, pitch 15°:
- Y above player = 4 × sin(15°) + 0.6 ≈ 1.64 m — well below 4 m ceiling. ✓
- Z behind player = 4 × cos(15°) ≈ 3.86 m — fits in a 4 m passage. ✓

Keep `pull_in_smoothing` high (30–40) so the camera snaps inward quickly when it hits
a wall rather than slowly crawling through geometry.

Orientation challenge: the player CANNOT see the full route from spawn. The camera must
stay close and low so the player reads passages ahead. Resist raising distance.

### 6. Descent — inverted descent ⚠️ medium risk

Player falls through 7 platforms over ~17 m drop. The ratchet holds Y at each tier
and eases down when the player lands lower. `vertical_pull = 0.18` adds a small
dynamic pull during freefall — raise this to 0.28–0.35 so the camera more aggressively
follows the player into the fall and shows the landing surface earlier.

Large drops (> 8 m floor-to-floor): snap happens (`reference_floor_snap_threshold`).
This is correct for very long falls (respawn feel). For the 4–6 m drops between Descent
platforms, the smoothed path applies. Tune `reference_floor_smoothing` upward to 10–14
so the camera arrives at each new tier fast (player is already there).

### 7. Filterbank — enclosed obstacle gauntlet ⚠️ medium risk

Z-axis corridor with press and sentry hazards. Similar geometry to Threshold Zone 2.
The IndustrialPress crushes downward from above — the camera must show the press
overhead and its stroke target simultaneously. From the default rear position, if the
press is directly ahead at Z+, it will be in frame.

If the press is hard to read: raise `pitch_degrees` to 28 (camera sees more vertical
extent) and verify `aim_height` puts the camera target high enough to show the press
body in frame when the player is at its base.

### 8. Viaduct — exposed bridge crossing ⚠️ medium risk

Spans are 1.5–2 m wide; void on both sides. Camera from 6 m behind on a 2 m span:
the player fills most of the frame and the span edges are barely visible. This is
intentional — the tension comes from the player not seeing the fall until they look.

Raise `pitch_degrees` to 26–28 to see more of the span surface. Keep `distance` at
default (6 m) — shorter distance makes the narrow spans feel claustrophobic.

On the final sentry span: the sentry will regularly pass in front of the camera's
view. This is expected behaviour, not a camera bug.

### 9. Arena — ringed platform ⚠️ medium risk

Player circles a 3/4 ring; the CentralAltar is always 6 m across the void. Camera
follows the circular path. The yaw naturally tracks movement direction — circling the
ring keeps the camera facing along the ring, which means the CentralAltar is seen from
an angle, not dead-on.

To show the altar from more approach angles: raise `aim_height` to 0.9 m so the camera
sits higher and the void with the altar across it is in frame throughout the ring walk.

The NWCorner→CentralAltar vault is a 3.5 + 4 m two-jump sequence over open void. The
blob shadow is critical here — depth perception on the CentralAltar is the hardest jump
in the level. See `depth_perception_cues.md`.

---

## Cross-cutting notes

**Occlusion layer setup**: camera occlusion only queries collision layer 7
(`CameraOccluder`). Assign large architectural walls and floors to layer 7 in each
level's `.tscn`. Small platforms should NOT be on layer 7 — the camera would pull in
every time the player walks near one. Current Threshold already uses this correctly.

**SpringArm child camera position**: if you ever re-parent Camera3D, reset its
local transform to (0, 0, 0) afterward. A stale local offset causes the spring length
to appear wrong (community finding; also in Godot docs for SpringArm3D).

**Godot 4.5 camera fix**: Godot 4.5 includes a fix for smoothed camera positioning when
limits are in place, but SpringArm3D fundamentals are unchanged. No engine-upgrade
action required.

---

## Implications for Project Void

1. **Cavern is the hardest camera shape** — do a dedicated camera-only pass before any
   other depth-pass work if Cavern is picked. Start with `distance = 4.0`, `pitch = 15`.
2. **Descent needs higher `vertical_pull`** (0.28–0.35) and higher `reference_floor_smoothing`
   (10–14) to show landing surfaces during freefall.
3. **Spire benefits from `apex_height_multiplier = 1.5`** to suppress per-hop camera
   noise during the full ascent.
4. **Rooftop, Filterbank, Viaduct, and Arena** can start with default camera values —
   the risks are mild and device-feel is the arbiter.
5. **Every shape benefits from blob shadow** tuning before par-time calibration.
   Blob shadow is the single highest-ROI depth cue (one ray, one draw call).
   See `depth_perception_cues.md`.
6. Add the picked level's key geometry to **CameraOccluder layer 7** on the first
   depth-pass day — do not leave all geometry on layer 1.
