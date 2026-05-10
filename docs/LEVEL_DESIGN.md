# LEVEL_DESIGN.md — Project Void

Principles for all spatial design. Read this before authoring any new layout.

---

## Core vocabulary

**Parti**: Every space has one idea. A level is "the ascent," "the void crossing," "the compression and release." Name it before placing geometry.

**Procession**: Players should experience a level as a sequence of compressed → expanded → compressed spaces. Brutalism excels at sudden scale change. Use it.

**Hierarchy**: Not all platforms are equal. Some are waypoints, some are landings, some are the destination. Visual hierarchy (size, height, light, red accent) guides the eye.

**Threshold**: Doorways, archways, and openings are not gaps — they're events. A character passing through a threshold enters a new world.

---

## Spatial principles for brutalist platforming

1. **Big empty first.** Start with a void. Place one platform. Ask: does the platform earn its place?
2. **No decoration.** Every object must be structural or navigational. If it's neither, delete it.
3. **Scale contrast.** Place a small The Stray against a large slab to communicate scale. This is free atmosphere.
4. **Fog as boundary.** Don't end a level with a wall. End it with fog. The world continues; The Stray just can't reach it.
5. **Sightlines.** Before placing fog, decide what the player should see from the start point. The first platform should be visible. The destination should be a silhouette in the mist.
6. **One red object per level section.** Serves as both collectible and navigation anchor. Everything else is grey.
7. **Ceiling and floor are optional.** Many brutalist spaces have no visible ceiling. Open sky (grey, overcast) is fine.

---

## Platform grammar

| Type | Description | Use |
|------|-------------|-----|
| Foundation | Large flat slab, ~4×4m or bigger | Landing zones, safe spaces |
| Ledge | 1–2m wide, long | Traversal routes, risk/reward |
| Column top | 1×1m max | Precision challenge |
| Void crossing | Two platforms with a gap | Pacing beat, commitment moment |
| Overhang | Underside of a slab with a ledge | Spatial compression moment |

---

## Camera hint guidelines

Place a `CameraHintArea` (Area3D with `hint_distance` and `hint_pitch` exports) at:
- The start of every new "room" or section transition
- Any platform where the default camera angle would obscure the next jump target
- The final destination of a level (pull back to show scale)

---

## Feel Lab

The Feel Lab (`scenes/levels/feel_lab.tscn`) is not a level — it's a test bench.
It should contain:
- A large flat ground plane (run-around space)
- Platforms at 1m, 2m, 3m, 4m height (single jumps to test ceiling)
- A gap of ~3m (test horizontal reach)
- A narrow ledge (precision test)
- No fog, no atmosphere — pure mechanics testing

---

## Reference: brutalist game spaces

- **Inside** (Playdead, 2016): compression, silence, scale contrast, fog
- **SOMA** (Frictional, 2015): cold concrete, industrial scale, purposeful emptiness
- **Caves of Qud** (text but applicable): layered procession, named spaces
- **Journey** (thatgamecompany, 2012): scale hierarchy, single accent colour
