extends CanvasLayer
## Dev menu overlay UI. Built programmatically — easier to maintain than
## a hand-authored .tscn and there's no theming work to lose.
##
## CLAUDE.md (Gate 0 minimum): controller profile dropdown, live sliders,
## juice toggle stubs, camera params group. All present.
##
## Controller sliders use a unified _profile_sliders dict keyed by property
## name so _select_profile can bulk-sync all of them when switching profiles.

const SNAPPY_PROFILE   := preload("res://resources/profiles/snappy.tres")
const FLOATY_PROFILE   := preload("res://resources/profiles/floaty.tres")
const MOMENTUM_PROFILE := preload("res://resources/profiles/momentum.tres")
const ASSISTED_PROFILE := preload("res://resources/profiles/assisted.tres")

var _profiles: Dictionary[String, Resource] = {
	"Snappy":   SNAPPY_PROFILE,
	"Floaty":   FLOATY_PROFILE,
	"Momentum": MOMENTUM_PROFILE,
	"Assisted": ASSISTED_PROFILE,
}

var _current_profile: Resource

var _profile_dropdown: OptionButton
## All controller-param sliders keyed by ControllerProfile property StringName.
## _select_profile iterates this to bulk-sync when switching profiles.
var _profile_sliders: Dictionary[StringName, HSlider] = {}
var _slider_time_scale: HSlider
var _juice_boxes: Dictionary[StringName, Button] = {}
var _perf_label: Label
var _save_as_row: HBoxContainer
var _save_name_field: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_select_profile("Snappy")


## Width of the menu panel as a fraction of the viewport width. The panel is
## anchored to the right edge and fills the full screen height; the scroll
## container inside handles overflow so the sliders themselves can be large.
const PANEL_WIDTH_FRAC := 0.40
## Base font size applied to every control inside the panel via a Theme.
## Slider rows scale around this — bump it to scale the whole menu.
const BASE_FONT_SIZE := 24
## Section header (e.g., "Camera", "Controller — Movement") font size.
const SECTION_FONT_SIZE := 28
## Top-level "Dev Menu" title font size.
const TITLE_FONT_SIZE := 36

func _build_ui() -> void:
	var panel := PanelContainer.new()
	# Anchor to the full right side. Left anchor < 1 sets the panel width as a
	# fraction of the viewport; offsets stay zero so the panel resizes with the
	# window.
	panel.anchor_left = 1.0 - PANEL_WIDTH_FRAC
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.theme = _build_theme()
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	vbox.add_child(_make_label("Dev Menu", TITLE_FONT_SIZE, true))
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
	vbox.add_child(_make_label("Profile", SECTION_FONT_SIZE, true))
	_profile_dropdown = OptionButton.new()
	_profile_dropdown.custom_minimum_size = Vector2(0, 64)
	for profile_name: String in _profiles:
		_profile_dropdown.add_item(profile_name)
	vbox.add_child(_profile_dropdown)
	_profile_dropdown.item_selected.connect(_on_profile_selected)

	_make_button(vbox, "Save as…", _toggle_save_row)

	_save_as_row = HBoxContainer.new()
	_save_as_row.add_theme_constant_override("separation", 12)
	vbox.add_child(_save_as_row)

	_save_name_field = LineEdit.new()
	_save_name_field.placeholder_text = "profile name"
	_save_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_name_field.custom_minimum_size = Vector2(0, 64)
	_save_as_row.add_child(_save_name_field)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size = Vector2(0, 64)
	save_btn.pressed.connect(_on_save_confirmed)
	_save_as_row.add_child(save_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "✕"
	cancel_btn.custom_minimum_size = Vector2(64, 64)
	cancel_btn.pressed.connect(func() -> void: _save_as_row.visible = false)
	_save_as_row.add_child(cancel_btn)

	_save_as_row.visible = false


func _build_controller_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	_build_controller_movement(vbox)
	_build_controller_jump(vbox)
	_build_controller_respawn(vbox)
	_build_controller_slope(vbox)
	_build_controller_assist(vbox)


func _build_controller_movement(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Movement", SECTION_FONT_SIZE, true))
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
	vbox.add_child(_make_label("Controller — Jump", SECTION_FONT_SIZE, true))
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
	_profile_sliders[&"air_jumps"] = _make_profile_slider(vbox,
		"Air jumps",          0.0,    3.0,  1.0,  &"air_jumps")
	_profile_sliders[&"air_jump_velocity_multiplier"] = _make_profile_slider(vbox,
		"Air jump vel ×",     0.3,    1.2,  0.05, &"air_jump_velocity_multiplier")
	_profile_sliders[&"air_jump_horizontal_preserve"] = _make_profile_slider(vbox,
		"Air jump H pres.",   0.0,    1.0,  0.05, &"air_jump_horizontal_preserve")



func _build_controller_respawn(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Respawn", SECTION_FONT_SIZE, true))
	_profile_sliders[&"reboot_duration"] = _make_profile_slider(vbox,
		"Reboot dur (s)",     0.05,   1.5,  0.05, &"reboot_duration")
	_profile_sliders[&"fall_kill_y"] = _make_profile_slider(vbox,
		"Fall kill Y",      -200.0,   0.0,  0.5,  &"fall_kill_y")


func _build_controller_slope(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Slope", SECTION_FONT_SIZE, true))
	_profile_sliders[&"max_floor_angle_degrees"] = _make_profile_slider(vbox,
		"Max floor°",         20.0,  70.0,  1.0,  &"max_floor_angle_degrees")


func _build_controller_assist(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Controller — Assist", SECTION_FONT_SIZE, true))
	_profile_sliders[&"landing_sticky_factor"] = _make_profile_slider(vbox,
		"Sticky factor",       0.0,   0.8,  0.05, &"landing_sticky_factor")
	_profile_sliders[&"landing_sticky_frames"] = _make_profile_slider(vbox,
		"Sticky frames",       0.0,   6.0,  1.0,  &"landing_sticky_frames")


func _build_camera_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Camera", SECTION_FONT_SIZE, true))
	_make_cam_slider(vbox, "Distance",        &"distance",           2.0,   15.0,  0.1,   6.0)
	_make_cam_slider(vbox, "Pitch (deg)",     &"pitch_degrees",      0.0,   80.0,  0.5,  22.0)
	_make_cam_slider(vbox, "Fall pull",       &"vertical_pull",      0.0,    1.0,  0.01,  0.18)
	_make_cam_slider(vbox, "Yaw sens",        &"yaw_drag_sens",      0.001,  0.05, 0.001, 0.005)
	_make_cam_slider(vbox, "Pitch sens",      &"pitch_drag_sens",    0.001,  0.05, 0.001, 0.003)
	_make_cam_slider(vbox, "Occl. margin",    &"occlusion_margin",   0.1,    1.0,  0.05,  0.3)

	vbox.add_child(_make_label("Camera — Tuning", SECTION_FONT_SIZE, true))
	_make_cam_slider(vbox, "Aim height",      &"aim_height",          0.0,   3.0,  0.05,  0.6)
	_make_cam_slider(vbox, "Pitch max deg",   &"pitch_max_degrees",   0.0,  89.0,  1.0,   55.0)
	# Vertical-follow ratchet: multiplier on the active profile's default
	# jump apex. Camera holds Y while player is within this band above the
	# reference floor; above the band the camera tracks Y. 0 reverts to
	# always-track-Y (legacy behaviour); ~1 is "ignore normal jumps".
	_make_cam_slider(vbox, "Apex multiplier", &"apex_height_multiplier", 0.0, 5.0, 0.05, 1.15)
	# Reference-floor smoothing: rate (per second) at which the camera eases
	# up/down to a new floor when the player lands on a different tier.
	# 0 = instant snap (the pre-fix behaviour); default 6 ≈ 400 ms settle.
	_make_cam_slider(vbox, "Floor smoothing", &"reference_floor_smoothing", 0.0, 30.0, 0.5, 6.0)
	# Floor snap threshold: Y delta beyond which the floor still snaps
	# instantly. Handles respawn and very long falls where a slow ease
	# would read as broken / camera-stuck.
	_make_cam_slider(vbox, "Floor snap thresh", &"reference_floor_snap_threshold", 0.5, 30.0, 0.5, 8.0)
	# Pitch min, lookahead, recenter sliders removed — tripod camera doesn't use them.


func _build_level_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Level", SECTION_FONT_SIZE, true))
	_slider_time_scale = _make_slider(vbox, "Time scale ×",
		0.25, 2.0, 0.05,
		func(v: float) -> void:
			Engine.time_scale = v
			DevMenu.time_scale_changed.emit(v),
		1.0)


func _build_touch_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Touch Controls", SECTION_FONT_SIZE, true))
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
	vbox.add_child(_make_label("Juice", SECTION_FONT_SIZE, true))
	var juice_grid := GridContainer.new()
	juice_grid.columns = 2
	juice_grid.add_theme_constant_override("h_separation", 12)
	juice_grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(juice_grid)
	for key: StringName in DevMenu.juice_state:
		var captured_key := key
		var btn := _make_toggle(juice_grid, String(key).capitalize(),
			DevMenu.juice_state[key],
			func(pressed: bool) -> void: DevMenu.set_juice(captured_key, pressed))
		_juice_boxes[key] = btn
	_build_blob_shadow_tuning(vbox)
	_build_squash_stretch_tuning(vbox)


func _build_blob_shadow_tuning(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Blob Shadow — Tuning", SECTION_FONT_SIZE, false))
	_make_blob_slider(vbox, "Radius ground",  &"radius_at_ground",  0.05, 1.0,  0.01, 0.22)
	_make_blob_slider(vbox, "Radius height",  &"radius_at_height",  0.1,  2.0,  0.01, 0.55)
	_make_blob_slider(vbox, "Fade height",    &"fade_height",        1.0,  20.0, 0.5,  6.0)
	_make_blob_slider(vbox, "Max alpha",      &"alpha_max",          0.05, 1.0,  0.01, 0.42)


func _build_debug_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Debug viz", SECTION_FONT_SIZE, true))
	_make_viz_checkbox(vbox, "Perf HUD (corner)",  &"perf_hud")
	_make_viz_checkbox(vbox, "Velocity + state",   &"velocity_vec")
	_make_viz_checkbox(vbox, "Collision capsule",  &"collision_capsule")
	_make_viz_checkbox(vbox, "Velocity arrow",     &"velocity_arrow")
	_make_viz_checkbox(vbox, "Ground normal",      &"ground_normal")
	_make_viz_checkbox(vbox, "Jump arc",           &"jump_arc")


func _build_perf_section(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_sep())
	vbox.add_child(_make_label("Performance", SECTION_FONT_SIZE, true))
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

# Theme applied to the whole panel so every Label/Button/CheckBox/etc. picks
# up the larger font size + content padding without per-widget overrides.
func _build_theme() -> Theme:
	var t := Theme.new()
	for cls in ["Label", "Button", "OptionButton", "CheckBox", "LineEdit"]:
		t.set_font_size("font_size", cls, BASE_FONT_SIZE)
	# Vertical padding for buttons / option buttons / line edits so they have
	# breathing room around the larger text.
	for cls in ["Button", "OptionButton", "LineEdit"]:
		t.set_constant("h_separation", cls, 16)
	return t


func _make_label(text: String, font_size: int, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if bold:
		l.add_theme_constant_override("outline_size", 0)
	return l


func _make_sep() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 12)
	return sep


func _make_button(parent: Node, label_text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 64)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


## Pass initial_value to show a start value without firing on_changed.
func _make_slider(parent: Node, label_text: String,
		mn: float, mx: float, step: float,
		on_changed: Callable, initial_value: float = NAN) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(240, 64)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = mn
	slider.max_value = mx
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Tall track makes the entire bar a usable touch target — the grabber
	# itself stays default-sized but anywhere on the row registers.
	slider.custom_minimum_size = Vector2(320, 64)
	row.add_child(slider)

	# Set before connecting so value_changed fires with no listeners → silent.
	if not is_nan(initial_value):
		slider.value = initial_value

	var val_label := Label.new()
	val_label.custom_minimum_size = Vector2(110, 64)
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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


## Blob-shadow-param slider: initial value matches @export_range defaults in
## blob_shadow.gd — the slider and the Inspector are parallel entry points
## for the same @export vars; the signal keeps them in sync at runtime.
func _make_blob_slider(parent: Node, label_text: String, param: StringName,
		mn: float, mx: float, step: float, default_val: float) -> void:
	_make_slider(parent, label_text, mn, mx, step,
		func(v: float) -> void: DevMenu.blob_shadow_param_changed.emit(param, v),
		default_val)


func _build_squash_stretch_tuning(vbox: VBoxContainer) -> void:
	vbox.add_child(_make_label("Squash-Stretch — Tuning", SECTION_FONT_SIZE, false))
	_make_squash_slider(vbox, "Impact scale",  &"impact_squash_scale", 0.0, 1.0, 0.01, 0.5)
	_make_squash_slider(vbox, "Stretch scale", &"jump_stretch_scale",  0.0, 1.0, 0.01, 0.5)


func _make_squash_slider(parent: Node, label_text: String, param: StringName,
		mn: float, mx: float, step: float, default_val: float) -> void:
	_make_slider(parent, label_text, mn, mx, step,
		func(v: float) -> void: DevMenu.squash_stretch_param_changed.emit(param, v),
		default_val)


func _make_viz_checkbox(parent: Node, label_text: String, key: StringName) -> void:
	_make_toggle(parent, label_text, DevMenu.is_debug_viz_on(key),
		func(pressed: bool) -> void: DevMenu.set_debug_viz(key, pressed))


# Custom toggle button — replaces CheckBox so the tap target scales with the
# rest of the menu (CheckBox icons in Godot don't follow font_size). Uses the
# Button's toggle_mode and shows ●/○ + a colour swap so the on/off state is
# visible regardless of the underlying StyleBox.
const _TOGGLE_ON_COLOR  := Color(0.55, 0.95, 0.55)
const _TOGGLE_OFF_COLOR := Color(0.65, 0.65, 0.7)

func _make_toggle(parent: Node, label_text: String, initial_pressed: bool,
		on_toggled: Callable) -> Button:
	var btn := Button.new()
	btn.toggle_mode = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 64)
	btn.button_pressed = initial_pressed
	_refresh_toggle(btn, label_text)
	btn.toggled.connect(func(pressed: bool) -> void:
		_refresh_toggle(btn, label_text)
		on_toggled.call(pressed))
	parent.add_child(btn)
	return btn


func _refresh_toggle(btn: Button, label_text: String) -> void:
	var on := btn.button_pressed
	btn.text = ("  ●  " if on else "  ○  ") + label_text
	var col := _TOGGLE_ON_COLOR if on else _TOGGLE_OFF_COLOR
	# Override every state's font color so the indicator stays visible whether
	# the button is sitting in normal, hover, or pressed (toggle-on) styling.
	for state in ["font_color", "font_pressed_color", "font_hover_color",
			"font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(state, col)


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
	var profile_name := _save_name_field.text.strip_edges()
	if profile_name.is_empty():
		return
	var new_p: Resource = _current_profile.duplicate(true)
	_profiles[profile_name] = new_p
	_profile_dropdown.add_item(profile_name)
	_profile_dropdown.selected = _profile_dropdown.item_count - 1
	_save_as_row.visible = false
	# Persist to user://profiles/ so it survives the session.
	DirAccess.make_dir_recursive_absolute("user://profiles")
	ResourceSaver.save(new_p, "user://profiles/" + profile_name + ".tres")
	# Switch to the saved copy so subsequent slider edits affect it, not the
	# original. OptionButton.selected = n does NOT emit item_selected, so we
	# must call _select_profile explicitly.
	_select_profile(profile_name)


# ---- profile logic ----------------------------------------------------------

func _select_profile(profile_name: String) -> void:
	if not _profiles.has(profile_name):
		return
	var p: Resource = _profiles[profile_name]
	_current_profile = p
	# Bulk-sync all sliders to the new profile's values.
	for prop: StringName in _profile_sliders:
		var val: Variant = p.get(prop)
		if val != null:
			_profile_sliders[prop].value = float(val)
	DevMenu.controller_profile_changed.emit(p)


func _on_profile_selected(idx: int) -> void:
	_select_profile(_profile_dropdown.get_item_text(idx))
