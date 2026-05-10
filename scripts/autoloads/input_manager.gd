extends Node

# Touch input state — written by VirtualJoystick and jump button UI nodes.
# All game code reads from here rather than polling UI nodes directly.

var _move_vector: Vector2 = Vector2.ZERO
var _jump_pressed: bool = false  # true for exactly one frame
var _jump_held: bool = false
var _camera_delta: Vector2 = Vector2.ZERO  # accumulated this frame, cleared each frame

# VirtualJoystick calls this every process frame.
func set_move_vector(v: Vector2) -> void:
	_move_vector = v

# Called by jump button on touch_down.
func notify_jump_pressed() -> void:
	_jump_pressed = true
	_jump_held = true

# Called by jump button on touch_up.
func notify_jump_released() -> void:
	_jump_held = false

# Called by camera drag handler with per-frame delta.
func add_camera_delta(delta: Vector2) -> void:
	_camera_delta += delta

# --- Reads ---

func get_move_vector() -> Vector2:
	# Keyboard fallback (for desktop dev).
	var kb := Vector2.ZERO
	kb.x = Input.get_axis("move_left", "move_right")
	kb.y = Input.get_axis("move_forward", "move_back")
	if kb.length() > 0.01:
		return kb.limit_length(1.0)
	return _move_vector

func is_jump_just_pressed() -> bool:
	# Keyboard fallback.
	if Input.is_action_just_pressed("jump"):
		return true
	return _jump_pressed

func is_jump_held() -> bool:
	if Input.is_action_pressed("jump"):
		return true
	return _jump_held

func get_camera_delta() -> Vector2:
	return _camera_delta

func _process(_delta: float) -> void:
	# Clear single-frame state.
	_jump_pressed = false
	_camera_delta = Vector2.ZERO
