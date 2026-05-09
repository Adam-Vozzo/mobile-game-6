class_name VirtualJoystick
extends Control

signal value_changed(v: Vector2)

@export var dead_zone: float = 0.15
@export var knob_radius: float = 60.0

var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _value: Vector2 = Vector2.ZERO

@onready var _knob: Control = $Knob

func _ready() -> void:
	_center_knob()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)

func _on_touch(ev: InputEventScreenTouch) -> void:
	if ev.pressed:
		if _touch_index == -1 and _hit_test(ev.position):
			_touch_index = ev.index
			_origin = to_local(ev.position)
	else:
		if ev.index == _touch_index:
			_release()

func _on_drag(ev: InputEventScreenDrag) -> void:
	if ev.index != _touch_index:
		return
	var offset := to_local(ev.position) - _origin
	var clamped := offset.limit_length(knob_radius)
	_knob.position = size * 0.5 + clamped - _knob.size * 0.5
	var raw := clamped / knob_radius
	_value = Vector2.ZERO if raw.length() < dead_zone else raw
	value_changed.emit(_value)

func _release() -> void:
	_touch_index = -1
	_value = Vector2.ZERO
	_center_knob()
	value_changed.emit(_value)

func _center_knob() -> void:
	if _knob:
		_knob.position = size * 0.5 - _knob.size * 0.5

func _hit_test(global_pos: Vector2) -> bool:
	var local := to_local(global_pos)
	return Rect2(Vector2.ZERO, size).has_point(local)

func get_value() -> Vector2:
	return _value
