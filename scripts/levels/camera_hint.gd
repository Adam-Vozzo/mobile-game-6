extends Area3D
class_name CameraHint
## Spatial marker that signals the camera rig to pull back and frame a vista.
## camera_rig.gd queries get_tree().get_nodes_in_group("camera_hints") every frame,
## blending toward the max pull_back_amount among active hints at CameraRig._HINT_BLEND_RATE /sec
## (≈ 95 % converged in ~1 s). See docs/research/camera_hint_authoring.md for placement guidance.

@export_range(0.0, 10.0, 0.5) var pull_back_amount: float = 0.0


func _ready() -> void:
	add_to_group(&"camera_hints")


func is_player_inside() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			return true
	return false
