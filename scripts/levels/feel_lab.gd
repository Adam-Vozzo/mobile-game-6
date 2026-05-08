extends Node3D
## Feel Lab — Gate 0 test arena. Greybox primitives only; promoted to real
## art per docs/ART_PIPELINE.md once a style direction is approved.
##
## Layout (rough): central spawn at origin, a chain of jump platforms going
## +X with rising heights, slopes going -X, a wall-jump pocket in -Z, a
## ping-pong moving platform in +Z, and four tall background pillars to
## hint at the megastructure scale around the test space.

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"
@export var fall_threshold_y: float = -25.0

@onready var _spawn: Marker3D = get_node_or_null(spawn_marker_path) as Marker3D


func _ready() -> void:
	if _spawn == null:
		return
	var spawn_t := _spawn.global_transform
	for player in get_tree().get_nodes_in_group(&"player"):
		if player is Node3D:
			(player as Node3D).global_transform = spawn_t
			# Keep the player's respawn point in sync with the spawn marker.
			if player.has_method("set_spawn_transform"):
				player.set_spawn_transform(spawn_t)


func get_spawn_transform() -> Transform3D:
	if _spawn != null:
		return _spawn.global_transform
	return Transform3D.IDENTITY
