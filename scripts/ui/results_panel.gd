extends CanvasLayer
class_name ResultsPanel
## Post-level results overlay. Built programmatically so any level can
## instantiate it without a separate .tscn. Hidden at start; call
## show_results() from the level's level_completed handler.
##
## Layout: dark semi-transparent backdrop covering the full viewport;
## centred VBox with TIME / PAR / SHARDS rows and a REPLAY button.
## PAR row is tinted green when the player beat par, red when over.
## Brutalist aesthetic: no decoration, large thumb-friendly tap target.

var _time_val: Label
var _par_val: Label
var _shard_val: Label

const _FONT_SIZE: int = 36
const _KEY_WIDTH: float = 180.0
const _ROW_SEP: int = 28
const _PANEL_WIDTH: float = 560.0
const _BTN_MIN: Vector2 = Vector2(360.0, 120.0)
const _BTN_FONT_SIZE: int = 40


func _ready() -> void:
	layer = 5
	hide()
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.04, 0.05, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	# CenterContainer fills the whole viewport and centres its child.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(_PANEL_WIDTH, 0.0)
	panel.add_theme_constant_override(&"separation", _ROW_SEP)
	center.add_child(panel)

	_time_val = _add_stat_row(panel, "TIME")
	_par_val = _add_stat_row(panel, "PAR")
	_shard_val = _add_stat_row(panel, "SHARDS")

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 40.0)
	panel.add_child(gap)

	var replay_btn := Button.new()
	replay_btn.text = "REPLAY"
	replay_btn.custom_minimum_size = _BTN_MIN
	replay_btn.add_theme_font_size_override(&"font_size", _BTN_FONT_SIZE)
	replay_btn.pressed.connect(_on_replay)
	panel.add_child(replay_btn)


# Appends a key–value row to `parent` and returns the value Label.
func _add_stat_row(parent: VBoxContainer, key: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 40)
	parent.add_child(row)

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.custom_minimum_size = Vector2(_KEY_WIDTH, 0.0)
	key_lbl.add_theme_font_size_override(&"font_size", _FONT_SIZE)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(key_lbl)

	var val_lbl := Label.new()
	val_lbl.text = "—"
	val_lbl.add_theme_font_size_override(&"font_size", _FONT_SIZE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(val_lbl)
	return val_lbl


## Call from the level script when level_completed fires.
func show_results(
		time_s: float,
		par_s: float,
		shards: int,
		total: int) -> void:
	_time_val.text = _fmt_time(time_s)
	_par_val.text = _fmt_time(par_s)
	_par_val.modulate = (
		Color(0.45, 1.0, 0.45) if time_s <= par_s else Color(1.0, 0.45, 0.45)
	)
	_shard_val.text = "%d / %d" % [shards, total]
	show()


func _fmt_time(seconds: float) -> String:
	var m: int = int(seconds) / 60
	var s: int = int(seconds) % 60
	var cs: int = int(fmod(seconds, 1.0) * 100.0)
	return "%d:%02d.%02d" % [m, s, cs]


func _on_replay() -> void:
	if has_node("/root/Game"):
		Game.reset_run()
	get_tree().reload_current_scene()
