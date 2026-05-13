extends AnimatableBody3D
class_name IndustrialPress
## Vertical-crush industrial press hazard. Four-beat cycle:
##   dormant → windup → stroke → rebound
## The press descends on Y by stroke_depth during the stroke beat.
## Emissive amber strip on the underside brightens through windup → stroke.
## KillZone (HazardBody child, Area3D) moves with the press and triggers
## respawn when a Player enters it.
##
## Dev menu live-tunes via DevMenu.press_param_changed signal.

@export_range(0.5, 5.0, 0.05) var stroke_depth: float = 2.5
@export_range(0.3, 3.0, 0.05) var dormant_time: float = 1.5
@export_range(0.3, 2.0, 0.05) var windup_time: float = 0.80
@export_range(0.05, 0.5, 0.01) var stroke_time: float = 0.18
@export_range(0.2, 2.0, 0.05) var rebound_time: float = 0.50

enum Phase { DORMANT = 0, WINDUP = 1, STROKE = 2, REBOUND = 3 }

var _phase: Phase = Phase.DORMANT
var _phase_t: float = 0.0
var _origin_y: float = 0.0
var _emissive_mat: StandardMaterial3D = null


func _ready() -> void:
	_origin_y = position.y
	_setup_emissive()
	_connect_dev_menu()


func _setup_emissive() -> void:
	var strip := get_node_or_null(^"EmissiveStrip") as MeshInstance3D
	if strip == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.08, 0.01)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.12)   # sodium-vapour amber
	mat.emission_energy_multiplier = 0.3
	strip.set_surface_override_material(0, mat)
	_emissive_mat = mat


func _connect_dev_menu() -> void:
	var dm := get_node_or_null(^"/root/DevMenu")
	if dm != null and dm.has_signal("press_param_changed"):
		dm.press_param_changed.connect(_on_press_param_changed)


func _on_press_param_changed(prop: StringName, value: float) -> void:
	set(prop, value)


func _physics_process(delta: float) -> void:
	_phase_t += delta
	var dur := _phase_duration()
	if _phase_t >= dur:
		_phase_t -= dur
		_phase = Phase((_phase + 1) % 4)
	position.y = _target_y()
	_update_emissive()


func _phase_duration() -> float:
	match _phase:
		Phase.DORMANT:  return dormant_time
		Phase.WINDUP:   return windup_time
		Phase.STROKE:   return stroke_time
		Phase.REBOUND:  return rebound_time
	return 1.0


func _target_y() -> float:
	var dur := maxf(_phase_duration(), 0.001)
	var p := _phase_t / dur
	match _phase:
		Phase.DORMANT:
			return _origin_y
		Phase.WINDUP:
			# Small retraction (0.3 m back) before the slam
			return _origin_y + p * 0.3
		Phase.STROKE:
			return _origin_y - p * stroke_depth
		Phase.REBOUND:
			return (_origin_y - stroke_depth) + p * stroke_depth
	return _origin_y


func _update_emissive() -> void:
	if _emissive_mat == null:
		return
	var dur := maxf(_phase_duration(), 0.001)
	var energy: float
	match _phase:
		Phase.DORMANT:
			energy = 0.3
		Phase.WINDUP:
			energy = lerpf(0.3, 2.5, _phase_t / dur)
		Phase.STROKE:
			energy = 2.5
		Phase.REBOUND:
			energy = lerpf(2.5, 0.3, _phase_t / dur)
	_emissive_mat.emission_energy_multiplier = energy
