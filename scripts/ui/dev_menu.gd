class_name DevMenuControl
extends CanvasLayer

# Dev menu overlay. Toggle: triple-tap top-left corner (within 80 px) or F1 on desktop.
# Registration API: register_float / register_bool / register_action.
# Scene file is a bare CanvasLayer — all UI created programmatically.

const CORNER_TAP_RADIUS: float = 80.0
const TRIPLE_TAP_WINDOW: float = 0.6  # seconds

var _entries: Array[Dictionary] = []
var _built: bool = false
var _panel: Control = null
var _content: VBoxContainer = null
var _corner_taps: int = 0
var _corner_tap_timer: float = 0.0

func _ready() -> void:
	layer = 100
	_build_panel_frame()

func _process(delta: float) -> void:
	if _corner_taps > 0:
		_corner_tap_timer -= delta
		if _corner_tap_timer <= 0.0:
			_corner_taps = 0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_toggle()
		return
	if event is InputEventScreenTouch and event.pressed:
		if event.position.length() < CORNER_TAP_RADIUS:
			_corner_taps += 1
			_corner_tap_timer = TRIPLE_TAP_WINDOW
			if _corner_taps >= 3:
				_corner_taps = 0
				_toggle()

# --- Registration API ---

func register_float(section: String, label: String, obj: Object, prop: String,
		min_val: float, max_val: float) -> void:
	_entries.append({
		"section": section, "label": label, "type": "float",
		"object": obj, "property": prop, "min": min_val, "max": max_val
	})
	_built = false

func register_bool(section: String, label: String, obj: Object, prop: String) -> void:
	_entries.append({
		"section": section, "label": label, "type": "bool",
		"object": obj, "property": prop
	})
	_built = false

func register_action(section: String, label: String, cb: Callable) -> void:
	_entries.append({
		"section": section, "label": label, "type": "action", "callable": cb
	})
	_built = false

# --- Private ---

func _build_panel_frame() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.custom_minimum_size = Vector2(460, 0)
	_panel.offset_left = 10
	_panel.offset_top = 40
	add_child(_panel)

	var outer := VBoxContainer.new()
	_panel.add_child(outer)

	var close_btn := Button.new()
	close_btn.text = "  Dev Menu  [close]"
	close_btn.pressed.connect(func() -> void: _panel.visible = false)
	outer.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 500)
	outer.add_child(scroll)

	_content = VBoxContainer.new()
	_content.custom_minimum_size.x = 440
	scroll.add_child(_content)

func _toggle() -> void:
	if _panel == null:
		return
	_panel.visible = not _panel.visible
	if _panel.visible and not _built:
		_build_entries()

func _build_entries() -> void:
	for child in _content.get_children():
		child.queue_free()

	var sorted := _entries.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["section"] < b["section"])

	var current_section := ""
	for entry in sorted:
		if entry["section"] != current_section:
			current_section = entry["section"]
			var header := Label.new()
			header.text = "— %s —" % current_section
			header.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			_content.add_child(header)

		match entry["type"]:
			"float":  _add_float_row(entry)
			"bool":   _add_bool_row(entry)
			"action": _add_action_row(entry)

	_built = true

func _add_float_row(entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = entry["label"]
	lbl.custom_minimum_size.x = 150
	lbl.clip_text = true
	var slider := HSlider.new()
	slider.min_value = entry["min"]
	slider.max_value = entry["max"]
	slider.step = (entry["max"] - entry["min"]) / 100.0
	slider.value = entry["object"].get(entry["property"])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val_lbl := Label.new()
	val_lbl.text = "%.2f" % slider.value
	val_lbl.custom_minimum_size.x = 52
	slider.value_changed.connect(func(v: float) -> void:
		entry["object"].set(entry["property"], v)
		val_lbl.text = "%.2f" % v)
	row.add_child(lbl)
	row.add_child(slider)
	row.add_child(val_lbl)
	_content.add_child(row)

func _add_bool_row(entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = entry["label"]
	lbl.custom_minimum_size.x = 150
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var check := CheckButton.new()
	check.button_pressed = entry["object"].get(entry["property"])
	check.toggled.connect(func(v: bool) -> void:
		entry["object"].set(entry["property"], v))
	row.add_child(lbl)
	row.add_child(check)
	_content.add_child(row)

func _add_action_row(entry: Dictionary) -> void:
	var btn := Button.new()
	btn.text = entry["label"]
	btn.pressed.connect(entry["callable"])
	_content.add_child(btn)
