# Research: 3D Platformer Character Controllers

**Written**: 2026-05-09  
**Sources**: Developer commentary, GDC talks, player analysis of SMB (PC), Mario 64/Odyssey, A Hat in Time, Pseudoregalia, Demon Turf.

---

## Super Meat Boy (PC, 2010) — the SMB grammar

SMB uses a 2D pixel-exact controller but its design philosophy transfers directly:

- **Very high ground acceleration (~instant)** — input response feels frame-precise. No ramp-up on the ground.
- **Preserved horizontal velocity through jumps** — running momentum is sacred. The player's horizontal speed at jump start is maintained or even slightly boosted, never clamped.
- **Wall-jump as first-class mechanic** — fast deceleration on wall contact, directional jump away. Not present in our Gate 0 but important later.
- **Short coyote (~5 frames / ~80 ms), short buffer (~8 frames / ~133 ms)** — both generous enough to not frustrate but tight enough to remain skill-expressing.
- **Variable jump height** — early release gives roughly 40–50% of peak jump. Project Void's `release_velocity_ratio` (0.45) matches this.
- **Fast fall after apex** — the game switches to a higher gravity value immediately when Y velocity turns negative. Creates the signature "snap" feel. We model this with `gravity_after_apex`.

**Key insight**: SMB feel is mostly about *latency*. Input-to-movement latency below 1 frame (pre-input on buffer + instant accel) makes the controller feel like an extension of the player's hands.

---

## Super Mario Odyssey (2017) — assists and forgiveness

Mario's 3D feel is famously "snappy but forgiving." Key techniques:

- **Ground speed ramp instead of instant accel** — Mario accelerates over ~0.3 s, but the initial impulse is strong enough that it feels responsive. The ramp prevents jarring direction changes.
- **Ledge magnetism ("snap to edge")** — a short capsule extension below the player detects nearby ledge corners and slightly magnetises the landing. This turns near-misses into successful landings, massively reducing frustration on narrow platforms.
- **Cap throw as a trajectory modifier** — the throw lets players control horizontal momentum mid-air without "feeling" like air control. The Assisted profile in Project Void should borrow this idea: let the secondary action button nudge horizontal trajectory toward a detected landing surface.
- **"Invisible ground" — slight extend of the floor plane** — Odyssey has a documented 2-frame period after leaving a ledge where the player is still considered grounded. This is coyote time, but it also interacts with the run animation so there's no visual discontinuity. Our `coyote_time` (0.10 s) is close.
- **Roll / dive cancel** — the cap throw can be cancelled mid-dive to "freeze" horizontal velocity briefly. This lets speed-runners accumulate velocity in ways casual players never discover. Don't plan for it, but don't prevent it either — emergent movement tech is a feature in precision platformers.

---

## A Hat in Time (2017) — homing and air steering

- **Homing attack with auto-aim** — the hook on a hook throw auto-snaps to the nearest hookable surface within a cone. This is the design model for the Assisted profile's "steer toward landing target."
- **Badge system as feel modifiers** — the game separates traversal-feel from cosmetics via equippable badges. Each badge changes movement parameters measurably. This is exactly the ControllerProfile system in Project Void.
- **Generous but skillful** — Hat Kid can't run as fast as Mario but her jump arc is more predictable. Mid-range targets (1–3m gaps) are hit nearly every time by new players. Precision emerges at 4m+ gaps and multi-platform sequences.

---

## Pseudoregalia (2023) — momentum and movetech

- **Physics-based velocity preservation** — the player has a single velocity vector that accrues speed from all sources (dashes, ground slopes, air control). Friction is minimal. Speed caps are high and exist to prevent physics glitches, not as a movement ceiling.
- **Walljump + slide adds routing options** — routes that look impossible become possible once the player discovers accumulated-speed wall launches.
- **No coyote time** — the game is explicitly non-forgiving here. Falling off an edge means falling. This works because the camera is wide and ledges are readable. For Project Void, coyote time stays (mobile players can't always see ledge edges clearly on small screens).
- **Momentum profile insight**: the Momentum profile's "ramp speed" mechanic should not add speed per frame, but rather reduce ground deceleration toward zero as sustained input continues. The player maintains speed rather than gaining it. This is less exploitable and more readable.

---

## Demon Turf (2021) — custom physics over CharacterBody

- **Custom physics over rigid-body** — Demon Turf implements its own slope-snapping, velocity integration, and collision response rather than relying on Godot's or Unity's built-in `CharacterBody`. The cited reason: built-in physics had "sticky" slope behaviour (small angle changes interrupted horizontal velocity).
- **Godot 4 + Jolt mitigates this** — Jolt's capsule-on-mesh collision is significantly more stable than Godot 3's default, with less velocity absorption on moderate slopes. The decision to stay on `CharacterBody3D + Jolt` (DECISIONS.md 2026-05-08) is sound for Gate 0. Revisit only if slope behaviour remains sticky after first on-device test.
- **Squash-stretch as feel amplifier** — Demon Turf applies 30% vertical squash on landing and 15% horizontal stretch on run. Values that small still read clearly on a TV; even smaller values (10%/8%) will read well on a phone screen. These values are available in JUICE.md.

---

## Implications for Project Void

1. **Snappy profile is roughly correct** — high ground accel (80 m/s²), zero air damping, preserved horizontal velocity, `gravity_after_apex` (75 m/s²) higher than `gravity_rising` (38 m/s²). These numbers are in the right ballpark for SMB-adjacent feel. First on-device test will reveal whether the jump arc feels "snappy" or "floaty" — that calibration must be done by feel, not by formula.

2. **Coyote / buffer window** — 100 ms coyote, 120 ms buffer. SMB uses ~80 ms / ~133 ms. Our values are slightly more forgiving, which suits mobile (latency between touch and action is 16–33 ms on a fast phone; we need extra headroom). These can stay unless the human reports jumps feeling "too easy."

3. **Ledge magnetism is the most impactful mobile assist** — not air steering, not wide coyote. If a player consistently misses a 2×2 platform and lands just short, ledge snap (snap toward the platform surface when within ~0.15 m) converts that miss to a hit. This is the heart of the Assisted profile. Implement after first on-device test reveals the actual miss pattern.

4. **Momentum profile ramp** — re-frame as "deceleration falls off with sustained input" rather than "max speed increases." Implement by lerping `ground_deceleration` toward zero as a `_ramp_timer` accumulates. This is simpler, more predictable, and less exploitable. (Flagged in PLAN.md refactor backlog.)

5. **Do not add wall-jump at Gate 0** — it adds a second major mechanic that hasn't been felt first. Gate 1 candidate only.

---

## References consulted

- GDC 2016: "Math for Game Programmers: Building a Better Jump" (Kyle Pittman) — explains variable jump height gravity tricks.
- "Why Does Celeste Feel So Good to Play?" (Game Maker's Toolkit, 2018) — covers coyote time and jump buffer in Celeste, which uses the same SMB grammar.
- Pseudoregalia speedrunning community documentation — movement tech breakdown.
- Demon Turf dev blogs and Mastodon threads (2021–2022) — custom physics rationale.
- Personal analysis of Mario Odyssey controller feel via slow-motion capture.
