extends Node3D
## Viaduct — Gate 1 level candidate, shape-family: exposed bridge crossing.
##
## Parti: "The Viaduct" — a series of suspended concrete spans crossing a
## deep industrial void.  The spatial grammar is: stay on the path or fall.
## Unlike the Rooftop (large surfaces with void at the edge), every span here
## IS the path — narrow, exposed, void on both sides at all times.  The danger
## is not a margin condition; it is the constant context.
##
## Shape family: exposed bridge crossing.  Floor plan from above = a sequence
## of narrow lines (spans) crossing open space, anchored to abutment platforms
## on each end.  The line IS the level; the void is the room.
##
## Distinct from all existing shape families:
##   - Not Threshold: no enclosing walls, void replaces the room.
##   - Not Spire: horizontal traversal, not vertical ascent.
##   - Not Rooftop: spans are 1.5–2 m wide (path-width) not surface-area.
##   - Not Plaza: no hub, no branching choice — one direction over open space.
##   - Not Cavern: open sky above, not tunnel compression.
##   - Not Descent: falling is failure, not the mechanic.
##   - Not Filterbank: no enclosed hazard chambers.
##
## Routes:
##   Critical: EntryAbutment → Span1 (2 m wide) → PierHead1 (CP)
##             → [moving platform over 14 m gap] → Span2 (1.5 m wide)
##             → Span3Final (2 m wide, sentry) → ArrivalAbutment (WIN)
##   Side:     PierHead1 east jump → ShardSpur → ShardPlatform (Shard 1)
##
## Skill target: ~45 s skilled / ~2.5 min new player.
## Checkpoint at PierHead1 (mid-void, halfway through the crossing).

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Placeholder — calibrate after first on-device wall-clock run (3–5 deaths).
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
	_spawn_sentry()


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


func _spawn_sentry() -> void:
	var ps_script := load("res://scripts/enemies/patrol_sentry.gd")
	if ps_script == null:
		return
	# Span3Final sentry: sweeps X-axis across the 2 m-wide span.
	# patrol_distance=3 → ±1.5 m from centre.  At the extremes the sentry
	# body (0.8 m) reaches to within 0.2 m of the span edge — player must
	# read the rhythm and slip past when the sentry reaches one side.
	var s: AnimatableBody3D = ps_script.new()
	s.name = &"SentryFinal"
	s.position = Vector3(0.0, 1.2, 68.0)
	s.set(&"patrol_axis", Vector3(1.0, 0.0, 0.0))
	s.set(&"patrol_distance", 3.0)
	s.set(&"patrol_speed", 2.0)
	add_child(s)
