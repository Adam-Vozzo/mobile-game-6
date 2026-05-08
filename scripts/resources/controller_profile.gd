class_name ControllerProfile
extends Resource

## Swappable character controller profile. All values live here — no magic numbers in player.gd.

@export_group("Identity")
@export var profile_name: String = "Snappy"

@export_group("Horizontal Movement")
## Top speed on the ground (m/s).
@export var speed: float = 9.0
## Ground acceleration (m/s² toward target velocity).
@export var acceleration: float = 60.0
## Ground deceleration (m/s² toward zero when no input).
@export var deceleration: float = 60.0
## Air acceleration (m/s² — lower means less mid-air steering).
@export var air_acceleration: float = 25.0
## Air deceleration when no input.
@export var air_deceleration: float = 8.0

@export_group("Jump")
## Vertical impulse applied on jump start (m/s).
@export var jump_velocity: float = 12.0
## Fraction of vertical velocity kept when jump is released early (0–1).
@export var jump_cut_factor: float = 0.35
## Time after leaving a ledge the player can still jump (seconds).
@export var coyote_time: float = 0.10
## How long a pressed jump is buffered before landing (seconds).
@export var jump_buffer_time: float = 0.13

@export_group("Gravity")
## Multiplier on base gravity while rising.
@export var gravity_multiplier: float = 2.5
## Multiplier on base gravity while falling (makes landing feel more deliberate).
@export var fall_gravity_multiplier: float = 4.5
## Terminal fall velocity (m/s, negative).
@export var terminal_velocity: float = -35.0

@export_group("Horizontal Velocity Preservation")
## How much of horizontal velocity is preserved through a jump (0 = none, 1 = full).
## At 1.0 the player carries full momentum into the air.
@export var horizontal_velocity_preservation: float = 1.0

@export_group("Slope")
## Max slope angle the player can walk up (degrees). Steeper = slip off.
@export var max_slope_degrees: float = 45.0

@export_group("Assists")
## Extra forgiveness distance for ledge snapping on landing (meters). 0 = off.
@export var ledge_snap_distance: float = 0.0
## If > 0, steers in-air toward the nearest likely landing target within this radius.
@export var air_steering_assist_radius: float = 0.0
