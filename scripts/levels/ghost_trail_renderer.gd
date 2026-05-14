extends Node3D
class_name GhostTrailRenderer
## Attempt-replay overlay — SMB-style ghost trails that replay all recent failed
## runs simultaneously with the live attempt.
##
## Reads Game.trail_history (populated by game.gd at each respawn) and writes
## instance transforms + colours to a single MultiMeshInstance3D each frame:
## 1 draw call for up to MAX_DEPTH × _visible_points() instances.
##
## Toggle via DevMenu juice key "ghost_trails" (default OFF).
## "visible_window_s" controls how many seconds of each attempt's history to
## show; tunable in the dev menu Juice → Ghost Trail section.

const MAX_DEPTH  := 5
const SAMPLE_HZ  := 30.0

## Seconds of each attempt's trail that are visible. At 30 samples/s:
##   2 s = 60 points, 4 s = 120 points.
@export_range(1.0, 5.0, 0.5) var visible_window_s: float = 2.0

var _mmesh: MultiMeshInstance3D
var _enabled: bool = false   # default OFF until the level has meaningful data


func _ready() -> void:
	_build_multimesh()
	if has_node("/root/DevMenu"):
		DevMenu.juice_toggle_changed.connect(_on_juice_changed)
		_enabled = DevMenu.is_juice_on(&"ghost_trails")
		DevMenu.ghost_trail_param_changed.connect(_on_ghost_trail_param)


func _build_multimesh() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.16
	sphere.radial_segments = 6
	sphere.rings = 3

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	sphere.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = MAX_DEPTH * _visible_points()
	mm.mesh = sphere

	_mmesh = MultiMeshInstance3D.new()
	_mmesh.multimesh = mm
	_mmesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmesh)


func _process(_delta: float) -> void:
	if _mmesh == null:
		return
	if not _enabled or not has_node("/root/Game"):
		# Hide the node — GPU skips it entirely. _on_juice_changed already
		# blanks instances on disable so no stale data appears on re-show.
		_mmesh.visible = false
		return
	_mmesh.visible = true

	var visible_pts := _visible_points()
	var inst := 0
	for a_idx: int in Game.trail_history.size():
		var trail: PackedVector3Array = Game.trail_history[a_idx]
		var start := maxi(0, trail.size() - visible_pts)
		# Newest attempt is brightest; each older attempt fades by ×0.55.
		var attempt_alpha := 0.35 * pow(0.55, float(a_idx))
		for p_idx: int in (trail.size() - start):
			# Oldest visible point fades to 0; newest is full attempt_alpha.
			var point_t := float(p_idx) / float(visible_pts)
			var col := Color(0.55, 0.55, 0.60, attempt_alpha * point_t)
			_mmesh.multimesh.set_instance_transform(inst,
				Transform3D(Basis(), trail[start + p_idx]))
			_mmesh.multimesh.set_instance_color(inst, col)
			inst += 1
	_blank_from(inst)


func _visible_points() -> int:
	return roundi(visible_window_s * SAMPLE_HZ)


func _blank_from(start_idx: int) -> void:
	var n := _mmesh.multimesh.instance_count
	for i: int in range(start_idx, n):
		_mmesh.multimesh.set_instance_color(i, Color(0.0, 0.0, 0.0, 0.0))


func _on_juice_changed(key: StringName, enabled: bool) -> void:
	if key == &"ghost_trails":
		_enabled = enabled
		if not enabled and _mmesh != null:
			_blank_from(0)


func _on_ghost_trail_param(param: StringName, value: float) -> void:
	if param != &"visible_window_s":
		return
	visible_window_s = value
	if _mmesh == null:
		return
	# Resize the MultiMesh instance buffer for the new window size.
	# Blank AFTER resize so new instances above the old count (which Godot
	# initialises to default colour, not transparent) are zeroed immediately.
	_mmesh.multimesh.instance_count = MAX_DEPTH * _visible_points()
	_blank_from(0)
