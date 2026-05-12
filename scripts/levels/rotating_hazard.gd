@tool
extends AnimatableBody3D
class_name RotatingHazard
## Continuously rotating AnimatableBody3D. Rotating around a local axis at a
## fixed angular rate. Use for maintenance arms, fans, spinning blades.
##
## HazardBody (Area3D) children kill on contact — add them to the arm geometry.
## period_seconds = one full revolution (TAU). paused freezes the rotation.

@export var rotation_axis: Vector3 = Vector3.UP
@export_range(0.5, 20.0, 0.25) var period_seconds: float = 4.0
@export var paused: bool = false

var _origin_position: Vector3
var _elapsed: float = 0.0


func _ready() -> void:
	_origin_position = position


func _physics_process(delta: float) -> void:
	if paused or period_seconds <= 0.0:
		return
	_elapsed += delta
	var angle: float = fmod(_elapsed / period_seconds, 1.0) * TAU
	var ax := rotation_axis.normalized()
	transform = Transform3D(Basis(ax, angle), _origin_position)
