extends Node3D

@onready var _player: Player = $Player
@onready var _camera: GameCamera = $GameCamera
@onready var _touch: TouchControls = $UI/TouchControls
@onready var _dev: DevMenu = $UI/DevMenu

func _ready() -> void:
	_camera.follow_target = _player
	_touch.move_changed.connect(func(v): _player.move_input = v)
	_touch.jump_pressed.connect(_player.on_jump_pressed)
	_touch.jump_released.connect(_player.on_jump_released)
	_dev.bind_profile(_player.profile)

func _physics_process(_delta: float) -> void:
	var kb := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if kb.length_squared() > 0.01 and _touch.get_move_input().length_squared() < 0.01:
		_player.move_input = kb
	if Input.is_action_just_pressed("jump"):
		_player.on_jump_pressed()
	_player.jump_held = Input.is_action_pressed("jump") or _touch.is_jump_held()
