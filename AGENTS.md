<!-- director:wire BEGIN -->
- Director 看板接线〔本项目；此节由 Director 看板维护，勿手改〕
    - 开工前必读：ProjectInfo/ProjectProgress.md（现在到哪 / 下一步 / 阻塞）
    - 收工后必做：更新 ProjectInfo/ProjectProgress.md（覆盖写现状快照）；有决策则追加 ProjectInfo/roadmap.md
    - 留痕：按 ProjectInfo/ 规范（sessions/ 摘要 + dialogues/ 原始对话）；每步落盘 + git 备份
    - 全项目规矩：见用户级 AGENTS.md / CLAUDE.md 内 Director 治理节
<!-- director:wire END -->

# Sisyphus Project Rules for Codex

## Default collaboration language
- Explain work to the user in concise Chinese.
- Before editing, state the files to change and the concrete plan in 3-6 bullets.
- Prefer small, reviewable diffs and run the fastest relevant Godot checks after behavior changes.

## Godot-first workflow
- The main implementation target is `/Users/haodong/Documents/GitHub/Sisyphus/godot`.
- Treat `/Users/haodong/Documents/GitHub/Sisyphus/prototype` as reference only; do not continue polishing the old web prototype unless explicitly asked.
- Use Godot 4.6.2 and GDScript. Do not introduce C# unless the user explicitly changes the technical direction.

## AI / Codex / Godot tooling workflow
- Prefer Godot AI MCP for editor-aware work when available.
  - Godot AI addon is installed at `godot/addons/godot_ai`.
  - Codex MCP config is in `/Users/haodong/.codex/config.toml` under `[mcp_servers."godot-ai"]`.
  - Expected MCP endpoint: `http://127.0.0.1:8000/mcp`.
  - To use it, open the Godot project first and confirm the Godot AI dock says `Connected`.
- Godot MCP Pro addon is installed at `godot/addons/godot_mcp`.
  - The public addon can run in the editor and listens on ports `6505-6514`.
  - The Node MCP server is only in the paid full package. Do not claim MCP Pro is fully connected until the paid package `server/` path is configured.
- Use Computer Use for visual checks when MCP tools are unavailable or when validating actual rendered windows.
- For Godot visual/physics bugs, do not rely on static code inspection alone. Use at least one of:
  - Godot AI MCP editor inspection.
  - Godot running window + Computer Use screenshot.
  - Headless Godot tests that reproduce the behavior.

## Required checks for Godot behavior changes
Run these from `/Users/haodong/Documents/GitHub/Sisyphus/godot` when relevant:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_game_logic.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_push_physics.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_player_behavior.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_main_start.gd
```

For visual verification:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/Main.tscn
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/Main.tscn -- --auto-push
```

## Current gameplay priorities
- First vertical slice only: double-sided mountain, continuous stone pushing, close shoulder camera, descent loop.
- Push feel matters more than visual polish.
- The player should not feel glued to the stone. Holding either hand trigger should sustain that hand's push; releasing both or backing away should smoothly disengage.
- Camera look is independent from force. Body facing plus per-hand contact geometry controls force, while A/D remains footwork only.

## Latest project journal
- Start with [`docs/journal/2026-07-31-two-hand-push-summary.md`](docs/journal/2026-07-31-two-hand-push-summary.md).
- Open its linked sanitized transcript only when exact session context or rejected alternatives are needed.

## Codex Game Studios workflow
- CCGS is installed project-locally under `.agents/skills/ccgs-*`, `.codex/agents/ccgs-*`, `.codex/rules`, `docs/studio`, and `production`.
- Use CCGS as a workflow layer, not as a reason to rewrite working game code wholesale.
- For the current stage, prefer `$ccgs-prototype` / `$ccgs-quick-design` / `$ccgs-smoke-check` style work: one falsifiable gameplay hypothesis, one small implementation slice, then Godot tests plus visual evidence.
- Use `$ccgs-vertical-slice` only when validating a complete 3-5 minute loop at representative quality.
- Spawn CCGS subagents only when the user explicitly asks for team/subagent/full-review work.
