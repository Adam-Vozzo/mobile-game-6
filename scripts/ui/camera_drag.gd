class_name CameraDrag
extends Control

# Covers the right ~65% of the screen (excluding joystick zone and jump button area).
# Single-finger drag sends yaw delta to InputManager.

@export var sensitivity: float = 0.3  # degrees per pixel
@export var left_edge_fraction: float = 0.35   # must match joystick activation_zone_right_fraction
@export var right_edge_fraction: float = 0.70  # must stay left of jump button (anchor_left=0.7)

var _touch_index: int = -1
var _last_pos: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1:
			return
		if not _is_in_drag_zone(event.position):
			return
		_touch_index = event.index
		_last_pos = event.position
	else:
		if event.index == _touch_index:
			_touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var delta := event.position - _last_pos
	_last_pos = event.position
	InputManager.add_camera_delta(delta)

func _is_in_drag_zone(pos: Vector2) -> bool:
	var vp_size := get_viewport_rect().size
	return pos.x > vp_size.x * left_edge_fraction and pos.x < vp_size.x * right_edge_fraction
