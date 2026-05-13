extends Area3D
class_name DataShard
## Gate 1 collectible — the data shard.
## A small cyan emissive gem rotating slowly in place. One per level, placed
## off the par route. Adds itself to the "data_shard" group so level scripts
## can auto-count via get_tree().get_nodes_in_group("data_shard").size().
## On collection: increments Game.shards_collected, hides the mesh, and
## plays a brief light-pulse before fading. Call respawn_shard() to reset
## (used by the dev menu without reloading the level).
##
## Collection geometry: SphereShape3D radius 0.6 m + player capsule radius
## 0.28 m = 0.88 m total overlap threshold. At default Snappy jump_velocity
## (11.5 m/s) / gravity_rising (38.0 m/s²) the apex is ~1.74 m above takeoff,
## letting the player collect a shard placed ~1.3 m above any platform surface
## without reaching it while standing.

var _collected: bool = false
var _mesh_instance: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group(&"data_shard")
	# Player is on collision_layer = 2 (see player.tscn). The Area3D's default
	# mask of 1 doesn't overlap, so body_entered never fired before this — the
	# player walked through the shard with no effect. Mask = 2 catches the
	# player specifically.
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	rotate_y(delta * 1.15)  # ~66 deg/s ≈ 11 rpm — readable spin without blur


func _build_visual() -> void:
	# Collision sphere — generous radius so mobile thumb latency doesn't punish
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	col.shape = sphere
	add_child(col)

	# Gem mesh (octahedron — two four-sided pyramids sharing an equatorial ring)
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _build_gem_mesh()
	add_child(_mesh_instance)

	# Cyan glow — casts a thin cone of light on nearby geometry
	_light = OmniLight3D.new()
	_light.light_color = Color(0.12, 0.90, 0.95)
	_light.light_energy = 1.4
	_light.omni_range = 4.5
	_light.shadow_enabled = false
	add_child(_light)


func _build_gem_mesh() -> ArrayMesh:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.78, 0.88)
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.78, 0.88)
	mat.emission_energy_multiplier = 3.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Disable back-face culling — gem is tiny and viewed from all angles
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)

	# Six vertices: top, four equatorial, bottom
	var v: Array[Vector3] = [
		Vector3(0.0,   0.28,  0.0),   # 0 top
		Vector3(0.20,  0.0,   0.0),   # 1 eq +x
		Vector3(0.0,   0.0,   0.20),  # 2 eq +z
		Vector3(-0.20, 0.0,   0.0),   # 3 eq -x
		Vector3(0.0,   0.0,  -0.20),  # 4 eq -z
		Vector3(0.0,  -0.22,  0.0),   # 5 bottom (slightly flatter than top)
	]

	# Upper hemisphere — 4 triangles fanning from top
	for i: int in range(4):
		st.add_vertex(v[0])
		st.add_vertex(v[1 + (i + 1) % 4])
		st.add_vertex(v[1 + i])

	# Lower hemisphere — 4 triangles fanning from bottom
	for i: int in range(4):
		st.add_vertex(v[5])
		st.add_vertex(v[1 + i])
		st.add_vertex(v[1 + (i + 1) % 4])

	return st.commit()


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body is Player:
		return
	_collect()


func _collect() -> void:
	_collected = true
	if has_node("/root/Game"):
		Game.shards_collected += 1
	# Hide the mesh immediately; keep the light visible for the pulse
	if is_instance_valid(_mesh_instance):
		_mesh_instance.visible = false
	# Disable monitoring so the signal can't fire twice during the fade
	set_deferred(&"monitoring", false)
	if is_instance_valid(_light):
		var tween := create_tween()
		tween.tween_property(_light, "light_energy", 7.0, 0.05)
		tween.tween_property(_light, "light_energy", 0.0, 0.30)
		tween.tween_callback(_on_pulse_done)
	else:
		_on_pulse_done()


func _on_pulse_done() -> void:
	if is_instance_valid(_light):
		_light.visible = false


## Resets the shard to its pre-collection state.
## Called from the dev menu "Respawn shard" button without reloading the level.
func respawn_shard() -> void:
	_collected = false
	if is_instance_valid(_mesh_instance):
		_mesh_instance.visible = true
	if is_instance_valid(_light):
		_light.visible = true
		_light.light_energy = 1.4
	set_deferred(&"monitoring", true)
