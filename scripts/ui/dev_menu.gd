class_name DevMenu
extends Control

signal profile_changed(p: ControllerProfile)

var _profile: ControllerProfile = null
var _panel: PanelContainer
var _vbox: VBoxContainer
var _open: bool = false

func _ready() -> void:
	_build()
	_panel.visible = false
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_menu_toggle"):
		_toggle()
		get_viewport().set_input_as_handled()

func bind_profile(p: ControllerProfile) -> void:
	_profile = p
	_rebuild_sliders()

func _toggle() -> void:
	_open = not _open
	_panel.visible = _open

func _build() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Toggle button pinned to top-right corner.
	var toggle_btn := Button.new()
	toggle_btn.text = "DEV"
	toggle_btn.anchor_left = 1.0
	toggle_btn.anchor_right = 1.0
	toggle_btn.anchor_top = 0.0
	toggle_btn.anchor_bottom = 0.0
	toggle_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	toggle_btn.offset_left = -64
	toggle_btn.offset_right = 0
	toggle_btn.offset_top = 4
	toggle_btn.offset_bottom = 40
	toggle_btn.pressed.connect(_toggle)
	add_child(toggle_btn)

	# Panel: right strip, full height, 300px wide.
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -300
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_vbox)

func _rebuild_sliders() -> void:
	for ch in _vbox.get_children():
		ch.queue_free()
	if _profile == null:
		return

	_section("Movement")
	_slider("Walk Speed",     "walk_speed",               1.0,  20.0)
	_slider("Acceleration",   "acceleration",              1.0,  80.0)
	_slider("Friction",       "friction",                  1.0,  80.0)
	_slider("Air Accel",      "air_acceleration",          1.0,  40.0)
	_slider("Air Friction",   "air_friction",              0.0,  20.0)

	_section("Jump")
	_slider("Gravity",        "base_gravity",              5.0,  60.0)
	_slider("Jump Velocity",  "jump_velocity",             2.0,  25.0)
	_slider("Hold Grav",      "jump_hold_gravity_scale",   0.1,   1.5)
	_slider("Fall Grav",      "fall_gravity_scale",        1.0,   5.0)
	_slider("Max Fall Spd",   "max_fall_speed",           10.0,  60.0)

	_section("Assist")
	_slider("Coyote Time",    "coyote_time",               0.0,   0.35)
	_slider("Jump Buffer",    "jump_buffer_time",          0.0,   0.35)

	_section("Rotation")
	_slider("Turn Spd°",      "turn_speed_deg",           90.0, 1440.0)

func _section(title: String) -> void:
	var lbl := Label.new()
	lbl.text = "— %s —" % title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(lbl)

func _slider(label: String, prop: String, lo: float, hi: float) -> void:
	var row := HBoxContainer.new()
	_vbox.add_child(row)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 110
	row.add_child(lbl)

	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = (hi - lo) / 200.0
	sl.value = _profile.get(prop)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sl)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size.x = 46
	val_lbl.text = "%.2f" % sl.value
	row.add_child(val_lbl)

	sl.value_changed.connect(func(v: float) -> void:
		_profile.set(prop, v)
		val_lbl.text = "%.2f" % v
		profile_changed.emit(_profile)
	)
