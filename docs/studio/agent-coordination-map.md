# Agent Coordination and Delegation Map

## Organizational Hierarchy

```
                           [Human Developer]
                                 |
                 +---------------+---------------+
                 |               |               |
         ccgs-creative-director  ccgs-technical-director  ccgs-producer
                 |               |               |
        +--------+--------+     |        (coordinates all)
        |        |        |     |
  ccgs-game-designer art-dir  narr-dir  ccgs-lead-programmer  ccgs-qa-lead  audio-dir
        |        |        |         |                |        |
     +--+--+     |     +--+--+  +--+--+--+--+--+   |        |
     |  |  |     |     |     |  |  |  |  |  |  |   |        |
    sys lvl eco  ta   wrt  wrld gp ep  ai net tl ui qa-t    snd
                                 |
                             +---+---+
                             |       |
                          perf-a   devops   analytics

  Additional Leads (report to ccgs-producer/directors):
    ccgs-release-manager         -- Release pipeline, versioning, deployment
    ccgs-localization-lead       -- i18n, string tables, translation pipeline
    ccgs-prototyper              -- Rapid throwaway prototypes, concept validation
    ccgs-security-engineer       -- Anti-cheat, exploits, data privacy, network security
    ccgs-accessibility-specialist -- WCAG, colorblind, remapping, text scaling
    ccgs-live-ops-designer       -- Seasons, events, battle passes, retention, live economy
    ccgs-community-manager       -- Patch notes, player feedback, crisis comms

  Engine Specialists (use the SET matching your engine):
    ccgs-unreal-specialist  -- UE5 lead: Blueprint/C++, GAS overview, UE subsystems
      ccgs-ue-gas-specialist         -- GAS: abilities, effects, attributes, tags, prediction
      ccgs-ue-blueprint-specialist   -- Blueprint: BP/C++ boundary, graph standards, optimization
      ccgs-ue-replication-specialist -- Networking: replication, RPCs, prediction, bandwidth
      ccgs-ue-umg-specialist         -- UI: UMG, CommonUI, widget hierarchy, data binding

    ccgs-unity-specialist   -- Unity lead: MonoBehaviour/DOTS, Addressables, URP/HDRP
      ccgs-unity-dots-specialist         -- DOTS/ECS: Jobs, Burst, hybrid renderer
      ccgs-unity-shader-specialist       -- Shaders: Shader Graph, VFX Graph, SRP customization
      ccgs-unity-addressables-specialist -- Assets: async loading, bundles, memory, CDN
      ccgs-unity-ui-specialist           -- UI: UI Toolkit, UGUI, UXML/USS, data binding

    ccgs-godot-specialist   -- Godot 4 lead: GDScript, node/scene, signals, resources
      ccgs-godot-gdscript-specialist    -- GDScript: static typing, patterns, signals, performance
      ccgs-godot-csharp-specialist      -- C#: .NET patterns, [Signal] delegates, async, type-safe node access
      ccgs-godot-shader-specialist      -- Shaders: Godot shading language, visual shaders, VFX
      ccgs-godot-gdextension-specialist -- Native: C++/Rust bindings, GDExtension, build systems
```

### Legend
```
sys  = ccgs-systems-designer       gp  = ccgs-gameplay-programmer
lvl  = ccgs-level-designer         ep  = ccgs-engine-programmer
eco  = ccgs-economy-designer       ai  = ccgs-ai-programmer
ta   = ccgs-technical-artist       net = ccgs-network-programmer
wrt  = ccgs-writer                 tl  = ccgs-tools-programmer
wrld = ccgs-world-builder          ui  = ccgs-ui-programmer
snd  = ccgs-sound-designer         qa-t = ccgs-qa-tester
narr-dir = ccgs-narrative-director perf-a = ccgs-performance-analyst
art-dir = ccgs-art-director
```

## Delegation Rules

### Who Can Delegate to Whom

| From | Can Delegate To |
|------|----------------|
| ccgs-creative-director | ccgs-game-designer, ccgs-art-director, ccgs-audio-director, ccgs-narrative-director |
| ccgs-technical-director | ccgs-lead-programmer, ccgs-devops-engineer, ccgs-performance-analyst, ccgs-technical-artist (technical decisions) |
| ccgs-producer | Any agent (task assignment within their domain only) |
| ccgs-game-designer | ccgs-systems-designer, ccgs-level-designer, ccgs-economy-designer |
| ccgs-lead-programmer | ccgs-gameplay-programmer, ccgs-engine-programmer, ccgs-ai-programmer, ccgs-network-programmer, ccgs-tools-programmer, ccgs-ui-programmer |
| ccgs-art-director | ccgs-technical-artist, ccgs-ux-designer |
| ccgs-audio-director | ccgs-sound-designer |
| ccgs-narrative-director | ccgs-writer, ccgs-world-builder |
| ccgs-qa-lead | ccgs-qa-tester |
| ccgs-release-manager | ccgs-devops-engineer (release builds), ccgs-qa-lead (release testing) |
| ccgs-localization-lead | ccgs-writer (string review), ccgs-ui-programmer (text fitting) |
| ccgs-prototyper | (works independently, reports findings to ccgs-producer and relevant leads) |
| ccgs-security-engineer | ccgs-network-programmer (security review), ccgs-lead-programmer (secure patterns) |
| ccgs-accessibility-specialist | ccgs-ux-designer (accessible patterns), ccgs-ui-programmer (implementation), ccgs-qa-tester (a11y testing) |
| [engine]-specialist | engine sub-specialists (delegates subsystem-specific work) |
| [engine] sub-specialists | (advises all programmers on engine subsystem patterns and optimization) |
| ccgs-live-ops-designer | ccgs-economy-designer (live economy), ccgs-community-manager (event comms), ccgs-analytics-engineer (engagement metrics) |
| ccgs-community-manager | (works with ccgs-producer for approval, ccgs-release-manager for patch note timing) |

### Escalation Paths

| Situation | Escalate To |
|-----------|------------|
| Two designers disagree on a mechanic | ccgs-game-designer |
| Game design vs narrative conflict | ccgs-creative-director |
| Game design vs technical feasibility | ccgs-producer (facilitates), then ccgs-creative-director + ccgs-technical-director |
| Art vs audio tonal conflict | ccgs-creative-director |
| Code architecture disagreement | ccgs-technical-director |
| Cross-system code conflict | ccgs-lead-programmer, then ccgs-technical-director |
| Schedule conflict between departments | ccgs-producer |
| Scope exceeds capacity | ccgs-producer, then ccgs-creative-director for cuts |
| Quality gate disagreement | ccgs-qa-lead, then ccgs-technical-director |
| Performance budget violation | ccgs-performance-analyst flags, ccgs-technical-director decides |

## Common Workflow Patterns

### Pattern 1: New Feature (Full Pipeline)

```
1. ccgs-creative-director  -- Approves feature concept aligns with vision
2. ccgs-game-designer      -- Creates design document with full spec
3. ccgs-producer           -- Schedules work, identifies dependencies
4. ccgs-lead-programmer    -- Designs code architecture, creates interface sketch
5. [specialist-programmer] -- Implements the feature
6. ccgs-technical-artist   -- Implements visual effects (if needed)
7. ccgs-writer             -- Creates text content (if needed)
8. ccgs-sound-designer     -- Creates audio event list (if needed)
9. ccgs-qa-tester          -- Writes test cases
10. ccgs-qa-lead           -- Reviews and approves test coverage
11. ccgs-lead-programmer   -- Code review
12. ccgs-qa-tester         -- Executes tests
13. ccgs-producer          -- Marks task complete
```

### Pattern 2: Bug Fix

```
1. ccgs-qa-tester          -- Files bug report with $ccgs-bug-report
2. ccgs-qa-lead            -- Triages severity and priority
3. ccgs-producer           -- Assigns to sprint (if not S1)
4. ccgs-lead-programmer    -- Identifies root cause, assigns to programmer
5. [specialist-programmer] -- Fixes the bug
6. ccgs-lead-programmer    -- Code review
7. ccgs-qa-tester          -- Verifies fix and runs regression
8. ccgs-qa-lead            -- Closes bug
```

### Pattern 3: Balance Adjustment

```
1. ccgs-analytics-engineer -- Identifies imbalance from data (or player reports)
2. ccgs-game-designer      -- Evaluates the issue against design intent
3. ccgs-economy-designer   -- Models the adjustment
4. ccgs-game-designer      -- Approves the new values
5. [data file update] -- Change configuration values
6. ccgs-qa-tester          -- Regression test affected systems
7. ccgs-analytics-engineer -- Monitor post-change metrics
```

### Pattern 4: New Area/Level

```
1. ccgs-narrative-director -- Defines narrative purpose and beats for the area
2. ccgs-world-builder      -- Creates lore and environmental context
3. ccgs-level-designer     -- Designs layout, encounters, pacing
4. ccgs-game-designer      -- Reviews mechanical design of encounters
5. ccgs-art-director       -- Defines visual direction for the area
6. ccgs-audio-director     -- Defines audio direction for the area
7. [implementation by relevant programmers and artists]
8. ccgs-writer             -- Creates area-specific text content
9. ccgs-qa-tester          -- Tests the complete area
```

### Pattern 5: Sprint Cycle

```
1. ccgs-producer           -- Plans sprint with $ccgs-sprint-plan new
2. [All agents]       -- Execute assigned tasks
3. ccgs-producer           -- Daily status with $ccgs-sprint-plan status
4. ccgs-qa-lead            -- Continuous testing during sprint
5. ccgs-lead-programmer    -- Continuous code review during sprint
6. ccgs-producer           -- Sprint retrospective with post-sprint hook
7. ccgs-producer           -- Plans next sprint incorporating learnings
```

### Pattern 6: Milestone Checkpoint

```
1. ccgs-producer           -- Runs $ccgs-milestone-review
2. ccgs-creative-director  -- Reviews creative progress
3. ccgs-technical-director -- Reviews technical health
4. ccgs-qa-lead            -- Reviews quality metrics
5. ccgs-producer           -- Facilitates go/no-go discussion
6. [All directors]    -- Agree on scope adjustments if needed
7. ccgs-producer           -- Documents decisions and updates plans
```

### Pattern 7: Release Pipeline

```text
1. ccgs-producer             -- Declares release candidate, confirms milestone criteria met
2. ccgs-release-manager      -- Cuts release branch, generates $ccgs-release-checklist
3. ccgs-qa-lead              -- Runs full regression, signs off on quality
4. ccgs-localization-lead    -- Verifies all strings translated, text fitting passes
5. ccgs-performance-analyst  -- Confirms performance benchmarks within targets
6. ccgs-devops-engineer      -- Builds release artifacts, runs deployment pipeline
7. ccgs-release-manager      -- Generates $ccgs-changelog, tags release, creates release notes
8. ccgs-technical-director   -- Final sign-off on major releases
9. ccgs-release-manager      -- Deploys and monitors for 48 hours
10. ccgs-producer            -- Marks release complete
```

### Pattern 8: Concept Prototype (early — before GDDs)

```text
1. ccgs-game-designer        -- Defines the hypothesis and success criteria
2. ccgs-prototyper           -- Scaffolds concept prototype with $ccgs-prototype
3. ccgs-prototyper           -- Builds minimal implementation (1-3 days)
4. ccgs-game-designer        -- Evaluates prototype against criteria
5. ccgs-prototyper           -- Documents findings in REPORT.md
6. ccgs-creative-director    -- PROCEED / PIVOT / KILL decision (full mode only)
7. ccgs-game-designer        -- Informs GDD writing with prototype learnings if PROCEED
```

### Pattern 8b: Vertical Slice (pre-production — after GDDs and architecture)

```text
1. ccgs-game-designer        -- Confirms slice scope against GDDs
2. ccgs-prototyper           -- Builds production-quality end-to-end build with $ccgs-vertical-slice
3. ccgs-prototyper           -- Conducts internal playtest sessions (minimum 1)
4. ccgs-prototyper           -- Documents findings in REPORT.md
5. ccgs-creative-director    -- Go/no-go decision on proceeding to Production (full mode)
6. ccgs-producer             -- Schedules Production epics/sprints if PROCEED
```

### Pattern 9: Live Event / Season Launch

```text
1. ccgs-live-ops-designer     -- Designs event/season content, rewards, schedule
2. ccgs-game-designer         -- Validates gameplay mechanics for event
3. ccgs-economy-designer      -- Balances event economy and reward values
4. ccgs-narrative-director    -- Provides seasonal narrative theme
5. ccgs-writer                -- Creates event descriptions and lore
6. ccgs-producer              -- Schedules implementation work
7. [implementation by relevant programmers]
8. ccgs-qa-lead               -- Test event flow end-to-end
9. ccgs-community-manager     -- Drafts event announcement and patch notes
10. ccgs-release-manager      -- Deploys event content
11. ccgs-analytics-engineer   -- Monitors event participation and metrics
12. ccgs-live-ops-designer    -- Post-event analysis and learnings
```

## Cross-Domain Communication Protocols

### Design Change Notification

When a design document changes, the ccgs-game-designer must notify:
- ccgs-lead-programmer (implementation impact)
- ccgs-qa-lead (test plan update needed)
- ccgs-producer (schedule impact assessment)
- Relevant specialist agents depending on the change

### Architecture Change Notification

When an ADR is created or modified, the ccgs-technical-director must notify:
- ccgs-lead-programmer (code changes needed)
- All affected specialist programmers
- ccgs-qa-lead (testing strategy may change)
- ccgs-producer (schedule impact)

### Asset Standard Change Notification

When the art bible or asset standards change, the ccgs-art-director must notify:
- ccgs-technical-artist (pipeline changes)
- All content creators working with affected assets
- ccgs-devops-engineer (if build pipeline is affected)

## Anti-Patterns to Avoid

1. **Bypassing the hierarchy**: A specialist agent should never make decisions
   that belong to their lead without consultation.
2. **Cross-domain implementation**: An agent should never modify files outside
   their designated area without explicit delegation from the relevant owner.
3. **Shadow decisions**: All decisions must be documented. Verbal agreements
   without written records lead to contradictions.
4. **Monolithic tasks**: Every task assigned to an agent should be completable
   in 1-3 days. If it is larger, it must be broken down first.
5. **Assumption-based implementation**: If a spec is ambiguous, the implementer
   must ask the specifier rather than guessing. Wrong guesses are more expensive
   than a question.
