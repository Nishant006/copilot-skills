---
name: onboarding
description: "Walk a new developer through codebase architecture, patterns, and AI workflow — with optional persistent KT output"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [code-explorer, architecture-diagrammer]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Guide a new developer from zero context to productive contributor. Provides tiered walkthroughs scaled to experience level, delegates deep-dives to code-explorer, and generates optional persistent KT documents in `.github/kt/` that the team can commit and share. Every future developer reads the same KT — zero human handoff required.

## Entry Conditions

1. A developer requests onboarding, codebase overview, or asks "how does this project work?"
2. Bootstrap: Read the files listed in "Files to Read First" (below) in order.

## Files to Read First

**Read these files IN THIS ORDER before any conversation begins.** This ensures the AI has full context and never hallucinates architecture details.

[PROJECT-SPECIFIC — adapted for this project]

| # | File | What it contains | If missing |
|---|------|-----------------|------------|
| 1 | `AGENTS.md` | Workflow phases, skill registry | Stop — "AGENTS.md not found. Cannot proceed with onboarding." |
| 2 | `.github/copilot-instructions.md` | Architecture, patterns, standards | Warn and continue — fall back to reading src/ directly |
| 3 | `.github/skills/onboarding/onboarding-guide.md` | Quick-start + gotchas | Warn and continue — derive info from src/ |
| 4 | `.github/skills/code-explorer/exploration-patterns.md` | Navigation paths | Continue without — deep-dives will be slower but still work |
| 5 | `pom.xml` (first 50 lines) | Java/Spring Boot version | Warn — "Cannot confirm tech stack versions" |
| 6 | `src/main/java/` (top-level packages) | Package structure | Stop — "No source code found." |
| 7 | `.github/kt/` folder | Existing KT docs | Continue without — Step 8 generates KT docs including diagrams |

After reading, confirm: "I've read [N] of 7 context files. Missing: [list or 'none']."

## Clarifying Questions

Ask ALL of these before proceeding:

1. What is your **role**? (backend engineer, QA, new grad, DevOps, etc.)
2. What is your **experience level** with this tech stack? (expert, familiar, beginner)
3. Do you have a **specific ticket or area** to focus on, or do you want a general overview?
4. Do you prefer a **high-level overview first**, or do you want to **dive into code** immediately?

Proceed only after answers are received.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill, check if `graphify-out/graph.json` exists. If it does, run `graphify explain "<component>"` or `graphify query "<architecture question>"` first. Use grep only to supplement graphify results or when graph is unavailable. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Clarify Level and Goal

Ask the developer (if not already provided):
- **Level**: L1 (quick overview), L2 (deep-dive into a specific area), or L3 (ready to contribute)?
- **Focus area**: full architecture, or a specific component (e.g., rate limiter, Kafka flow)?

```bash
# Check: what KT docs already exist?
ls .github/kt/ 2>/dev/null && echo "KT docs found — will build on them" || echo "No KT docs yet"
```
**No hard stop — informational. Use the level to determine which steps to execute.**

## Step 1 — Determine Walkthrough Level

Based on clarifying answers, select the appropriate tier:

| Level | Duration | Audience | Content |
|-------|----------|----------|---------|
| **Level 0** | ~2 min | Setup only | Clone, `./mvnw clean install`, verify all tests pass, explain project structure, explain profiles (local/dev/preprod/prod) |
| **Level 1** | ~5 min | Quick overview | Architecture diagram, key entry points, tech stack summary |
| **Level 2** | ~15 min | Architecture deep-dive | Full request pipeline, design patterns, config flow, test strategy |
| **Level 3** | ~30 min | First-ticket guided walkthrough | Level 2 + hands-on ticket walkthrough using AI skills |

```bash
# ✓ Check before moving on: Level selected and communicated to developer.
echo 'Step done: Level selected and communicated to developer'
```
## Step 2 — Architecture Overview (all levels)

**Resume support** (see AGENTS.md §Checkpoint & Resume Protocol): On re-invocation, check `.github/kt/` file existence and `Last updated` dates. Report fresh vs stale files. For KT generation (Step 8), use SKIP/UPDATE/REWRITE per file age.

Present the project architecture using information from the files read in "Files to Read First":

1. **Entry points** — identify all inbound channels
   Source: `.github/copilot-instructions.md` §Architecture → REST API Gateway Pipeline [PROJECT-SPECIFIC]
2. **Request pipeline** — trace from REST request to validation to config lookup to Kafka publish
   Source: `.github/copilot-instructions.md` §Architecture → Request Processing Pipeline [PROJECT-SPECIFIC]
3. **External integrations** — list all third-party services and their purpose
   Source: `.github/copilot-instructions.md` §External Integrations table [PROJECT-SPECIFIC]
4. **Data stores** — databases, caches, and their roles
   Source: `.github/copilot-instructions.md` §Configuration Storage [PROJECT-SPECIFIC]
5. **Config management** — where configuration lives and how it is loaded
   Source: `.github/copilot-instructions.md` §Configuration Storage + §Profiles [PROJECT-SPECIFIC]

Auto-trigger **architecture-diagrammer** to generate visual overview (default for Level 2+; skip only if developer explicitly declines).

```bash
# ✓ Check before moving on: Developer can name the entry points, processing layers, and data stores.
echo "✓ Check: developer named at least 2 entry points and 1 processing layer"
```
## Step 3 — Interactive Deep Dive (Level 2+)

After presenting the architecture overview, **always pause and offer to go deeper**. Do not wait for the developer to ask.

Present exactly this menu:

> "Want to go deeper into any of these areas? I'll pull up the actual code with file:line references."
>
> <!-- [PROJECT-SPECIFIC] Deep-dive menu — dispatcher-specific components -->
> | # | Area | What you'll see |
> |---|---|---|
> | 1 | Request pipeline | Trace `CommunicationController` → `RequestValidatorServiceImpl` → `ProducerServiceImpl` → `KafkaProducer` with exact line numbers |
> | 2 | Security & API key flow | How `SecurityFilter` validates `x-api-key` — trace for v1 (unsecured) vs v2 (secured) |
> | 3 | Config cache chain | Two-tier cache: Redis (circuit breaker) → MongoDB fallback with actual `ConfigServiceCircuitBreakerImpl` code |
> | 4 | Kafka publishing | How `ProducerServiceImpl` resolves priority topic and `KafkaProducer` sends — key generation, partitioning |
> | 5 | Request validation | `RequestValidatorServiceImpl` — required fields, config ID format, country-specific headers |
> | 6 | Scheduled notifications | Shedlock-based distributed scheduling — cron triggers, lock management |
> | 7 | Circuit breaker internals | Resilience4j state machine in `ConfigServiceCircuitBreakerImpl` — open/half-open/closed transitions |
> | **S** | **Skip** | Continue to design patterns |

**For each chosen option:**
1. Trigger **code-explorer** sub-agent with the specific class/flow as input
2. Present the result with file:line references
3. After each deep dive, ask: "Anything else to explore, or shall we move on to design patterns?" — show the remaining options

**Rule**: Never present all deep dives unprompted. Wait for developer's selection. Allow multiple selections (e.g., "1 and 3").

**⛔ Gate**: Do not proceed to the Key Patterns subsection until either:
- Developer has selected at least one deep-dive option, OR
- Developer has explicitly chosen "Skip"
Use `ask_user` tool with choices: `["1 — Request pipeline", "2 — Security & API key flow", "3 — Config cache chain", "4 — Kafka publishing", "5 — Request validation", "6 — Scheduled notifications", "7 — Circuit breaker internals", "S — Skip deep dives"]`
This menu MUST be presented via `ask_user` if available. **Fallback**: If `ask_user` is not available in the current runtime, present the numbered list as plain text and ask the developer to type their choice number(s). The gate requirement (developer must choose or skip) still applies regardless of presentation method.

```bash
# ✓ Check before moving on: Developer has explored at least one area in code depth, or explicitly skipped.
echo 'Step done: Developer has explored at least one area in code depth, or e'
```
#### Key Patterns (Level 2+)

Identify and explain the dominant design patterns in the codebase.
For each pattern: read 2–3 actual implementations, explain the role + interface, show how to add a new instance.

[PROJECT-SPECIFIC — patterns and file paths below are specific to this project]

| Pattern | Interface/Class | Example Implementation | Location |
|---------|----------------|----------------------|----------|
| Controller → Service delegation | `CommunicationController` | REST endpoint → validation → publish | `src/main/java/.../controller/` |
| Request validation | `RequestValidatorServiceImpl` | DTO field validation + config lookup | `src/main/java/.../service/impl/` |
| Circuit breaker (fallback) | `ConfigServiceCircuitBreakerImpl` | Resilience4j Redis → MongoDB fallback | `src/main/java/.../circuitbreaker/` |
| Producer abstraction | `ProducerServiceImpl` + `KafkaProducer` | Priority-based Kafka topic routing | `src/main/java/.../producer/` |
| Security filter | `SecurityFilter` | x-api-key header validation, path exclusion | `src/main/java/.../security/` |
| Scheduled task (Shedlock) | Scheduled notification classes | Distributed cron with lock management | `src/main/java/.../scheduled/` |

Auto-trigger **code-explorer** for deep-dives if the developer requests more detail on any pattern.

```bash
# ✓ Check before moving on: Developer can describe each major pattern and where to find examples.
echo 'Step done: Developer can describe each major pattern and where to find '
```
## Step 4 — Pattern Deep Dive (Level 2+)

After presenting all 6 patterns, **always pause and offer per-pattern deep dives**.

Present exactly this menu:

> "Which pattern would you like to explore in the actual code?"
>
> <!-- [PROJECT-SPECIFIC] Pattern deep-dive menu — dispatcher-specific patterns -->
> | # | Pattern | What you'll see |
> |---|---|---|
> | 1 | Controller → Service | Trace a POST request: `CommunicationController` → validation → config lookup → Kafka publish with real file paths |
> | 2 | Request Validation | How `RequestValidatorServiceImpl` validates CommunicationDTO fields, resolves config ID, checks country-specific rules |
> | 3 | Circuit Breaker | What happens when Redis goes down — Resilience4j state machine, fallback to MongoDB |
> | 4 | Kafka Producer | Priority topic selection — how `ProducerServiceImpl` determines high/medium/low and `KafkaProducer` sends |
> | 5 | Security Filter | How `SecurityFilter` intercepts requests — v1 exclusion, API key lookup, `SecurityConfig.keys` map |
> | 6 | Scheduled Notifications | Shedlock distributed locking — how cron jobs execute safely across multiple instances |
> | **S** | **Skip** | Continue to AI workflow introduction |

**For each chosen option:**
1. Trigger **code-explorer** sub-agent with the specific pattern target
2. Return with file:line references and real code snippets
3. After each, ask: "Want to explore another pattern, or move on?"

**Rule**: Never present all pattern deep-dives unprompted. Developer selects; AI executes.

**⛔ Gate**: Do not proceed to Step 5 until either:
- Developer has selected at least one pattern deep-dive, OR
- Developer has explicitly chosen "Skip"
Use `ask_user` tool with choices matching the pattern table above. This menu MUST be presented via `ask_user` if available. **Fallback**: If `ask_user` is not available, present the pattern list as plain text and ask the developer to type their choice. The gate requirement still applies.

```bash
# ✓ Check before moving on: Developer has explored at least one pattern in code depth, or explicitly skipped
echo 'Step done: Developer has explored at least one pattern in code depth, o'
```
## Step 5 — AI Workflow Introduction (Level 2+)

Present using information from AGENTS.md (read in "Files to Read First"):
1. Explain the phased AI workflow (6 phases: spec → plan → implement → PR → review)
2. Map each phase to the corresponding skill
3. Show the skill invocation syntax

Present the Work-Type Router:
- "I have a new feature" → `spec-writer`
- "I have a rough idea" → `idea-to-spec` → `spec-writer`
- "I want to fix a bug" → `bug-tracer`
- "I want to change config" → `implement-and-test`
- "I want to refactor" → `blast-radius` → `safe-refactor`
- "I want to understand something specific" → `code-explorer`
- "I want to review a PR" → `code-reviewer`
- "I'm confused" → `workflow-help`

```bash
# ✓ Check before moving on: Developer knows which skill to use for their next task.
echo 'Step done: Developer knows which skill to use for their next task'
```
## Step 6 — Guided First-Ticket Walkthrough (Level 3 only)

If the developer provided a ticket:
1. Read the ticket requirements
2. Identify which codebase areas are affected (use code-explorer if needed)
3. Walk through the AI workflow phases applied to this specific ticket
4. End with: "Your next step is to invoke [skill-name] with [specific input]."

```bash
# ✓ Check before moving on: Developer has a concrete next action with the exact skill and input.
echo 'Step done: Developer has a concrete next action with the exact skill an'
```
## Step 7 — Understand Then Build (when developer has both goals)

If the developer wants to understand the codebase AND then build a feature:
1. Complete Level 2+ walkthrough (Steps 2-5)
2. Ask: "Which ticket or feature area would you like to start with?"
3. Use code-explorer to deep-dive into the specific area their ticket affects
4. Hand off to spec-writer: "Your next step: use the spec-writer skill for [TICKET] with description: [paraphrase]"

Chain: onboarding → architecture-diagrammer → code-explorer → spec-writer

```bash
# ✓ Check before moving on: Developer has completed onboarding and has a clear handoff to the next skill.
echo 'Step done: Developer has completed onboarding and has a clear handoff t'
```
## Step 8 — Generate KT Output (optional, Level 2+ only)

After completing the walkthrough, offer persistent output:

> "I can generate/update a KT document set in `.github/kt/` — 10 files covering architecture, Mermaid diagrams (in `diagrams/` subfolder), an end-to-end request story, design patterns, gotchas, local setup, AI workflow quick-start, and a reading guide. Your team can commit these and every future developer reads the same KT. Generate now? [YES / NO]"

**If NO**: Walkthrough ends. No files created.

**If YES** (or affirmative synonym): Execute Step 8.0 first (smart update assessment), then Steps 8.1–8.8:

**Anything else** → Clarify: `"Please reply YES to generate KT docs, or NO to skip."`

## Step 8.0 — Smart Update Assessment (ALWAYS run before generating anything)

Before writing any file, assess each target file's freshness:

**For each of the 10 KT targets** (`architecture.md`, `diagrams/system-overview.md`, `diagrams/component-overview.md`, `diagrams/request-processing-flow.md`, `event-story.md`, `patterns.md`, `gotchas.md`, `local-setup.md`, `ai-workflow.md`, `README.md`):

1. **If file does not exist** → decision: `GENERATE` (no further check needed)
2. **If file exists**:
   a. Read the first 5 lines — extract the `Last updated: YYYY-MM-DD` date
   b. For `architecture.md` only: grep the Component Inventory table; compare counts against actual source:
      ```bash
      ACTUAL_CONTROLLERS=$(grep -rn "extends\|@RestController" src/main --include="*.java" | wc -l | tr -d ' ')
      ACTUAL_SERVICES=$(grep -rn "implements.*Service" src/main --include="*.java" | wc -l | tr -d ' ')
      ```
   c. Apply this decision matrix:

   | Condition | Decision | Action |
   |---|---|---|
   | Last updated < 30 days AND no count drift | `SKIP` | Leave file unchanged |
   | Last updated 30–90 days OR count drifted | `UPDATE` | Patch only stale sections; preserve narrative and examples |
   | Last updated > 90 days OR major structural gap | `REWRITE` | Regenerate completely |
   | File missing | `GENERATE` | Create from scratch |

**Present the decision table to the developer before writing anything:**

```
| File                              | Decision  | Reason                              |
|-----------------------------------|-----------|-------------------------------------|
| architecture.md                   | UPDATE ~  | Service count drifted               |
| diagrams/system-overview.md       | SKIP  ✓   | Fresh (updated 5 days ago)          |
| diagrams/component-overview.md    | SKIP  ✓   | Fresh (updated 5 days ago)          |
| diagrams/request-processing-flow.md | SKIP  ✓ | Fresh (updated 5 days ago)          |
| event-story.md                    | REWRITE ✗ | Last updated 95 days ago            |
| patterns.md                       | SKIP  ✓   | Fresh (updated 12 days ago)         |
| gotchas.md                        | UPDATE ~  | Last updated 45 days ago            |
| local-setup.md                    | SKIP  ✓   | Fresh (updated 5 days ago)          |
| ai-workflow.md                    | SKIP  ✓   | Fresh (updated 5 days ago)          |
| README.md                         | UPDATE ~  | Table of contents needs refresh     |
Proceed? (YES / NO / SKIP: file1,file2)
```

- `✓ SKIP` = no write needed
- `~ UPDATE` = partial patch (preserve narrative, fix counts/paths only)
- `✗ REWRITE` = full regeneration
- `✗ GENERATE` = new file

**If developer replies `SKIP: file1,file2`**: exclude those files and proceed with the rest.
**If developer replies anything else**: Clarify: "I need `YES`, `NO`, or `SKIP: file1,file2` (to exclude specific files)."

**IMPORTANT**: Every generated or updated file MUST include a `Last updated: YYYY-MM-DD` header in the first 5 lines so this logic works on the next run.

**If all files are SKIP**: Say "All KT docs are fresh — nothing to regenerate." and end Step 8.

## Step 8.1 — Verify sources before writing

Run grep to confirm these classes exist (record verified paths):

[PROJECT-SPECIFIC — class list below is specific to this project]

| Class | Expected Location | Purpose |
|-------|------------------|---------|
| `CommunicationController` | `src/main/java/.../controller/CommunicationController.java` | REST API entry point |
| `SecurityFilter` | `src/main/java/.../security/SecurityFilter.java` | API key validation filter |
| `RequestValidatorServiceImpl` | `src/main/java/.../service/impl/RequestValidatorServiceImpl.java` | Payload validation |
| `ProducerServiceImpl` | `src/main/java/.../service/impl/ProducerServiceImpl.java` | Kafka publish orchestration |
| `ConfigServiceCircuitBreakerImpl` | `src/main/java/.../circuitbreaker/ConfigServiceCircuitBreakerImpl.java` | Redis→MongoDB fallback |
| `KafkaProducer` | `src/main/java/.../producer/KafkaProducer.java` | Kafka message sending |
| `CommunicationDTO` | `src/main/java/.../dto/request/CommunicationDTO.java` | Inbound request DTO |
| `Data` | `src/main/java/.../dto/request/Data.java` | Notification data container |
| `Recipients` | `src/main/java/.../dto/request/Recipients.java` | Recipient list DTO |
| `APIResponse` | `src/main/java/.../dto/response/APIResponse.java` | Standardised API response |

For any class not found: **OMIT it from the KT doc** and add to a `## Unverified References` section at the bottom of the file with a note: `<!-- OMITTED: ClassName — not found via grep. Verify manually before adding. -->`. Never write unverifiable placeholders into committed docs.

## Step 8.2 — Generate `.github/kt/architecture.md` + diagrams

Apply the Step 8.0 decision for `architecture.md`.

**FIRST: Ensure the diagrams directory exists before writing any diagram file:**
```bash
mkdir -p .github/kt/diagrams
```
This is required when regenerating from scratch (e.g., after deleting the entire `.github/kt/` folder).

**⛔ DIAGRAM GATE**: architecture-diagrammer MUST run for Step 8.2 unless ALL THREE diagram files (`system-overview.md`, `component-overview.md`, `request-processing-flow.md`) have a SKIP decision from Step 8.0 (i.e., all are fresh < 30 days). There are only two valid states:
- **At least one diagram file is UPDATE/REWRITE/GENERATE** → architecture-diagrammer sub-agent MUST be triggered. Do NOT skip.
- **All three diagram files are SKIP** → architecture-diagrammer is not triggered. Log explicitly: "⏭️ DIAGRAM GATE — skipping architecture-diagrammer: all 3 diagram files are fresh (< 30 days)." This log line is MANDATORY — do not silently skip.

If architecture-diagrammer is triggered but returns no output or fails: Stop — "architecture-diagrammer did not complete successfully. Cannot continue KT generation without diagrams. Retry or diagnose the failure."

If `UPDATE` or `REWRITE` or `GENERATE`: Trigger **architecture-diagrammer** sub-agent: "Generate a system overview diagram showing REST endpoints, validation pipeline, config resolution, Kafka publishing, and data stores."

Save/update:
- `.github/kt/architecture.md` — narrative summary + Component Inventory table + links to diagrams
- `.github/kt/diagrams/system-overview.md` — full Mermaid system graph
- `.github/kt/diagrams/component-overview.md` — all controllers, services, DTOs, filters (apply 8.0 decision per file)
- `.github/kt/diagrams/request-processing-flow.md` — 3 sequence diagrams: request flow, config cache, Kafka publish (apply 8.0 decision per file)

All diagram files: add `Last updated: YYYY-MM-DD` header.

## Step 8.3 — Generate `.github/kt/event-story.md`

**This is the most valuable KT file.** It tells a narrative story, not a class list.

Title: "What Happens When a Notification Request Arrives? (End-to-End Story)"

Opening: _"A customer in Dubai (mafuae) just had their order delivered. The order management system sends a notification request to this project. Here is exactly what happens in the milliseconds between that REST call and the Kafka message landing on the right priority topic."_

[PROJECT-SPECIFIC — entire story content is specific to this project]

The story covers 8 steps, each with this format:
```
### Story Segment: [Plain English Title]
**Class:** `ClassName` at `src/main/java/[verified-path]`
**Method:** `methodName()`
**What happens:** [one paragraph, plain English]
**Why this way:** [one sentence on design decision]
```

Steps to cover:
1. Upstream system sends POST to `/api/v2/communication/notification`
2. `SecurityFilter` intercepts — validates `x-api-key` header against `SecurityConfig.keys`
3. `CommunicationController` receives the validated request
4. `RequestValidatorServiceImpl` validates CommunicationDTO fields and resolves config
5. `ConfigServiceCircuitBreakerImpl` fetches config from Redis (or falls back to MongoDB)
6. `ProducerServiceImpl` determines priority topic and prepares the Kafka message
7. `KafkaProducer` sends the message to the appropriate Kafka topic
8. Response returned to caller with tracking ID

After all steps: include a Mermaid sequence diagram of the full flow.
End with: "**Key insight:** [what makes this a gateway — it validates and routes, it does NOT process notifications]"

## Step 8.4 — Generate `.github/kt/patterns.md`

For each pattern from Step 3's table:
- Name, purpose, interface (verified path), example implementation (verified path)
- "How to add a new instance" — step-by-step instructions

## Step 8.5 — Generate `.github/kt/gotchas.md`

Source: `onboarding-guide.md` Top 10 Gotchas. Expand each with:
- What goes wrong
- How to detect it
- How to fix it

## Step 8.6 — Generate `.github/kt/local-setup.md`

Source: Level 0 walkthrough. Include:
- Clone → configure profiles → run tests → verify setup
- IDE setup (IntelliJ plugins: Mermaid, Lombok)
- Environment variables, local profile, common errors

## Step 8.7 — Generate `.github/kt/ai-workflow.md`

A codebase-specific quick-start for the AI workflow:
- Skill invocation table (skill + when + exact phrase)
- 3 worked examples (bug fix, new API endpoint, config change)
- "Your first 5 commands after onboarding"

## Step 8.8 — Generate `.github/kt/README.md` (LAST)

Index of all files with reading order per role:
- New developer: start with `event-story.md` → `architecture.md` → `patterns.md`
- Reviewer: start with `patterns.md` → `gotchas.md`
- Bug fixer: start with `event-story.md` → `gotchas.md`

Include:
- Link to `diagrams/` subfolder with brief description of each diagram file
- How to regenerate: `use the onboarding skill` → L2+ → YES (smart update: only stale files are rewritten)
- How auto-regeneration works: `docs-drift-notify.yml` opens a `docs-drift` issue on push to main/develop when component counts drift
- How to commit: `git add .github/kt/ && git commit -m "docs(kt): update KT documents"`

## Smart Defaults

```
"I'll walk you through this codebase. Tell me:
  - Your role and experience level
  - Focus area or ticket number (if any)
  - Preferred depth (quick overview vs deep-dive)
Or press Enter for a Level 2 architecture deep-dive."
```

## Exit Conditions / Done Definition

- [ ] Walkthrough level selected and completed
- [ ] Developer explored at least one deep-dive area (Step 3 or 4), or explicitly skipped
- [ ] Developer can name the entry points, processing layers, and key patterns
- [ ] Developer has received the **rich next-steps menu** (see below) — not just a single suggestion
- [ ] Developer confirms understanding (verbal acknowledgment)
- [ ] If YES to KT output: `.github/kt/` folder created with 10 files (7 in `kt/` root + 3 Mermaid diagrams in `kt/diagrams/`)

**⛔ EXIT GATE**: The onboarding is NOT complete until ALL of the above are met. Specifically:
- Step 3 deep-dive menu was presented via `ask_user` (or plain text fallback if ask_user unavailable)
- Step 4 pattern menu was presented via `ask_user` (or plain text fallback, or skipped by user)
- Rich next-steps menu below was presented (ALL options, not summarized)
- **⛔ KT FILE GATE** — KT folder has exactly 10 files (7 root + 3 diagrams). This MUST be verified by running the command — do not assume:
  ```bash
  find .github/kt/ -type f -not -name '.gitkeep' | sort
  ```
  Expected output: exactly 10 paths. If count < 10: identify which files are missing, re-run the corresponding Step 7.x sub-step. If count > 10: unexpected files present — list them and ask developer whether to remove.
If any gate is not met, loop back to the missed step before closing.

## Rich Next-Steps Menu (MANDATORY — always present at end of Level 2+)

After completing the walkthrough, present the canonical `## Skill Completion` → `### 🔀 Next Steps (skill-specific)` menu defined near the end of this file. Never end with a single suggestion. Present all options, then make one **role-aware recommendation** based on the developer's answers to the clarifying questions.

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|-----------|---------|-------|--------|
| code-explorer | Step 3 — architecture deep dives (on developer selection) | Specific component/flow (e.g., "Request pipeline", "SecurityFilter API key flow") | Explanation with file:line references |
| code-explorer | Step 4 — pattern deep dives (on developer selection) | Specific pattern target (e.g., "circuit breaker fallback", "Kafka producer routing") | Code walkthrough with file:line references |
| code-explorer | Step 5/6 — ticket or feature deep-dives | Class name or flow to explore | Explanation with file:line references |
| architecture-diagrammer | Step 2 — default for Level 2+ | Request for visual overview | Architecture diagram |
| architecture-diagrammer | Step 8.2 — KT generation | "Generate system overview" | `.github/kt/architecture.md` |

## Example Invocation

**Example 1: Standard onboarding with ticket**
```
Developer: "I'm a new backend engineer joining the team. I have ticket COM-456."
AI:
  1. Reads 7 context files → "I've read 7 of 7 context files. Missing: none."
  2. Asks clarifying questions → learns: backend, familiar with Spring Boot, has ticket
  3. Selects Level 3 (first-ticket walkthrough)
  4. Delivers architecture overview with entry points and pipeline
  5. [Step 3] Offers deep-dive menu → developer picks "Request pipeline"
     → code-explorer traces CommunicationController → RequestValidatorServiceImpl → ProducerServiceImpl with line refs
  6. Explains key patterns with file:line references
  7. [Step 4] Offers pattern deep-dive menu → developer picks "Circuit Breaker"
     → code-explorer shows Resilience4j state machine with real file paths
  8. Introduces AI workflow phases
  9. Walks through COM-456: identifies affected areas, maps to workflow phases
  10. Presents FULL next-steps menu (9 options)
  11. "⭐ My recommendation for a Backend Engineer with ticket: Option 1 — use the spec-writer skill for COM-456"
```

**Example 2: Onboarding with KT generation**
```
Developer: "I'm new to this team. Walk me through the codebase."
AI:
  1. Reads 7 context files → confirms
  2. Asks clarifying questions → L2 deep-dive, no specific ticket
  3. Architecture overview + [Step 3 deep-dive menu offered] + patterns + [Step 4 offered] + AI workflow
  4. "Would you like me to generate .github/kt/ — 10 files your team can commit?"
Developer: "YES"
AI:
  5. Step 8.0: all files missing → all decisions: GENERATE
  6. Runs: mkdir -p .github/kt/diagrams
  7. Verifies source classes (Step 8.1) → 10/10 found
  8. Generates architecture.md, diagrams/system-overview.md, diagrams/component-overview.md,
     diagrams/request-processing-flow.md, event-story.md, patterns.md, gotchas.md,
     local-setup.md, ai-workflow.md, README.md
  9. ".github/kt/ generated — 10 files. Commit: git add .github/kt/"
  10. Presents FULL next-steps menu (9 options)
  11. "⭐ My recommendation for a Tech Lead: Option 5 (blast-radius) — understand the impact surface before making your first change."
```

**Example 3: Deep-dive session**
```
Developer: "Explain the architecture to me."
AI:
  1-3. Architecture overview presented
  4. [Step 3] "Want to go deeper?" → developer selects options 1 and 3
     → code-explorer: Request pipeline with file:line refs
     → code-explorer: Config cache chain with Resilience4j state machine
  5. Patterns overview
  6. [Step 4] "Which pattern?" → developer picks "Kafka Producer"
     → code-explorer traces ProducerServiceImpl → KafkaProducer → priority topic selection
  7. Full 9-option next-steps menu presented
  8. "⭐ My recommendation..." based on role
```

## What I Will NOT Do

- Write application code or modify source files
- Assume what the developer already knows — always ask first
- Skip pattern explanations — walk through every major pattern
- Provide project-specific details without reading actual source code first
- Generate KT files without explicit YES from developer
- End with only one next-step suggestion — always present the full 9-option menu
- Skip Step 3 and Step 4 deep-dive pauses — always offer them, even if developer skips

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Files to Read First | One or more context files missing | Warn and continue. Fall back to reading src/ directly. Stop only if AGENTS.md or src/ is missing. |
| Step 2 (architecture) | Cannot verify a class mentioned in copilot-instructions.md | grep src/ for partial match. If truly missing, note it as stale documentation. |
| Step 3/4 (deep dive) | code-explorer sub-agent returns empty result | Report: "code-explorer found no results for [target]. Possible: (1) misspelled, (2) dynamic dispatch, (3) unused code." |
| Step 8 (KT generation) | Cannot create .github/kt/ directory | Check permissions. Try `mkdir -p .github/kt/diagrams`. If fails, save to alternative location. |
| Step 8.0 (freshness) | Cannot determine file age (no date header) | Default to REWRITE for that file. |

---

---

## Step 9 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ onboarding — done?
  □ Steps 0–9 executed (including this step) (+ sub-steps 8.0–8.8 for KT generation)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next? (pick what fits your situation)

  A) Start a feature           — say: "use the spec-writer skill for COM-XXX"
  B) Fix a bug                 — say: "use the bug-tracer skill — [symptom]"
  C) Explore specific code     — say: "use the code-explorer skill — [class/flow]"
  D) Check change impact       — say: "use the blast-radius skill on [ClassName]"
  E) Review a PR               — say: "give me all open PRs"
  F) Get help                  — say: "help"

⭐ Recommend: A (if you have a ticket) or C (if still exploring) — start building
  or exploring once you feel oriented.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Role-aware tip** (add after ASCII box):
- Tech Lead → blast-radius + architecture-diagrammer first
- Engineer with ticket → spec-writer immediately
- New to codebase → code-explorer for one flow before touching code

