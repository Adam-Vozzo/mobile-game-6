extends Node
## Performance budget autoload. Tracks tri/draw-call/particle budgets
## against the targets in CLAUDE.md, and exposes them to the dev menu.
##
## Targets: Nothing Phone 4(a) Pro, locked 60 fps, 8–10 ms frametime,
## ~80k tris on-screen, baked lighting only, ASTC textures, hard particle
## budget. The numbers below are starting points; tune as we learn the device.

const TARGET_FPS := 60
const FRAMETIME_BUDGET_MS := 9.0
const TRIANGLE_BUDGET := 80_000
const DRAW_CALL_BUDGET := 200
const ACTIVE_PARTICLES_BUDGET := 256

var triangles_in_frame: int = 0
var draw_calls_in_frame: int = 0
var active_particles: int = 0
var last_frametime_ms: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	# Use actual frame delta so spike frames (e.g. 25 ms hitches) show up
	# correctly rather than being smoothed away by Engine.get_frames_per_second().
	last_frametime_ms = delta * 1000.0
	triangles_in_frame = int(RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	draw_calls_in_frame = int(RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))


func over_budget() -> bool:
	return (
		triangles_in_frame > TRIANGLE_BUDGET
		or draw_calls_in_frame > DRAW_CALL_BUDGET
		or active_particles > ACTIVE_PARTICLES_BUDGET
		or last_frametime_ms > FRAMETIME_BUDGET_MS
	)


func snapshot() -> Dictionary:
	return {
		"fps": Engine.get_frames_per_second(),
		"frametime_ms": last_frametime_ms,
		"triangles": triangles_in_frame,
		"draw_calls": draw_calls_in_frame,
		"active_particles": active_particles,
	}
