class_name HUD
extends CanvasLayer

# Minimal in-game overlay. Created programmatically — scene file is a bare CanvasLayer.

@export var show_fps: bool = true
@export var show_velocity: bool = false

var _player: CharacterBody3D = null
var _fps_label: Label = null
var _vel_label: Label = null

func _ready() -> void:
	layer = 5
	_build_ui()
	_register_dev_menu()
	call_deferred("_find_player")

func set_player(p: CharacterBody3D) -> void:
	_player = p

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0] as CharacterBody3D

func _process(_delta: float) -> void:
	if _fps_label != null and show_fps:
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	if _vel_label != null and show_velocity and _player != null:
		var h := Vector2(_player.velocity.x, _player.velocity.z).length()
		_vel_label.text = "v %.1f  y %.1f" % [h, _player.velocity.y]
	if _fps_label != null:
		_fps_label.visible = show_fps
	if _vel_label != null:
		_vel_label.visible = show_velocity

func _build_ui() -> void:
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	anchor.set_anchor(SIDE_LEFT, 1.0)
	anchor.set_anchor(SIDE_RIGHT, 1.0)
	anchor.offset_left = -160
	anchor.offset_right = 0
	anchor.offset_top = 8
	anchor.offset_bottom = 80
	add_child(anchor)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	anchor.add_child(vbox)

	_fps_label = Label.new()
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_fps_label)

	_vel_label = Label.new()
	_vel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_vel_label)

func _register_dev_menu() -> void:
	if not has_node("/root/DevMenu"):
		return
	var dm := get_node("/root/DevMenu")
	dm.register_bool("Debug", "Show FPS", self, "show_fps")
	dm.register_bool("Debug", "Show Velocity", self, "show_velocity")
