extends Area3D
class_name WinState
## Level-completion trigger. Calls Game.level_complete() (which stops the
## run timer then emits level_completed) when the player enters for the
## first time. The level script listens to level_completed and shows
## its ResultsPanel overlay.
##
## Wayfinding beacon: set add_beacon = true to spawn a biolume OmniLight3D
## as a child — makes the win position visible through fog from ~20 m away.
## Default false keeps all existing .tscn files unchanged.

## Enable to add a biolume OmniLight3D as a wayfinding beacon at this trigger.
@export var add_beacon: bool = false
## Beacon light range (m). 14 m reads through fog density ≤ 0.065 at ~20 m.
@export_range(4.0, 20.0, 0.5) var beacon_range: float = 14.0
## Beacon energy. 2.0 is legible at distance without washing nearby surfaces.
@export_range(0.5, 4.0, 0.1) var beacon_energy: float = 2.0

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if add_beacon:
		_build_beacon()


func _build_beacon() -> void:
	var light := OmniLight3D.new()
	# Biolume cyan matches DataShard glow — the colour signals "goal" to the player.
	light.light_color = Color(0.12, 0.90, 0.95)
	light.light_energy = beacon_energy
	light.omni_range = beacon_range
	light.shadow_enabled = false  # Mobile renderer: shadows on OmniLight are expensive
	add_child(light)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body is Player:
		return
	_triggered = true
	if has_node("/root/Game"):
		Game.level_complete()
