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

@onready var _spawn: Marker3D = get_node_or_null(spawn_marker_path) as Marker3D


func _ready() -> void:
	if _spawn != null:
		for player: Node in get_tree().get_nodes_in_group(&"player"):
			if player is Node3D:
				(player as Node3D).global_transform = _spawn.global_transform
	if has_node("/root/Game"):
		Game.current_level_path = scene_file_path


func get_spawn_transform() -> Transform3D:
	if _spawn != null:
		return _spawn.global_transform
	return Transform3D.IDENTITY
