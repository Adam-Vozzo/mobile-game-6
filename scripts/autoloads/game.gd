extends Node

## Game autoload — global references and scene lifecycle.
## Player, CameraRig, and DevMenu register themselves here on _ready.

var _player: Player = null
var _camera_rig: CameraRig = null


func _ready() -> void:
	_spawn_dev_menu()


func _spawn_dev_menu() -> void:
	var dev_menu_scene: PackedScene = load("res://scenes/ui/dev_menu.tscn")
	if dev_menu_scene:
		var dev_menu: Node = dev_menu_scene.instantiate()
		get_tree().root.call_deferred("add_child", dev_menu)


# ─── Registration ─────────────────────────────────────────────────────────────

func register_player(p: Player) -> void:
	_player = p
	if _camera_rig:
		_camera_rig.target = p
		p.set_camera_rig(_camera_rig)


func register_camera(cam: CameraRig) -> void:
	_camera_rig = cam
	if _player:
		cam.target = _player
		_player.set_camera_rig(cam)


func get_player() -> Player:
	return _player


func get_camera() -> CameraRig:
	return _camera_rig
