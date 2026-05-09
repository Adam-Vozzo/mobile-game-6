extends CanvasLayer
## Dev menu overlay UI. Built programmatically — easier to maintain than
## a hand-authored .tscn and there's no theming work to lose.
##
## CLAUDE.md (Gate 0 minimum): controller profile dropdown, live sliders,
## juice toggle stubs, camera params group. All present.

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_select_profile("Snappy")


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(400, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	vbox.add_child(_make_label("Dev Menu", 20, true))
	_build_profile_section(vbox)
	_build_controller_section(vbox)
	_build_camera_section(vbox)
	_build_juice_section(vbox)
	_build_perf_section(vbox)


# ---- section builders -------------------------------------------------------

func _build_profile_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Profile", 14, true))
	_profile_dropdown = OptionButton.new()
	for profile_name in _profiles:
		_profile_dropdown.add_item(profile_name)
	vbox.add_child(_profile_dropdown)
	_profile_dropdown.item_selected.connect(_on_profile_selected)


func _build_controller_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Controller", 14, true))
	_slider_max_speed = _make_slider(vbox, "Max speed",
		2.0, 20.0, 0.1, _on_max_speed_changed)
	_slider_jump_velocity = _make_slider(vbox, "Jump velocity",
		4.0, 20.0, 0.1, _on_jump_velocity_changed)
	_slider_coyote = _make_slider(vbox, "Coyote (s)",
		0.0, 0.3, 0.005, _on_coyote_changed)
	_slider_buffer = _make_slider(vbox, "Buffer (s)",
		0.0, 0.3, 0.005, _on_buffer_changed)


func _build_camera_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Camera", 14, true))
	_make_cam_slider(vbox, "Distance",       &"distance",          2.0,    15.0,   0.1,    6.0)
	_make_cam_slider(vbox, "Pitch (deg)",    &"pitch_degrees",     0.0,    80.0,   0.5,    22.0)
	_make_cam_slider(vbox, "Lookahead",      &"lookahead_distance",0.0,    5.0,    0.05,   1.2)
	_make_cam_slider(vbox, "Fall pull",      &"vertical_pull",     0.0,    1.0,    0.01,   0.18)
	_make_cam_slider(vbox, "Yaw sens",       &"yaw_drag_sens",     0.001,  0.05,   0.001,  0.005)
	_make_cam_slider(vbox, "Pitch sens",     &"pitch_drag_sens",   0.001,  0.05,   0.001,  0.003)
	_make_cam_slider(vbox, "Rctr delay",     &"idle_recenter_delay",0.0,   5.0,    0.1,    1.2)
	_make_cam_slider(vbox, "Rctr speed",     &"idle_recenter_speed",0.1,   10.0,   0.1,    1.5)
	_make_cam_slider(vbox, "Occl. margin",   &"occlusion_margin",  0.1,    1.0,    0.05,   0.3)


func _build_juice_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
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


func _build_perf_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Performance", 14, true))
	_perf_label = Label.new()
	_perf_label.text = "—"
	vbox.add_child(_perf_label)


# ---- per-frame updates ------------------------------------------------------

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


# ---- widget factories -------------------------------------------------------

func _make_label(text: String, font_size: int, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if bold:
		l.add_theme_constant_override("outline_size", 0)
	return l


func _make_sep() -> HSeparator:
	return HSeparator.new()


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
	val_label.text = _fmt(slider.value, step)
	row.add_child(val_label)

	slider.value_changed.connect(func(v: float) -> void:
		val_label.text = _fmt(v, step))
	slider.value_changed.connect(on_changed)

	return slider


## Camera-param slider: fires DevMenu.camera_param_changed and sets an initial value.
func _make_cam_slider(parent: Node, label_text: String, param: StringName,
		mn: float, mx: float, step: float, default_val: float) -> HSlider:
	var slider := _make_slider(parent, label_text, mn, mx, step,
		func(v: float) -> void: DevMenu.camera_param_changed.emit(param, v))
	# Set value after connecting; value_changed will update the display label
	# and broadcast the initial default to the camera rig if it's already live.
	slider.value = default_val
	return slider


## Smart number format: enough digits to show the step resolution.
static func _fmt(v: float, step: float) -> String:
	if step >= 1.0:
		return "%d" % int(v)
	elif step >= 0.1:
		return "%.1f" % v
	elif step >= 0.01:
		return "%.2f" % v
	elif step >= 0.001:
		return "%.3f" % v
	return "%.4f" % v


# ---- profile logic ----------------------------------------------------------

func _select_profile(profile_name: String) -> void:
	if not _profiles.has(profile_name):
		return
	var p: Resource = _profiles[profile_name]
	_current_profile = p
	# Sync sliders to the new profile. value_changed fires but writes back the
	# same values the resource already holds — harmless.
	_slider_max_speed.value = p.max_speed
	_slider_jump_velocity.value = p.jump_velocity
	_slider_coyote.value = p.coyote_time
	_slider_buffer.value = p.jump_buffer
	DevMenu.controller_profile_changed.emit(p)


func _on_profile_selected(idx: int) -> void:
	_select_profile(_profile_dropdown.get_item_text(idx))


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
