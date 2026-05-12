extends Area3D
class_name CameraHint
## Spatial marker that signals the camera rig to pull back and frame a vista.
## Stub for Gate 1: the camera rig will query active hints via
## get_tree().get_nodes_in_group("camera_hints") once the framing pass lands.
##
## @export pull_back_amount: extra spring-arm distance (metres) while inside.
## @export blend_time:       seconds to lerp in/out of the hint.

@export_range(0.0, 10.0, 0.5) var pull_back_amount: float = 0.0
@export_range(0.1, 2.0, 0.1) var blend_time: float = 0.5


func _ready() -> void:
	add_to_group(&"camera_hints")


func is_player_inside() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			return true
	return false
