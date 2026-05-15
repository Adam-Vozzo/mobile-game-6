extends Node3D
## Rooftop — Gate 1 level candidate, shape-family: open-air rooftop.
##
## Parti: the Stray emerges onto the exposed top surface of a megastructure floor
## plate through a maintenance hatch. The roof is a shattered expanse of concrete
## fragments, service beams, and catwalks with no enclosing walls. The void —
## total darkness — is below on all sides. Navigation means reading the broken
## architecture to find a path across to a raised comms relay beacon.
##
## Shape family: open horizontal traversal over a void (no walls, no ceiling).
## Compare to Threshold (linear corridor, enclosed) and Spire (vertical shaft).
## The camera copes with open space; the depth cue is the void below.
##
## Layout (north = −Z):
##   SpawnSlab → FragA → BeamB (narrow) → SlabC (CP) →
##   [MovPlatE bridge east] → EastPost → StepG → RelayPad (WIN)
##
## Skill target: ~45 s skilled / ~2 min new player.
## One checkpoint on SlabC (mid-traverse).

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Placeholder; calibrate from first on-device wall-clock run (3–5 deaths).
@export var par_time_seconds: float = 45.0

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
