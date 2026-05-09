# Juice Density Research — Astro's Playroom, Astro Bot, and Precision Platformers

Primary sources synthesised: Astro's Playroom (PS5, 2020), Astro Bot (PS5, 2024),
Super Mario Odyssey (2017), Super Meat Boy (2010), and commentary from Nicolas
Doucet (Team Asobi) on the juice philosophy behind both Astro titles.

---

## What Astro's Playroom / Astro Bot actually do

### The "layered receipt" model
Every meaningful player action fires three simultaneous feedback layers:
1. **Audio** — short, punchy SFX with a clear attack (no slow fades)
2. **Visual** — particle burst or squash-stretch matching the SFX timing exactly
3. **Screen / world reaction** — environment responds (grass flattens, dust kicks)

The SFX and visual are synchronised to ±1 frame. When only two of the three
layers fire, the game feels thinner. The team describes this as the player
getting a "receipt" for every action.

### What fires on every player-controlled event
- **Jump takeoff**: quick squash → stretch of the player body, small foot-puff
  particle burst, a soft pop SFX with a faint echo
- **Jump apex**: a brief audio note change (pitch dip) signals the gravity shift;
  body briefly holds stretch pose 1–2 frames before falling animation begins
- **Landing (small)**: body squash, single dust mote particle, a soft clank
- **Landing (heavy, >2 m)**: larger squash, ring of dust motes, louder clank with
  a ringing tail, screen push-down (low-freq camera dip, not a shake)
- **Running fast**: continuous micro-particle trail behind feet, servo-whir audio
  pitches up proportionally to speed
- **Idle > 3 s**: idle animation + audio desaturates (no ambient noise)
- **Death**: body break apart (for Astro Bot); equivalent of sparks + dark frame
  in Project Void's already-implemented reboot animation

### What they do NOT juice
- No screen shake on normal jump landings (only on very heavy or boss hits)
- Footstep particles are 4 quads maximum (mobile budget equivalent)
- Motion trails only appear above a speed threshold — they are invisible during
  normal play, prominent only during sprint or boost sequences
- SFX are never "busy" — there's always breathing room in the mix

---

## Precision platformer contrast (Super Meat Boy)

SMB has far fewer juice layers but each one is extremely tuned:
- **Death**: instant, blood splash (1 frame), audio stab — zero wait
- **Respawn**: fade-in from white, audio "ready" note — under 0.35 s total
- **Jump**: no particles, no squash (the SMB art style can't do it cleanly) — relies
  entirely on responsive physics feel and the jump SFX
- **Landing**: single-frame squash, no particles — minimal

**Implication**: SMB proves that precision-focused games can strip juice down to audio
+ one visual tell per action and still feel satisfying, IF the physics feel is right.
The bar for juice density scales with how forgiving and exploratory the game is.
Astro Bot (exploration, moderate difficulty) → heavy juice; SMB (precision, punishing)
→ sparse juice. Project Void should sit closer to SMB.

---

## Thumb-zone juice considerations for mobile

Touch games get two extra juice opportunities that console games don't:
1. **Stick knob press feedback** — small scale-down of the knob gfx on first touch
2. **Jump button press visual** — a brief ring pulse or background fill when held

Both are already `idea` status in JUICE.md under "UI juice." Worth noting that on
mobile, UI-layer juice (button feedback) compensates for the haptic layer that's
absent vs. a DualSense controller.

---

## Juice budget realities for Mobile renderer

Every juice element must survive the ≤50 draw-call / ≤80k tri budget:
- Squash-stretch: **free** — it's a scale tween on a single Node3D
- Particles (4-quad footstep): **~1 draw call** per active emitter; cap at 2 simultaneous
- Audio SFX: **free** from render budget
- Screen shake: **free** — camera transform manipulation
- Motion trail (after-image): depends on implementation; the MultiMesh approach in
  `ghost_trail_prototype.md` is 1 draw call for 300 instances
- ImmediateMesh sparks: **0 at rest**, **1 draw call** during reboot anim (already implemented)

---

## Synthesis: what this means for JUICE.md Gate 1 priorities

**Highest ROI (implement first):**
1. **Landing squash** — squash_stretch toggle already exists; this is a 5-line tween
   triggered from `_physics_process` when `is_on_floor()` goes true. Scales by fall
   speed. Zero draw-call cost. Astro's Playroom treats this as non-negotiable.
2. **Jump stretch** — same toggle, brief Y-stretch at takeoff. Pairs with existing
   death squish to give squash_stretch its full repertoire.
3. **Jump puff particle** — 4-quad burst at foot position on takeoff. Fits inside the
   particle budget. Gated behind `particles` toggle (already wired).
4. **Pre-jump anticipation squash** — 1–2 frame Y-squish during jump buffer window.
   Zero cost; makes buffered jumps feel "charged."

**Second tier (Gate 1 polish pass):**
5. **Land impact ring** — scaled by fall velocity; only on hard landings (>2 m).
6. **Servo-whir speed ramp** — audio only; pitch-modulated by horizontal speed.
   Doesn't exist yet (no audio system) — flag for Gate 1 audio pass.
7. **Jump button press ring** — UI layer pulse; compensates for no haptics on mobile.

**Defer to Gate 2+:**
- Screen shake (hard land, hazard hit) — feels heavy on mobile small screens; calibrate
  after device testing
- Ghost trail / attempt-replay — already planned for Gate 1, but separate system
- Hitstop — needs an enemy archetype first

**Anti-patterns to avoid (Astro's Playroom team's own notes):**
- Don't fire all juice layers simultaneously on every action — reserve the heavy
  layering for landing-after-big-fall, boss hit, etc. Normal jumps get 1–2 layers.
- Don't let particle trails fire at low speed — they read as visual noise, not reward.
- Keep SFX attack times under 5 ms or the action will feel delayed even if physics is frame-perfect.

---

## Implications for Project Void

1. **Landing squash is the highest-ROI un-shipped juice element.** It directly tells
   the player "I arrived" and pairs with the existing death squish code in `player.gd`.
   Implement it in Gate 1's first juice pass.
2. **Jump anticipation squash** (pre-jump, in buffer window) is a precision platformer
   staple — it makes coyote jumps and buffered jumps feel intentional, not lucky.
   Should be gated behind `squash_stretch` toggle (already in dev menu).
3. **Juice density in Void should be closer to SMB than Astro Bot** given the
   brutalist/lonely tone. Heavy particle clusters would undercut the atmosphere.
   One clear tell per action; silence between actions is part of the design.
4. **Audio is the fastest path to feeling polished** — even placeholder SFX
   (beeps, thuds) dramatically improve perceived quality. Flag for Gate 1 scope discussion
   with the human before committing to an audio direction.
5. **The "receipt model"** (audio + visual always together) is worth enforcing as a
   project convention: if you add a particle burst, add a matching SFX stub at the same
   time even if the audio system isn't ready. Stubs keep the audio wiring obvious.
6. **UI juice (button press feedback)** compensates for the missing haptics layer on
   Android. Prioritise it above screen shake, which can feel sickening on small
   landscape screens.
