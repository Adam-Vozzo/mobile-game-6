extends Node
## Dev menu autoload. Owns the overlay scene and broadcasts changes via
## signals so gameplay code can react live without polling.
##
## Toggle: F1 in editor, 3-finger tap on device.

const OVERLAY_SCENE := preload("res://tools/dev_menu/dev_menu_overlay.tscn")
const HUD_OVERLAY_SCRIPT := preload("res://tools/debug/hud_overlay.gd")

# Signals are emitted from the dev menu overlay scene (which lives outside this
# autoload) and consumed by gameplay code. The autoload itself only declares
# them so listeners can connect via the global namespace.
@warning_ignore("unused_signal")
signal controller_profile_changed(profile_resource: Resource)
@warning_ignore("unused_signal")
signal controller_param_changed(param_name: StringName, value: float)
@warning_ignore("unused_signal")
signal camera_param_changed(param_name: StringName, value: float)
@warning_ignore("unused_signal")
signal juice_toggle_changed(toggle_name: StringName, enabled: bool)
@warning_ignore("unused_signal")
signal time_scale_changed(scale: float)
@warning_ignore("unused_signal")
signal teleport_requested(checkpoint_id: StringName)
@warning_ignore("unused_signal")
signal debug_viz_changed(key: StringName, enabled: bool)
@warning_ignore("unused_signal")
signal touch_param_changed(param: StringName, value: Variant)
@warning_ignore("unused_signal")
signal reposition_controls_requested
@warning_ignore("unused_signal")
signal blob_shadow_param_changed(param: StringName, value: float)
@warning_ignore("unused_signal")
signal squash_stretch_param_changed(param: StringName, value: float)
@warning_ignore("unused_signal")
signal press_param_changed(param: StringName, value: float)
@warning_ignore("unused_signal")
signal atmosphere_param_changed(param: StringName, value: Variant)
@warning_ignore("unused_signal")
signal ghost_trail_param_changed(param: StringName, value: float)
@warning_ignore("unused_signal")
signal particles_param_changed(param: StringName, value: float)

var is_open: bool = false
var juice_state: Dictionary[StringName, bool] = {
	&"screen_shake": true,
	&"hitstop": true,
	&"particles": true,
	&"motion_trails": true,
	&"squash_stretch": true,
	&"sound_layers": true,
	&"blob_shadow": true,
	&"ghost_trails": false,   # default OFF — enable once level has meaningful data
}
var debug_viz_state: Dictionary[StringName, bool] = {
	&"perf_hud": true,
	&"velocity_vec": false,
	&"collision_capsule": false,
	&"velocity_arrow": false,
	&"ground_normal": false,
	&"jump_arc": false,
	&"wall_normal": false,
	&"free_cam": false,
}

var _overlay: CanvasLayer
var _hud: CanvasLayer
var _active_touches: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Defer instantiation by one frame so the autoload graph is fully up
	# before the overlay's _ready runs (avoids ordering surprises).
	call_deferred("_install_overlay")


func _install_overlay() -> void:
	if _overlay != null:
		return
	_overlay = OVERLAY_SCENE.instantiate()
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	# Add to /root so the overlay survives scene swaps.
	get_tree().root.add_child(_overlay)
	_overlay.visible = is_open

	# Always-on corner HUD — independent of is_open, controlled by debug_viz_state.
	_hud = HUD_OVERLAY_SCRIPT.new()
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_hud)


func toggle() -> void:
	set_open(not is_open)


func set_open(open: bool) -> void:
	is_open = open
	if _overlay != null:
		_overlay.visible = is_open


func set_juice(toggle_name: StringName, enabled: bool) -> void:
	juice_state[toggle_name] = enabled
	juice_toggle_changed.emit(toggle_name, enabled)


func is_juice_on(toggle_name: StringName) -> bool:
	return juice_state.get(toggle_name, true)


func set_debug_viz(key: StringName, enabled: bool) -> void:
	debug_viz_state[key] = enabled
	debug_viz_changed.emit(key, enabled)


func is_debug_viz_on(key: StringName) -> bool:
	return debug_viz_state.get(key, false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed(&"dev_menu_toggle"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_active_touches[touch.index] = true
			if _active_touches.size() >= 3:
				toggle()
				_active_touches.clear()
				get_viewport().set_input_as_handled()
		else:
			_active_touches.erase(touch.index)
