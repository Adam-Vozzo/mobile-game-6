extends Node
## Touch input autoload. Aggregates virtual-stick and jump-button state
## published by the touch overlay scene, plus right-side camera drag.
##
## Naming note: CLAUDE.md called this autoload "Input", but Godot's built-in
## global singleton is also named Input — autoloading another node with that
## name would shadow it everywhere. Renamed to TouchInput to avoid the clash.
## Logged in docs/DECISIONS.md.

signal jump_pressed
signal jump_released

var move_vector: Vector2 = Vector2.ZERO
var jump_held: bool = false
var camera_drag_delta: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


## Called by the touch overlay each frame.
func set_move_vector(v: Vector2) -> void:
	move_vector = v.limit_length(1.0)


## Called by the touch overlay when the jump button is pressed/released.
func set_jump_held(pressed: bool) -> void:
	if pressed and not jump_held:
		jump_held = true
		jump_pressed.emit()
	elif not pressed and jump_held:
		jump_held = false
		jump_released.emit()


## Called by the touch overlay each frame for right-side drag delta in pixels.
func set_camera_drag_delta(delta: Vector2) -> void:
	camera_drag_delta = delta


## Convenience: prefer this over reading `move_vector` directly so we can
## later splice in keyboard fallback for editor testing.
func get_move_vector() -> Vector2:
	if move_vector.length_squared() > 0.0001:
		return move_vector
	# Editor fallback: WASD / arrows
	var v := Vector2.ZERO
	if Input.is_action_pressed(&"move_left"):
		v.x -= 1.0
	if Input.is_action_pressed(&"move_right"):
		v.x += 1.0
	if Input.is_action_pressed(&"move_up"):
		v.y -= 1.0
	if Input.is_action_pressed(&"move_down"):
		v.y += 1.0
	return v.limit_length(1.0)


func is_jump_held() -> bool:
	return jump_held or Input.is_action_pressed(&"jump")
