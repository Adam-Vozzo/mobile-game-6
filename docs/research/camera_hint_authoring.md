# CameraHint Authoring Guide — Project Void

Written iter 125 (2026-05-17). Authored after observing the CameraHint system is fully
implemented in `camera_rig.gd` but has no placement guidance. This note serves as the
authoring companion to `camera_per_shape.md` (which covers rig-level tuning) — it covers
where to put CameraHint nodes and why.

---

## How the system works

`CameraHint` (extends `Area3D`) sits in the scene tree. When the player's capsule overlaps
its collision volume, `is_player_inside()` returns true. Every frame, `camera_rig.gd::
_update_hint_distance` queries all nodes in the `camera_hints` group, finds the **maximum**
`pull_back_amount` among active hints, and exponentially blends `_hint_distance_extra` toward
that value at **3 /sec** (95 % reached in ~1 second):

```gdscript
_hint_distance_extra = lerpf(_hint_distance_extra, _get_active_hint_extra(),
                             1.0 - exp(-3.0 * delta))
return distance + _hint_distance_extra
```

The blend runs every frame including while airborne, so the camera is already partly extended
when the player lands inside a hint. Only one "winning" value (the max) is active at a time —
overlapping hints don't stack additively, they compete.

---

## Known gap: blend_time is not wired

`CameraHint` exports `blend_time` (default 0.5 s, range 0.1–2.0 s), but `camera_rig.gd`
ignores it — the blend rate is always 3 /sec regardless. The current test in
`_test_hint_distance_blend()` documents this as `const RATE := 3.0` (hardcoded).

**Depth-pass decision**: either

A. Wire `blend_time` into the blend rate. The correct formula for "95 % blend reached
   in `blend_time` seconds" is `rate = -log(0.05) / blend_time ≈ 3.0 / blend_time`.
   With the default 0.5 s that gives rate = 6 /sec (snappier), with 2.0 s it gives 1.5 /sec
   (very gradual). This makes `blend_time` meaningful per-hint.

B. Remove `blend_time` from the export and document 3 /sec as the project-wide standard.
   3 /sec is already slow enough to read as deliberate (≠ a cut) and fast enough to complete
   within the approach zone before the player needs the extra frame. Removing the export
   reduces configuration surface.

**Recommendation for Gate 1**: Option B — remove `blend_time`. 3 /sec is the right speed
for all nine current shape families; per-hint rate control is Gate 2+ complexity. Removing
the export also fixes the silent discrepancy between the hint's self-description and the
rig's actual behaviour.

---

## Stale docstring in camera_hint.gd

The class comment still reads: "Stub for Gate 1: the camera rig will query active hints via
`get_tree().get_nodes_in_group("camera_hints")` once the framing pass lands." The framing
pass has landed. Fix this docstring in the same pass that wires or removes `blend_time`.

---

## Placement principles

### When to use a hint

Use a hint when the **default camera pose gives the player insufficient information** for the
next decision. This happens at:

- **Vista reveals** — the player crests a height and the world opens out. Pull back so the
  goal and the path ahead are both visible. (Archetype: Spire summit, Rooftop final ledge.)
- **Complex gap setups** — the approach to a multi-step jump where seeing the whole sequence
  matters. Pull back to fit all three platforms in frame. (Archetype: Viaduct PierHead1
  before the moving platform span.)
- **Directional ambiguity** — a junction where the player can go three ways. Pull back to
  show all options simultaneously. (Archetype: Cavern JunctionRoom.)
- **Press/hazard reveals** — entering a chamber where a moving hazard is the main mechanic.
  Pull back to show the full stroke before the first crossing. (Archetype: Filterbank beat
  chamber entrances.)

Do not use a hint in:
- **Cramped shafts** (Spire lower half) — extra distance conflicts with occlusion avoidance,
  which will snap the camera closer anyway. The hint wastes space.
- **Already-open zones** (Rooftop lower levels) — the default pose is fine; pulling further
  back pushes the player character to a small dot.
- **Fast-reflex sequences** — the 1-second blend-in means the hint fires late. A player
  sprinting through a gauntlet won't notice a pull-back that completes after the beat.

### Sizing the collision volume

The hint volume should be the **approach zone**, not the arrival point. Place the Area3D so
the leading edge of the volume is 2–4 m before the player sees the vista — the blend reaches
~63 % at 0.33 s, enough to meaningfully open the view by the moment of arrival.

Volume depth (along the approach axis) should be ≥ 3 m so that the player is inside for
at least 3 frames at walking speed (3 m / 3.5 m/s ≈ 0.86 s — enough time for 95 % blend).

### Sizing pull_back_amount

| Level geometry | Recommended pull_back_amount |
|---|---|
| Narrow shaft / corridor (< 8 m wide) | 0.5–1.5 m |
| Mid-width floor (8–16 m) | 1.5–2.5 m |
| Open arena / rooftop | 2.5–4.0 m |
| Full-world vista (Viaduct, Threshold Zone 3) | 3.0–5.0 m |

Anything above 5 m risks exposing the geometry ceiling limit or making the Stray character
too small to read at the target depth of field.

---

## Per-shape placement recommendations (first depth pass)

These are starting suggestions, not requirements. All values subject to device-feel tuning.

### Threshold (corridor)
- **Zone 1 lintel** (before entering Zone 2): 3 m × 6 m × 3 m box, pull_back 2.0 m.
  Reveals the maintenance yard as the player ducks under the lintel. Pairs with the
  fog density shift from Zone 1 → Zone 2.
- **Zone 3 top gantry** (G2 descent start): 4 m × 4 m × 3 m box, pull_back 3.0 m.
  Reveals the industrial drop and the Beat4 platforms below.

### Spire (vertical tower)
- **Summit approach** (PlatformG → summit, y = 14–17): 5 m × 4 m × 10 m box (tall, covers
  the final three platforms), pull_back 1.5 m. The shaft is narrow so keep this conservative.
  Reveals the win state above and the drop below simultaneously.

### Rooftop (open-air)
- **EastPost approach** (before StepG → RelayPad): 8 m × 4 m × 4 m box, pull_back 2.5 m.
  The final jump is exposed (no walls) and the RelayPad is easy to miss — the pull-back gives
  spatial context.

### Plaza (hub)
- **PillarSummit approach** (above PillarStep2): 6 m × 4 m × 6 m box, pull_back 2.5 m.
  Reveals the three spoke arms and the full hub floor from height. Reinforces the hub-as-
  world-anchor read at the moment of victory.

### Cavern (maze)
- **JunctionRoom** (at the T-intersection): 14 m × 3 m × 14 m box, pull_back 2.0 m.
  The junction is where orientation is hardest. Pull back to show all three exits: NorthLedge
  (critical path), WestPass (shards), EastPass (mirrored). Pairs with checkpoint here.

### Descent (inverted)
- **LedgeC approach** (before BasePad drop): 6 m × 3 m × 4 m box, pull_back 2.0 m.
  Shows the BasePad below and the full drop context before the player commits.

### Filterbank (gauntlet)
- **Beat2 chamber entrance** (before Press1): 8 m × 3 m × 4 m box, pull_back 2.0 m.
  Reveals the full press stroke range so the player can time the window before first contact.
- **Beat4 combined chamber**: 8 m × 3 m × 4 m box, pull_back 2.5 m.
  The combined press + sentry beat requires seeing both simultaneously.

### Viaduct (bridge crossing)
- **PierHead1** (before the moving platform gap): 6 m × 3 m × 6 m box, pull_back 3.5 m.
  The 14 m moving platform gap is the level's centrepiece — pull back to show the full span
  and the platform's travel range in one frame. Strongest vista in the set.

### Arena (ringed)
- **SouthRim summit approach**: 8 m × 4 m × 8 m box, pull_back 3.0 m. Reveals the full ring
  from height as the player crests the final climb.

---

## Dev-menu tuning workflow

The dev menu has no direct CameraHint controls (pull_back_amount is a scene-authored export).
Tuning workflow:

1. **Proxy via dev menu Camera → Distance slider**: temporarily raise the global `distance`
   to `distance + target_pull_back_amount` and walk the approach. If it feels right, encode
   that difference as `pull_back_amount` in the hint.
2. **Place, play, observe blend**: the 3/sec blend is visible in real-time. If the pull-in
   feels too slow for the approach, either widen the approach volume (player is inside longer)
   or increase pull_back_amount to overshoot slightly and let it settle.
3. **Check occlusion**: in tight geometry, the occlusion avoidance will cancel the hint's
   extra distance if the wall is closer than the extended arm. Use the Camera → Occlusion
   debug toggles to visualise.

---

## Implications for Void (concrete action items)

1. **Fix the stale "Stub for Gate 1" docstring** in `camera_hint.gd` — it ships with the
   code and is actively misleading.
2. **Decide on `blend_time`**: recommended Option B (remove the export, 3 /sec is project
   standard). A one-line change in `camera_hint.gd`. Log the decision in `DECISIONS.md`.
3. **First hint placement**: add one hint to the chosen depth-pass level's most legibility-
   critical moment (see per-shape table above). Gate 1 target: 1–2 hints per level.
4. **Camera per-shape compatibility**: all nine shapes' camera risk classifications in
   `camera_per_shape.md` assumed default arm lengths — the hint system adds on top. In
   high-risk shapes (Cavern, Descent), confirm the hint's extra distance doesn't exceed the
   occlusion probe range.
5. **No dev-menu runtime tuning** is possible today without a custom devtool. Low priority —
   the proxy workflow above is adequate for Gate 1.
