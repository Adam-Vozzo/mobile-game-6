Ambient audio files — manual download required.

Expected files:
  ambient_global.ogg  (B1 — AlaskaRobotics "ambient spacecraft hum", freesound #221570, CC0)
  ambient_zone2.ogg   (B2 — IanStarGem "Industrial/Factory Fans Loop", freesound #271096, CC0)

Download steps:
  1. Visit https://freesound.org/people/AlaskaRobotics/sounds/221570/
     Log in, click Download OGG. Save as assets/audio/ambient/ambient_global.ogg
  2. Visit https://freesound.org/people/IanStarGem/sounds/271096/
     Log in, click Download OGG. Save as assets/audio/ambient/ambient_zone2.ogg
  3. Open Godot — both files auto-import as AudioStreamOggVorbis.
  4. Looping is set programmatically in audio.gd::_load_ambient_streams()
     (no import settings change needed).

Volume tuning:
  Dev menu → Juice → Audio — Ambient → "Ambient volume ×" slider.
  Zone 2 fan layer is -4 dB relative to the global hum by default.

Both clips are CC0 (no attribution required). See assets/ASSETS.md for full entry.
