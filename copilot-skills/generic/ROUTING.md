# ROUTING.md — Skill Routing Reference

> **When to read this file**: When routing a user request to the correct skill.
> During skill execution, this file is NOT needed — focus on the SKILL.md.
> Reference: `AGENTS.md` for execution protocols.

## Work-Type Router

**FIRST ACTION on every request**: Classify the work type using this table. If ambiguous, STOP and ask.

| # | Work Type | Detection Signal | Route |
|---|---|---|---|
| 0 | **Unsure / help** | "What should I do?", "help", ambiguous request | Route: workflow-help (triages and routes to correct skill) |
| 1 | **New feature** | "Add X endpoint", "New config type", "New validation rule". Detection: No existing controller/service for this capability | Full workflow: Phase 1 → 2? → 3 → 4 → 5 → 6 |
| 2 | **Enhancement** | "Add field to existing DTO", "Extend validation to support Y". Detection: Existing controller/service exists, adding behavior | Phase 1 → 3 → 4 → 5 → 6 (skip lifecycle unless cross-cutting) |
| 3 | **Bug fix** | "Fix X", "X is broken", "Not working for site" | Fast-track: bug-tracer → Phase 4 → Phase 5 |
| 4 | **Config/YAML only** | "Enable X for site", "Update Redis config", no Java logic | Fast-track: Phase 4 → Phase 5 |
| 5 | **Refactoring** | "Rename X", "Extract X", "Reorganize X" | Fast-track: blast-radius → safe-refactor → Phase 5 |
| 6 | **Dependency upgrade** | "Update Spring Boot", "Upgrade library" | Fast-track: blast-radius → Phase 4 → Phase 5 |
| 7 | **Hotfix emergency** | "Production down", "Urgent fix needed" | Streamlined: fix → test → COMMIT YES → PUSH YES → PR → post-mortem later |
| 8 | **Understand codebase** | "How does X work?", "I'm new", "Explain architecture" | Standalone: onboarding → code-explorer |
| 9 | **Understand then build** | "I want to understand first, then build a feature" | Chain: onboarding → architecture-diagrammer → code-explorer → spec-writer (full workflow from Phase 1) |
| 10 | **Rough idea, no spec** | "I'm thinking about...", "what if we...", rough verbal idea | Chain: idea-to-spec → spec-writer (full workflow from Phase 1) |
| 11 | **Architectural decision** | "Should we X or Y?", "tradeoffs", "post-mortem" | Standalone: party-mode |
| 12 | **Architecture sync** | "Architecture docs are stale", "update diagrams", "class not in architecture", "refresh docs" | Standalone: architecture-diagrammer (refresh mode) |
| 13 | **Test API** | "Test the API", "fire curl", "run test cases", "check payloads", "check drift", "generate payload" | Standalone: api-tester [PROJECT-SPECIFIC — only available if project has api-tester overlay] |
| 14 | **Generate/update docs** | "generate docs", "update feature docs", "create testing.md", "refresh docs for feature" | Direct: feature-docs (auto-detects phase from existing artifacts) |
| 15 | **Generate/update Postman** | "update postman", "generate postman collection", "create collection for feature" | Direct: postman-collection (manual trigger path) |
| 16 | **Resume / continue** | "continue", "resume", "where were we?", "what's next?", "pick up from last time" | Resume protocol (see §Resume Protocol below) |
| 17 | **Check readiness** | "is this ready for PR?", "check my feature", "am I done?", "what's left?" | pr-preparation (dry-run: reports status without committing) |
| 18 | **Show available skills** | "what skills are available?", "show all skills", "what can you do?" | workflow-help (displays Quick Reference table) |
| 19 | **Cross-service flow** | "how do services communicate?", "map the flow between X and Y", "lifecycle diagram" | If `spec.md` APPROVED with `Cross-cutting: Yes` → lifecycle-flow. Otherwise → code-explorer or architecture-diagrammer (no spec prerequisite needed for exploratory questions) |
| 20 | **Check setup / tools** | "check my setup", "is everything installed?", "verify prerequisites" | Standalone: setup-check |
| 21 | **Run API tests** | "run api tests", "test with newman", "run postman", "verify api", "use newman-tester skill", "test the collection" | Standalone: newman-tester |

**For every work type**: Ask scope/impact questions FIRST. Verify blast radius where applicable. Never jump directly to implementation.

**Smart routing (natural language)**: The router must match USER INTENT, not exact phrases. If a user's message doesn't match any detection signal literally but ONE work type is clearly supported by context, route to that type. If TWO OR MORE work types are plausible, STOP and ask — never silently infer. Examples:
- "I just finished coding" → #16 Resume (detect: plan.md has all `[x]` → suggest pr-preparation) — ONE clear match
- "Add logging to the rate limiter" → #2 Enhancement (Java code change) NOT #4 Config — ONE clear match
- "This endpoint is slow" → #3 Bug fix (performance bug) — ONE clear match
- "What skills exist?" → #18 Show skills — ONE clear match
- "Let's discuss before we build" → #11 Party-mode → then #1 New feature — ONE clear match
- "Make this better" → AMBIGUOUS (could be #2 Enhancement, #5 Refactoring, or #3 Bug fix) → STOP and ask

---

## Phase Definitions — Full Workflow

### Phase 1: SPECIFICATION

| Field | Value |
|---|---|
| **Skill** | `spec-writer` |
| **Entry** | Feature description + ticket ID |
| **Exit** | `spec.md` with `Status: APPROVED` |
| **Post-gate** | `feature-docs phase:post-spec` → README.md, design.md, architecture-diagrams.md, flow.md |
| **Handoff** | `Cross-cutting: Yes` → Phase 2. Otherwise → Phase 3. |

### Phase 2: LIFECYCLE FLOW (optional)

| Field | Value |
|---|---|
| **Skill** | `lifecycle-flow` |
| **Entry** | `spec.md` APPROVED + `Cross-cutting: Yes` |
| **Exit** | `lifecycle.md` + `APPROVE-LIFECYCLE` token |
| **Skip** | Routine single-module changes go directly to Phase 3 |

### Phase 3: IMPLEMENTATION PLAN

| Field | Value |
|---|---|
| **Skill** | `impl-planner` |
| **Entry** | `spec.md` APPROVED (+ `lifecycle.md` APPROVED if cross-cutting) |
| **Exit** | `plan.md` with `Status: APPROVED` |
| **Post-gate** | `feature-docs phase:post-plan` → design.md, flow.md updated |

### Phase 4: IMPLEMENT + TEST

| Field | Value |
|---|---|
| **Skill** | `implement-and-test` |
| **Entry** | `plan.md` APPROVED (or fast-track direct entry) |
| **Exit** | All tasks `[x]` + build verifies + no unresolved stops |
| **Post-gate** | `feature-docs phase:post-impl` → testing.md, integration-guide.md; `postman-collection` → collection updated |

### Phase 5: PR PREPARATION

| Field | Value |
|---|---|
| **Skill** | `pr-preparation` |
| **Entry** | Phase 4 done + docs fresh + collection fresh |
| **Exit** | `COMMIT YES` → commit. `PUSH YES` → push. PR created on GitHub. |

### Phase 6: CODE REVIEW

| Field | Value |
|---|---|
| **Skill** | `code-reviewer` |
| **Entry** | PR exists on GitHub |
| **Discovery** | `gh pr list --state open` if PR number unknown. Comma-separated → parallel review. |
| **Exit** | Verdict delivered + posted to GitHub (on YES). After Phase 5 PR creation, always say: "PR #N created. Say `review PR #N` when ready." |

### Approval Protocol

`DRAFT` + `APPROVE` → `APPROVED` (next phase unlocked). `DRAFT` + `REVISE: [feedback]` → AI updates, stays `DRAFT`.
Lifecycle: `APPROVE-LIFECYCLE` → Phase 3 unlocked. `REVISE-LIFECYCLE: [feedback]` → AI updates.

---

## Fast-Track Path Definitions

### Bug Fix

```
Route: bug-tracer → implement-and-test → pr-preparation
Gates: Tests pass. Blast-radius reviewed.
```

### Config / YAML Only

```
Route: implement-and-test (config-only entry) → pr-preparation
Gates: Build passes. All profile files updated consistently.
Note: If Java logic is involved, reclassify as Enhancement (#2).
```

### Refactoring

```
Route: blast-radius → safe-refactor → pr-preparation
Gates: Tests pass after each file changed. Zero behavior change.
```

### Dependency Upgrade

```
Route: blast-radius → implement-and-test → pr-preparation
Gates: Build passes. No new deprecation warnings.
```

### Enhancement (partial workflow)

```
Entry: Existing feature extended. Route: spec-writer (delta only) → impl-planner → implement-and-test → pr-preparation → code-review
Gates: Same as full workflow. Spec MUST define OUT OF SCOPE boundary.
```

### Understand Then Build

```
Route: onboarding → code-explorer → spec-writer (full workflow from Phase 1)
Gate:  Developer says "I'm ready to build" before spec-writer starts.
```

### Idea to Spec

```
Route: idea-to-spec → spec-writer → full workflow from Phase 1
Gates: brief.md exists before spec-writer. spec.md APPROVED before planning.
```

### Hotfix Emergency

```
Route: fix → test → COMMIT YES → PUSH YES → PR created immediately
Note:  🔒 COMMIT YES and PUSH YES are REQUIRED even on hotfix. NEVER push to protected branches.
       After stabilization: create features/<ticket-id>/ with retrospective spec.
```

### API Testing (standalone) [PROJECT-SPECIFIC]

```
Route: api-tester → pre-flight → drift check → fire curls → verify delivery → report
Gates: cred.md populated. Server reachable. Layer 1 drift resolved before firing.
```

---

## Skill Registry

### Generic Skills (18) — Available to All Projects

#### Layer 1 — Java/Spring Boot Skills (Portable)

| Skill | Phase | Sub-Agents Triggered | Auto-triggered by | Does NOT |
|---|---|---|---|---|
| `implement-and-test` | 4 | blast-radius (Step 8), feature-docs (post-impl), postman-collection (post-impl) | — (manual) | Commit, skip tests |
| `blast-radius` | Sub-agent | — (leaf) | implement-and-test, code-reviewer, safe-refactor, impl-planner, pr-preparation, bug-tracer, postman-collection | Modify code |
| `code-explorer` | Sub-agent | — (leaf) | onboarding, architecture-diagrammer, bug-tracer, idea-to-spec, spec-writer, lifecycle-flow, feature-docs | Modify code |
| `onboarding` | Standalone | code-explorer (Steps 2.5/3.5/5/6), architecture-diagrammer (Step 2, Step 7.2) | — (manual) | Write application code; generates/updates .github/kt/ only on explicit YES; smart update: SKIP/UPDATE/REWRITE per file age |
| `architecture-diagrammer` | Sub-agent | code-explorer (Step 2) | onboarding, spec-writer, lifecycle-flow, pr-preparation, feature-docs | Modify code |
| `workflow-help` | Standalone | — (router only, max 2 clarifying questions) | — (default fallback for ambiguous requests) | Execute skills; only routes |
| `spec-writer` | 1 | code-explorer (Step 3), architecture-diagrammer (Step 4 — if cross-cutting), feature-docs (post-spec — after APPROVED) | — (manual) | Implement features; creates spec.md only |
| `impl-planner` | 3 | blast-radius (Step 3 — for EVERY change point), feature-docs (post-plan — after APPROVED) | — (manual) | Write code; creates plan.md only |
| `pr-preparation` | 5 | blast-radius (Step 2), architecture-diagrammer (Step 6 — topology check), feature-docs (staleness gate), postman-collection (staleness gate) | — (manual) | Merge PRs; creates commit + branch + PR draft |
| `code-reviewer` | 6 | blast-radius (Step 2 — on all changed classes) | — (manual or PR event) | Approve without analysis; always gives verdict |
| `bug-tracer` | Fast-track | code-explorer (Step 2), blast-radius (Step 7) | — (manual) | Fix bugs; traces root cause only |
| `safe-refactor` | Fast-track | blast-radius (Phase 1 — pre-check) | — (manual) | Modify behavior; structural changes only |
| `idea-to-spec` | Pre-Phase 1 | code-explorer (Step 3 — pattern check) | — (manual) | Write specs; creates brief.md only |
| `party-mode` | Standalone | — (discussion only) | — (manual) | Modify files; discussion and analysis only |
| `setup-check` | Standalone | — (leaf) | — (manual or first invocation) | Install without permission |
| `feature-docs` | Sub-agent | code-explorer, architecture-diagrammer | spec-writer (post-APPROVED), impl-planner (post-APPROVED), implement-and-test (post-completion, re-invocation), pr-preparation (staleness gate) | Modify application code; generates/updates feature docs only |
| `postman-collection` | Sub-agent | blast-radius | implement-and-test (post-completion, re-invocation), pr-preparation (staleness gate) | Modify application code; generates/updates Postman collections only |
| `newman-tester` | Standalone/Sub-agent | postman-collection | implement-and-test (Step 11 — post-postman, on YES), code-reviewer (Step 13 — post-fixes, on YES) | Modify application code; runs Newman, diagnoses failures with full analysis, fixes with explicit approval only, updates e2e-test-report.md |

#### Layer 2 — Repo/Domain Skills [PROJECT-SPECIFIC]

> Some Layer 2 skills exist in `generic/.github/skills/` as **reusable templates** (marked `[PROJECT-SPECIFIC — TEMPLATE]` in their header). These provide workflow structure that projects customize via overlays. Fully project-specific skills live only in `projects/<name>/.github/skills/`.

| Skill | Phase | Sub-Agents Triggered | Auto-triggered by | Location | Does NOT |
|---|---|---|---|---|---|
| `lifecycle-flow` | 2 | code-explorer, architecture-diagrammer | spec-writer (when Cross-cutting: Yes) | generic/ (template) | Implement features; maps cross-service flows only |
| `api-tester` | Standalone | — (self-contained) | — (manual) | projects/ only | Modify application code; fires curls, detects payload drift, generates payload scaffolds, runs P0 CI |

### Quick Reference: Which Skill Do I Use?

| I want to... | Use this | Also triggered by... |
|---|---|---|
| Build a new feature | `"use the spec-writer skill for COM-XXX"` | "add X endpoint", "new feature" |
| Crystallize a rough idea | `"use the idea-to-spec skill — [idea]"` | "I'm thinking about...", "what if we..." |
| Extend an existing feature | `"use the spec-writer skill for COM-XXX"` (enhancement path) | "add field to X", "extend X to support Y" |
| Fix a bug | `"use the bug-tracer skill — [symptom]"` | "X is broken", "fix X", "not working" |
| Change config/YAML only | `"use the implement-and-test skill"` | "enable X for site", "update config" |
| Understand unfamiliar code | `"use the code-explorer skill"` | "how does X work?", "explain X" |
| Know what breaks if I change X | `"use the blast-radius skill on [ClassName]"` | "impact of changing X" |
| Rename/reorganize code | `"use the safe-refactor skill — [type] [target]"` | "rename X", "extract X", "move X" |
| Review a PR | `"use the code-reviewer skill — review PR #N"` | "review my PR", "give me open PRs" |
| Onboard to the codebase | `"use the onboarding skill"` | "I'm new", "explain architecture" |
| Get help / unsure what to do | `"help"` or `"what should I do next?"` | "what skills exist?", "show me skills" |
| Generate architecture diagram | `"use the architecture-diagrammer skill"` | "show architecture", "update diagrams" |
| Map cross-service flows | `"use the lifecycle-flow skill for COM-XXX"` | "how do services communicate?" |
| Discuss architectural tradeoffs | `"use the party-mode skill — [question]"` | "should we X or Y?", "tradeoffs" |
| Create implementation plan | `"use the impl-planner skill for COM-XXX"` | "plan the implementation" |
| Prepare a PR | `"use the pr-preparation skill"` | "I'm done coding", "ready for PR" |
| Update stale architecture docs | `"refresh architecture docs"` | "docs are stale" |
| Test the API | `"use the api-tester skill"` | "fire curls", "check drift", "test endpoint" |
| Check my setup | `"check my setup"` | "is everything installed?" |
| Generate/update feature docs | `"generate feature docs"` or `"update docs"` | Auto after spec/plan/impl approval |
| Generate/update Postman collection | `"update postman collection"` | Auto after implementation |
| Continue where I left off | `"continue"` or `"resume"` or `"what's next?"` | "where were we?", "pick up" |
| Check if feature is ready | `"is this ready for PR?"` or `"what's left?"` | "am I done?", "check readiness" |
| Run API tests with Newman | `"use the newman-tester skill"` | "run newman", "test postman", "verify api", "run api tests", "test the collection" |

> **Note**: Users do NOT need to remember exact skill names. Any natural language phrasing that matches the "Also triggered by" column will auto-route to the correct skill via the Work-Type Router.

---
