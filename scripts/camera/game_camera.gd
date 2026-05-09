class_name GameCamera
extends Node3D

@export var follow_target: Node3D
@export var lerp_speed: float = 8.0
@export var rotation_lerp: float = 5.0
@export var distance: float = 9.0
@export var height: float = 5.0
@export var look_height: float = 1.0

@onready var _camera: Camera3D = $Camera3D

var _yaw: float = 0.0
var _initialized: bool = false

func _physics_process(delta: float) -> void:
	if follow_target == null or _camera == null:
		return

	var target_yaw := follow_target.rotation.y + PI
	_yaw = lerp_angle(_yaw, target_yaw, rotation_lerp * delta)

	var offset := Vector3(sin(_yaw) * distance, height, cos(_yaw) * distance)
	var target_pos := follow_target.global_position + offset

	if not _initialized:
		global_position = target_pos
		_yaw = target_yaw
		_initialized = true
	else:
		global_position = global_position.lerp(target_pos, lerp_speed * delta)

	var look_at_pos := follow_target.global_position + Vector3(0, look_height, 0)
	if global_position.distance_to(look_at_pos) > 0.01:
		_camera.look_at(look_at_pos)
