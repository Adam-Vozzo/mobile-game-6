# Project Void — Decisions Log

Format: **Context → Decision → Alternatives → Consequence**

---

## ADR-001: Physics engine — Jolt over Godot default

**Date**: 2026-05-08
**Context**: Godot 4.x ships with GodotPhysics 3D and Jolt as alternatives. The project needs predictable character controller behaviour: consistent step-up heights, no ghost collisions, reliable `is_on_floor()` detection at 60 fps on mobile.
**Decision**: Use Jolt Physics (already configured in project.godot from setup). Keep throughout development unless a Jolt-specific bug arises.
**Alternatives**: GodotPhysics 3D — familiar but known for jitter at mobile framerates and inconsistent floor detection on slopes.
**Consequence**: Jolt is deterministic and consistent. Some Godot tutorials assume GodotPhysics; we may need Jolt-specific workarounds for edge cases. Log these here.

---

## ADR-002: Camera architecture — SpringArm3D with separate rig node

**Date**: 2026-05-08
**Context**: Third-person camera needs to avoid clipping, follow player smoothly, and allow manual right-drag override. Options: (a) camera as direct child of player, (b) separate Node3D following player with SpringArm3D child, (c) full custom camera class.
**Decision**: Separate CameraRig Node3D (not parented to player) that interpolates its position to the player's position each frame. SpringArm3D is a child of CameraRig. This decouples camera position from player jitter/collision resolution.
**Alternatives**: Child of player — simpler but camera bobs with every collision. Full custom — overkill for Gate 0.
**Consequence**: CameraRig node lives in the level scene (not player scene). Player exposes a `camera_target` marker node. Slightly more setup per level, but camera independence is worth it.

---

## ADR-003: Input architecture — action-based with touch layer on top

**Date**: 2026-05-08
**Context**: Need keyboard/editor testing AND touch-only production. Options: (a) read InputEvent directly in player, (b) use Godot input actions throughout with virtual input injection from touch layer.
**Decision**: Use `Input.get_vector()` and `Input.is_action_pressed()` everywhere in gameplay code. Touch layer (virtual stick + button) injects synthetic key/axis events via `Input.action_press()` and `Input.action_release()`. This means keyboard works in editor unchanged.
**Alternatives**: Direct InputEvent — breaks keyboard fallback. Two separate code paths — duplication, maintenance burden.
**Consequence**: Touch input nodes must carefully manage action state (no double-press without release). Jump buffer is implemented in the player script, not the input layer — means buffer works identically from keyboard and touch.

---

## ADR-004: ControllerProfile as Resource

**Date**: 2026-05-08
**Context**: All controller tunables need to be (a) live-editable from dev menu, (b) saveable as named variants, (c) swappable at runtime without code changes.
**Decision**: `ControllerProfile` extends `Resource`. All exported fields. Four pre-built `.tres` files. Dev menu reads/writes properties by name via `set()`/`get()`. Saved as `.tres` in `resources/controller_profiles/`.
**Alternatives**: Dictionary — no type safety. Autoload singleton — only one profile at a time with no easy swap.
**Consequence**: Adding a new tunable means: add `@export` to ControllerProfile, update dev menu slider list, update all four `.tres` files. Cost is low; the pattern is clear.

---

## ADR-005: Dev menu as CanvasLayer autoload-triggered overlay

**Date**: 2026-05-08
**Context**: Dev menu must be accessible in every scene (Feel Lab, future levels) without being embedded in each scene's tree.
**Decision**: `DevMenu.tscn` is a `CanvasLayer` instantiated by the `Game` autoload on startup and added to the scene tree. `F1` (keyboard) and 3-finger tap (touch) toggle visibility. `Game` autoload holds the reference.
**Alternatives**: Instance in each scene — duplication. Separate Godot layer/overlay — same as CanvasLayer but more complex.
**Consequence**: Dev menu has access to the player and camera via the `Game` autoload's registered references. Player and camera must call `Game.register_player()` / `Game.register_camera()` on `_ready()`.

---

## ADR-006: Gravity implementation — dual-multiplier (rise vs fall)

**Date**: 2026-05-08
**Context**: SMB-style feel requires faster fall than rise (heavier gravity on the way down) to make the jump arc feel punchy and land-readable. Standard single-gravity feels floaty.
**Decision**: `ControllerProfile` exposes `gravity_multiplier` (upward phase) and `fall_gravity_multiplier` (downward phase). Base gravity constant `-30.0 m/s²` in player script. Applied as `GRAVITY * multiplier * delta`.
**Alternatives**: Single gravity with lower jump velocity — can't achieve the SMB arc shape. Curve resource — more expressive but overkill for Gate 0 (tracked in Refactor Backlog).
**Consequence**: Snappy profile uses 2.5× rise / 4.5× fall, giving a sharp up-then-drop arc. Floaty uses 1.8× / 2.2×.
