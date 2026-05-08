class_name TouchInput
extends CanvasLayer

## Virtual joystick (left half) + Jump button (right half).
## Injects Godot input actions so gameplay code reads Input.* uniformly.
## Jump button feeds the jump buffer via Player.request_jump().

# Layout fractions of screen width/height — tweak from dev menu or inspector.
@export var stick_center_x_ratio: float = 0.15
@export var stick_center_y_ratio: float = 0.72
@export var stick_radius: float = 60.0
@export var stick_dead_zone: float = 0.15

@export var jump_button_x_ratio: float = 0.88
@export var jump_button_y_ratio: float = 0.72
@export var jump_button_radius: float = 55.0

# Visual nodes.
@onready var _stick_bg: Control = $StickBg
@onready var _stick_nub: Control = $StickNub
@onready var _jump_bg: Control = $JumpBg

# Internal state.
var _stick_touch_index: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _jump_touch_index: int = -1
var _current_axis: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 10
	_layout_controls()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _process(_delta: float) -> void:
	_inject_movement_actions(_current_axis)


# ─── Event handling ───────────────────────────────────────────────────────────

func _handle_touch(e: InputEventScreenTouch) -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if e.pressed:
		# Stick zone: left 50% of screen.
		if e.position.x < vp_size.x * 0.5:
			if _stick_touch_index == -1:
				_stick_touch_index = e.index
				_stick_origin = e.position
				_stick_bg.global_position = e.position - _stick_bg.size * 0.5
		else:
			# Jump zone: right 50%.
			if _jump_touch_index == -1 and _is_in_jump_zone(e.position, vp_size):
				_jump_touch_index = e.index
				_fire_jump()
	else:
		if e.index == _stick_touch_index:
			_stick_touch_index = -1
			_current_axis = Vector2.ZERO
			_release_all_movement_actions()
			_stick_nub.global_position = _stick_bg.global_position + _stick_bg.size * 0.5 - _stick_nub.size * 0.5
		if e.index == _jump_touch_index:
			_jump_touch_index = -1
			Input.action_release("jump")


func _handle_drag(e: InputEventScreenDrag) -> void:
	if e.index != _stick_touch_index:
		return
	var delta: Vector2 = e.position - _stick_origin
	var clamped: Vector2 = delta.limit_length(stick_radius)
	_current_axis = clamped / stick_radius
	# Update nub visual.
	_stick_nub.global_position = _stick_origin + clamped - _stick_nub.size * 0.5


func _is_in_jump_zone(pos: Vector2, vp_size: Vector2) -> bool:
	var jc: Vector2 = Vector2(vp_size.x * jump_button_x_ratio, vp_size.y * jump_button_y_ratio)
	# Accept any tap in the right half — generous zone, not just the button circle.
	return pos.x >= vp_size.x * 0.5


# ─── Input injection ──────────────────────────────────────────────────────────

func _inject_movement_actions(axis: Vector2) -> void:
	_set_action("move_right", max(0.0, axis.x))
	_set_action("move_left", max(0.0, -axis.x))
	_set_action("move_back", max(0.0, axis.y))
	_set_action("move_forward", max(0.0, -axis.y))


func _set_action(action: String, strength: float) -> void:
	if strength > stick_dead_zone:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _release_all_movement_actions() -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)


func _fire_jump() -> void:
	Input.action_press("jump")
	# Notify player directly to start buffer (belt-and-suspenders with action).
	var player: Player = Game.get_player()
	if player:
		player.request_jump()


# ─── Layout ───────────────────────────────────────────────────────────────────

func _layout_controls() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var sc: Vector2 = Vector2(vp_size.x * stick_center_x_ratio, vp_size.y * stick_center_y_ratio)
	var jc: Vector2 = Vector2(vp_size.x * jump_button_x_ratio, vp_size.y * jump_button_y_ratio)

	if _stick_bg:
		_stick_bg.size = Vector2(stick_radius * 2.0, stick_radius * 2.0)
		_stick_bg.global_position = sc - _stick_bg.size * 0.5
	if _stick_nub:
		_stick_nub.size = Vector2(stick_radius * 0.7, stick_radius * 0.7)
		_stick_nub.global_position = sc - _stick_nub.size * 0.5
	if _jump_bg:
		_jump_bg.size = Vector2(jump_button_radius * 2.0, jump_button_radius * 2.0)
		_jump_bg.global_position = jc - _jump_bg.size * 0.5
