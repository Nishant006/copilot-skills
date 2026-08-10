---
name: workflow-help
description: "Context-aware routing — tells you what skill to use next based on your current state"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: []
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

The entry point when a developer is unsure what to do next. Three modes: (1) show all available skills, (2) route based on known state, (3) ask clarifying questions to resolve ambiguity. Inspired by BMAD's `bmad-help` — adapted for our workflow.

## Entry Conditions

1. Developer asks "what should I do?", "what skills are available?", "I'm stuck", or any ambiguous request that doesn't match a specific skill.
2. This skill is the **default fallback** — if the Work-Type Router in `ROUTING.md` cannot classify the request, route here.
3. Bootstrap: Read `ROUTING.md` (Work-Type Router + Skill Registry + Phase Definitions).

### Stop conditions
- If **ROUTING.md is not found** or unreadable: **STOP. Report: "Cannot route your request — ROUTING.md (routing engine) not found. Verify this repo has .github/ properly set up." Do not continue.**
- If **request matches 2+ work types equally** after Mode 3 questioning: **STOP. Report: "Your request matches multiple skills equally: [list]. Please clarify which aspect is more important: [specific disambiguating question]." Do not continue.**

## Clarifying Questions

Only ask if Mode 3 (Ambiguous) is triggered. See "Step 3" below.

When Mode 3 IS triggered: ask a maximum of 2 questions to disambiguate. Proceed only after answers are received. If after 2 questions the request is still ambiguous, present the top 2-3 matching skills and let the developer choose.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

## Step 0 — Detect Current State

```bash
# Check: what is the current feature state?
git branch --show-current 2>/dev/null
ls features/ 2>/dev/null | head -5
```
**No hard stop — use this output to route to the correct skill.**

## Step 1 — Detect Mode

| Mode | Trigger | Action |
|------|---------|--------|
| **1: Show All** | "what skills are available?", "help", "what can I do?" | Go to Step 2 |
| **2: Known State** | Developer describes a state that matches the routing table below | Go to Step 4 |
| **3: Ambiguous** | Request doesn't clearly match any skill | Go to Step 3 |

```bash
# ✓ Check before moving on: Mode classified as 1, 2, or 3. If cannot classify → default to Mode 3 (ask).
echo 'Step done: Mode classified as 1, 2, or 3. If cannot classify → default '
```
## Step 2 — Show All Skills (Mode 1)

Present this table:

| Skill | Purpose | When to Use | Invocation |
|-------|---------|-------------|------------|
| `onboarding` | Codebase walkthrough + optional KT generation | New to the team or codebase | `"use the onboarding skill"` |
| `idea-to-spec` | Rough idea → structured brief.md | You have a vague feature idea, not a Jira ticket yet | `"use the idea-to-spec skill"` |
| `spec-writer` | Write feature specification | You have a feature with clear requirements | `"use the spec-writer skill for COM-XXX"` |
| `impl-planner` | Create implementation plan | After spec is APPROVED | `"use the impl-planner skill for COM-XXX"` |
| `implement-and-test` | Write code + tests | After plan is APPROVED (or direct for config/fast-track) | `"use the implement-and-test skill for COM-XXX"` |
| `pr-preparation` | Commit + create PR | After implementation + tests pass | `"use the pr-preparation skill for COM-XXX"` |
| `code-reviewer` | Review a PR | PR exists on GitHub | `"give me all open PRs"` or `"review PR #142"` |
| `bug-tracer` | Trace and fix a bug | Something is broken | `"use the bug-tracer skill"` |
| `safe-refactor` | Rename/reorganize code safely | Code cleanup without behavior change | `"use the safe-refactor skill"` |
| `code-explorer` | Understand specific code areas | Need to understand a class, flow, or pattern | `"use the code-explorer skill"` |
| `blast-radius` | Analyze what breaks if X changes | Before risky changes | `"use the blast-radius skill on SmsClientFactory"` |
| `architecture-diagrammer` | Generate system diagrams | Need visual overview | `"use the architecture-diagrammer skill"` |
| `lifecycle-flow` | Map cross-service flows | Feature spans multiple services | `"use the lifecycle-flow skill"` |
| `feature-docs` | Generate/update feature docs | After spec/plan/impl approval | `"generate feature docs"` |
| `postman-collection` | Generate/update Postman collection | After API endpoint changes | `"update postman collection"` |
| `newman-tester` | Run API tests with Newman | Run API tests, verify API behavior, or execute a Postman collection | `"use the newman-tester skill"` |
| `party-mode` | Multi-persona discussion | Complex design decisions | `"use the party-mode skill"` |
| `workflow-help` | This skill — routing guidance | You're unsure what to do next | `"help"` or `"what should I do next?"` |
| `setup-check` | Pre-flight environment check | Verify AI tooling setup | `"check my setup"` |

Then ask: "Which of these matches what you need? Or describe your situation and I'll recommend one."

```bash
# ✓ Check before moving on: Skill table presented to user. User has actionable invocation phrases.
echo "✓ Check: skill recommendation was delivered with exact invocation phrase"
```
## Step 3 — Resolve Ambiguity (Mode 3)

Ask exactly ONE question at a time from this decision tree:

1. "Are you trying to **build something new**, **fix something broken**, **change configuration**, **understand something**, or **review someone's work**?"
2. Based on answer, narrow further:
   - **Build** → "Do you have a clear idea with requirements, or is it still a rough concept?"
     - Clear → `spec-writer`
     - Rough → `idea-to-spec`
   - **Fix** → `bug-tracer`
   - **Config** → `implement-and-test` (config fast-track)
   - **API tests** / phrases like "run api tests", "test with newman", "run postman", "verify api" → `newman-tester`
   - **Understand** → "The whole codebase, or a specific class/flow?"
     - Whole → `onboarding`
     - Specific → `code-explorer`
   - **Review** → `code-reviewer`
3. If still ambiguous after 2 questions: present the 2-3 most likely skills and let the developer choose.

**Rule**: Never ask more than 2 clarifying questions. By question 2, you must recommend a skill (or present 2-3 choices for the developer to pick from).

```bash
# ✓ Check before moving on: A specific skill recommendation is delivered to the user within 2 questions maxi
echo 'Step done: A specific skill recommendation is delivered to the user wit'
```
## Step 4 — Route from Known State (Mode 2)
| Current State | Next Skill | Exact Phrase |
|---|---|---|
| New / first day | `onboarding` | `"use the onboarding skill"` |
| Rough idea / what if | `idea-to-spec` | `"use the idea-to-spec skill"` |
| Have ticket | `spec-writer` or `idea-to-spec` | Ask if requirements are defined or still rough |
| spec.md DRAFT / Spec APPROVED no plan | `APPROVE`/`REVISE` or `impl-planner` | `"use the impl-planner skill for COM-XXX"` |
| plan.md DRAFT / Plan APPROVED / continue coding | `APPROVE`/`REVISE` or `implement-and-test` | `"use the implement-and-test skill for COM-XXX"` |
| Tests pass / done coding / PR up / requested changes | `pr-preparation` / `code-reviewer` / `implement-and-test` | `"use the pr-preparation skill for COM-XXX"` / `"give me all open PRs"` |
| Config only / broken / understand code | `implement-and-test` / `bug-tracer` / `code-explorer` | `"use the implement-and-test skill"` / `"use the bug-tracer skill"` / `"use the code-explorer skill"` |
| Run API tests / test with newman / run postman / verify api | `newman-tester` | `"use the newman-tester skill"` |
| Refactor / impact / dependency upgrade | `blast-radius` → `safe-refactor` or `implement-and-test` | `"use the blast-radius skill on [target]"` |
| Design tradeoff / need diagram / new and need to build | `party-mode` / `architecture-diagrammer` / `onboarding` → `spec-writer` | `"use the party-mode skill"` / `"use the architecture-diagrammer skill"` |
| features/ exists / stuck | Route from missing or DRAFT artifact / show full menu | `show all` |
```bash
# ✓ Check before moving on: Routing recommendation displayed with exact invocation phrase.
echo 'Step done: Routing recommendation displayed with exact invocation phrase'
# Verify: a skill was recommended
echo "Routing complete — confirm exact invocation phrase was provided"
```
## Exit Conditions / Done Definition

- [ ] Developer has been routed to a specific skill with an exact invocation phrase
- [ ] Developer confirms the recommendation makes sense

## Sub-Agents

None — this skill is a router, not an executor.

## Example Invocation

**Example 1: MODE A — Show all skills**
```
Developer: "help"
AI: [shows full skill table with 19 skills]
    "Which of these matches what you need? Or describe your situation."
Developer: "I need to add a new notification event"
AI: "📍 You are here: Starting a new feature
    ✅ Next skill: spec-writer
    🔤 Say this: 'use the spec-writer skill for COM-XXX — [event name]'
    📦 It will produce: features/COM-XXX/spec.md
    ➡️ After that: impl-planner → implement-and-test → pr-preparation"
```

**Example 2: MODE B — Known state (spec approved)**
```
Developer: "I just got spec APPROVED for COM-789. What's next?"
AI: "📍 You are here: Spec approved, no plan yet
    ✅ Next skill: impl-planner
    🔤 Say this: 'use the impl-planner skill for COM-789'
    📦 It will produce: features/COM-789/plan.md with complexity-assessed task list
    ➡️ After that: implement-and-test (after plan APPROVED)"
```

**Example 3: MODE B — Known state (bug)**
<!-- [PROJECT-SPECIFIC] example references site code mafpak -->
```
Developer: "SMS is failing for mafpak customers"
AI: "📍 You are here: Bug in production
    ✅ Next skill: bug-tracer
    🔤 Say this: 'use the bug-tracer skill — SMS failing for mafpak'
    📦 It will produce: Root cause analysis + fix recommendation
    ➡️ After that: implement-and-test → pr-preparation"
```

**Example 4: MODE B — Known state (new team member)**
```
Developer: "I'm new to the team and need to review PR #142"
AI: "📍 You are here: New to codebase, need to review
    ✅ Next skill: onboarding (first, to understand the codebase)
    🔤 Say this: 'use the onboarding skill — I need context for PR #142'
    📦 It will produce: Architecture walkthrough + optional .github/kt/ KT docs
    ➡️ After that: code-reviewer — 'review PR #142'"
```

**Example 5: MODE C — Ambiguous state**
```
Developer: "I need to make some changes to the SMS system"
AI: "Are you building something new, fixing something broken, changing config,
     understanding code, or reviewing someone's work?"
Developer: "Adding a new vendor"
AI: "📍 You are here: New SMS vendor = new feature
    ✅ Next skill: spec-writer
    🔤 Say this: 'use the spec-writer skill for COM-XXX — new SMS vendor [name]'
    📦 It will produce: features/COM-XXX/spec.md
    ➡️ After that: impl-planner → implement-and-test → pr-preparation"
```

## What I Will NOT Do

- Execute any skill — only recommend and route
- Assume what the developer needs — always ask if unclear
- Skip the routing table — every recommendation comes from the table above
- Give a vague answer like "it depends" — always give the exact invocation phrase
- Ask more than one clarifying question per routing attempt — one focused question to disambiguate, then route. (In complex cases where the first answer still leaves ambiguity, a follow-up is permitted — max 2 total.)

---

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Classification | Request matches multiple work types | Ask developer: "Is this primarily a [type A] or [type B]?" Present both paths. |
| Classification | Request matches no work type | Default to code-explorer for understanding, or spec-writer for building. Ask developer to clarify goal. |
| Routing | Suggested skill doesn't exist or fails to load | Fall back to the closest alternative. List available skills. |
| Any step | Developer is frustrated or confused | Simplify: "Tell me in one sentence what you want to accomplish." Route from there. |

---

## Step 5 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ workflow-help — done?
  □ Steps 0–5 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Start the recommended skill
  B) Explore the codebase first             — say: "use the code-explorer skill — how does X work?"
  C) Discuss tradeoffs                      — say: "use the party-mode skill — [topic]"
  D) Check setup                            — say: "check my setup"
  E) Get help                              — say: "help"

⭐ follow the routing suggestion.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
