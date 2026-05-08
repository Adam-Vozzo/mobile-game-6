extends Node
## Audio autoload. Stub. Will own bus references, ducking rules, and
## one-shot SFX dispatch once we have actual audio assets.

const BUS_MASTER := &"Master"
const BUS_SFX_PLAYER := &"SFX_Player"
const BUS_SFX_WORLD := &"SFX_World"
const BUS_MUSIC := &"Music"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_sfx(_stream: AudioStream, _bus: StringName = BUS_SFX_WORLD) -> void:
	# Intentionally empty for kickoff. Wire up when first SFX lands.
	pass
