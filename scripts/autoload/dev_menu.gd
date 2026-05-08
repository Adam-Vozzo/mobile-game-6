extends Node
## Dev menu autoload. Owns the overlay scene and broadcasts changes via
## signals so gameplay code can react live without polling.
##
## Toggle: F1 in editor, 3-finger tap on device.
## Mini perf HUD: always-visible fps/frametime corner label, toggleable.

const OVERLAY_SCENE := preload("res://tools/dev_menu/dev_menu_overlay.tscn")

signal controller_profile_changed(profile_resource: Resource)
signal controller_param_changed(param_name: StringName, value: float)
signal camera_param_changed(param_name: StringName, value: float)
signal juice_toggle_changed(toggle_name: StringName, enabled: bool)
signal time_scale_changed(scale: float)
signal teleport_requested(checkpoint_id: StringName)

var is_open: bool = false
var juice_state: Dictionary = {
	&"screen_shake": true,
	&"hitstop": true,
	&"particles": true,
	&"motion_trails": true,
	&"squash_stretch": true,
	&"sound_layers": true,
}

var _overlay: CanvasLayer
var _active_touches: Dictionary = {}

# Mini perf HUD — separate from the overlay so it survives overlay close.
var _hud_layer: CanvasLayer
var _hud_label: Label
var _hud_visible: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_install_overlay")


func _install_overlay() -> void:
	if _overlay != null:
		return
	_overlay = OVERLAY_SCENE.instantiate()
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_overlay)
	_overlay.visible = is_open

	_build_perf_hud()


func _build_perf_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 98
	_hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_hud_layer)

	# Full-rect anchor so we can use PRESET_TOP_RIGHT.
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root_ctrl)

	_hud_label = Label.new()
	_hud_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hud_label.offset_left = -220
	_hud_label.offset_top = 8
	_hud_label.offset_right = -8
	_hud_label.offset_bottom = 56
	_hud_label.add_theme_font_size_override("font_size", 13)
	_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root_ctrl.add_child(_hud_label)


func _process(_delta: float) -> void:
	if _hud_label == null or not _hud_visible:
		return
	var snap: Dictionary = PerfBudget.snapshot()
	_hud_label.text = "%d fps  %.1f ms\n%d tris  %d dc" % [
		int(snap.get("fps", 0)),
		float(snap.get("frametime_ms", 0.0)),
		int(snap.get("triangles", 0)),
		int(snap.get("draw_calls", 0)),
	]


func toggle() -> void:
	set_open(not is_open)


func set_open(open: bool) -> void:
	is_open = open
	if _overlay != null:
		_overlay.visible = is_open


func toggle_perf_hud() -> void:
	_hud_visible = not _hud_visible
	if _hud_label != null:
		_hud_label.visible = _hud_visible


func set_juice(toggle_name: StringName, enabled: bool) -> void:
	juice_state[toggle_name] = enabled
	juice_toggle_changed.emit(toggle_name, enabled)


func is_juice_on(toggle_name: StringName) -> bool:
	return bool(juice_state.get(toggle_name, true))


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
