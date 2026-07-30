# Agent Roster

The following agents are available. Each has a dedicated definition file in
`.codex/agents/`. Use the agent best suited to the task at hand. When a task
spans multiple domains, the coordinating agent (usually `ccgs-producer` or the
domain lead) should delegate to specialists.

## Tier 1 -- Leadership Agents (Opus)
| Agent | Domain | When to Use |
|-------|--------|-------------|
| `ccgs-creative-director` | High-level vision | Major creative decisions, pillar conflicts, tone/direction |
| `ccgs-technical-director` | Technical vision | Architecture decisions, tech stack choices, performance strategy |
| `ccgs-producer` | Production management | Sprint planning, milestone tracking, risk management, coordination |

## Tier 2 -- Department Lead Agents (Sonnet)
| Agent | Domain | When to Use |
|-------|--------|-------------|
| `ccgs-game-designer` | Game design | Mechanics, systems, progression, economy, balancing |
| `ccgs-lead-programmer` | Code architecture | System design, code review, API design, refactoring |
| `ccgs-art-director` | Visual direction | Style guides, art bible, asset standards, UI/UX direction |
| `ccgs-audio-director` | Audio direction | Music direction, sound palette, audio implementation strategy |
| `ccgs-narrative-director` | Story and writing | Story arcs, world-building, character design, dialogue strategy |
| `ccgs-qa-lead` | Quality assurance | Test strategy, bug triage, release readiness, regression planning |
| `ccgs-release-manager` | Release pipeline | Build management, versioning, changelogs, deployment, rollbacks |
| `ccgs-localization-lead` | Internationalization | String externalization, translation pipeline, locale testing |

## Tier 3 -- Specialist Agents (Sonnet or Haiku)
| Agent | Domain | Model | When to Use |
|-------|--------|-------|-------------|
| `ccgs-systems-designer` | Systems design | Sonnet | Specific mechanic implementation, formula design, loops |
| `ccgs-level-designer` | Level design | Sonnet | Level layouts, pacing, encounter design, flow |
| `ccgs-economy-designer` | Economy/balance | Sonnet | Resource economies, loot tables, progression curves |
| `ccgs-gameplay-programmer` | Gameplay code | Sonnet | Feature implementation, gameplay systems code |
| `ccgs-engine-programmer` | Engine systems | Sonnet | Core engine, rendering, physics, memory management |
| `ccgs-ai-programmer` | AI systems | Sonnet | Behavior trees, pathfinding, NPC logic, state machines |
| `ccgs-network-programmer` | Networking | Sonnet | Netcode, replication, lag compensation, matchmaking |
| `ccgs-tools-programmer` | Dev tools | Sonnet | Editor extensions, pipeline tools, debug utilities |
| `ccgs-ui-programmer` | UI implementation | Sonnet | UI framework, screens, widgets, data binding |
| `ccgs-technical-artist` | Tech art | Sonnet | Shaders, VFX, optimization, art pipeline tools |
| `ccgs-sound-designer` | Sound design | Sonnet | SFX design docs, audio event lists, mixing notes |
| `ccgs-writer` | Dialogue/lore | Sonnet | Dialogue writing, lore entries, item descriptions |
| `ccgs-world-builder` | World/lore design | Sonnet | World rules, faction design, history, geography |
| `ccgs-qa-tester` | Test execution | Haiku | Writing test cases, bug reports, test checklists |
| `ccgs-performance-analyst` | Performance | Sonnet | Profiling, optimization recs, memory analysis |
| `ccgs-devops-engineer` | Build/deploy | Haiku | CI/CD, build scripts, version control workflow |
| `ccgs-analytics-engineer` | Telemetry | Sonnet | Event tracking, dashboards, A/B test design |
| `ccgs-ux-designer` | UX flows | Sonnet | User flows, wireframes, accessibility, input handling |
| `ccgs-prototyper` | Rapid prototyping | Sonnet | Throwaway prototypes, mechanic testing, feasibility validation |
| `ccgs-security-engineer` | Security | Sonnet | Anti-cheat, exploit prevention, save encryption, network security |
| `ccgs-accessibility-specialist` | Accessibility | Haiku | WCAG compliance, colorblind modes, remapping, text scaling |
| `ccgs-live-ops-designer` | Live operations | Sonnet | Seasons, events, battle passes, retention, live economy |
| `ccgs-community-manager` | Community | Haiku | Patch notes, player feedback, crisis comms, community health |

## Engine-Specific Agents (use the set matching your engine)

### Engine Leads

| Agent | Engine | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `ccgs-unreal-specialist` | Unreal Engine 5 | Sonnet | Blueprint vs C++, GAS overview, UE subsystems, Unreal optimization |
| `ccgs-unity-specialist` | Unity | Sonnet | MonoBehaviour vs DOTS, Addressables, URP/HDRP, Unity optimization |
| `ccgs-godot-specialist` | Godot 4 | Sonnet | GDScript patterns, node/scene architecture, signals, Godot optimization |

### Unreal Engine Sub-Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `ccgs-ue-gas-specialist` | Gameplay Ability System | Sonnet | Abilities, gameplay effects, attribute sets, tags, prediction |
| `ccgs-ue-blueprint-specialist` | Blueprint Architecture | Sonnet | BP/C++ boundary, graph standards, naming, BP optimization |
| `ccgs-ue-replication-specialist` | Networking/Replication | Sonnet | Property replication, RPCs, prediction, relevancy, bandwidth |
| `ccgs-ue-umg-specialist` | UMG/CommonUI | Sonnet | Widget hierarchy, data binding, CommonUI input, UI performance |

### Unity Sub-Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `ccgs-unity-dots-specialist` | DOTS/ECS | Sonnet | Entity Component System, Jobs, Burst compiler, hybrid renderer |
| `ccgs-unity-shader-specialist` | Shaders/VFX | Sonnet | Shader Graph, VFX Graph, URP/HDRP customization, post-processing |
| `ccgs-unity-addressables-specialist` | Asset Management | Sonnet | Addressable groups, async loading, memory, content delivery |
| `ccgs-unity-ui-specialist` | UI Toolkit/UGUI | Sonnet | UI Toolkit, UXML/USS, UGUI Canvas, data binding, cross-platform input |

### Godot Sub-Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `ccgs-godot-gdscript-specialist` | GDScript | Sonnet | Static typing, design patterns, signals, coroutines, GDScript performance |
| `ccgs-godot-csharp-specialist` | C# / .NET | Sonnet | .NET patterns, [Signal] delegates, async, nullable types, type-safe node access |
| `ccgs-godot-shader-specialist` | Shaders/Rendering | Sonnet | Godot shading language, visual shaders, particles, post-processing |
| `ccgs-godot-gdextension-specialist` | GDExtension | Sonnet | C++/Rust bindings, native performance, custom nodes, build systems |
