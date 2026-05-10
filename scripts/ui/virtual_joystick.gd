class_name VirtualJoystick
extends Control

# Floating virtual joystick — activates wherever the left thumb lands within
# the defined activation zone. Scene file is a bare full-screen Control + script.
# Radius and dead zone scale with screen height for DPI independence.

@export var activation_zone_right_fraction: float = 0.35  # left N% of screen width
@export var joystick_radius_fraction: float = 0.08        # fraction of screen height
@export var deadzone_fraction: float = 0.15               # fraction of joystick_radius

var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _radius: float = 80.0

# Programmatically created visuals.
var _base: ColorRect = null
var _knob: ColorRect = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_visuals()
	_recalculate_radius()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1:
			return
		if not _in_activation_zone(event.position):
			return
		_touch_index = event.index
		_origin = event.position
		_position_base(_origin)
		_base.visible = true
		_update_knob(_origin)
	else:
		if event.index == _touch_index:
			_release()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index:
		_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var offset := touch_pos - _origin
	var clamped := offset.limit_length(_radius)
	if _knob != null:
		_knob.position = clamped - Vector2(_knob.size.x, _knob.size.y) * 0.5 + Vector2(_radius, _radius)

	var dead := _radius * deadzone_fraction
	var output := Vector2.ZERO
	if offset.length() > dead:
		output = (offset / _radius).limit_length(1.0)
	InputManager.set_move_vector(output)

func _release() -> void:
	_touch_index = -1
	if _base != null:
		_base.visible = false
	InputManager.set_move_vector(Vector2.ZERO)

func _in_activation_zone(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x * activation_zone_right_fraction

func _position_base(center: Vector2) -> void:
	if _base == null:
		return
	_base.position = center - Vector2(_radius, _radius)

func _recalculate_radius() -> void:
	_radius = get_viewport_rect().size.y * joystick_radius_fraction
	var d := _radius * 2.0
	if _base != null:
		_base.size = Vector2(d, d)
		_base.pivot_offset = Vector2(_radius, _radius)
	if _knob != null:
		var kd := _radius * 0.5
		_knob.size = Vector2(kd, kd)

func _build_visuals() -> void:
	_base = ColorRect.new()
	_base.color = Color(1, 1, 1, 0.18)
	_base.visible = false
	add_child(_base)

	_knob = ColorRect.new()
	_knob.color = Color(1, 1, 1, 0.55)
	_base.add_child(_knob)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_radius()
