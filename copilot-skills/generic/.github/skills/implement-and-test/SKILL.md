---
name: implement-and-test
description: "Implement code and write tests for each task in the approved plan"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [blast-radius, feature-docs, postman-collection, newman-tester]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Execute each task in an approved implementation plan: write/modify code, write corresponding tests, run tests, and mark tasks complete. Supports full-workflow entry (from plan.md) and fast-track entry (bug-fix or config-only changes without a formal plan).

## Entry Conditions

**Full workflow:**
- `features/<ticket-id>/plan.md` exists with `Status: APPROVED`
- Tasks use checkbox format: `- [ ]` = pending, `- [x]` = done

**Fast-track (bug-fix):**
- Bug-tracer has identified root cause with file path and suggested fix
- No spec/plan required

**Fast-track (config-only):**
- Change description provided, no spec/plan required

If none of these conditions are met: **STOP. I need an approved plan.md, a bug-tracer handoff, or a config-only change description. Do not continue.**

## Clarifying Questions

Before proceeding, ask the developer:

- Which task should I start with (or should I follow dependency order)?
- Do you prefer test-first (write test → write code → verify) or code-first (write code → write test → verify)?
- What is the minimum acceptable test coverage threshold for new code?

For fast-track entry, ask:
- Should I proceed with the suggested fix, or do you have modifications?

**For enhancement entry (extending existing feature):**
- Which existing EventProcessor/class am I extending?
- Should I modify the existing class or create a new one that delegates to it?
- Are there existing tests I should extend vs. create new test classes?

**For dependency upgrade entry:**
- What is the current version and target version?
- Are there known breaking API changes?
- Should I run the full test suite or focus on specific areas?

Proceed only after answers are received.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill for verifying class references, checking existing patterns, or understanding caller/dependency relationships, anchor to the repo root with `cd "$(git rev-parse --show-toplevel)"`, then check if `graphify-out/graph.json` exists (a "graph file not found" error from a subdirectory is NOT a missing graph). If it does, run `graphify query "<what class does X depend on>"` or `graphify path "<ClassA>" "<ClassB>"` first. Use grep only to supplement or verify specifics. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Entry Conditions

```bash
# Full workflow: verify approved plan exists
grep -l "Status: APPROVED" features/*/plan.md 2>/dev/null \
  || echo "MISSING: No approved plan.md found"
# Show pending vs done task counts
grep -c "\- \[ \]" features/*/plan.md 2>/dev/null | head -3
grep -c "\- \[x\]" features/*/plan.md 2>/dev/null | head -3
```
**STOP. If "MISSING" is shown and this is a full-workflow run, run impl-planner first. Fast-track entry (bug-fix or config-only): no plan.md required — document entry type in output.**

**Resume support**: On re-invocation, read `plan.md` first. Skip all `[x]` tasks. Report: "Found N completed tasks. Resuming from task: [first `[ ]` task]." Ask: "Resume from here, or start fresh?"

**TASK EXECUTION LOOP — One task at a time, no batching:**

```bash
# Show ALL pending tasks before starting
grep -n "\- \[ \]" features/*/plan.md 2>/dev/null
```

Pick the FIRST `- [ ]` task. Execute Steps 1–6 for that task ONLY.
After Step 6 (task marked [x]), announce:
`"✅ Task [N] — [name] — complete. Remaining: [list remaining - [ ] tasks]"`
Then loop back to Step 1 for the next `- [ ]` task.

**STOP. Never execute Steps 1–6 for two tasks simultaneously. Never skip a task because 'it's similar to the previous one'. Every task gets a full pass through Steps 1–6.**

## Step 1 — Read task

Parse the next pending `- [ ]` task from `plan.md`. A valid task entry looks like:
```
### Task N: [Name]
- **File**: `src/path/to/File.java`
- **Action**: create / modify / delete
- **Description**: [what to do]
- **Blast Risk**: LOW / MEDIUM / HIGH
- **Depends on**: Task M or none
```
Note the file path, action, description, spec reference, and blast-risk level.
```bash
# Show next pending task
grep -n "\- \[ \]" features/*/plan.md | head -3
```
## Step 2 — Verify references

Grep to confirm all classes, methods, and interfaces referenced by this task exist in the codebase. If any reference is missing: **STOP. Report the missing reference. Do not write any code until it is resolved.**
   ```bash
# ✓ Check before moving on: All referenced classes, methods, and interfaces return grep hits.
# Grep already ran above — check output shows matches
```
## Step 3 — Write/modify code

Implement the change following patterns in the project's coding standards. If project-specific companion files exist, load them: [coding-standards-core.md](coding-standards-core.md) [PROJECT-SPECIFIC] and [coding-standards-reference.md](coding-standards-reference.md) (on-demand for full examples). If no companion files exist (generic-only mode), follow the principles below directly from codebase patterns. Follow ALL standards including:
   - SOLID principles (§1), DRY (§1.6), Clean Code (§2)
   - Design patterns appropriate to the change (§3)
   - Fault tolerance for external calls (§6)
   - Performance rules for async code (§7)
   - Trade-off documentation when choosing between approaches (§8)

   ```bash
# ✓ Check before moving on: Code changes are saved to disk.
echo 'Step done: Code changes are saved to disk'
```
## Step 4 — Write corresponding test

Write a test class/method for the change. If project-specific companion files exist, load: [test-patterns-core.md](test-patterns-core.md) and [test-patterns-reference.md](test-patterns-reference.md) (on-demand) [PROJECT-SPECIFIC]. If no companion files exist, infer test patterns from existing test files in the project (grep for `@Test` or equivalent). Follow ALL patterns including:
   - BDD structure: Given/When/Then comments (§BDD Structure)
   - Test naming: should[Behavior]When[Condition] (§Naming Convention)
   - Parameterized tests for multi-site scenarios (§Parameterized Tests)
   - Async testing for CompletableFuture code (§Async Testing)
   - Coverage: 80% line, 70% branch, 100% for critical path (§Coverage Rules)

   ```bash
# ✓ Check before moving on: Test file is saved to disk.
echo 'Step done: Test file is saved to disk'
```
## Step 5 — Run test

Execute the test for this task's test class. If test fails: analyze output → fix → re-run (max 3 attempts). If still failing after 3 attempts: **STOP. Report the full failure output. Do not mark the task done.**
   ```bash
   # Run targeted test (adapt command to project stack)
   ./mvnw test -Dtest=ClassName 2>/dev/null || npm test -- --testNamePattern="ClassName" 2>/dev/null || go test -run TestName ./... 2>/dev/null
   ```
   ```bash
# ✓ Check before moving on: Targeted test output shows PASS for the task's test class.
./mvnw test 2>/dev/null | tail -5 || npm test 2>/dev/null | tail -5 || go test ./... 2>/dev/null | tail -5
```
## Step 6 — Mark task done

Update `- [ ]` to `- [x]` in `plan.md`.
   ```bash
   # Verify: checkbox was updated
   grep "\- \[x\]" features/*/plan.md | tail -3
   ```

**After all tasks are complete:**

## Step 7 — Run full build verification

Execute the project's full test suite and coverage gate.
   ```bash
   # Run full build (adapt to project stack)
   ./mvnw verify 2>/dev/null || npm test 2>/dev/null || go test ./... 2>/dev/null
   ```
   **STOP. If build fails, fix failures before proceeding. Do not continue to blast-radius with a broken build.**
## Step 8 — Trigger blast-radius sub-agent

Always run blast-radius on ALL changed files. This is not conditional.
   Provide the list of all changed files with one-line change descriptions. blast-radius returns risk level and unexpected callers.
   ```bash
   # Get changed files for blast-radius input
   git diff --name-only HEAD 2>/dev/null | grep -E '\.(java|ts|js|py|go)$' | head -20
   ```
## Step 9 — Trigger feature-docs sub-agent (post-impl)

Generate testing.md, integration-guide.md; update all existing feature docs with code-verified references.
   ```bash
# Verify Step 9: feature-docs ran
ls features/*/testing.md 2>/dev/null && echo '✅ testing.md exists' || echo '❌ MISSING — feature-docs did not complete'
```
**STOP. If testing.md is missing and this is full-workflow (not fast-track), feature-docs did not run. Do not proceed.**
## Step 10 — Trigger postman-collection sub-agent

Generate/update Postman collection and environment for new/modified endpoints.
    ```bash
# Verify Step 10: postman-collection ran
ls postman/*.postman_collection.json 2>/dev/null && echo '✅ collection exists' || echo 'ℹ️ No collection — confirm no API endpoints were added'
```

## Step 11 — Offer Newman E2E validation

After postman-collection completes (or is skipped):
    1. Search for Postman collection: `find postman/ tests/ . -maxdepth 1 -name "*.postman_collection.json" 2>/dev/null`
    2. If collection found: present to user:
       ```
       I found a Postman collection at: {path}
       Your implementation touched: {list changed endpoints}
       The collection covers: {M} of those endpoints.
       Would you like me to run it against your local server to verify the implementation end-to-end?
       [YES / NO]
       ```
       Wait for explicit YES before proceeding. NEVER run Newman without confirmation.
    3. If YES: invoke `newman-tester` skill (Mode A — post-fix). Return here after newman-tester completes.
    4. If NO: continue to Phase Gate (Step 12) as usual.
    5. If no collection found: say "No Postman collection found. You can create one with `use the postman-collection skill` or proceed directly to PR preparation."
    ```bash
# ✓ Check before moving on: Developer was offered Newman validation and responded. Either newman-tester ran 
echo "✓ Check: developer responded to Newman offer above (YES/NO recorded)"
```
## Step 12 — Phase Gate (with mandatory pre-condition check)

Before presenting the gate, verify:
    ```
    PRE-CONDITION CHECK (mandatory — print this checklist):
    ────────────────────────────────────────────────────────
    □ Build verify passed?                    → [PASS/FAIL]
    □ feature-docs ran (Step 9)?             → [YES — testing.md + integration-guide.md exist]
                                               OR [SKIPPED — reason: {fast-track|no-spec|explicit-skip}]
    □ postman-collection ran (Step 10)?      → [YES — collection exists]
                                               OR [SKIPPED — reason: {no-endpoints|explicit-skip}]
    ────────────────────────────────────────────────────────
    If ANY □ is unresolved → DO NOT present the gate. Go back and execute the missing step.
    ```
    
    Then present:
    ```
    ✅ All [N] tasks complete. Build verify: [PASS/FAIL].
       Feature docs: [✅ Generated | ⚠️ SKIPPED: reason].
       Postman collection: [✅ Updated | ⚠️ SKIPPED: reason].
    
    ➡️  Next step: Prepare a PR.
        Shall I invoke pr-preparation now? [YES / LATER]
    ```
    If developer says YES (or "continue", "go ahead", "ship it") → auto-invoke `pr-preparation` with the same ticket context.
     
    ```bash
# ✓ Check before moving on: Pre-condition checklist is printed, all items resolved, then completion summary 
git log --oneline -3 2>/dev/null
```
**On re-invocation (code changed after initial completion):**

## Step 13 — Staleness Detection & Auto-Heal

Only runs on re-invocation (all tasks already `[x]`). Skip on first run.

```bash
# Check if src/ changed AFTER docs/postman were generated
git log --oneline --since="$(stat -f %Sm -t '%Y-%m-%dT%H:%M' features/*/testing.md 2>/dev/null)" -- src/ 2>/dev/null | head -5
```

If any commits shown: re-trigger `feature-docs` (post-impl) and `postman-collection` automatically. Report: "🔄 Syncing docs + Postman to latest code changes." If no commits: report "✅ Docs and Postman collection are current."


## Exit Conditions / Done Definition

- Every task in `plan.md` is marked `- [x]`
- Full build verification passes with zero test failures
- No unresolved HARD STOPs remain
- For fast-track: code change made + test written + build passes

**Idempotency**: Running this skill twice on the same plan.md:
- Already-completed tasks (marked [x]) are skipped
- Partially completed tasks resume from where they left off
- Tests are re-run to confirm previous work still passes
- No duplicate files or classes created

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|---|---|---|---|
| `blast-radius` | Step 8 — always, on ALL changed files (unconditional) | List of changed file paths + change descriptions | Risk assessment confirming no unintended side effects |
| `feature-docs` | Step 9 — always on full-workflow completion | Feature ticket, spec, plan, Q&A log | testing.md, integration-guide.md + updates to all existing docs |
| `postman-collection` | Step 10 — when feature has API endpoints | Endpoint list, DTOs, spec acceptance criteria | Collection JSON + environment updates |
| `newman-tester` | Step 11 — after postman-collection, when developer says YES | Collection path, changed endpoints | Newman run results + e2e-test-report.md updated |
| `feature-docs` | Step 13 — on re-invocation with code changes | Changed file list + existing docs | Updated docs with code-verified references |
| `postman-collection` | Step 13 — on re-invocation with code changes | Changed endpoints + existing collection | Updated collection with new/modified requests |

## Example Invocation

**Full workflow:**
> "Implement COM-789. Start with Task 1."

**AI responds:**
> "I see plan.md has 5 tasks. Before I start:
> 1. Should I follow dependency order (Tasks 1→3→2→4→5) or your preferred order?
> 2. Test-first or code-first?
> 3. What's the minimum coverage threshold?"

**Fast-track (bug-fix):**
> "Fix the bug traced in COM-456. bug-tracer identified the root cause in the order processor."

**AI responds:**
> "Bug-tracer identified root cause in OrderProcessor.java:142. Should I proceed with the suggested null-check fix, or do you have a different approach?"

## What I Will NOT Do

- Skip writing tests for any task
- Commit code (that is pr-preparation's responsibility)
- Touch files outside the scope listed in plan.md
- Assume classes/methods exist without grep verification
- Continue past a HARD STOP without developer resolution

---

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 3 (test writing) | Cannot determine what to test | Read existing test for sibling class. Follow same pattern. If no sibling exists, ask developer. |
| Step 5 (test failure) | Test fails after 3 attempts | **STOP. Present options to developer: (A) Debug manually with stack trace, (B) Use bug-tracer skill, (C) Simplify the change and retry, (D) Mark task as blocked in plan.md.** Wait for choice. |
| Step 6 (verify) | `./mvnw verify` fails on unrelated test | Confirm test was failing before changes: `git stash && ./mvnw test -Dtest=FailingTest && git stash pop`. If pre-existing: STOP and ask developer "Test [X] was already failing before your changes. Options: (A) Proceed to PR — note pre-existing failure in PR body, (B) Fix it now, (C) Abort." Do NOT silently proceed. |
| Step 8 (blast-radius) | Post-implementation blast-radius shows unexpected callers | Review each unexpected caller. If tests cover them, proceed. If not, add tests. |

---

## Step 14 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ implement-and-test — done?
  □ Steps 0–14 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Create PR                              — say: "use the pr-preparation skill for COM-XXX"
  B) Run blast-radius check                 — say: "use the blast-radius skill on [modified class]"
  C) Debug test failures                    — say: "use the bug-tracer skill — [test failure description]"
  D) Revise plan                            — say: "use the impl-planner skill for COM-XXX"
  E) Get help                              — say: "help"

⭐ A — all tasks complete and verified, ship it.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
