# Sub-Agent Trigger Contracts

> **[REUSABLE]** — These contracts define how skills auto-invoke other skills as sub-agents.
> Each contract specifies: who triggers it, what input it needs, what output it must return,
> and whether the parent skill blocks waiting for the result.

## Contract 1: blast-radius (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | `impl-planner`, `pr-preparation`, `code-reviewer`, `safe-refactor`, `bug-tracer`, `implement-and-test`, `postman-collection` |
| **Input required** | Target class/method/field name (string), OR a group of related targets (e.g., classes in same package) + change type: rename / remove / modify / add |
| **Output returned** | Blast radius report: risk level (LOW/MEDIUM/HIGH/CRITICAL) + direct callers table + DI wiring + limitations |
| **Blocking** | Yes — parent skill waits for the report before continuing |
| **Idempotent** | Yes — running twice on the same target produces the same report |

**Trigger protocol:**
```
Parent skill identifies a class/method that will be changed
  → Parent calls: "Run blast-radius analysis on [ClassName.methodName]"
     (or for impl-planner grouped mode: "Run blast-radius on [Group: Class1, Class2]")
  → blast-radius runs Steps 1-4 from its SKILL.md
  → Returns structured report (risk level + callers table)
  → Parent skill incorporates risk level into its own output
```

**When parent should trigger:**
- `impl-planner`: On EVERY class listed in the task breakdown
- `pr-preparation`: On ALL files in the changeset (summary mode)
- `code-reviewer`: On ALL changed classes in the PR diff
- `safe-refactor`: On the refactoring target BEFORE making changes
- `bug-tracer`: On the identified root-cause class AFTER finding the bug
- `implement-and-test`: After implementation, when any task has blast-risk MEDIUM or HIGH (Step 8)
- `postman-collection`: On each controller/endpoint class during Step 1 discovery (to find DTOs, auth filters, exception handlers)

---

## Contract 2: code-explorer (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | `spec-writer`, `onboarding`, `bug-tracer`, `lifecycle-flow`, `architecture-diagrammer`, `idea-to-spec`, `feature-docs` |
| **Input required** | Class name or pattern name or flow description (string) + depth: overview / deep-dive |
| **Output returned** | Explanation of component: purpose, dependencies, callers, related classes, file paths |
| **Blocking** | Yes — parent skill waits for understanding before continuing |
| **Idempotent** | Yes — exploring the same component twice produces consistent results |

**Trigger protocol:**
```
Parent skill encounters an unfamiliar component or needs to understand existing patterns
  → Parent calls: "Explore [ClassName] — I need to understand its purpose and dependencies"
  → code-explorer runs Steps 1-6 from its SKILL.md
  → Returns explanation with file paths and line references
  → Parent skill uses this context to inform its own work
```

**When parent should trigger:**
- `spec-writer`: When verifying if a pattern exists before specifying a new one
- `onboarding`: When developer asks to deep-dive into a specific component
- `bug-tracer`: When tracing a call chain and a component's behavior is unclear
- `lifecycle-flow`: When a component's role in a cross-service flow is unclear
- `architecture-diagrammer`: When a component's purpose is unclear during diagram generation
- `idea-to-spec`: When Q2 reveals a new event type — check if similar pattern exists

---

## Contract 3: safe-refactor (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | After `blast-radius` confirms scope (developer-initiated, not auto) |
| **Input required** | Refactoring type (rename/extract/move/inline) + target + scope from blast-radius report |
| **Output returned** | Refactored code + all tests passing + coverage maintained |
| **Blocking** | Yes — sequential execution (refactor → test → next file) |
| **Idempotent** | Yes — refactoring the same target twice is a no-op if already done |

**Trigger protocol:**
```
Developer invokes blast-radius on a refactoring target
  → blast-radius returns risk report
  → Developer reviews and confirms refactoring scope
  → safe-refactor executes bottom-up: leaf → callers → entry points
  → Tests run after each file change
  → Returns: all files changed + final ./mvnw verify status
```

**Note:** safe-refactor is NOT fully automatic. It requires developer confirmation between blast-radius and execution because refactoring scope decisions are human-owned.

---

## Contract 4: architecture-diagrammer (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | `spec-writer` (for cross-cutting features), `onboarding` (for visual overview, default for Level 2+), `lifecycle-flow` (after lifecycle.md created), `pr-preparation` (topology-change refresh), `feature-docs` (architecture-diagrams.md generation) |
| **Input required** | Scope: "entire system" or "specific feature flow" + diagram type: overview / sequence / data-flow |
| **Output returned** | Mermaid diagram + component reference table |
| **Blocking** | No for onboarding (supplementary). Yes for spec-writer (proposed flow needed before approval). Yes for lifecycle-flow (component diagram needed before review). |
| **Idempotent** | Yes — regenerating a diagram overwrites the previous version |

**Trigger protocol:**
```
spec-writer: Feature is cross-cutting (§7 Cross-cutting: Yes)
  → Triggers architecture-diagrammer: "Generate proposed flow for [feature]"
  → Diagram saved to features/<ticket-id>/proposed-flow.md
  → Included in spec for developer review

onboarding: Developer asks for visual overview
  → Triggers architecture-diagrammer: "Generate system overview"
  → Diagram displayed inline or saved to `.github/kt/diagrams/`

lifecycle-flow: After lifecycle.md sequence diagram created
  → Triggers architecture-diagrammer: "Generate component interaction diagram for [feature]"
  → Component diagram embedded or referenced in lifecycle.md
```

---

## Contract 4b: lifecycle-flow (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | `spec-writer` (when `Cross-cutting: Yes` in spec) |
| **Input required** | `spec.md` with `Status: APPROVED` and `Cross-cutting: Yes` + list of involved services/components |
| **Output returned** | `features/<ticket-id>/lifecycle.md` — Mermaid sequence diagram mapping cross-service message flows |
| **Blocking** | Yes — parent waits for lifecycle.md before proceeding to impl-planner |
| **Idempotent** | Yes — regenerating overwrites existing lifecycle.md |

**Trigger protocol:**
```
spec-writer: After APPROVE, if spec contains "Cross-cutting: Yes"
  → spec-writer passes to lifecycle-flow:
    - specPath: "features/<ticket-id>/spec.md"
    - services: [list of services/components mentioned in spec]
    - entryPoints: [identified entry points per service]
  → lifecycle-flow:
    1. Triggers code-explorer to trace each service's role
    2. Maps message flows (HTTP, Kafka, async) between services
    3. Generates Mermaid sequence diagram
    4. Triggers architecture-diagrammer for topology view
  → Returns: "lifecycle.md created — N services, M message flows documented."
```

**Sub-agents used by lifecycle-flow:**
- `code-explorer` — trace component roles across services
- `architecture-diagrammer` — generate topology/deployment view after lifecycle mapped

**Failure behavior:**
- If a service's code is not accessible (different repo): mark as `📦 EXTERNAL — role inferred from spec only`
- If code-explorer cannot trace a path: mark as `⚠️ UNVERIFIED — path documented from spec, not code`
- lifecycle-flow generation failure does NOT block the creation of lifecycle.md — AI retries or asks for manual input
- However, the **approval gate** (`APPROVE-LIFECYCLE`) STILL BLOCKS Phase 3. The lifecycle.md must exist AND be approved before impl-planner can start for cross-cutting features. See `AGENTS.md` §Phase 3 entry gate.

---

## Contract 5: feature-docs (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | `spec-writer` (after Status: APPROVED), `impl-planner` (after Status: APPROVED), `implement-and-test` (after all tasks `[x]` + verify passes), `pr-preparation` (staleness gate — Step 0) |
| **Input required** | Phase identifier (`post-spec` / `post-plan` / `post-impl`) + feature directory path (`features/<ticket-id>/`) + Q&A decisions from parent skill |
| **Output returned** | Generated/updated documentation files in `features/<ticket-id>/` + verification report (post-impl) |
| **Blocking** | Phase-dependent: Non-blocking during spec/plan/impl phases (parent skill continues after triggering — docs are generated in the same run but do not gate the next workflow phase). BLOCKING at `pr-preparation` Step 0 staleness gate (PR cannot proceed if docs are missing or stale). |
| **Idempotent** | Yes — re-running any phase overwrites existing docs (safe to retry) |

**Trigger protocol:**
```
spec-writer: After developer types APPROVE and Status is set to APPROVED
  → Passes to feature-docs:
    - phase: "post-spec"
    - featureDir: "features/<ticket-id>/"
    - specPath: "features/<ticket-id>/spec.md"
    - questionsAsked: [{id, topic, question, answer, skill, timestamp}]
    - briefPath: "features/<ticket-id>/brief.md" (if exists)
  → feature-docs generates: README.md, design.md (v1), architecture-diagrams.md, flow.md (v1)
  → Reports back: "4 feature docs created in features/<ticket-id>/"

impl-planner: After developer types APPROVE and Status is set to APPROVED
  → Passes to feature-docs:
    - phase: "post-plan"
    - featureDir: "features/<ticket-id>/"
    - planPath: "features/<ticket-id>/plan.md"
    - blastRadiusResults: [{target, riskTier, callers, diWiring, keyRisk}]
    - questionsAsked: [{id, topic, question, answer, skill, timestamp}]
  → feature-docs updates: design.md (adds blast-radius + phases), flow.md (adds planned paths)
  → Reports back: "Feature docs updated (post-plan). design.md + flow.md enriched."

implement-and-test: After ALL plan tasks are [x] AND ./mvnw verify passes
  → Passes to feature-docs:
    - phase: "post-impl"
    - featureDir: "features/<ticket-id>/"
    - completedTasks: [list of completed task descriptions]
    - testClassesCreated: [list of test file paths]
  → feature-docs generates: testing.md, integration-guide.md
  → feature-docs updates: flow.md (code-verified), architecture-diagrams.md (grep-verified), design.md (status)
  → feature-docs runs VERIFICATION PASS: grep-verifies every class/method reference in ALL docs
  → Reports back: "Feature docs finalized. N references verified, M warnings."
```

**Non-skippable enforcement:**
```
This contract is MANDATORY. The following rules ensure feature-docs is never skipped:

1. spec-writer MUST trigger feature-docs after APPROVE. 
   If spec-writer completes without triggering → protocol violation.

2. impl-planner MUST trigger feature-docs after APPROVE.
   If impl-planner completes without triggering → protocol violation.

3. implement-and-test MUST trigger feature-docs after all tasks done.
   If implement-and-test completes without triggering → protocol violation.
   🔒 ENFORCEMENT: implement-and-test Step 11 Phase Gate has a mandatory
   pre-condition checklist that BLOCKS presentation until Step 9 (feature-docs)
   is confirmed complete. The AI CANNOT present the completion gate without
   printing the pre-condition check showing feature-docs status.

4. pr-preparation MUST verify feature docs exist before allowing commit:
   - Check: features/<ticket-id>/README.md exists
   - Check: features/<ticket-id>/design.md exists
   - Check: features/<ticket-id>/testing.md exists (for full workflow, not fast-track)
   - Check: features/<ticket-id>/integration-guide.md exists (for full workflow)
   If missing → HARD STOP: "Feature docs incomplete. Run feature-docs first or SKIP: [reason]."
   This is a BLOCKING check — pr-preparation cannot proceed without resolution.

DRIFT DETECTION: If the AI presents implement-and-test completion (Step 11)
without first showing the printed pre-condition checklist confirming Steps 9-10,
the developer SHOULD reject and say: "Gates didn't fire — run feature-docs."
This visible checklist is the developer's guarantee that gates were executed.
```

**Q&A passthrough protocol:**
```
Every parent skill that asks clarifying questions MUST pass them to feature-docs:

Format: questionsAsked = [
  {
    id: "Q1",
    topic: "Time window granularity",
    question: "Per-minute, per-hour, or configurable?",
    options: ["(a) Per-minute fixed", "(b) Per-hour fixed", "(c) Configurable per rule"],
    answer: "(c) Per-minute but configurable per rule",
    skill: "spec-writer",
    timestamp: "2026-06-08T14:30:00"
  },
  ...
]

feature-docs appends these to design.md §All Questions — Full Record.
Questions from different skills are numbered sequentially (Q1-Q5 from idea-to-spec,
Q6-Q10 from spec-writer, Q11-Q15 from party-mode, etc.)
```

**Post-implementation verification protocol:**
```
At post-impl phase, feature-docs MUST:
1. Read ALL generated docs in features/<ticket-id>/
2. Extract every class name, method name, file path reference
3. grep-verify each against src/main/java/ (or equivalent source root)
4. For EACH reference:
   - Found → mark ✅ VERIFIED
   - Not found → mark ❌ NOT FOUND — verify manually
5. Report summary: "Verified N references. M passed. K failed."
6. If K > 0: list all failed references for developer review
```

## Contract 6: postman-collection (Sub-Agent)

| Field | Value |
|---|---|
| **Triggered by** | `implement-and-test` (post-impl), `pr-preparation` (staleness gate), manual invocation |
| **Input required** | Feature ticket ID + endpoint list (from grep) + spec acceptance criteria + existing collection conventions |
| **Output returned** | Collection JSON file path + environment updates + coverage summary |
| **Blocking** | Non-blocking at `implement-and-test` (code tasks complete regardless). BLOCKING at `pr-preparation` Step 0 staleness gate (PR cannot proceed without fresh collection). |
| **Idempotent** | Yes — regenerating produces equivalent collection (deterministic request ordering) |

**Trigger protocol:**
```
implement-and-test completes all tasks
  → Checks: does the feature have API endpoints? (grep @RestController/@GetMapping etc.)
  → If YES: "Generating Postman collection for <feature>..."
    → postman-collection runs Steps 1-14 from its SKILL.md
    → Returns: collection file path + stats (folders, requests, coverage)
  → If NO endpoints: skip silently (not an error)
```

**When parent should trigger:**
- `implement-and-test`: After Step 8 (blast-radius) + Step 9 (feature-docs), as Step 10
- `implement-and-test` re-invocation: Step 12 — when src/ changes detected after initial generation
- `pr-preparation`: Step 0 (Artifact Freshness Gate) — when postman timestamp < latest src commit

**Non-skippable enforcement:**
- `implement-and-test` completing WITHOUT triggering postman-collection (when endpoints exist) is a protocol violation
- `pr-preparation` MUST check postman freshness before proceeding — stale collection is BLOCKING
- Exception: features with NO API endpoints — skip is valid and silent

**Convention consistency protocol:**
```
Before generating any collection, postman-collection MUST:
1. Read existing collections in postman/ folder
2. Extract patterns: variable naming, pre-request script style, test assertion format
3. Match conventions exactly — new collection must look like it was written by the same author
4. If no existing collections: use the templates as the canonical style
```

**Staleness detection protocol (used by pr-preparation):**
```
1. Find latest src/ commit: git log -1 --format=%ct -- "src/"
2. Find postman collection mtime: stat -f %m postman/<Feature>.postman_collection.json
3. If src commit > collection mtime:
   → STALE — auto-trigger postman-collection in UPDATE mode
   → Wait for completion before pr-preparation continues
4. Update mode:
   - Only regenerate requests for CHANGED endpoints
   - Keep existing test scripts for unchanged endpoints
   - Add new requests for new endpoints
   - Update assertions for modified DTOs
```

## Cross-Contract: Artifact Freshness Protocol

> This protocol is MANDATORY and enforced at two gates:
> 1. `implement-and-test` re-invocation (Step 12)
> 2. `pr-preparation` entry (Step 0)

**Rule: No stale artifacts may reach PR.**

Any code change (`src/`, `resources/`) committed AFTER feature docs or postman collection were generated makes those artifacts STALE. Stale artifacts MUST be regenerated before PR creation.

**Detection logic:**
```bash
# Latest source modification (any file under src/ or resources/)
LATEST_SRC=$(git log -1 --format=%ct -- "src/" "src/main/resources/")

# Feature docs timestamp (use oldest doc as reference)
FEATURE_DIR="features/<ticket-id>"
OLDEST_DOC=$(stat -f %m $(ls -t "$FEATURE_DIR"/*.md | tail -1) 2>/dev/null || echo 0)

# Postman collection timestamp
POSTMAN_TS=$(stat -f %m postman/<Feature>.postman_collection.json 2>/dev/null || echo 0)

# Stale check
if [ "$LATEST_SRC" -gt "$OLDEST_DOC" ]; then
  echo "STALE: feature-docs"
fi
if [ "$LATEST_SRC" -gt "$POSTMAN_TS" ]; then
  echo "STALE: postman-collection"
fi
```

**Resolution:** Re-trigger the stale skill(s) automatically. DO NOT ask the developer — this is non-negotiable. The developer sees a progress message, not a question.

**Exception paths (skip staleness check):**
- Fast-track config-only changes (no feature folder exists)
- Documentation-only changes (no src/ commits)
- `COPILOT_POSTMAN_ENABLED=0` (skip postman check, still check feature-docs)

---

## Cross-Contract: Failure Recovery Protocol

> Defines what happens when an auto-triggered sub-agent fails at any gate.

### Failure during `feature-docs` auto-trigger

| Failure type | Detection | Recovery action |
|---|---|---|
| grep can't find referenced class | Verification pass reports `❌ NOT FOUND` | Mark reference with `❌ NOT FOUND — verify manually`. Continue with remaining docs. Report count to parent. Parent skill does NOT stop. |
| Template section completely empty (no data to populate) | Generated section has only headings, no content | Write `> N/A — this feature does not use [component]. Section intentionally empty.` Continue. |
| `code-explorer` sub-agent fails | code-explorer returns error or times out | Skip code-exploration findings. Mark section: `> ⚠️ Code exploration unavailable — populate manually.` Continue with remaining steps. |
| `architecture-diagrammer` sub-agent fails | architecture-diagrammer returns error | Generate placeholder: `> ⚠️ Diagram generation failed — add manually after debugging.` Continue. |
| File write permission error | OS-level write failure | HARD STOP. Report: "Cannot write to features/<ticket-id>/. Check permissions." Return control to parent. |

**Key rule:** feature-docs failure does NOT block the parent workflow. Parent continues. Failures are reported as warnings, and `pr-preparation` Step 0 will catch any missing/incomplete docs.

### Failure during `postman-collection` auto-trigger

| Failure type | Detection | Recovery action |
|---|---|---|
| No endpoints found (false positive trigger) | grep returns 0 matches for `@RestController` etc. | Skip with visible message: "ℹ️ No API surface detected — postman-collection skipped." |
| DTO class not found for request body | grep can't find DTO referenced in controller | HARD STOP at that request. Ask developer: "What is the request body format for endpoint X?" After answer, continue generation. |
| Existing collection has conflicting format | Parse error or incompatible structure | Keep separate. Don't attempt merge. Report: "Main collection format incompatible — generated standalone file." |
| Environment file write conflict | File locked or git-tracked | Create as `postman/<Feature>.postman_environment.json.new`. Report: "Env file conflict — saved as .new. Merge manually." |
| JSON generation produces invalid output | JSON.parse fails on generated content | Retry once with simplified structure. If still invalid, HARD STOP. Report: "Collection JSON invalid. Debug required." |
| More than 100 endpoints | Discovery finds massive API surface | Split into domain-area sub-collections automatically. Report: "Large API surface — split into N sub-collections." |

**Key rule:** postman-collection is NON-BLOCKING when triggered from `implement-and-test` — code tasks complete regardless. If it HARD STOPs, report the issue but mark only the Postman artifact incomplete. Postman IS BLOCKING at `pr-preparation` Step 0 staleness gate — PR cannot proceed without a fresh collection.

### Failure during `blast-radius` auto-trigger

| Failure type | Detection | Recovery action |
|---|---|---|
| Target class/method not found | grep returns 0 matches | Report: "blast-radius could not locate [target]. Possible causes: typo, dynamic dispatch, or unused code." Ask developer to confirm target name or skip. |
| Timeout / context window exceeded | Sub-agent does not complete | Retry once. If still fails, generate minimal risk table from available grep results. Mark: `⚠️ Blast-radius incomplete — manual review recommended.` |
| Contradictory callers found | Two code paths suggest opposite behavior | Report both. Do NOT silently pick one. Present: "Found conflicting call paths. Which is current?" Wait for developer. |
| Empty result (no callers at all) | grep finds definition but zero callers | Report: "No callers found. Possible: unused code, reflection-based injection, or dynamically dispatched." Assign LOW risk but flag for developer awareness. |

**Key rule:** blast-radius failure BLOCKS the parent skill (impl-planner, pr-preparation, safe-refactor). After 1 retry + fallback to manual risk table, if still unresolved, HARD STOP the parent and ask developer how to proceed: `[Skip risk assessment] [Provide manual callers] [Abort]`.

### Retry policy (all sub-agents)

```
Max retries per step: 1
Retry triggers: transient errors (file system, timeout, grep returning empty due to build not complete)
Non-retriable: logic errors, missing references, permission errors
After max retries exhausted: mark artifact as INCOMPLETE, report to parent, continue workflow
```

---

## Contract 7: setup-check (Pre-Flight)

| Field | Value |
|---|---|
| **Triggered by** | Any skill (first invocation per session) |
| **Input required** | None — auto-detects project stack from cwd |
| **Output returned** | Pass/fail status per tool (silent on auto-pass; full report on manual invoke or failure) |
| **Blocking** | Conditionally — blocks only when mandatory tools are missing AND user says NO |
| **Idempotent** | Yes — re-running produces same check results |

**Trigger protocol:**
```
First skill invocation in a session
  → AI checks: has setup-check run this session? (track in session state)
  → If not run yet:
    → Run setup-check silently (Steps 1-2 from SKILL.md)
    → If ALL mandatory checks pass:
      → Proceed silently (user sees no output — pre-flight is transparent)
      → Continue to requested skill immediately
    → If ANY mandatory check fails:
      → Present failures interactively
      → Wait for YES / NO / SKIP: [reason]
      → Block requested skill until resolved
  → If already run this session: skip (no re-check)
```

**Failure modes:**
- Mandatory tool missing + user says NO → HARD STOP (report missing tools, do not proceed)
- Mandatory tool missing + user says SKIP: [reason] → proceed with documented limitations
- Graphify not installed → warn once, proceed (non-blocking)
- Network/auth error on `gh auth status` → HARD STOP (require `gh auth login`)

---

## Contract 8: api-tester (Project-Specific) [PROJECT-SPECIFIC]

| Field | Value |
|---|---|
| **Triggered by** | Manual invocation only (despite SKILL.md frontmatter) |
| **Input required** | Environment name + test scope (from cred.md) |
| **Output returned** | Versioned test report in `reports/` |
| **Blocking** | N/A — not auto-triggered by other skills |
| **Idempotent** | Partially — curl execution has external side effects; reports are versioned |

**Trigger protocol:**
```
Developer says "test the API" / "fire curls" / "use the api-tester skill"
  → Work-Type Router classifies as #13 (Test API)
  → api-tester skill executes its own steps (pre-flight, drift, fire, verify, report)
  → NOT triggered automatically by implement-and-test or any other skill
```

**Clarification on frontmatter:**
The api-tester SKILL.md declares `triggered-by: [implement-and-test]` in its frontmatter. This is an ASPIRATIONAL declaration for future automation. Currently, api-tester is MANUAL-ONLY. Auto-triggering requires the project to explicitly configure it in their workflow. Do not auto-invoke api-tester unless the project overlay explicitly enables it.

**Sub-agents used by api-tester:**
- api-tester does NOT trigger blast-radius or code-explorer during test execution
- It is self-contained: its drift detection scripts handle all validation internally

---

## Contract 9: newman-tester (Sub-Agent / Standalone)

| Field | Value |
|---|---|
| **Triggered by** | `implement-and-test` (Step 11 — after postman-collection, on developer YES), `code-reviewer` (Step 13 — after verdict + GitHub posting, when code fixes applied + developer YES) |
| **Input required** | Collection path (found by parent), list of changed endpoints (from parent context), mode: `A` (post-fix) |
| **Output returned** | Newman run results (pass/fail counts) + `e2e-test-report.md` created/updated |
| **Blocking** | Non-blocking at trigger — only executes if developer says YES. Once started, blocks parent until run completes (0 failures or developer stops). |
| **Idempotent** | Partially — Newman execution fires real HTTP requests (side effects). Reports are versioned with timestamps. |

**Trigger protocol:**
```
implement-and-test Step 11 (or code-reviewer Step 13):
  → Parent searches for *.postman_collection.json in postman/, tests/, project root
  → If found:
    → Present assessment: "I found a Postman collection at {path}.
       Your changes touched: {endpoints}.
       The collection covers {M} of them.
       Run it to verify nothing broke? [YES / NO]"
    → Wait for explicit YES. NEVER run without confirmation.
  → If YES:
    → Invoke newman-tester (Mode A — post-fix)
    → Pass: collection path + changed endpoints list
    → newman-tester runs Steps 1-7 from its SKILL.md
    → Returns: pass/fail counts + e2e-test-report.md path
    → Parent resumes after newman-tester completes (or user types STOP)
  → If NO: parent continues to its next step (Phase Gate or PR prep)
  → If no collection found: parent emits informational message, skips silently
```

**When parent should trigger:**
- `implement-and-test`: After Step 10 (postman-collection) completes — offer Newman validation as Step 11
- `code-reviewer`: After Step 12 (GitHub posting) — offer Newman validation as Step 13, ONLY if code fixes were applied in this session

**Non-skippable enforcement:**
- newman-tester is NEVER auto-run — requires explicit YES from developer every time
- Parent MUST present the assessment (collection path + changed endpoint count) before asking for YES — never ask YES/NO without context
- NEVER modify the Postman collection without: (1) showing what failed + why, (2) showing exact JSON diff, (3) receiving explicit YES. Use `--folder` exclusion instead of modifying for incompatible tests.

### Failure during `newman-tester` auto-trigger

| Failure type | Detection | Recovery action |
|---|---|---|
| Newman not installed | `which newman` returns nothing | Offer install: "Newman is not installed. Run: `npm install -g newman`. Approve? [YES/NO]". Block until resolved. |
| Server not running | Health check returns non-2xx or connection refused | HARD STOP — "Server is not running on {base_url}. Start it first, then say 'started' and I will continue." |
| Auth credentials are placeholders | Environment file has `replace-with-*` / `YOUR_KEY_HERE` / `<...>` values | HARD STOP — list exact variable names that need real values. Block until resolved. |
| Collection not found | `find` returns no `.postman_collection.json` | Skip silently. Parent emits: "No Postman collection found. Create one with `use the postman-collection skill`." |
| Newman run produces CODE BUG failure | Failure categorized as CODE BUG | Report to parent. Do NOT attempt collection fix. Return: "Newman found a code bug in {endpoint}. Fix the implementation first, then re-run." |
| Newman run exceeds context with many failures | 10+ failures at once | Present first 3 in detail. For rest: "N additional failures found. Resolve these 3 first, then re-run." |

**Key rule:** newman-tester is ALWAYS non-blocking at the trigger decision point — developer chooses YES or NO. Once YES is given and the run starts, the parent skill pauses until the run completes or developer types STOP. A CODE BUG finding from Newman does NOT auto-stop the parent workflow — it is reported and the developer decides next steps.
