# Depth Perception Cues — Mobile 3D Platformers

## Why this matters for Void

SMB 3D's biggest post-launch criticism (see `smb3d.md`) was depth perception: even
with fixed-per-level cameras and a full spatial-aid suite, reviewers still called out
the difficulty of reading landing depth in 3D. Void compounds this with a brutalist
aesthetic (dark, monochromatic, fog-heavy) and a small protagonist. Fog and darkness
are essential to the tone and cannot be removed; depth cue design must work *within*
them, not around them.

---

## Sources surveyed

- SMB 3D reviews and developer commentary (via `smb3d.md`)
- Astro Bot / Astro's Playroom GDC postmortems
- *Super Mario Galaxy* depth-cue analysis (GameMaker's Toolkit)
- *A Hat in Time* developer commentary (gravity arrows, shadow disc)
- Godot 4 documentation: Decal, shadow mapping on Mobile renderer
- General HCI: visual depth cues survey (binocular disparity irrelevant on flat screen;
  monocular cues only: relative size, motion parallax, occlusion, shadow, texture gradient)

---

## The blob shadow is the single highest-ROI cue

Every 3D platformer reviewed uses a blob (disc) shadow directly beneath the character,
regardless of whether real-time shadows exist for the environment.

**Why it works:**
- Provides an unambiguous vertical position reference — the disc shows where "below the
  player" is at a glance, independent of scene lighting.
- Size and opacity both scale with height: ground = large+opaque, airborne = small+faded.
  The shrinking disc visually communicates "the floor is now far away."
- Zero reliance on scene shadow maps (which are expensive and often disabled on mobile).
- Costs 1 raycast + 1 draw call per frame — the cheapest meaningful depth cue available.

**Current status in Void:** `prototype` in `blob_shadow.gd`. Four tunables live in dev
menu (radius_ground, radius_height, fade_height, max_alpha). This is correct and
sufficient for Gate 1. The tuning pass (max_alpha, fade_height) should happen on device.

**Recommended values to validate on device:**
- `max_alpha` 0.5–0.65 (fog-dark world → can afford higher opacity than a bright game)
- `radius_ground` 0.30–0.40 m (slightly larger than the capsule for visual comfort)
- `fade_height` 5–8 m (fades to invisible at two platform heights above the floor)
- Blob colour: near-black (0.0, 0.0, 0.0), not warm — warm reads as a light source

---

## Secondary cues worth considering

### 1. Landing shadow / target indicator

Several 3D platformers (Galaxy, Banjo-Kazooie, Astro Bot) project a **second disc or
crosshair** at the predicted landing position rather than at the current ground directly
below the player. This answers "where will I land?" rather than "how high am I?".

- **Projection approach**: raycast from player position along the parabolic arc (or just
  downward if the player is moving slowly) to the anticipated landing point.
- **Cost**: 1 additional raycast per frame. Negligible.
- **Relevance to Void**: High value on the Zone 3 lateral gantry platforms, where the
  player jumps laterally and the current blob shadow (directly below) is behind them
  by the time they land.
- **Implementation path**: add optional `predict_landing` bool export to `blob_shadow.gd`.
  When true, cast a second ray in the current velocity direction × `profile.air_dash_duration`
  seconds ahead. Render as a smaller (0.5× radius), lower-alpha disc at the hit point.
  Gate behind a separate dev-menu toggle so it can be A/B tested on device.
- **Flag as Gate 1 enhancement** — implement only if device testing confirms the lateral
  jump beats (Zone 3) read as hard to land.

### 2. Platform edge contrast (brightness rim)

Astro Bot and Mario Galaxy both use slight brightness brightening on platform top edges
to make the boundary between "walkable" and "void" legible. This is architectural, not
a runtime effect.

- **In Void's context**: the brutalist palette is concrete grey — platform tops and the
  floor-void boundary look the same colour. A thin lighter-grey top face material would
  help, especially in Zone 2 narrow ledges.
- **Implementation path**: create `mat_concrete_edge.tres` — same roughness as
  `mat_concrete.tres` but albedo raised by ~0.08–0.10. Apply only to top-face geometry
  of narrow ledges where the boundary matters. No runtime cost.
- **Flag for texture pass** — pairs naturally with the concrete kit art pass that's blocked
  on asset picks.

### 3. Camera angle and height

The single most powerful depth cue in 3D platformers is the camera being *slightly above*
and *looking slightly down* — this creates a perspective foreshortening effect that makes
depth differences visible. Cameras at eye level or looking up lose this entirely.

- **Current Void camera**: tripod `aim_height` and vertical pull on fall are already
  pulling toward a slightly-above-looking-down configuration.
- **SMB 3D comparison**: fixed camera was placed above and slightly behind the player —
  intentional because "dynamic camera couldn't keep up with pace."
- **Risk for Void**: the `pitch_max = 70°` drag allows the player to pull the camera
  nearly to ground level. At low pitch, depth perception degrades significantly.
- **Mitigation**: consider a `pitch_soft_clamp` — at pitches below 20° the auto-recenter
  applies 2× stronger pull-back pressure to nudge the camera back up. Hard limit stays at
  0° (no upward gaze) as approved; soft pressure just makes very-low-pitch an uncomfortable
  sustained state. Expose as a slider: "Auto-recenter boost below (°)".
- **Flag as Gate 1 enhancement** — not urgent while Threshold is greybox; revisit when
  on-device pitch tests complete.

### 4. Character silhouette readability

Depth is much easier to read when the player character silhouette stands out clearly
against the background. Dadish 3D does this with the character's flat-colour cutout
style. Void's Stray is a small robot in a dark world.

- **Stray's single red accent** is doing this work. Against fog-grey concrete, red reads
  at any distance because it is the only warm hue in the scene.
- **Risk**: if the industrial press or Zone 3 hazards are also warm-amber/orange (hazard
  stripe), the Stray's red accent competes with hazard colouring.
- **Mitigation already in place**: `HazardStripe` is amber (0.9, 0.55, 0.1) — a different
  hue from Stray red (pure red). This creates a warm-vs-warmer distinction but still both
  warm. At Gate 1, this should be tested on device — if hazards and Stray blend together
  visually, shift hazard amber toward a cooler orange-yellow or reduce its energy.
- **No immediate action**: flag for on-device playtest.

### 5. Fog as depth gradient

Void's directional fog is a natural depth cue — distant objects are more grey-white than
near objects. This is free and already in the aesthetic.

- **Current status**: three zone Environments with distinct fog density (`Env_Z1` warm
  sodium, `Env_Z2` cold, `Env_Z3` amber). Fog already contributes.
- **Do not reduce fog for depth clarity** — it would break the brutalist tone. Instead,
  let the blob shadow carry the vertical-depth work; fog handles horizontal-distance depth.

---

## Motion parallax (camera movement)

Player-driven camera drag creates motion parallax — near objects move more than far
objects — which is a powerful depth cue in VR and some 3D games. On mobile with touch
drag, this is available but not constantly active. Verdict: it is a bonus, not a
primary cue. Do not design depth reliance on manual camera drag.

---

## What SMB 3D missed (and Void should not)

From smb3d.md: "blob shadow is mandatory for depth perception — even SMB 3D's full
spatial-aid suite still drew depth-perception criticism."

SMB 3D criticism was about *vertical* depth reads — players could not tell whether a
platform was one jump's height below or three jumps. The blob shadow addresses this but
requires one critical companion: platforms must have **visual height difference cues**
in the geometry, not just altitude numbers.

In Void, zone layering already does this naturally (Zone 1 = ground, Zone 2 = 4 m up,
Zone 3 = 8 m up) but only if zone transitions are readable. The zone atmosphere swaps
(warm/cold/amber) provide zone identity. The blob shadow provides per-platform-hop
vertical reads. Together they should address SMB 3D's failure mode.

---

## Implications for Void (concrete and actionable)

1. **Blob shadow tuning pass is Gate 1 P0.** On first device run, tune `max_alpha`,
   `fade_height`, and `radius_ground`. Target: player can clearly tell "1 platform height
   airborne" from "3 platform heights airborne" by blob size alone.

2. **Landing-target predictor is Gate 1 enhancement (not P0).** Only implement if
   Zone 3 lateral jumps read as ambiguous on device. Keep behind a dev-menu toggle.

3. **Platform edge contrast is texture-pass work.** `mat_concrete_edge.tres` (albedo
   +0.08) for narrow-ledge top faces. Pairs with concrete kit, blocked on asset picks.

4. **Do not reduce fog density for depth.** Fog is load-bearing for tone. Blob shadow
   does the vertical depth work; fog does horizontal distance work.

5. **Camera pitch below 20° degrades depth perception.** Consider soft auto-recenter
   boost at low pitch. Not urgent for greybox; flag for Gate 1 camera pass.

6. **Monitor hazard-stripe vs Stray-red readability on device.** Both are warm;
   amber energy may need reducing if they visually blend with the Stray at distance.

7. **Zone atmosphere contrast is doing level-design depth work already.** The warm/cold/amber
   zone transitions communicate altitude progression. Protect this even when baked lighting
   arrives.
