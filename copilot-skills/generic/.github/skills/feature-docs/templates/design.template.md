# {{FEATURE_NAME}} — Design

> **Last updated**: {{DATE}} ({{VERSION}} — {{VERSION_NOTE}})
> **Project**: `{{SERVICE_NAME}}`
> **Scope**: {{SCOPE_SUMMARY}}
> **Status**: {{STATUS}}

---

<!--
╔══════════════════════════════════════════════════════════════════════════════════╗
║  GENERATION INSTRUCTIONS (AI reads this; not included in output)               ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  APPLICABILITY: This document is ALWAYS generated for all feature types.       ║
║  It applies universally — no skip conditions. The sections adapt:              ║
║  • No DB → §Code Exploration omits DB analysis, mark "N/A — no database"      ║
║  • No external APIs → §Design Decisions omits integration patterns             ║
║  • Library-only → focus on public API design decisions                         ║
║  • Event-driven → focus on event schema, ordering, idempotency decisions       ║
║                                                                                ║
║  TECHNOLOGY NEUTRAL:                                                           ║
║  • Use generic terms: "entry point" not "controller"                           ║
║  • Use "handler" not "@RestController"                                         ║
║  • Use "data model" not "DTO"                                                  ║
║  • Adapt terminology to whatever stack the project uses                        ║
║                                                                                ║
║  This document is the DESIGN AUTHORITY for the feature. It captures:           ║
║  • Every design decision with rationale                                        ║
║  • Every question asked and answered across ALL skills                         ║
║  • Code exploration findings (what exists, what's missing, critical issues)    ║
║  • Blast-radius analysis results                                               ║
║  • Implementation status verified against code                                 ║
║                                                                                ║
║  LIFECYCLE:                                                                    ║
║  • v1 (post-spec): Q&A record + exploration findings + design decisions        ║
║  • v2 (post-plan): blast-radius + implementation phases added                  ║
║  • v3 (post-impl): status verified against code, all components confirmed      ║
║                                                                                ║
║  QUALITY STANDARDS:                                                            ║
║                                                                                ║
║  Q&A SECTION:                                                                  ║
║  • Capture EVERY question from idea-to-spec, party-mode, spec-writer           ║
║  • Each question numbered sequentially across all skills (Q1, Q2, Q3...)       ║
║  • Each question has: topic, full question text, options, decided answer       ║
║  • Include the RATIONALE for each decision (why this option, not others)       ║
║  • Undecided questions marked ❓ OPEN with context for future resolution       ║
║  • This section is the AUDIT TRAIL — management can trace every decision       ║
║                                                                                ║
║  EXPLORATION SECTION:                                                          ║
║  • Run code-explorer on every class referenced in the spec                     ║
║  • Document: what exists, what's a clean slate, what has issues                ║
║  • Critical findings get their own subsection with code snippets               ║
║  • Include: current code (problematic) + needed code (proposed fix)            ║
║                                                                                ║
║  DESIGN DECISIONS:                                                             ║
║  • Summary table of all architectural choices                                  ║
║  • Each must reference which Q&A question drove the decision                   ║
║  • Include alternatives considered and why they were rejected                  ║
║                                                                                ║
║  BLAST-RADIUS (post-plan):                                                     ║
║  • For every change point from impl-planner                                    ║
║  • Show: target, risk tier, direct callers, DI wiring, key risk                ║
║  • Critical/High risks get explanation of mitigation strategy                  ║
║                                                                                ║
║  IMPLEMENTATION STATUS (post-impl):                                            ║
║  • Every component grep-verified with exact file path                          ║
║  • Status: ✅ Implemented / ❌ Deferred to Phase N / ⏳ In Progress            ║
║  • Cross-reference with plan.md tasks                                          ║
║                                                                                ║
║  DO NOT:                                                                       ║
║  • Invent questions that weren't actually asked                                ║
║  • Skip any question from any skill (even if answer seems obvious)             ║
║  • Mark something as ✅ without grepping the source                            ║
║  • Leave exploration findings empty — always run code-explorer                 ║
║  • Combine multiple questions into one (each gets its own ### block)           ║
╚══════════════════════════════════════════════════════════════════════════════════╝
-->

## Related Documents

| Document | Purpose |
|---|---|
| `spec.md` | Feature specification (ACs, business rules, contracts) |
| `plan.md` | Implementation plan (tasks, dependencies, complexity) |
| `architecture-diagrams.md` | Mermaid diagrams (system overview, sequences, hierarchy) |
| `flow.md` | End-to-end request flow (every class, method, failure path) |
| `integration-guide.md` | How-to guide for other teams to use this feature |
| `testing.md` | Test inventory, gaps, local/remote testing, default behaviours |

> **Canonical sources**: {{Note which document is authoritative for what — e.g., "MongoDB schema → spec §10. Architecture diagrams → architecture-diagrams.md."}}

---

## ✅ Implementation Status (verified against code)

> Every row below is verified by grep against source. No assumptions.
> This section is populated at post-impl phase.

| Component | Status | Key File | Plan Task |
|---|---|---|---|
<!-- Post-impl: grep every component, populate with real paths
| {{ComponentName}} | ✅ Implemented | `{{path/to/File.java}}` | Task {{N}} |
| {{ComponentName}} | ❌ Phase {{N}} | — | Deferred |
-->

---

## Code Exploration Findings (Pre-Design)

> Populated by `code-explorer` during post-spec phase.
> This section captures what ALREADY EXISTS before any new code is written.

### What Already Exists

| Component | Finding | Location |
|---|---|---|
<!-- Run code-explorer on every class/pattern referenced in spec.
     For each:
     | SecurityFilter | ✅ Exists — validates x-api-key, @Order not set | security/SecurityFilter.java |
     | RateLimitFilter | ❌ NONE — clean slate | N/A |
-->

### Key Insights

<!-- Document patterns, conventions, and constraints discovered:
     - Existing patterns to follow (e.g., "ConfigServiceImpl uses @Cacheable — read-only")
     - Gaps to fill (e.g., "no @CachePut/@CacheEvict in current code")
     - Conventions (e.g., "all filters use OncePerRequestFilter base")
     Include ASCII diagrams for complex patterns:
-->

```
{{PATTERN_DIAGRAM_IF_APPLICABLE}}
```

### ⚠️ Critical Findings

<!-- For EACH issue discovered that affects the design:
     - Title the finding
     - Explain why it matters
     - Show current code (problematic)
     - Show needed code (proposed fix)
     - Note: these may become additional tasks in plan.md
-->

---

## All Questions — Full Record

> Questions marked ✅ DECIDED have confirmed answers. ❓ OPEN = still needs confirmation.
> Questions are numbered SEQUENTIALLY across ALL skills that contributed.
> This is the audit trail — every decision is traceable.

---

<!--
TEMPLATE FOR EACH QUESTION:

### Q{{N}}: {{Topic}}
**Source skill**: {{idea-to-spec / party-mode / spec-writer / impl-planner}}
**Question**: {{The exact question asked}}
- (a) {{Option A}} — {{brief implication}}
- (b) {{Option B}} — {{brief implication}}
- (c) {{Option C}} — {{brief implication}}

> **Answer**: ✅ DECIDED — **({{letter}}) {{chosen option}}**. {{Full rationale: why this choice, what it enables, what it rules out. 2-3 sentences minimum.}}

---

OR for open questions:

### Q{{N}}: {{Topic}}
**Source skill**: {{skill-name}}
**Question**: {{The exact question asked}}

> **Answer**: ❓ OPEN — deferred to {{phase/reason}}. Context: {{what's needed to decide}}.

---
-->

---

## Design Decisions

> Architectural choices summarized from the Q&A record above.
> Each decision references its source question for traceability.

| # | Decision | Chosen Approach | Alternatives Considered | Source | Rationale |
|---|---|---|---|---|---|
<!-- 
| 1 | How to store config | 2-collection split (API + Dimension) | Single merged doc per client×API | Q3, Q5 | Scales linearly; day/night changes are 2 API calls not N |
-->

---

## Blast-Radius Findings

> Populated during post-plan phase from impl-planner's blast-radius analysis.
> Every class that will be MODIFIED or DEPENDED UPON gets a risk assessment.

| Change Point | Risk Tier | Direct Callers | DI/Injection Sites | Key Risk | Mitigation |
|---|---|---|---|---|---|
<!--
| SecurityFilter | MEDIUM | 0 (leaf) | SecurityConfig bean | Filter order change affects all requests | Add @Order explicitly; regression tests |
-->

### Critical/High Risk Details

<!-- For each CRITICAL or HIGH risk item, expand with:
     - Full caller list
     - Exact change being made
     - What could break
     - How tests will catch it
     - Rollback plan
-->

---

## Proposed Implementation Phases

> Populated during post-plan phase from plan.md task breakdown.

| Phase | Tasks | Key Files | Complexity | Dependencies | Estimated Effort |
|---|---|---|---|---|---|
<!--
| 1 — Core model | Create DTOs + repository | model/, repository/ | S | None | 2h |
| 2 — Service layer | Implement business logic | service/impl/ | M | Phase 1 | 4h |
-->

---

## Version History

| Version | Date | Phase | Changes |
|---|---|---|---|
| v1 | {{CREATED_DATE}} | post-spec | Initial design: Q&A record + exploration findings + design decisions |
<!-- Append as design evolves:
| v2 | {{DATE}} | post-plan | Added blast-radius findings + implementation phases |
| v3 | {{DATE}} | post-impl | Verified against code; implementation status confirmed |
-->
