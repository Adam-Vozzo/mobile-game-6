extends Node3D
## Threshold level — Gate 1, first level.
##
## Parti: three architecturally distinct zones separated by abrupt thresholds.
## The Stray moves from the human scale of an abandoned habitation layer through
## a punishing maintenance buffer into the inhuman scale of active industrial
## machinery — a spatial autobiography of the megastructure.
##
## Skill targets: ~70 s skilled / ~3 min new player.
## Par route: buffer skip (long cross-cart jump) + industrial early-commit lines.

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Par completion time for the results panel. 35 s is a conservative skilled
## target; tune after first on-device playtest.
@export var par_time_seconds: float = 35.0

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
