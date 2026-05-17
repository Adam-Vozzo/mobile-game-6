extends Area3D
class_name CameraHint
## Spatial marker that signals the camera rig to pull back and frame a vista.
## camera_rig.gd queries get_tree().get_nodes_in_group("camera_hints") every frame,
## blending toward the max pull_back_amount among active hints at 3 /sec (95 % in ~1 s).
##
## NOTE: blend_time is exported but not wired — blend rate is always 3 /sec.
## Depth-pass action: remove blend_time (project standard is 3 /sec) or wire it.
## See docs/research/camera_hint_authoring.md for placement guidance.

@export_range(0.0, 10.0, 0.5) var pull_back_amount: float = 0.0
@export_range(0.1, 2.0, 0.1) var blend_time: float = 0.5


func _ready() -> void:
	add_to_group(&"camera_hints")


func is_player_inside() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			return true
	return false
