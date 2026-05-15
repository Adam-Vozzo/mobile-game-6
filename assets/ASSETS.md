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

- assets/art/character/animal-chick.glb
  assets/art/character/colormap-cube-pets.png
  Source: https://kenney.nl/assets/cube-pets (v1.0)
  Author: Kenney (kenney.nl)
  Licence: CC0 1.0 Universal
  Date acquired: 2026-05-15
  Notes: Yellow chick model used as the Stray protagonist. Part of the Cube
  Pets pack (24 animated 3D pets). GLB embeds the colormap texture; colormap.png
  copy kept alongside for reference. No attribution required (CC0).

- assets/art/architecture/factory-kit/ (143 GLB files + colormap-factory-kit.png)
  Source: https://kenney.nl/assets/factory-kit (v3.0)
  Author: Kenney (kenney.nl)
  Licence: CC0 1.0 Universal
  Date acquired: 2026-05-15
  Notes: Industrial/factory 3D asset kit — conveyors, pipes, cogs, catwalks,
  cranes, tanks, machines. Used for Zone 2/3 set-dressing in Threshold and
  future industrial levels. No attribution required (CC0).

- assets/art/architecture/space-station-kit/ (97 GLB files)
  Source: https://kenney.nl/assets/space-station-kit
  Author: Kenney (kenney.nl)
  Licence: CC0 1.0 Universal
  Date acquired: 2026-05-15
  Notes: Modular space-station 3D asset kit — floors, walls, panels, doors,
  consoles, containers, structural columns. Used for Zone 1/2 modular geometry
  in Threshold and future habitation-layer levels. No attribution required (CC0).
