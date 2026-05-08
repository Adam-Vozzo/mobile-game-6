extends CanvasLayer
## Dev menu overlay UI. Built programmatically — easier to maintain than
## a hand-authored .tscn and there's no theming work to lose.
##
## CLAUDE.md (Gate 0 minimum): controller profile dropdown, 3–4 live
## sliders, juice toggle stubs. Camera params section added in iteration 1.

const SNAPPY_PROFILE := preload("res://resources/profiles/snappy.tres")
const FLOATY_PROFILE := preload("res://resources/profiles/floaty.tres")
const MOMENTUM_PROFILE := preload("res://resources/profiles/momentum.tres")

var _profiles: Dictionary = {
	"Snappy": SNAPPY_PROFILE,
	"Floaty": FLOATY_PROFILE,
	"Momentum": MOMENTUM_PROFILE,
}

var _current_profile: Resource

var _profile_dropdown: OptionButton
var _slider_max_speed: HSlider
var _slider_jump_velocity: HSlider
var _slider_coyote: HSlider
var _slider_buffer: HSlider
var _juice_boxes: Dictionary = {}
var _perf_label: Label

# Camera sliders — defaults mirror camera_rig.gd @export values.
var _slider_cam_distance: HSlider
var _slider_cam_pitch: HSlider
var _slider_cam_lookahead: HSlider
var _slider_cam_vpull: HSlider
var _slider_cam_yaw_sens: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_select_profile("Snappy")


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(380, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	vbox.add_child(_make_label("Dev Menu", 20, true))

	# --- Profile ---
	vbox.add_child(_make_label("Profile", 14, true))
	var dropdown := OptionButton.new()
	for profile_name in _profiles:
		dropdown.add_item(profile_name)
	vbox.add_child(dropdown)
	_profile_dropdown = dropdown
	dropdown.item_selected.connect(_on_profile_selected)

	# --- Controller sliders ---
	vbox.add_child(_make_label("Controller", 14, true))
	_slider_max_speed = _make_slider(vbox, "Max speed",
		2.0, 20.0, 0.1, _on_max_speed_changed)
	_slider_jump_velocity = _make_slider(vbox, "Jump vel",
		4.0, 20.0, 0.1, _on_jump_velocity_changed)
	_slider_coyote = _make_slider(vbox, "Coyote (s)",
		0.0, 0.3, 0.005, _on_coyote_changed)
	_slider_buffer = _make_slider(vbox, "Buffer (s)",
		0.0, 0.3, 0.005, _on_buffer_changed)

	# --- Camera sliders ---
	vbox.add_child(_make_label("Camera", 14, true))
	_slider_cam_distance = _make_slider(vbox, "Distance",
		2.0, 15.0, 0.1, _on_cam_distance_changed)
	_slider_cam_distance.value = 6.0
	_slider_cam_pitch = _make_slider(vbox, "Pitch (deg)",
		0.0, 80.0, 0.5, _on_cam_pitch_changed)
	_slider_cam_pitch.value = 22.0
	_slider_cam_lookahead = _make_slider(vbox, "Lookahead",
		0.0, 5.0, 0.05, _on_cam_lookahead_changed)
	_slider_cam_lookahead.value = 1.2
	_slider_cam_vpull = _make_slider(vbox, "Fall pull",
		0.0, 1.0, 0.01, _on_cam_vpull_changed)
	_slider_cam_vpull.value = 0.18
	_slider_cam_yaw_sens = _make_slider(vbox, "Yaw sens",
		0.0001, 0.02, 0.0001, _on_cam_yaw_sens_changed)
	_slider_cam_yaw_sens.value = 0.005

	# --- Juice toggles ---
	vbox.add_child(_make_label("Juice", 14, true))
	var juice_grid := GridContainer.new()
	juice_grid.columns = 2
	vbox.add_child(juice_grid)
	for key in DevMenu.juice_state:
		var cb := CheckBox.new()
		cb.text = String(key).capitalize()
		cb.button_pressed = bool(DevMenu.juice_state[key])
		var captured_key := key as StringName
		cb.toggled.connect(func(pressed: bool) -> void:
			DevMenu.set_juice(captured_key, pressed))
		juice_grid.add_child(cb)
		_juice_boxes[key] = cb

	# --- Perf overlay ---
	vbox.add_child(_make_label("Performance", 14, true))
	_perf_label = Label.new()
	_perf_label.text = "—"
	vbox.add_child(_perf_label)


func _process(_delta: float) -> void:
	if not visible or _perf_label == null:
		return
	var snap: Dictionary = PerfBudget.snapshot()
	_perf_label.text = "fps %d   ft %.1f ms\ntris %d   draws %d" % [
		int(snap.get("fps", 0)),
		float(snap.get("frametime_ms", 0.0)),
		int(snap.get("triangles", 0)),
		int(snap.get("draw_calls", 0)),
	]


func _make_label(text: String, font_size: int, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if bold:
		l.add_theme_constant_override("outline_size", 0)
	return l


func _make_slider(parent: Node, label_text: String,
		mn: float, mx: float, step: float,
		on_changed: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = mn
	slider.max_value = mx
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(160, 24)
	row.add_child(slider)

	var val_label := Label.new()
	val_label.custom_minimum_size = Vector2(54, 0)
	val_label.text = "%.3f" % slider.value
	row.add_child(val_label)

	slider.value_changed.connect(func(v: float) -> void:
		val_label.text = "%.3f" % v)
	slider.value_changed.connect(on_changed)

	return slider


func _select_profile(profile_name: String) -> void:
	if not _profiles.has(profile_name):
		return
	var p: Resource = _profiles[profile_name]
	_current_profile = p
	# Sync sliders to the new profile.  value_changed fires and mutates
	# _current_profile, but the values are the same so it's harmless.
	_slider_max_speed.value = p.max_speed
	_slider_jump_velocity.value = p.jump_velocity
	_slider_coyote.value = p.coyote_time
	_slider_buffer.value = p.jump_buffer
	DevMenu.controller_profile_changed.emit(p)


func _on_profile_selected(idx: int) -> void:
	var profile_name := _profile_dropdown.get_item_text(idx)
	_select_profile(profile_name)


# --- Controller slider callbacks ---

func _on_max_speed_changed(v: float) -> void:
	if _current_profile == null:
		return
	_current_profile.max_speed = v
	DevMenu.controller_param_changed.emit(&"max_speed", v)


func _on_jump_velocity_changed(v: float) -> void:
	if _current_profile == null:
		return
	_current_profile.jump_velocity = v
	DevMenu.controller_param_changed.emit(&"jump_velocity", v)


func _on_coyote_changed(v: float) -> void:
	if _current_profile == null:
		return
	_current_profile.coyote_time = v
	DevMenu.controller_param_changed.emit(&"coyote_time", v)


func _on_buffer_changed(v: float) -> void:
	if _current_profile == null:
		return
	_current_profile.jump_buffer = v
	DevMenu.controller_param_changed.emit(&"jump_buffer", v)


# --- Camera slider callbacks ---

func _on_cam_distance_changed(v: float) -> void:
	DevMenu.camera_param_changed.emit(&"distance", v)


func _on_cam_pitch_changed(v: float) -> void:
	DevMenu.camera_param_changed.emit(&"pitch_degrees", v)


func _on_cam_lookahead_changed(v: float) -> void:
	DevMenu.camera_param_changed.emit(&"lookahead_distance", v)


func _on_cam_vpull_changed(v: float) -> void:
	DevMenu.camera_param_changed.emit(&"vertical_pull", v)


func _on_cam_yaw_sens_changed(v: float) -> void:
	DevMenu.camera_param_changed.emit(&"yaw_drag_sens", v)
