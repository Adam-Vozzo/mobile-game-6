extends Node
## Game-wide state autoload. Owns scene flow, run state, attempt counters,
## and scoring (Gate 1+).

@warning_ignore("unused_signal")
signal player_respawned
@warning_ignore("unused_signal")
signal checkpoint_reached(checkpoint_id: StringName)
@warning_ignore("unused_signal")
signal level_completed
## Emitted by player/hazards when a game event warrants a camera shake.
## magnitude: peak rotation offset in radians; duration: seconds; freq: Hz.
@warning_ignore("unused_signal")
signal screen_shake_requested(magnitude: float, duration: float, freq: float)

## Ghost trail recording — 30 samples/s, up to 5 attempts, up to 90 s each.
const SAMPLE_INTERVAL := 1.0 / 30.0
const MAX_TRAIL_DEPTH := 5
const MAX_TRAIL_LEN   := 2700   # 90 s × 30 samples/s — hard cap

var current_level_path: String = ""
var attempts: int = 0
var run_time_seconds: float = 0.0
var is_running: bool = false
var shards_collected: int = 0
var shards_total: int = 0

## Published trail data — read by GhostTrailRenderer each frame.
var trail_history: Array[PackedVector3Array] = []
var _current_trail := PackedVector3Array()
var _sample_accum: float = 0.0
var _recording: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player_respawned.connect(_on_player_respawned)


func _process(delta: float) -> void:
	if is_running:
		run_time_seconds += delta


func _physics_process(delta: float) -> void:
	if not _recording:
		return
	_sample_accum += delta
	if _sample_accum < SAMPLE_INTERVAL:
		return
	_sample_accum -= SAMPLE_INTERVAL
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	_current_trail.append((player as Node3D).global_position)
	if _current_trail.size() > MAX_TRAIL_LEN:
		_current_trail.remove_at(0)


func start_run() -> void:
	run_time_seconds = 0.0
	shards_collected = 0
	is_running = true
	trail_history.clear()
	_current_trail.clear()
	_sample_accum = 0.0
	_recording = true


func level_complete() -> void:
	is_running = false
	_recording = false
	level_completed.emit()


func register_attempt() -> void:
	attempts += 1


func reset_run() -> void:
	is_running = false
	_recording = false
	attempts = 0
	run_time_seconds = 0.0
	shards_collected = 0
	trail_history.clear()
	_current_trail.clear()
	_sample_accum = 0.0


func _on_player_respawned() -> void:
	if _current_trail.size() > 0:
		trail_history.push_front(_current_trail.duplicate())
		if trail_history.size() > MAX_TRAIL_DEPTH:
			trail_history.pop_back()
	_current_trail.clear()
	_sample_accum = 0.0
