extends Node3D

## Feel Lab — test arena script.
## Wires player, camera, and touch input after the scene is ready.

@onready var _player: Player = $Player
@onready var _camera_rig: CameraRig = $CameraRig
@onready var _touch_input: TouchInput = $TouchInput
@onready var _death_zone: Area3D = $DeathZone


func _ready() -> void:
	# camera_rig target is set by Game autoload when both register.
	# Explicit wiring here as belt-and-suspenders for hot-reload.
	_camera_rig.target = _player
	_player.set_camera_rig(_camera_rig)

	if _death_zone:
		_death_zone.body_entered.connect(_on_death_zone_body_entered)


func _on_death_zone_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).respawn()
