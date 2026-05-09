@tool
class_name ControllerProfile
extends Resource

@export_group("Horizontal Movement")
@export var walk_speed: float = 7.0
@export var acceleration: float = 30.0
@export var friction: float = 25.0
@export var air_acceleration: float = 15.0
@export var air_friction: float = 5.0

@export_group("Vertical Movement")
## Applied every physics frame when airborne (m/s²).
@export var base_gravity: float = 25.0
@export var jump_velocity: float = 11.0
## Gravity scale while rising with jump held — lowers peak gravity for higher hold-jump.
@export var jump_hold_gravity_scale: float = 0.5
## Gravity scale during fall — snappier landing.
@export var fall_gravity_scale: float = 2.0
@export var max_fall_speed: float = 30.0

@export_group("Jump Assist")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.15

@export_group("Rotation")
@export var turn_speed_deg: float = 720.0
