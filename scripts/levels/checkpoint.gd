extends Area3D
class_name CheckPoint
## Sets the player's active spawn point when they pass through, then locks.
## Place as a child of an alcove node with an appropriate CollisionShape3D child.

@export var checkpoint_id: StringName = &"checkpoint_1"

var _activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func reset() -> void:
	_activated = false


func _on_body_entered(body: Node3D) -> void:
	if _activated:
		return
	if not body is Player:
		return
	_activated = true
	(body as Player).set_spawn_transform(global_transform)
	if has_node("/root/Game"):
		Game.checkpoint_reached.emit(checkpoint_id)
