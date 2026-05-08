extends CanvasLayer
## Dev menu overlay UI. Built programmatically — easier to maintain than
## a hand-authored .tscn and there's no theming work to lose.
##
## CLAUDE.md (Gate 0 minimum): controller profile dropdown, 3–4 live sliders,
## juice toggle stubs. Additional sections: camera params, extra controller
## tunables, perf HUD toggle. See PLAN.md for still-queued items.

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

# Controller sliders
var _sl_max_speed: HSlider
var _sl_jump_velocity: HSlider
var _sl_coyote: HSlider
var _sl_buffer: HSlider
var _sl_gravity_rising: HSlider
var _sl_gravity_falling: HSlider
var _sl_gravity_apex: HSlider
var _sl_release_ratio: HSlider

# Camera sliders
var _sl_cam_distance: HSlider
var _sl_cam_pitch: HSlider
var _sl_cam_fov: HSlider
var _sl_cam_lookahead: HSlider
var _sl_cam_vert_pull: HSlider
var _sl_cam_yaw_sens: HSlider
var _sl_cam_pitch_sens: HSlider
var _sl_cam_recenter_delay: HSlider
var _sl_cam_recenter_speed: HSlider

var _juice_boxes: Dictionary = {}
var _perf_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_select_profile("Snappy")


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	scroll.position = Vector2(20, 20)
	scroll.custom_minimum_size = Vector2(400, 640)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	vbox.add_child(_make_label("DEV MENU", 18, true))
	_build_controller_section(vbox)
	_build_camera_section(vbox)
	_build_juice_section(vbox)
	_build_perf_section(vbox)


func _build_controller_section(parent: VBoxContainer) -> void:
	parent.add_child(_make_separator())
	parent.add_child(_make_label("Controller", 14, true))

	_profile_dropdown = OptionButton.new()
	for profile_name in _profiles:
		_profile_dropdown.add_item(profile_name)
	parent.add_child(_profile_dropdown)
	_profile_dropdown.item_selected.connect(_on_profile_selected)

	_sl_max_speed = _make_slider(parent, "Max speed",
		2.0, 20.0, 0.1, _on_max_speed_changed)
	_sl_jump_velocity = _make_slider(parent, "Jump velocity",
		4.0, 20.0, 0.1, _on_jump_velocity_changed)
	_sl_coyote = _make_slider(parent, "Coyote (s)",
		0.0, 0.3, 0.005, _on_coyote_changed)
	_sl_buffer = _make_slider(parent, "Buffer (s)",
		0.0, 0.3, 0.005, _on_buffer_changed)
	_sl_gravity_rising = _make_slider(parent, "Grav rising",
		10.0, 80.0, 0.5, _on_gravity_rising_changed)
	_sl_gravity_falling = _make_slider(parent, "Grav falling",
		10.0, 80.0, 0.5, _on_gravity_falling_changed)
	_sl_gravity_apex = _make_slider(parent, "Grav apex",
		10.0, 100.0, 0.5, _on_gravity_apex_changed)
	_sl_release_ratio = _make_slider(parent, "Release ratio",
		0.1, 1.0, 0.01, _on_release_ratio_changed)


func _build_camera_section(parent: VBoxContainer) -> void:
	parent.add_child(_make_separator())
	parent.add_child(_make_label("Camera", 14, true))

	_sl_cam_distance = _make_slider(parent, "Distance",
		2.0, 15.0, 0.1, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"distance", v))
	_sl_cam_distance.value = 6.0

	_sl_cam_pitch = _make_slider(parent, "Pitch (°)",
		0.0, 80.0, 0.5, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"pitch_degrees", v))
	_sl_cam_pitch.value = 22.0

	_sl_cam_fov = _make_slider(parent, "FOV",
		40.0, 120.0, 1.0, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"fov", v))
	_sl_cam_fov.value = 60.0

	_sl_cam_lookahead = _make_slider(parent, "Lookahead",
		0.0, 5.0, 0.05, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"lookahead_distance", v))
	_sl_cam_lookahead.value = 1.2

	_sl_cam_vert_pull = _make_slider(parent, "Vert pull",
		0.0, 1.0, 0.01, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"vertical_pull", v))
	_sl_cam_vert_pull.value = 0.18

	_sl_cam_yaw_sens = _make_slider(parent, "Yaw sens",
		0.001, 0.02, 0.0005, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"yaw_drag_sens", v))
	_sl_cam_yaw_sens.value = 0.005

	_sl_cam_pitch_sens = _make_slider(parent, "Pitch sens",
		0.001, 0.02, 0.0005, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"pitch_drag_sens", v))
	_sl_cam_pitch_sens.value = 0.003

	_sl_cam_recenter_delay = _make_slider(parent, "Recenter dly",
		0.0, 5.0, 0.05, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"idle_recenter_delay", v))
	_sl_cam_recenter_delay.value = 1.2

	_sl_cam_recenter_speed = _make_slider(parent, "Recenter spd",
		0.1, 10.0, 0.1, func(v: float) -> void:
			DevMenu.camera_param_changed.emit(&"idle_recenter_speed", v))
	_sl_cam_recenter_speed.value = 1.5


func _build_juice_section(parent: VBoxContainer) -> void:
	parent.add_child(_make_separator())
	parent.add_child(_make_label("Juice", 14, true))

	var juice_grid := GridContainer.new()
	juice_grid.columns = 2
	parent.add_child(juice_grid)

	for key in DevMenu.juice_state:
		var cb := CheckBox.new()
		cb.text = String(key).capitalize()
		cb.button_pressed = bool(DevMenu.juice_state[key])
		var captured_key := key as StringName
		cb.toggled.connect(func(pressed: bool) -> void:
			DevMenu.set_juice(captured_key, pressed))
		juice_grid.add_child(cb)
		_juice_boxes[key] = cb


func _build_perf_section(parent: VBoxContainer) -> void:
	parent.add_child(_make_separator())
	parent.add_child(_make_label("Performance", 14, true))

	_perf_label = Label.new()
	_perf_label.text = "—"
	parent.add_child(_perf_label)

	var hud_btn := Button.new()
	hud_btn.text = "Toggle Perf HUD"
	hud_btn.pressed.connect(func() -> void: DevMenu.toggle_perf_hud())
	parent.add_child(hud_btn)


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


# ---------- helpers ----------

func _make_label(text: String, font_size: int, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if bold:
		l.add_theme_constant_override("outline_size", 0)
	return l


func _make_separator() -> HSeparator:
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
	slider.custom_minimum_size = Vector2(150, 24)
	row.add_child(slider)

	var val_label := Label.new()
	val_label.custom_minimum_size = Vector2(54, 0)
	val_label.text = "%.3f" % slider.value
	row.add_child(val_label)

	slider.value_changed.connect(func(v: float) -> void:
		val_label.text = "%.3f" % v)
	slider.value_changed.connect(on_changed)

	return slider


# ---------- profile management ----------

func _select_profile(profile_name: String) -> void:
	if not _profiles.has(profile_name):
		return
	var p: Resource = _profiles[profile_name]
	_current_profile = p
	# Sync all controller sliders (fires value_changed which writes back to the
	# resource — harmless, same value, same object).
	_sl_max_speed.value = p.max_speed
	_sl_jump_velocity.value = p.jump_velocity
	_sl_coyote.value = p.coyote_time
	_sl_buffer.value = p.jump_buffer
	_sl_gravity_rising.value = p.gravity_rising
	_sl_gravity_falling.value = p.gravity_falling
	_sl_gravity_apex.value = p.gravity_after_apex
	_sl_release_ratio.value = p.release_velocity_ratio
	DevMenu.controller_profile_changed.emit(p)


func _on_profile_selected(idx: int) -> void:
	_select_profile(_profile_dropdown.get_item_text(idx))


# ---------- controller param callbacks ----------

func _on_max_speed_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.max_speed = v
		DevMenu.controller_param_changed.emit(&"max_speed", v)


func _on_jump_velocity_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.jump_velocity = v
		DevMenu.controller_param_changed.emit(&"jump_velocity", v)


func _on_coyote_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.coyote_time = v
		DevMenu.controller_param_changed.emit(&"coyote_time", v)


func _on_buffer_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.jump_buffer = v
		DevMenu.controller_param_changed.emit(&"jump_buffer", v)


func _on_gravity_rising_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.gravity_rising = v
		DevMenu.controller_param_changed.emit(&"gravity_rising", v)


func _on_gravity_falling_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.gravity_falling = v
		DevMenu.controller_param_changed.emit(&"gravity_falling", v)


func _on_gravity_apex_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.gravity_after_apex = v
		DevMenu.controller_param_changed.emit(&"gravity_after_apex", v)


func _on_release_ratio_changed(v: float) -> void:
	if _current_profile != null:
		_current_profile.release_velocity_ratio = v
		DevMenu.controller_param_changed.emit(&"release_velocity_ratio", v)
