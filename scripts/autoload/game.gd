extends Node
## Game-wide state autoload. Owns scene flow, run state, attempt counters,
## and scoring (Gate 1+).

@warning_ignore("unused_signal")
signal player_respawned
@warning_ignore("unused_signal")
signal checkpoint_reached(checkpoint_id: StringName)
@warning_ignore("unused_signal")
signal level_completed

var current_level_path: String = ""
var attempts: int = 0
var run_time_seconds: float = 0.0
var is_running: bool = false
var shards_collected: int = 0
var shards_total: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if is_running:
		run_time_seconds += delta


func start_run() -> void:
	run_time_seconds = 0.0
	shards_collected = 0
	is_running = true


func level_complete() -> void:
	is_running = false
	level_completed.emit()


func register_attempt() -> void:
	attempts += 1


func reset_run() -> void:
	is_running = false
	attempts = 0
	run_time_seconds = 0.0
	shards_collected = 0
