# Sisyphus Downhill Godot Prototype

Godot 4.6.2 / GDScript vertical slice for `西西弗斯下山`.

## Run

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot
```

Open `res://scenes/Main.tscn` and press Play.

The exported app boots to `res://scenes/MainMenu.tscn`; the Play button enters `res://scenes/VerticalSlice.tscn`.

Push-lab feel experiment:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/PushLab.tscn
```

Steam-directed vertical slice scene:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn
```

Representative human playtest helper. Use the current packet/readiness report
for the active tester/date:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/run_current_representative_playtest.sh
```

Check current handoff status without launching Godot:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/check_current_representative_handoff.sh
```

Submit the filled current report after pressing `F9` at `complete / Chapter I End`:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/submit_current_representative_playtest_report.sh
```

Vertical slice visual verification modes:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=approach
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=push
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=left
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=right
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=release
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=descent
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=hum
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=loop
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=route
```

Automated visual modes:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/PushLab.tscn -- --lab-auto=approach
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/PushLab.tscn -- --lab-auto=push
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/PushLab.tscn -- --lab-auto=left
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/PushLab.tscn -- --lab-auto=release
```

## Controls

- `WASD`: move; hold `W` against the stone to keep pushing.
- Mouse or trackpad drag: over-shoulder look.
- `Q/E`: keyboard turn fallback.
- `Esc`: release mouse capture.
- Vertical slice: `Esc` or `P` opens the pause menu; Resume returns to play, Main Menu returns to the release boot menu.
- Vertical slice: `F9` saves a manual playtest snapshot report plus a same-name `.png` screenshot.
- Push-lab: `1/2/3` switches heavy/standard/light presets, `R` resets, `F3` toggles force vectors.

## Verify

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --check-only --script tests/test_game_logic.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_game_logic.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_push_lab.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_push_lab_player_loop.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_logic.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_trail_environment_response.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_humming_progression.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_route_telemetry.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_playtest_report_builder.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_export_readiness.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_pause_menu.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_playtest_capture.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_visual_modes.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_route_physics.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --quit-after 120
```

Visual force-vector verification:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/Main.tscn -- --auto-push
```

## Desktop Export Readiness

Desktop export presets live in `export_presets.cfg` and target `../builds/desktop/`.

Readiness check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_export_readiness.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_release_tooling.gd
```

Template preflight:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh --check-templates
```

Local macOS export and smoke verification:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh macos
/Users/haodong/Documents/GitHub/Sisyphus/tools/smoke_macos_build.sh
```

Future target exports:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh windows
/Users/haodong/Documents/GitHub/Sisyphus/tools/export_desktop.sh linux
```

On this Mac, only the macOS export can be treated as a runnable local build. Windows and Linux exports are packaging artifacts until they are launched on matching target machines or CI runners.

Steam packaging, signing, depot upload, and store assets are not covered by this readiness step.
