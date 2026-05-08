extends Control
class_name TouchOverlay
## Touch input overlay for landscape mobile play. Routes screen touches
## into TouchInput according to where they land:
##   - Left half: virtual stick (free-floating, origin = first contact).
##   - Jump button area on right: jump press/release.
##   - Anything else on the right half: camera drag (yaw/pitch).
##
## CLAUDE.md mandates touch only, repositionable + resizable buttons,
## and explicitly bans a second virtual stick for camera. Kickoff scope:
## working stick + jump + drag, exported anchors for repositioning, and
## a `enter_reposition_mode()` stub. The drag-to-place reposition UI and
## persistence to user://input.cfg are queued in PLAN.md.

@export_category("Stick")
@export_range(40.0, 250.0, 1.0) var stick_max_radius: float = 110.0
@export_range(20.0, 120.0, 1.0) var stick_knob_radius: float = 50.0
@export_range(0.0, 0.5, 0.01) var stick_deadzone: float = 0.15

@export_category("Jump button")
## Anchor in viewport coordinates (1920x1080 reference frame).
@export var jump_button_anchor: Vector2 = Vector2(1720.0, 900.0)
@export_range(40.0, 200.0, 1.0) var jump_button_radius: float = 95.0

const KIND_NONE := 0
const KIND_STICK := 1
const KIND_JUMP := 2
const KIND_DRAG := 3

var _touches: Dictionary = {}  # InputEvent.index -> kind
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_knob: Vector2 = Vector2.ZERO
var _drag_last: Dictionary = {}  # InputEvent.index -> Vector2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _input(event: InputEvent) -> void:
	# Sleep while the dev menu is open so touches go to the panel.
	if has_node("/root/DevMenu") and DevMenu.is_open:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var kind := _classify(event.position)
		_touches[event.index] = kind
		match kind:
			KIND_STICK:
				_stick_origin = event.position
				_stick_knob = event.position
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
				_stick_knob = Vector2.ZERO
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
	var viewport_size := get_viewport_rect().size
	if pos.x < viewport_size.x * 0.5:
		return KIND_STICK
	return KIND_DRAG


func _draw() -> void:
	# Jump button — always visible.
	var jump_pressed := false
	for kind in _touches.values():
		if kind == KIND_JUMP:
			jump_pressed = true
			break
	var alpha := 0.55 if jump_pressed else 0.28
	draw_circle(jump_button_anchor, jump_button_radius, Color(0.78, 0.18, 0.18, alpha))
	draw_arc(jump_button_anchor, jump_button_radius - 2.0,
		0.0, TAU, 36, Color(1, 1, 1, 0.7), 2.0)

	# Stick — only while a stick gesture is active.
	if _stick_origin != Vector2.ZERO:
		draw_circle(_stick_origin, stick_max_radius, Color(1, 1, 1, 0.10))
		draw_arc(_stick_origin, stick_max_radius - 2.0,
			0.0, TAU, 36, Color(1, 1, 1, 0.32), 2.0)
		draw_circle(_stick_knob, stick_knob_radius, Color(1, 1, 1, 0.42))


## Stub for the reposition UI (CLAUDE.md mandate; full UI queued in
## PLAN.md). When implemented, this enters a mode where each control is
## draggable until the player taps "Done", then writes the new positions
## to user://input.cfg.
func enter_reposition_mode() -> void:
	push_warning("TouchOverlay.enter_reposition_mode(): not implemented yet — see PLAN.md")
