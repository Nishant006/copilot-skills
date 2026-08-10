# AGENTS.md — AI Workflow Engine

<!--
  PURPOSE: Workflow orchestration for AI-assisted development.
  VERSION: 2.1.0
  LAST UPDATED: 2026-06-09
  SCOPE: Phase definitions, skill routing, sub-agent contracts, developer interaction protocol.
  COUNTERPART: .github/copilot-instructions.md handles architecture knowledge and coding standards.
  PORTABILITY: Sections marked [PROJECT-SPECIFIC] must be rewritten per repository.
               All other sections are reusable across any Java/Spring Boot service.
  SUB-AGENT CONTRACTS: .github/skills/SUB-AGENT-CONTRACTS.md defines auto-trigger protocols.
  
  READING PRIORITY (for AI — read in this order, stop when you have what you need):
    0. §Survival Card (ALWAYS — non-negotiable rules that override everything)
    1. §Request Normalization Protocol (ALWAYS — before ANY action)
    1b. §Anti-Drift & Context Persistence Protocol (ALWAYS — self-check before every response)
    2. §System + §Work-Type Router (determines which skill to invoke)
    3. §Phase Definitions OR §Fast-Track (only the relevant path for this request)
    4. §Human-First Interaction Protocol (ALWAYS — governs how to talk to user)
    5. §Skill Completion Protocol (read when finishing a skill)
    6. §Resume Protocol (read only when user says "continue"/"resume")
    7. §Error Recovery Protocol (read on any failure/error)
    8. Other sections: on-demand reference only
-->

---

## 🛡️ Survival Card (Non-Negotiable — ALWAYS Loaded)

> **This block MUST remain in AI memory at all times.** After context compaction, session resume, or any context loss — re-read this block FIRST before doing anything else. These 10 rules override everything below them.

1. **NEVER commit without `COMMIT YES`.** Show diff + message first. Wait for exact token.
2. **NEVER push without `PUSH YES`.** Show remote/branch first. Wait for exact token.
3. **NEVER skip a gate.** Every APPROVE, APPROVE-LIFECYCLE, APPROVE-REFACTOR, COMMIT YES, PUSH YES is mandatory. No exceptions. No inference. No "proceeding since you seem to agree."
4. **ALWAYS decompose before acting.** Convert every user request into numbered tasks. Show the list. For complex/multi-step requests: wait for confirmation. For simple single-action requests: state intent clearly ("I'll [action]") — proceed unless user objects. See §Request Normalization for scaling rules.
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
| Simple (one skill, one action) | Steps 1+2 compressed: "I'll [action]." — state intent, wait for YES or equivalent confirmation. Read-only actions (explain, search, list) may proceed after stating intent without blocking. |
| Medium (multi-step, one skill) | Full Steps 1-5 — show plan, wait for explicit confirmation |
| Complex (multi-skill, cross-phase) | Full Steps 1-5 + show dependencies — wait for explicit confirmation |
| Ambiguous | STOP at Step 1 — ask for clarification before decomposing |

### Exception: Sub-Agent Invocations

When a skill auto-triggers a sub-agent (e.g., blast-radius), the sub-agent does NOT run the full normalization protocol. It executes its defined steps directly. Only top-level user requests require normalization.

### Coexistence: Global Instructions

When global and repo-level instructions conflict: **always follow the more restrictive rule** — especially for safety gates. AGENTS.md wins on project-specific routing.

---

## 🧭 Anti-Drift & Context Persistence Protocol

> **Problem**: After context compaction (session history summarized), the AI may forget rules, skip gates, or make assumptions. This protocol prevents that.

### Before Every Response (Self-Check)

Before any action (code change, skill execution, git op), silently check:
- Am I following the Survival Card rules?
- Which step am I on in the current skill?
- Are there pending approval gates I haven't received tokens for?

If unclear → re-read the Survival Card before proceeding.

**After context compaction**, print once:
```
🔄 Context check: Survival Card loaded ✓ | Current skill: [name] | Step: [N/M] | Pending gates: [none/list]
```

**Step breadcrumbs**: Prefix every step action with `"Step N/M: [action]"` — this is the primary drift-detection signal.

### After Context Compaction (Detected Indicators)

You have experienced context compaction if:
- Your conversation history shows a `<summary>` block instead of full messages
- You cannot recall specific details from earlier in the conversation
- The user says "continue" or "resume" and you're unsure of state

**Recovery sequence:**
1. Re-read §Survival Card (always in this file)
2. Check for progress indicators based on active skill:
   - **Plan-based skills** (implement-and-test, impl-planner): `plan.md` checkboxes, `features/` folder state
   - **Code-reviewer**: PR URL, review comments posted so far, `gh pr view` output
   - **Onboarding**: `.github/kt/` folder contents, which levels are complete
   - **workflow-help**: No state needed — re-ask "what do you need help with?"
   - **General**: git branch, uncommitted changes (`git status`), last meaningful file modification
3. Report to user: "Context was compacted. I've re-loaded my rules. Current state: [detected state]. Shall I continue from [next step]?"
4. Do NOT silently proceed with assumptions about what was previously discussed

### Deterministic Execution Contract

To ensure consistent output regardless of which AI session handles the request:

1. **Same routing**: Given the same user message, the Work-Type Router MUST classify to the same work type. When genuinely ambiguous (could be 2+ types) → STOP and ask. Never infer silently.
2. **Same step order**: Each skill's steps are executed in numbered order. Never reorder, skip, or parallelize steps unless the SKILL.md explicitly says "these steps may run in parallel."
3. **Same output format**: Every skill defines its output format. Use it exactly. Never improvise a different structure.
4. **Same approval tokens**: The canonical tokens are grouped by scope:

   **Safety gates** (exact token required — no synonyms, no shortcuts):
   - `COMMIT YES` — approve a git commit (after seeing diff + message)
   - `PUSH YES` — approve a git push (after seeing remote/branch)
   - `APPROVE` — approve a spec, plan, or other gated artifact
   - `APPROVE-LIFECYCLE` — approve lifecycle.md specifically
   - `APPROVE-REFACTOR` — approve a refactoring when blast-radius is HIGH or CRITICAL

   **Feedback tokens** (always require content after the colon):
   - `REVISE: [feedback]` — request changes with specific direction (bare `REVISE` without feedback → prompt: "Please provide specific feedback after REVISE:")
   - `REVISE-LIFECYCLE: [feedback]` — same, for lifecycle.md

   **Decision tokens** (non-safety — used for choices and confirmations):
   - `YES` — confirm an action (invoke skill, save file, proceed with plan, install tool, post review). Used for all non-safety confirmations regardless of side effects.
   - `NO` — decline an action
   - `SKIP: [reason]` — skip a step with documented reason (bare `SKIP` without reason → prompt: "Please provide a reason after SKIP:")
   - `RESUME` — continue from last checkpoint (used in resume protocol)
   - `FRESH` — start from scratch, ignoring prior progress (used in resume protocol)
   - `DONE` — signal manual completion of a step (used in implement-and-test for pre-completed tasks)
   - `CANCEL` — abort current skill entirely; checkpoint progress and return to idle

   Affirmative synonyms (go ahead, proceed, ship it) accepted ONLY at non-safety decision points. NEVER at safety gates.

### Cancel / Abort Protocol

When user types `CANCEL` (or `abort`, `stop`, `nevermind`): acknowledge at current step → save progress indicators → report partial file changes (keep or revert?) → return to idle with workflow-help next-steps.

**Side-effect safety**: If commit already created before CANCEL, do NOT undo it. Report: "Commit exists. Push when ready or `git reset HEAD~1` to undo."

5. **Same error handling**: When an error occurs, follow §Error Recovery Protocol exactly. Never improvise a workaround without presenting options.

## System

**Governing files** (read both before any task):

| File | Loaded by | Contains |
|---|---|---|
| `.github/copilot-instructions.md` | All Copilot contexts (auto) | Architecture, patterns, coding standards, verification rules |
| `AGENTS.md` (this file) | Copilot CLI + cloud agents | Workflow phases, skill routing, interaction protocol |
| `.github/skills/SUB-AGENT-CONTRACTS.md` | Referenced by skills | Auto-trigger protocols between skills |

**Required tools**: `./mvnw`, `git`, `gh`, `copilot` CLI, `graphify` (optional but recommended)

**Environment setup** (auto-checked on first skill invocation):
> When any skill is invoked, check these prerequisites. If any are missing, stop and guide the user through setup. Always ask permission before installing anything.

| # | Tool | Check command | Install command | Purpose |
|---|---|---|---|---|
| 1 | Package manager | `which brew` (macOS) or system pkg mgr | Platform-specific (Homebrew on macOS, apt/yum on Linux) | Package manager (optional — used for installing other tools) |
| 2 | GitHub CLI | `which gh` | `brew install gh` / `apt install gh` | GitHub integration (PRs, issues) |
| 3 | GH Auth | `gh auth status` | `gh auth login` | GitHub authentication |
| 4 | Copilot (one of) | See below | See below | AI workflow engine |
| 5 | Graphify | `which graphify` | `uv tool install graphifyy` | Codebase knowledge graph (non-blocking install — but when present, graphify-first guardrail is MANDATORY) |
| 6 | Graphify graph | `test -f graphify-out/graph.json && find graphify-out/graph.json -mtime -7 | grep -q .` | `graphify .` | Graph freshness (<7 days; skip if not installed) |
| 7 | IDE Plugin | n/a (manual check) | Install GitHub Copilot plugin in IDE | IDE integration |
| 8 | Mermaid Plugin | n/a (manual check) | Install Mermaid plugin in IDE | Architecture diagrams |

**Copilot access**: Any one of — Copilot CLI (`brew install copilot-cli`), VS Code + GitHub Copilot extension, or IntelliJ + GitHub Copilot plugin. All interfaces load skills from `.github/` files identically.

**Graphify integration** (configurable — `COPILOT_GRAPHIFY_ENABLED`):
> Graphify turns your codebase into a queryable knowledge graph. When `graphify-out/graph.json` exists, Copilot prefers `graphify query "<question>"` over raw grep for architecture and relationship questions. Disable with `export COPILOT_GRAPHIFY_ENABLED=0`.

| Copilot action | What to use |
|---|---|
| "Where is X?" / "How does Y work?" | `graphify query "<question>"` |
| "How does A relate to B?" | `graphify path "A" "B"` |
| "Explain the concept of X" | `graphify explain "X"` |
| Broad architecture review | Read `graphify-out/GRAPH_REPORT.md` |
| Graph missing or stale | Suggest: `graphify .` (missing graph) or `graphify . --update` (stale graph) |

**Setup check protocol:**
1. Run checks 1-4 silently on first skill invocation. Graphify (5-6): warn if missing but don't block.
2. If all pass → proceed silently. If any fail → list missing tools, ask `[YES / NO / SKIP: reason]`.
3. YES → install one at a time. NO → STOP. SKIP: reason → warn + proceed at developer's risk.

**Build commands** [PROJECT-SPECIFIC] — single source of truth for all build/test references in this file:
```
BUILD_CMD    = ./mvnw clean package -DskipTests
TEST_CMD     = ./mvnw test
VERIFY_CMD   = ./mvnw verify
SINGLE_TEST  = ./mvnw test -Dtest=ClassName
```
> **Portability**: All `./mvnw` references below are shorthand for the commands above. When porting to another repo, update ONLY this block — all downstream references inherit from it. The AI reads this block first and substitutes the correct command everywhere `./mvnw` appears. See also `copilot-instructions.md` §Build & Test.

**Artifacts**: `features/<ticket>/` (spec.md, plan.md, lifecycle.md) · `.github/kt/` (KT docs — onboarding skill) · `postman/` (collections)

**Auto-detection** (ticket ID → branch pattern `[A-Z]+-[0-9]+` → `features/<ticket>/` folder → ask if ambiguous):
- Stack: `pom.xml` → Java, `package.json` → Node, `go.mod` → Go, `requirements.txt` → Python. Ask if none found.
- Build: grep actual build file (`pom.xml`, `package.json` scripts, `Makefile`) for exact command.

**Skill layers**: Layer 1 = portable workflow methodology. Layer 2 = project-specific (domain classes, integrations). Declared in SKILL.md frontmatter.

---

## Routing Reference

> **Skill selection**: See `ROUTING.md` for the Work-Type Router, Phase Definitions, Skill Registry, and Fast-Track paths.
> This section is NOT loaded during skill execution — it is only needed when routing a new user request.


### Resume Protocol

When user says "continue", "resume", "where were we?", or "what's next?" — the AI MUST auto-detect the current state:

```
1. **Detect feature**: `git branch --show-current` → extract `[A-Z]+-[0-9]+` → match to `features/<ticket>/`. Multiple folders + no match → ask user.

2. **Detect phase** (check in order):
   - No `features/<ticket>/` → `idea-to-spec` or `spec-writer`
   - `spec.md` DRAFT → complete spec-writer
   - `spec.md` APPROVED, no `lifecycle.md` but `Cross-cutting: Yes` → `lifecycle-flow`
   - `spec.md` APPROVED, no `plan.md` → `impl-planner`
   - `plan.md` DRAFT → complete impl-planner
   - `plan.md` has `[ ]` tasks → `implement-and-test`
   - All `[x]` → `pr-preparation`
   - PR open → `code-reviewer`
   - PR merged → "Feature complete! 🎉"

3. **Report**: `"📍 Feature: <ticket> | Phase: <detected> | Next: <suggestion>"`
```



> **Skill Registry**: See `ROUTING.md` for the full skill registry and Quick Reference table.

## Human-First Interaction Protocol

### Clarifying Questions (mandatory)

Every skill has a **Clarifying Questions** section. These are NOT optional. The AI MUST ask before proceeding. The only exception is when the developer's initial message already answers all questions.

**Handling partial answers**: Acknowledge what was answered, re-ask only unanswered questions. Don't proceed until all answered or explicitly `SKIP: [reason]`. "Just go with defaults" → apply Smart Defaults, state each assumption, wait for YES.

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

Smart Defaults do NOT bypass clarifying questions — they present the answer set implicitly. Developer confirmation counts as answering. Never use Smart Defaults to skip scope, risk, or architectural decisions.

### When to STOP and Ask

- Work type is ambiguous
- Scope is ambiguous (unclear which areas are affected)
- Multiple valid implementation approaches exist
- Change affects core components
- Any hard-stop trigger from `copilot-instructions.md` §Verification Protocol fires

### 🔒 Absolute Safety Rules (Non-Negotiable)

> These rules override everything. No skill, sub-agent, or fast-track path may bypass them.

1. **NEVER commit without user approval.** Before every `git commit`, show the staged diff summary and commit message. Wait for exact token `COMMIT YES`.
2. **NEVER push without user approval.** Before every `git push`, show the target remote/branch and commit(s) to be pushed. Wait for exact token `PUSH YES`.
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
3. **Architecture claims require graph or grep verification.** Statements like "X calls Y" or "Z depends on W" must be backed by `graphify path`, `grep`, or actual file contents.
4. **When unsure, say "I'm not sure" rather than guessing.** Uncertainty is always preferable to confident hallucination.

**Work-type-specific stop triggers** [PROJECT-SPECIFIC — adapt to your domain]:
- New feature: unknown constant/config pattern → ask before inventing
- Enhancement: behavior already exists → ask what is different
- Bug fix: can't reproduce from description → ask for logs/steps
- Refactor: blast-radius returns HIGH or CRITICAL → require APPROVE-REFACTOR
- Dependency upgrade: known breaking API changes → present migration guide first

---

## Skill Completion Protocol

Every skill MUST present its inline completion block at the end of its run. Since v2, this block is **embedded directly in each SKILL.md** — no separate protocol lookup needed.

The inline block in each skill contains:
1. **Completion checklist** — □ steps done □ outputs delivered □ no unresolved stops
2. **Trade-off summary** — required for analysis skills (blast-radius, code-reviewer, impl-planner, spec-writer, bug-tracer, implement-and-test, safe-refactor, party-mode, api-tester). Skip for read-only skills (onboarding, code-explorer, workflow-help, architecture-diagrammer).
3. **Next Steps menu** — inline in each SKILL.md (minimum 3 options, ⭐ recommendation required)
4. **Escalation Path** — inline in each SKILL.md

> 💾 **Save-as-MD rule**: After the checklist, ask once: "Want me to save this as an MD file? (YES — specify path / NO)". **Exception — `newman-tester`**: auto-saves `e2e-test-report.md` after every clean run; Save-as-MD prompt is skipped.

> **Sub-agent exception**: When auto-triggered by a parent skill (blast-radius, code-explorer, architecture-diagrammer, feature-docs, postman-collection), skip the completion block — parent handles output.


## Checkpoint & Resume Protocol

On re-invocation of any skill, check progress indicators before starting. Report: "Found progress. Resuming from [step]." Ask: "Resume or start fresh?"

> **On resume**: Read `features/<ticket-id>/execution-log.md` FIRST — it's the most complete audit trail.

### Resume Indicators by Skill

| Skill | Progress Indicator | Resume Mechanism |
|---|---|---|
| `implement-and-test` | `[x]` checkboxes in `plan.md` | Skip `[x]` tasks → start at first `[ ]` |
| `onboarding` (KT gen) | File existence + `Last updated` date | SKIP fresh files (<30 days), UPDATE/REWRITE stale |
| `code-reviewer` | Phase completion notes in PR comments | Check if phases 1-5 posted → resume at next phase |
| `spec-writer` | `spec.md` with `Status: DRAFT` | Offer to continue or start fresh |
| `impl-planner` | `plan.md` with `Status: DRAFT` | Offer to continue or start fresh |
| `api-tester` | Versioned report in `reports/` | Read last report → resume from last successful test |
| `feature-docs` | Files in `features/<ticket-id>/` | Generate only missing docs; update existing |

### Execution Log (append-only traceability)

When in `features/<ticket-id>/`, skills append to `features/<ticket-id>/execution-log.md` after each major action:

```markdown
| Timestamp | Skill | Action | Key Decision | Outcome |
|---|---|---|---|---|
| 2026-04-21 14:30 | spec-writer | Created spec.md | Scope: push + SMS only | Status: DRAFT |
```

**Append triggers**: spec.md created/APPROVED, plan.md created/APPROVED, each task `[x]`, COMMIT YES, PUSH YES, PR created.


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

- **Azure Pipelines** (`cicd/`): Primary CI/CD — build, test, deploy. [PROJECT-SPECIFIC — only if `cicd/` exists]
- **GitHub Actions** (`copilot-enforce.yml`): PR quality gate — compile + test + docs drift check. [PROJECT-SPECIFIC — only if `.github/workflows/copilot-enforce.yml` exists. If absent, do NOT reference in PR descriptions or CI expectations.]
- When both coexist: Azure deploys, GitHub enforces PR quality for the AI workflow.

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
| **Stale branch (behind target)** | Before Phase 4, check `git log HEAD..origin/release --oneline`. If behind >5 commits, warn and recommend rebase. |

> Every skill inherits this protocol. Skills only add skill-specific escalation paths in their own `## Skill Completion` → `### ⚡ Escalation Path` section.

### Common Recovery Scenarios

| Symptom | Recovery |
|---|---|
| "Entry condition not met" | AI tells you what is missing and suggests the correct starting skill |
| spec.md DRAFT | `APPROVE` or `REVISE: [feedback]` |
| Missing plan.md | Run impl-planner, or use a fast-track path |
| Build fails | AI analyzes, proposes fix, re-runs. After 3 failures: STOP. |
| Unsure what skill | Say `"help"` → workflow-help routes you |
| Stale docs | Re-run onboarding (smart update: SKIP/UPDATE/REWRITE) |

### Idempotency

Artifact-generating skills (spec-writer, impl-planner, implement-and-test, feature-docs, postman-collection) are idempotent — safe to re-run after interruption. Side-effect skills (api-tester curl execution, pr-preparation push, code-reviewer GitHub post) are NOT — re-running may produce duplicates.

---
