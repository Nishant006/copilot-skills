# AGENTS.md — AI Workflow Engine

<!--
  PURPOSE: Workflow orchestration for AI-assisted development.
  SCOPE: Phase definitions, skill routing, sub-agent contracts, developer interaction protocol.
  COUNTERPART: .github/copilot-instructions.md handles architecture knowledge and coding standards.
  PORTABILITY: Sections marked [PROJECT-SPECIFIC] must be rewritten per repository.
               All other sections are reusable across any Java/Spring Boot service.
  SUB-AGENT CONTRACTS: .github/skills/SUB-AGENT-CONTRACTS.md defines auto-trigger protocols.
  
  READING PRIORITY (for AI — read in this order, stop when you have what you need):
    0. §Survival Card (ALWAYS — non-negotiable rules that override everything)
    1. §Request Normalization Protocol (ALWAYS — before ANY action)
    2. §System + §Work-Type Router (determines which skill to invoke)
    3. §Phase Definitions OR §Fast-Track (only the relevant path for this request)
    4. §Human-First Interaction Protocol (ALWAYS — governs how to talk to user)
    5. §Skill Completion Protocol (read when finishing a skill)
    6. §Resume Protocol (read only when user says "continue"/"resume")
    7. Other sections: on-demand reference only
-->

---

## 🛡️ Survival Card (Non-Negotiable — ALWAYS Loaded)

> **This block MUST remain in AI memory at all times.** After context compaction, session resume, or any context loss — re-read this block FIRST before doing anything else. These 10 rules override everything below them.

1. **NEVER commit without `COMMIT YES`.** Show diff + message first. Wait for exact token.
2. **NEVER push without `PUSH YES`.** Show remote/branch first. Wait for exact token.
3. **NEVER skip a gate.** Every APPROVE, APPROVE-LIFECYCLE, COMMIT YES, PUSH YES is mandatory. No exceptions. No inference. No "proceeding since you seem to agree."
4. **ALWAYS decompose before acting.** Convert every user request into numbered tasks. Show the list. Wait for confirmation before executing.
5. **ALWAYS ask when ambiguous.** If two valid interpretations exist, STOP and ask. Never silently pick one.
6. **NEVER hallucinate.** Every factual claim must cite `file:line` or grep evidence. If you cannot verify, say `[ASSUMPTION]` or "I'm not sure."
7. **ALWAYS verify before marking done.** After completing each task, verify the outcome (grep, test, file check). A task is not done until verified.
8. **NEVER modify protected branches.** `release`, `master`, `main` are off-limits for direct commits/pushes.
9. **ALWAYS follow the Request Normalization Protocol.** Every user message goes through structured decomposition before execution begins.
10. **If context was compacted: re-read this Survival Card + the current skill's SKILL.md before continuing.** Never assume you remember the rules — verify.

> **Drift detection**: If you find yourself about to skip a step, bypass a gate, or proceed without verification — STOP. You have drifted. Re-read this card.

---

## 🔄 Request Normalization Protocol (Mandatory — Every Interaction)

> **DEFAULT BEHAVIOR**: Before executing ANY user request, the AI MUST convert it into a structured meta-prompt. This applies to every interaction, every skill, every phase — no exceptions.

### Step 1 — Parse & Restate

Restate the user's request in your own words to confirm understanding:
```
"I understand you want to: [restated request in precise terms]"
```

### Step 2 — Decompose into Atomic Tasks

Break the request into numbered, verifiable tasks:
```
Tasks:
1. [Specific action] → [Expected outcome] → [How to verify]
2. [Specific action] → [Expected outcome] → [How to verify]
...
```

### Step 3 — Identify Gates & Dependencies

For each task, identify:
- Which approval tokens are required (APPROVE, COMMIT YES, PUSH YES, etc.)
- Which tasks depend on which (task 3 needs task 2 done first)
- Which skills will be invoked

### Step 4 — Present & Confirm

Show the full decomposition to the user:
```
"Here's my plan:
[Numbered task list with gates marked]
Shall I proceed? Or would you like to adjust?"
```

### Step 5 — Execute Sequentially with Verification

- Execute each task ONE AT A TIME
- Verify completion before moving to next
- If any task fails or is ambiguous → STOP and ask
- Update progress after each task: "✅ Task 1 done. Starting Task 2..."

### When to Apply (ALWAYS — but scale appropriately)

| Request Complexity | Decomposition Level |
|---|---|
| Simple (one skill, one action) | Steps 1+2 compressed: "I'll [action]. Proceeding." — but still verify |
| Medium (multi-step, one skill) | Full Steps 1-5 |
| Complex (multi-skill, cross-phase) | Full Steps 1-5 + show dependencies |
| Ambiguous | STOP at Step 1 — ask for clarification before decomposing |

### Exception: Sub-Agent Invocations

When a skill auto-triggers a sub-agent (e.g., blast-radius), the sub-agent does NOT run the full normalization protocol. It executes its defined steps directly. Only top-level user requests require normalization.

---

## 🧭 Anti-Drift & Context Persistence Protocol

> **Problem**: After context compaction (session history summarized), the AI may forget rules, skip gates, or make assumptions. This protocol prevents that.

### Before Every Response (Self-Check)

Before generating any response that involves action (code change, skill execution, git operation, or decision), verify:

```
Self-check (silent — do not print):
□ Am I following the Survival Card rules?
□ Did the user's last message require Request Normalization?
□ Am I in the middle of a skill? If yes — which step am I on?
□ Are there pending approval gates I haven't received tokens for?
□ Am I about to assume something I should verify?
```

If ANY answer is unclear → re-read relevant section before proceeding.

### After Context Compaction (Detected Indicators)

You have experienced context compaction if:
- Your conversation history shows a `<summary>` block instead of full messages
- You cannot recall specific details from earlier in the conversation
- The user says "continue" or "resume" and you're unsure of state

**Recovery sequence:**
1. Re-read §Survival Card (always in this file)
2. Check for progress indicators: `plan.md` checkboxes, `features/` folder state, git branch
3. Report to user: "Context was compacted. I've re-loaded my rules. Current state: [detected state]. Shall I continue from [next step]?"
4. Do NOT silently proceed with assumptions about what was previously discussed

### Deterministic Execution Contract

To ensure consistent output regardless of which AI session handles the request:

1. **Same routing**: Given the same user message, the Work-Type Router MUST classify to the same work type. When genuinely ambiguous (could be 2+ types) → STOP and ask. Never infer silently.
2. **Same step order**: Each skill's steps are executed in numbered order. Never reorder, skip, or parallelize steps unless the SKILL.md explicitly says "these steps may run in parallel."
3. **Same output format**: Every skill defines its output format. Use it exactly. Never improvise a different structure.
4. **Same approval tokens**: The exact tokens are: `APPROVE`, `REVISE: [feedback]`, `APPROVE-LIFECYCLE`, `REVISE-LIFECYCLE: [feedback]`, `COMMIT YES`, `PUSH YES`, `APPROVE-REFACTOR`, `YES`, `NO`, `SKIP`. Accept ONLY these exact tokens at gates. Anything else → clarify: "I need one of: [valid tokens]. Which would you like?"
   **CRITICAL**: Affirmative synonyms (yes, go ahead, proceed, continue, ship it) are accepted at NON-SAFETY gates only. At commit/push/approve gates, ONLY the exact tokens listed above are accepted. Empty input / Enter is NEVER a valid confirmation.
5. **Same error handling**: When an error occurs, follow §Error Recovery Protocol exactly. Never improvise a workaround without presenting options.

## System

**Governing files** (read both before any task):

| File | Loaded by | Contains |
|---|---|---|
| `.github/copilot-instructions.md` | All Copilot contexts (auto) | Architecture, patterns, coding standards, verification rules |
| `AGENTS.md` (this file) | Copilot CLI + cloud agents | Workflow phases, skill routing, interaction protocol |
| `.github/skills/SUB-AGENT-CONTRACTS.md` | Referenced by skills | Auto-trigger protocols between skills |

**Instruction loading precedence** (later wins on conflict, except safety):
1. Global user: ~/.github/copilot-instructions.md OR ~/.copilot/copilot-instructions.md
2. Repo instructions: .github/instructions/*.instructions.md (all loaded, order undefined)
3. Repo copilot-instructions: .github/copilot-instructions.md
4. Repo workflow: AGENTS.md (this file)

Conflict resolution:
- Safety rules (commit/push gates, PII, secrets): ALWAYS follow the MORE RESTRICTIVE rule
- Workflow/scaling rules: AGENTS.md wins (it has project context)
- Graphify-first: The guardrail in graphify.instructions.md is MANDATORY when graph exists — no file may weaken it
- If genuinely uncertain which wins: ask the developer

**Required tools**: `./mvnw`, `git`, `gh`, `copilot` CLI, `graphify` (strongly recommended — graphify-first guardrail is active when graph exists)

**Environment setup** (auto-checked on first skill invocation):
> When any skill is invoked, check these prerequisites. If any are missing, stop and guide the user through setup. Always ask permission before installing anything.

| # | Tool | Check command | Install command | Purpose |
|---|---|---|---|---|
| 1 | Homebrew | `which brew` | [manual — brew.sh](https://brew.sh) | Package manager (macOS) |
| 2 | GitHub CLI | `which gh` | `brew install gh` | GitHub integration (PRs, issues) |
| 3 | GH Auth | `gh auth status` | `gh auth login` | GitHub authentication |
| 4 | Copilot (one of) | See below | See below | AI workflow engine |
| 5 | Graphify | `which graphify` | `uv tool install graphifyy` | Codebase knowledge graph (graphify-first guardrail — mandatory when graph exists) |
| 6 | Graphify graph | `test -f graphify-out/graph.json && find graphify-out/graph.json -mtime -7 | grep -q .` | `graphify .` | Graph freshness (<7 days; warn if stale but still use) |
| 7 | IDE Plugin | n/a (manual check) | Install GitHub Copilot plugin in IDE | IDE integration |
| 8 | Mermaid Plugin | n/a (manual check) | Install Mermaid plugin in IDE | Architecture diagrams |

**Copilot access** (any ONE of these is sufficient):
| Option | Check | Install | Best for |
|--------|-------|---------|----------|
| Copilot CLI (terminal) | `which copilot` | `brew install copilot-cli` | Terminal-first workflow (recommended) |
| VS Code + Copilot Chat | Extensions panel → "GitHub Copilot" installed | VS Code marketplace | VS Code users |
| IntelliJ + Copilot | Settings → Plugins → "GitHub Copilot" installed | JetBrains marketplace | IntelliJ/JetBrains users |

> All skills work identically regardless of which Copilot interface you use. The skills are loaded from `.github/` files which all Copilot interfaces read.

**Graphify integration** (NON-NEGOTIABLE when graph exists — `COPILOT_GRAPHIFY_ENABLED`):
> 🔒 **Graphify-First Guardrail**: When `graphify-out/graph.json` exists, the AI MUST use `graphify query/path/explain` BEFORE falling back to grep for any architecture, navigation, or relationship question. This is enforced by `.github/instructions/graphify.instructions.md`. See that file for the full enforcement protocol, decision tree, and fallback conditions. Disable ONLY with `export COPILOT_GRAPHIFY_ENABLED=0`.

| Copilot action | What to use |
|---|---|
| "Where is X?" / "How does Y work?" | `graphify query "<question>"` (per-repo graph) |
| "How does A relate to B?" | `graphify path "A" "B"` |
| "Explain the concept of X" | `graphify explain "X"` |
| "Which services share/use X?" | Global graph — `~/.graphify/global-graph.json` |
| Broad architecture review | Read `graphify-out/GRAPH_REPORT.md` |
| Graph missing or stale | Suggest: `copilot-skills graphify rebuild` (this repo) or `rebuild-all` (every repo + global) |

**Two-layer model** — queries resolve in this order:

| Layer | Path | Scope |
|---|---|---|
| Per repo | `<repo>/graphify-out/graph.json` | One service, full detail (AST + semantic) |
| Global | `~/.graphify/global-graph.json` | All services, repo-tagged, + cross-repo integration edges |

Start global to find **which** services are involved, then use that service's per-repo
graph for the detail. A per-repo graph contains only its own repo — if a query returns
another service's files, the graph is contaminated; rebuild with `copilot-skills graphify rebuild-all`.

> ⛔ **Never point several repos at one shared `graphify-out` via symlink.** It silently
> mixes every service's AST nodes into one unattributable graph. Cross-repo knowledge
> belongs in the global graph, which re-tags nodes per repo.


**Setup check protocol:**
```
On first skill invocation in a session:
  1. Run check commands 1-4 silently (skip row 4 — Copilot presence is implicit)
  2. Rows 5-6 (Graphify): If graphify is installed AND graph exists → graphify-first guardrail is ACTIVE (mandatory for architecture queries). If graphify is not installed → warn once, suggest install, proceed with grep fallback.
  3. If mandatory checks (1-4) ALL pass → proceed with skill
  4. If ANY mandatory check fails → present list of missing tools
  5. Ask: "I need to install: [list]. Proceed? [YES / NO / SKIP]"
  6. If YES → run install commands ONE AT A TIME, confirming each
  7. If NO → STOP. Report: "Cannot proceed — required tools missing. Install manually and retry."
  8. If SKIP → warn which skills may be limited, proceed anyway (at developer's risk)
  9. Tools 7-8 (IDE plugins) → remind user, cannot auto-install
```

**Build commands** [PROJECT-SPECIFIC] — single source of truth for all build/test references in this file:
```
BUILD_CMD    = ./mvnw clean package -DskipTests
TEST_CMD     = ./mvnw test
VERIFY_CMD   = ./mvnw verify
SINGLE_TEST  = ./mvnw test -Dtest=ClassName
```
> When porting to another repo, update these four commands and all `./mvnw` references below. See also `copilot-instructions.md` §Build & Test.

**Artifact directories**:
- `features/<ticket-id>/` — contains spec.md, plan.md, lifecycle.md (optional). Example: `features/COM-123/`
- `.github/kt/` — **single source of truth for project KT docs** (architecture, patterns, gotchas, setup, AI workflow); generated/updated by onboarding skill; committed and shared across team
- `postman/` — Postman collections and environment files (per-feature + main)

**Auto-detection protocol** (applies to ALL skills that need a ticket ID or feature reference):
```
1. TICKET ID detection (try in order, use first match):
   a. Explicit in user message: "for COM-123", "COM-123", "FEAT-456"
   b. Git branch: git branch --show-current → extract [A-Z]+-[0-9]+ pattern
   c. Feature folder: ls features/ → if exactly one folder, use it
   d. Multiple features + no branch match: "Which feature? I see: [list folders]" — STOP and ask
   e. No features/ dir exists: Ask user for ticket ID + description (create folder)
   f. NEVER auto-pick "most recent" without asking — if ambiguous, always ask

2. PROJECT STACK detection (for tech-agnostic skills):
   a. pom.xml / build.gradle → Java/Spring/Kotlin
   b. package.json → Node.js (check for express/fastify/nest)
   c. requirements.txt / pyproject.toml → Python (check for fastapi/django/flask)
   d. go.mod → Go
   e. Cargo.toml → Rust
   f. None found → ask user: "What's your project stack?"
   g. Use detected stack to adapt: grep patterns, test commands, build commands

3. BUILD COMMAND detection (override [PROJECT-SPECIFIC] block):
   a. If pom.xml exists → ./mvnw (or mvn)
   b. If package.json exists → npm run (check scripts section)
   c. If Makefile exists → make
   d. If go.mod exists → go build / go test
   e. Always grep the actual build file for exact command names
```

**Two-layer skill architecture**:
- **Layer 1** (Java/Spring Boot): Portable to any Java/Spring Boot project. Contains workflow methodology only.
- **Layer 2** (Repo/Domain): Specific to this codebase. Contains domain patterns, class names, integrations.

Each SKILL.md declares its layer in frontmatter. Layer 1 skills reference Layer 2 companion files marked `[PROJECT-SPECIFIC]`.

---

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
| 19 | **Cross-service flow** | "how do services communicate?", "map the flow between X and Y", "lifecycle diagram" | lifecycle-flow |
| 20 | **Check setup / tools** | "check my setup", "is everything installed?", "verify prerequisites" | Standalone: setup-check |

**For every work type**: Ask scope/impact questions FIRST. Verify blast radius where applicable. Never jump directly to implementation.

**Smart routing (natural language)**: The router must match USER INTENT, not exact phrases. If a user's message doesn't match any detection signal literally, infer the closest work type from context. Examples:
- "I just finished coding" → #16 Resume (detect: plan.md has all `[x]` → suggest pr-preparation)
- "Add logging to the rate limiter" → #2 Enhancement (Java code change) NOT #4 Config
- "This endpoint is slow" → #3 Bug fix (performance bug)
- "What skills exist?" → #18 Show skills
- "Let's discuss before we build" → #11 Party-mode → then #1 New feature

---

## Phase Definitions — Full Workflow

### Phase 1: SPECIFICATION

| | |
|---|---|
| **Skill** | `spec-writer` (Layer 1) |
| **Entry gate** | Developer provides feature description + Jira ID |
| **Clarifying questions** | Scope, channels, sites, business rules, out-of-scope boundary (see skill for full list) |
| **Sub-agents triggered** | `code-explorer` (Step 2 — always), `architecture-diagrammer` (Step 4 — if cross-cutting), `feature-docs` (after APPROVED — always) |
| **Exit gate** | `spec.md` exists with `Status: APPROVED` (developer types APPROVE or REVISE) |
| **Post-gate action** | `feature-docs phase:post-spec` auto-generates: README.md, design.md, architecture-diagrams.md, flow.md |
| **Handoff** | If spec says `Cross-cutting: Yes` → Phase 2. Otherwise → Phase 3. |

### Phase 2: LIFECYCLE FLOW (optional)

| | |
|---|---|
| **Skill** | `lifecycle-flow` (Layer 2) |
| **Entry gate** | `spec.md` with `Status: APPROVED` AND `Cross-cutting: Yes` |
| **Sub-agents triggered** | `code-explorer` (when component role unclear), `architecture-diagrammer` (after lifecycle.md created) |
| **Exit gate** | `lifecycle.md` created AND developer types `APPROVE-LIFECYCLE` (or `REVISE-LIFECYCLE: [feedback]` to iterate) |
| **Handoff** | → Phase 3 |
| **Skip condition** | Routine patterns (new validation rule, new config DTO field) MAY skip Phase 2 — but the AI MUST record the skip reason: "Skipping lifecycle (Phase 2): [reason — e.g., single-service change, no cross-cutting flow]". If the developer or AI is unsure whether it's truly routine → do NOT skip, run lifecycle-flow. |

### Phase 3: IMPLEMENTATION PLAN

| | |
|---|---|
| **Skill** | `impl-planner` (Layer 1) |
| **Entry gate** | `spec.md` with `Status: APPROVED`. If spec has `Cross-cutting: Yes` → `lifecycle.md` must exist with `Status: APPROVED` (developer typed `APPROVE-LIFECYCLE`). Reads `lifecycle.md` and `brief.md` if they exist. |
| **Step 0** | Complexity assessment: XS (inline) / S (minimal) / M (standard) / L (detailed + rollback) / XL (full + ADR). Developer confirms tier before proceeding. |
| **Sub-agents triggered** | `blast-radius` (Step 3 — for EVERY change point, see SUB-AGENT-CONTRACTS.md), `feature-docs` (after APPROVED — always) |
| **Exit gate** | `plan.md` exists with `Status: APPROVED` |
| **Post-gate action** | `feature-docs phase:post-plan` updates: design.md (blast-radius + phases), flow.md (planned paths) |
| **Handoff** | → Phase 4 |

### Phase 4: IMPLEMENT + TEST

| | |
|---|---|
| **Skill** | `implement-and-test` (Layer 1) |
| **Entry gate** | `plan.md` with `Status: APPROVED` (full workflow) OR direct entry (fast-track paths) |
| **Sub-agents triggered** | `blast-radius` (Step 8 — after implementation if risk is MEDIUM+), `feature-docs` (Step 9 — after all tasks done + verify passes — always for full workflow), `postman-collection` (Step 10 — when feature has API endpoints) |
| **Hard-stop triggers** | Class not found, spec contradicts code, test failure unresolvable, unclear requirements |
| **Exit gate** | ALL tasks marked `[x]` AND `./mvnw verify` passes AND zero pending hard-stops |
| **Post-gate action** | `feature-docs phase:post-impl` generates: testing.md, integration-guide.md; updates: flow.md, architecture-diagrams.md, design.md (all code-verified). `postman-collection` generates: collection + environment for new/modified endpoints. |
| **Handoff** | → Phase 5 |

### Phase 5: PR PREPARATION

| | |
|---|---|
| **Skill** | `pr-preparation` (Layer 1) |
| **Entry gate** | Phase 4 exit conditions met + feature docs fresh + postman collection fresh (Step 0 staleness gate) |
| **Sub-agents triggered** | `blast-radius` (Step 2 — always, for PR summary), `feature-docs` (Step 0 — if stale), `postman-collection` (Step 0 — if stale) |
| **Exit gate** | Dual-approval: (1) Developer types `COMMIT YES` after reviewing diff+message → commit created. (2) Developer types `PUSH YES` after seeing target remote/branch → push executed. (3) PR created on GitHub. |
| **Handoff** | → Phase 6 |

### Phase 6: CODE REVIEW

| | |
|---|---|
| **Skill** | `code-reviewer` (Layer 1, manual) + `copilot-enforce.yml` (automated) |
| **Entry gate** | PR exists on GitHub |
| **PR discovery** | If reviewer doesn't know the PR number: AI runs `gh pr list --state open` and presents a formatted table. Developer picks one or comma-separated numbers. |
| **Parallel review** | Comma-separated PR numbers → clarifying questions asked once → all reviews run in parallel → separate verdict per PR |
| **Sub-agents triggered** | `blast-radius` (Step 2 — always, on all changed classes) |
| **Automated** | GitHub Actions runs `./mvnw clean verify`, checks for TODO/FIXME in changed files |
| **Post to GitHub** | After each verdict, AI asks "Shall I post this to GitHub?" → runs `gh pr review [N] --approve/--request-changes/--comment` on YES |
| **Exit gate** | PR approved and merged |
| **Post-PR-creation prompt** | After Phase 5 creates the PR, AI MUST inform developer: "PR #N created. Phase 6 (code-review) is available — say `review PR #N` when ready, or request a teammate review." AI must NOT silently stop after PR creation. |

### Approval Protocol

All gated artifacts (spec.md, plan.md, lifecycle.md) use this status workflow:

```
Status: DRAFT     →  Developer types APPROVE  →  Status: APPROVED
Status: DRAFT     →  Developer types REVISE: [feedback]  →  AI updates, remains DRAFT
Status: APPROVED  →  Next phase can proceed
```

For Phase 2 specifically:
```
lifecycle.md created  →  Developer types APPROVE-LIFECYCLE  →  Phase 3 can proceed
lifecycle.md created  →  Developer types REVISE-LIFECYCLE: [feedback]  →  AI updates
```

---

## Fast-Track Path Definitions

### Bug Fix (skip spec + plan)

```
Entry:  Developer describes bug symptom
Steps:  1. bug-tracer → asks clarifying Qs (environment, timing, error, scope)
        2. bug-tracer traces root cause → triggers code-explorer + blast-radius
        3. implement-and-test (fix code + write regression test)
        4. pr-preparation (commit: fix(scope): description [JIRA-XXX])
Gates:  Tests must pass. Blast-radius on fix reviewed.
```

### Config / YAML Only (skip spec + plan + lifecycle)

```
Entry:  Developer describes config change. AI verifies NO Java logic is touched.
Steps:  1. implement-and-test → asks: which profiles? which sites? (clarifying Qs)
        2. Modify YAML/properties, run ./mvnw verify
        3. pr-preparation (commit: config(scope): description [JIRA-XXX])
Gates:  ./mvnw verify passes. All profile files updated consistently.
```

### Refactoring (skip spec + plan)

```
Entry:  Developer describes refactoring goal
Steps:  1. blast-radius (analyze impact on target class/method)
        2. safe-refactor → asks: type? scope? behavior change OK? (clarifying Qs)
        3. Execute bottom-up: leaf → callers → entry points, test after each
        4. pr-preparation (commit: refactor(scope): description [JIRA-XXX])
Gates:  All tests pass after each step. No behavior change. Coverage maintained.
```

### Dependency Upgrade (skip spec + plan)

```
Entry:  Developer specifies library and target version
Steps:  1. blast-radius (what uses this dependency? breaking API changes?)
        2. implement-and-test → asks: breaking changes expected? test scope?
        3. Update pom.xml, fix compilation, update tests
        4. pr-preparation (commit: build(deps): upgrade X from A to B [JIRA-XXX])
Gates:  ./mvnw verify passes. No new deprecation warnings introduced.
```

### Enhancement (partial workflow)

```
Entry:  Developer describes extension to existing feature
Steps:  1. spec-writer (reads existing implementation first, specs ONLY the delta)
        2. impl-planner (blast-radius on existing code being extended)
        3. implement-and-test → pr-preparation → code-review
Gates:  Same as full workflow. Spec must define OUT OF SCOPE to prevent scope creep.
```

### Understand Then Build (guided onboarding → development)

```
Entry:  New developer wants to understand the codebase before building a feature
Steps:  1. onboarding → asks role, experience, focus area
        2. architecture-diagrammer (auto-triggered) → visual overview
        3. code-explorer → deep-dive into specific areas relevant to ticket
        4. spec-writer → when developer is ready to build (enters full workflow at Phase 1)
Gates:  Developer explicitly says "I'm ready to build" before transitioning to spec-writer.
```

### Idea to Spec (rough idea → brief → spec)

```
Entry:  Developer has a rough idea but no formal requirements
Steps:  1. idea-to-spec → 5 structured discovery questions → brief.md
        2. spec-writer → reads brief.md, asks only unanswered questions → spec.md
        3. Normal workflow from Phase 1 (impl-planner → implement-and-test → ...)
Gates:  brief.md must exist before spec-writer. spec.md must be APPROVED before planning.
```

### Hotfix Emergency (streamlined workflow — safety rules still apply)

```
Entry:  Production incident requiring immediate fix
Steps:  1. Fix code → ./mvnw test (must pass)
        2. Show diff + commit message → wait for COMMIT YES → commit (fix(scope): hotfix description [JIRA-XXX])
        3. Show target remote/branch → wait for PUSH YES → push
        4. Create PR immediately (no spec/plan/lifecycle required)
        5. Create features/<ticket-id>/ with spec + retrospective AFTER stabilization.
           This is a MANDATORY follow-up. After PR is merged, AI MUST remind: "🔴 Post-hotfix follow-up required: create features/<ticket-id>/ with retrospective spec. Say 'create hotfix retrospective for <ticket>' when ready." Track as a pending obligation until completed.
Note:   This is the only path that skips spec/plan/lifecycle phases.
        🔒 Safety rules STILL APPLY: commit requires COMMIT YES, push requires PUSH YES.
        NEVER push directly to protected branches (release/master/main).
```

### API Testing (standalone)

```
Entry:  Developer wants to test the dispatcher API
Steps:  1. api-tester → asks: environment, test cases, recipients
        2. Pre-flight checks (cred.md, health check, comm-service path setup)
        3. Payload existence check — generate from user's curl if missing
        4. Layer 1 drift check  (detect-drift.js — always runs)
        5. Layer 3 FTL check    (ftl-checker.js  — runs if commServicePath configured)
        6. Layer 2 config check (config-validator.js — always runs unless CI=true or TC-VAL-*/TC-AUTH-*)
        7. Fire curls, capture responses
        8. Verify delivery (inbox verification for email)
        9. Generate versioned report
Gates:  cred.md populated. Environment reachable. Layer 1 DRIFT resolved before curl fires.
        Layer 2 MISSING/DISABLED resolves before curl fires. Layer 3 is always non-blocking.
```

---

### Resume Protocol

When user says "continue", "resume", "where were we?", or "what's next?" — the AI MUST auto-detect the current state:

```
1. DETECT current feature:
   - Check git branch name: extract ticket ID (COM-XXX, FEAT-XXX, etc.)
   - If exactly one `features/` subfolder exists, use it
   - If multiple `features/` subfolders exist and no branch match: ask "Which feature? I see: [list]"
   - NEVER auto-pick the most recent feature folder without asking

2. DETECT current phase by checking artifacts:
   a. No features/<ticket-id>/ folder       → suggest: idea-to-spec or spec-writer
   b. brief.md exists, no spec.md        → suggest: spec-writer (reads brief)
   c. spec.md exists, Status: DRAFT      → suggest: complete spec-writer (APPROVE or REVISE)
   d. spec.md APPROVED, Cross-cutting: Yes, no lifecycle.md or lifecycle DRAFT → suggest: lifecycle-flow
   e. spec.md APPROVED, no plan.md       → suggest: impl-planner
   f. plan.md exists, Status: DRAFT      → suggest: complete impl-planner (APPROVE)
   g. plan.md APPROVED, has [ ] tasks    → suggest: implement-and-test (show first pending task)
   h. plan.md all [x], verify not run    → suggest: implement-and-test (final verify)
   i. All [x] + verify passes           → suggest: pr-preparation
   j. PR exists, not merged              → suggest: code-reviewer
   k. PR merged                          → report: "Feature complete! 🎉"

3. REPORT to user:
   "📍 Feature: <ticket> | Phase: <detected phase> | Next: <suggested action>"
   "Would you like to proceed with <suggestion>?"

4. AUTO-DETECT ticket ID from branch:
   - Branch patterns: feat/COM-XXX/*, fix/COM-XXX/*, config/COM-XXX/*, refactor/COM-XXX/*, build/COM-XXX/*
   - Extract: first occurrence of [A-Z]+-[0-9]+ pattern
   - Use for: locating features/<ticket-id>/ folder, naming new feature folders
```

#### 3-Layer Drift Detection

The api-tester runs three automated checks before every test. Run them in this order:

```
Layer 1 — node detect-drift.js        (DTO field names vs payloads)
Layer 3 — node ftl-checker.js         (FTL template vars vs placeholders — only if commServicePath set)
Layer 2 — node config-validator.js    (MongoDB config state vs payload)
```

**Layer 1 output → action:**
```
✅ OK: 4  WARN: 0  DRIFT: 0  → Proceed — no action needed
✅ OK: 3  WARN: 1  DRIFT: 0  → Proceed — WARN is non-blocking
❌ DRIFT: 1+                  → STOP — must resolve before firing any curl
  REMOVED top-level field    → DTO field renamed/deleted — manual fix required
  REMOVED recipients field   → recipients block out of sync — manual fix required
  SYSTEM_ONLY in payload     → payload sends @Null field → dispatcher returns 400 — remove it
  REMOVED notificationData   → inner-class field changed — update payload manually
```

**Layer 3 output → action:**
```
✅ FTL MATCH                 → Proceed — placeholder keys match FTL DTO-bound variables
⚠️ MISSING IN PAYLOAD        → Informational — FTL references vars not in placeholders
                                Ask user: "Is this a placeholder the caller sends, or system-injected?"
⚠️ POSSIBLY UNUSED           → Informational — payload has keys not in FTL
                                Do NOT remove — may be used in lang variants
⚠️ No FTL files found        → emit visible WARN: "No FTL templates found for this event. If FTL validation is expected, verify commServicePath points to the correct repository." Do NOT suppress.
(all Layer 3 findings = WARN — never block testing)
```

**Layer 2 output → action:**
```
✅ VALID / cached            → Proceed immediately
⚠️ CONFIG CHANGED            → Non-blocking — show diff, ask developer to proceed
⚠️ TEMPLATE MISMATCH         → Non-blocking — template name in payload ≠ config's templates map
❌ MISSING                   → HARD STOP — config not in MongoDB, create it first
❌ DISABLED                  → HARD STOP — config globally disabled
❌ CHANNEL DISABLED          → HARD STOP — channel not enabled for this event
❌ Network error             → HARD STOP — VPN/connectivity issue
```

#### How to Resolve Each Drift Type

| Type | Script / Action | When to use |
|---|---|---|
| Layer 1: New optional field missing | `node detect-drift.js --fix` | Safe: adds `{{FIELD_NAME}}` placeholder automatically |
| Layer 1: REMOVED / renamed field | Edit payload manually | Check git blame; update field name |
| Layer 1: SYSTEM_ONLY in payload | Remove field from payload JSON | These are `@Null` — dispatcher rejects them |
| Layer 1: Deprecated field present | `node detect-drift.js --fix` or leave | Non-blocking — migrate when convenient |
| Layer 2: Config missing/disabled | Fix MongoDB config, then re-run | Config must exist and be enabled before testing |
| Layer 2: Template mismatch | Verify template name in MongoDB config | Non-blocking — check `communicationConfig.{channel}Config.templates` |
| Layer 3: Missing in payload | Verify if system-injected or caller-provided | Non-blocking — add to placeholders only if caller must send it |

#### Drift Stop Trigger (HARD STOP)

**When `❌ DRIFT` (Layer 1) is detected**: STOP. Do not proceed to curl execution.
```
❌ Drift in {file}:
  REMOVED: {fields} — no longer in CommunicationDTO.java

Options:
  [Show DTO definition]  [Auto-fix new fields]  [Skip — intentional]
```

**When `❌ MISSING / DISABLED / CHANNEL DISABLED` (Layer 2) is detected**: STOP.
```
❌ Config validation failed for {configId}:
  {reason}

Fix the config issue in MongoDB, then re-run api-tester.
```

Only continue after developer resolves or explicitly skips.

---

## Skill Registry

### Migrated Skills (18) — All Available

#### Layer 1 — Java/Spring Boot Skills (Portable)

| Skill | Phase | Sub-Agents Triggered | Auto-triggered by | Does NOT |
|---|---|---|---|---|
| `implement-and-test` | 4 | blast-radius (Step 8), feature-docs (post-impl), postman-collection (post-impl) | — (manual) | Commit, skip tests |
| `blast-radius` | Sub-agent | — (leaf) | implement-and-test, code-reviewer, safe-refactor, impl-planner, pr-preparation, bug-tracer, postman-collection | Modify code |
| `code-explorer` | Sub-agent | — (leaf) | onboarding, architecture-diagrammer, bug-tracer, idea-to-spec, spec-writer, lifecycle-flow, feature-docs | Modify code |
| `onboarding` | Standalone | code-explorer (Steps 2.5/3.5/5/6), architecture-diagrammer (Step 2, Step 7.2) | — (manual) | Write application code; generates/updates .github/kt/ only on explicit YES; smart update: SKIP/UPDATE/REWRITE by freshness + source drift |
| `architecture-diagrammer` | Sub-agent | code-explorer (Step 2) | onboarding, spec-writer, lifecycle-flow, pr-preparation, feature-docs | Modify code |
| `workflow-help` | Standalone | — (router only) | — (default fallback for ambiguous requests) | Execute skills; only routes |
| `spec-writer` | 1 | code-explorer (Step 3), architecture-diagrammer (Step 4 — if cross-cutting), feature-docs (post-spec — after APPROVED) | — (manual) | Implement features; creates spec.md only |
| `impl-planner` | 3 | blast-radius (Step 3 — for EVERY change point), feature-docs (post-plan — after APPROVED) | — (manual) | Write code; creates plan.md only |
| `pr-preparation` | 5 | blast-radius (Step 2), feature-docs (staleness gate), postman-collection (staleness gate) | — (manual) | Merge PRs; creates commit + branch + PR draft |
| `code-reviewer` | 6 | blast-radius (Step 2 — on all changed classes) | — (manual or PR event) | Approve without analysis; always gives verdict |
| `bug-tracer` | Fast-track | code-explorer (Step 2), blast-radius (Step 7) | — (manual) | Fix bugs; traces root cause only |
| `safe-refactor` | Fast-track | blast-radius (Phase 1 — pre-check) | — (manual) | Modify behavior; structural changes only |
| `idea-to-spec` | Pre-Phase 1 | code-explorer (Step 3 — pattern check) | — (manual) | Write specs; creates brief.md only |
| `party-mode` | Standalone | — (discussion only) | — (manual) | Modify files; discussion and analysis only |
| `setup-check` | Standalone | — (leaf) | — (manual or first invocation) | Install without permission |
| `feature-docs` | Sub-agent | code-explorer, architecture-diagrammer | spec-writer (post-APPROVED), impl-planner (post-APPROVED), implement-and-test (post-completion, re-invocation) | Modify application code; generates/updates feature docs only |
| `postman-collection` | Sub-agent | blast-radius | implement-and-test (post-completion, re-invocation), pr-preparation (staleness gate) | Modify application code; generates/updates Postman collections only |

#### Layer 2 — Repo/Domain Skills [PROJECT-SPECIFIC]

> These skills are defined per-project in `projects/<name>/.github/skills/`. They are NOT in the generic skills directory. Projects opt-in by creating their own SKILL.md.

| Skill | Phase | Sub-Agents Triggered | Auto-triggered by | Does NOT |
|---|---|---|---|---|
| `api-tester` | Standalone | — (self-contained) | — (manual) | Modify application code; fires curls, detects payload drift, generates payload scaffolds, runs P0 CI |
| `lifecycle-flow` | 2 | code-explorer, architecture-diagrammer | spec-writer (when Cross-cutting: Yes) | Implement features; maps cross-service flows only |

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

> **Note**: Users do NOT need to remember exact skill names. Any natural language phrasing that matches the "Also triggered by" column will auto-route to the correct skill via the Work-Type Router.

---

## Human-First Interaction Protocol

### Clarifying Questions (mandatory)

Every skill has a **Clarifying Questions** section. These are NOT optional. The AI MUST ask before proceeding. The only exception is when the developer's initial message already answers all questions.

### Smart Defaults (reduce question fatigue)

When a well-established pattern exists, propose a plan instead of a questionnaire:

```
"I'll follow the [pattern] pattern. My plan:
  1. [specific action + file path]
  2. [specific action + file path]
  3. [specific action + file path]
Type YES to proceed, or tell me what's different."
```

Use smart defaults ONLY when: pattern is well-established, only one reasonable approach exists, or change is purely additive.

### When to STOP and Ask

- Work type is ambiguous
- Scope is ambiguous (unclear which areas are affected)
- Multiple valid implementation approaches exist
- Change affects core components
- Any hard-stop trigger from `copilot-instructions.md` §Verification Protocol fires

### 🔒 Absolute Safety Rules (Non-Negotiable)

> These rules override everything. No skill, sub-agent, or fast-track path may bypass them.

1. **NEVER commit without `COMMIT YES`.** Before every `git commit`, show the staged diff summary and commit message. Wait for exact token `COMMIT YES`.
2. **NEVER push without `PUSH YES`.** Before every `git push`, show the target remote/branch and commit(s) to be pushed. Wait for exact token `PUSH YES`.
3. **NEVER operate on protected branches directly.** The `release`, `master`, and `main` branches are protected. NEVER checkout, commit to, push to, or force-push to these branches. All work must happen on feature/refactor branches.
4. **NEVER auto-merge or rebase onto protected branches.** If a merge/rebase is needed, present the plan and wait for approval.
5. **NEVER delete branches without user approval.** Show which branch will be deleted and why.
6. **If in doubt, STOP.** If any git operation feels risky (force push, reset, rebase with conflicts), stop and ask.

**Enforcement**: Every skill that produces code changes must follow this sequence:
```
Code changes → show diff + proposed commit message → wait for COMMIT YES → commit
→ show target remote/branch + commits to push → wait for PUSH YES → push
```
Any deviation from this sequence is a protocol violation.

### 🧠 Anti-Hallucination Rule (Universal)

> This rule applies to ALL skills, ALL phases, ALL outputs.

1. **Every nontrivial factual claim must cite its source.** When stating that a class exists, a method is called, a config is used, or a pattern applies — provide `file:line` or `grep` evidence. If you cannot cite a source, explicitly mark the statement as `[ASSUMPTION]`.
2. **Never invent class names, method signatures, or config keys from memory.** Always grep/verify before referencing. If grep returns no results, say so — do not fabricate.
3. **Architecture claims require graph-first verification.** Statements like "X calls Y" or "Z depends on W" must be verified by `graphify path` FIRST (when graph exists), then `grep` or actual file contents as fallback. Using grep alone when a graph exists violates the graphify-first guardrail.
4. **When unsure, say "I'm not sure" rather than guessing.** Uncertainty is always preferable to confident hallucination.

**Work-type-specific stop triggers** [PROJECT-SPECIFIC]:
- **New feature**: When config ID pattern is not in Constants — stop and ask if it should be added
- **Enhancement**: When existing controller/service already handles the requested behavior — stop and ask what is different
- **Bug fix**: When bug cannot be reproduced from description alone — stop and ask for logs/steps
- **Config change**: When change affects core pipeline classes — stop and confirm this is truly config-only
- **Refactor**: When blast-radius returns CRITICAL — stop and require APPROVE-REFACTOR before proceeding
- **Dependency upgrade**: When upgrade has known breaking API changes — stop and present migration guide

**Dispatcher-specific stop triggers** [PROJECT-SPECIFIC]:
- **API key missing**: When `cred.md` does not contain valid API key for the target environment — HARD STOP, ask developer to populate credentials
- **Config ID not found (Layer 2)**: When `config-validator.js` reports `❌ MISSING` — HARD STOP, confirm config ID and environment. Config must exist in MongoDB before testing.
- **Config disabled (Layer 2)**: When `config-validator.js` reports `❌ DISABLED` or `❌ CHANNEL DISABLED` — HARD STOP, resolve in MongoDB before proceeding.
- **Layer 1 drift detected**: When `detect-drift.js` reports `❌ DRIFT` — HARD STOP before firing any curl. Show drift summary, present the 3-choice menu (Show DTO / Auto-fix / Skip). Do NOT proceed until developer resolves or explicitly skips. See "3-Layer Drift Detection" above.
- **Layer 3 findings**: When `ftl-checker.js` reports `⚠️ MISSING IN PAYLOAD` — do NOT add placeholder keys automatically. Ask developer whether the variable is system-injected by comm-service or must be provided by the API caller. Layer 3 never blocks.

---

## Skill Completion Protocol (mandatory)

Every skill MUST execute these 4 components at the end of its run, in this order. This is enforced, not optional.

**Exceptions** (documented here — the ONLY cases where completion protocol is reduced):
- **Auto-triggered sub-agents** (blast-radius, code-explorer, architecture-diagrammer when invoked by a parent skill): Return results to parent. Skip Components 2-4 (parent handles next-steps). Component 1 (checklist) is still required.
- **setup-check when auto-triggered**: If ALL checks pass, emit a single-line confirmation: "✅ Prerequisites verified (brew ✓ gh ✓ copilot ✓ graphify ✓)". Full output is suppressed on pass, but the one-liner provides audit evidence. If any check fails or setup-check is manually invoked, full protocol applies.

Each skill adds a `## Skill Completion` section in its SKILL.md with skill-specific next-steps and escalation tables that complement this protocol.

**Anti-drift note for all skills**: If the AI detects it has been running for an extended period (>10 steps, or context feels compressed), it MUST pause and self-check against §Survival Card before presenting the completion checklist. This prevents drift in long-running skills like implement-and-test or onboarding.

### Component 1 — ✅ Completion Checklist

Present a checkbox-style checklist at the end of every skill run:

```
✅ [SkillName] Completion:
- [x] All steps executed (Steps 1–N)
- [x] All verifiable outcomes confirmed
- [x] Output delivered in specified format
- [x] Trade-off summary presented (or marked N/A)
- [x] Next steps menu presented
- [x] Save-as-MD offered
```

If any item is `[ ]`: explain what is missing and how to resolve before proceeding.

### Component 2 — 📊 Trade-off Summary

**When to present:** Any skill that analyzes a change, risk, decision, or option.
**When to skip:** Purely informational skills (see table below).

| Always Present Trade-off | Skip Trade-off |
|---|---|
| blast-radius, safe-refactor, bug-tracer, impl-planner, code-reviewer, pr-preparation, implement-and-test, spec-writer, idea-to-spec, party-mode, api-tester | onboarding, code-explorer (read-only), workflow-help, architecture-diagrammer |

Template:

```markdown
### 📊 Trade-off Summary

| Dimension | Current State | Proposed Change | Do Nothing | Why It Matters |
|---|---|---|---|---|
| [dim 1] | [what exists] | [what changes] | [risk of inaction] | [impact] |
| [dim 2] | ... | ... | ... | ... |

**Recommendation**: [One sentence: what to do and why.]
```

### Component 3 — 🔀 Next Steps Menu

**MANDATORY** — always present at end of every skill run. Never end with a single suggestion.

Requirements:
- Minimum 4 options, maximum 6
- Always include: natural next step, go deeper, alternative path, get help
- Every option must include the exact invocation phrase (`"use the X skill — Y"`)
- End with `⭐ My recommendation:` — one highlighted option with rationale

Template:

```markdown
### 🔀 Next Steps

| # | Option | Skill | Say This | When to Use |
|---|---|---|---|---|
| 1 | [Natural next step] | `skill-name` | `"exact invocation phrase"` | [context] |
| 2 | [Go deeper] | `skill-name` | `"exact invocation phrase"` | [context] |
| 3 | [Alternative path] | `skill-name` | `"exact invocation phrase"` | [context] |
| 4 | [Discuss tradeoffs] | `party-mode` | `"use the party-mode skill — [topic]"` | [context] |
| 5 | [Get help] | `workflow-help` | `"help"` | Unsure what to do |

⭐ **My recommendation**: Option N — [one sentence why].
```

### Component 4 — ⚡ Escalation Path

Skill-specific failure recovery. Each skill defines its own escalation table in its SKILL.md.

Template:

```markdown
### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| [Step/Phase] | [Specific failure] | [Exact recovery action] |
| Any step | Unclear requirements | HARD STOP → ask developer for clarification |
| Any step | Tool failure | Retry once → report exact error → suggest manual alternative |
```

### Save-as-MD Behaviour

After presenting the completion checklist and next-steps menu, ALWAYS ask:

> "Would you like me to save this analysis as an MD file? (YES — specify path / NO)"

Rules:
- Ask once per skill run, at the very end (after next-steps menu)
- If YES: save to the path the developer specifies, or suggest a sensible default (e.g., `features/<ticket-id>/blast-radius-report.md`)
- If NO: continue without saving — no follow-up
- If invoked as a sub-agent by another skill: do NOT ask (the parent skill manages output)

### How Skills Reference This Protocol

Each SKILL.md adds a `## Skill Completion` section at the end (before `## References`):

```markdown
## Skill Completion

> Follow the **Skill Completion Protocol** in `AGENTS.md` §Skill Completion Protocol.

### 🔀 Next Steps (skill-specific)

| # | Option | Skill | Say This | When to Use |
|---|---|---|---|---|
| 1 | ... | ... | ... | ... |

⭐ **My recommendation**: ...

### ⚡ Escalation Path (skill-specific)

| Stuck At | What Happened | Do This |
|---|---|---|
| ... | ... | ... |
```

This keeps the protocol DRY — universal rules defined once here, skill-specific routing in each SKILL.md.

---

## Checkpoint & Resume Protocol

Long-running skills (implement-and-test, onboarding, code-reviewer, api-tester) risk losing progress if the AI's context window fills or the session is interrupted. This protocol ensures they can resume from where they stopped.

### How It Works

1. **After each major step/task**, the skill checks for an existing progress indicator:
   - `implement-and-test`: Uses `[x]` checkboxes in `plan.md` — already a checkpoint mechanism. On re-invocation, read plan.md and start at first `[ ]`. Before skipping, verify the last completed task's artifact exists (file on disk or test passes). If verification fails, report: "⚠️ Task [X] was marked done but artifact is missing. Re-run? [YES / SKIP]"
   - `onboarding KT generation`: Uses file existence — SKIP fresh files (< 30 days AND no source changes since last generation — check via git log --since="$(stat -f %Sm -t %Y-%m-%d FILE)" src/). If source changed since KT was generated: UPDATE regardless of age.
   - `code-reviewer`: Uses phase completion — if invoked with `"resume review of PR #N"`, the AI checks the PR comment history for previously posted phase results.
   - `api-tester`: Uses versioned reports — if `.github/skills/api-tester/reports/` contains a report for the same config ID and environment, the AI reads the last report to detect drift and resume from the last successful test case.

2. **On re-invocation**, the skill MUST:
   - Read the existing progress indicators before starting
   - Report: "Found progress from a previous run. Completed: [list]. Resuming from: [next step]."
   - Ask: "Should I resume from where I left off, or start fresh?"

3. **Progress is always human-readable** — no opaque JSON files. Progress lives in artifacts the developer can inspect:
   - plan.md checkboxes (implement-and-test)
   - File existence + `Last updated` headers (onboarding)
   - PR comment history (code-reviewer)
   - Versioned report files with timestamps (api-tester)

### Skills That MUST Support Resume

| Skill | Progress Indicator | Resume Mechanism |
|---|---|---|
| `implement-and-test` | `[x]` checkboxes in `plan.md` | Read plan.md → skip `[x]` tasks → start at first `[ ]`. Before skipping, verify the last completed task's artifact exists (file on disk or test passes). If verification fails, report: "⚠️ Task [X] was marked done but artifact is missing. Re-run? [YES / SKIP]" |
| `onboarding` (KT gen) | File existence + `Last updated` date | List `.github/kt/` files → SKIP fresh files (< 30 days AND no source changes since last generation — check via git log --since="$(stat -f %Sm -t %Y-%m-%d FILE)" src/). If source changed since KT was generated: UPDATE regardless of age. |
| `code-reviewer` | Phase completion notes | Check if phases 1-5 already posted → resume at next phase |
| `spec-writer` | `spec.md` existence | If spec.md exists with `Status: DRAFT`, offer to continue editing |
| `impl-planner` | `plan.md` existence | If plan.md exists with `Status: DRAFT`, offer to continue editing |
| `api-tester` | Versioned report in `reports/` | Read last report → detect payload drift → resume from last successful test case or re-run all if drift detected |
| `feature-docs` | File existence in `features/<ticket-id>/` | Check which docs exist → generate only missing ones; update existing with new phase data |

### Execution Log (traceability)

When working within a `features/<ticket-id>/` directory, skills MUST append to `features/<ticket-id>/execution-log.md` after each major action. This provides a traceable audit trail from requirements to PR.

**Format:**

```markdown
## Execution Log — <ticket-id>

| Timestamp | Skill | Action | Key Decision | Outcome |
|---|---|---|---|---|
| 2026-04-21 14:30 | spec-writer | Created spec.md | Scope: push + SMS only | Status: DRAFT |
| 2026-04-21 14:45 | spec-writer | Developer APPROVED | — | Status: APPROVED |
| 2026-04-21 15:00 | impl-planner | Created plan.md | 4 tasks, complexity: M | Status: DRAFT |
```

**Rules:**
- Append-only — never modify previous entries
- One row per major action (skill start, key decision, approval, completion)
- If no `features/<ticket-id>/` directory exists (e.g., standalone skills like onboarding), skip the log
- If invoked as a sub-agent, let the parent skill handle logging

---

### Jira Format [PROJECT-SPECIFIC]
`COM-XXX` (e.g., COM-575, COM-612)

### Branch Naming [PROJECT-SPECIFIC]
```
feat/COM-XXX/short-description
fix/COM-XXX/short-description
config/COM-XXX/short-description
refactor/COM-XXX/short-description
build/COM-XXX/short-description
```
> When porting: replace `COM-XXX` with your Jira prefix and adjust branch prefixes to match your team convention.

### Commit Convention
```
feat(scope): description [COM-XXX]
fix(scope): description [COM-XXX]
config(scope): description [COM-XXX]
refactor(scope): description [COM-XXX]
build(deps): description [COM-XXX]
```

---

## CI/CD

- **Azure Pipelines** (`cicd/`): Primary CI/CD — build, test, deploy to AKS.
- **GitHub Actions** (`copilot-enforce.yml`): PR quality gate — compile + test + docs drift check against `.github/kt/architecture.md`.
- Both coexist by design. Azure deploys. GitHub enforces PR quality for the AI workflow.

---

## Error Recovery Protocol (shared — all skills inherit)

All skills follow this error handling behavior. Individual skills do NOT need their own `## Error Handling` section — they reference this protocol.

### Error Types (AI-facing — what to do when things go wrong)

| Error Type | Action |
|---|---|
| **Entry condition not met** | HARD STOP. Report exactly what is missing. Suggest the prerequisite skill. |
| **File/class not found** | Verify spelling. Try alternative names. If still not found: HARD STOP and ask user. |
| **Test failure** | Analyze failure. Propose fix. Re-run. If fails 3 times: HARD STOP with full error output. |
| **Ambiguous choice** | STOP. Present all options. Wait for user choice. Never pick silently. |
| **Sub-agent failure** | Report the failure and ask how to proceed: retry, skip, or manual alternative. |
| **Sub-agent returns empty** | Report: "blast-radius/code-explorer returned no results for [target]. Possible causes: 1) target doesn't exist, 2) dynamic dispatch hides callers, 3) target is unused code. How should I proceed?" |
| **Tool unavailable** | Fall back to alternative (e.g., if `ask_user` unavailable → plain text prompt). If no fallback exists: HARD STOP. |
| **Companion doc missing** | Proceed without it — use grep/annotation-based discovery instead. Do NOT fail. |
| **Network/auth error** | HARD STOP. Report error. Suggest diagnostic steps (VPN, auth refresh, etc). |
| **Context window limit** | Save progress indicators (checkboxes, file markers). Report: "Reached context limit at Step N. Say `continue` to resume." Then follow §Anti-Drift & Context Persistence Protocol. |
| **Merge conflict on branch** | Run `git status`. List conflicted files. Show both sides. Ask developer which resolution. NEVER auto-resolve. After resolution, run verify. |
| **Stale branch (behind target)** | Before Phase 4, check `git log HEAD..origin/release --oneline`. If behind >5 commits, warn and recommend rebase. If behind > 10 commits: HARD STOP — require explicit override: "Branch is 10+ commits behind. Rebase first? [YES to rebase / SKIP to continue anyway]" |

> Every skill inherits this protocol. Skills only add skill-specific escalation paths in their own `## Skill Completion` → `### ⚡ Escalation Path` section.

### Common Recovery Scenarios (developer-facing — what to type)

| Symptom | Recovery |
|---|---|
| "Entry condition not met" | AI tells you what is missing and suggests the correct starting skill |
| spec.md still DRAFT | Type `APPROVE` to approve, or `REVISE: [feedback]` to iterate |
| Missing plan.md | Run impl-planner first, or use bug-fix/config fast-track to skip it |
| ./mvnw test fails | AI analyzes failure, proposes fix, re-runs. If stuck: HARD STOP with question. |
| "I don't know which skill" | Describe your goal. AI routes via Work-Type Router above. Or say `"help"` to invoke workflow-help skill. |
| Stale docs | AI runs `onboarding skill` → Level 2+ → YES — smart update: SKIP/UPDATE/REWRITE by freshness + source drift |
| Skill produces wrong output | Re-run artifact-generating skills directly; for side-effect skills (`api-tester`, `pr-preparation`, `code-reviewer`), verify prior run state first to avoid duplicates. If the problem is systematic, file a workflow feedback issue. |
| API test cred.md missing | api-tester stops with: "cred.md not found or incomplete. Please populate API key and base URL for [environment]." |
| Config ID not in MongoDB | api-tester stops with: "Config ID [X] not found. Verify the ID exists in [environment] MongoDB. Run: `db.communicationConfigs.findOne({configId: 'X'})`" |

### Idempotency Guarantee

**Artifact-generating skills are idempotent.** Running these skills twice on the same input:
- **Does NOT** create duplicate files (overwrites existing spec.md, plan.md, lifecycle.md)
- **Does NOT** corrupt state (re-running implement-and-test re-checks already-completed tasks)
- **SAFE** to re-run after an interruption, timeout, or partial failure

**Side-effect skills are NOT fully idempotent** — re-running may cause duplicates:
- `api-tester`: Re-fires real HTTP requests (may trigger duplicate notifications)
- `pr-preparation`: May create duplicate PRs if branch/PR check fails
- `code-reviewer`: May post duplicate review comments to GitHub
- `setup-check`: Safe to re-run (installs are idempotent)

Re-run side-effect skills only after verifying prior run state.

---

## Adding a New Skill — Recipe

Follow this checklist when creating a new skill. Every step is required.

### 1. Create Skill Directory

```
.github/skills/<skill-name>/SKILL.md        # Required — must follow standard structure
.github/skills/<skill-name>/companion.md     # Optional — project-specific patterns [PROJECT-SPECIFIC]
```

### 2. SKILL.md Standard Structure

Every SKILL.md must contain these sections in order:

```markdown
---
name: <skill-name>
description: "<one-line purpose>"
last-updated: YYYY-MM-DD
layer: 1 | 2
triggers-sub-agents: [<list>]
triggered-by: [<list>]
---
## Purpose
## Entry Conditions
## Clarifying Questions
## Step-by-Step Process
## Exit Conditions / Done Definition
## Sub-Agents
## Example Invocation
## What I Will NOT Do
## Output Format (if applicable)
## Skill Completion                        # Reference AGENTS.md §Skill Completion Protocol
## References
```

### 3. Register the Skill

Update these files (all required):

| File | Section to Update | What to Add |
|---|---|---|
| `AGENTS.md` | §Skill Registry table | Row with skill name, phase, sub-agents, triggers, constraints |
| `AGENTS.md` | §Quick Reference: Which Skill Do I Use? | Row with "I want to…" → skill name |
| `AGENTS.md` | §Work-Type Router (if new work type) | New row mapping detection signal → route |
| `.github/copilot-instructions.md` | §File Responsibility Map (if companion exists) | Add companion file entry |
| `AI-WORKFLOW.md` | §4. Skill Map | Add to the skill list |

### 4. Wire Sub-Agent Contracts (if applicable)

If the new skill triggers or is triggered by other skills:
- Update `.github/skills/SUB-AGENT-CONTRACTS.md` — add trigger protocol
- Update the **other** skill's `triggers-sub-agents` or `triggered-by` frontmatter

### 5. Verify

```bash
# Confirm skill file exists and has correct frontmatter
head -10 .github/skills/<skill-name>/SKILL.md

# Confirm no orphan references
grep -rn "<skill-name>" .github/ AGENTS.md AI-WORKFLOW.md

# Confirm registry consistency
grep -c "skills/" AGENTS.md   # Should reflect new total
```

---

## Portability — Adapting to Another Repository

**Change** (project-specific):
- `.github/copilot-instructions.md` sections marked [PROJECT-SPECIFIC]
- `.github/kt/` docs (regenerate using `onboarding skill` → Level 2+ → YES)
- `AGENTS.md` §Build commands block (update `./mvnw` → your build tool) and §Conventions (Jira format, branch prefix)
- Companion files in `.github/skills/` marked [PROJECT-SPECIFIC]
- Issue templates (adapt to the new service domain)
- Layer 2 skills (api-tester — rewrite for the new domain)

**Keep as-is** (reusable):
- `AGENTS.md` Work-Type Router, Phase Definitions, Human-First Protocol, Error Recovery
- All Layer 1 SKILL.md files (workflow-generic — search for `[PROJECT-SPECIFIC]` comments/tags to find sections requiring updates; examples using project class names are illustrative and can be replaced)
- `.github/skills/SUB-AGENT-CONTRACTS.md` (reusable protocol)
- `.github/workflows/copilot-enforce.yml` (adjust build command and [PROJECT-SPECIFIC] count commands)

---
## Project Context (communication-dispatcher)

SERVICE CONTEXT: communication-dispatcher is a Spring Boot 3.4.5 / Java 21 API gateway.
It receives notification REST requests, validates them, resolves config from MongoDB/Redis,
and publishes to Kafka. The downstream communication-service processes and delivers notifications.

### Additional Required Tools
- `node` (for yopmail inbox checking via easy-yopmail)

### Layer 2 Domain Classes (Critical + High Risk)
RateLimitFilter, SecurityFilter, CommunicationController, KafkaProducer,
ProducerServiceImpl, ConfigServiceCircuitBreakerImpl, RequestValidatorServiceImpl,
CustomRequestContextFilter, RateLimitServiceImpl, RateLimitPolicyCache, ConfigService, SecurityConfig

### Site Codes
mafuae, mafsau, mafegy, mafjor, mafgeo, mafpak, mafqat, mafkwt, mafbhr, maflbn, mafken, mafomn, mafuzb, mafarm, mafuga

### Extended Environment Setup

| # | Tool | Check command | Install command | Purpose |
|---|---|---|---|---|
| 6 | Node.js | `which node` | `brew install node` | yopmail inbox checker |
| 7 | easy-yopmail | `cd .github/skills/api-tester && npm list easy-yopmail` | `cd .github/skills/api-tester && npm install` | Automated email verification |
| 8 | IDE Plugin | n/a (manual check) | Install GitHub Copilot plugin in IntelliJ | IDE integration |
| 9 | Mermaid Plugin | n/a (manual check) | Install Mermaid plugin in IntelliJ | Architecture diagrams |
