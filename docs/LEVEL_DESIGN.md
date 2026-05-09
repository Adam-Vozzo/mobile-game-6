# Project Void — Level Design Principles

---

## Core principles (read before authoring any spatial layout)

### 1. Procession
Every level is a procession — a directed journey with clear start, middle, and end. The player always knows which way is "forward" even without a minimap. Use: elevation changes, fog density, The Stray's glow as distant beacon.

### 2. Hierarchy of space
Three spatial types, always present:
- **Threshold**: narrow or compressed space — generates anticipation.
- **Nave**: open, tall space — releases tension. The Stray lives here.
- **Apse**: intimate, enclosed end-point — the goal feels earned.

### 3. Environmental storytelling
No text, no dialogue. The world tells its story through:
- Geometry: what structures were here? What collapsed?
- Light: where is the sun? What does shadow protect?
- Red: The Stray is the only warm thing. Why is it here?

### 4. Brutalist vocabulary
- **Mass**: heavy volumes. Platforms are thick, not wafer-thin.
- **Repetition**: repeated elements create rhythm.
- **Void**: empty space is a material. Don't fill it.
- **Raw surface**: concrete, exposed. No decoration.

### 5. Platform language
Platforms communicate through visual language:
- **Reachable**: close enough to visually confirm. Player should *know* they can jump there.
- **Challenge**: slightly further. Requires commitment. Place a sight line from safe ground.
- **Optional secret**: off the main procession. Reward curiosity.

---

## Feel Lab layout (Gate 0 test space)

```
         [Stray]
         [Platform B] ← 3×3, y=3.0, z=-11
              ↑ (gap jump ~5m, 1.5m rise — skill test)
         [Platform A] ← 4×4, y=1.5, z=-6
              ↑ (easy hop ~2m, 1.75m rise)
         [Floor]      ← 20×20, y=0
         [Start]

Side:    [Narrow]     ← 6×2, y=2.0, x=4, z=-9  (lateral challenge)
```

**Purpose**: verify player movement. Not a designed level. No story here.

---

## Level 01 sketch (Gate 2 — future)

Thematic fragment: "The Stray is lost in the ruins."

- Start: narrow corridor, compressed ceiling, cold.
- Middle: open brutalist courtyard, columns, thick fog in corners.
- End: elevated platform, Stray glowing below in a sunken void.
- Key moment: player drops down to Stray (counter-intuitive — down, not up).

*Full design requires human approval before implementation.*

---

## Camera hints (future system)

`CameraHint` is an Area3D that, when entered, lerps the camera to a scripted position/angle. Use for:
- Revealing a new space dramatically.
- Keeping an important sight-line open during a challenge.
- Holding on The Stray at the end of a procession.

Implement `CameraHint` in Gate 3.
