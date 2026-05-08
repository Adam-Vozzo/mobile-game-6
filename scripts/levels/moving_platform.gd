class_name MovingPlatform
extends AnimatableBody3D

## Oscillates between two points on a local axis.
## Uses sync_to_physics = true so CharacterBody3D detects motion.

@export var move_axis: Vector3 = Vector3(4.0, 0.0, 0.0)
@export var period: float = 3.0
@export var phase_offset: float = 0.0

var _origin: Vector3 = Vector3.ZERO
var _t: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = global_position
	_t = phase_offset


func _physics_process(delta: float) -> void:
	_t += delta
	var frac: float = (sin(_t * TAU / period) + 1.0) * 0.5
	global_position = _origin + move_axis * frac
