extends Node
## Audio autoload. Manages the bus hierarchy, one-shot SFX dispatch, and
## the sound_layers juice-toggle mute gate.
##
## Bus layout (created at runtime if absent):
##   Master ─┬─ Music        (background music — not muted by sound_layers)
##            ├─ SFX_Player  (player actions: jump, land, dash, respawn)
##            └─ SFX_World   (world / hazard events; muted by sound_layers)
##
## All stream vars default null (no assets yet). play_sfx(null, …) is a safe
## no-op, so every dispatch point is hot-wired and ready to accept a real
## stream the moment the audio direction is confirmed.
##
## Gate 1 event hooks:
##   on_jump()              — player._try_jump()
##   on_land(impact: float) — player._tick_timers(), just_landed frame (0..1)
##   on_collect_shard()     — data_shard._collect()
##   on_respawn_start()     — player.respawn()
##
## Kenney Sci-Fi Sounds assets (CC0) are loaded from res://assets/audio/sfx/
## by _load_sfx_streams() inside _ready(). If a file has not been imported
## yet (first Godot open after commit), load() returns null and every
## dispatch is a silent no-op — same safe-null path as before assets landed.
##
## SFX volume (0.0–2.0 linear, default 1.0) is tunable from the dev menu
## Juice → Audio — SFX section via DevMenu.audio_param_changed.

const BUS_MASTER     := &"Master"
const BUS_SFX_PLAYER := &"SFX_Player"
const BUS_SFX_WORLD  := &"SFX_World"
const BUS_MUSIC      := &"Music"

## Impact threshold separating a light land (below) from a heavy clank (above).
## Mirrors the 0-to-1 impact scale from player._tick_timers.
const LAND_HEAVY_THRESHOLD := 0.25

# One AudioStream per event — null at declaration, populated in _ready()
# via _load_sfx_streams(). play_sfx(null) is a safe no-op so headless tests
# and pre-import first-runs remain silent rather than erroring.
var _sfx_jump:          AudioStream = null
var _sfx_land_light:    AudioStream = null
var _sfx_land_heavy:    AudioStream = null
var _sfx_collect_shard: AudioStream = null
var _sfx_respawn_start: AudioStream = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(BUS_MUSIC,      BUS_MASTER)
	_ensure_bus(BUS_SFX_PLAYER, BUS_MASTER)
	_ensure_bus(BUS_SFX_WORLD,  BUS_MASTER)
	_load_sfx_streams()
	if has_node("/root/DevMenu"):
		DevMenu.juice_toggle_changed.connect(_on_juice_toggle)
		_apply_sound_layers(DevMenu.is_juice_on(&"sound_layers"))
		DevMenu.audio_param_changed.connect(_on_audio_param_changed)


func _load_sfx_streams() -> void:
	_sfx_jump          = load("res://assets/audio/sfx/jump.ogg")
	_sfx_land_light    = load("res://assets/audio/sfx/land_light.ogg")
	_sfx_land_heavy    = load("res://assets/audio/sfx/land_heavy.ogg")
	_sfx_collect_shard = load("res://assets/audio/sfx/collect_shard.ogg")
	_sfx_respawn_start = load("res://assets/audio/sfx/respawn_start.ogg")


## Creates a bus if it doesn't already exist and routes it to parent_name.
func _ensure_bus(bus_name: StringName, parent_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus(-1)
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, parent_name)


func _on_juice_toggle(toggle_name: StringName, enabled: bool) -> void:
	if toggle_name == &"sound_layers":
		_apply_sound_layers(enabled)


func _apply_sound_layers(enabled: bool) -> void:
	var sfx_p := AudioServer.get_bus_index(BUS_SFX_PLAYER)
	var sfx_w := AudioServer.get_bus_index(BUS_SFX_WORLD)
	if sfx_p >= 0:
		AudioServer.set_bus_mute(sfx_p, not enabled)
	if sfx_w >= 0:
		AudioServer.set_bus_mute(sfx_w, not enabled)


## Plays a one-shot sound on the given bus. No-op if stream is null.
func play_sfx(stream: AudioStream, bus: StringName = BUS_SFX_PLAYER) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# ── event dispatch ─────────────────────────────────────────────────────────

func on_jump() -> void:
	play_sfx(_sfx_jump, BUS_SFX_PLAYER)


## impact is 0..1. Below LAND_HEAVY_THRESHOLD plays the light tap;
## at or above plays the heavy clank.
func on_land(impact: float) -> void:
	if impact < LAND_HEAVY_THRESHOLD:
		play_sfx(_sfx_land_light, BUS_SFX_PLAYER)
	else:
		play_sfx(_sfx_land_heavy, BUS_SFX_PLAYER)


func on_collect_shard() -> void:
	play_sfx(_sfx_collect_shard, BUS_SFX_PLAYER)


func on_respawn_start() -> void:
	play_sfx(_sfx_respawn_start, BUS_SFX_PLAYER)


func _on_audio_param_changed(param: StringName, value: float) -> void:
	match param:
		&"sfx_volume":
			var idx := AudioServer.get_bus_index(BUS_SFX_PLAYER)
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value))
