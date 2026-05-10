class_name CameraRig
extends Node3D

@export var target: NodePath = NodePath("")
@export_group("Follow")
@export var follow_speed: float = 10.0
@export var height_offset: float = 1.5
@export_group("Spring")
@export var spring_length: float = 6.0
@export var pitch_angle: float = -20.0  # degrees; negative = camera above, looking down
@export_group("Manual Yaw")
@export var yaw_sensitivity: float = 0.3  # degrees per pixel

@onready var _spring: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D

var _target_node: Node3D = null
var _yaw: float = 0.0

func _ready() -> void:
	if target != NodePath(""):
		_target_node = get_node_or_null(target)
	_register_dev_menu()

func _process(delta: float) -> void:
	var cam_delta := InputManager.get_camera_delta()
	_yaw -= cam_delta.x * yaw_sensitivity
	# Set both pitch and yaw in one assignment to avoid Euler-angle partial-set issues.
	_spring.rotation = Vector3(deg_to_rad(pitch_angle), deg_to_rad(_yaw), 0.0)
	_spring.spring_length = spring_length
	_camera.position.z = spring_length
	_follow_target(delta)

# Allow level scripts to assign target after scene init.
func set_target(node: Node3D) -> void:
	_target_node = node

func _follow_target(delta: float) -> void:
	if _target_node == null:
		return
	var desired := _target_node.global_position + Vector3(0.0, height_offset, 0.0)
	global_position = global_position.lerp(desired, follow_speed * delta)

func _register_dev_menu() -> void:
	if not has_node("/root/DevMenu"):
		return
	var dm := get_node("/root/DevMenu")
	dm.register_float("Camera", "Spring Length", self, "spring_length", 2.0, 15.0)
	dm.register_float("Camera", "Follow Speed", self, "follow_speed", 1.0, 20.0)
	dm.register_float("Camera", "Height Offset", self, "height_offset", 0.0, 4.0)
	dm.register_float("Camera", "Pitch Angle", self, "pitch_angle", -60.0, 0.0)
	dm.register_float("Camera", "Yaw Sensitivity", self, "yaw_sensitivity", 0.05, 1.0)
