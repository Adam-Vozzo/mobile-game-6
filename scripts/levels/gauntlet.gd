extends Node3D
## Gauntlet — Gate 1 level candidate, shape-family: enclosed obstacle gauntlet.
##
## Parti: "The Filterbank" — a sequence of decommissioned industrial processing
## chambers connected by low-ceilinged service passages. Each chamber houses a
## surviving mechanical hazard that must be timed or dodged. The Stray advances
## by reading each machine's rhythm and moving with it.
##
## Shape family: enclosed obstacle gauntlet. Floor plan is a single forced
## corridor of hazard chambers — no branching, no open voids, no exploration.
## The mechanical obstacles ARE the spatial grammar; the corridor is connective
## tissue between them. Distinct from all existing shape families.
##
## Hazard sequence (each beat is a distinct mechanical type):
##   Beat 1 — Press1: timed Y-crush (read dormant window, walk under)
##   Beat 2 — PatrolSentry: timed X-patrol dodge (wait for gap, cross)
##   Beat 3 — Moving Platform over void (jump on, ride, jump off)
##   Beat 4 — Press2 + Sentry2 combined (both rhythms simultaneously)
##
## Routes:
##   Critical path: time each hazard in sequence, z=0 → z=72.
##   Shard 1: shelf east of Press1 exit (z≈21) — jump up after clearing press.
##   Shard 2: shelf east in Sentry Corridor (z≈28) — collect while sentry is west.
##   Checkpoint at z=34 (after sentry, before moving-platform void).
##
## Skill target: ~45 s skilled / ~3 min new player.

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Placeholder; calibrate after first on-device wall-clock run (3–5 deaths).
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
	_spawn_sentries()


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


func _spawn_sentries() -> void:
	var ps_script := load("res://scripts/enemies/patrol_sentry.gd")
	if ps_script == null:
		return
	# Beat 2: sentry sweeps the 8 m corridor width, blocking the Z-axis path.
	# patrol_distance=6 → goes ±3 m from spawn; player must time when sentry is
	# at far side to cross. patrol_speed=2.0 gives a comfortable window.
	var s1: AnimatableBody3D = ps_script.new()
	s1.name = &"SentryBeat2"
	s1.position = Vector3(0.0, 1.2, 28.0)
	s1.set(&"patrol_axis", Vector3(1.0, 0.0, 0.0))
	s1.set(&"patrol_distance", 6.0)
	s1.set(&"patrol_speed", 2.0)
	add_child(s1)
	# Beat 4 combined: second sentry occupies exit zone after Press2 (z≈59-65).
	# Slightly faster than Beat 2 to increase pressure.
	var s2: AnimatableBody3D = ps_script.new()
	s2.name = &"SentryBeat4"
	s2.position = Vector3(0.0, 1.2, 62.0)
	s2.set(&"patrol_axis", Vector3(1.0, 0.0, 0.0))
	s2.set(&"patrol_distance", 6.0)
	s2.set(&"patrol_speed", 2.5)
	add_child(s2)
