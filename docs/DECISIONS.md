# Project Void — Architecture Decisions

Format: context → decision → alternatives → consequence.

---

## D-001 — Physics engine: Jolt Physics

**Context**: Godot 4.6 supports both GodotPhysics and Jolt Physics for 3D.  
**Decision**: Use Jolt Physics (already set in `project.godot`).  
**Alternatives**: GodotPhysics — more familiar but slower; known CCD issues with fast-moving objects.  
**Consequence**: Better performance and more stable collision for fast platformer movement. Jolt is the de-facto standard for Godot 4 3D games as of 2025.

---

## D-002 — Renderer: Mobile renderer

**Context**: Target platforms are Android/iOS.  
**Decision**: Use Godot's Mobile renderer (already set).  
**Alternatives**: Compatibility renderer — lower fidelity; Forward+ renderer — too expensive on mobile.  
**Consequence**: Good balance of visual quality and performance for mid-range devices.

---

## D-003 — Player movement: manual gravity in CharacterBody3D

**Context**: CharacterBody3D doesn't apply gravity automatically.  
**Decision**: Apply gravity manually in `player.gd`'s `_physics_process`, using `base_gravity` from `ControllerProfile` with per-state scale factors.  
**Alternatives**: RigidBody3D — loses precise control over feel; using engine default gravity — doesn't allow variable gravity for jump hold.  
**Consequence**: Full control over jump arc shape. Coyote time and jump buffer are clean to implement. All parameters live in ControllerProfile and are exposed in dev menu.

---

## D-004 — Camera: yaw-following, no orbit

**Context**: Mobile 3D platformers need a camera that works without manual camera control (no right-stick on mobile).  
**Decision**: Camera auto-follows player's facing direction (yaw lerp), positioned behind and above. No manual orbit. `GameCamera.gd` handles this.  
**Alternatives**: Fixed world-space camera (good for fixed-perspective sections, not for open traversal); manual orbit (requires extra input area, bad ergonomics on mobile).  
**Consequence**: Camera always shows what's ahead of player. Needs `CameraHint` zones for scripted transitions in level design. Add those in Gate 2.

---

## D-005 — Input architecture: scene-owned, signals-to-player

**Context**: Player must respond to both touch and keyboard input.  
**Decision**: `feel_lab.gd` (and future level scripts) connect `TouchControls` signals to `Player` methods (`on_jump_pressed`, etc.) and poll keyboard each physics frame. Player exposes `move_input: Vector2` and `jump_held: bool` as settable properties.  
**Alternatives**: Global input singleton — harder to test, tighter coupling; Player polls directly — leaks touch concerns into player logic.  
**Consequence**: Player is input-agnostic. Scene wires input. Keyboard and touch coexist cleanly.

---

## D-006 — Dev menu: dynamically generated from ControllerProfile

**Context**: Tunable count will grow; hardcoding sliders is brittle.  
**Decision**: `dev_menu.gd` builds sliders programmatically by calling `_slider(label, property, min, max)` with string property names. Uses `Resource.get/set` for live modification.  
**Alternatives**: Hardcoded UI in .tscn — doesn't scale; inspector-based editing — requires editor, not useful at runtime.  
**Consequence**: Adding a new tunable is one line in `dev_menu.gd._rebuild_sliders()`. Profile changes are live.

---

## D-007 — ControllerProfile as @tool Resource

**Context**: Movement parameters need to be tweakable at runtime AND saveable as .tres presets.  
**Decision**: `ControllerProfile` is a `@tool` Resource with `@export` properties. Default instance saved as `resources/profiles/default.tres`.  
**Alternatives**: Plain dictionary/autoload — not saveable as preset; Node-based config — bloats scene tree.  
**Consequence**: Profiles are saveable, loadable, inspectable in editor. Human can create variant profiles (e.g., `floaty.tres`, `snappy.tres`) for feel comparison.
