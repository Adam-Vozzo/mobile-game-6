class_name DevMenu
extends CanvasLayer

## Developer tweaks overlay.
## Toggle: F1 in editor, 3-finger tap on device.
## Sections: Controller, Camera, Juice, Debug, Level.

const PROFILE_PATHS: Array[String] = [
	"res://resources/controller_profiles/profile_snappy.tres",
	"res://resources/controller_profiles/profile_floaty.tres",
	"res://resources/controller_profiles/profile_momentum.tres",
	"res://resources/controller_profiles/profile_assisted.tres",
]

@onready var _root_panel: PanelContainer = $RootPanel
@onready var _tabs: TabContainer = $RootPanel/TabContainer

# Perf bar at top.
@onready var _perf_label: Label = $RootPanel/VBox/PerfBar/PerfLabel

# Controller tab nodes — populated in _build_controller_tab.
var _profile_option: OptionButton = null
var _profile_sliders: Dictionary = {}  # property_name -> HSlider
var _loaded_profiles: Array[ControllerProfile] = []
var _active_profile_index: int = 0

# Juice toggles.
var _juice_flags: Dictionary = {}

# Debug viz flags — read by other systems.
var show_velocity_vector: bool = false
var show_collision_shapes: bool = false
var show_normals: bool = false
var show_jump_arc: bool = false
var show_frametime_overlay: bool = true

# Level controls.
var time_scale: float = 1.0

# Touch: three-finger detection.
var _touch_count: int = 0
var _touch_timer: float = 0.0


func _ready() -> void:
	layer = 100
	_load_profiles()
	_build_ui()
	hide_menu()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_F1:
			_toggle()

	if event is InputEventScreenTouch:
		var te: InputEventScreenTouch = event as InputEventScreenTouch
		if te.pressed:
			_touch_count += 1
			_touch_timer = 0.3
		else:
			_touch_count = max(0, _touch_count - 1)


func _process(delta: float) -> void:
	_touch_timer -= delta
	if _touch_timer < 0.0 and _touch_count >= 3:
		_toggle()
		_touch_count = 0

	if _root_panel.visible:
		_update_perf_label()


# ─── Visibility ───────────────────────────────────────────────────────────────

func _toggle() -> void:
	if _root_panel.visible:
		hide_menu()
	else:
		show_menu()


func show_menu() -> void:
	_root_panel.show()


func hide_menu() -> void:
	_root_panel.hide()


# ─── Profile loading ──────────────────────────────────────────────────────────

func _load_profiles() -> void:
	_loaded_profiles.clear()
	for path in PROFILE_PATHS:
		var res: Resource = load(path)
		if res is ControllerProfile:
			_loaded_profiles.append(res as ControllerProfile)
		else:
			push_warning("DevMenu: could not load profile at " + path)


# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	_build_controller_tab()
	_build_camera_tab()
	_build_juice_tab()
	_build_debug_tab()
	_build_level_tab()


func _build_controller_tab() -> void:
	var scroll: ScrollContainer = _get_tab_scroll("Controller")
	var vbox: VBoxContainer = _make_vbox(scroll)

	# Profile selector.
	_profile_option = OptionButton.new()
	for p in _loaded_profiles:
		_profile_option.add_item(p.profile_name)
	_profile_option.selected = _active_profile_index
	_profile_option.item_selected.connect(_on_profile_selected)
	vbox.add_child(_add_labeled("Profile", _profile_option))

	# Sliders for key tunables.
	var slider_defs: Array = [
		["speed",             "Speed (m/s)",       2.0,  20.0, 0.1],
		["jump_velocity",     "Jump Height (m/s)", 4.0,  20.0, 0.1],
		["coyote_time",       "Coyote (s)",        0.0,   0.3, 0.01],
		["jump_buffer_time",  "Buffer (s)",        0.0,   0.3, 0.01],
		["acceleration",      "Ground Accel",      5.0,  120.0, 1.0],
		["air_acceleration",  "Air Accel",         2.0,   80.0, 1.0],
		["gravity_multiplier","Gravity Rise×",     0.5,    5.0, 0.1],
		["fall_gravity_multiplier","Gravity Fall×",0.5,    8.0, 0.1],
		["jump_cut_factor",   "Jump Cut",          0.0,    1.0, 0.05],
	]
	for s_def in slider_defs:
		var prop: String = s_def[0]
		var slider: HSlider = _make_slider(s_def[2], s_def[3], s_def[4])
		_profile_sliders[prop] = slider
		slider.value_changed.connect(_on_profile_slider_changed.bind(prop))
		vbox.add_child(_add_labeled(s_def[1], slider))

	_sync_sliders_to_profile()


func _build_camera_tab() -> void:
	var scroll: ScrollContainer = _get_tab_scroll("Camera")
	var vbox: VBoxContainer = _make_vbox(scroll)

	var cam_defs: Array = [
		["arm_length",        "Arm Length",       2.0,  12.0, 0.1],
		["follow_speed",      "Follow Speed",     1.0,  20.0, 0.5],
		["lookahead_strength","Lookahead",         0.0,   5.0, 0.1],
		["drag_sensitivity_x","Drag Sens X",       0.05,  1.0, 0.05],
		["drag_sensitivity_y","Drag Sens Y",       0.05,  1.0, 0.05],
		["idle_recenter_delay","Recenter Delay(s)", 0.5,  6.0, 0.5],
	]
	for s_def in cam_defs:
		var prop: String = s_def[0]
		var slider: HSlider = _make_slider(s_def[2], s_def[3], s_def[4])
		slider.value_changed.connect(_on_camera_slider_changed.bind(prop))
		vbox.add_child(_add_labeled(s_def[1], slider))
		# Sync initial value from camera rig if available.
		var cam: CameraRig = Game.get_camera()
		if cam:
			slider.value = cam.get(prop)


func _build_juice_tab() -> void:
	var scroll: ScrollContainer = _get_tab_scroll("Juice")
	var vbox: VBoxContainer = _make_vbox(scroll)

	var juice_items: Array[String] = [
		"squash_stretch", "motion_trail", "lean",
		"screen_shake",   "hitstop",      "land_particles",
		"jump_puff",      "reboot_flash", "power_pulse",
		"damage_flicker", "footstep_sound","jump_sound",
		"land_sound",     "reboot_sound",
	]
	for key in juice_items:
		_juice_flags[key] = false
		var cb: CheckButton = CheckButton.new()
		cb.text = key.replace("_", " ").capitalize()
		cb.button_pressed = false
		cb.toggled.connect(_on_juice_toggled.bind(key))
		vbox.add_child(cb)


func _build_debug_tab() -> void:
	var scroll: ScrollContainer = _get_tab_scroll("Debug")
	var vbox: VBoxContainer = _make_vbox(scroll)

	var debug_items: Array = [
		["show_velocity_vector",  "Velocity vector"],
		["show_collision_shapes", "Collision shapes"],
		["show_normals",          "Ground normals"],
		["show_jump_arc",         "Jump arc"],
		["show_frametime_overlay","Frametime overlay"],
	]
	for d in debug_items:
		var cb: CheckButton = CheckButton.new()
		cb.text = d[1]
		cb.button_pressed = self.get(d[0])
		cb.toggled.connect(_on_debug_toggled.bind(d[0]))
		vbox.add_child(cb)


func _build_level_tab() -> void:
	var scroll: ScrollContainer = _get_tab_scroll("Level")
	var vbox: VBoxContainer = _make_vbox(scroll)

	# Time scale slider.
	var ts_slider: HSlider = _make_slider(0.1, 2.0, 0.05)
	ts_slider.value = 1.0
	ts_slider.value_changed.connect(_on_time_scale_changed)
	vbox.add_child(_add_labeled("Time Scale", ts_slider))

	# Respawn button.
	var respawn_btn: Button = Button.new()
	respawn_btn.text = "Respawn Player"
	respawn_btn.pressed.connect(_on_respawn_pressed)
	vbox.add_child(respawn_btn)


# ─── Callbacks ────────────────────────────────────────────────────────────────

func _on_profile_selected(index: int) -> void:
	_active_profile_index = index
	_sync_sliders_to_profile()
	var player: Player = Game.get_player()
	if player and index < _loaded_profiles.size():
		player.profile = _loaded_profiles[index]


func _on_profile_slider_changed(value: float, prop: String) -> void:
	if _active_profile_index >= _loaded_profiles.size():
		return
	var profile: ControllerProfile = _loaded_profiles[_active_profile_index]
	profile.set(prop, value)
	# Apply to player immediately.
	var player: Player = Game.get_player()
	if player:
		player.profile = profile


func _on_camera_slider_changed(value: float, prop: String) -> void:
	var cam: CameraRig = Game.get_camera()
	if cam:
		cam.set(prop, value)


func _on_juice_toggled(pressed: bool, key: String) -> void:
	_juice_flags[key] = pressed


func _on_debug_toggled(pressed: bool, prop: String) -> void:
	set(prop, pressed)
	# Apply relevant flags directly.
	if prop == "show_frametime_overlay":
		_perf_label.visible = pressed
	var player: Player = Game.get_player()
	if player and prop == "show_velocity_vector":
		player.debug_show_velocity = pressed


func _on_time_scale_changed(value: float) -> void:
	time_scale = value
	Engine.time_scale = value


func _on_respawn_pressed() -> void:
	var player: Player = Game.get_player()
	if player:
		player.respawn()


# ─── Sync helpers ─────────────────────────────────────────────────────────────

func _sync_sliders_to_profile() -> void:
	if _active_profile_index >= _loaded_profiles.size():
		return
	var profile: ControllerProfile = _loaded_profiles[_active_profile_index]
	for prop in _profile_sliders:
		var slider: HSlider = _profile_sliders[prop]
		slider.value = profile.get(prop)


func _update_perf_label() -> void:
	var ft: float = PerfBudget.get_frametime_ms()
	var dc: int = PerfBudget.get_draw_calls()
	_perf_label.text = "%.1f ms  |  %d DC  |  FPS %d" % [ft, dc, Engine.get_frames_per_second()]


# ─── Juice flag accessor ─────────────────────────────────────────────────────

func is_juice_on(key: String) -> bool:
	return _juice_flags.get(key, false)


# ─── Widget factory helpers ───────────────────────────────────────────────────

func _get_tab_scroll(tab_name: String) -> ScrollContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)
	scroll.name = tab_name
	return scroll


func _make_vbox(parent: Control) -> VBoxContainer:
	var vb: VBoxContainer = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(vb)
	return vb


func _make_slider(min_v: float, max_v: float, step: float) -> HSlider:
	var sl: HSlider = HSlider.new()
	sl.min_value = min_v
	sl.max_value = max_v
	sl.step = step
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sl


func _add_labeled(label_text: String, control: Control) -> HBoxContainer:
	var hb: HBoxContainer = HBoxContainer.new()
	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	hb.add_child(lbl)
	hb.add_child(control)
	return hb
