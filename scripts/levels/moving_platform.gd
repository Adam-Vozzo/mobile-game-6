@tool
extends AnimatableBody3D
class_name MovingPlatform
## Kinematic ping-pong platform. Pairs with CharacterBody3D's built-in
## platform-floor handling so the player rides it without sliding.
##
## Author the platform as the rest position; `travel` is the offset from
## that origin. `period_seconds` is one full back-and-forth cycle.

@export var travel: Vector3 = Vector3(6.0, 0.0, 0.0)
@export var period_seconds: float = 4.0
@export var ease_in_out: bool = true
@export var paused: bool = false

var _origin: Vector3
var _elapsed: float = 0.0


func _ready() -> void:
	_origin = position
	# AnimatableBody3D defaults: sync_to_physics on, so animating `position`
	# in _physics_process gives the player surface velocity for free.


func _physics_process(delta: float) -> void:
	if paused or period_seconds <= 0.0:
		return
	_elapsed += delta
	var phase := fmod(_elapsed / period_seconds, 1.0)
	var triangle := 1.0 - absf(phase * 2.0 - 1.0)
	var t := smoothstep(0.0, 1.0, triangle) if ease_in_out else triangle
	position = _origin + travel * t
