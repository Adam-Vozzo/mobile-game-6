extends Node

## PerfBudget autoload — tracks particle emitter count and draw calls.
## Warns in the console when budgets are exceeded.
## Budget constants match the targets in CLAUDE.md.

const TRI_BUDGET: int = 80_000
const DRAW_CALL_BUDGET: int = 200
const PARTICLE_BUDGET: int = 32

var _particle_count: int = 0
var _last_frametime_ms: float = 0.0
var _last_draw_calls: int = 0

## Called once per second by the dev menu overlay for display.
var on_stats_updated: Callable


func _process(_delta: float) -> void:
	_last_frametime_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_last_draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func register_particles(emitter: Node) -> void:
	_particle_count += 1
	if _particle_count > PARTICLE_BUDGET:
		push_warning("PerfBudget: particle emitter count %d exceeds budget %d" % [_particle_count, PARTICLE_BUDGET])
	emitter.tree_exited.connect(_on_emitter_removed.bind(emitter))


func _on_emitter_removed(_emitter: Node) -> void:
	_particle_count = max(0, _particle_count - 1)


# ─── Accessors for dev menu ───────────────────────────────────────────────────

func get_frametime_ms() -> float:
	return _last_frametime_ms


func get_draw_calls() -> int:
	return _last_draw_calls


func get_particle_count() -> int:
	return _particle_count
