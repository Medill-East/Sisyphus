# Skill Test Spec: $ccgs-team-level

## Skill Summary

Orchestrates the full level design team for a single level or area. Coordinates
ccgs-narrative-director, ccgs-world-builder, ccgs-level-designer, ccgs-systems-designer, ccgs-art-director,
ccgs-accessibility-specialist, and ccgs-qa-tester through five sequential steps with one
parallel phase (Step 4). Compiles all team outputs into a single level design
document saved to `design/levels/[level-name].md`. Uses `Codex request_user_input` at each
step transition. Delegates all file writes to sub-agents. Produces a summary report
with verdict COMPLETE / BLOCKED and handoffs to `$ccgs-design-review`, `$ccgs-dev-story`,
`$ccgs-qa-plan`.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase/step headings (Step 1 through Step 5 are all present)
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" or "File Write Protocol" — writes delegated to sub-agents, orchestrator does not write files directly
- [ ] Has a next-step handoff at the end (references `$ccgs-design-review`, `$ccgs-dev-story`, `$ccgs-qa-plan`)
- [ ] Error Recovery Protocol section is present with all four recovery steps
- [ ] Uses `Codex request_user_input` at step transitions for user approval before proceeding
- [ ] Step 4 is explicitly marked as parallel (ccgs-art-director and ccgs-accessibility-specialist run simultaneously)
- [ ] Context gathering reads: `design/gdd/game-concept.md`, `design/gdd/game-pillars.md`, `design/levels/`, `design/narrative/`, and relevant world-building docs
- [ ] Team Composition lists all seven roles (ccgs-narrative-director, ccgs-world-builder, ccgs-level-designer, ccgs-systems-designer, ccgs-art-director, ccgs-accessibility-specialist, ccgs-qa-tester)
- [ ] ccgs-accessibility-specialist output includes severity ratings (BLOCKING / RECOMMENDED / NICE TO HAVE)
- [ ] Final level design document saved to `design/levels/[level-name].md`

---

## Test Cases

### Case 1: Happy Path — All team members produce outputs, document compiled and saved

**Fixture:**
- `design/gdd/game-concept.md` exists and is populated
- `design/gdd/game-pillars.md` exists
- `design/levels/` directory exists (may contain other level docs)
- `design/narrative/` directory exists with relevant narrative docs

**Input:** `$ccgs-team-level forest dungeon`

**Expected behavior:**
1. Context gathering — orchestrator reads game-concept.md, game-pillars.md, existing level docs in `design/levels/`, narrative docs in `design/narrative/`, and world-building docs for the forest region
2. Step 1 — ccgs-narrative-director spawned: defines narrative purpose, key characters, dialogue triggers, emotional arc; ccgs-world-builder spawned: provides lore context, environmental storytelling opportunities, world rules; `Codex request_user_input` confirms Step 1 outputs before Step 2
3. Step 2 — ccgs-level-designer spawned: designs spatial layout (critical path, optional paths, secrets), pacing curve, encounters, puzzles, entry/exit points and connections to adjacent areas; `Codex request_user_input` confirms layout before Step 3
4. Step 3 — ccgs-systems-designer spawned: specifies enemy compositions, loot tables, difficulty balance, area-specific mechanics, resource distribution; `Codex request_user_input` confirms systems before Step 4
5. Step 4 — ccgs-art-director and ccgs-accessibility-specialist spawned in parallel; ccgs-art-director: visual theme, color palette, lighting, asset list, VFX needs; ccgs-accessibility-specialist: navigation clarity, colorblind safety, cognitive load check — each concern rated BLOCKING / RECOMMENDED / NICE TO HAVE; `Codex request_user_input` presents both outputs before Step 5
6. Step 5 — ccgs-qa-tester spawned: test cases for critical path, boundary/edge cases (sequence breaks, softlocks), playtest checklist, acceptance criteria
7. Orchestrator compiles all team outputs into level design document format; sub-agent asked "May I write to `design/levels/forest-dungeon.md`?"; file saved
8. Summary report: area overview, encounter count, estimated asset list, narrative beats, cross-team dependencies, verdict: COMPLETE
9. Next steps listed: `$ccgs-design-review design/levels/forest-dungeon.md`, `$ccgs-dev-story`, `$ccgs-qa-plan`

**Assertions:**
- [ ] All five sources read during context gathering before any agent is spawned
- [ ] ccgs-narrative-director and ccgs-world-builder both spawned in Step 1 (may be sequential or parallel — both must complete before Step 2)
- [ ] `Codex request_user_input` called at each step gate (minimum: after Step 1, Step 2, Step 3, Step 4)
- [ ] Step 4 agents (ccgs-art-director, ccgs-accessibility-specialist) launched simultaneously
- [ ] All file writes delegated to sub-agents — orchestrator does not write directly
- [ ] Level doc saved to `design/levels/forest-dungeon.md` (slugified from argument)
- [ ] Verdict COMPLETE in final summary report
- [ ] Next steps include `$ccgs-design-review`, `$ccgs-dev-story`, `$ccgs-qa-plan`
- [ ] Summary report includes: area overview, encounter count, estimated asset list, narrative beats

---

### Case 2: Blocked Agent (ccgs-world-builder) — Partial report produced with gap noted

**Fixture:**
- `design/gdd/game-concept.md` exists
- World-building docs for the forest region do NOT exist
- ccgs-world-builder agent returns BLOCKED: "No world-building docs found for the forest region — cannot provide lore context"

**Input:** `$ccgs-team-level forest dungeon`

**Expected behavior:**
1. Context gathering completes; missing world-building docs noted
2. Step 1 — ccgs-narrative-director completes successfully; ccgs-world-builder spawned and returns BLOCKED
3. Error Recovery Protocol triggered: "ccgs-world-builder: BLOCKED — no world-building docs for forest region"
4. `Codex request_user_input` presented with options:
   - (a) Skip ccgs-world-builder and note the lore gap in the level doc
   - (b) Retry with narrower scope (ccgs-world-builder focuses only on what can be inferred from game-concept.md)
   - (c) Stop here and create world-building docs first
5. If user chooses (a): pipeline continues with Steps 2–5 using ccgs-narrative-director context only; level doc compiled with a clearly marked gap section: "World-building context: NOT PROVIDED — see open dependency"
6. Final report produced: partial outputs documented, ccgs-world-builder section marked BLOCKED, overall verdict: BLOCKED

**Assertions:**
- [ ] BLOCKED surface message appears immediately when ccgs-world-builder fails — before Step 2 begins without user input
- [ ] `Codex request_user_input` offers at minimum three options (skip / retry / stop)
- [ ] Partial report produced — ccgs-narrative-director's completed work is not discarded
- [ ] Level doc (if compiled) contains an explicit gap notation for the missing world-building context
- [ ] Overall verdict is BLOCKED (not COMPLETE) when ccgs-world-builder remains unresolved
- [ ] Skill does NOT silently fabricate lore content to fill the gap

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `$ccgs-team-level` (no argument)

**Expected behavior:**
1. Skill detects no argument provided
2. Outputs usage message explaining the required argument (level name or area to design)
3. Provides example invocations: `$ccgs-team-level tutorial`, `$ccgs-team-level forest dungeon`, `$ccgs-team-level final boss arena`
4. Skill exits without reading any project files or spawning any subagents

**Assertions:**
- [ ] Skill does NOT spawn any subagents when no argument is given
- [ ] Usage message includes the argument-hint format from frontmatter
- [ ] At least one example of a valid invocation is shown
- [ ] No GDD or level files read before failing
- [ ] Verdict is NOT shown (pipeline never starts)

---

### Case 4: Accessibility Review Gate — Blocking concern surfaces before sign-off

**Fixture:**
- Steps 1–3 complete successfully
- `design/accessibility-requirements.md` committed tier: Enhanced
- ccgs-accessibility-specialist (Step 4, parallel) flags a BLOCKING concern: the critical path through the forest dungeon requires players to distinguish between two environmental hazards (toxic pools vs. shallow water) using color alone — no shape, icon, or audio cue differentiates them

**Input:** `$ccgs-team-level forest dungeon`

**Expected behavior:**
1. Steps 1–3 complete; Step 4 parallel phase begins
2. ccgs-accessibility-specialist returns: BLOCKING concern — "Critical path hazard distinction relies on color only (toxic pools vs. shallow water). Shape, icon, or audio cue required per Enhanced accessibility tier."
3. ccgs-art-director returns Step 4 output (complete)
4. Skill presents both Step 4 results via `Codex request_user_input` — BLOCKING concern highlighted prominently
5. `Codex request_user_input` offers:
   - (a) Return to ccgs-level-designer + ccgs-art-director to redesign hazard visual/audio language before Step 5
   - (b) Document as a known accessibility gap and proceed to Step 5 with the concern logged
6. Skill does NOT silently proceed past the BLOCKING concern
7. If user chooses (a): ccgs-level-designer and ccgs-art-director revision spawned; re-run Step 4 accessibility check
8. Final report includes BLOCKING concern and its resolution status regardless of user choice

**Assertions:**
- [ ] BLOCKING accessibility concern is not treated as advisory — it is surfaced as a blocker
- [ ] `Codex request_user_input` presents the specific concern text (not just "accessibility issue found")
- [ ] Step 5 (ccgs-qa-tester) does NOT begin without user acknowledging the BLOCKING concern
- [ ] Revision path offered: ccgs-level-designer + ccgs-art-director can be sent back before proceeding
- [ ] Final report includes the accessibility concern and its resolution status
- [ ] ccgs-art-director's completed output is NOT discarded when ccgs-accessibility-specialist blocks

---

### Case 5: Circular Level Reference — Adjacent area dependency flagged

**Fixture:**
- Steps 1–3 in progress
- ccgs-level-designer (Step 2) produces a layout that specifies entry/exit points connecting to "the crystal caves" (an adjacent area)
- `design/levels/crystal-caves.md` does NOT exist — the crystal caves area has not been designed yet

**Input:** `$ccgs-team-level forest dungeon`

**Expected behavior:**
1. Step 2 — ccgs-level-designer produces layout including: "West exit connects to crystal-caves entry point A"
2. Orchestrator (or ccgs-level-designer subagent) checks `design/levels/` for `crystal-caves.md`; file not found
3. Dependency gap surfaced: "Level references crystal-caves as an adjacent area but `design/levels/crystal-caves.md` does not exist"
4. `Codex request_user_input` presented with options:
   - (a) Proceed with a placeholder reference — note the dependency in the level doc as UNRESOLVED
   - (b) Pause and run `$ccgs-team-level crystal caves` first to establish that area
5. Skill does NOT invent crystal caves content to satisfy the reference
6. If user chooses (a): level doc compiled with the west exit marked "→ crystal-caves (UNRESOLVED — area not yet designed)"; flagged in the open dependencies section of the summary report
7. Final report includes open cross-level dependencies section

**Assertions:**
- [ ] Skill detects the missing adjacent area by checking `design/levels/` — does not assume it will be created later
- [ ] Skill does NOT fabricate crystal caves content (lore, layout, connections) to resolve the reference
- [ ] `Codex request_user_input` offers a "design crystal caves first" option referencing `$ccgs-team-level`
- [ ] If user proceeds with placeholder, level doc explicitly marks the west exit as UNRESOLVED
- [ ] Summary report includes an open cross-level dependencies section listing unresolved references
- [ ] Circular or forward references do not cause the skill to loop or crash

---

## Protocol Compliance

- [ ] `Codex request_user_input` used at each step transition — user approves before pipeline advances
- [ ] All file writes delegated to sub-agents via Codex subagent — orchestrator does not call Write or Edit directly
- [ ] Error Recovery Protocol followed: surface → assess → offer options → partial report
- [ ] Step 4 agents (ccgs-art-director, ccgs-accessibility-specialist) launched in parallel per skill spec
- [ ] Partial report always produced even when agents are BLOCKED
- [ ] Accessibility BLOCKING concerns surface before sign-off and require explicit user acknowledgment
- [ ] Verdict is one of COMPLETE / BLOCKED
- [ ] Next steps present at end: `$ccgs-design-review`, `$ccgs-dev-story`, `$ccgs-qa-plan`

---

## Coverage Notes

- ccgs-narrative-director and ccgs-world-builder in Step 1 may be sequential or parallel — the skill spec
  spawns both but does not mandate simultaneous launch; coverage of parallel Step 1 would require
  an explicit timing assertion fixture.
- The "Retry with narrower scope" option in the blocked ccgs-world-builder case (Case 2) — the
  retry behavior itself is not tested in depth; its full path is analogous to the blocked agent
  pattern covered in Case 2 and in other team-* specs.
- ccgs-systems-designer (Step 3) block scenarios are not separately tested; the same Error Recovery
  Protocol applies and the pattern is validated by Case 2.
- Step 4 parallel ordering (ccgs-art-director completing before or after ccgs-accessibility-specialist)
  does not affect outcomes — both must return before Step 5 regardless of order.
- The level doc slug convention (argument → filename) is implicitly tested by Case 1
  (`forest dungeon` → `forest-dungeon.md`); multi-word slugification edge cases (special
  characters, very long names) are not covered.
