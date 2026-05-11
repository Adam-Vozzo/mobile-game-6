# Collectible Design — Research Note

Gate 1 spec requires one collectible type. This note surveys how reference
games handle collectibles and derives a concrete recommendation for Void.

---

## How reference games do it

### Super Meat Boy (2D)
No collectibles in the traditional sense. Bandages are present but purely
optional and cosmetic (unlock Dr. Fetus cutscene characters). They sit on
high-risk detour paths — the player must judge whether the platform risk is
worth the cosmetic reward. This establishes a clean principle: **collectibles
should never live on the critical path**. The core loop — attempt, die, retry
— must be independent of collection state.

### Super Meat Boy 3D (live reference, 2026)
Based on release descriptions, SMB 3D continues the bandage-style optional
cosmetic approach. The main loop is pure survival/time-attack. Collectibles
are placed off the par route, often in clearly visible but awkward-to-reach
locations so the player can see them before deciding to attempt the detour.
Visibility before commitment is key.

### Dadish 3D
Collectibles are narrative: the radishes are *the point* — find all of
Dadish's children. This makes the collectible the win condition, not an
optional overlay. Not applicable to Void's structure (we have a separate
win state, so collectibles must be decoupled from it).

### Celeste
Strawberries: purely cosmetic, placed on hazardous detour paths off the
main route. Crucially: you lose the strawberry if you die after grabbing
it but before reaching the next screen boundary. This "checkpoint grab"
mechanic creates tension without blocking progress. The item's visual
brightness (red on blue/grey) ensures it's readable in every scene.

### Super Mario Odyssey
Two tiers: coins (abundant, low risk, no permanent state — coins exist to be
spent) and Power Moons (sparse, individually named, each in a designed
pocket). Moons are the "event" collectible; coins are ambient reward texture.
Void has neither spending nor abundance, so the coin model is irrelevant.
The moon model — sparse, individually authored, each a small set-piece
detour — is the right match.

---

## Mobile constraints

- **Contrast**: must be visible against dark concrete from 8–15 m camera
  distance. A glowing element is required; passive colours (grey, brown)
  will be invisible. Biolume cyan is Void's designated rare accent for
  deep layers (CLAUDE.md palette); a faint cyan glow reads cleanly against
  the charcoal/grey world without competing with the Stray's red.
- **Pick-up radius**: touch correction latency means the player can't
  micro-adjust to a narrow hitbox. Collection should be automatic via
  Area3D with a generous radius (0.8–1.0 m), not requiring direct contact.
  This is the same generosity principle applied to hazard hitboxes
  (from `enemy_archetypes.md`) but inverted — the collection zone should
  be *larger* than the mesh, not smaller.
- **Collection effect**: must read in 1–2 frames of mobile display. A
  brief pulse of the cyan glow → particle burst → disappear is the minimum
  feedback. Audio cue (single clean tone) is the strongest feedback
  channel given the absence of haptics.
- **Placement**: avoid placing collectibles directly above platforms where
  the player must fight the camera for a precise jump. Prefer open-air
  positions approached from a known trajectory (e.g., at the apex of a
  long horizontal jump, or inside an alcove off the main run).

---

## Aesthetics fit — brutalism / BLAME!

Coins, stars, and radishes all belong to friendly, legible games. Void is
oppressive, inhuman, silent. The collectible must fit that world and justify
its presence narratively.

**The data shard** — a fragment of the megastructure's lost index or an
echoed memory of the system that built it. Visually: a small irregular
geometric shard (fractured prism), faintly glowing cyan (biolume), slowly
rotating, casting a thin cyan light cone onto the floor below it.

This fits because:
1. The megastructure is vast and indifferent — scattered data remnants are
   plausible lore.
2. Cyan is the designated biolume accent in the brutalist palette (CLAUDE.md).
3. A self-illuminating object is readable in darkness without needing the
   warm key light.
4. "Shard" connotes something broken and found, not given — consistent with
   the Stray's wandering nature.

---

## Concrete recommendation for Gate 1

**One data shard per level, placed off the par route.**

Implementation plan:
- `scenes/collectibles/data_shard.tscn` — `Area3D` root, small
  `MeshInstance3D` (irregular prism primitive, cyan emissive material),
  `OmniLight3D` (cyan, range 4 m, energy 1.2), `AnimationPlayer` (slow
  Y-axis rotation, ~3 rpm), `CollisionShape3D` (sphere, radius 0.9 m).
- Script: on `body_entered(body)`, check `body.is_in_group("player")` →
  emit `collected` signal → play pickup effect (burst of 6 cyan ImmediateMesh
  lines, same pattern as jump puff) → queue_free.
- `Game` autoload tracks `shards_collected: int` and `shards_total: int`.
  Level end screen shows "Shard: ✓ / ✗" (single binary per level — not a
  count, since there's only one per level at Gate 1).
- Juice: cyan pulse on `_body_entered` (brief `OmniLight3D` energy spike
  0.05 s → fade 0.3 s), audio hook for a clean sine-wave tone (Gate 3).
- Dev menu: shard collected status visible in Level section; "respawn shard"
  button resets collected state without restarting the level.

**Deferred to Gate 2:**
- Multiple shards per level with a count display.
- Shard-unlock mechanic (e.g., unlock a cosmetic skin or alternate colour
  palette for the Stray).
- Risk-reward: shard on a dead-end branch surrounded by hazards.

---

## Implications for Void (Gate 1)

1. **Data shard is the collectible type** — small cyan prism with emissive
   glow, on-collect burst. Fits palette, fits lore, reads in darkness.
2. **Area3D with 0.9 m radius** — generous collection zone, never require
   contact. Mobile thumb latency demands this.
3. **One shard per Gate 1 level, off the par route** — do not block win state
   on collection. Pure optional reward.
4. **Cyan glow is the visual hook** — must be visible from the level's widest
   shot. If a shard can't be spotted from the intro camera angle, reposition it.
5. **`Game` autoload needs `shards_collected` / `shards_total` fields** — add
   alongside `player_respawned` signal. Minimal: just two integers and a reset
   method.
6. **Placement rule**: shard must be visible from the main route but not
   collectable from it. The player should make a conscious detour decision.
