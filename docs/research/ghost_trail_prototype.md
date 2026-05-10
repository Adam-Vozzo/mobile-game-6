# Ghost Trail Prototype — attempt-replay overlay

**Status:** Sketch only. Gate 1 P0 — do not implement until vertical slice level exists.  
**Sources:** Super Meat Boy (Team Meat, 2010), SMB Forever (2020), GDC post-mortems on
replay systems, Godot 4 MultiMesh docs.

---

## What SMB's ghost trail actually does

- Every player attempt records a **position sample every frame** (60 Hz).
- On respawn, the dead attempt's recording is frozen and replayed as a translucent ghost
  simultaneously with the next live attempt.
- Up to **five past attempts** are visible at once; the sixth displaces the oldest.
- Ghost alpha scales by recency: newest dead ghost ≈ 0.35 alpha, oldest ≈ 0.05.
- All ghosts share the same colour (a flat, slightly desaturated version of the character
  sprite) but can be tinted by attempt index for readability.
- The trail is **the entire path**, not just the current position — you see the full arc of
  each failed run, which shows exactly where momentum was lost or a jump was mis-timed.
- Critically: ghosts convey *why* the level is hard. Dense ghost clusters mark the "death
  wall." A player instinctively reads them before trying the section again.

## Godot 4 implementation options

### Option A — MultiMeshInstance3D (recommended for Gate 1)

Store positions, render all ghost points as one multi-mesh batch.

```
Recording:
  Array[PackedVector3Array]  trail_history   # one entry per attempt, capped at 5
  PackedVector3Array         current_trail   # grows each physics frame
  float                      _sample_accum   # accumulates delta
  const SAMPLE_INTERVAL = 1.0 / 30.0        # 30 samples/s (every 2 physics frames at 60 Hz)

On respawn:
  trail_history.push_front(current_trail.duplicate())
  if trail_history.size() > 5:
      trail_history.pop_back()
  current_trail.clear()

Rendering (GhostTrailRenderer node):
  MultiMeshInstance3D with a squashed sphere mesh (r=0.15, h=0.3)
  instance_count = 5 * VISIBLE_TRAIL_LENGTH   # e.g. 5 * 60 = 300
  Each frame: iterate trail_history, set instance transforms + colors
```

**Alpha calculation:**
```gdscript
var attempt_alpha := 0.35 * pow(0.55, attempt_idx)   # 0.35, 0.19, 0.11, 0.06, 0.03
var point_alpha   := 1.0 - float(point_idx) / VISIBLE_TRAIL_LENGTH
instance_color = Color(0.55, 0.55, 0.60, attempt_alpha * point_alpha)
```

**Performance:**
- 5 attempts × 60 visible trail points = 300 MultiMesh instances = **1 draw call**.
- Well within the ≤50 draw call budget (this is 1 additional call).
- Zero CPU cost when no attempts have been recorded yet.
- Memory: 5 attempts × 90 s × 30 samples = 13,500 Vector3 positions ≈ 160 KB. Negligible.

### Option B — Line3D / ImmediateMesh polyline per attempt

Build a tube mesh from the trail positions using SurfaceTool each frame. Supports
per-vertex alpha fading but requires `SurfaceTool.commit()` every frame per ghost — that's
5 mesh rebuilds/frame. Acceptable for PC, questionable on mobile TBDR at 60 fps.

**Verdict:** Use for prototyping; switch to MultiMesh if frametime spikes.

### Option C — GPU ring buffer texture (advanced, not for Gate 1)

Write 2D position history to a `ImageTexture` updated via `Image.set_pixel`; a vertex
shader samples the texture to position billboard quads. Zero CPU mesh work per frame once
the texture is filled. Complexity is high; save for Gate 2+ if the MultiMesh approach shows
CPU cost on low-end devices.

### Option D — Real physics replay (discard)

Instantiate invisible Player nodes and feed them recorded inputs. Determinism is not
guaranteed with Jolt on different hardware. Hugely expensive. Do not use.

---

## Concrete sketch for Gate 1

### Recording — add to `game.gd`

```gdscript
const SAMPLE_INTERVAL := 1.0 / 30.0
const MAX_TRAIL_DEPTH := 5
const MAX_TRAIL_LEN   := 2700   # 90 s × 30 samples — safety cap

var trail_history: Array[PackedVector3Array] = []
var _current_trail := PackedVector3Array()
var _sample_accum: float = 0.0

func _physics_process(delta: float) -> void:
    if not _recording:
        return
    _sample_accum += delta
    if _sample_accum >= SAMPLE_INTERVAL:
        _sample_accum -= SAMPLE_INTERVAL
        var player := get_tree().get_first_node_in_group(&"player")
        if player:
            _current_trail.append(player.global_position)
            if _current_trail.size() > MAX_TRAIL_LEN:
                _current_trail.remove_at(0)

func on_player_respawned() -> void:
    trail_history.push_front(_current_trail.duplicate())
    if trail_history.size() > MAX_TRAIL_DEPTH:
        trail_history.pop_back()
    _current_trail.clear()
```

### Renderer node (new: `scripts/levels/ghost_trail_renderer.gd`)

```gdscript
extends Node3D
const VISIBLE_POINTS := 60   # 2 s of trail at 30 samples/s

@onready var _mmesh: MultiMeshInstance3D = $MultiMeshInstance3D

func _ready() -> void:
    _mmesh.multimesh.instance_count = 5 * VISIBLE_POINTS
    _mmesh.multimesh.use_colors = true

func _process(_delta: float) -> void:
    var inst := 0
    for a_idx in Game.trail_history.size():
        var trail: PackedVector3Array = Game.trail_history[a_idx]
        var start := maxi(0, trail.size() - VISIBLE_POINTS)
        var attempt_alpha := 0.35 * pow(0.55, a_idx)
        for p_idx in (trail.size() - start):
            var fade := 1.0 - float(p_idx) / VISIBLE_POINTS
            var col := Color(0.55, 0.55, 0.60, attempt_alpha * fade)
            var xf := Transform3D(Basis(), trail[start + p_idx])
            _mmesh.multimesh.set_instance_transform(inst, xf)
            _mmesh.multimesh.set_instance_color(inst, col)
            inst += 1
    # blank out unused instances
    while inst < _mmesh.multimesh.instance_count:
        _mmesh.multimesh.set_instance_color(inst, Color(0, 0, 0, 0))
        inst += 1
```

### Dev menu integration

Add a "Ghost trails" checkbox to the Juice section (key `&"ghost_trails"`).
`GhostTrailRenderer._process` skips update when `DevMenu.is_juice_on(&"ghost_trails")` is false.
Default OFF until the first level exists.

---

## Open questions before implementing

- **Colour palette**: cold blue-grey (0.55, 0.55, 0.60) matches the brutalist world tone.
  Could tint each attempt index slightly differently (cyan → grey → charcoal) so the five
  overlapping trails are visually separable. Decide after first level is playable.
- **Temporal window**: 60 points (2 s) feels right for a platformer beat. SMB uses the full
  run. For Void's longer sequences, the full run may produce too much visual noise; a 3–4 s
  window is likely the sweet spot. Tune in the dev menu.
- **Respawn-point anchoring**: ghosts should only be shown near the current checkpoint, not
  for the entire level if the level is long. Gate on distance from player (e.g., hide ghost
  points > 30 m away) to reduce clutter and save MultiMesh instance slots.

---

## Implications for Project Void

1. **Gate 1 task**: add `trail_history` recording to `game.gd` and `GhostTrailRenderer` to
   the vertical slice level. MultiMesh approach keeps this at 1 draw call.
2. **Dev menu**: add `ghost_trails` juice toggle before shipping; default OFF.
3. **`game.gd` signal hook**: `Game.player_respawned` is already emitted on respawn —
   connect `on_player_respawned` there. No new signal needed.
4. **Performance**: the 300-instance MultiMesh costs essentially nothing on Mali/Adreno GPUs.
   The position-copy loop on CPU is O(300) — negligible.
5. **Reboot duration interaction**: ghost trails start recording immediately after
   `_is_rebooting = false`. The reboot animation duration (0.35–0.5 s) creates a short gap
   in the trail; acceptable, since that gap is during teleport/power-on where position is
   the spawn point anyway.
6. **Colour restraint**: ghost blue-grey is deliberately desaturated so the Stray's red
   remains the only warm focal point in the world. Don't add per-attempt bright tints.
