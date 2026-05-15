# Kenney Kit Material Override — Brutalist Palette Approach

## Why this matters for Void

The Kenney Factory Kit (CC0) and Space Station Kit (CC0) ship with their own
`StandardMaterial3D` resources tuned for a bright, readable cartoon aesthetic:
mid-saturation blues, greys, and oranges at roughness ~0.7. Against Void's
brutalist palette (cold concrete, amber sodium light, deep fog) these materials
read as "colourful toy factory" rather than "inhuman megastructure." Every
kit piece placed in Threshold needs a decision: override or keep?

This note documents the pattern established in iters 89–90 and should be the
first read for any future art-pass or level-dressing iteration.

---

## Sources

- Iter 89: `scripts/enemies/patrol_sentry.gd` — dark body mat + amber emissive eye
- Iter 89: `scenes/levels/threshold.tscn` — 13 kit props placed under Z1/Z2/Z3Dressing
- DECISIONS.md 2026-05-15: PatrolSentry visual approach
- `resources/materials/mat_concrete_dark.tres` (albedo 0.32/0.32/0.35, roughness 0.9)
- `resources/materials/mat_concrete.tres`      (albedo 0.55/0.55/0.58, roughness 0.85)
- `docs/CLAUDE.md` § Style direction

---

## The two-class rule

**Override the body:** Any large structural surface (columns, walls, floor plates,
machine housings) should use `mat_concrete_dark.tres` or `mat_concrete.tres` via
`set_surface_override_material(surface_idx, mat)` in `_ready()` (if spawned
programmatically) or directly in the Godot Inspector.

**Keep the emissive / detail surface:** Emissive strips, light pods, eye indicators,
and indicator panels carry zone identity. Replace their albedo with a near-black
(0.02–0.12 grey) and tune `emission` colour + `emission_energy_multiplier` to
the zone palette:

| Zone | Emission colour | Energy |
|------|----------------|--------|
| Zone 1 (habitation) | sodium amber `Color(1.0, 0.65, 0.08)` | 1.4–2.0 |
| Zone 2 (maintenance) | cold blue-white `Color(0.4, 0.55, 0.9)` | 1.2–1.8 |
| Zone 3 (industrial) | amber-orange `Color(1.0, 0.55, 0.05)` | 1.8–2.4 |
| Hazard / danger      | amber-orange `Color(1.0, 0.55, 0.05)` | 2.2 |

PatrolSentry (`patrol_sentry.gd`) is the reference implementation:
```gdscript
# Body: dark grey, no emission.
body_mat.albedo_color = Color(0.18, 0.18, 0.20)
body_mat.roughness = 0.85

# Eye strip: near-black albedo + sodium amber emission.
eye_mat.albedo_color    = Color(0.12, 0.07, 0.0)
eye_mat.emission_enabled = true
eye_mat.emission        = Color(1.0, 0.55, 0.05)
eye_mat.emission_energy_multiplier = 2.2
```

---

## Style fidelity check before placing any kit piece

Per `CLAUDE.md` § Third-party assets:
> Does it read in the brutalist palette under fog at the camera distance the player will see it?

Practical checklist:
1. Apply `mat_concrete_dark.tres` override to the body mesh.
2. Stand the piece next to a grey `CSGBox3D` at runtime — if the Kenney piece
   reads "lighter" or "warmer" than the box, reduce albedo or roughness.
3. Add one emissive detail strip in the zone colour palette.
4. View from ~8 m (typical platform-hop distance) with zone fog on.
5. Ask: does the piece read as infrastructure or as decoration?

---

## Specific per-zone advice for Threshold

### Zone 1 — Habitation / Plaza (Space Station Kit)

CompSys (computer console) and Container (cargo box) are the two placed pieces.
`mat_concrete_dark.tres` on the housing body. The CompSys screen panel should
carry a warm sodium glow (Energy 1.4) to reinforce Zone 1 identity. Containers
can be purely dark-grey (no emission) — they are structural mass, not indicators.

### Zone 2 — Maintenance Yard (Factory Kit)

CogA, Machine1, PipeL. Override cog body with `mat_concrete_dark.tres`. Machine1
has an amber HazardStripe already on the underside from iter 70 — keep it. PipeL
can stay purely dark-grey. Emissive conduit strips (ConduitLeft/Right from iter 70)
carry zone 2 identity — don't add more warm lights here or Zone 2 will stop reading
as cold-blue.

### Zone 3 — Industrial / Gantry (Factory Kit)

Crane1 and HopperR are overhead silhouettes. At Zone 3 height (8 m up), their
surface texture barely matters — what matters is silhouette shape. Override body
with `mat_concrete_dark.tres`. A single amber emissive strip on Crane1's cab is
sufficient.

---

## Material-slot index lookup

Kenney GLBs are single-mesh models. `set_surface_override_material(0, mat)` covers
the whole visible mesh in most cases. Multi-mesh Kenney pieces (those with visible
sub-nodes) need a loop over `get_surface_override_material_count()` or use the
Inspector's "Surface Material Override" array.

The `_body_mesh` path for the Stray chick is `Visual/Chick/root/body` (GLB hierarchy
discovered in iter 89). Factory Kit pieces follow the same single-level GLB convention:
the top-level `MeshInstance3D` after import is the overrideable surface.

---

## What blocks the full texture pass

Per DECISIONS.md and PLAN.md "Blocked / needs human":
- Texture-pass timing (E) is TBD — human hasn't confirmed when to promote from
  primitive materials to a Poly Haven concrete-texture kit.
- Once approved: acquire C2 candidate (Poly Haven concrete textures, CC0), import
  with ASTC compression enabled, apply to `mat_concrete.tres` and `mat_concrete_dark.tres`
  as albedo/roughness/normal maps. Texel density target 8–12 for Threshold's 24×36 m
  floor; 4–6 for narrow ledges. See `docs/research/baked_lighting.md` for the full
  bake pipeline.

---

## Implications for Void

1. **No new script needed for body-mesh overrides** — Inspector override array works
   at edit time. Only dynamic spawns (like PatrolSentry) need code.
2. **Emissive strips are free at Gate 1** — they use SHADING_MODE_UNSHADED so they
   bypass the lighting pipeline. Use liberally for zone identity.
3. **Two materials are enough for Gate 1 geometry** — `mat_concrete.tres` (light
   floor surfaces) and `mat_concrete_dark.tres` (walls, ceilings, kit bodies).
   Adding a third per-zone material is premature until device tests confirm the two
   don't already provide sufficient contrast.
4. **Don't override Kenney kit pieces with warm albedo** — any piece that reads
   warmer than cold-grey fights the Stray's lemon yellow as the focal point.
5. **Kit pieces are atmosphere, not affordance** — avoid placing kit pieces on
   surfaces the player needs to read as walkable or dangerous. Those surfaces use
   the concrete materials directly, not kit dressing.
