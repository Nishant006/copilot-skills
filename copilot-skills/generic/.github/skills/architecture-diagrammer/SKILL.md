---
name: architecture-diagrammer
description: "Generate Mermaid architecture diagrams from source code analysis"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [code-explorer]
triggered-by: [spec-writer, onboarding, lifecycle-flow, pr-preparation, feature-docs]
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Generate accurate Mermaid diagrams by reading source code — not from memory or assumptions.
Produces two diagram types: **high-level system overview** (service boundaries, data stores, external integrations)
and **low-level sequence diagrams** (specific flows through the codebase).

Use this skill when:
- A new developer needs to visualize the architecture
- A new feature requires a proposed flow diagram before implementation
- Existing architecture docs are missing or stale
- A PR changes the system's topology (new integration, new message flow)

## Entry Conditions

- Codebase is accessible (can read `src/main/java/`, config files, `pom.xml`)
- If generating a feature-specific diagram: `features/<ticket-id>/spec.md` must exist with `Status: APPROVED`
- If no source code access: **STOP. Cannot generate diagrams without source code access. Do not continue.**

## Clarifying Questions

Before generating ANY diagram, ask:

- What type of diagram do you need? (system overview / sequence diagram / data flow / component diagram)
- What scope? (entire system / specific module / specific feature flow)
- What level of detail? (high-level service boundaries / mid-level class interactions / low-level method calls)
- Should this diagram be saved to `.github/kt/diagrams/` or is it for conversation only?
- For feature diagrams: Is this a PROPOSED flow (pre-implementation) or ACTUAL flow (documenting existing)?

If the developer says "just give me an overview" → default to high-level system diagram of the entire project.

**Sub-agent mode exception**: When auto-triggered by a parent skill (spec-writer, lifecycle-flow, onboarding, pr-preparation, feature-docs), skip clarifying questions. Use the scope and type specified by the parent's invocation context. Default to: system overview, high-level, saved to `.github/kt/diagrams/`.

Proceed only after answers are received (or sub-agent mode confirmed).

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill, check if `graphify-out/graph.json` exists. If it does, run `graphify query "list all controllers, services, filters, and Kafka producers"` and `graphify export callflow-html` first. Use grep only to verify specific nodes or supplement. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Entry Conditions

```bash
# Check: does a knowledge graph exist?
test -f graphify-out/graph.json \
  && echo "✅ Graph found — use graphify export callflow-html for diagrams" \
  || echo "ℹ️ No graph — will use grep-based discovery"
# Check: what source code is available?
ls src/ 2>/dev/null | head -5 || find . -name "*.java" -maxdepth 4 | head -3
```
**No hard stop — informational. If graph exists, prefer graphify for diagram generation.**

## Step 1: Discover Architecture

```bash
# Find entry points (controllers, filters, scheduled tasks)
grep -rn "@RestController\|@Controller\|@Scheduled" src/main/java/ --include="*.java" -l

# Find filters (security, request context)
grep -rn "OncePerRequestFilter\|Filter" src/main/java/ --include="*.java" -l

# Find service layer
grep -rn "@Service" src/main/java/ --include="*.java" -l

# Find Kafka producers
grep -rn "KafkaTemplate\|KafkaProducer\|@KafkaListener" src/main/java/ --include="*.java" -l

# Find data stores
grep -rn "@Document\|@Entity\|@Repository\|MongoTemplate\|RedisTemplate" src/main/java/ --include="*.java" -l

# Find config/properties
grep -rn "@ConfigurationProperties\|@Value" src/main/java/ --include="*.java" -l | head -20

# Find circuit breakers
grep -rn "@CircuitBreaker" src/main/java/ --include="*.java" -l
```

```bash
# ✓ Check before moving on: At least one category of components (controllers, services, data stores) is disc
# Verify Step 0 conditions above before proceeding
```
## Step 2: Build Component Map

From grep results, categorize into layers:
1. **Ingestion**: Controllers, filters (what receives and authenticates requests)
2. **Validation**: Validators, DTO annotations (what validates payloads)
3. **Processing**: Services, circuit breakers (what orchestrates business logic)
4. **Integration**: Kafka producers (what publishes to downstream systems)
5. **Persistence**: Redis, MongoDB (what stores config and state)
6. **Configuration**: Properties, security config (what controls behavior)
7. **Scheduling**: Scheduled tasks, cron triggers (what handles timed operations)

```bash
# ✓ Check before moving on: Every component in the map has a grep-confirmed file path. No component is inven
echo 'Step done: Every component in the map has a grep-confirmed file path. N'
```
## Step 3: Generate Diagram

Use Mermaid syntax. Choose diagram type based on request:

**System Overview** → `graph TD` (top-down flowchart)
**Sequence Diagram** → `sequenceDiagram` (for specific flows)
**Data Flow** → `flowchart LR` (left-right data movement)
**Component Diagram** → `graph TD` with subgraphs per layer

```bash
# ✓ Check before moving on: Every node in the diagram corresponds to a real class/component confirmed in Ste
# Diagram output in response above — scan for mermaid block
```
**Diagram Format:**
- Default: Mermaid (renderable in GitHub, IntelliJ with Mermaid plugin, VS Code)
- Fallback: If developer requests PlantUML, generate `@startuml/@enduml` syntax instead
- Ask: "Mermaid or PlantUML?" only if developer hasn't specified a preference. Default to Mermaid.

**C4 Model Conventions:**
For system-level diagrams, follow C4 model levels:
- **Level 1 (Context)**: System boundary, external actors, external systems → use for `.github/kt/diagrams/system-overview.md`
- **Level 2 (Container)**: Internal containers (services, databases, message brokers) → use for `.github/kt/diagrams/component-overview.md`
- **Level 3 (Component)**: Internal components within a container → use for feature-specific diagrams

Label each diagram with its C4 level in the title: `# System Overview (C4 Level 1)`

Rules:
- Every node MUST correspond to a real class/component found in Step 1
- Every arrow MUST represent a real method call or message flow verified by grep
- Label arrows with the communication method (HTTP, Kafka, direct call, DI)
- Use subgraphs to group related components
- Include external systems as distinct nodes (databases, message brokers, third-party APIs)

## Step 4: Verify Accuracy

For every connection in the diagram:
```bash
# Verify that ClassA actually calls/references ClassB
grep -rn "ClassB" src/main/java/.../ClassA.java
```

If a connection cannot be verified by grep, mark it with `-.->` (dashed arrow) and add a note: "Inferred — verify with IDE Find Usages."

```bash
# ✓ Check before moving on: Every solid-line connection in the diagram has grep evidence. All unverified con
# Diagram output in response above — scan for mermaid block
```
## Step 5: Save or Present

Ask the developer (once):
```
How would you like the diagrams?
  A) Save to .github/kt/diagrams/ (recommended for team sharing)
  B) Show inline in this conversation only
  C) Both — save and show
```

**If A or C — save the diagrams:**
```bash
mkdir -p .github/kt/diagrams
# Write diagram files — one per diagram type generated in Steps 1-4
ls .github/kt/diagrams/ && echo "Diagrams saved"
```

**If B — show inline only:** Paste the Mermaid block(s) in the response.

```bash
# Verify: at least one diagram file exists (for save mode)
ls .github/kt/diagrams/*.md 2>/dev/null | head -5
```


## Diagram

```mermaid
[diagram content]
```

## Legend

| Symbol | Meaning |
|---|---|
| `-->` | Direct method call or DI injection |
| `-.->` | Inferred connection (verify with IDE) |
| `===>` | Message flow (Kafka/HTTP) |

## Components Referenced

| Component | File Path | Role |
|---|---|---|
| [Name] | [path] | [purpose] |
```

## Exit Conditions / Done Definition

- [ ] Diagram generated with ONLY verified components (no invented classes)
- [ ] Every connection verified by grep (or explicitly marked as inferred)
- [ ] Legend included explaining all symbols
- [ ] If saved: file written to `.github/kt/diagrams/` or `features/<ticket-id>/`
- [ ] Developer confirms the diagram is accurate or provides corrections (manual invocation only — when auto-triggered as sub-agent, return diagram to parent skill without separate developer confirmation)

## Sub-Agents

| Sub-Agent | When Triggered | Input | Output |
|---|---|---|---|
| `code-explorer` | When a component's role is unclear during Step 2 | Class name + "what does this do?" | Explanation of class purpose and dependencies |

## Example Invocation

**Developer:** "Generate a system architecture diagram for this project"

**AI Response:**
```
I'll generate a system overview diagram. Let me analyze the codebase first.

Diagram type: System overview (high-level)
Scope: Entire project
Detail level: Service boundaries + external integrations

Scanning entry points... [runs grep commands]
Found: 4 controllers, 2 filters, 1 Kafka producer
Found: 6 service classes
Found: MongoDB + Redis data stores

Generating Mermaid diagram...

[displays diagram]

Save to .github/kt/diagrams/system-overview.md? (yes/no)
```

**Developer:** "Create a sequence diagram for the notification dispatch flow"

**AI Response:**
```
I'll trace the notification dispatch flow. Let me ask:
- Which specific endpoint? (e.g., POST /v2/communication, scheduled notification)
- What level of detail? (controller-to-Kafka or include security + validation steps)

[after answers, traces the flow via grep, generates sequence diagram]
```

## What I Will NOT Do

- Invent components that don't exist in the source code
- Generate diagrams from memory — every node must be grep-verified
- Create deployment or infrastructure diagrams (Kubernetes, cloud topology) — those require ops context
- Modify any source code

---

## Refresh Mode (Architecture Sync)

**Entry Mode**: Invoked by saying `"use the onboarding skill"` → Level 2+ → YES, or auto-triggered by `pr-preparation` skill when topology-changing paths are detected.

**Entry Condition**: `.github/kt/diagrams/` folder exists with at least 1 `.md` file.

**When to use**: After a PR changes topology-adjacent code (new controller, new integration, renamed class) and docs need updating — but you don't want to regenerate from scratch.

### Refresh Steps

**R1. Count Drift Detection**
Run the same counts used by CI:
```bash
# [PROJECT-SPECIFIC] Count commands — update for your project structure
ACTUAL_CTRL=$(find src/main -path "*/controller/*" -name "*.java" | wc -l)
ACTUAL_SVC=$(find src/main -path "*/service/*" -name "*.java" | wc -l)
ACTUAL_CONFIG=$(find src/main -path "*/config/*" -name "*.java" | wc -l)
ACTUAL_DTO=$(find src/main -path "*/dto/*" -name "*.java" | wc -l)
ACTUAL_FILTER=$(find src/main -path "*/security/*" -name "*.java" | wc -l)
ACTUAL_UTIL=$(find src/main -path "*/util/*" -name "*.java" | wc -l)
ACTUAL_SCHEDULED=$(find src/main -path "*/scheduled/*" -name "*.java" | wc -l)
```
Compare against values in `.github/kt/architecture.md` Component Inventory table.

**R2. Identify What Changed**
```bash
# Show recent topology changes
git log --oneline -20 -- src/main/java/**/controller/ src/main/java/**/service/ src/main/java/**/security/ src/main/java/**/producer/ src/main/resources/application-*.yml
```
List discrepancies: which counts drifted, which new classes appeared, which were deleted.

**R3. Targeted Section Update**
For each discrepancy, present:
```
Drift found:
  - architecture.md: Controllers — doc says 3, actual is 4
  - diagrams/component-overview.md: Controllers table missing NewController
  - diagrams/system-overview.md: diagram may need new node

Update architecture.md Component Inventory? (YES = update / NO = keep existing / SKIP = proceed without diagrams)
Update diagrams/component-overview.md Controllers table? (YES = update / NO = keep existing / SKIP = proceed without diagrams)
Update diagrams/system-overview.md diagram? (YES = update / NO = keep existing / SKIP = proceed without diagrams)
```
On YES: regenerate ONLY that specific section, not the entire file.

**R4. Anti-Hallucination Rules for Refresh**
- **NEVER** update a count without running the count command first
- **NEVER** add a class to a diagram without grep-verifying it exists: `find src/main -name "ClassName.java"`
- **NEVER** remove a node from a diagram without confirming the class was deleted: `find src/ -name "ClassName.java"` must return empty
- **NEVER** modify a section without showing the before/after diff to the developer

**R5. Update Last Updated Header**
Update `Last updated: YYYY-MM-DD` header in every file touched.

**R6. Report**
```
Refresh complete:
  - [N] sections updated
  - [M] sections already current
  - Files modified: [list]
  
Run 'use the architecture-diagrammer skill' for a full regeneration if needed.
```

---

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 2 (exploration) | code-explorer returns stale or missing component | Grep src/ directly. If component was renamed/removed, update diagram. |
| Step 5 (Mermaid) | Diagram is too large to render | Split into sub-diagrams: system overview + component detail + sequence flows. |
| Step 6 (save) | Cannot write to `.github/kt/diagrams/` | Check directory exists: `mkdir -p .github/kt/diagrams`. Check permissions. |
| Refresh mode | Component counts don't match architecture.md | Update counts. Flag drift in the output. |

---

## Step 6 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ architecture-diagrammer — done?
  □ Steps 0–6 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Check impact of changes        — say: "use the blast-radius skill on [class from diagram]"
  B) Start building                 — say: "use the impl-planner skill for COM-XXX"
  C) Discuss architecture           — say: "use the party-mode skill — [architecture question]"
  D) Get help                          — say: "help"

⭐ use the diagram to guide deeper exploration of unfamiliar components.

💾 Save output? "Save as MD? (YES — specify path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
