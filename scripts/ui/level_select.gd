extends Node
## Level selector — boot scene.  Lists all playable levels so the human can
## jump between them during playtesting.  Boot to this first; pick a level to
## load it.  Each entry shows the level name and a one-line shape-family
## description so the human immediately knows which prototype they're loading.

const _LEVELS: Array[Dictionary] = [
	{
		"name": "FEEL LAB",
		"path": "res://scenes/levels/feel_lab.tscn",
		"desc": "Tuning sandbox — not a level",
	},
	{
		"name": "THRESHOLD",
		"path": "res://scenes/levels/threshold.tscn",
		"desc": "Linear corridor (shape family 1)",
	},
	{
		"name": "SPIRE",
		"path": "res://scenes/levels/spire.tscn",
		"desc": "Vertical climbing tower (shape family 2)",
	},
]

const _BTN_MIN  := Vector2(520.0, 88.0)
const _BTN_FONT := 34
const _DESC_FONT := 22
const _TITLE_FONT := 52
const _SEP       := 20


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.06, 1.0)
	layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", _SEP)
	center.add_child(vbox)

	_add_header(vbox)

	var div := HSeparator.new()
	div.custom_minimum_size = Vector2(540, 0)
	vbox.add_child(div)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(gap)

	for level: Dictionary in _LEVELS:
		_add_level_row(vbox, level)


func _add_header(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "PROJECT VOID"
	title.add_theme_font_size_override(&"font_size", _TITLE_FONT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.92, 0.92, 1.0)
	parent.add_child(title)

	var sub := Label.new()
	sub.text = "— select level —"
	sub.add_theme_font_size_override(&"font_size", 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.45, 0.45, 0.55)
	parent.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 28)
	parent.add_child(gap)


func _add_level_row(parent: VBoxContainer, level: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override(&"separation", 24)
	parent.add_child(hbox)

	var btn := Button.new()
	btn.text = level["name"]
	btn.custom_minimum_size = _BTN_MIN
	btn.add_theme_font_size_override(&"font_size", _BTN_FONT)
	btn.pressed.connect(_on_level_selected.bind(level["path"]))
	hbox.add_child(btn)

	var desc := Label.new()
	desc.text = level["desc"]
	desc.add_theme_font_size_override(&"font_size", _DESC_FONT)
	desc.modulate = Color(0.45, 0.45, 0.55)
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(desc)


func _on_level_selected(path: String) -> void:
	if has_node("/root/Game"):
		Game.reset_run()
	get_tree().change_scene_to_file(path)
