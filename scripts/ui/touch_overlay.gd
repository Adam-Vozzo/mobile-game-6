extends Control
class_name TouchOverlay
## Touch input overlay for landscape mobile play. Zones:
##   Left side (< stick_zone_ratio × width): virtual stick (free-floating).
##   Jump button region (right side): jump press/release.
##   Remaining right-side touches: camera drag (yaw/pitch).
##
## Layout persists to user://input.cfg. Drag-to-place reposition mode is
## triggered by the dev menu Touch section ▶ "Reposition controls…" button,
## or by calling enter_reposition_mode() directly.

@export_category("Stick")
@export_range(40.0, 250.0, 1.0) var stick_max_radius: float = 110.0
@export_range(20.0, 120.0, 1.0) var stick_knob_radius: float = 50.0
@export_range(0.0, 0.5, 0.01) var stick_deadzone: float = 0.15
## Fraction of viewport width that is "stick territory" (left of divider = stick zone).
@export_range(0.3, 0.7, 0.01) var stick_zone_ratio: float = 0.5

@export_category("Jump button")
@export var jump_button_anchor: Vector2 = Vector2(1720.0, 900.0)
@export_range(40.0, 200.0, 1.0) var jump_button_radius: float = 95.0

# --- touch classification ---
const KIND_NONE  := 0
const KIND_STICK := 1
const KIND_JUMP  := 2
const KIND_DRAG  := 3

var _touches: Dictionary = {}    # index → KIND_*
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_knob:   Vector2 = Vector2.ZERO
var _drag_last:    Dictionary = {}    # index → Vector2

# --- reposition mode ---
var _reposition_mode: bool = false
var _repo_drag_jump:   bool = false    # currently moving the jump circle
var _repo_drag_resize: bool = false    # currently resizing the jump circle

# Thumb-zone presets in the same coordinate space as jump_button_anchor.
# "zone" is stick_zone_ratio (0.0–1.0 fraction of viewport width).
const _PRESETS: Array = [
	{"name": "Default", "anchor": Vector2(1720, 900),  "radius": 95.0,  "zone": 0.50},
	{"name": "Closer",  "anchor": Vector2(1580, 900),  "radius": 90.0,  "zone": 0.45},
	{"name": "Wider",   "anchor": Vector2(1830, 950),  "radius": 100.0, "zone": 0.55},
]

const CFG_PATH    := "user://input.cfg"
const CFG_SECTION := "touch"

const _REPO_FONT_SM := 13
const _REPO_FONT_NM := 18


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_layout()
	if has_node("/root/DevMenu"):
		DevMenu.touch_param_changed.connect(_on_touch_param)
		DevMenu.reposition_controls_requested.connect(enter_reposition_mode)


func _input(event: InputEvent) -> void:
	if _reposition_mode:
		_handle_repo_input(event)
		get_viewport().set_input_as_handled()
		return
	if has_node("/root/DevMenu") and DevMenu.is_open:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


# ── normal play ───────────────────────────────────────────────────────────────

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var kind := _classify(event.position)
		_touches[event.index] = kind
		match kind:
			KIND_STICK:
				_stick_origin = event.position
				_stick_knob   = event.position
				TouchInput.set_move_vector(Vector2.ZERO)
			KIND_JUMP:
				TouchInput.set_jump_held(true)
			KIND_DRAG:
				_drag_last[event.index] = event.position
	else:
		var kind: int = _touches.get(event.index, KIND_NONE)
		match kind:
			KIND_STICK:
				_stick_origin = Vector2.ZERO
				_stick_knob   = Vector2.ZERO
				TouchInput.set_move_vector(Vector2.ZERO)
			KIND_JUMP:
				TouchInput.set_jump_held(false)
			KIND_DRAG:
				_drag_last.erase(event.index)
		_touches.erase(event.index)
	queue_redraw()


func _handle_drag(event: InputEventScreenDrag) -> void:
	var kind: int = _touches.get(event.index, KIND_NONE)
	match kind:
		KIND_STICK:
			var offset := event.position - _stick_origin
			if offset.length() > stick_max_radius:
				offset = offset.normalized() * stick_max_radius
			_stick_knob = _stick_origin + offset
			var v := offset / stick_max_radius
			if v.length() < stick_deadzone:
				v = Vector2.ZERO
			TouchInput.set_move_vector(v)
			queue_redraw()
		KIND_DRAG:
			var last: Vector2 = _drag_last.get(event.index, event.position)
			TouchInput.add_camera_drag_delta(event.position - last)
			_drag_last[event.index] = event.position


func _classify(pos: Vector2) -> int:
	if pos.distance_to(jump_button_anchor) <= jump_button_radius:
		return KIND_JUMP
	if pos.x < get_viewport_rect().size.x * stick_zone_ratio:
		return KIND_STICK
	return KIND_DRAG


# ── reposition mode ───────────────────────────────────────────────────────────

## Enter drag-to-place layout mode. Closes dev menu and redirects all input.
func enter_reposition_mode() -> void:
	if has_node("/root/DevMenu"):
		DevMenu.set_open(false)
	_touches.clear()
	_drag_last.clear()
	_stick_origin = Vector2.ZERO
	TouchInput.set_move_vector(Vector2.ZERO)
	TouchInput.set_jump_held(false)
	_reposition_mode  = true
	_repo_drag_jump   = false
	_repo_drag_resize = false
	queue_redraw()


func exit_reposition_mode() -> void:
	_reposition_mode  = false
	_repo_drag_jump   = false
	_repo_drag_resize = false
	_save_layout()
	queue_redraw()


## Parses any relevant input event into position + gesture intent.
## Returns an empty dict if the event should be ignored in reposition mode.
func _parse_repo_event(event: InputEvent) -> Dictionary:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		return {&"pos": t.position, &"pressed": t.pressed, &"released": not t.pressed, &"moved": false}
	if event is InputEventScreenDrag:
		return {&"pos": (event as InputEventScreenDrag).position, &"pressed": false, &"released": false, &"moved": true}
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return {}
		return {&"pos": mb.position, &"pressed": mb.pressed, &"released": not mb.pressed, &"moved": false}
	if event is InputEventMouseMotion:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return {}
		return {&"pos": (event as InputEventMouseMotion).position, &"pressed": false, &"released": false, &"moved": true}
	return {}


func _on_repo_press(pos: Vector2) -> void:
	if _done_rect().has_point(pos):
		exit_reposition_mode()
		return
	var pr := _preset_rects()
	for i in pr.size():
		if (pr[i] as Rect2).has_point(pos):
			_apply_preset(i)
			return
	if pos.distance_to(_resize_handle_pos()) <= 30.0:
		_repo_drag_resize = true
		_repo_drag_jump   = false
		return
	if pos.distance_to(jump_button_anchor) <= jump_button_radius + 20.0:
		_repo_drag_jump   = true
		_repo_drag_resize = false


func _on_repo_move(pos: Vector2) -> void:
	if _repo_drag_jump:
		jump_button_anchor = pos
		queue_redraw()
	elif _repo_drag_resize:
		jump_button_radius = clampf(pos.distance_to(jump_button_anchor), 40.0, 200.0)
		queue_redraw()


func _on_repo_release() -> void:
	_repo_drag_jump   = false
	_repo_drag_resize = false


func _handle_repo_input(event: InputEvent) -> void:
	var ev := _parse_repo_event(event)
	if ev.is_empty():
		return
	if ev[&"pressed"]:
		_on_repo_press(ev[&"pos"])
	elif ev[&"moved"]:
		_on_repo_move(ev[&"pos"])
	elif ev[&"released"]:
		_on_repo_release()


func _resize_handle_pos() -> Vector2:
	return jump_button_anchor + Vector2(jump_button_radius + 16.0, 0.0)


# ── reposition UI geometry (same coordinate space as _draw) ──────────────────

func _done_rect() -> Rect2:
	var vp := get_viewport_rect().size
	return Rect2(vp.x * 0.5 - 80.0, 16.0, 160.0, 52.0)


func _preset_rects() -> Array:
	var vp  := get_viewport_rect().size
	var bw  := 110.0
	var gap := 12.0
	var total := bw * _PRESETS.size() + gap * (_PRESETS.size() - 1)
	var x0  := vp.x * 0.5 - total * 0.5
	var rects: Array = []
	for i in _PRESETS.size():
		rects.append(Rect2(x0 + i * (bw + gap), 76.0, bw, 44.0))
	return rects


# ── draw ──────────────────────────────────────────────────────────────────────

func _draw() -> void:
	if _reposition_mode:
		_draw_reposition()
	else:
		_draw_play()


func _draw_play() -> void:
	var jump_pressed := false
	for kind in _touches.values():
		if kind == KIND_JUMP:
			jump_pressed = true
			break
	var alpha := 0.55 if jump_pressed else 0.28
	draw_circle(jump_button_anchor, jump_button_radius, Color(0.78, 0.18, 0.18, alpha))
	draw_arc(jump_button_anchor, jump_button_radius - 2.0,
		0.0, TAU, 36, Color(1, 1, 1, 0.7), 2.0)

	if _stick_origin != Vector2.ZERO:
		draw_circle(_stick_origin, stick_max_radius, Color(1, 1, 1, 0.10))
		draw_arc(_stick_origin, stick_max_radius - 2.0,
			0.0, TAU, 36, Color(1, 1, 1, 0.32), 2.0)
		draw_circle(_stick_knob, stick_knob_radius, Color(1, 1, 1, 0.42))


func _draw_reposition() -> void:
	var vp := get_viewport_rect().size
	_draw_dim_overlay(vp)
	_draw_zone_divider(vp)
	_draw_jump_button_repo()
	_draw_resize_handle_repo()
	_draw_done_button_repo()
	_draw_preset_buttons_repo()
	_draw_repo_header(vp)


func _draw_dim_overlay(vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.45))


func _draw_zone_divider(vp: Vector2) -> void:
	var div_x := vp.x * stick_zone_ratio
	draw_line(Vector2(div_x, 0), Vector2(div_x, vp.y), Color(0.4, 0.7, 1.0, 0.55), 2.5)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(div_x + 8.0, vp.y * 0.55),
			"STICK ◀", HORIZONTAL_ALIGNMENT_LEFT, -1, _REPO_FONT_SM, Color(0.4, 0.7, 1.0, 0.8))


func _draw_jump_button_repo() -> void:
	draw_circle(jump_button_anchor, jump_button_radius, Color(0.78, 0.18, 0.18, 0.4))
	draw_arc(jump_button_anchor, jump_button_radius, 0.0, TAU, 36,
		Color(1.0, 0.25, 0.25, 0.9), 2.5)
	draw_line(jump_button_anchor - Vector2(18, 0), jump_button_anchor + Vector2(18, 0),
		Color(1, 1, 1, 0.8), 2.0)
	draw_line(jump_button_anchor - Vector2(0, 18), jump_button_anchor + Vector2(0, 18),
		Color(1, 1, 1, 0.8), 2.0)


func _draw_resize_handle_repo() -> void:
	var rh := _resize_handle_pos()
	draw_circle(rh, 16.0, Color(1.0, 0.75, 0.1, 0.9))
	draw_arc(rh, 16.0, 0.0, TAU, 20, Color(1, 1, 1, 0.95), 1.5)


func _draw_done_button_repo() -> void:
	var dr := _done_rect()
	draw_rect(dr, Color(0.12, 0.72, 0.12, 0.9), true, -1.0)
	draw_rect(dr, Color(1, 1, 1, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font,
			Vector2(dr.position.x, dr.position.y + dr.size.y * 0.5 + _REPO_FONT_NM * 0.38),
			"DONE", HORIZONTAL_ALIGNMENT_CENTER, dr.size.x, _REPO_FONT_NM, Color.WHITE)


func _draw_preset_buttons_repo() -> void:
	var font := ThemeDB.fallback_font
	var pr := _preset_rects()
	for i in pr.size():
		var r: Rect2 = pr[i]
		draw_rect(r, Color(0.15, 0.35, 0.75, 0.88), true, -1.0)
		draw_rect(r, Color(1, 1, 1, 0.7), false, 1.5)
		if font:
			draw_string(font,
				Vector2(r.position.x, r.position.y + r.size.y * 0.5 + _REPO_FONT_SM * 0.38),
				_PRESETS[i]["name"], HORIZONTAL_ALIGNMENT_CENTER, r.size.x,
				_REPO_FONT_SM, Color(1, 1, 1, 0.95))


func _draw_repo_header(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(0.0, 13.0),
			"TOUCH CONTROLS — drag ✛ to move, drag ● to resize, tap preset to snap",
			HORIZONTAL_ALIGNMENT_CENTER, vp.x, _REPO_FONT_SM, Color(0.9, 0.9, 0.9, 0.9))


# ── presets ───────────────────────────────────────────────────────────────────

func _apply_preset(idx: int) -> void:
	var p: Dictionary = _PRESETS[idx]
	jump_button_anchor = p["anchor"]
	jump_button_radius = p["radius"]
	stick_zone_ratio   = p["zone"]
	queue_redraw()


# ── persistence ───────────────────────────────────────────────────────────────

func _save_layout() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(CFG_SECTION, "jump_anchor_x", jump_button_anchor.x)
	cfg.set_value(CFG_SECTION, "jump_anchor_y", jump_button_anchor.y)
	cfg.set_value(CFG_SECTION, "jump_radius",   jump_button_radius)
	cfg.set_value(CFG_SECTION, "stick_zone",    stick_zone_ratio)
	cfg.save(CFG_PATH)


func _load_layout() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	jump_button_anchor.x = cfg.get_value(CFG_SECTION, "jump_anchor_x", jump_button_anchor.x)
	jump_button_anchor.y = cfg.get_value(CFG_SECTION, "jump_anchor_y", jump_button_anchor.y)
	jump_button_radius   = cfg.get_value(CFG_SECTION, "jump_radius",   jump_button_radius)
	stick_zone_ratio     = cfg.get_value(CFG_SECTION, "stick_zone",    stick_zone_ratio)


func _on_touch_param(param: StringName, value: Variant) -> void:
	match param:
		&"jump_radius":
			jump_button_radius = float(value)
			queue_redraw()
		&"stick_zone_ratio":
			stick_zone_ratio = float(value)
			queue_redraw()
