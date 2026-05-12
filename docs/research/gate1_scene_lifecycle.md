# Gate 1 Scene Lifecycle — Godot 4 Implementation Notes

Prepared 2026-05-12. Covers: level loading/reloading, run-timer pattern,
win-state trigger, and `Game` autoload integration for Gate 1.

---

## Problem statement

Gate 1 requires:
1. A level that can be **instantly restarted** (SMB grammar: death → respawn ≤ 0.35 s,
   retry button ≤ 1 s to in-game).
2. A **run timer** that starts when the level loads and stops when the win trigger fires.
3. A **win-state results panel** (time, par delta, shard count) that overlays the paused
   level briefly, then either returns to play or reloads.
4. All of this must not hitch on a mid-range Android phone.

---

## 1. Level reload options in Godot 4

### Option A — `get_tree().reload_current_scene()`

```gdscript
# In Game autoload or a LevelManager node:
func reset_run() -> void:
    attempts += 1
    run_time_seconds = 0.0
    get_tree().reload_current_scene()
```

**Pros:** one call, built-in, resets all node state automatically.  
**Cons:** on mobile, a full scene reload can take 30–80 ms depending on scene
complexity (asset re-import stays cached; physics init is the bottleneck). For a
Gate 1 level with ~10–20 static platforms and 1 player that's acceptable, but
profiling is required.  
**Verdict:** use this for Gate 1. Profile on device at Gate 2 if reload hitch is
noticeable.

### Option B — Manual node reset (soft reset)

Keep the level scene in memory. On death, call a `reset()` method on the root level
node that re-positions the player, resets moving platforms, clears any spawned
particles/effects, and re-arms hazards.

**Pros:** sub-frame reset — no scene tree manipulation, no GC pressure, ideal for
SMB-speed respawn.  
**Cons:** every new level element (hazard, moving platform, collectible) needs a
`reset()` implementation; easy to forget one and get stale state.  
**Verdict:** use this for the *player respawn within a run*. Combine with Option A
for the "restart from beginning" button on the results screen.

### Option C — Preload + swap

```gdscript
var _level_scene := preload("res://scenes/levels/level_01.tscn")
func load_level() -> void:
    if _current_level:
        _current_level.queue_free()
    _current_level = _level_scene.instantiate()
    add_child(_current_level)
```

**Pros:** first load is paid up front; subsequent swaps avoid parse time.  
**Cons:** `queue_free` + `instantiate` is similar cost to `reload_current_scene`;
doesn't eliminate the hitch.  
**Verdict:** most useful for level-select (Gate 2) where you know the next level
in advance and can background-load it.

---

## 2. Run timer pattern

Timer lives in the `Game` autoload, not in the level scene. This survives level
transitions and results-panel overlays without needing a persistent timer node.

```gdscript
# game.gd additions for Gate 1
var run_time_seconds: float = 0.0
var is_running: bool = false
var shards_collected: int = 0
var shards_total: int = 0

func start_run() -> void:
    run_time_seconds = 0.0
    shards_collected = 0
    is_running = true

func _process(delta: float) -> void:
    if is_running:
        run_time_seconds += delta

func level_complete() -> void:
    is_running = false
    emit_signal("level_completed")
```

Key points:
- `start_run()` is called by the level's `_ready()`.
- `level_complete()` is called by the `WinState` Area3D trigger.
- `is_running = false` pauses the timer during the results panel; `reset_run()` 
  resets it and calls `get_tree().reload_current_scene()`.
- `attempts` is incremented in `reset_run()` so the results panel can show it if 
  desired (per `win_state_design.md`: don't show death count by default, but track
  it for post-session stats).

---

## 3. Win-state trigger and results panel

```
WinState (Area3D, collision_layer=1, monitorable=false)
  └─ CollisionShape3D (BoxShape3D spanning the finish zone)
```

In the level script:
```gdscript
func _on_win_state_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        Game.level_complete()
        $ResultsPanel.show_results(Game.run_time_seconds, par_time_seconds,
                                    Game.shards_collected, Game.shards_total)
```

`par_time_seconds` is a `@export float` on the level script — authorable per level.

### Results panel as UI overlay (not a scene change)

The results panel is a `CanvasLayer` child of the level scene, hidden by default.
Showing it does not require a scene change, so there is no reload hitch mid-session.
The **Replay** button calls `Game.reset_run()` which reloads the scene (panel 
destroyed with it). This is the right architecture:

```
Level (Node3D)
  ├─ World geometry
  ├─ Player
  ├─ WinState (Area3D)
  └─ ResultsPanel (CanvasLayer, hidden at start)
       ├─ Background (ColorRect, semi-transparent)
       ├─ TimeLabel (Label)
       ├─ ParLabel (Label)
       ├─ ShardLabel (Label)
       └─ ReplayButton (Button)  → Game.reset_run()
```

### Mobile UX requirements (from `win_state_design.md`)

- Panel visible in ≤ 1 frame after trigger.
- Replay button reaches screen within 0.5 s (no mandatory animation that blocks the button).
- Replay = full reload (`reload_current_scene`); does not need a fade.
- Don't show death count on the panel by default; track it quietly in `Game.attempts`.

---

## 4. Shard tracking

```gdscript
# DataShard.gd (Area3D)
func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        Game.shards_collected += 1
        queue_free()  # shard disappears; respawn via level reload
```

`Game.shards_total` is set in the level's `_ready()` by counting `DataShard` nodes:
```gdscript
func _ready() -> void:
    Game.start_run()
    Game.shards_total = get_tree().get_nodes_in_group("data_shard").size()
```

On `reset_run()`, `shards_collected` is zeroed because the scene reloads (shards 
re-instantiate). No manual reset needed — reload handles it.

---

## 5. Frame-hitch avoidance on mobile

- **Avoid `await` in the reload path.** `reload_current_scene()` is synchronous; 
  adding an `await get_tree().process_frame` before it to "let the results panel render
  one frame" is fine, but more than 1–2 awaits creates jank.
- **No LoadingScreen.** The gate 1 level is small enough that reload completes in one
  frame's physics idle. A loading screen would flash and look worse than a 50 ms
  black frame. Add one at Gate 2 only if level complexity warrants it.
- **`queue_free` ordering.** When `reset_run()` reloads, all nodes (including the 
  `ResultsPanel`) are freed by the scene reload. Don't manually `queue_free` the panel
  before reloading — it introduces a one-frame "blank level" state.
- **Preload key resources.** `player.tscn`, `DataShard.tscn`, `HazardBody.tscn` should
  be listed in Project Settings → Preload Resources or held as class-level preloads in
  the level script so they're in the resource cache before instantiation.

---

## 6. Gate 1 `game.gd` change summary

Fields to add:
- `var is_running: bool = false`
- `var shards_collected: int = 0`
- `var shards_total: int = 0`

Methods to add/update:
- `start_run()` — zeroes timer, shards, sets `is_running = true`
- `level_complete()` — clears `is_running`, emits `level_completed`
- `reset_run()` → add `get_tree().reload_current_scene()` call (currently a stub)
- `_process(delta)` → add `if is_running: run_time_seconds += delta`

Signals already present (stubs): `level_completed`, `player_respawned`, `checkpoint_reached`.

---

## Implications for Project Void

1. **Use `reload_current_scene()` for Gate 1 restart** — simple, correct, acceptable
   hitch for a small scene. Profile on device before Gate 2.
2. **Results panel as `CanvasLayer` in the level** — not a separate scene; no scene
   transition overhead; freed automatically on reload.
3. **Timer and shard tracking in `Game` autoload** — survives the results-panel overlay;
   reset is implicit in the scene reload.
4. **`start_run()` called from level `_ready()`** — level is the source of truth for
   `par_time_seconds`; pass it to the results panel via a direct call, not via `Game`.
5. **`WinState` is the last scene piece authored** — per `win_state_design.md` implication
   6; author after all gameplay is working so it doesn't interfere with testing.
6. **`game.gd` changes are backwards-compatible** — all new fields default to 0/false;
   the Feel Lab scene (which doesn't call `start_run()`) will not be affected.
