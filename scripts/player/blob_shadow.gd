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

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _enabled: bool = true


func _ready() -> void:
	_build_mesh()
	if has_node("/root/DevMenu"):
		@warning_ignore("return_value_discarded")
		DevMenu.juice_toggle_changed.connect(_on_juice_changed)
		_enabled = DevMenu.is_juice_on(&"blob_shadow")


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


func _process(_delta: float) -> void:
	if not _enabled:
		_mesh.visible = false
		return

	var parent := get_parent()
	if parent == null:
		_mesh.visible = false
		return

	var origin: Vector3 = parent.global_position
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 25.0)
	query.collision_mask = ray_mask
	query.exclude = [parent.get_rid()]
	var hit := space.intersect_ray(query)

	if hit.is_empty():
		_mesh.visible = false
		return

	var height := origin.y - (hit["position"] as Vector3).y
	if height > fade_height:
		_mesh.visible = false
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


func _on_juice_changed(key: StringName, enabled: bool) -> void:
	if key == &"blob_shadow":
		_enabled = enabled
