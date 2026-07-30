# Technical Preferences

Project-specific CCGS configuration for `西西弗斯下山`.

## Engine & Language

- **Engine**: Godot 4.6.2
- **Language**: GDScript
- **Rendering**: Godot Forward+ 3D, low-poly art direction
- **Physics**: Godot 4.6 Jolt 3D physics, `RigidBody3D` stone, `CharacterBody3D` player

## Input & Platform

- **Target Platforms**: Desktop first: macOS, Windows, Linux. Itch download build before Steam.
- **Input Methods**: Keyboard/mouse and Mac trackpad now; gamepad later.
- **Primary Input**: WASD movement, mouse/trackpad look, `W` sustained push.
- **Gamepad Support**: None for this prototype.
- **Touch Support**: None.
- **Platform Notes**: Web prototype is reference only. Godot desktop builds are the main path.

## Naming Conventions

- **Classes**: PascalCase `class_name` for reusable scripts.
- **Variables**: `snake_case` with explicit type annotations.
- **Signals/Events**: `snake_case`, past-tense when event-like.
- **Files**: Existing PascalCase script files are allowed; new reusable components should use descriptive PascalCase to match current project.
- **Scenes/Prefabs**: PascalCase `.tscn`.
- **Constants**: `SCREAMING_SNAKE_CASE`.

## Performance Budgets

- **Target Framerate**: 60 FPS desktop.
- **Frame Budget**: 16.67 ms.
- **Draw Calls**: Keep low-poly prototype simple; no formal cap yet.
- **Memory Ceiling**: No formal cap for spike, but avoid large external assets.

## Testing

- **Framework**: Godot headless script tests in `godot/tests`.
- **Minimum Coverage**: Gameplay logic and physics regressions for every push/camera/control change.
- **Required Tests**: `test_game_logic.gd`, `test_push_physics.gd`, `test_contact_push_physics.gd`, `test_player_behavior.gd`, `test_main_start.gd`.

## Forbidden Patterns

- Do not return to polishing the old React/Web prototype unless explicitly asked.
- Do not replace Godot/GDScript with C# without explicit user direction.
- Do not script the stone along a path; push must remain sustained input plus physics.
- Do not rely on static code inspection alone for feel/camera/physics claims.

## Allowed Libraries / Addons

- Godot AI addon in `godot/addons/godot_ai`.
- Godot MCP Pro public editor addon in `godot/addons/godot_mcp`; full MCP Pro requires paid server package before use.
- No external runtime gameplay dependencies are approved yet.

## Architecture Decisions Log

- Current main technical route: Godot 4.6.2 / GDScript / non-C#.
- Current playable target: one double-sided mountain vertical slice with continuous stone pushing and descent loop.

## Engine Specialists

- **Primary**: `ccgs-godot-specialist`
- **Language/Code Specialist**: `ccgs-godot-gdscript-specialist`
- **Shader Specialist**: `ccgs-godot-shader-specialist`
- **UI Specialist**: `ccgs-ui-programmer` with Godot specialist review when needed
- **Additional Specialists**: `ccgs-gameplay-programmer`, `ccgs-performance-analyst`, `ccgs-qa-tester`
- **Routing Notes**: Use CCGS specialists conceptually in this session. Spawn subagents only if the user explicitly asks for team/subagent/full-review work.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `.gd` game code | `ccgs-godot-gdscript-specialist` |
| `.tscn` scenes | `ccgs-godot-specialist` |
| Shader / material files | `ccgs-godot-shader-specialist` |
| UI / HUD files | `ccgs-ui-programmer` |
| Native extension / plugin files | `ccgs-godot-gdextension-specialist` |
| General architecture review | `ccgs-technical-director` |
