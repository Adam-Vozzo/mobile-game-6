extends Node3D
## Style Test — static viewing room for art fidelity checks.
## Use this scene to evaluate any incoming asset (mesh, texture, material)
## before committing it. See docs/ART_PIPELINE.md § Style fidelity check.
##
## Workflow: place the candidate asset as a MeshInstance3D inside DisplayRoom,
## run the scene, walk the Stray around it, and answer the five fidelity
## questions in ART_PIPELINE.md (palette fit, silhouette, detail density,
## tonal fit, scale).

@export var spawn_marker_path: NodePath = ^"PlayerSpawn"

@onready var _spawn: Marker3D = get_node_or_null(spawn_marker_path) as Marker3D


func _ready() -> void:
	if _spawn == null:
		return
	for player: Node in get_tree().get_nodes_in_group(&"player"):
		if player is Node3D:
			(player as Node3D).global_transform = _spawn.global_transform


func get_spawn_transform() -> Transform3D:
	if _spawn != null:
		return _spawn.global_transform
	return Transform3D.IDENTITY
