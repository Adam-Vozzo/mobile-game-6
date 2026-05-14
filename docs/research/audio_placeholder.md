# Audio — Placeholder Strategy for Gate 1

**Context:** Audio direction is gated on human approval (CLAUDE.md). Gate 1 needs
*some* SFX feedback for feel testing, but locking in sounds before the human hears them
causes the same drift problem as locking in a controller profile. This note covers the
architecture choices already made and the options available for the placeholder layer.

---

## Bus hierarchy (implemented: `scripts/autoload/audio.gd`)

```
Master
├── Music        (background loops — not affected by sound_layers toggle)
├── SFX_Player   (player-action events: jump, land, dash, respawn)
└── SFX_World    (world/hazard events: press, hazard contact, ambient pulses)
```

Created at runtime in `Audio._ready()` via `AudioServer.add_bus()` if the bus
doesn't already exist. `SFX_Player` and `SFX_World` are muted together when the
`sound_layers` juice toggle is OFF. Music is never muted by this toggle
(music direction is separate).

**Why three SFX buses?**
The split lets a future mixer drop the world ambience without touching player
feedback, and lets a "player sounds only" mode work for accessibility or focus
testing. Cost: zero CPU/GPU overhead — buses have no processing cost when silent.

---

## Event dispatch points (Gate 1 minimum set)

| Event              | Call site                            | Impact note                          |
|--------------------|--------------------------------------|--------------------------------------|
| `on_jump()`        | `player._try_jump()` (floor + air)   | Also fires for double-jump           |
| `on_land(impact)`  | `player._tick_timers()`, just_landed | `impact` 0..1; 0.25 splits light/heavy |
| `on_collect_shard()` | `data_shard._collect()`            | One per shard per run                |
| `on_respawn_start()` | `player.respawn()`                 | First beat of the reboot animation   |

JUICE.md "Sound layers" table lists three more ideas (servo whir, footsteps, reboot
chord) that can follow once assets land.

---

## Placeholder options — what to use until direction is confirmed

### Option 1: Silence (current — no streams assigned)

All `_sfx_*` vars in `audio.gd` are `null`. `play_sfx(null)` is a safe no-op.
No sound plays at all.

**Pro:** Zero audio drift. The architecture is wired; drop in real streams on approval.  
**Con:** Feel testing on device has no SFX feedback. May feel emptier than the final game
warrants, biasing feel verdicts toward "needs more juice."

### Option 2: Kenney Sci-Fi Sounds (CC0, B5 in ASSET_OPTIONS.md)

Kenney's Sci-Fi Sounds pack (CC0, ~200 short clips) includes mechanical, electronic,
and robotic hits that sit plausibly in the brutalist palette. Landing sounds and sci-fi
beeps would not "feel correct" for servo-whir gameplay, but are credible stand-ins.

- Source: `https://kenney.nl/assets/sci-fi-sounds`
- Licence: CC0
- Concern: Kenney's sci-fi palette skews "retro video game" rather than "mechanical
  industrial." Some sounds could bias the human toward a direction that conflicts with
  the planned servo-whir / clanking-metal approach.

### Option 3: freesound CC0 single-clip placeholders

Individual CC0 clips specifically matching the action type:
- Jump: a short servo-whir click (many available CC0)
- Land (heavy): a concrete-thud impact
- Land (light): a light metallic tap
- Collect: a thin electronic ping (one per shard)
- Respawn: silence or a crackle (onset of reboot)

These are direction-specific ("servo whirs and clanks") — exactly what CLAUDE.md
describes. The risk is lower than a full pack because each is one small clip, not a tone.

**Pro:** Gives feel feedback without committing to an audio style beyond what's already
written in CLAUDE.md.  
**Con:** Acquiring 4–5 separate clips requires human approval as a group, not as a
single pack pick.

### Option 4: Procedural placeholder (AudioStreamGenerator)

Godot 4's `AudioStreamGenerator` can produce silence, sine tones, or noise bursts
in GDScript. A 40 ms sine-burst on jump and a 20 ms noise-burst on land would provide
pure timing feedback without any stylistic cues.

**Pro:** Zero assets required. No direction locked in.  
**Con:** "Blips and bloops" as a placeholder tends to make testers evaluate feel against
a completely wrong reference. Not recommended.

---

## Recommendation

**Ship Option 1 (silence) until the human confirms a sound direction pick** from
ASSET_OPTIONS.md (either B1+B2 freesound loops + B5 Kenney SFX layer, or another
combination). The architecture is live and all dispatch points are wired — adding
streams is a one-line change per event once assets arrive.

If the human wants basic placeholder feedback before approving the full direction,
**Option 3 (individual CC0 freesound clips)** is the lowest-risk path because each
clip is chosen to match the CLAUDE.md description directly. Ask the human to approve
as a group before committing.

Avoid Options 2 and 4 — Kenney may bias the style verdict, procedural sounds mislead
feel evaluation.

---

## AudioStreamRandomizer (for post-direction implementation)

Godot 4's `AudioStreamRandomizer` resource wraps multiple streams and picks one
randomly on each `play()`. For landing sounds especially (heavy footstep vs light
tap), a randomizer with 2–3 variants eliminates the "machine-gun" repetition artifact.

```
_sfx_land_heavy = AudioStreamRandomizer.new()
_sfx_land_heavy.add_stream(0, load("res://assets/audio/sfx/land_heavy_a.ogg"))
_sfx_land_heavy.add_stream(0, load("res://assets/audio/sfx/land_heavy_b.ogg"))
_sfx_land_heavy.random_volume_offset_db = 2.0
_sfx_land_heavy.random_pitch = 0.05
```

Implement this when the first real assets land. No architecture change needed — just
swap the null var for the randomizer resource.

---

## Implications for Project Void

1. **audio.gd is now the single integration point** for all runtime SFX. Call-sites
   in player.gd and data_shard.gd use `Audio.on_*()` — not raw `AudioStreamPlayer`.
2. **sound_layers toggle is now live.** Toggling it off in the dev menu actually
   mutes SFX_Player + SFX_World buses. Previously it was a no-op.
3. **Four event dispatch stubs are wired.** Landing the first stream is a one-liner.
4. **`LAND_HEAVY_THRESHOLD = 0.25`** — tested constant. Tweak if on-device feel suggests
   heavy-clank should trigger later or earlier in the impact range.
5. **Research basis for B5 (Kenney Sci-Fi Sounds) in ASSET_OPTIONS.md** is now
   documented. The pick is a complement to B1+B2 (freesound long-form loops), not a
   replacement. Confirm with human before acquiring.
