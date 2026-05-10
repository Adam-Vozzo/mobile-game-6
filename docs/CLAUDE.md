# CLAUDE.md — Project Void

## Project overview

Project Void is a mobile 3D platformer for Android (primary) / iOS (secondary), built in Godot 4.6.
The player guides **The Stray** — a small solitary figure navigating brutalist megastructures.
Tone: cold, quiet, architectural. Movement is the vocabulary. Red is precious.

## Tech stack

- Godot 4.6, **Mobile renderer** (forward+/mobile, not compatibility)
- **Jolt Physics** (3D) — already configured in project.godot
- GDScript 4 throughout — no C#, no GDNative
- Target: Android (primary), iOS (secondary), Desktop as dev convenience
- Orientation: **landscape only**

## Directory conventions

```
scenes/             .tscn files
  player/           player & camera rig scenes
  ui/               HUD, dev menu, virtual joystick
  levels/           level scenes (feel_lab, level_01, …)
scripts/            .gd files
  autoloads/        singletons: InputManager, GameManager
  player/           player.gd, camera_rig.gd
  ui/               virtual_joystick.gd, dev_menu.gd, hud.gd
  levels/           level-specific logic
resources/          .tres files
  controller_profiles/  named feel presets
assets/             binary assets (models, audio, textures)
  ASSETS.md         REQUIRED manifest for all third-party assets
docs/               this folder
  research/         research notes (one file per topic)
tests/              GUT test files
```

## Code conventions

- GDScript: `snake_case` for variables/functions, `PascalCase` for class names
- `@export` every tunable — **no magic numbers in code bodies**
- Signals over direct calls for cross-system communication
- Max **40 lines per method**; split if longer, log the debt if it'll need a refactor
- No comments explaining *what* — only *why* (hidden constraints, workarounds, non-obvious invariants)
- Autoloads available everywhere: `InputManager`, `GameManager`

## Dev menu

**Every tunable must be exposed in the dev menu the same iteration it's introduced.**
Tunables not in the dev menu don't exist.

Toggle: triple-tap the top-left corner of the screen (or press F1 on desktop).
Registration API: `DevMenu.register_float(section, label, obj, prop, min, max)`
                  `DevMenu.register_bool(section, label, obj, prop)`
                  `DevMenu.register_action(section, label, callable)`

## Git workflow

### Iteration startup
1. Check open PRs (GitHub MCP or `gh pr list --author @me --state open`).
2. If an open PR targets your planned item → check out that branch; don't fork a parallel branch.
3. Otherwise branch from `main`: `iter/<short-task-name>`.
4. One PR per iteration; small commits; imperative messages.

### Designated session branch
The session system may assign a `claude/*` branch. Use it if assigned; otherwise follow iter/* above.

### Merging
- Add `auto-merge` label to the PR; squash-merge workflow fires automatically.
- Belt-and-braces: also call `mcp__github__merge_pull_request` with `merge_method: squash`.
- **Open as draft, no label, stop for human review** if the change:
  - Alters `.github/workflows/auto-merge.yml` or `CLAUDE.md`
  - Rewrites history or force-pushes
  - Introduces a paid external service
  - Hits anything in *What requires the human* below

## Style direction — Brutalist Cold

- **Palette**: near-black base, concrete mid-grey, off-white/grey fog. **Red only for The Stray** (warm accent).
- No saturation in environment materials. Warmth is earned, not ambient.
- **Geometry**: heavy slabs, columns, voids, overhangs. No curves except The Stray.
- **Fog**: 15–30 m. Long sightlines break the feel.
- **Lighting**: 1–2 dim directional lights (cold white/blue). Rare warm point lights as navigation anchors.
- **Sound** (Gate 3+): industrial hum, concrete footsteps, sparse ambient. No music before Gate 3.
- When in doubt: **remove**. Brutalism is restraint, not decoration.
- Red is **precious** — every red object is a meaningful signal. Don't dilute it.

## Camera philosophy

Auto-frame first. The camera must never require manual input to see what matters.
Use `CameraHint` area volumes to trigger re-framing at key moments.
Only add manual camera rotation if auto-framing demonstrably fails across three distinct scenarios.
On mobile, camera swipe (drag on right half of screen, away from buttons) is acceptable as *supplementary* — never as *required*.

## Touch input ergonomics (landscape)

```
┌────────────────────────────────────────────────┐
│ [DEV]                                          │
│                                                │
│                                                │
│                        ╔══════════╗            │
│  ◉ joystick            ║  JUMP   ║            │
│  (bottom-left)         ╚══════════╝            │
└────────────────────────────────────────────────┘
```

- Left thumb zone: movement joystick (bottom-left ~30% of screen)
- Right thumb zone: jump button (bottom-right ~20% of screen)
- Camera swipe: right half of screen, excluding button zone
- Joystick radius: ~80 px at 1080p (scale with screen DPI)

## Gates (human advances; Claude **never** advances a gate)

| Gate | Name | Cleared when |
|------|------|--------------|
| 0 | Foundation | Player moves, camera follows, Feel Lab runs, dev menu live |
| 1 | Core Feel | Human approves movement/jump feel; all tunables in dev menu |
| 2 | Level 1 Draft | Level 1 playable end-to-end |
| 3 | Polish & Juice | Juice pass, sound, game loop complete |
| 4 | Ship Ready | Perf certified on device, store assets ready |

**Current gate: 0**

## What requires the human

- Gate transitions (feel verdicts, style approvals)
- Any new paid / external service
- Major art direction changes (new character design, palette shift)
- Changes to `CLAUDE.md` or `.github/workflows/auto-merge.yml`
- Direct pushes to `main`

## Not-alone list (stop and ask before proceeding)

- Altering the auto-merge workflow
- Rewriting published history / force-push
- Introducing a new service that costs money
- Advancing a gate
- Redesigning The Stray's appearance or making canon story decisions
