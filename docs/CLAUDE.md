# Project Void — CLAUDE.md
## Authoritative guide for autonomous iterations

---

## What the game is

**Project Void** is a mobile-first 3D platformer for Android/iOS.

Aesthetic: **Brutalist**. Cold, desaturated world. Heavy geometry. Sparse light.
Warmth: **The Stray** — a small red glowing object in each level, the only warm colour.
References: Super Mario Bros. 3D (movement language), Dadish 3D (mobile touch ergonomics, feel), Journey (environmental storytelling).

---

## Scope / gates

Progress is gated. **Only the human advances gates.**

| Gate | Name | Done when |
|------|------|-----------|
| 0 | Foundation | Player moves, jumps, and lands in FeelLab. Touch controls functional. Dev menu exposed. |
| 1 | Feel | Human approves the core jump/move feel. ControllerProfile saved. |
| 2 | Level 01 | First playable level with Stray collectible and goal. |
| 3 | Camera | Auto-framing camera approved by human. |
| 4 | Polish | Juice pass approved. Sound pass done. Export to device. |
| 5 | Ship | Play Store / App Store submission. |

---

## Style direction

- **Restraint always wins**. Less colour, more fog, sparser lights, bigger empty spaces.
- **Red is precious**. The Stray is the only red object in the world. No red in UI except the Jump button (thematic: action = warmth).
- **Grey palette**: concrete #6b6c70, shadow concrete #3a3b3d, sky/fog #1d1f22.
- **Geometry**: BoxMesh/CapsuleMesh primitives are fine. No organic shapes.
- **Fog**: always on. density ~0.015–0.025. Contributes to depth and mystery.
- **Lighting**: one key DirectionalLight, low ambient, no colourful fills.

Before adding any colour: ask "does this dilute red?"

---

## Architecture overview

```
scenes/
  feel_lab/   FeelLab.tscn + feel_lab.gd  ← primary test scene (Gate 0–1)
  player/     Player.tscn                  ← CharacterBody3D + player.gd
  camera/     GameCamera.tscn              ← Node3D + game_camera.gd
  ui/         TouchControls.tscn, DevMenu.tscn

scripts/
  autoloads/  game_manager.gd              ← registered autoload
  player/     controller_profile.gd, player.gd
  camera/     game_camera.gd
  ui/         touch_controls.gd, dev_menu.gd, virtual_joystick.gd

resources/
  profiles/   default.tres                 ← ControllerProfile .tres files

docs/
  PLAN.md, DECISIONS.md, JUICE.md, LEVEL_DESIGN.md, research/

assets/
  ASSETS.md                               ← required for every third-party asset

tests/unit/                               ← GUT tests (GUT addon: future)
```

---

## Key systems

### ControllerProfile
A `@tool` Resource (`controller_profile.gd`) holding all movement tunables.  
Saved as `.tres` files in `resources/profiles/`.  
The dev menu dynamically generates sliders from profile properties.  
**Every new tunable must be added to ControllerProfile, not hardcoded.**

### Player (`player.gd`)
`CharacterBody3D`. Reads `move_input: Vector2` and `jump_held: bool` set externally each physics frame by the scene controller (e.g., `feel_lab.gd`).  
`on_jump_pressed()` / `on_jump_released()` called on events.  
Implements: coyote time, jump buffer, variable jump height via gravity scaling.

### Touch Controls (`touch_controls.gd` + `virtual_joystick.gd`)
Landscape layout: joystick anchored bottom-left, jump button anchored bottom-right.  
Signals: `move_changed(Vector2)`, `jump_pressed`, `jump_released`.  
Keyboard fallback registered in `game_manager.gd` (WASD + Space, backtick for dev menu).  
**Thumb-reach check**: joystick area must stay within 260px of left edge; jump button within 260px of right edge on 1080p landscape.

### Camera (`game_camera.gd`)
Follows player by tracking facing direction (yaw lerp). `distance` and `height` are `@export`. No manual orbit in base implementation.  
`CameraHint` zones (future): trigger lerp to scripted camera positions. Do not add manual orbit control without a CameraHint alternative first.

### Dev Menu (`dev_menu.gd`)
Toggled with backtick (`` ` ``). Dynamically builds sliders from a bound `ControllerProfile`.  
**Rule**: every new gameplay tunable exposed in the dev menu the same iteration it's added.  
Profile changes are live (modify the resource in-place; player reads each frame).

### Juice system (`JUICE.md`)
Every juice element has an independent toggle in the dev menu's Juice section.  
Log each new element in `JUICE.md`: name, toggle property, description, date added.

---

## Git workflow

### Branch naming
- Feature/fix: `iter/<short-task-name>`
- Autonomous iteration: use the pre-assigned branch in the iteration prompt (`claude/...`)

### Iteration startup
1. `git fetch origin && git log --oneline -20`
2. Check for open PRs (`mcp__github__list_pull_requests state=open`). If an open PR targets the same task, check out that branch instead of forking a new one.
3. Never open a parallel branch for in-flight work.

### Landing PRs
- Add `auto-merge` label + mark ready. The workflow squash-merges on label.
- Belt-and-braces: also call `mcp__github__merge_pull_request` with `merge_method: squash` before ending the session.

### Draft-only (stop for human)
Open as **draft, no `auto-merge` label** for:
- Changes to `.github/workflows/auto-merge.yml` or `docs/CLAUDE.md`
- Anything that modifies version-control history
- Paid service integration
- Public / Play Store release

---

## What requires the human

- Approving game feel (moving past Gate 1)
- Advancing any gate
- Approving level layout before final polish
- Choosing style direction when genuinely ambiguous
- Any paid service or external release

---

## Conventions

- No comments explaining *what* code does. Only *why* if non-obvious.
- Methods ≤ 40 lines. Split if larger.
- Constants in `ControllerProfile` or a `@export` — not as magic numbers.
- Scene UIDs: any unique alphanumeric string in Godot 4 format `uid://XXXXXXXX`. Keep them readable.
- GUT tests live in `tests/unit/`. Test file prefix: `test_`.
- Third-party assets: entry in `assets/ASSETS.md` before committing.
- Research notes: `docs/research/<topic>.md`. Update `docs/research/INDEX.md`.

---

## Performance targets (Gate 0–1)

| Metric | Budget |
|--------|--------|
| Frametime | ≤ 16.7 ms (60 fps) on mid-range Android |
| Draw calls | ≤ 80 per frame in FeelLab |
| Script time | ≤ 2 ms per frame |

Use Godot's built-in profiler. Capture numbers in every README update entry.
