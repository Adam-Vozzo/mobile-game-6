# Wayfinding Design — Mobile 3D Platformers

*Written iter 112. Cross-cutting reference for any Gate 1 depth pass.*

---

## Why wayfinding matters more on mobile

Desktop 3D platformers lean on peripheral vision, minimaps, and HUD waypoints to
orient players. Void has none of these by design — touch input demands eyes-on-screen
at all times, the landscape viewport is narrower in solid angle than a monitor, and the
brutalist aesthetic forbids floating objective markers.

The failure mode is specific: the player lands on a platform, rotates the camera, still
can't see what to do, and disengages. Unlike a maze game (where confusion is intentional),
a platformer depends on immediate goal-clarity at every respawn. Getting back up after a
death must feel purposeful, not exploratory.

**The golden rule:** at every respawn point, within the first 3 seconds, the player
should either (a) see the goal, or (b) see an unambiguous next platform. If neither is
true, the level has a wayfinding debt that touch-control frustration will amplify.

---

## Kevin Lynch's 5 elements, translated to Void

Kevin Lynch (*The Image of the City*, 1960) identified five elements people use to build
a mental map of an environment. All five apply to platformer level design.

| Lynch element | Void equivalent | Example |
|---|---|---|
| **Path** | The par route — the sequence of jumps the skilled player takes | Spire's zigzag climb |
| **Edge** | Void boundary — the drop-off that defines the play surface | Viaduct spans over the void |
| **District** | Zone — areas with distinct atmosphere/lighting | Threshold's three zones |
| **Node** | Checkpoint / hub — a recognised decision or rest point | Plaza's hub floor |
| **Landmark** | A singular element visible from multiple positions | Spire's summit biolume, Arena's CentralAltar |

**The landmark is the highest-leverage element.** It orients the player after each respawn
without any UI. Every Gate 1 level needs at least one landmark visible from the spawn
and from each checkpoint. In most Void levels, the **win state is the natural landmark** —
make it glow.

---

## Goal-visibility audit — all 9 shapes

Can the player see the win state from spawn (or from the last checkpoint before the final
section)? Current state of each level's WinState visibility:

| Level | Goal visible? | Current beacon | Assessment |
|---|---|---|---|
| Threshold (corridor) | ❌ No (three zones) | None — zones obscure goal | Fine — forward direction is clear; per-zone telegraphing via zone atmosphere |
| Spire (tower) | ✅ Yes — look up | `SummitLight` OmniLight3D (teal, energy 2.5, range 9) at y=18 | Strong. Light visible up the shaft. |
| Rooftop (open air) | ⚠️ Partial | `RelayPad` WinState in open void — no dedicated beacon | Goal is visible if camera angle is right; lacks a beacon to catch peripheral attention |
| Plaza (hub) | ✅ Yes — central pillar top | `PillarSummit` height contrast visible from hub floor | Strong. The pillar IS the landmark. Double-jump required keeps goal legible (players see they need height). |
| Cavern (maze) | ❌ No (design intent) | FinalChamber biolume cyan light, but only visible from NorthLedge | Weakest legibility — by design, but must not tip into frustration. FinalChamber beacon needs range boost. |
| Descent (shaft) | ✅ Yes — look down | BasePad biolume cyan at bottom of shaft | Excellent. Depth-first read. Don't obscure with fog. |
| Filterbank (gauntlet) | ⚠️ Partial | Terminal WinState at z=72; no dedicated beacon | Sequential chambers force forward — direction is never ambiguous, but goal distance is unknown |
| Viaduct (bridge) | ✅ Yes — look forward | `ArrivalAbutment` visible at far end of spans | Strong. Bridge-as-path makes the destination self-evident. |
| Arena (ring) | ✅ Yes — look inward | `CentralAltar` is always visible from the ring | Excellent. The ring orientation means the goal is always centre-frame. |

**Natural legibility ranking (most → least):**
Spire, Plaza, Arena, Viaduct → Descent → Threshold, Filterbank → Rooftop → Cavern

---

## Cross-cutting gap: WinState has no emissive beacon on most levels

`win_state.gd` is a pure collision trigger — no visual component. The depth pass must
add a biolume beacon to each WinState on the chosen level (and, eventually, all levels).

**Recommended beacon spec:**
```
OmniLight3D as child of WinState Area3D
  light_color = Color(0.12, 0.90, 0.95)   # biolume cyan (matching DataShard glow)
  light_energy = 2.0
  omni_range = 14.0                        # visible through 0.045 fog at ~20 m
  shadow_enabled = false
```

Range 14 m balances visibility with the draw-call cost (shadow OFF is mandatory on
Mobile renderer). Adjust down to 10 m in Cavern where the design intent is partial
obscurity (don't beacon from behind walls — the biolume should leak through the
NorthLedge gap, not broadcast to the entire cavern).

**Levels that need this beacon added in the depth pass:**
- Threshold (WinState at Beat4/Terminal)
- Rooftop (RelayPad)
- Cavern (FinalChamber — range 10 m, not 14 m)
- Descent (BasePad — light energy 1.6, range 12 m — it is already partially visible)
- Filterbank (Terminal)
- Viaduct (ArrivalAbutment)

Spire's `SummitLight` is already working and covers this. Plaza and Arena's architecture
serves as the beacon — no additional light needed.

---

## Mobile-specific wayfinding rules for Void

### 1. Fog density ceiling for goal visibility

Current densities: Cavern 0.090, Filterbank 0.080, Descent 0.065, Threshold varies
0.030–0.045, others lower. The 14 m OmniLight beacon reads clearly through densities
up to ~0.065. At 0.080–0.090 it is visible only within 8–10 m.

**Rule**: if the goal is more than 12 m from the last checkpoint, fog density should be
≤ 0.065. Cavern and Filterbank may need a small density reduction during the depth pass
if the beacon test fails on device.

### 2. "The desire line is the par route"

(Per `alexander_pattern_language.md`.) The most visually obvious path from each platform
should BE the par route. On the depth pass, walk the par route and check whether each
step looks like the natural next move. If a player would naturally try to go elsewhere
first, the par route needs a geometry or lighting nudge — not an arrow, just a slightly
brighter/closer platform.

### 3. No floating objective markers — ever

The brutalist constraint. No HUD waypoints, no floating question marks, no glowing
outlines. Legibility must emerge from architecture, scale, and light. If a section
needs a marker, the geometry is wrong.

### 4. Checkpoint-to-goal legibility chain

Each checkpoint should give the player a clear view of the next obstacle (not necessarily
the goal). After respawning at a checkpoint, the player should see (within 3 seconds)
what the immediate challenge is. If the view from a checkpoint is blocked, add a
`CameraHint` node that nudges the camera toward the next landmark.

### 5. Descending vs ascending legibility asymmetry

Looking up (Spire) gives less spatial context than looking forward (Viaduct) or down
(Descent). In ascending levels, height landmarks (biolume at summit, scale contrast
of tall goal structure) substitute for forward visibility. Ensure ascending levels have
a visible high-altitude anchor — do not let the summit disappear into fog.

---

## Implications for Void

1. **Best legibility for first human device playtest**: Spire, Plaza, Arena. These are
   self-navigating — minimum depth-pass work to achieve a clean "go here" read.

2. **Viaduct and Descent are self-explanatory by shape**: the direction IS the route.
   Very low depth-pass wayfinding cost.

3. **Cavern needs a navigation pass before evaluation**: the FinalChamber OmniLight
   (currently existing) needs its range checked on device. If the biolume does not leak
   through the NorthLedge gap, add a second low-energy light (energy 0.6) just inside
   the EastPass entrance to simulate the leak. Otherwise the player has no beacon when
   they reach the junction.

4. **WinState OmniLight beacon is a cross-cutting depth-pass task**: add to every
   WinState on the chosen level in the first depth pass iteration. ~15 lines per level
   (a single OmniLight3D child added in `win_state.gd::_ready()`). Worth making a
   configurable `@export` on the WinState script rather than adding lights to each
   `.tscn` separately.

5. **Threshold's reliance on sequential zone reveals**: without goal visibility from
   spawn, Threshold's wayfinding strategy is "fog gate → new zone reveals direction."
   This works architecturally but is the most demanding to execute cleanly on device —
   each zone transition must feel like a discovery, not a dead end. The Threshold
   redesign already structures this with the lintel-hiding-Z2 detail. Correct approach;
   needs device verification.

6. **Don't treat wayfinding debt with difficulty debt**: a level that is hard to navigate
   is not more challenging — it is more frustrating. The difficulty should come from
   hazard timing and jump precision, not from "which way do I go." These are independent
   axes; don't trade one for the other.

---

## Sources

- Kevin Lynch, *The Image of the City* (1960) — 5-element wayfinding vocabulary
- `level_design_references.md` — landmark requirement, desire-line = par route
- `alexander_pattern_language.md` — desire line as par route
- `brutalism_blame.md` — BLAME!'s deliberate navigation opacity as artistic choice
- `depth_perception_cues.md` — fog density as a readability tool (not to be reduced)
- `android_input_latency.md` — touch latency forces 3-second orientation rule
- `gate1_depth_pass_plan.md` — depth pass checklist (WinState beacon not yet listed)
