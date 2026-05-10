extends CanvasLayer
## Dev menu overlay UI. Built programmatically — easier to maintain than
## a hand-authored .tscn and there's no theming work to lose.
##
## CLAUDE.md (Gate 0 minimum): controller profile dropdown, live sliders,
## juice toggle stubs, camera params group. All present.
##
## Controller sliders use a unified _profile_sliders dict keyed by property
## name so _select_profile can bulk-sync all of them when switching profiles.

const SNAPPY_PROFILE := preload("res://resources/profiles/snappy.tres")
const FLOATY_PROFILE := preload("res://resources/profiles/floaty.tres")
const MOMENTUM_PROFILE := preload("res://resources/profiles/momentum.tres")

## Panel / scroll sizing.
const _PANEL_W    := 400.0
const _SCROLL_H   := 600.0
const _SECTION_SEP := 6

## Slider row column widths — label | track | value. Sum (324) fits in _PANEL_W.
const _SL_LABEL_W := 110.0
const _SL_TRACK_W := 160.0
const _SL_TRACK_H := 24.0
const _SL_VAL_W   := 54.0

var _profiles: Dictionary = {
	"Snappy": SNAPPY_PROFILE,
	"Floaty": FLOATY_PROFILE,
	"Momentum": MOMENTUM_PROFILE,
}

var _current_profile: Resource

var _profile_dropdown: OptionButton
## All controller-param sliders keyed by ControllerProfile property StringName.
## _select_profile iterates this to bulk-sync when switching profiles.
var _profile_sliders: Dictionary = {}
var _slider_time_scale: HSlider
var _juice_boxes: Dictionary = {}
var _perf_label: Label
var _save_as_row: HBoxContainer
var _save_name_field: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_select_profile("Snappy")


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(_PANEL_W, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(_PANEL_W, _SCROLL_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", _SECTION_SEP)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	vbox.add_child(_make_label("Dev Menu", 20, true))
	_build_profile_section(vbox)
	_build_controller_section(vbox)
	_build_camera_section(vbox)
	_build_level_section(vbox)
	_build_touch_section(vbox)
	_build_juice_section(vbox)
	_build_debug_section(vbox)
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

	_make_button(vbox, "Save as…", _toggle_save_row)

	_save_as_row = HBoxContainer.new()
	vbox.add_child(_save_as_row)

	_save_name_field = LineEdit.new()
	_save_name_field.placeholder_text = "profile name"
	_save_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_as_row.add_child(_save_name_field)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_confirmed)
	_save_as_row.add_child(save_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "✕"
	cancel_btn.pressed.connect(func() -> void: _save_as_row.visible = false)
	_save_as_row.add_child(cancel_btn)

	_save_as_row.visible = false


func _build_controller_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	_build_controller_movement(vbox)
	_build_controller_jump(vbox)
	_build_controller_respawn(vbox)
	_build_controller_slope(vbox)


func _build_controller_movement(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Movement", 14, true))
	_profile_sliders[&"max_speed"] = _make_profile_slider(vbox,
		"Max speed",          2.0,   20.0,  0.1,  &"max_speed")
	_profile_sliders[&"ground_acceleration"] = _make_profile_slider(vbox,
		"Ground accel",      10.0,  200.0,  1.0,  &"ground_acceleration")
	_profile_sliders[&"ground_deceleration"] = _make_profile_slider(vbox,
		"Ground decel",      10.0,  200.0,  1.0,  &"ground_deceleration")
	_profile_sliders[&"air_acceleration"] = _make_profile_slider(vbox,
		"Air accel",          5.0,  200.0,  1.0,  &"air_acceleration")
	_profile_sliders[&"air_horizontal_damping"] = _make_profile_slider(vbox,
		"Air damping",        0.0,    5.0,  0.05, &"air_horizontal_damping")


func _build_controller_jump(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Jump", 14, true))
	_profile_sliders[&"jump_velocity"] = _make_profile_slider(vbox,
		"Jump velocity",      4.0,   20.0,  0.1,  &"jump_velocity")
	_profile_sliders[&"gravity_rising"] = _make_profile_slider(vbox,
		"Gravity rising",    10.0,   80.0,  0.5,  &"gravity_rising")
	_profile_sliders[&"gravity_falling"] = _make_profile_slider(vbox,
		"Gravity falling",   10.0,   80.0,  0.5,  &"gravity_falling")
	_profile_sliders[&"gravity_after_apex"] = _make_profile_slider(vbox,
		"Gravity apex",      10.0,  100.0,  0.5,  &"gravity_after_apex")
	_profile_sliders[&"terminal_velocity"] = _make_profile_slider(vbox,
		"Terminal vel",      10.0,   60.0,  0.5,  &"terminal_velocity")
	_profile_sliders[&"coyote_time"] = _make_profile_slider(vbox,
		"Coyote (s)",         0.0,    0.3,  0.005, &"coyote_time")
	_profile_sliders[&"jump_buffer"] = _make_profile_slider(vbox,
		"Buffer (s)",         0.0,    0.3,  0.005, &"jump_buffer")
	_profile_sliders[&"release_velocity_ratio"] = _make_profile_slider(vbox,
		"Release ratio",      0.1,    1.0,  0.01, &"release_velocity_ratio")


func _build_controller_respawn(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Respawn", 14, true))
	_profile_sliders[&"reboot_duration"] = _make_profile_slider(vbox,
		"Reboot dur (s)",     0.05,   1.5,  0.05, &"reboot_duration")
	_profile_sliders[&"fall_kill_y"] = _make_profile_slider(vbox,
		"Fall kill Y",      -200.0,   0.0,  0.5,  &"fall_kill_y")


func _build_controller_slope(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Slope", 14, true))
	_profile_sliders[&"max_floor_angle_degrees"] = _make_profile_slider(vbox,
		"Max floor°",         20.0,  70.0,  1.0,  &"max_floor_angle_degrees")


func _build_camera_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Camera", 14, true))
	_make_cam_slider(vbox, "Distance",        &"distance",           2.0,   15.0,  0.1,   6.0)
	_make_cam_slider(vbox, "Pitch (deg)",     &"pitch_degrees",      0.0,   80.0,  0.5,  22.0)
	_make_cam_slider(vbox, "Lookahead",       &"lookahead_distance", 0.0,    5.0,  0.05,  1.2)
	_make_cam_slider(vbox, "Fall pull",       &"vertical_pull",      0.0,    1.0,  0.01,  0.18)
	_make_cam_slider(vbox, "Yaw sens",        &"yaw_drag_sens",      0.001,  0.05, 0.001, 0.005)
	_make_cam_slider(vbox, "Pitch sens",      &"pitch_drag_sens",    0.001,  0.05, 0.001, 0.003)
	_make_cam_slider(vbox, "Rctr delay",      &"idle_recenter_delay",0.0,    5.0,  0.1,   1.2)
	_make_cam_slider(vbox, "Rctr speed",      &"idle_recenter_speed",0.1,   10.0,  0.1,   1.5)
	_make_cam_slider(vbox, "Occl. margin",    &"occlusion_margin",   0.1,    1.0,  0.05,  0.3)

	vbox.add_child(_make_label("Camera — Tuning", 14, true))
	_make_cam_slider(vbox, "Aim height",      &"aim_height",          0.0,   3.0,  0.05,  0.6)
	_make_cam_slider(vbox, "Look lerp",       &"lookahead_lerp",      0.5,  20.0,  0.5,   4.0)
	_make_cam_slider(vbox, "Look min spd",    &"lookahead_min_speed", 0.0,   5.0,  0.05,  0.15)
	_make_cam_slider(vbox, "Pitch min deg",   &"pitch_min_degrees",  -89.0,  0.0,  1.0,  -55.0)
	_make_cam_slider(vbox, "Pitch max deg",   &"pitch_max_degrees",   0.0,  89.0,  1.0,   55.0)
	_make_cam_slider(vbox, "Rctr min spd",    &"recenter_min_speed",  0.0,  10.0,  0.1,   0.5)


func _build_level_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Level", 14, true))
	_slider_time_scale = _make_slider(vbox, "Time scale ×",
		0.25, 2.0, 0.05,
		func(v: float) -> void:
			Engine.time_scale = v
			DevMenu.time_scale_changed.emit(v),
		1.0)


func _build_touch_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Touch Controls", 14, true))
	_make_button(vbox, "Reposition controls…",
		func() -> void: DevMenu.reposition_controls_requested.emit())
	# Read actual loaded values from the touch overlay rather than using
	# hardcoded defaults. DevMenuOverlay._ready() is triggered via
	# DevMenu.call_deferred("_install_overlay"), so the full scene tree —
	# including TouchOverlay._ready() → _load_layout() — has completed
	# before this runs. Falls back to @export defaults if no overlay is
	# found (e.g. editor scenes without touch UI).
	var jump_radius := 95.0
	var stick_zone  := 0.5
	var touch_nodes := get_tree().get_nodes_in_group(&"touch_overlay")
	if not touch_nodes.is_empty():
		jump_radius = float(touch_nodes[0].get(&"jump_button_radius"))
		stick_zone  = float(touch_nodes[0].get(&"stick_zone_ratio"))
	_make_slider(vbox, "Jump radius",
		40.0, 200.0, 1.0,
		func(v: float) -> void: DevMenu.touch_param_changed.emit(&"jump_radius", v),
		jump_radius)
	_make_slider(vbox, "Stick zone %",
		0.30, 0.70, 0.01,
		func(v: float) -> void: DevMenu.touch_param_changed.emit(&"stick_zone_ratio", v),
		stick_zone)


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


func _build_debug_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Debug viz", 14, true))
	_make_viz_checkbox(vbox, "Perf HUD (corner)",  &"perf_hud")
	_make_viz_checkbox(vbox, "Velocity + state",   &"velocity_vec")
	_make_viz_checkbox(vbox, "Collision capsule",  &"collision_capsule")
	_make_viz_checkbox(vbox, "Velocity arrow",     &"velocity_arrow")
	_make_viz_checkbox(vbox, "Ground normal",      &"ground_normal")
	_make_viz_checkbox(vbox, "Jump arc",           &"jump_arc")


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


func _make_button(parent: Node, label_text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


## Pass initial_value to show a start value without firing on_changed.
func _make_slider(parent: Node, label_text: String,
		mn: float, mx: float, step: float,
		on_changed: Callable, initial_value: float = NAN) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(_SL_LABEL_W, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = mn
	slider.max_value = mx
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(_SL_TRACK_W, _SL_TRACK_H)
	row.add_child(slider)

	# Set before connecting so value_changed fires with no listeners → silent.
	if not is_nan(initial_value):
		slider.value = initial_value

	var val_label := Label.new()
	val_label.custom_minimum_size = Vector2(_SL_VAL_W, 0)
	val_label.text = _fmt(slider.value, step)
	row.add_child(val_label)

	slider.value_changed.connect(func(v: float) -> void:
		val_label.text = _fmt(v, step))
	slider.value_changed.connect(on_changed)

	return slider


## Profile-param slider: mutates the active profile resource directly (player
## reads from it each frame) and emits controller_param_changed.
func _make_profile_slider(parent: Node, label_text: String,
		mn: float, mx: float, step: float,
		prop: StringName) -> HSlider:
	return _make_slider(parent, label_text, mn, mx, step,
		func(v: float) -> void:
			if _current_profile != null:
				_current_profile.set(prop, v)
				DevMenu.controller_param_changed.emit(prop, v))


## Camera-param slider: silent init (camera rig uses its own @export defaults).
func _make_cam_slider(parent: Node, label_text: String, param: StringName,
		mn: float, mx: float, step: float, default_val: float) -> HSlider:
	return _make_slider(parent, label_text, mn, mx, step,
		func(v: float) -> void: DevMenu.camera_param_changed.emit(param, v),
		default_val)


func _make_viz_checkbox(parent: Node, label_text: String, key: StringName) -> void:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = DevMenu.is_debug_viz_on(key)
	cb.toggled.connect(func(pressed: bool) -> void:
		DevMenu.set_debug_viz(key, pressed))
	parent.add_child(cb)


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


# ---- save-as logic ----------------------------------------------------------

func _toggle_save_row() -> void:
	_save_as_row.visible = not _save_as_row.visible
	if _save_as_row.visible:
		_save_name_field.text = ""
		_save_name_field.grab_focus()


func _on_save_confirmed() -> void:
	var name := _save_name_field.text.strip_edges()
	if name.is_empty():
		return
	var new_p: Resource = _current_profile.duplicate(true)
	_profiles[name] = new_p
	_profile_dropdown.add_item(name)
	_profile_dropdown.selected = _profile_dropdown.item_count - 1
	_save_as_row.visible = false
	# Persist to user://profiles/ so it survives the session.
	DirAccess.make_dir_recursive_absolute("user://profiles")
	ResourceSaver.save(new_p, "user://profiles/" + name + ".tres")
	# Switch to the saved copy so subsequent slider edits affect it, not the
	# original. OptionButton.selected = n does NOT emit item_selected, so we
	# must call _select_profile explicitly.
	_select_profile(name)


# ---- profile logic ----------------------------------------------------------

func _select_profile(profile_name: String) -> void:
	if not _profiles.has(profile_name):
		return
	var p: Resource = _profiles[profile_name]
	_current_profile = p
	# Bulk-sync all sliders to the new profile's values.
	for prop: StringName in _profile_sliders:
		var val = p.get(prop)
		if val != null:
			_profile_sliders[prop].value = float(val)
	DevMenu.controller_profile_changed.emit(p)


func _on_profile_selected(idx: int) -> void:
	_select_profile(_profile_dropdown.get_item_text(idx))
