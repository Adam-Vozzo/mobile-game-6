# ASSETS — third-party asset log

Every third-party asset committed to this repo gets an entry here, in the
format below. The `assets/` tree is otherwise empty until we promote a
primitive (see `docs/ART_PIPELINE.md`).

```
- assets/<path>
  Source: <URL or "AI-generated via <tool>">
  Author: <name or "n/a">
  Licence: <CC0 / CC-BY-4.0 / Mixamo EULA / etc.>
  Date acquired: <YYYY-MM-DD>
  Notes: <attribution string if required, modifications made>
```

CC-BY entries must include the exact attribution string the licence
requires; we'll surface them in an in-game credits screen later.

Avoid GPL-licensed assets and "non-commercial only" assets — easier to
stay clean now than to swap later. If a licence is unclear or unstated,
do not commit the asset.

---

## Entries

_(none yet — kickoff used only built-in primitives, fog, and the default
Godot icon already present in the repo.)_
