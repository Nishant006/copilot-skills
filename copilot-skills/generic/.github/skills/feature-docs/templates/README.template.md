# {{TICKET_ID}} — {{FEATURE_NAME}}

**Scope**: {{SCOPE_SUMMARY}}
**Service**: `{{SERVICE_NAME}}`
**Status**: {{STATUS}}

---

<!--
╔══════════════════════════════════════════════════════════════════════════════════╗
║  GENERATION INSTRUCTIONS (AI reads this; not included in output)               ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  This file is the INDEX for the feature folder. It must:                       ║
║  • Be instantly scannable (30 seconds to understand what's here)               ║
║  • List EVERY document with its purpose and generation phase                   ║
║  • Include a quick-reference block for the most important runtime facts        ║
║  • Include a status tracker showing which phases are complete                  ║
║  • Be updated at EVERY phase (post-spec, post-plan, post-impl)                ║
║                                                                                ║
║  QUALITY:                                                                      ║
║  • Quick reference must contain the TOP 5-8 facts someone needs immediately   ║
║  • Status tracker must be accurate (updated at each phase gate)                ║
║  • All file links must be valid                                                ║
╚══════════════════════════════════════════════════════════════════════════════════╝
-->

## Documents in this folder

| File | What it answers | Generated at | Status |
|---|---|---|---|
| `spec.md` | Full feature spec (ACs, business rules, schema, contracts) | Phase 1 — Specification | {{STATUS}} |
| `design.md` | Design decisions, Q&A audit trail, exploration findings, blast-radius | Phase 1+3 — Spec + Plan | {{STATUS}} |
| `flow.md` | Full request flow — every class, method, data path, failure mode | Phase 1+4 — Spec + Impl | {{STATUS}} |
| `architecture-diagrams.md` | Mermaid diagrams: system overview, sequences, component relationships | Phase 1+4 — Spec + Impl | {{STATUS}} |
| `integration-guide.md` | How other teams use/integrate with this feature (step-by-step + examples) | Phase 4 — After Implementation | {{STATUS}} |
| `testing.md` | Test inventory, gaps, defaults, assumptions, how to test locally + remote | Phase 4 — After Implementation | {{STATUS}} |
| `plan.md` | Implementation plan (tasks, dependencies, complexity, size estimates) | Phase 3 — Planning | {{STATUS}} |

## Quick reference

```
{{KEY_FACT_1}}
{{KEY_FACT_2}}
{{KEY_FACT_3}}
{{KEY_FACT_4}}
{{KEY_FACT_5}}
{{KEY_FACT_6}}
```

## Status tracker

| Phase | Status | Date | Key Output |
|---|---|---|---|
| Idea / Brief | {{STATUS}} | {{DATE}} | `brief.md` |
| Specification | {{STATUS}} | {{DATE}} | `spec.md` — {{AC_COUNT}} acceptance criteria |
| Design Docs (post-spec) | {{STATUS}} | {{DATE}} | design.md, architecture-diagrams.md, flow.md |
| Planning | {{STATUS}} | {{DATE}} | `plan.md` — {{TASK_COUNT}} tasks, complexity {{TIER}} |
| Design Docs (post-plan) | {{STATUS}} | {{DATE}} | design.md updated (blast-radius + phases) |
| Implementation | {{STATUS}} | {{DATE}} | All plan tasks `[x]` |
| Design Docs (post-impl) | {{STATUS}} | {{DATE}} | testing.md, integration-guide.md, all verified |
| PR | {{STATUS}} | {{DATE}} | PR #{{N}} |
| Review | {{STATUS}} | {{DATE}} | {{VERDICT}} |
