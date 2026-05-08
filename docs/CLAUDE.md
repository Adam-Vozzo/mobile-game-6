# Project Void — Mobile 3D Platformer

## Mandate

Build a mobile 3D platformer fusing Dadish 3D's accessible charm with Super Meat Boy's precision/momentum/instant-respawn grammar, set in a brutalist megastructure inspired by Tsutomu Nihei's BLAME!. Polished vertical slice first, then content expansion, then ship polish.

The two non-negotiable craft pillars are character controller feel and level design. Everything else serves these.

## Style direction

### World

Brutalist megastructure. Vast inhuman scale, exposed concrete, geometric repetition, industrial decay, twisted organic-mechanical fusion in deeper layers. Heavy fog, sparse pools of warm light in vast darkness. Verticality as a primary design dimension — falling shafts, climbing towers, narrow ledges over voids. Architecture authored under real principles, not just dressed-up corridors. See `docs/LEVEL_DESIGN.md`.

### Palette

Concrete greys, charcoal, rust orange, sodium-vapour yellow. Biolume cyan as rare accent in deeper layers. Deep blacks (OLED-friendly). The protagonist's red is the constant focal point — the only bright warm thing in the world. Use red sparingly elsewhere; if everything is red, nothing is.

### Protagonist — the Stray

A small stray robot. Chibi proportions, readable silhouette. Single bright red accent — power core, single visor lens, antenna light, or chest indicator (decide during art direction). Mechanical movement language: servo whirs on motion, soft clanks on landing, brief electrical flicker on damage, reboot animation on respawn (sparks → dark frame → power-on hum → upright). The Stray is a fragment of the world that has wandered off and become its own thing. The world was not built for them, and that is the whole point.

### Tone

Oppressive scale tempered by the protagonist's small bright presence. Loneliness and awe over jump-scares. Levels are environmental storytelling — see `docs/LEVEL_DESIGN.md` — not jokes. Light moments emerge from physical comedy of small robot in big world, not text or character voice. Likely zero dialogue.

### Audio

Echoing footsteps and servo whirs, sparse industrial ambience, hum of distant machinery, occasional far-off mechanical groan. Punchy player-action SFX (anticipation + impact + tail) that read clearly against the quiet world. Music: minimal, atmospheric, building from drone toward sparse melody at moments of vista or arrival.

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
  README.md       # human dashboard — full update log lives here
  PLAN.md         # rolling plan
  DECISIONS.md    # ADR-lite log of significant choices
  JUICE.md        # catalog of juice elements + state
  LEVEL_DESIGN.md # level design philosophy
  ART_PIPELINE.md # how to swap primitives for real art
  ANDROID.md      # Android build / signing notes
  /research       # research notes by topic, INDEX.md lists them
/tests            # GUT tests where applicable
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
