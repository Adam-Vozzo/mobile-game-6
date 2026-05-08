extends Node
## Game-wide state autoload. Currently a stub; will own scene flow, run state,
## attempt counters, and scoring once Gate 1 lands.

signal player_respawned
signal checkpoint_reached(checkpoint_id: StringName)
signal level_completed

var current_level_path: String = ""
var attempts: int = 0
var run_time_seconds: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func register_attempt() -> void:
	attempts += 1


func reset_run() -> void:
	attempts = 0
	run_time_seconds = 0.0
