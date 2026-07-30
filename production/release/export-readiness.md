# Desktop Export Readiness

Date: 2026-05-24

## Current Status

The Godot project now has desktop export presets for:

- macOS
- Windows Desktop
- Linux

The presets target `builds/desktop/` and are guarded by:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_export_readiness.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_release_tooling.gd
```

## Verified

- `export_presets.cfg` loads.
- macOS, Windows Desktop, and Linux presets exist.
- Each preset is runnable and points to the expected desktop output path.
- `rendering/textures/vram_compression/import_etc2_astc=true`, so macOS universal/arm64 export is not blocked by that project setting.
- Godot 4.6.2 export templates are installed on this machine and pass `tools/export_desktop.sh --check-templates`.
- `tools/export_desktop.sh macos` creates `builds/desktop/macos/SisyphusDownhill.zip`.
- `tools/smoke_macos_build.sh` unpacks the zip and launches the exported app headlessly with an explicit writable log path.
- Computer Use visual check launched the exported macOS app window, confirmed the new `MainMenu.tscn` renders first, clicked Play, confirmed `VerticalSlice.tscn` loads with mountain, stone, player, HUD, and telemetry, pressed Escape, confirmed the pause menu appears, then clicked Resume successfully.

## Export Commands

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh --check-templates
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh macos
/Users/haodong/Documents/GitHub/Sisyphus/tools/smoke_macos_build.sh
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh windows
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh linux
```

Current local proof only covers the macOS build, because it can be launched on this machine. Windows and Linux exports remain future packaging artifacts until they are run on matching target systems.

## Still Pending

Steam release still needs signed macOS builds, Windows export plus Windows runtime validation, SteamPipe/depot setup, store assets, QA soak runs, and external playtests.

## Latest Local Build Evidence

- Build: `builds/desktop/macos/SisyphusDownhill.zip`
- Smoke: `tools/smoke_macos_build.sh`
- Visual: exported macOS app window rendered `MainMenu.tscn`; Play entered the vertical-slice scene; Escape opened the pause menu; Resume returned to play.
