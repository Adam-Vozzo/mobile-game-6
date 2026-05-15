# Project Void — Mobile 3D Platformer

## Mandate

Build a mobile 3D platformer fusing Dadish 3D's accessible charm with Super Meat Boy's precision/momentum/instant-respawn grammar, set in a brutalist megastructure inspired by Tsutomu Nihei's BLAME!. Polished vertical slice first, then content expansion, then ship polish.

The two non-negotiable craft pillars are character controller feel and level design. Everything else serves these.

## Style direction

### World

Brutalist megastructure. Vast inhuman scale, exposed concrete, geometric repetition, industrial decay, twisted organic-mechanical fusion in deeper layers. Heavy fog, sparse pools of warm light in vast darkness. Verticality as a primary design dimension — falling shafts, climbing towers, narrow ledges over voids. Architecture authored under real principles, not just dressed-up corridors. See `docs/LEVEL_DESIGN.md`.

### Palette

Concrete greys, charcoal, rust orange, sodium-vapour amber. Biolume cyan as rare accent in deeper layers. Deep blacks (OLED-friendly). The protagonist's bright lemon yellow is the constant focal point — the only saturated warm thing in the world. The world's sodium lighting reads more amber/muted than the chick's lemon-yellow to keep tonal separation. Use saturated yellow sparingly elsewhere; if everything is yellow, nothing is.

### Protagonist — the Stray

A small stray bird — a yellow chick (Kenney Cube Pets). Chibi cube-pet proportions, readable silhouette, bright lemon yellow against the cold concrete. Movement language: light footfalls, soft chirps, brief feather-burst on damage, respawn animation (feather-poof → settle → small chirp + flap → upright). Double jump is a literal flap. The Stray is a small living thing that wandered into the megastructure and made a home of it. The world was not built for them, and that is the whole point.

### Tone

Oppressive scale tempered by the protagonist's small bright presence. Loneliness and awe over jump-scares. Levels are environmental storytelling — see `docs/LEVEL_DESIGN.md` — not jokes. Light moments emerge from physical comedy of a small chick in a vast machine-built world, not text or character voice. Likely zero dialogue.

### Audio

Light footfalls and soft chirps from the Stray, sparse industrial ambience, hum of distant machinery, occasional far-off mechanical groan. Wing-flap on double jump. Punchy player-action SFX (anticipation + impact + tail) that read clearly against the quiet world. Music: minimal, atmospheric, building from drone toward sparse melody at moments of vista or arrival.

Placeholder primitives are fine until a style guide is approved. See `docs/ART_PIPELINE.md` when promoting any primitive to real art.

## Target & constraints

* Engine: Godot 4.x (current stable). GDScript by default; only C# if a profiler proves a hot path needs it.
* Renderer: Mobile renderer. Escalate to Forward+ only with justification.
* Platform: Android, landscape locked.
* Test device: Nothing Phone 4(a) Pro. Target locked 60 fps with 8–10 ms frametimes (headroom for thermal throttling).
* Budgets: ~80k tris on-screen max, baked lighting only, ASTC textures, hard particle budget tracked in a `PerfBudget` autoload.
* Input: Touch only. Landscape thumb-zones — left virtual stick, right jump + secondary action. Camera defaults to auto-framing; manual override via right-side drag (NOT a second virtual stick — Dadish 3D reviews show that pattern fails on mobile). Buttons must be repositionable and resizable.
* Cadence: This project runs autonomous iterations approximately every 2 hours, plus ad-hoc human direction. The human will not see every report in real-time. Plan accordingly.

## Reference research

### Super Meat Boy 3D (Sluggerfly + Team Meat, 2026)

Recently released. Tags: precision platformer, fast-paced, time attack, unforgiving, 3D, boss fights, dark world. Inheritor of the SMB grammar in a 3D space. Closest live reference. Watch reviews and developer commentary as they appear.

### Dadish 3D (Thomas K Young, 2024)

Mobile 3D platformer, controller-friendly. Real pain points from Play Store reviews to design around:

* Camera: "always unlocked outside of chase sequences, leading to the player fiddling with the camera." Auto-framing first; manual is a nudge.
* Air control: "character no longer stops mid-flight" was a post-launch fix. Get preserved horizontal velocity right from day one.
* Bar: "touch controls are serviceable… definitely play with a controller if you can." Beat this.
* UX: requests for sensitivity sliders and resizable buttons. Build these in early.

### Other reading worth pursuing during iteration

Postmortems and dev blogs on 3D platformer character controllers — Mario Odyssey (snap-to-grid feel and assists), A Hat in Time (homing-attack as platforming aid), Pseudoregalia (momentum and movetech), Demon Turf (custom physics over rigid-body), Astro's Playroom (juice density). Touch-control discussions for Genshin Impact, Sky: Children of the Light, Alto's Odyssey. Architectural reading: Christopher Alexander on parti and pattern, Kevin Lynch on legibility, video essays on level design from Mark Brown, Steve Lee, Game Maker's Toolkit. Notes go in `docs/research/`.

## Scope gates

Do not advance a gate without the human's explicit OK in chat.

1. **Gate 0 — Feel Lab**: One scene, one character controller, instrumented. Coyote, buffer, variable jump height, air control with preserved horizontal velocity, ground detection, slope handling all working and tunable from the dev menu.
2. **Gate 1 — Vertical Slice**: One full level (~60–90 s skilled, ~3 min new player), checkpoints, instant respawn, attempt-replay overlay (SMB-style ghost trails), one enemy archetype, one collectible type, win state. Brutalist art direction at least roughed in. Level authored using principles in `LEVEL_DESIGN.md`.
3. **Gate 2 — Content Spine**: 8–12 levels in one biome, level-select hub, par-time tracking, basic UX flow.
4. **Gate 3 — Polish & Ship**: Audio pass, juice pass, settings, save/load, accessibility, Play Store build.

## Gate 1 — level direction is direction-finding, not polish

**Active directive (2026-05-16).** The human has not yet picked a level shape-family
to commit to for Gate 1's vertical slice. Two earlier passes on Threshold
(corridor / linear) failed playtest reads — even after a redesign with vision
blockers, multiple routes, fog, collision on dressing, and broader skyline
silhouettes, the level still reads as "a straight line with random blocks
around." That's a shape-family problem, not a polish problem.

Until the human picks a survivor, the autonomous loop's job is **breadth, not
depth**:

* **Build many level scenes in genuinely distinct shape-families.** Every
  iter that touches level design picks the next *unrepresented* style to seed
  — not another pass on an existing one. Variety over polish.
* **Examples of distinct shape-families** (not an exhaustive list; invent
  more): linear corridor (Threshold — already exists), plaza hub with
  radiating spokes (Spyro PS1), vertical climbing tower, cavern / maze with
  branches, open-air rooftop with edge-of-void platforming, ringed
  arena, inverted descent (climbing *down*), enclosed obstacle gauntlet,
  exposed bridge crossing with verticality below. The shape-family is "what
  does the floor plan look like from above" — not theme or dressing.
* **Each new level must be playable end-to-end** (spawn → win state), use
  the same Player + CameraRig + TouchOverlay + Game autoload wiring as
  Threshold, and live under `scenes/levels/`.
* **A `level_select.tscn`** lists every level and lets the human jump
  between them for playtesting. Boot to selector first; selector swaps to
  the chosen `current_level_path`.
* **Don't iterate on Threshold or any prior level** until the human picks a
  survivor — re-polishing rejected shapes is wasted work.
* **When the human picks a survivor:** the loop pivots to depth on that one
  shape, and the others become reference scenes (kept in repo, dropped from
  selector if desired). The directive in this section gets revised at that
  point.

If a planned iter would touch level work but every shape-family is already
represented at least once, escalate to the human and pick a different P0
instead. The point of this directive is to *not* keep polishing the same
shape.

## Architecture conventions

```
/scenes           # .tscn files
  /player
  /levels
  /ui
  /enemies
/scripts          # .gd files mirroring scenes/
/resources        # .tres files (curves, configs, controller variants)
/assets
  /art
  /audio
  /shaders
  ASSETS.md       # licence + source log for all third-party assets
/addons           # Godot plugins
/tools
  /dev_menu       # in-game tweaks UI
  /debug          # overlays, gizmos, profilers
/docs
  CLAUDE.md       # this file
  PLAN.md         # rolling plan
  DECISIONS.md    # ADR-lite log of significant choices
  JUICE.md        # catalog of juice elements + state
  LEVEL_DESIGN.md # level design philosophy
  ART_PIPELINE.md # how to swap primitives for real art
  ANDROID.md      # Android build / signing notes
  /research       # research notes by topic, INDEX.md lists them
/tests            # GUT tests where applicable
README.md         # human dashboard — full update log lives here (repo root)
```

* One scene = one responsibility. Composition over inheritance for player abilities.
* All tunable values live in `Resource` files. Never magic numbers in script bodies.
* Signals for cross-scene comms; small set of autoloads only (`Game`, `Audio`, `Input`, `PerfBudget`, `DevMenu`).
* Naming: `snake_case` for files, `PascalCase` for classes, `_` prefix for private.

## Third-party assets — open access, with logging

You may acquire art, audio, shaders, and shaders from any source you judge useful (Kenney, Quaternius, Sketchfab CC, Mixamo, freesound, OpenGameArt, itch asset packs, public-domain, AI-generated, etc.). No approval needed.

For each asset committed, append an entry to `assets/ASSETS.md`:

```
- assets/art/character/mesh_stray.glb
  Source: <URL or "AI-generated via <tool>">
  Author: <name or "n/a">
  Licence: <CC0 / CC-BY-4.0 / Mixamo EULA / etc.>
  Date acquired: <YYYY-MM-DD>
  Notes: <attribution string if required, modifications made>
```

Style fidelity check before committing any new asset: does it read in the brutalist palette under fog at the camera distance the player will see it? If not, decline or modify it before committing — asset-flip drift is the failure mode.

Avoid GPL-licensed code/assets and "non-commercial" assets unless we're certain the project will never ship — easier to stay clean now than swap later.

Once a real asset is in place, don't swap it without a documented reason in `DECISIONS.md`. Asset churn at high iteration cadence creates instability.

## Character controller — design intent

`CharacterBody3D` with a swappable `ControllerProfile` resource. Profiles to implement:

* **Snappy** (SMB-leaning): high acceleration, low air friction, tight jump arc, short coyote/buffer windows, strong momentum preservation through jumps.
* **Floaty** (Dadish-leaning): smooth accel, generous air control, longer hangtime at apex, larger windows.
* **Momentum** (experimental): ramps speed with sustained input, preserves horizontal velocity through jumps strongly.
* **Assisted** (mobile-first): in-air steering toward likely landing targets, generous ledge grab, auto-snap to platform edges on landing.

All four live-swappable from the dev menu. The human chooses after feeling them on device.

Specific behaviours to nail in every profile:

* Coyote time (~80–120 ms typical).
* Jump buffer (~100–150 ms typical).
* Variable jump height (release-to-cut).
* Preserved horizontal velocity through jumps.
* Slope handling that doesn't feel sticky or slippery.
* Out-of-bounds → instant respawn at last checkpoint, no fade. Stray plays reboot animation.

## Camera — design intent

Third-person, slightly behind-and-above. `SpringArm3D` with:

* Lookahead in horizontal velocity direction.
* Vertical pull when player is airborne with downward velocity.
* Framing assist via `CameraHint` nodes the level author drops in.
* Manual override: right-side touch drag (not a second stick) with sensitivity slider.
* Auto-recenter behind player after a short idle window.

Camera fiddling on mobile is the single biggest pain point in Dadish 3D. Get this right and the touch experience differentiates immediately.

## Dev tweaks menu — required from Gate 0

Togglable overlay (3-finger tap on device, F1 in editor):

* **Controller**: profile dropdown, live sliders, save-as-new-profile.
* **Camera**: damping, lookahead, FOV, height, distance, manual sensitivity.
* **Juice**: independent toggles for screen shake, hitstop, particles, motion trails, squash-stretch, sound layers.
* **Debug viz**: collision shapes, velocity vector, ground/wall normals, jump prediction arc, frametime overlay, draw-call count.
* **Level**: teleport to checkpoints, time scale slider (0.25× to 2×), free-camera mode.
* **Profiles**: save/load full settings snapshots.

## Definition of "done" for any feature

* Works on the test device, OR has a clear "on-device pending" note.
* No new errors in editor or runtime logs.
* No performance regression vs. last `README.md` update (frametime within ±0.5 ms, draw calls within ±10%).
* Tunables exposed in dev menu where applicable.
* Touched code has no obvious smells.
* `README.md`, `PLAN.md`, and other relevant docs updated.
* Any third-party assets logged in `assets/ASSETS.md`.

## What requires the human (do not decide alone)

* Final controller profile selection.
* Art style approval (any move past primitives).
* Audio direction.
* Level concept selection from any options Claude generates.
* Gate transitions (0 → 1 → 2 → 3).
* Anything that costs money, publishes anywhere, or modifies version control history.

## What you can decide alone

* Implementation details inside an approved feature.
* Refactors that preserve behaviour.
* Bug fixes.
* Adding new dev menu controls.
* Adding new ControllerProfile variants.
* New levels within an approved biome and spec.
* Performance work.
* Tests.
* Acquiring third-party assets (with logging in `ASSETS.md`).
* Research notes in `docs/research/`.

## Git workflow

### Iteration startup — read this BEFORE picking work

The 2-hour cadence will create duplicate work if every run starts from a
stale `main` and re-picks the same top P0 item. Before doing anything
else:

1. **List your own open PRs** (`mcp__github__list_pull_requests` with
   `state=open` or `gh pr list --author @me`).
2. **If any open PR already targets the item you would have picked**:
   *do not* open a new branch. Either (a) check out that PR's branch
   and iterate on it, or (b) skip that item and pick the next one in
   `PLAN.md`. Both are fine; opening a parallel branch is not.
3. **If multiple open PRs cover the same item** (it has happened),
   pick the most complete one, merge it, close the rest as duplicates
   with a comment linking to the merged PR. Then continue.
4. Only after that — pull from the top of `PLAN.md`'s queue.

### Per-PR rules

* Push every change to a feature branch and open a PR (no direct
  commits to `main`).
* **Auto-merge: add the `auto-merge` label when you open the PR and
  mark it ready for review.** `.github/workflows/auto-merge.yml`
  squash-merges any non-draft PR carrying that label as soon as the
  event fires. The PR exists for traceability, not as a gate. Belt and
  braces: also call `mcp__github__merge_pull_request` (squash) yourself
  before ending the session — if the workflow already merged it, the
  call is a no-op. Don't end the session with an open PR you intended
  to auto-merge.
* **Exception — open the PR as a *draft* without the `auto-merge`
  label and stop for human review** when the change: alters this Git
  workflow or `.github/workflows/auto-merge.yml`, modifies version
  control history (force push, rewrite, branch delete), introduces a
  paid service, ships outside the repo (Play Store, public release),
  or hits any item in *What requires the human*.
* Never force-push, rewrite history, or delete branches without
  explicit instruction.

### End-of-iteration update

The PR you merge **must** include updates to `docs/PLAN.md` (move the
completed item out of the queue into "Recently completed", re-rank the
queue if needed) and `README.md` (append an "Updates" entry for the
iteration). If those aren't updated, the next run will see stale state
and pick the same item again — exactly the failure mode the iteration
startup rule is meant to prevent.

## Initial kickoff tasks

Do these in order, committing after each:

1. Initialise Godot 4.x project with the folder structure above. Configure project settings: landscape locked, Mobile renderer, ASTC, 60 fps cap, low-end target preset.
2. Set up Android export preset for arm64-v8a, current API target. Document signing/keystore in `docs/ANDROID.md` (do not generate keys — leave a stub).
3. Create documentation files: `PLAN.md`, `DECISIONS.md`, `JUICE.md`, `README.md` (use the template provided), `assets/ASSETS.md` (empty header), `docs/research/INDEX.md`.
4. Build the Feel Lab scene: small test arena with platforms of varied size/spacing, slopes, walls, a moving platform. Brutalist primitive aesthetic — grey concrete-shader cubes, fog, single warm light source.
5. Implement `CharacterBody3D` player (the Stray) with the Snappy profile working end-to-end. Coyote, buffer, variable jump, preserved horizontal velocity, ground/slope detection, instant respawn with placeholder reboot effect (red flash → dark → fade in).
6. Implement dev menu skeleton with at minimum: controller profile dropdown, 3–4 live sliders, juice toggle stubs.
7. Implement spring-arm camera with lookahead and right-drag manual override.
8. Implement touch input: virtual stick (left), jump button (right), repositionable. Settings stub for repositioning.
9. Verify on-device build instructions in `ANDROID.md`.
10. Update `PLAN.md` and `README.md` with what's next.

When kickoff is done, stop and report back. Do not start Gate 1 work without a green light.
