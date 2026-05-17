# Platform Gap Calibration — Project Void

Research note for depth-pass level authoring. Gives each controller profile's
actual jump reach so platform gaps can be set to intentional difficulty tiers
rather than guess-and-check.

---

## Physics model

`player.gd` uses three gravity bands per jump:

| Phase                     | Gravity used          |
|---------------------------|-----------------------|
| Rising, jump held         | `gravity_rising`      |
| Rising, jump released     | `gravity_falling`     |
| Falling (vy ≤ 0)          | `gravity_after_apex`  |

For a **full held jump from a standstill**:
- **t_apex** = `jump_velocity / gravity_rising`
- **h_max** = `jump_velocity² / (2 × gravity_rising)`
- **t_fall** = `sqrt(2 × h_max / gravity_after_apex)` (fall from apex to start height)
- **t_air** = `t_apex + t_fall`
- **x_reach** = `max_speed × t_air` (assumes full speed by jump time)

For a **same-height gap** the player must clear, the gap = `x_reach × safety_factor`.
A comfortable gap is ~80 % of `x_reach`; near-limit is ~95 %.

---

## Per-profile jump statistics

Values from `resources/profiles/*.tres`, 2026-05-17.

| Profile   | jump_vel | grav_rise | grav_apex | max_speed | t_apex (s) | h_max (m) | t_fall (s) | t_air (s) | x_reach (m) |
|-----------|----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|------------|
| Snappy    | 12.0     | 38.0      | 65.0      | 5.0       | 0.316     | 1.90      | 0.241     | 0.557     | **2.8**    |
| Floaty    | 10.0     | 20.0      | 40.0      | 5.5       | 0.500     | 2.50      | 0.354     | 0.854     | **4.7**    |
| Momentum  | 12.0     | 30.0      | 80.0      | 11.0 †    | 0.400     | 2.40      | 0.245     | 0.645     | **7.1**    |
| Assisted  | 10.0     | 15.0      | 50.0      | 5.0       | 0.667     | 3.33      | 0.365     | 1.032     | **5.2**    |

† Momentum `ramp_max_speed = 18.0 m/s` → `x_reach = 11.6 m` after a sustained run.

### Snappy double-jump (air_jumps = 1, multiplier = 0.9)

Second jump velocity = 12.0 × 0.9 = 10.8 m/s. Best case: second jump fires at the
apex of the first (vy = 0 at that moment).

| Metric                      | Value    |
|-----------------------------|----------|
| Second t_apex               | 0.284 s  |
| Combined h_max              | 3.43 m   |
| Fall from combined apex     | 0.325 s  |
| Total t_air (t1+t2+t_fall)  | 0.925 s  |
| x_reach (double jump)       | **4.6 m** |

In practice the second jump won't always fire at the perfect apex; comfortable
timing gives ~4.0–4.2 m, tight timing ~4.4–4.6 m.

---

## Cross-profile gap table (same-height, full-speed horizontal jump)

Difficulty labels: **✅ easy** (< 70 % reach), **🟡 medium** (70–85 %),
**🔴 tight** (85–95 %), **❌ impossible** (> reach).

| Gap    | Snappy 1× | Snappy 2× | Floaty | Momentum | Assisted |
|--------|-----------|-----------|--------|----------|----------|
| 1.5 m  | ✅        | ✅        | ✅     | ✅       | ✅       |
| 2.0 m  | 🟡        | ✅        | ✅     | ✅       | ✅       |
| 2.5 m  | 🔴        | ✅        | ✅     | ✅       | ✅       |
| 2.8 m  | ❌ (limit)| ✅        | ✅     | ✅       | ✅       |
| 3.0 m  | ❌        | ✅        | ✅     | ✅       | ✅       |
| 3.5 m  | ❌        | 🟡        | 🟡     | ✅       | ✅       |
| 4.0 m  | ❌        | 🔴        | 🟡     | ✅       | 🟡       |
| 4.5 m  | ❌        | ❌(~limit)| 🔴     | ✅       | 🔴       |
| 5.0 m  | ❌        | ❌        | ❌     | ✅       | ❌(limit)|
| 6.0 m  | ❌        | ❌        | ❌     | 🟡       | ❌       |
| 7.0 m  | ❌        | ❌        | ❌     | ❌(limit)| ❌       |

**Key implication**: Snappy is the most constrained profile at 2.8 m single-jump.
A 3.0 m gap already requires the double-jump, so any gap ≥ 3 m is implicitly
teaching the double jump. The Gate 1 level must introduce double-jump before any
gap ≥ 3 m appears.

---

## Height differential

For a platform **above** the jump origin by Δh, the available fall distance
from the apex is `(h_max − Δh)`, shrinking horizontal window.

Approximation: `x_reach(Δh) ≈ max_speed × (t_apex + sqrt(2 × (h_max − Δh) / gravity_after_apex))`
(assumes Δh ≤ h_max; invalid above that).

| Profile  | Δh = +0.5 m | Δh = +1.0 m | Δh = +1.5 m | Δh = max† |
|----------|------------|------------|------------|----------|
| Snappy   | 2.6 m      | 2.4 m      | 2.1 m      | 1.6 m (≈Δh=1.9)|
| Floaty   | 4.5 m      | 4.2 m      | 3.9 m      | 2.5 m (≈Δh=2.5)|
| Assisted | 5.0 m      | 4.8 m      | 4.5 m      | 2.7 m (≈Δh=3.3)|

† "max" = platform at the profile's h_max. Player barely crests it; x_reach ≈ max_speed × t_apex.

**Rule of thumb**: a +1.0 m height difference costs ~15 % of horizontal reach for
Snappy and ~10 % for Floaty/Assisted (flatter curves due to lower gravity_after_apex).

For platforms **below** the origin by Δh, reach increases because the player arrives
lower; the extra fall distance `Δh / gravity_after_apex` adds to t_fall.

| Profile | Δh = −0.5 m | Δh = −1.0 m |
|---------|------------|------------|
| Snappy  | +0.21 s → 3.8 m total | +0.40 s → 4.8 m total |
| Floaty  | +0.16 s → 5.6 m total | +0.31 s → 6.4 m total |

Descending platforms give surprising extra reach. The Descent level exploits this
intentionally (falling gaps are easier than they look).

---

## Existing level calibration notes

Cross-referencing the 9 shape-family levels against Snappy (Gate 1 primary profile):

| Level      | Reported gap / spacing              | Calibration verdict                                      |
|------------|-------------------------------------|----------------------------------------------------------|
| Threshold  | Beat4 platform tightened; Z3 gantries | Gaps not published; verify on device                  |
| Spire      | 1.5–2.5 m, tuned for Snappy        | ✅ Well-calibrated (easy to medium Snappy range)         |
| Rooftop    | No gap data in scene description   | MovingPlatE must be timed; static gaps unknown           |
| Plaza      | MovingPlatform 7 m arm, 4.5 s      | Timed gap — platform must be catchable at Snappy speed   |
| Cavern     | NorthLedge: 1 m gap + 1.5 m rise  | 1 m gap + height: x_reach≈2.0 m → comfortable for Snappy|
| Descent    | 1 m gap + 1.5 m rise (downward)    | Expert line is pure drop → no gap constraint             |
| Filterbank | Press kill zone full room (10 m)   | Timing hazard, not a gap                                 |
| Viaduct    | Span1: 2 m wide, 4 m static gaps  | 4 m gap → beyond Snappy single-jump — relies on MovPlatBridge |
| Arena      | Patrol zone data, gap not published | Not measured                                             |

**Viaduct concern**: The 4 m static gaps between spans are impossible for Snappy without the
`MovPlatBridge`. If the moving platform is missed, the player is stuck with no retry path.
Verify on device that the platform arrival window is ≥ 0.5 s (comfortable) at Snappy speed.

---

## Depth-pass implications for Void

1. **Gate 1 primary profile is Snappy.** Design the critical-path geometry for Snappy first.
   Comfortable gaps: 1.5–2.0 m. Challenge gaps: 2.0–2.5 m. Double-jump required: 3.0+ m.

2. **Double jump must be taught before any 3.0 m gap.** On the chosen level, place an easy
   3.0 m gap (or a visible double-jump "demo" moment) before any hard 3.0+ m gap appears.
   This is a Gate 1 checklist item.

3. **Height differences erode reach more than expected.** A 1.0 m step-up on a 2.5 m gap
   is near-impossible for Snappy (reach ≈ 2.4 m). If the level has ascending platforms,
   reduce gap by ~15 % per 1 m of elevation, or reduce the step height.

4. **Ascending vs descending asymmetry matters most for Spire and Descent.** In Spire the
   player climbs, so gaps must stay in the easy-medium Snappy range. In Descent the player
   falls, so gaps naturally feel more reachable (extra fall time) — a 3.5 m gap while
   descending ~1.5 m feels like a 2.5 m gap in practice.

5. **Moving platform timing.** For a 4 s period platform at Snappy max_speed:
   - Platform visible catch window = platform length / max_speed = e.g. 3 m / 5.0 m/s = 0.6 s
   - This is the minimum comfortable window. Shorter = tight timing.
   - The Viaduct's moving bridge (14 m span, 4 s period) should be verified: if the gap is
     4 m and the platform moves in 2 s, the player has ~2 s to jump on → comfortable.

6. **Floaty and Assisted profiles will find all Snappy-designed gaps trivially easy.**
   If the human picks Floaty or Assisted as the Gate 1 profile, redesign gaps upward:
   comfortable Floaty gap = 2.5–3.5 m, challenge = 3.5–4.0 m.

7. **Par-time calibration and gap size are linked.** A 2.5 m gap the player runs to takes
   ~0.5 s total air time. A level with 5 such gaps adds ~2.5 s of mandatory air time.
   Account for this in par_time calibration (see `run_timer_semantics.md`).

---

## Sources

- `resources/profiles/*.tres` — current profile values (read 2026-05-17)
- `scripts/player/player.gd` — `_apply_gravity()` (lines 265–275), `_try_jump()` (lines 278–305)
- `tests/test_controller_kinematics.gd` — `_test_jump_height_plausible()`, `_test_jump_arc_geometry()`
- Level scene descriptions in `docs/PLAN.md` (iters 97–104)
