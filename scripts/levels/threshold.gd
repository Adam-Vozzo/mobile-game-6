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

## Zone-distinct Environment resources (warm / cold / amber). Each is swapped
## onto the single WorldEnv node when the player enters the matching zone trigger.
## Assigned from sub_resources in threshold.tscn so the editor can preview each.
@export var zone1_env: Environment
@export var zone2_env: Environment
@export var zone3_env: Environment

## When false the WorldEnvironment stays on zone1_env regardless of triggers.
## Toggled from dev menu "Zone atmosphere" button for A/B comparison.
var zone_atmosphere_enabled: bool = true

@onready var _spawn: Marker3D = get_node_or_null(spawn_marker_path) as Marker3D
@onready var _world_env: WorldEnvironment = get_node_or_null(^"WorldEnv") as WorldEnvironment

var _results_panel: ResultsPanel = null
var _active_zone: int = 1


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
	_connect_zone_triggers()
	_apply_zone_env(1)
	if has_node("/root/DevMenu"):
		DevMenu.atmosphere_param_changed.connect(_on_atmosphere_param_changed)


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


func _connect_zone_triggers() -> void:
	for id: int in [1, 2, 3]:
		var trig := get_node_or_null("Zone%dTrigger" % id) as Area3D
		if trig != null:
			trig.body_entered.connect(_on_zone_body_entered.bind(id))


func _on_zone_body_entered(body: Node3D, zone_id: int) -> void:
	if not body is Player:
		return
	_active_zone = zone_id
	_apply_zone_env(zone_id)


func _apply_zone_env(zone_id: int) -> void:
	if _world_env == null:
		return
	var envs: Array[Environment] = [null, zone1_env, zone2_env, zone3_env]
	var target: Environment = envs[zone_id] if zone_id < envs.size() else null
	if zone_atmosphere_enabled and target != null:
		_world_env.environment = target
	elif not zone_atmosphere_enabled and zone1_env != null:
		_world_env.environment = zone1_env


func _on_atmosphere_param_changed(param: StringName, value: Variant) -> void:
	if param == &"zone_atmo_enabled":
		zone_atmosphere_enabled = bool(value)
		_apply_zone_env(_active_zone)
