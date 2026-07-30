# Skill Flow Diagrams

Visual maps of how skills chain together across the 7 development phases.
These show what runs before and after each skill, and what artifacts flow between them.

---

## Full Pipeline Overview (Zero to Ship)

```
PHASE 1: CONCEPT
  $ccgs-start ──────────────────────────────────────────────────────► routes to A/B/C/D
  $ccgs-brainstorm ──────────────────────────────────────────────────► design/gdd/game-concept.md
  $ccgs-setup-engine ────────────────────────────────────────────────► AGENTS.md + technical-preferences.md
  $ccgs-prototype [core-mechanic] ───────────────────────────────────► prototypes/[name]-concept/REPORT.md
        │ PROCEED                                                  (validate idea BEFORE writing GDDs)
        ▼
  $ccgs-design-review [game-concept.md] ────────────────────────────► concept validated
  $ccgs-gate-check ─────────────────────────────────────────────────► PASS → advance to systems-design
        │
        ▼
PHASE 2: SYSTEMS DESIGN
  $ccgs-map-systems ────────────────────────────────────────────────► design/gdd/systems-index.md
        │
        ▼ (for each system, in dependency order)
  $ccgs-design-system [name] ──────────────────────────────────────► design/gdd/[system].md
  $ccgs-design-review [system].md ─────────────────────────────────► per-GDD review comments
        │
        ▼ (after all MVP GDDs done)
  $ccgs-review-all-gdds ────────────────────────────────────────────► design/gdd/gdd-cross-review-[date].md
  $ccgs-gate-check ─────────────────────────────────────────────────► PASS → advance to technical-setup
        │
        ▼
PHASE 3: TECHNICAL SETUP
  $ccgs-create-architecture ────────────────────────────────────────► docs/architecture/master.md
  $ccgs-architecture-decision (×N) ─────────────────────────────────► docs/architecture/[adr-nnn].md
  $ccgs-architecture-review ────────────────────────────────────────► review report + docs/architecture/tr-registry.yaml
  $ccgs-create-control-manifest ────────────────────────────────────► docs/architecture/control-manifest.md
  $ccgs-gate-check ─────────────────────────────────────────────────► PASS → advance to pre-production
        │
        ▼
PHASE 4: PRE-PRODUCTION
  [UX — before epics, so specs exist when stories are written]
  $ccgs-ux-design [screen/hud/patterns] ────────────────────────────► design/ux/*.md
  $ccgs-ux-review ──────────────────────────────────────────────────► UX specs approved (HARD gate for $ccgs-team-ui)

  [Test infrastructure — scaffold before stories reference tests]
  $ccgs-test-setup ─────────────────────────────────────────────────► test framework + CI/CD pipeline
  $ccgs-test-helpers ───────────────────────────────────────────────► tests/helpers/[engine-specific].gd

  [Vertical slice — before epics, validate full game loop]
  $ccgs-vertical-slice ─────────────────────────────────────────────► prototypes/[name]-vertical-slice/REPORT.md
  $ccgs-playtest-report ────────────────────────────────────────────► production/playtests/

  [Stories + sprint plan — only after vertical slice PROCEEDS]
  $ccgs-create-epics [layer] ───────────────────────────────────────► production/epics/*/EPIC.md
  $ccgs-create-stories [epic-slug] ─────────────────────────────────► production/epics/*/story-*.md
  $ccgs-sprint-plan new ────────────────────────────────────────────► production/sprints/sprint-01.md
  $ccgs-gate-check ─────────────────────────────────────────────────► PASS → advance to production
        │
        ▼
PHASE 5: PRODUCTION (repeating sprint loop)
  $ccgs-sprint-status ──────────────────────────────────────────────► sprint snapshot
  $ccgs-story-readiness [story] ────────────────────────────────────► story validated READY
        │
        ▼ (pick up and implement)
  $ccgs-dev-story [story] ──────────────────────────────────────────► routes to correct programmer agent
        │
        ▼ (during implementation, as needed)
  $ccgs-code-review ────────────────────────────────────────────────► code review report
  $ccgs-scope-check ────────────────────────────────────────────────► scope creep detected / clear
  $ccgs-content-audit ──────────────────────────────────────────────► GDD content gaps identified
  $ccgs-bug-report ─────────────────────────────────────────────────► production/qa/bugs/bug-NNN.md
  $ccgs-bug-triage ─────────────────────────────────────────────────► bugs re-prioritized + assigned

  [Team skills for feature areas — spawn when working a full feature]
  $ccgs-team-combat / $ccgs-team-narrative / $ccgs-team-ui / $ccgs-team-level / $ccgs-team-audio

  [QA cycle per sprint]
  $ccgs-qa-plan ────────────────────────────────────────────────────► production/qa/qa-plan-sprint-NN.md
  $ccgs-smoke-check ────────────────────────────────────────────────► smoke test gate (PASS/FAIL)
  $ccgs-regression-suite ───────────────────────────────────────────► coverage gaps + missing regression tests
  $ccgs-test-evidence-review ───────────────────────────────────────► evidence quality report
  $ccgs-test-flakiness ─────────────────────────────────────────────► flaky test report
        │
        ▼
  $ccgs-story-done [story] ─────────────────────────────────────────► story closed + next surfaced
  $ccgs-sprint-plan [next] ─────────────────────────────────────────► next sprint
        │
        ▼ (after Production milestone)
  $ccgs-milestone-review ───────────────────────────────────────────► milestone report
  $ccgs-gate-check ─────────────────────────────────────────────────► PASS → advance to polish
        │
        ▼
PHASE 6: POLISH
  $ccgs-perf-profile ───────────────────────────────────────────────► perf report + fixes
  $ccgs-balance-check ──────────────────────────────────────────────► balance report + fixes
  $ccgs-asset-audit ────────────────────────────────────────────────► asset compliance report
  $ccgs-tech-debt ──────────────────────────────────────────────────► docs/tech-debt-register.md
  $ccgs-soak-test ──────────────────────────────────────────────────► soak test protocol + results
  $ccgs-localize ───────────────────────────────────────────────────► localization readiness report
  $ccgs-team-polish ────────────────────────────────────────────────► polish sprint orchestrated
  $ccgs-team-qa ────────────────────────────────────────────────────► full QA cycle sign-off
  $ccgs-gate-check ─────────────────────────────────────────────────► PASS → advance to release
        │
        ▼
PHASE 7: RELEASE
  $ccgs-launch-checklist ───────────────────────────────────────────► launch readiness report
  $ccgs-release-checklist ──────────────────────────────────────────► platform-specific checklist
  $ccgs-changelog ──────────────────────────────────────────────────► CHANGELOG.md
  $ccgs-patch-notes ────────────────────────────────────────────────► player-facing notes
  $ccgs-team-release ───────────────────────────────────────────────► release pipeline orchestrated
        │
        ▼ (post-launch, ongoing)
  $ccgs-hotfix ─────────────────────────────────────────────────────► emergency fix with audit trail
  $ccgs-team-live-ops ──────────────────────────────────────────────► live-ops content plan
```

---

## Skill Chain: $ccgs-design-system in Detail

How a single GDD gets authored, reviewed, and handed to architecture:

```
systems-index.md (input)
game-concept.md (input)
upstream GDDs (input, if any)
        │
        ▼
$ccgs-design-system [name]
        │
        ├── Pre-check: feasibility table + engine risk flags
        │
        ├── Section cycle × 8:
        │     question → options → decision → draft → approval → WRITE
        │     [each section written to file immediately after approval]
        │
        └── Output: design/gdd/[system].md (complete, all 8 sections)
                │
                ▼
        $ccgs-design-review design/gdd/[system].md
                │
                ├── APPROVED → mark DONE in systems-index, proceed to next system
                ├── NEEDS REVISION → agent shows specific issues, re-enter section cycle
                └── MAJOR REVISION → significant redesign needed before next system
                        │
                        ▼ (after all MVP GDDs + cross-review)
                $ccgs-review-all-gdds
                        │
                        └── Output: gdd-cross-review-[date].md
```

---

## Skill Chain: UX / UI Pipeline in Detail

UX specs are authored in Phase 4 (Pre-Production), before epics are written, so
that story acceptance criteria can reference specific UX artifacts.

```
design/gdd/*.md (UI/UX requirements extracted)
design/player-journey.md (emotional arc, if authored)
        │
        ▼
$ccgs-ux-design hud              → design/ux/hud.md
$ccgs-ux-design screen [name]    → design/ux/screens/[name].md
$ccgs-ux-design patterns         → design/ux/interaction-patterns.md
        │
        ▼
$ccgs-ux-review design/ux/
        │
        ├── APPROVED → UX specs ready, proceed to $ccgs-create-epics
        ├── NEEDS REVISION → blocking issues listed → fix → re-run review
        └── MAJOR REVISION → fundamental UX problems → redesign before epics
                │
                ▼ (after APPROVED — in Phase 5 when implementing UI features)
        $ccgs-team-ui
                │
                ├── Phase 1: $ccgs-ux-design (if any specs still missing) + $ccgs-ux-review
                ├── Phase 2: visual design (ccgs-art-director)
                ├── Phase 3: layout implementation (ccgs-ui-programmer)
                ├── Phase 4: accessibility audit (ccgs-accessibility-specialist)
                └── Phase 5: final review

Note: $ccgs-ux-design and $ccgs-ux-review belong in Phase 4 (Pre-Production).
      $ccgs-team-ui belongs in Phase 5 (Production) when a UI feature is being built.
```

---

## Skill Chain: Dev Story Flow in Detail

How a story moves from backlog to closed:

```
$ccgs-story-readiness [story]
        │
        ├── READY → Status: ready-for-dev → pick up for implementation
        ├── NEEDS WORK → agent shows specific gaps → resolve → re-run readiness
        └── BLOCKED → ADR still Proposed, or upstream story incomplete
                │
                ▼ (after READY)
        $ccgs-dev-story [story]
                │
                ├── Reads: story file, linked GDD requirement, ADR decisions, control manifest
                ├── Routes to: ccgs-gameplay-programmer / ccgs-engine-programmer / ccgs-ui-programmer / etc.
                │
                └── Implementation begins
                        │
                        ▼ (optional, during/after implementation)
                $ccgs-code-review          → architectural review of changeset
                $ccgs-scope-check          → verify no scope creep vs. original story criteria
                $ccgs-test-evidence-review → validate test files and manual evidence quality
                        │
                        ▼
                $ccgs-story-done [story]
                        │
                        ├── COMPLETE → Status: Complete, sprint-status.yaml updated, next story surfaced
                        ├── COMPLETE WITH NOTES → complete but some criteria deferred (logged)
                        └── BLOCKED → acceptance criteria cannot be verified → investigate blocker
```

---

## Skill Chain: Story Lifecycle (Backlog to Closed)

How a story gets from backlog to closed (summary view):

```
$ccgs-create-epics [layer]
        │
        └── Output: production/epics/[slug]/EPIC.md
                │
                ▼
        $ccgs-create-stories [epic-slug]
                │
                └── Output: production/epics/[slug]/story-NNN-[slug].md
                            (Status: Ready or Blocked if ADR is Proposed)
                │
                ▼
        $ccgs-story-readiness [story]
                │
                ├── READY → $ccgs-dev-story → implement → $ccgs-story-done
                ├── NEEDS WORK → resolve gaps → re-run
                └── BLOCKED → fix upstream dependency first
```

---

## Skill Chain: QA Pipeline in Detail

```
[Phase 4 — one-time infrastructure setup]
$ccgs-test-setup ────────────────────────────────────────────────────► test framework scaffolded + CI/CD wired
$ccgs-test-helpers ──────────────────────────────────────────────────► tests/helpers/[engine].gd (GDUnit4, NUnit, etc.)

[Phase 5 — per-sprint QA cycle]
$ccgs-qa-plan [sprint or feature]
        │
        ├── Reads: story files, GDDs, acceptance criteria
        ├── Classifies each story by test type:
        │     Logic → automated unit test (BLOCKING)
        │     Integration → integration test or documented playtest (BLOCKING)
        │     Visual/Feel → screenshot + lead sign-off (ADVISORY)
        │     UI → manual walkthrough or interaction test (ADVISORY)
        │     Config/Data → smoke check (ADVISORY)
        └── Output: production/qa/qa-plan-sprint-NN.md
                │
                ▼
        $ccgs-smoke-check
                │
                ├── PASS → QA hand-off cleared
                └── FAIL → block sprint close → fix critical paths first
                        │
                        ▼
                $ccgs-regression-suite
                        │
                        └── Coverage gaps + list of fixed bugs without regression tests
                                │
                                ▼
                        $ccgs-test-evidence-review
                                │
                                └── Validates evidence quality, not just existence
                                        │
                                        ▼ (if CI run history available)
                        $ccgs-test-flakiness
                                │
                                └── Flaky test report + fix recommendations

[Phase 6 — extended stability testing]
$ccgs-soak-test ─────────────────────────────────────────────────────► soak test protocol + observed results
$ccgs-team-qa ───────────────────────────────────────────────────────► full QA cycle sign-off for release gate

[Ongoing — bug management]
$ccgs-bug-report ────────────────────────────────────────────────────► production/qa/bugs/bug-NNN.md
$ccgs-bug-triage ────────────────────────────────────────────────────► open bugs re-prioritized + assigned

[Meta — harness validation]
$ccgs-skill-test [lint|spec|catalog] ────────────────────────────────► skill file structural + behavioral check
```

---

## Brownfield Onboarding Flow

For projects with existing work (use `$ccgs-start` option D or run directly):

```
$ccgs-project-stage-detect    → stage detection report
        │
        ▼
$ccgs-adopt
        │
        ├── Phase 1: detect what exists
        ├── Phase 2: FORMAT audit (not just existence)
        ├── Phase 3: classify gaps (BLOCKING / HIGH / MEDIUM / LOW)
        ├── Phase 4: ordered migration plan
        ├── Phase 5: write docs/adoption-plan-[date].md
        └── Phase 6: fix most urgent gap inline (optional)
                │
                ▼
        $ccgs-design-system retrofit [path]    → fills missing GDD sections
        $ccgs-architecture-decision retrofit [path] → fills missing ADR sections
        $ccgs-gate-check                       → where are you in the pipeline?
```

---

## How to Read These Diagrams

| Symbol | Meaning |
|--------|---------|
| `──►` | Produces this artifact |
| `│ ▼` | Flows into next step |
| `├──` | Branch (multiple possible outcomes) |
| `×N` | Runs N times (once per system, story, etc.) |
| `(input)` | Read by the skill but not produced here |
| `[optional]` | Not required for the gate to pass |
| `WRITE` (caps) | File written to disk immediately |

---

## Common Entry Points

| Where you are | Run this |
|---------------|---------|
| Brand new, no idea | `$ccgs-start` → `$ccgs-brainstorm` |
| Have a concept, no engine | `$ccgs-setup-engine` |
| Have concept + engine | `$ccgs-map-systems` |
| Mid-systems design | `$ccgs-design-system [next system]` or `$ccgs-map-systems next` |
| All GDDs done | `$ccgs-review-all-gdds` → `$ccgs-gate-check` |
| In technical setup | `$ccgs-create-architecture` → `$ccgs-architecture-decision` |
| Starting UX design | `$ccgs-ux-design screen [name]` or `$ccgs-ux-design hud` |
| Scaffolding tests | `$ccgs-test-setup` → `$ccgs-test-helpers` |
| Have stories, ready to code | `$ccgs-story-readiness [story]` → `$ccgs-dev-story [story]` |
| Story done | `$ccgs-story-done [story]` |
| Running QA for a sprint | `$ccgs-qa-plan` → `$ccgs-smoke-check` → `$ccgs-regression-suite` |
| Bug backlog needs sorting | `$ccgs-bug-triage` |
| Extended stability testing | `$ccgs-soak-test` |
| Not sure | `$ccgs-help` |
| Existing project | `$ccgs-adopt` |
