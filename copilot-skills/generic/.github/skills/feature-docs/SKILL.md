---
name: feature-docs
description: "Auto-generate presentation-ready feature documentation at each workflow gate"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [code-explorer, architecture-diagrammer]
triggered-by: [spec-writer, impl-planner, implement-and-test, pr-preparation]
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Automatically generate a complete set of feature documentation at defined workflow gates — after spec approval, after plan approval, and after implementation. These documents serve two audiences: upper management and stakeholders before coding starts (`design.md`, `architecture-diagrams.md`, `flow.md`), and engineering teams and maintainers after coding is complete (`testing.md`, `integration-guide.md`, updated `flow.md`).

The skill ensures no feature ships without comprehensive, accurate, code-verified documentation. It captures all decisions made throughout the process as an auditable trail.

## Entry Conditions

This skill is **primarily auto-triggered** as a sub-agent at workflow gates. It can also be **manually invoked** for regeneration or on-demand documentation (e.g., `"generate feature docs"` or `"update docs for COM-XXX"`).

### Auto-trigger (normal workflow)

| Gate | Triggered by | Required context |
|---|---|---|
| `post-spec` | `spec-writer` (after Status: APPROVED) | `features/<ticket-id>/spec.md` exists with Status: APPROVED |
| `post-plan` | `impl-planner` (after Status: APPROVED) | `features/<ticket-id>/plan.md` exists with Status: APPROVED |
| `post-impl` | `implement-and-test` (after all tasks `[x]`) | All plan tasks done + `./mvnw verify` passes |

### Manual trigger

User says: `"generate feature docs"`, `"update feature docs"`, `"use the feature-docs skill"`

When manually triggered:
1. **Auto-detect phase** from existing artifacts:
   - spec.md exists + no testing.md → run `post-spec` (or `post-plan` if plan exists)
   - plan.md exists + no testing.md → run `post-plan` then `post-impl` if code is written
   - testing.md exists → run `post-impl` (update/verification mode)
2. **Auto-detect ticket** from: branch name (`[A-Z]+-[0-9]+`), or `features/` folder, or ask user
3. No parent skill context → ask: "Which feature folder? I see: [list]"

**If entry conditions are not met**: **STOP. Report which condition failed and suggest what to do next. Example: "spec.md not found or not APPROVED. Run spec-writer first." Do not continue.**
- If **spec.md is malformed** (missing required sections per spec-template.md): **STOP. spec.md is missing sections: [list]. Cannot generate accurate docs. Fix spec first. Do not continue.**
- If **grep verification fails** at post-impl phase (class/method referenced in docs not found in src/): **STOP. Reference verification failed: [class] not found in codebase. Docs would be inaccurate. Do not continue.**

## Clarifying Questions

When **auto-triggered**: Does NOT ask clarifying questions. All context comes from:
- `spec.md` — feature scope, ACs, business rules
- `plan.md` — implementation tasks, blast-radius results
- `design.md` (if exists) — prior decisions from earlier phases
- `brief.md` (if exists) — original idea context
- Conversation history — Q&A decisions from parent skills

When **manually triggered**: May ask:
- "Which feature? I see folders: [list]" (if multiple features exist and branch doesn't identify one)
- "Which phase? Spec is approved, plan is approved, code is written — run post-impl?" (if ambiguous)

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill for architecture verification or diagram generation, anchor to the repo root with `cd "$(git rev-parse --show-toplevel)"`, then check if `graphify-out/graph.json` exists (a "graph file not found" error from a subdirectory is NOT a missing graph). If it does, run `graphify query` first to verify component references. Use grep only to supplement or verify. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Entry Conditions

```bash
# Auto-detect phase from existing artifacts
ls features/*/spec-infobip.md 2>/dev/null && grep "Status:" features/*/spec-infobip.md | head -3
ls features/*/plan.md 2>/dev/null && grep "Status:" features/*/plan.md | head -3
ls features/*/testing.md 2>/dev/null && echo "Post-impl docs already exist" || echo "No post-impl docs yet"
```
**No hard stop — use this output to determine which phase docs to generate.**

### Phase: post-spec (triggered after spec APPROVED)

**Input**: `spec.md` (APPROVED), `brief.md` (if exists), conversation Q&A from idea-to-spec + spec-writer + party-mode

**Steps:**

## Step 1 — Create features/<ticket-id>/README.md
   - Use README template
   - List all documents that will exist in this folder (including planned future ones)
   - Include quick-reference summary from spec
   - ```bash
# ✓ Check before moving on: `test -f features/<ticket-id>/README.md` — file exists with non-zero content
echo 'Step done: `test -f features/<ticket-id>/README.md` — file exists with '
```
## Step 2 — Create features/<ticket-id>/design.md (v1)
   - §Code Exploration Findings: trigger `code-explorer` on classes referenced in spec
   - §All Questions — Full Record: capture EVERY question asked during idea-to-spec, party-mode, spec-writer
   - Each question formatted as: `### Q{N}: {topic}` with `> **Answer**: ✅ DECIDED — {answer}`
   - §Design Decisions: summarize architectural choices with rationale
   - §Related Documents: link to spec.md and any other feature docs
   - ```bash
# ✓ Check before moving on: design.md contains at least §Code Exploration Findings and §Design Decisions sec
echo 'Step done: design.md contains at least §Code Exploration Findings and §'
```
## Step 3 — Create features/<ticket-id>/architecture-diagrams.md (v1)
   - Trigger `architecture-diagrammer` with spec context
   - Generate system overview diagram (C4 Level 2) showing where new feature fits
   - Generate request flow sequence diagram (conceptual — not code-verified yet)
   - Mark with `> Status: CONCEPTUAL — will be code-verified after implementation`
   - ```bash
# ✓ Check before moving on: File contains at least one valid Mermaid code block (```mermaid)
echo 'Step done: File contains at least one valid Mermaid code block (```merm'
```
## Step 4 — Create features/<ticket-id>/flow.md (v1 — conceptual)
   - High-level request flow based on spec
   - Planned class names and method signatures (from spec §Domain References)
   - Mark unverified items: `⚠️ PLANNED — not yet implemented`
   - Include filter chain order, entry points, data flow
   - ```bash
# ✓ Check before moving on: File contains at least one sequence/flowchart diagram and lists entry points
# Diagram output in response above — scan for mermaid block
```
## Step 5 — Trigger architecture-diagrammer follow-up for cross-cutting features
   - If the approved spec is cross-cutting, trigger `architecture-diagrammer` to review the conceptual diagrams from Step 3 against the planned flow captured in Step 4.
   - Capture any follow-up diagram notes in `architecture-diagrams.md` or include them in the post-spec handoff summary.
   - ```bash
# ✓ Check before moving on: Cross-cutting features have an architecture-diagrammer follow-up note or are marked not applicable.
 echo 'Step done: Cross-cutting features have an architecture-diagrammer follow-up note or are marked not applicable.'
```
**Report to parent skill**: "Feature docs generated (post-spec phase). 4 files created in `features/<ticket-id>/`."

---

### Phase: post-plan (triggered after plan APPROVED)

**Input**: `plan.md` (APPROVED), existing `design.md`, blast-radius results from impl-planner

**Steps:**

## Step 6 — Update features/<ticket-id>/design.md
   - Add §Implementation Phases section (from plan.md complexity + task breakdown)
   - Add §Blast-Radius Findings section (risk tiers for each change point)
   - Add §Proposed Implementation Phases table (task order, file paths, size estimates)
   - Update §Related Documents with link to plan.md
   - ```bash
# ✓ Check before moving on: design.md updated with blast-radius data and phase breakdown.
# Blast-radius output received and logged above
```
## Step 7 — Update features/<ticket-id>/flow.md
   - Add planned file paths from plan.md tasks
   - Update class names if plan refined them from spec
   - Still marked `⚠️ PLANNED` — code verification happens post-impl
   - ```bash
# ✓ Check before moving on: flow.md updated with planned file paths and refined class names from plan.md.
ls features/*/plan.md 2>/dev/null && grep 'Status:' features/*/plan.md | head -3
```
## Step 8 — Finalize the post-plan design update with blast-radius results
   - Confirm `design.md` includes the blast-radius findings and implementation phase breakdown received from `impl-planner`.
   - Report the post-plan summary to the parent skill, covering both `design.md` and `flow.md` updates.
   - ```bash
# ✓ Check before moving on: Parent skill receives a post-plan update summary covering both updated files.
echo 'Step done: Parent skill receives a post-plan update summary covering both updated files.'
```
### Phase: post-impl (triggered after all tasks `[x]` + verify passes)

**Input**: All feature code written, tests passing, actual file:line references available

**Steps:**

## Step 9 — Create features/<ticket-id>/testing.md
    - Use testing template
    - grep actual test classes to build test inventory table
    - Count tests per class
    - Identify gaps (untested paths based on spec ACs vs test coverage)
    - Include "How to test locally" section with commands
    - Include "How to test in dev/preprod" section
    - ```bash
# ✓ Check before moving on: testing.md generated with test class names verified via grep.
ls features/*/testing.md 2>/dev/null && echo 'testing.md exists'
```
## Step 10 — Create features/<ticket-id>/integration-guide.md
    - Use integration-guide template
    - Reference actual code paths (grep-verified)
    - Step-by-step guide for other teams to use/integrate with this feature
    - Include curl examples, config examples, prerequisite setup
    - ```bash
# ✓ Check before moving on: integration-guide.md created with grep-verified code paths and integration steps
echo 'Step done: integration-guide.md created with grep-verified code paths a'
```
## Step 11 — Update features/<ticket-id>/flow.md (code-verified)
    - Replace ALL `⚠️ PLANNED` markers with actual `file:line` references
    - grep-verify every class name, method name, and path
    - Add exact method signatures from source
    - Add failure paths discovered during implementation
    - ```bash
# ✓ Check before moving on: flow.md updated with code-verified `file:line` references and no unresolved plan
echo 'Step done: flow.md updated with code-verified `file:line` references an'
```
## Step 12 — Update features/<ticket-id>/architecture-diagrams.md (code-verified)
    - Re-run `architecture-diagrammer` with actual source code
    - Replace `Status: CONCEPTUAL` with `Status: CODE-VERIFIED ✅`
    - Every node in Mermaid diagram must be grep-verified against `src/main/java/`
    - Add any components discovered during impl that weren't in spec
    - ```bash
# ✓ Check before moving on: architecture-diagrams.md marked `CODE-VERIFIED ✅` and every Mermaid node maps to
# Diagram output in response above — scan for mermaid block
```
## Step 13 — Update features/<ticket-id>/design.md (final)
    - Update §Implementation Status with verified table (component → status → file path)
    - Mark overall status: `Status: IMPLEMENTED ✅`
    - Ensure no `TODO` or `VERIFY-NEEDED` markers remain
    - ```bash
# ✓ Check before moving on: design.md shows final implementation status and contains no unresolved TODO/veri
echo 'Step done: design.md shows final implementation status and contains no '
```
## Step 14 — Update features/<ticket-id>/README.md
    - Update status to reflect completion
    - Verify all document links are valid
    - ```bash
# ✓ Check before moving on: README.md reflects implementation-complete status and all internal doc links res
echo 'Step done: README.md reflects implementation-complete status and all in'
```
## Step 15 — Verification pass (CRITICAL — no hallucinations)

| Verify | Requirement | On failure |
|---|---|---|
| `file:line` refs | grep every reference in all docs | **STOP. Reference verification failed: [item] not found in codebase. Fix source or remove reference.** |
| Class names | every mentioned class exists in source | **STOP** |
| Method signatures | exact source match | **STOP** |
| Post-impl markers | no unresolved `⚠️ PLANNED`, `TODO`, or `VERIFY-NEEDED` | **STOP** |

If all rows pass, report `N references verified, M warnings, zero NOT FOUND`.

```bash
# ✓ Check before moving on: All references verified (zero `NOT FOUND`). If any failed, hard stop was trigger
echo 'Step done: All references verified (zero `NOT FOUND`). If any failed, h'
```
**Report to parent skill**: "Feature docs finalized (post-impl phase). All docs code-verified. N references verified, M warnings."
    - ```bash
# ✓ Check before moving on: Parent skill receives the finalized post-impl report with verification counts.


echo 'Step done: Parent skill receives the finalized post-impl report with ve'
```
## Exit Conditions / Done Definition

| Phase | Done when |
|---|---|
| post-spec | README.md + design.md + architecture-diagrams.md + flow.md exist |
| post-plan | design.md updated with blast-radius + phases; flow.md updated with planned paths |
| post-impl | testing.md + integration-guide.md exist; ALL docs code-verified; zero unresolved `⚠️ PLANNED` markers |

## Sub-Agents

| Sub-agent | When triggered | Purpose |
|---|---|---|
| `code-explorer` | post-spec Step 2, post-impl Step 11 | Explore existing code for design.md findings; verify flow paths |
| `architecture-diagrammer` | post-spec Step 3, post-impl Step 12 | Generate/refresh Mermaid diagrams |

## Example Invocation

This skill is primarily auto-triggered, but can also be manually invoked (see Entry Conditions above):

```
# Inside spec-writer, after developer types APPROVE:
spec-writer → sets Status: APPROVED → triggers feature-docs phase:post-spec

# Inside impl-planner, after developer types APPROVE:
impl-planner → sets Status: APPROVED → triggers feature-docs phase:post-plan

# Inside implement-and-test, after all [x] + verify passes:
implement-and-test → all tasks done → triggers feature-docs phase:post-impl
```

## What I Will NOT Do

- ❌ Generate docs without source verification (post-impl phase)
- ❌ Invent class names, method signatures, or file paths
- ❌ Skip the post-impl verification pass
- ❌ Create docs with placeholder content that says "TODO" or "TBD"
- ❌ Run without at least a spec.md in the feature folder (minimum requirement)
- ❌ Ask clarifying questions when auto-triggered as sub-agent — uses parent context + existing artifacts
- ❌ Modify application code — documentation only
- ❌ Replace the spec.md or plan.md — those are owned by their respective skills

## Output Format

All documents are written to `features/<ticket-id>/` directory. Format:
- Markdown files with standardized headers
- Mermaid diagrams inline (rendered in GitHub/IntelliJ)
- All code references as `package.Class.method()` or `path/to/File.java:lineNum`
- grep-verification markers: `✅ FOUND` / `❌ NOT FOUND`

## Q&A Capture Protocol

**How decisions flow into design.md:**

Each parent skill (idea-to-spec, party-mode, spec-writer) that asks clarifying questions MUST pass its Q&A pairs to feature-docs. The contract:

```
Parent skill completes its Q&A phase
  → Parent passes to feature-docs: { questions: [{id, topic, question, answer, decidedAt}] }
  → feature-docs appends to design.md §All Questions — Full Record
  → Each question gets: ### Q{N}: {topic}
                         **Question**: {text}
                         > **Answer**: ✅ DECIDED — {answer}
```

**Questions from multiple skills are numbered sequentially** (Q1-Q5 from idea-to-spec, Q6-Q10 from spec-writer, Q11-Q15 from party-mode, etc.)

**Undecided questions** (developer said "decide later" or skipped):
- Marked as `> **Answer**: ❓ OPEN — deferred to implementation phase`
- Surfaced again at post-plan phase for resolution

## Step 16 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ feature-docs — done?
  □ Steps 0–16 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Plan implementation                    — say: "use the impl-planner skill for <ticket-id>"
  B) Start implementation                   — say: "use the implement-and-test skill for <ticket-id>"
  C) Prepare a PR                           — say: "use the pr-preparation skill"
  D) Review generated docs                  — say: "use the code-explorer skill — review features/<ticket-id>/"
  E) Update Postman collection              — say: "update postman collection"
  F) Get help                              — say: "help"

⭐ The option matching your current phase — post-spec→impl-planner, post-plan→implement-

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ⚡ Escalation Path (skill-specific)

| Stuck At | What Happened | Do This |
|---|---|---|
| post-spec Step 2 | code-explorer can't find referenced classes | Report to parent: "Spec references classes that don't exist yet. design.md §Exploration section will be populated after impl." |
| post-spec Step 3 | architecture-diagrammer returns empty | Generate a minimal placeholder diagram from spec endpoints; mark as CONCEPTUAL |
| post-impl Step 15 | Verification finds broken references | List ALL broken refs in report. Do NOT suppress. Parent skill decides whether to fix or mark as known gaps. |
| Any phase | Feature directory doesn't exist | Create `features/<ticket-id>/` directory |
| Any phase | Previous phase docs are missing | Generate them from scratch (idempotent — safe to re-run any phase) |
