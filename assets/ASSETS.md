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

- assets/audio/sfx/jump.ogg           (source: laserSmall_000.ogg)
  assets/audio/sfx/land_light.ogg     (source: impactMetal_000.ogg)
  assets/audio/sfx/land_heavy.ogg     (source: impactMetal_004.ogg)
  assets/audio/sfx/collect_shard.ogg  (source: forceField_003.ogg)
  assets/audio/sfx/respawn_start.ogg  (source: laserLarge_000.ogg)
  Source: https://kenney.nl/assets/sci-fi-sounds
  Author: Kenney (kenney.nl)
  Licence: CC0 1.0 Universal
  Date acquired: 2026-05-15
  Notes: Five clips selected from the 70-file Sci-Fi Sounds pack for Gate 1
  placeholder SFX — jump, light land, heavy land, shard collection, respawn.
  Files renamed from Kenney originals to semantic event names under sfx/.
  Tunable from dev menu Juice → Audio — SFX ("SFX volume ×"). On-device
  pending — final clip selection may change after first device playtest.
  No attribution required (CC0).

- assets/audio/ambient/ambient_global.ogg   (PENDING — needs manual download)
  Source: https://freesound.org/people/AlaskaRobotics/sounds/221570/
  Author: AlaskaRobotics
  Licence: CC0 1.0 Universal
  Date acquired: pending
  Notes: "Ambient spacecraft hum" — deep bass-heavy industrial hum, 17.8 s
  loopable. Selected as B1 in ASSET_OPTIONS.md. Looping set programmatically
  via AudioStreamOGGVorbis.loop = true in audio.gd::_load_ambient_streams().
  Plays on Ambient bus for all zones. No attribution required (CC0).
  Download: visit the freesound URL above, log in, click Download OGG, save
  as assets/audio/ambient/ambient_global.ogg, then reopen Godot to import.

- assets/audio/ambient/ambient_zone2.ogg   (PENDING — needs manual download)
  Source: https://freesound.org/people/IanStarGem/sounds/271096/
  Author: IanStarGem
  Licence: CC0 1.0 Universal
  Date acquired: pending
  Notes: "Industrial/Factory Fans Loop" — mechanical fan soundscape, 6.7 s
  seamless loop. Selected as B2 in ASSET_OPTIONS.md. Zone 2 (maintenance yard)
  secondary layer — plays at -4 dB relative to global hum. Looping set
  programmatically. No attribution required (CC0).
  Download: visit the freesound URL above, log in, click Download OGG, save
  as assets/audio/ambient/ambient_zone2.ogg, then reopen Godot to import.
