# Win State Design — Project Void

**Research date:** 2026-05-11
**Gate relevance:** Gate 1 ("Win state and results screen" requirement)
**Dependency:** Requires `Game.level_completed` signal (stub already in `game.gd`).

---

## What the reference games do

### Super Meat Boy (2010)

- No UI during play. On level exit the game **instantly** cuts to a stats screen.
- Stats: time (to nearest 0.001 s), deaths. No score.
- **Grade system** (A+ / A / B / C / D): encourages replay without locking content.
- Dark World variant unlocks if you beat the light world fast enough — gives the
  hardcore run a concrete target.
- The results screen is deliberately **brief**: time, deaths, grade, next / replay.
  Players spend more time replaying than reading results.
- Pedagogical function of the stats screen: turns a painful run into legible
  information. "I died 47 times but finished in 1:12 — that's progress."

### Super Meat Boy 3D (2026)

- Based on `smb3d.md`: ghost trail replay **is** the results screen — on level
  complete, the game replays all attempts overlaid, so you see your improvement
  arc before the stats panel appears.
- Time and attempt count confirmed present; grading system assumed similar.
- Level length ~20 s skilled means the replay animation is short enough not to
  feel like a punishment.

### Dadish 3D (2024)

- Mobile-first results: simple full-screen panel, large text, "Next" and "Replay"
  buttons sized for thumbs.
- Reviews note the end screen as adequate but un-memorable — it doesn't add
  anything beyond time.
- No death count shown by default (avoids embarrassing new players on mobile).
- Star rating (1–3 stars) based on completion time relative to par. Stars are
  immediately visible and emotionally legible on small screens.

### Celeste (2018)

- Chapter complete screen: clear time, death count, strawberries collected.
- **Death count is prominent** — Celeste reclaims deaths as a badge of honour.
  The culture around Celeste (speedrunning, no-death runs) reinforces this.
- B-side and C-side variants unlock, similar to SMB's dark world.
- Time saved vs. personal best shown on subsequent runs — drives intrinsic
  motivation to improve.

---

## Mobile-specific constraints

1. **Minimal wait time.** Mobile players have shorter patience windows and may
   be interrupted. The gap between level end and "can replay" should be ≤ 3 s.
2. **Large tap targets.** Replay and Next buttons must be thumb-reachable —
   minimum 80 px height, ideally 120 px, in the lower half of the screen.
3. **No mandatory animation.** Any completion fanfare should be skippable or
   already short enough (< 1 s) that it doesn't feel like a penalty.
4. **Avoid embarrassing new players.** Death counts on mobile are high;
   exposing them prominently can read as punishing. Either hide by default or
   frame positively ("attempts").
5. **Landscape layout.** Stats panel should be centred, not full-screen, so
   the level environment is still visible behind a semi-transparent backdrop —
   reinforces the sense of place and makes the result feel earned.

---

## Void recommendation

### Win state trigger

- A `WinState` node: `Area3D` with `body_entered` signal.
- On `body_entered`: if the body is in the `player` group, emit
  `Game.level_completed`. The signal already exists in `game.gd`.
- `Game` tracks `run_time_seconds` (needs a `_process` increment —
  currently stubbed, see `game.gd`).

### Results panel

Present three lines of information, nothing more:

```
TIME     0:47.23    ← run_time_seconds formatted
PAR      0:35.00    ← level resource: par_time_seconds
SHARDS   1 / 1      ← Game.shards_collected / Game.shards_total
```

- No death count (too punishing on mobile for Gate 1 audience).
- Par time comparison gives an implicit grade without a letter grade.
- Shard count is legible even if the player missed the shard (Gate 1 has one).

### Buttons

Two buttons, vertically stacked, bottom-centre:

1. **REPLAY** — `Game.reset_run()` → `get_tree().reload_current_scene()`
2. **MENU** — deferred to Gate 2 (no hub yet); hide this button in Gate 1

### Framing

- Semi-transparent dark panel over the frozen level — do not cut to a new scene.
- Time scale set to 0.0 on `level_completed` (freeze the world) after a 0.5 s
  hold (lets the player feel the finish before the panel appears).
- Background: the level is still visible, ideally with the Stray at the exit
  trigger, reinforcing completion.

### Ghost trail replay (Gate 1)

Per `ghost_trail_prototype.md`, the ghost trail plays during the run not after.
For Gate 1, the results panel appears *without* a replay animation — the trail
design already provides the replay loop as play-time pedagogy, so a post-level
animation replay would be redundant. Defer if the human wants it.

---

## Gate 1 implementation checklist

1. **`WinState.tscn`** — `Area3D` + `CollisionShape3D` + script; emits
   `Game.level_completed` on player contact.
2. **`Game._process(delta)`** — increment `run_time_seconds` when
   `current_level_path != ""` and not paused (add `is_running` bool flag).
3. **`Game.shards_collected` / `shards_total`** — stubs per
   `collectible_design.md`; Gate 1 level sets `shards_total = 1`.
4. **`ResultsPanel.tscn`** — `CanvasLayer` with `PanelContainer`, three labels,
   two buttons; added as autoloaded scene or instantiated by `game.gd` on
   `level_completed`.
5. **Par time** — add `par_time_seconds: float` to a `LevelMeta` resource or
   as a constant in the level script. Gate 1 par = 35 s (skilled clear target;
   tune after on-device play).
6. **Juice**: brief `AudioStreamPlayer` stinger on level complete; scale-up
   tween on the panel (0.8 → 1.0 over 0.25 s). Both gated behind juice toggles.

---

## Implications for Project Void

1. **`Game.is_running`** boolean (not yet added) — needed to pause the run
   timer on the results screen and after respawn (timer should not tick
   during the reboot animation).
2. **`WinState.tscn` is the last Gate 1 scene to author** — place it after
   checkpoint design and level greybox are settled (it's just an exit trigger).
3. **No death count on the results panel** — align with Dadish 3D's more
   supportive mobile stance. Deaths are tracked internally for ghost trails;
   they just aren't shown. Can add as an opt-in dev-menu toggle later.
4. **Par time drives intrinsic motivation** — even for a single Gate 1 level,
   showing par immediately invites a replay without requiring a leaderboard.
   Set it conservatively (skilled but not speedrun) so most players see "below
   par" and feel the pull to improve.
5. **Ghost trail replay post-level is deferred** — the trail serves its purpose
   during play. A post-level animated replay adds engineering cost for Gate 1
   with questionable marginal value. Revisit at Gate 2 if the human wants it.
6. **`Game.reset_run()` already exists** — the replay button requires no new
   Game API. `get_tree().reload_current_scene()` after `reset_run()` is the
   full implementation.
