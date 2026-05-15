extends Node3D
## Plaza — Gate 1 level candidate, shape-family: hub with radiating spokes.
##
## Parti: a ruined transit atrium at the intersection of three megastructure
## circulation corridors. The hub floor is the only large flat space — the
## three decommissioned spoke-arms radiate outward (north, east, west) to
## dead-end platforms with salvageable data shards. At the centre of the
## north wall, a monitoring pillar climbs toward a breach in the ceiling slab.
## That breach is the only exit.
##
## Shape family: central hub + radiating spoke arms (Spyro PS1 grammar).
## Distinct from: Threshold (linear), Spire (vertical shaft), Rooftop (void
## below, no hub). Here the player is anchored by the hub, sees all routes
## simultaneously, and chooses.
##
## Routes:
##   Hub → PillarStep1 → PillarStep2 (CP) → PillarSummit (WIN)  [north, critical]
##   Hub → ESide1 → MovingPlatE → ETerminus (Shard 1)            [east, timing]
##   Hub → WPost → WNarrow → WChamber (Shard 2)                  [west, precision]
##
## Skill target: ~40 s skilled / ~3 min new player.
## Checkpoint at PillarStep2 (mid pillar-climb, before hardest jump).

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
