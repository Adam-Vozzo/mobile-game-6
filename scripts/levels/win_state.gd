extends Area3D
class_name WinState
## Level-completion trigger. Calls Game.level_complete() (which stops the
## run timer then emits level_completed) when the player enters for the
## first time. The level script listens to level_completed and shows
## its ResultsPanel overlay.

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body is Player:
		return
	_triggered = true
	if has_node("/root/Game"):
		Game.level_complete()
