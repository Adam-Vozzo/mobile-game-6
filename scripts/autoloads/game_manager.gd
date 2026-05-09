extends Node

signal gate_changed(gate: int)

var current_gate: int = 0
var stray_collected: int = 0

func _ready() -> void:
	_register_input_actions()

func _register_input_actions() -> void:
	_add_key("dev_menu_toggle", KEY_QUOTELEFT)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("jump", KEY_SPACE)

func _add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	else:
		return
	var ev := InputEventKey.new()
	ev.keycode = key
	InputMap.action_add_event(action, ev)
