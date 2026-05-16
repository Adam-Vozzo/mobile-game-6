extends Node3D
## Arena — Gate 1 level candidate, shape-family: ringed arena.
##
## Parti: "The Annulus" — a decommissioned megastructure pressure containment
## ring. The ring's eastern arc has collapsed into the void; the Stray enters
## through a breach in the southern wall, circles the intact western arc, and
## vaults to the control node floating at the ring's centre.
##
## Shape family: ringed arena. Floor plan from above = an incomplete square
## ring (three-quarter frame) surrounding a central open void. The central
## altar is visible from every point on the ring but only reachable from the
## north arm's inner edge. Distinct from all prior shape families:
##   - Not Threshold: inner void is always present; no enclosing walls.
##   - Not Spire: horizontal traversal around a void, not vertical ascent.
##   - Not Rooftop: void is internal — the player rings it, not skirts it.
##   - Not Plaza: no hub-and-spoke; the ring IS the floor plan.
##   - Not Cavern: open overhead, no tunnel compression.
##   - Not Descent: falling is failure, not the mechanic.
##   - Not Filterbank: continuous looping route, not sequential chambers.
##   - Not Viaduct: wide walkway loops around a void, not thin spans over it.
##
## Layout (ring inner void ±6 m; ring width 4 m; outer boundary ±10 m):
##   SpawnSlab (S) → walk west → SWCorner → WestArm →
##   [0.5 m hop + 6 m ride + 0.5 m hop: moving platform across 9 m void] →
##   NWCorner (CP) → NorthArm [sentry] → [3.5 m + 4 m vault] → CentralAltar (WIN)
##   Side: NWCorner east edge → [1.5 m east jump] → ShardPedestal (Shard 1)
##         or NorthArm south edge → [2.5 m south jump] → ShardPedestal
##
## East side of ring is collapsed: no SECorner, EArm, or NECorner.
## The void is visible from spawn; CentralAltar biolume marks the goal.
##
## Skill target: ~50 s skilled / ~3 min new player.
## Checkpoint at NWCorner (after moving platform crossing, before sentry + vault).

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
## Placeholder — calibrate after first on-device wall-clock run (3–5 deaths).
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
	# NorthArm sentry: sweeps the arm's X-axis.  Player must read the rhythm
	# before committing to the inner-edge run-up for the final vault.
	# patrol_distance=6 → ±3 m from arm centre, covering most of the 12 m arm.
	var s: AnimatableBody3D = ps_script.new()
	s.name = &"SentryNorth"
	s.position = Vector3(0.0, 1.2, -8.0)
	s.set(&"patrol_axis", Vector3(1.0, 0.0, 0.0))
	s.set(&"patrol_distance", 6.0)
	s.set(&"patrol_speed", 2.0)
	add_child(s)
