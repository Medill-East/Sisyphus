# Skill Test Spec: $ccgs-team-release

## Skill Summary

Orchestrates the release team through a 7-phase pipeline from release candidate to
deployment and post-release monitoring. Coordinates ccgs-release-manager, ccgs-qa-lead,
ccgs-devops-engineer, ccgs-producer, ccgs-security-engineer (optional, required for online/
multiplayer), ccgs-network-programmer (optional, required for multiplayer),
ccgs-analytics-engineer, and ccgs-community-manager. Phase 3 agents run in parallel. Ends
with a go/no-go decision; deployment (Phase 6) is skipped if the ccgs-producer calls
NO-GO. Closes with a post-release monitoring plan.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" language in the File Write Protocol section (delegated to sub-agents)
- [ ] Has a File Write Protocol section stating that the orchestrator does not write files directly
- [ ] Has an Error Recovery Protocol section with four recovery options (surface / assess / offer options / partial report)
- [ ] Has a next-step handoff referencing post-release monitoring, `$ccgs-retrospective`, and `production/stage.txt`
- [ ] Uses `Codex request_user_input` at phase transitions requiring user approval before proceeding
- [ ] Phase 3 agents (ccgs-qa-lead, ccgs-devops-engineer, and optionally ccgs-security-engineer, ccgs-network-programmer) are explicitly stated to run in parallel
- [ ] Phase 6 (Deployment) is conditional on a GO decision from Phase 5
- [ ] ccgs-security-engineer is described as conditional on online features / player data — not always spawned

---

## Test Cases

### Case 1: Happy Path (Single-Player) — All phases complete, version deployed

**Fixture:**
- `production/stage.txt` exists and contains a Production-or-later stage
- Milestone acceptance criteria are all met (ccgs-producer can confirm)
- No online features, no multiplayer, no player data collection
- All CI builds are clean on the current branch
- No open S1/S2 bugs
- `production/sprints/` contains the completed sprint stories for this milestone

**Input:** `$ccgs-team-release v1.0.0`

**Expected behavior:**
1. Phase 1: Spawns `ccgs-producer` via Codex subagent; confirms all milestone acceptance criteria met; identifies any deferred scope; produces release authorization; presents to user; Codex request_user_input: user approves before Phase 2
2. Phase 2: Spawns `ccgs-release-manager` via Codex subagent; cuts release branch from agreed commit; bumps version numbers; invokes `$ccgs-release-checklist`; freezes branch; output: branch name and checklist; Codex request_user_input: user approves before Phase 3
3. Phase 3 (parallel): Issues Codex subagent calls simultaneously for `ccgs-qa-lead` (regression suite, critical path sign-off) and `ccgs-devops-engineer` (build artifacts, CI verification); ccgs-security-engineer is NOT spawned (no online features); ccgs-network-programmer is NOT spawned (no multiplayer); both complete successfully
4. Phase 4: Verifies localization strings all translated; `ccgs-analytics-engineer` verifies telemetry fires correctly on the release build; performance benchmarks pass; sign-off produced
5. Phase 5: Spawns `ccgs-producer` via Codex subagent; collects sign-offs from ccgs-qa-lead, ccgs-release-manager, ccgs-devops-engineer; no open blocking issues; ccgs-producer declares GO; Codex request_user_input: user sees GO decision and confirms deployment
6. Phase 6: Spawns `ccgs-release-manager` + `ccgs-devops-engineer` (parallel); tags release in version control; invokes `$ccgs-changelog`; deploys to staging; smoke test passes; deploys to production; simultaneously spawns `ccgs-community-manager` to finalize patch notes via `$ccgs-patch-notes v1.0.0` and prepare launch announcement
7. Phase 7: ccgs-release-manager generates release report; ccgs-producer updates milestone tracking; ccgs-qa-lead begins monitoring for regressions; ccgs-community-manager publishes communication; ccgs-analytics-engineer confirms live dashboards healthy
8. Verdict: COMPLETE — release executed and deployed

**Assertions:**
- [ ] Phase 3 ccgs-qa-lead and ccgs-devops-engineer Codex subagent calls are issued simultaneously, not sequentially
- [ ] ccgs-security-engineer is NOT spawned when the game has no online features, multiplayer, or player data
- [ ] Phase 5 ccgs-producer collects sign-offs from all required parties before declaring GO
- [ ] Phase 6 deployment only begins after GO decision is confirmed by the user
- [ ] `$ccgs-changelog` is invoked by ccgs-release-manager in Phase 6 (not written directly)
- [ ] `$ccgs-patch-notes v1.0.0` is invoked by ccgs-community-manager in Phase 6
- [ ] Phase 7 monitoring plan includes a 48-hour post-release monitoring commitment
- [ ] Next steps recommend updating `production/stage.txt` to `Live` after successful deployment
- [ ] Verdict: COMPLETE appears in the final output

---

### Case 2: Go/No-Go: NO — S1 bug found in Phase 3, deployment skipped

**Fixture:**
- Release candidate branch exists for v0.9.0
- ccgs-qa-lead discovers a previously unreported S1 crash in the main menu during Phase 3 regression testing
- ccgs-devops-engineer build is clean and artifacts are ready
- ccgs-producer is aware of the S1 bug

**Input:** `$ccgs-team-release v0.9.0`

**Expected behavior:**
1. Phases 1–2 complete normally; release candidate is cut
2. Phase 3 (parallel): ccgs-devops-engineer returns clean build sign-off; ccgs-qa-lead returns with an S1 bug identified and regression suite failing; ccgs-qa-lead declares quality gate: NOT PASSED
3. Orchestrator surfaces the ccgs-qa-lead result immediately: "QA-LEAD: S1 bug found — [crash description]. Quality gate: NOT PASSED."
4. Phase 4 proceeds cautiously or is paused (Codex request_user_input: continue to Phase 4 or skip to Phase 5 for go/no-go?)
5. Phase 5: Spawns `ccgs-producer` via Codex subagent; ccgs-producer receives ccgs-qa-lead's NOT PASSED verdict; no S1 sign-off available; ccgs-producer declares NO-GO with rationale: "S1 bug [ID] is open and unresolved. Releasing is not safe."
6. Codex request_user_input: user is presented with the NO-GO decision and the S1 bug details; options: fix the bug and re-run, defer the release, or override (with documented rationale)
7. Phase 6 (Deployment) is SKIPPED entirely — no branch tagging, no deploy to staging, no deploy to production
8. ccgs-community-manager is NOT spawned in Phase 6 (no deployment to announce)
9. Skill ends with a partial report summarizing what was completed (Phases 1–5) and what was skipped (Phase 6) and why
10. Verdict: BLOCKED — release not deployed

**Assertions:**
- [ ] ccgs-qa-lead S1 bug finding is surfaced to the user immediately after Phase 3 completes — not suppressed until Phase 5
- [ ] ccgs-producer's NO-GO decision explicitly references the S1 bug and the quality gate result
- [ ] Phase 6 Deployment is completely skipped when ccgs-producer declares NO-GO
- [ ] ccgs-community-manager is NOT spawned for patch notes or launch announcement on NO-GO
- [ ] The partial report clearly states which phases completed and which were skipped, with reasons
- [ ] Verdict: BLOCKED (not COMPLETE) when deployment is skipped due to NO-GO
- [ ] Codex request_user_input offers the user resolution options (fix and re-run / defer / override with rationale)
- [ ] Override path (if chosen) requires user to provide a documented rationale before proceeding to Phase 6

---

### Case 3: Security Audit for Online Game — ccgs-security-engineer is spawned in Phase 3

**Fixture:**
- Game has multiplayer features and stores player account data
- Release candidate exists for v2.1.0
- ccgs-qa-lead and ccgs-devops-engineer both return clean sign-offs
- ccgs-security-engineer audit is required per team composition rules

**Input:** `$ccgs-team-release v2.1.0`

**Expected behavior:**
1. Phases 1–2 complete normally
2. Phase 3 (parallel): Orchestrator detects that the game has online/multiplayer features and player data; issues Codex subagent calls simultaneously for `ccgs-qa-lead`, `ccgs-devops-engineer`, AND `ccgs-security-engineer`; also spawns `ccgs-network-programmer` for netcode stability sign-off
3. ccgs-security-engineer conducts pre-release security audit: reviews authentication flows, anti-cheat presence, data privacy compliance; returns sign-off
4. ccgs-network-programmer verifies lag compensation, reconnect handling, and bandwidth under load; returns sign-off
5. All four Phase 3 agents complete; their results are collected before Phase 4 begins
6. Phase 5: ccgs-producer collects sign-offs from all four Phase 3 agents (ccgs-qa-lead, ccgs-devops-engineer, ccgs-security-engineer, ccgs-network-programmer) before making the go/no-go call
7. Remaining phases proceed normally to COMPLETE

**Assertions:**
- [ ] ccgs-security-engineer IS spawned in Phase 3 when the game has online features, multiplayer, or player data — this is not skipped
- [ ] ccgs-network-programmer IS spawned in Phase 3 when the game has multiplayer
- [ ] All four Phase 3 Codex subagent calls (ccgs-qa-lead, ccgs-devops-engineer, ccgs-security-engineer, ccgs-network-programmer) are issued simultaneously
- [ ] ccgs-security-engineer audit covers authentication, anti-cheat, and data privacy compliance
- [ ] Phase 5 ccgs-producer sign-off collection includes ccgs-security-engineer (four parties, not two)
- [ ] Phase 6 deployment does not begin until ccgs-security-engineer has signed off
- [ ] Skill does NOT treat ccgs-security-engineer as optional for a game with player data

---

### Case 4: Localization Miss — Untranslated strings block the ship

**Fixture:**
- Release candidate exists for v1.2.0
- Phase 3 (ccgs-qa-lead, ccgs-devops-engineer) complete with clean sign-offs
- Phase 4: localization verification detects 47 untranslated strings in the French locale (a supported language in the game's localization scope)
- ccgs-localization-lead is available as a delegatable agent

**Input:** `$ccgs-team-release v1.2.0`

**Expected behavior:**
1. Phases 1–3 complete with clean sign-offs
2. Phase 4: Localization verification step detects untranslated strings; identifies 47 strings in French locale; ccgs-localization-lead (if available) is spawned to assess the severity
3. Orchestrator surfaces: "LOCALIZATION MISS: 47 untranslated strings found in French locale. Localization sign-off is required before shipping."
4. Codex request_user_input: options presented — (a) Fix translations and re-run Phase 4, (b) Remove French locale from this release, (c) Ship as-is with a known issues note
5. If user selects (a): Phase 4 is re-run after translations are provided; skill waits for localization sign-off
6. Phase 5 go/no-go does NOT proceed while localization sign-off is outstanding
7. Ship is blocked (Phase 6 not entered) until localization issue is resolved or explicitly waived

**Assertions:**
- [ ] Localization verification in Phase 4 detects untranslated strings and counts them (not just "some strings missing")
- [ ] Untranslated strings for a supported locale block the pipeline before Phase 5
- [ ] Codex request_user_input is used to offer the user resolution choices — the skill does not auto-waive
- [ ] Phase 5 go/no-go is NOT called while localization sign-off is pending
- [ ] If user chooses to re-run Phase 4: the skill does not require restarting from Phase 1
- [ ] If user explicitly waives (ships as-is): the waiver is documented in the release report (Phase 7) as a known issue
- [ ] Skill does NOT fabricate translated strings to unblock itself

---

### Case 5: No Argument — Skill infers version or asks

**Fixture (variant A — milestone data present):**
- `production/milestones/` exists with a milestone file; most recent milestone is "v1.1.0 — Gold"
- `production/session-state/active.md` references a version or milestone

**Fixture (variant B — no discoverable version):**
- `production/milestones/` does not exist
- `production/session-state/active.md` does not reference a version
- No git tags are present from which to infer a version

**Input:** `$ccgs-team-release` (no argument)

**Expected behavior (variant A):**
1. Phase 1: No argument provided; reads `production/session-state/active.md`; reads most recent milestone file in `production/milestones/`
2. Infers v1.1.0 as the target version; reports "No version argument provided — inferred v1.1.0 from milestone data. Proceeding."
3. Confirms with Codex request_user_input before beginning Phase 1 proper: "Releasing v1.1.0. Is this correct?"
4. Proceeds as if `$ccgs-team-release v1.1.0` was the input

**Expected behavior (variant B):**
1. Phase 1: No argument provided; reads available state files — no version discoverable
2. Uses Codex request_user_input: "What version number should be released? (e.g., v1.0.0)"
3. Waits for user input before proceeding

**Assertions:**
- [ ] Skill does NOT default to a hardcoded version string when no argument is provided
- [ ] Skill reads `production/session-state/active.md` and milestone files before asking (variant A)
- [ ] Inferred version is confirmed with the user via Codex request_user_input before proceeding (variant A)
- [ ] When no version is discoverable, Codex request_user_input is used — skill does not guess (variant B)
- [ ] Skill does NOT error out when milestone files are absent — it falls back to asking (variant B)

---

## Protocol Compliance

- [ ] `Codex request_user_input` used at each phase transition gate (post-Phase 1, post-Phase 2, post-Phase 3/4 if issues, post-Phase 5 go/no-go)
- [ ] Phase 3 agents are always issued as parallel Codex subagent calls — ccgs-qa-lead and ccgs-devops-engineer are never sequential
- [ ] ccgs-security-engineer is conditionally spawned based on game features — never silently skipped when features are present
- [ ] File Write Protocol: orchestrator never calls apply_patch/edit directly — all writes are delegated to sub-agents or sub-skills
- [ ] Phase 6 Deployment is strictly conditional on a GO verdict from Phase 5 — never auto-triggered
- [ ] Error recovery: any BLOCKED agent is surfaced immediately before continuing to dependent phases
- [ ] Partial reports are always produced if any phase fails or the pipeline is halted (Case 2)
- [ ] Verdict: COMPLETE only when deployment completes; BLOCKED when go/no-go is NO or a hard blocker is unresolved
- [ ] Next steps always include 48-hour post-release monitoring, `$ccgs-retrospective` recommendation, and `production/stage.txt` update to `Live`

---

## Coverage Notes

- Phase 7 post-release actions (release report, milestone tracking, community publishing, dashboard monitoring) are validated implicitly by Case 1. No separate edge case is required as Phase 7 is non-gated and does not have a blocking failure mode.
- The "ccgs-devops-engineer build fails" path is not separately tested — it would surface as a BLOCKED result in Phase 3 and follow the standard error recovery protocol (surface → assess → Codex request_user_input options). This is validated structurally by the Static Assertions error recovery check.
- The parallel Phase 4 path (localization + performance + analytics simultaneously with Phase 3) is a documented option in the skill ("can run in parallel with Phase 3 if resources available"). Case 4 tests Phase 4 as a sequential gate; the parallel variant is left to the skill's implementation judgment.
- The `ccgs-network-programmer` sign-off path for multiplayer is validated as part of Case 3 rather than a separate case, as it follows the same parallel-spawn pattern as ccgs-security-engineer.
- The "override NO-GO with documented rationale" path in Case 2 is referenced but not exhaustively tested — it is an escape hatch that the skill must support, and its existence is validated by the Codex request_user_input options assertion in Case 2.
