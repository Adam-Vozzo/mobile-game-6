class_name JumpButton
extends Control

# Right-thumb jump button. Responds on touch_down for minimum latency.
# Sized using a radius based on screen height — no scene children needed.

@export var touch_radius_fraction: float = 0.11  # fraction of screen height

var _touch_index: int = -1
var _touch_radius: float = 60.0
var _visual: ColorRect = null

func _ready() -> void:
	_recalculate_radius()
	_build_visual()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1:
			return
		if not _hit_test(event.position):
			return
		_touch_index = event.index
		InputManager.notify_jump_pressed()
		if _visual != null:
			_visual.modulate = Color(1.5, 1.5, 1.5, 0.8)
	else:
		if event.index == _touch_index:
			_touch_index = -1
			InputManager.notify_jump_released()
			if _visual != null:
				_visual.modulate = Color(1, 1, 1, 0.55)

func _hit_test(pos: Vector2) -> bool:
	var center := global_position + size * 0.5
	return pos.distance_to(center) <= _touch_radius

func _recalculate_radius() -> void:
	_touch_radius = get_viewport_rect().size.y * touch_radius_fraction

func _build_visual() -> void:
	_visual = ColorRect.new()
	_visual.color = Color(1, 1, 1, 0.55)
	_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_visual)
	var lbl := Label.new()
	lbl.text = "JUMP"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(lbl)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_radius()
