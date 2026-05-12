extends Area3D
class_name WinState
## Level-completion trigger. Fires Game.level_completed when the player
## enters for the first time. ResultsPanel wired at Gate 1; for now the
## signal is emitted and a console message confirms it.

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
		Game.level_completed.emit()
	print("[WinState] Level complete — results screen stub. Gate 1 wires ResultsPanel.")
