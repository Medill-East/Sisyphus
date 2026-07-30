# Godot Current Best Practices

Project-local pointer for CCGS agents.

Read the migrated Godot 4.6 reference before proposing APIs:

- `docs/studio/upstream-project-docs/engine-reference/godot/current-best-practices.md`

Project-specific defaults:

- Prefer GDScript with explicit type annotations.
- Use Godot CLI headless script tests for gameplay logic.
- Use Computer Use or Godot AI MCP for visual/physics verification.
- For stone-pushing behavior, verify both automated tests and an actual running window.
