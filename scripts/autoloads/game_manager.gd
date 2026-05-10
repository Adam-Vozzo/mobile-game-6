extends Node

# Stub. Owns game-level state: current scene, pause, checkpoint, death count.
# Expanded in Gate 2 when a game loop exists.

enum State { PLAYING, PAUSED, DEAD }

var state: State = State.PLAYING

signal state_changed(new_state: State)

func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(new_state)

func is_playing() -> bool:
	return state == State.PLAYING
