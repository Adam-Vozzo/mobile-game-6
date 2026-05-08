# Android Build Notes — Project Void

## Target

- Device: Nothing Phone 4(a) Pro
- API target: Android 14 (API 34), min API 24
- Architecture: arm64-v8a (configured in export preset)
- Orientation: Landscape locked (configured in project.godot)
- Renderer: Mobile (GLES3 compatible)

## Export Preset

The Android export preset is already configured in `export_presets.cfg`:
- `architectures/arm64-v8a=true`, others disabled
- `script_export_mode=2` (GDScript bytecode)

## Keystore Setup (stub — do not generate keys here)

Before exporting a signed APK you need to:

1. Generate a keystore locally on your machine (NOT committed to the repo):
   ```
   keytool -genkey -v -keystore project_void_release.jks \
     -alias project_void -keyalg RSA -keysize 2048 -validity 10000
   ```
2. In Godot: **Project → Export → Android** → fill in:
   - Keystore (debug): point to your debug.keystore
   - Keystore (release): point to your project_void_release.jks
   - Key alias: project_void
   - Key password: (your password)
3. Do NOT commit the .jks file or passwords to the repo.
4. For CI builds: use environment variables (`KEYSTORE_PATH`, `KEYSTORE_PASS`, `KEY_ALIAS`, `KEY_PASS`).

## Required Android SDK Components

- Android SDK Platform 34
- Android SDK Build-Tools (latest stable)
- Android NDK (for GDNative/GDExtension if needed — not required for pure GDScript)
- Godot Android Export Templates (install via Godot Editor: **Editor → Manage Export Templates**)

## Export Steps (development build)

1. Open project in Godot Editor.
2. **Project → Export**
3. Select Android preset.
4. Enable "Export With Debug" for dev builds.
5. Click "Export Project" → save as `.apk`.
6. Install via ADB:
   ```
   adb install -r build/android/project_void_debug.apk
   ```
7. Launch from device app drawer or ADB:
   ```
   adb shell am start -n com.projectvoid.game/.GodotApp
   ```

## Performance Profiling on Device

```
adb logcat -s godot
```

For Godot's built-in profiler: connect Godot Remote Debugger via USB while the APK is running.

## Known Issues / Notes

- Nothing Phone 4(a) Pro target: 60 fps cap enforced in project settings. Thermal throttling headroom built into 8–10 ms frametime budget.
- ASTC texture compression required. All textures in `assets/` must use ASTC on Android import.
- The dev menu (F1 / 3-finger tap) is available in all builds including release. Consider adding a build flag to strip it for store builds in Gate 3.
