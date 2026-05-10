# DECISIONS.md — Project Void

Settled questions. Don't relitigate these.

---

## 001 — Mobile renderer over Compatibility

**Date**: 2026-05-10
**Context**: Godot 4.6 offers three renderers: Forward+, Mobile, Compatibility.
**Decision**: Use **Mobile** renderer.
**Alternatives considered**: Forward+ (richer features but heavier on mobile GPU), Compatibility (WebGL-compatible but fewer shader features).
**Consequence**: Better performance on mid-tier Android/iOS devices. Some advanced post-processing unavailable, but brutalist aesthetic doesn't need them (fog + flat lighting is fine).

---

## 002 — Jolt Physics over Godot default (GodotPhysics)

**Date**: 2026-05-10 (pre-configured in initial commit)
**Context**: Godot 4.4+ ships Jolt as an option; it offers more stable contacts and better performance on complex geometry.
**Decision**: Use **Jolt Physics** (already set in project.godot).
**Alternatives considered**: GodotPhysics (default, well-documented, but jitter on thin platforms).
**Consequence**: More stable character controller; need to test Jolt-specific edge cases (steep slopes, moving platforms). All CharacterBody3D move_and_slide calls should work identically.

---

## 003 — Landscape-only orientation

**Date**: 2026-05-10
**Context**: 3D platformer camera needs horizontal FOV. Portrait gives a tall, narrow view that's hostile to 3D navigation.
**Decision**: **Landscape only**.
**Alternatives considered**: Auto-rotate (complex layout work, poor feel). Portrait (not viable for 3D platformer).
**Consequence**: Touch zones sized for landscape thumbreach. All UI anchored to landscape dimensions.

---

## 004 — Variable gravity (asymmetric rise/fall)

**Date**: 2026-05-10
**Context**: Research note `mobile_touch_controls.md` confirms that all quality mobile 3D platformers use faster fall gravity than rise gravity. Pure Newtonian arcs feel floaty and hard to judge on a small screen.
**Decision**: Two gravity values: `gravity_rise` (default 28) and `gravity_fall` (default 40). Ratio ~1:1.4.
**Alternatives considered**: Single gravity with jump hold (hold to extend jump). Acceptable but adds input complexity; asymmetric gravity achieves the same feel with simpler input.
**Consequence**: Jump arc is fast-up, snappy-down. Coyote time (0.12 s) and jump buffer (0.10 s) pair with this to maintain responsiveness. All values exposed in dev menu.

---

## 005 — DevMenu registration API

**Date**: 2026-05-10
**Context**: Dev menu needs to expose tunables from many different scripts. Hardcoding references couples systems.
**Decision**: **Registration API** — each script calls `DevMenu.register_float(…)` / `register_bool(…)` at ready time.
**Alternatives considered**: Hardcoded references in dev_menu.gd (brittle), reflection/editor plugin (overkill for now).
**Consequence**: Any script can register its tunables independently. DevMenu is a passive display board, not a god-object. Registration happens after the autoload init order, so scripts call `DevMenu.register_*` in `_ready()`.

---

## 006 — CameraRig as scene sibling, not player child

**Date**: 2026-05-10
**Context**: If CameraRig is a child of Player, it inherits player rotation, causing camera spin when The Stray turns.
**Decision**: CameraRig is a **sibling** in the level scene. It holds a `target` NodePath to Player and follows via global position.
**Alternatives considered**: Camera as child with `set_as_top_level(true)` (works but fragile with nested scenes), RemoteTransform3D (one-way, can't drive SpringArm rotation independently).
**Consequence**: Level scenes must include both Player and CameraRig instances. CameraRig `target` export must be set in each level scene.
