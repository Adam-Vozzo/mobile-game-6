extends CanvasLayer
## Always-on corner HUD. Independent of the dev-menu open/close state;
## controlled by DevMenu.debug_viz_state (toggled from the Debug viz section).
##
## perf_hud    — FPS + frametime in top-right corner. Default ON.
## velocity_vec — player velocity + on-floor state below perf. Default OFF.

var _perf_label: Label
var _state_label: Label


func _ready() -> void:
	layer = 98  # below dev menu panel (100) so it never occludes controls
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	if has_node("/root/DevMenu"):
		DevMenu.debug_viz_changed.connect(_on_viz_changed)
	_perf_label.visible = DevMenu.is_debug_viz_on(&"perf_hud")
	_state_label.visible = DevMenu.is_debug_viz_on(&"velocity_vec")


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_perf_label = Label.new()
	_perf_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_perf_label.offset_left = -190
	_perf_label.offset_right = -8
	_perf_label.offset_top = 8
	_perf_label.offset_bottom = 36
	_perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_perf_label.add_theme_font_size_override("font_size", 13)
	root.add_child(_perf_label)

	_state_label = Label.new()
	_state_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_state_label.offset_left = -190
	_state_label.offset_right = -8
	_state_label.offset_top = 40
	_state_label.offset_bottom = 92
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_state_label.add_theme_font_size_override("font_size", 11)
	root.add_child(_state_label)


func _process(_delta: float) -> void:
	if _perf_label.visible:
		var snap := PerfBudget.snapshot()
		_perf_label.text = "%d fps  %.1fms" % [
			int(snap.get("fps", 0)),
			float(snap.get("frametime_ms", 0.0)),
		]
	if _state_label.visible:
		var player := _find_player()
		if player != null and player is CharacterBody3D:
			var cb := player as CharacterBody3D
			var v := cb.velocity
			_state_label.text = "%.1f %.1f %.1f\n%s" % [
				v.x, v.y, v.z,
				"floor" if cb.is_on_floor() else "air",
			]
		else:
			_state_label.text = "(no player)"


func _find_player() -> Node3D:
	if not is_inside_tree():
		return null
	var group := get_tree().get_nodes_in_group(&"player")
	if group.size() > 0:
		return group[0] as Node3D
	return null


func _on_viz_changed(key: StringName, enabled: bool) -> void:
	match key:
		&"perf_hud":
			_perf_label.visible = enabled
		&"velocity_vec":
			_state_label.visible = enabled
