extends Node3D
class_name BlobShadow
## Soft disc shadow projected below the Stray for depth-perception during jumps.
##
## In 3D precision platformers, the hardest player complaint is misjudged landings.
## SMB 3D identified depth perception as "the biggest new challenge" in the 2D→3D
## transition and uses a shadow blob as the primary spatial aid. This implementation
## raycasts straight down each frame, places a translucent disc at the hit point,
## and scales/fades with height — giving the player a clear read on where they will
## land without any real-time shadow lighting.
##
## A second optional disc ("landing predictor") projects at the anticipated landing
## point using the player's current velocity. Toggle via juice key "predict_landing"
## (default OFF — enable if Zone 3 lateral jumps read ambiguous on device).
## See docs/research/depth_perception_cues.md §1.
##
## Toggled via DevMenu juice key "blob_shadow" (default ON).
## Tunables are @export so they appear in the Godot inspector for rapid iteration.

## Disc radius when the player is at ground level (on the floor).
@export_range(0.05, 1.0, 0.01) var radius_at_ground: float = 0.22
## Disc radius at maximum height (shadow largest when furthest away, matching
## natural shadow penumbra expansion).
@export_range(0.1, 2.0, 0.01) var radius_at_height: float = 0.55
## Height above the floor at which the shadow fades to fully transparent.
@export_range(1.0, 20.0, 0.5) var fade_height: float = 6.0
## Maximum shadow opacity (at ground level).
@export_range(0.05, 1.0, 0.01) var alpha_max: float = 0.42
## Collision mask for the raycast. Defaults to layer 1 (World) — ignore
## CameraOccluder (layer 7) and everything else.
@export_flags_3d_physics var ray_mask: int = 1

## How far ahead (seconds × velocity) to project the predictor disc origin.
@export_range(0.05, 1.0, 0.05) var predict_seconds: float = 0.35
## Predictor disc radius as a fraction of the main disc's current radius.
@export_range(0.1, 1.0, 0.05) var predictor_radius_scale: float = 0.5
## Maximum opacity of the predictor disc (kept dimmer than the main shadow).
@export_range(0.05, 1.0, 0.01) var predictor_alpha_max: float = 0.25

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _enabled: bool = true
var _predict_mesh: MeshInstance3D
var _predict_mat: StandardMaterial3D
var _predict_enabled: bool = false


func _ready() -> void:
	_build_mesh()
	_build_predict_mesh()
	if has_node("/root/DevMenu"):
		@warning_ignore("return_value_discarded")
		DevMenu.juice_toggle_changed.connect(_on_juice_changed)
		_enabled = DevMenu.is_juice_on(&"blob_shadow")
		_predict_enabled = DevMenu.is_juice_on(&"predict_landing")
		@warning_ignore("return_value_discarded")
		DevMenu.blob_shadow_param_changed.connect(_on_blob_shadow_param_changed)


func _build_mesh() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.01
	cyl.radial_segments = 16
	cyl.rings = 0

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.02, 0.01, 0.01, alpha_max)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS

	_mesh = MeshInstance3D.new()
	_mesh.mesh = cyl
	_mesh.material_override = _mat
	add_child(_mesh)


func _build_predict_mesh() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.01
	cyl.radial_segments = 12
	cyl.rings = 0

	_predict_mat = StandardMaterial3D.new()
	_predict_mat.albedo_color = Color(0.02, 0.01, 0.01, predictor_alpha_max)
	_predict_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_predict_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_predict_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_predict_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS

	_predict_mesh = MeshInstance3D.new()
	_predict_mesh.mesh = cyl
	_predict_mesh.material_override = _predict_mat
	_predict_mesh.visible = false
	add_child(_predict_mesh)


func _process(_delta: float) -> void:
	if not _enabled:
		_hide_all()
		return
	var parent := get_parent()
	if parent == null:
		_hide_all()
		return
	var origin: Vector3 = parent.global_position
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 25.0)
	query.collision_mask = ray_mask
	query.exclude = [parent.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		_hide_all()
		return
	var height := origin.y - (hit["position"] as Vector3).y
	if height > fade_height:
		_hide_all()
		return
	# t: 0 = at floor, 1 = at fade_height.
	var t := clampf(height / fade_height, 0.0, 1.0)
	var r := lerpf(radius_at_ground, radius_at_height, t)
	# Alpha falls off quadratically so the shadow reads clearly near the ground
	# and disappears smoothly well before the hard fade_height cutoff.
	var a := lerpf(alpha_max, 0.0, t * t)
	_mesh.visible = true
	_mesh.global_position = (hit["position"] as Vector3) + Vector3.UP * 0.012
	_mesh.scale = Vector3(r, 1.0, r)
	_mat.albedo_color = Color(0.02, 0.01, 0.01, a)
	_update_predictor(parent, origin, space, height, t)


func _hide_all() -> void:
	_mesh.visible = false
	if _predict_mesh != null:
		_predict_mesh.visible = false


# Projects a second disc at the anticipated landing point using the player's
# current velocity. Only shown when _predict_enabled and the player is airborne
# (height > 0.2 m so the predictor doesn't flicker on ground level).
func _update_predictor(
		parent: Node, origin: Vector3,
		space: PhysicsDirectSpaceState3D, height: float, t: float) -> void:
	if not (_predict_enabled and _predict_mesh != null and height > 0.2):
		if _predict_mesh != null:
			_predict_mesh.visible = false
		return
	var vel := Vector3.ZERO
	if parent is CharacterBody3D:
		vel = (parent as CharacterBody3D).velocity
	var pq_origin := origin + vel * predict_seconds
	var pq := PhysicsRayQueryParameters3D.create(pq_origin, pq_origin + Vector3.DOWN * 30.0)
	pq.collision_mask = ray_mask
	pq.exclude = [parent.get_rid()]
	var phit := space.intersect_ray(pq)
	if phit.is_empty():
		_predict_mesh.visible = false
		return
	_predict_mesh.visible = true
	_predict_mesh.global_position = (phit["position"] as Vector3) + Vector3.UP * 0.013
	var pred_r := lerpf(radius_at_ground, radius_at_height, t) * predictor_radius_scale
	_predict_mesh.scale = Vector3(pred_r, 1.0, pred_r)
	_predict_mat.albedo_color = Color(0.02, 0.01, 0.01, predictor_alpha_max * (1.0 - t * t))


func _on_juice_changed(key: StringName, enabled: bool) -> void:
	if key == &"blob_shadow":
		_enabled = enabled
	elif key == &"predict_landing":
		_predict_enabled = enabled


func _on_blob_shadow_param_changed(param: StringName, value: float) -> void:
	match param:
		&"radius_at_ground":       radius_at_ground = value
		&"radius_at_height":       radius_at_height = value
		&"fade_height":            fade_height = value
		&"alpha_max":              alpha_max = value
		&"predict_seconds":        predict_seconds = value
		&"predictor_radius_scale": predictor_radius_scale = value
		&"predictor_alpha_max":    predictor_alpha_max = value
