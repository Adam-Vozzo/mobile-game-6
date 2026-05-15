extends Node3D
## Cavern — Gate 1 level candidate, shape-family: maze with branches.
##
## Parti: a maintenance conduit network buried deep in the megastructure.
## Low ceilings, narrow passages, T-junctions. The player spawns in a
## service bay and must navigate to a junction room with three exits:
## west dead-end (shard), east dead-end (shard), and a narrow north shaft
## that climbs to an elevated monitoring alcove — the only exit.
##
## Shape family: cave / maze with branches.
## Distinct from: Threshold (linear), Spire (vertical shaft), Rooftop
## (void below, open air), Plaza (hub with visible spokes from centre).
## Here the player CANNOT see the full route from spawn. Orientation is
## the primary challenge, not reflex.
##
## Routes:
##   EntryBay → NorthPass → JunctionRoom (CP) → NorthLedge → FinalChamber (WIN)
##   JunctionRoom → WestPass → WestSpur (Shard 1)
##   JunctionRoom → EastPass → EastSpur (Shard 2)
##
## Skill target: ~45 s skilled / ~3 min new player.
## Checkpoint at JunctionRoom (required — player must orient before the climb).

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
