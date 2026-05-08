extends Node
## Dev menu autoload. Owns the in-game tweaks UI and broadcasts changes via
## signals so gameplay code can react live without polling.
##
## Toggle: F1 in editor, 3-finger tap on device (handled in dev_menu scene).
## Live tunables go through the *_changed signals so listeners don't need
## a direct reference to the menu scene.

signal controller_profile_changed(profile_resource: Resource)
signal controller_param_changed(param_name: StringName, value: float)
signal camera_param_changed(param_name: StringName, value: float)
signal juice_toggle_changed(toggle_name: StringName, enabled: bool)
signal time_scale_changed(scale: float)
signal teleport_requested(checkpoint_id: StringName)

var visible: bool = false
var juice_state: Dictionary = {
	&"screen_shake": true,
	&"hitstop": true,
	&"particles": true,
	&"motion_trails": true,
	&"squash_stretch": true,
	&"sound_layers": true,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func toggle_visible() -> void:
	visible = not visible


func set_juice(toggle_name: StringName, enabled: bool) -> void:
	juice_state[toggle_name] = enabled
	juice_toggle_changed.emit(toggle_name, enabled)


func is_juice_on(toggle_name: StringName) -> bool:
	return bool(juice_state.get(toggle_name, true))
