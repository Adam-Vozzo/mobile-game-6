# Run-Timer Semantics — Project Void

**Research date:** 2026-05-14
**Gate relevance:** Gate 1 ("Win state and results screen" — `par_time_seconds` calibration)
**Depends on:** `win_state_design.md`, `game.gd` implementation

---

## The core question

The Threshold level's results panel shows `run_time_seconds` vs. `par_time_seconds`.
The timer is a `_process(delta)` accumulator that runs while `is_running = true`.

**Does the timer stop during the reboot animation (0.33 s Snappy / 0.50 s others), or does it run continuously?**

Current implementation: **continuous** — the timer runs through every death, every reboot
animation, and every re-settlement. There is no pause hook in `respawn()` or the
reboot-effect coroutine.

The `win_state_design.md` note says "timer should not tick during the reboot animation"
— but this was written before the implementation was complete, and it reflects one design
option, not a settled decision.

---

## What the reference games do

### Super Meat Boy (2010)

- Timer is **wall-clock**, running continuously. It measures the time from level-start
  button to the moment the player reaches the exit, inclusive of every death and respawn.
- Why: the stat the game surfaces — your **time** — is the direct measure of practice.
  48 deaths and 1:12 is honest. You got better; you also died a lot.
- The reboot in SMB is nearly instant (~0.3 s). The cost is negligible per-death.
  At 50 deaths in SMB, the overhead is ~15 s — but players rarely notice because
  every death also includes re-running the level from the start (room-based design).
- Par times in SMB are set as absolute wall-clock targets. "A+" is roughly
  the developer's speedrun time. "A" is competent first-clear territory.

### Super Meat Boy 3D (2026)

- No definitive documentation, but level structure is continuous (no room reset),
  so the timer is almost certainly wall-clock. Instant respawn at level-specific
  restart point = the timer model is the same as SMB.
- Reboot animation is ~0.3–0.35 s (per `smb3d.md` observations and visual inspection).

### Celeste (2018)

- Chapter timer: **wall-clock**, runs through all deaths including the brief
  death-flash and respawn animation (~0.5–1.0 s). The chapter summary shows
  total time including all deaths.
- Death count is shown separately so players can mentally attribute the extra
  time to deaths. This separates "run efficiency" from "death overhead."
- Celeste's death animation is ~0.8 s. At 100 deaths that's ~80 s of pure overhead
  in the displayed time — a significant fraction of a 10-minute chapter. Celeste
  accepts this because the death count shown alongside makes it legible.

### Dadish 3D (2024)

- Timer is wall-clock (inferred from level design: respawn at last checkpoint,
  timer keeps running). No death count displayed by default.
- Because the timer doesn't tell the player how many deaths they took, a high
  wall-clock time is ambiguous — the player can't tell if they were slow or died.
  This was not flagged as a complaint in the reviews reviewed in `win_state_design.md`,
  suggesting mobile players accept wall-clock timing.

---

## Void's current model: wall-clock

`game.gd::_process(delta)` accumulates while `is_running = true`.
`is_running` is only set to `false` by `level_complete()` (on win) and `reset_run()`.
Neither `respawn()` nor `_run_reboot_effect()` touches `is_running`.

Result: **wall-clock timer**, identical to SMB's model.

---

## Overhead per death, by profile

| Profile  | reboot_duration | Deaths needed to add 10 s overhead |
|----------|----------------|-------------------------------------|
| Snappy   | 0.33 s         | ~30 deaths                         |
| Floaty   | 0.50 s         | ~20 deaths                         |
| Assisted | 0.50 s         | ~20 deaths                         |
| Momentum | 0.50 s         | ~20 deaths                         |

For a Gate 1 target of `par = 35 s`, a new player taking 15–30 deaths would
add 5–15 s of overhead to their displayed time. Their movement time might already
be close to par, but the results panel shows them "over par." This could feel
discouraging on mobile where death rates are high.

---

## Two calibration approaches

### Approach A — Calibrate par as wall-clock (current model, simpler)

Set `par_time_seconds` to the expected wall-clock time for a **competent first-clear**:
player who knows the level, dies 3–5 times, and takes clean lines elsewhere.

**Formula:** `par ≈ movement_time + (expected_deaths × reboot_duration)`

For Threshold with Snappy at ~35 s movement time and 4 expected deaths:
`par ≈ 35 + (4 × 0.33) ≈ 36.3 s` → round to **37 s**.

The A+ / personal-best wall-clock time (near-deathless skilled run) would then be
~35.5 s — clearly beating par. A player who dies 10 times sees ~38.3 s, slightly
over par, and learns one more clean segment beats it.

Benefit: no code changes needed. Simple, honest. Matches SMB convention.
Risk: par must be tuned to include realistic death overhead, not pure movement time.

### Approach B — Pause timer during reboot (Celeste-adjacent)

`respawn()` sets `is_running = false`; `_run_reboot_effect()` sets it back to `true`
at beat 4 (after `_is_rebooting = false`).

**Effect:** displayed time = pure movement time. Par = developer's movement time.

Benefit: time is a pure skill signal, not a mixed skill+patience signal.
Risk:
1. Code change in `respawn()` and `_run_reboot_effect()`. Not complex, but testable.
2. Timer stops during reboot, so `run_time_seconds` is no longer wall-clock.
   The UX implication is subtle: players who die 50 times and die slowly might
   feel the timer is "wrong" compared to a wall clock.
3. On device, if the player notices the timer stops during reboot, they may feel
   it's a glitch (especially if a HUD timer is ever shown).
4. Ghost trail alignment: trail timestamps are currently in wall-clock sample
   indices. If the timer pauses, trail replay duration differs from displayed time.
   This is only relevant if a timed replay is ever added (deferred to Gate 2+).

---

## Recommendation

**Keep wall-clock (Approach A) and calibrate `par_time_seconds` to include expected
death overhead.** Reasons:

1. It matches the established SMB convention that players familiar with the genre
   expect.
2. No code change needed — the current implementation is correct for this model.
3. Ghost trail timing stays consistent.
4. The correction is small: Approach A par ≈ Approach B par + 1–2 s for a typical
   Gate 1 run. The delta is not perceptually meaningful.
5. If death count is ever surfaced (opt-in dev-menu toggle per `win_state_design.md`),
   the player can mentally attribute the overhead.

**Concrete action:** When on-device feel is tested, set par by running the level
cleanly (3–5 deaths max) and using that wall-clock time. Do not time a deathless run
and subtract reboot — that produces a par that most players will never beat.

---

## Implications for Project Void

1. **`par_time_seconds = 35.0`** in `threshold.gd` is a placeholder. After first
   on-device feel playtest, replace with a wall-clock time from a 3–5-death run.
   Expected calibrated value: 36–40 s depending on profile and platform speed.
2. **No code change needed to `game.gd`** for the timer to work correctly under the
   wall-clock model. The current implementation is aligned with this research.
3. **`win_state_design.md` note** "timer should not tick during reboot" reflected
   Approach B; this research supersedes that note in favour of Approach A (wall-clock).
4. **If the human prefers Approach B** (pause during reboot), the change is: in
   `respawn()`, call `Game.is_running = false`; in `_run_reboot_effect()` beat 4
   (after `_is_rebooting = false`), call `Game.is_running = true`. Add guard:
   only if `is_running` was true before respawn (don't re-enable if the run was
   already complete or the level never started).
5. **Par time is profile-dependent.** Snappy (faster reboot, higher skill floor)
   will produce a lower par than Floaty. Par should be calibrated per-profile in
   production, or set conservatively so it is beatable by all profiles. Gate 1
   uses a single `par_time_seconds` float — profile-specific par is a Gate 2+
   concern.

---

## Sources

- Super Meat Boy — direct play, Team Meat postmortems, `level_design_references.md`.
- Super Meat Boy 3D — `smb3d.md`, visual inspection of released build.
- Celeste — direct play, Noclip documentary (Maddy Thorson commentary on death counts).
- Dadish 3D — Play Store reviews analysed in `win_state_design.md`.
- Void implementation — `scripts/autoload/game.gd`, `scripts/player/player.gd`.
