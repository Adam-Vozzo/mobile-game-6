class_name TouchControls
extends Control

signal move_changed(v: Vector2)
signal jump_pressed
signal jump_released

@onready var _joystick: VirtualJoystick = $Joystick
@onready var _jump_btn: Button = $JumpButton

func _ready() -> void:
	_joystick.value_changed.connect(func(v): move_changed.emit(v))
	_jump_btn.button_down.connect(func(): jump_pressed.emit())
	_jump_btn.button_up.connect(func(): jump_released.emit())

func is_jump_held() -> bool:
	return _jump_btn.button_pressed

func get_move_input() -> Vector2:
	return _joystick.get_value()
