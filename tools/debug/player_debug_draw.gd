extends Node3D
class_name PlayerDebugDraw
## In-world 3D debug overlays for the player controller.
## Add this node to any scene that has a "player"-group member.
## Toggled from Dev Menu → Debug viz section.
##
## DevMenu.debug_viz_state keys owned here:
##   collision_capsule — wireframe capsule matching the physics shape
##   velocity_arrow    — arrow in velocity direction, length ∝ speed
##   ground_normal     — floor surface normal arrow when on ground
##   wall_normal       — wall contact normal arrow when pressing against a wall
##   jump_arc          — predicted jump/fall parabola from current position

const _SEGS     := 24   # horizontal circle resolution
const _CAP_SEGS := 12   # hemisphere arc resolution

# Capsule dimensions must match the shape in player.tscn.
const _CAP_R  := 0.28
const _CAP_H  := 0.9
const _CAP_OY := 0.45   # capsule centre above player origin

const _C_CAPSULE     := Color(0.0, 0.9, 0.8)
const _C_VEL         := Color(1.0, 0.8, 0.0)
const _C_NORMAL      := Color(0.2, 1.0, 0.2)
const _C_WALL_NORMAL := Color(1.0, 0.3, 0.9)
const _C_ARC         := Color(1.0, 0.45, 0.1)

var _imesh: ImmediateMesh
var _player: Player
# Cached OR of all four viz flags — updated via signal rather than 4 dict
# lookups per frame. Avoids the scene-tree group search when all overlays off.
var _viz_active: bool = false


func _ready() -> void:
	_imesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	var mi := MeshInstance3D.new()
	mi.mesh = _imesh
	mi.material_override = mat
	add_child(mi)
	if has_node("/root/DevMenu"):
		DevMenu.debug_viz_changed.connect(_on_viz_changed)
	_refresh_viz_active()


func _refresh_viz_active() -> void:
	_viz_active = (
		DevMenu.is_debug_viz_on(&"collision_capsule") or
		DevMenu.is_debug_viz_on(&"velocity_arrow") or
		DevMenu.is_debug_viz_on(&"ground_normal") or
		DevMenu.is_debug_viz_on(&"wall_normal") or
		DevMenu.is_debug_viz_on(&"jump_arc"))


func _on_viz_changed(_key: StringName, _enabled: bool) -> void:
	_refresh_viz_active()


func _process(_delta: float) -> void:
	_imesh.clear_surfaces()
	if not _viz_active:
		return
	if _player == null or not is_instance_valid(_player):
		_find_player()
	if _player == null:
		return
	_imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var origin := _player.global_position
	if DevMenu.is_debug_viz_on(&"collision_capsule"):
		_draw_capsule(origin + Vector3(0.0, _CAP_OY, 0.0), _CAP_R, _CAP_H)
	if DevMenu.is_debug_viz_on(&"velocity_arrow"):
		_draw_velocity_arrow(origin)
	if DevMenu.is_debug_viz_on(&"ground_normal"):
		_draw_ground_normal(origin)
	if DevMenu.is_debug_viz_on(&"wall_normal"):
		_draw_wall_normal(origin)
	if DevMenu.is_debug_viz_on(&"jump_arc"):
		_draw_jump_arc(origin)
	_imesh.surface_end()


# ---- overlay drawers -----------------------------------------------------------

func _draw_capsule(center: Vector3, r: float, h: float) -> void:
	# h = total height; cylinder half = h/2 - r
	var cy := h * 0.5 - r
	_imesh.surface_set_color(_C_CAPSULE)
	_xz_circle(center + Vector3(0.0,  cy, 0.0), r)
	_xz_circle(center + Vector3(0.0, -cy, 0.0), r)
	for i in range(4):
		var a  := float(i) * PI * 0.5
		var d  := Vector3(cos(a) * r, 0.0, sin(a) * r)
		_add_line(center + d + Vector3(0.0,  cy, 0.0),
				  center + d + Vector3(0.0, -cy, 0.0))
	# Hemisphere arcs in XY and ZY planes.
	_hemi_arc(center, r, cy, true,  false)
	_hemi_arc(center, r, cy, true,  true)
	_hemi_arc(center, r, cy, false, false)
	_hemi_arc(center, r, cy, false, true)


func _draw_velocity_arrow(origin: Vector3) -> void:
	var v := _player.velocity
	if v.length_squared() < 0.01:
		return
	_imesh.surface_set_color(_C_VEL)
	var base := origin + Vector3(0.0, _CAP_OY, 0.0)
	var tip  := base + v * 0.15
	_add_line(base, tip)
	var dir  := v.normalized()
	# Perpendicular for arrowhead ticks — handle near-vertical velocity.
	var perp: Vector3
	if absf(dir.dot(Vector3.UP)) < 0.9:
		perp = dir.cross(Vector3.UP).normalized() * 0.12
	else:
		perp = dir.cross(Vector3.RIGHT).normalized() * 0.12
	var notch := tip - dir * 0.2
	_add_line(tip, notch + perp)
	_add_line(tip, notch - perp)


func _draw_ground_normal(origin: Vector3) -> void:
	if not _player.is_on_floor():
		return
	_imesh.surface_set_color(_C_NORMAL)
	var n   := _player.get_floor_normal()
	var tip := origin + n * 1.2
	_add_line(origin, tip)
	var perp: Vector3
	if absf(n.dot(Vector3.RIGHT)) < 0.9:
		perp = n.cross(Vector3.RIGHT).normalized() * 0.12
	else:
		perp = n.cross(Vector3.FORWARD).normalized() * 0.12
	_add_line(tip, origin + n * 1.0 + perp)
	_add_line(tip, origin + n * 1.0 - perp)


func _draw_wall_normal(origin: Vector3) -> void:
	if not _player.is_on_wall():
		return
	_imesh.surface_set_color(_C_WALL_NORMAL)
	var n   := _player.get_wall_normal()
	var tip := origin + n * 1.2
	_add_line(origin, tip)
	var perp: Vector3
	if absf(n.dot(Vector3.UP)) < 0.9:
		perp = n.cross(Vector3.UP).normalized() * 0.12
	else:
		perp = n.cross(Vector3.RIGHT).normalized() * 0.12
	_add_line(tip, origin + n * 1.0 + perp)
	_add_line(tip, origin + n * 1.0 - perp)


func _draw_jump_arc(origin: Vector3) -> void:
	var p := _player.profile
	if p == null:
		return
	_imesh.surface_set_color(_C_ARC)
	var pos := origin
	# On floor: preview a jump from here. In air: show current trajectory.
	var vel: Vector3
	if _player.is_on_floor():
		vel = Vector3(_player.velocity.x, p.jump_velocity, _player.velocity.z)
	else:
		vel = _player.velocity
	var dt   := 1.0 / 30.0
	var prev := pos
	for _i in range(60):
		# Use rising gravity while ascending, apex gravity once falling.
		if vel.y > 0.0:
			vel.y -= p.gravity_rising * dt
		else:
			vel.y -= p.gravity_after_apex * dt
		vel.y = maxf(vel.y, -p.terminal_velocity)
		pos += vel * dt
		_add_line(prev, pos)
		prev = pos
		if pos.y < origin.y - 8.0:
			break


# ---- ImmediateMesh primitives (must be inside surface_begin/end) ---------------

func _xz_circle(c: Vector3, r: float) -> void:
	for i in range(_SEGS):
		var a0 := float(i)       / _SEGS * TAU
		var a1 := float(i + 1)   / _SEGS * TAU
		_imesh.surface_add_vertex(c + Vector3(cos(a0) * r, 0.0, sin(a0) * r))
		_imesh.surface_add_vertex(c + Vector3(cos(a1) * r, 0.0, sin(a1) * r))


func _hemi_arc(center: Vector3, r: float, cy: float,
		top: bool, zy_plane: bool) -> void:
	# Quarter-circle from rim to pole in the XY plane (zy_plane=false) or ZY (true).
	var s := 1.0 if top else -1.0
	for i in range(_CAP_SEGS):
		var a0 := float(i)     / _CAP_SEGS * (PI * 0.5)
		var a1 := float(i + 1) / _CAP_SEGS * (PI * 0.5)
		var x0 := cos(a0) * r
		var x1 := cos(a1) * r
		var y0 := cy * s + sin(a0) * r * s
		var y1 := cy * s + sin(a1) * r * s
		if zy_plane:
			_imesh.surface_add_vertex(center + Vector3(0.0, y0, x0))
			_imesh.surface_add_vertex(center + Vector3(0.0, y1, x1))
		else:
			_imesh.surface_add_vertex(center + Vector3(x0, y0, 0.0))
			_imesh.surface_add_vertex(center + Vector3(x1, y1, 0.0))


func _add_line(a: Vector3, b: Vector3) -> void:
	_imesh.surface_add_vertex(a)
	_imesh.surface_add_vertex(b)


func _find_player() -> void:
	if not is_inside_tree():
		return
	var group := get_tree().get_nodes_in_group(&"player")
	if group.size() > 0:
		_player = group[0] as Player
