extends Node3D
## Descent — Gate 1 level candidate, shape-family: inverted descent.
##
## Parti: a descent through the hollow of a dead elevator column.
## The Stray falls through the world rather than climbing it — each
## floor plate is a waypoint in a controlled downward journey.
## The top is dim amber (old industrial); the bottom glows biolume cyan
## (something still runs down here — the column is dead, not the world).
##
## Shape family: inverted descent — primary movement axis is DOWNWARD.
## Distinct from: Threshold (horizontal), Spire (vertical ascent),
## Rooftop (open-air horizontal), Plaza (hub + spokes), Cavern (maze).
## Falling is the mechanic; the challenge is controlling the descent and
## making horizontal detours to collect shards from side ledges.
##
## Routes:
##   TopSlab → (east edge drop, optional LedgeA stop) → LedgeB (CP)
##     → east route via LedgeC + ShardLedge2 → BasePad (WIN)
##     OR expert line: straight drop from LedgeB center to BasePad
##   TopSlab west → ShardLedge1 (1m gap jump) → Shard 1
##   LedgeC east → ShardLedge2 (1m gap jump) → Shard 2
##
## Skill target: ~40 s skilled / ~2 min new player.
## Checkpoint at LedgeB (mid-shaft, halfway through the descent).

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Placeholder; calibrate from first on-device wall-clock run (3–5 deaths).
@export var par_time_seconds: float = 40.0

@onready var _spawn: Marker3D = get_node_or_null(spawn_marker_path) as Marker3D

var _results_panel: ResultsPanel = null


func _ready() -> void:
	if _spawn != null:
		for player: Node in get_tree().get_nodes_in_group(&"player"):
			if player is Node3D:
				(player as Node3D).global_transform = _spawn.global_transform
	if has_node("/root/Game"):
		Game.current_level_path = scene_file_path
		Game.shards_total = get_tree().get_nodes_in_group(&"data_shard").size()
		Game.level_completed.connect(_on_level_completed)
		Game.start_run()
	_results_panel = ResultsPanel.new()
	add_child(_results_panel)
	if has_node("/root/Audio"):
		Audio.set_ambient_zone(1)


func _on_level_completed() -> void:
	if _results_panel != null:
		_results_panel.show_results(
			Game.run_time_seconds,
			par_time_seconds,
			Game.shards_collected,
			Game.shards_total,
		)


func get_spawn_transform() -> Transform3D:
	if _spawn != null:
		return _spawn.global_transform
	return Transform3D.IDENTITY
