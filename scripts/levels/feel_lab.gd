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
	# Move the player to the spawn marker if one was instanced as a child
	# at scene-load time. Step 5 wires the player as an actual child node;
	# until then this is a no-op.
	if _spawn == null:
		return
	for player in get_tree().get_nodes_in_group(&"player"):
		if player is Node3D:
			(player as Node3D).global_transform = _spawn.global_transform


func get_spawn_transform() -> Transform3D:
	if _spawn != null:
		return _spawn.global_transform
	return Transform3D.IDENTITY
