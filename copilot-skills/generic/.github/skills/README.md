# AI Skills Index

Quick reference for all available skills in this repository. See [AGENTS.md](../../AGENTS.md) for full workflow routing.

## Layer 1 — Java/Spring Boot (Portable)

| Skill | Phase | Purpose | Invocation |
|---|---|---|---|
| `spec-writer` | 1 — Specification | Write feature spec from requirements | `"use the spec-writer skill for COM-XXX"` |
| `impl-planner` | 3 — Planning | Create implementation plan with task breakdown | `"use the impl-planner skill for COM-XXX"` |
| `implement-and-test` | 4 — Build | Implement code + write tests per plan | `"use the implement-and-test skill"` |
| `pr-preparation` | 5 — Ship | Run checklist, create commit, open PR | `"use the pr-preparation skill"` |
| `code-reviewer` | 6 — Review | Deep code review of a PR | `"use the code-reviewer skill — review PR #N"` |
| `blast-radius` | Sub-agent | Analyze change impact | `"use the blast-radius skill on [class]"` |
| `code-explorer` | Sub-agent | Navigate and explain code | `"use the code-explorer skill — [area]"` |
| `bug-tracer` | Fast-track | Trace bug to root cause | `"use the bug-tracer skill"` |
| `safe-refactor` | Fast-track | Plan and execute safe refactoring | `"use the safe-refactor skill"` |
| `onboarding` | Standalone | Walk through codebase architecture | `"use the onboarding skill"` |
| `architecture-diagrammer` | Sub-agent | Generate Mermaid architecture diagrams | `"use the architecture-diagrammer skill"` |
| `idea-to-spec` | Pre-Phase 1 | Turn rough idea into brief.md | `"use the idea-to-spec skill — [idea]"` |
| `party-mode` | Standalone | Multi-persona discussion for decisions | `"use the party-mode skill — [question]"` |
| `workflow-help` | Standalone | Route to correct skill | `"help"` |
| `local-review` | Standalone | Inline code review loop: comment → Copilot replies → todos → fix → clean | `"I left some review comments"` or `"use the local-review skill"` |

## Layer 2 — Repo/Domain [PROJECT-SPECIFIC]

| Skill | Phase | Purpose | Invocation |
|---|---|---|---|
| `lifecycle-flow` | 2 — Lifecycle | Map cross-service communication flows | `"use the lifecycle-flow skill"` |

## Support Files

| File | Location | Purpose |
|---|---|---|
| `SUB-AGENT-CONTRACTS.md` | `.github/skills/` | Auto-trigger protocols between skills |
| `coding-standards-core.md` | `implement-and-test/` | Always-loaded coding rules (~11KB) |
| `coding-standards-reference.md` | `implement-and-test/` | Full examples, on-demand (~55KB) |
| `test-patterns-core.md` | `implement-and-test/` | Always-loaded test rules (~4.5KB) |
| `test-patterns-reference.md` | `implement-and-test/` | Full test examples, on-demand (~36KB) |
| `java-patterns.md` | `blast-radius/` | Java/Spring grep patterns for DI/annotations |

## Don't Know Which Skill? → Say `"help"`

The `workflow-help` skill triages your request and routes you to the right skill.
