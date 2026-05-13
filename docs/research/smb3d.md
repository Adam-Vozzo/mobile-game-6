# Super Meat Boy 3D — Design Analysis

**Sources**
- [MonsterVine review, Apr 2026](https://monstervine.com/2026/04/super-meat-boy-3d-review/)
- [Keengamer review, PC](https://www.keengamer.com/articles/reviews/pc-reviews/super-meat-boy-3d-review-pc-a-bold-evolution-that-struggles-with-precision/)
- [Xbox Wire developer Q&A, Jun 2025](https://news.xbox.com/en-us/2025/06/09/super-meat-boy-3d-xbox-games-showcase/)
- [PSNProfiles community guide (100% completion data)](https://forum.psnprofiles.com/topic/192827-super-meat-boy-3d-100-guide-all-150-a-times-75-bandages-5-glitches-5-secret-levels/)
- [supermeatboy.wiki Beginner Guide](https://supermeatboy.wiki/guide/beginner/)
- [Sluggerfly developer page](https://sluggerfly.com/smb3d)
- Wikipedia: Super Meat Boy 3D

Released **31 March 2026** (PC/Xbox Series X/S; Switch 2/PS5 followed). Developed by Sluggerfly (team of 7, previously *Hell Pie*) in close collaboration with Team Meat's Tommy Refenes. Published by Headup Games. This is the closest live reference to Project Void.

---

## Core new mechanics in 3D

**Wall run** — approach a wall at an angle and hold the run direction to sprint horizontally across its surface. Limited duration; dust-trail effect signals the remaining window. Abort by jumping sideways.

**Air dash** — press dash while airborne to launch in the held direction (or straight ahead if no direction held). Briefly ignores gravity for its duration. Recharges on landing. The guide specifically says to conserve dash for repositioning, not to use it early in a jump.

**Wall jump** — press into any wall surface to stick and slide slowly. Jump at the slide apex, direct movement away. Called "the single most important mechanic" in the beginner guide.

**Ground slam** — mid-air slam straight down at speed. Gap navigation and hazard avoidance.

---

## Camera design

- **Fixed per level** — not player-controlled, not dynamic. Quote from the team: *"A dynamic or player-controlled camera just couldn't keep up with the pace Meat Boy requires."*
- Depth axis is consistent within each level (the "towards/away from screen" axis is the same across a whole room).
- No auto-framing — levels are built around the fixed angle.

---

## Level structure

- **~20 seconds per level** (skilled). Under 1 minute maximum. There are ~150 main levels.
- **Dark World** — if a level is completed under the A+ time, a harder remixed version of that level unlocks.
- No checkpoints, no health. One hazard touch = instant death + instant respawn.
- Difficulty ramps slowly then sharply (some stages see 50+ deaths).
- Collectible bandages add a secondary routing challenge in each level.

---

## Ghost trail / attempt replay

After clearing a level, the game plays back every single failed attempt simultaneously — all ghost copies run from spawn at the same time, dying off one by one as the winning run emerges from the pack. This is the exact same design as 2D SMB. It is not bonus content; it is the core pedagogical loop: failure becomes visible, patterns become legible, the winning line announces itself from the noise. It also makes individual deaths feel cheap ("just data") rather than punishing.

---

## Depth perception

This was the most-cited technical failure in critical reviews. Key observations:

- **Shadow blob** under the character at all times. The beginner guide: *"3D depth perception is your biggest new challenge."* The blob is the primary spatial aid for judging where the character will land.
- **Background landmarks** advised for depth judgment — don't rely on the shadow alone.
- **45-degree level geometry angles** throughout. Sluggerfly chose these explicitly: "helps players anticipate and plan their moves, especially at high speed."
- **"Ground circle" indicator** marks player's ground position during high/far travel — a projected reticle separate from the shadow blob.
- **Eight-directional stick** movement constrains inputs to predictable headings at high speed, reducing depth-axis error.

Despite all of these aids, depth perception is still flagged in multiple reviews as the largest failure point of the 2D→3D translation. Deaths still "feel less fair than in the original game."

---

## What works / what doesn't

**Works:**
- Wall-running and the weighty-yet-smooth jump feel "completely natural in 3D" (MonsterVine).
- Instant respawn prevents discouragement. Level length keeps frustration fleeting.
- Ghost trail replay is pedagogically strong, same as 2D.
- Dark World as difficulty extension works well.

**Doesn't:**
- Movement feels "less precise" than 2D. Controls are responsive but judging depth causes off-axis deaths that feel arbitrary.
- Visual identity was lost: smooth, clean 3D aesthetics replaced the gritty Flash original. Reviewers describe a "softer edge" and weaker personality.
- Fixed cameras conflict with spatial awareness in some rooms.

---

## Metacritic reception

Mixed-to-favorable (PC/Xbox generally favorable; Switch 2/PS5 mixed/average). Critical variance tracks closely with how tolerant individual reviewers are of depth-perception difficulty.

---

## Implications for Project Void

1. **Blob shadow is mandatory before the first on-device feel test.** SMB 3D launched with this and still gets depth-perception criticism. Without it, the human's first feel verdict will be polluted by spatial disorientation, not controller feel. Blob shadow implemented in `scripts/player/blob_shadow.gd` (iter 31); dev menu tunables in Juice → Blob Shadow — Tuning.

2. **Camera stability beats camera dynamism for precision platforming.** SMB 3D chose fixed-per-level cameras explicitly because a dynamic camera "couldn't keep up with the pace." Void's tripod model (no lateral translation) is already aligned with this principle. The airborne rigid-translate (locking the camera frame from takeoff to landing) is Void's equivalent of the "consistent depth axis per level" design.

3. **45-degree geometry → brutalist 90-degree geometry.** SMB 3D uses 45-degree angles for predictability at speed. Void's brutalist aesthetic gives us 90-degree rectilinear forms for the same reason — structural clarity aids player prediction. The parti principle ("expressed structure = free affordance") from Alexander research maps directly.

4. **Air dash as depth-perception error recovery.** The air dash recharges on landing and is explicitly for repositioning. If a player misjudges depth on a jump, the dash gives one correction burst. This is a very strong mobile feature candidate — touch air-dashes require only a swipe, avoiding button clutter. Consider for Assisted profile Phase 2 or as a universal mechanic gated to Gate 1 tuning.

5. **Ghost trail replay is the core pedagogical tool — not an optional feature.** SMB 3D confirms what 2D SMB established: the attempt overlay IS the learning loop. Gate 1 must ship with this or the difficulty ramp will feel arbitrary rather than instructive. Research note `ghost_trail_prototype.md` has the Godot 4 implementation sketch ready.

6. **Level length target confirmed: 20 seconds skilled.** Void's Gate 1 target of "60–90 seconds skilled" is 3–4× longer than SMB 3D rooms. That may be intentional (Void is a single full level vs. SMB 3D's discrete rooms), but each beat within the level should be individually clearable in ~20 seconds. Gate 1 layout should be structured as a procession of ~20-second beats with brief rest nodes between them, not a continuous gauntlet.

7. **Style loss is the biggest long-term risk.** SMB 3D's clearest critical failure was losing visual identity in the 3D transition. Void's brutalist/BLAME! direction is actually an advantage here — concrete, fog, and darkness are inherently 3D materials that gain from perspective. The Stray's red accent will pop MORE against grey-on-grey in 3D than it would in 2D. Protect the style direction. Don't let convenience assets or "cleaner" visuals soften the brutalism.

8. **Instant respawn speed is non-negotiable.** SMB 3D confirms: instant. Void's current reboot animation at 0.5 s is cinematic-length. `level_design_references.md` already flags: Snappy reboot_duration should be ≤ 0.35 s. This remains a deferred tuning task — do it on first device feel verdict.
