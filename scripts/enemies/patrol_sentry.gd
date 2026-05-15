extends AnimatableBody3D
class_name PatrolSentry
## Slow linear-patrol enemy. Zero AI — moves back and forth along a local
## axis, reverses at each endpoint, optional pause at each end.
##
## Visual is built programmatically: a dark BoxMesh body with an amber
## emissive eye strip on the +Z face.  Kill zone is a programmatic Area3D
## carrying hazard_body.gd, sized slightly larger than the visual body so it
## triggers before the physics wall stops the player.
##
## Dev menu live-tunes patrol_speed, patrol_distance, and wait_duration via
## DevMenu.sentry_param_changed.  bob_enabled is toggled via the same signal.

## Speed along patrol_axis in m/s.
@export_range(0.5, 8.0, 0.1) var patrol_speed: float = 2.5
## Total one-way distance; sentry travels half in each direction from spawn.
@export_range(1.0, 20.0, 0.5) var patrol_distance: float = 8.0
## Local-space direction of patrol movement.
@export var patrol_axis: Vector3 = Vector3.RIGHT
## Pause at each endpoint (0 = instant reversal).
@export_range(0.0, 3.0, 0.1) var wait_duration: float = 0.5
## Gentle sine Y-bob — gives a "hovering drone" read.
@export var bob_enabled: bool = true

## Half-extent of the visual + physics body (0.8 m cube).
const BODY_HALF     := 0.40
## Kill-zone half-extent — slightly larger so Area3D fires before physics wall.
const KILL_HALF     := 0.50
const BOB_AMPLITUDE := 0.08   # metres
const BOB_PERIOD    := 2.0    # seconds per full sine cycle

var _origin: Vector3
var _offset: float = 0.0   # signed displacement from _origin along patrol_axis
var _dir: float    = 1.0   # +1 or -1
var _wait_t: float = 0.0
var _waiting: bool = false
var _bob_t: float  = 0.0


func _ready() -> void:
	_origin = position
	_setup_visual()
	_setup_kill_zone()
	_connect_dev_menu()


func _setup_visual() -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * BODY_HALF * 2.0
	mi.mesh = box
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.18, 0.18, 0.20)
	body_mat.roughness = 0.85
	mi.set_surface_override_material(0, body_mat)
	add_child(mi)

	# Amber emissive eye strip on the +Z face — reads as "active / dangerous"
	var strip := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(BODY_HALF * 1.2, 0.05, 0.02)
	strip.mesh = sbox
	strip.position = Vector3(0.0, 0.0, BODY_HALF + 0.015)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.12, 0.07, 0.0)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.55, 0.05)   # sodium-vapour amber
	eye_mat.emission_energy_multiplier = 2.2
	strip.set_surface_override_material(0, eye_mat)
	mi.add_child(strip)

	# Physics collision shape (World layer by default)
	var col := CollisionShape3D.new()
	var cshape := BoxShape3D.new()
	cshape.size = Vector3.ONE * BODY_HALF * 2.0
	col.shape = cshape
	add_child(col)


func _setup_kill_zone() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2   # player layer
	var hb_script := load("res://scripts/levels/hazard_body.gd")
	if hb_script != null:
		area.set_script(hb_script)
	var ks := CollisionShape3D.new()
	var kbox := BoxShape3D.new()
	kbox.size = Vector3.ONE * KILL_HALF * 2.0
	ks.shape = kbox
	area.add_child(ks)
	add_child(area)


func _connect_dev_menu() -> void:
	var dm := get_node_or_null(^"/root/DevMenu")
	if dm == null or not dm.has_signal("sentry_param_changed"):
		return
	dm.sentry_param_changed.connect(_on_sentry_param_changed)


func _on_sentry_param_changed(prop: StringName, value: Variant) -> void:
	set(prop, value)


func _physics_process(delta: float) -> void:
	_bob_t += delta
	_tick_patrol(delta)
	var ax := patrol_axis.normalized()
	var bob_y := sinf(_bob_t * TAU / BOB_PERIOD) * BOB_AMPLITUDE if bob_enabled else 0.0
	position = _origin + ax * _offset + Vector3.UP * bob_y


func _tick_patrol(delta: float) -> void:
	if _waiting:
		_wait_t += delta
		if _wait_t >= wait_duration:
			_waiting = false
			_wait_t = 0.0
		return
	var half := patrol_distance * 0.5
	var new_offset := _offset + _dir * patrol_speed * delta
	if new_offset >= half:
		_offset = half
		_dir = -1.0
		if wait_duration > 0.0:
			_waiting = true
	elif new_offset <= -half:
		_offset = -half
		_dir = 1.0
		if wait_duration > 0.0:
			_waiting = true
	else:
		_offset = new_offset
