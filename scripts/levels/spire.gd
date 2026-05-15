extends Node3D
## Spire — Gate 1 level candidate, shape-family: vertical climbing tower.
##
## Parti: the megastructure's primary exhaust shaft — a sealed column bored
## through several floor plates.  The Stray climbs from the lowest accessible
## catwalk to a breach at the summit.  Ascent is discovery; scale only becomes
## apparent halfway up.
##
## Shape family: compact floor-plan (~10 × 8 m), all traversal on the Y axis.
## Compare to Threshold (linear corridor) — the camera and jump arc demands are
## fundamentally different here.
##
## Skill target: ~50 s skilled / ~2 min new player.
## One mid-shaft checkpoint (PlatformC, between ShelfB and ShelfD).

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Conservative placeholder; calibrate after first on-device wall-clock run.
@export var par_time_seconds: float = 50.0

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
