---
name: code-explorer
description: "Navigate, trace, and explain unfamiliar code paths and patterns"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: []
triggered-by: [spec-writer, onboarding, bug-tracer, lifecycle-flow, architecture-diagrammer, idea-to-spec, feature-docs]
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Sub-agent for code navigation and explanation. Use when a developer needs to understand how a component works, trace a data/control flow between two points, or build a mental model of unfamiliar code. Produces conversation-only output — no files are created or modified.

## Entry Conditions

1. Developer (or parent skill) specifies a **target**: class name, interface, pattern name, or a flow between two points (e.g., "from A to B").
2. The repository must be cloned locally with source under `src/`.
3. If the target is ambiguous → **STOP. Ask: "Which specific class/flow? Provide a name or describe the start and end points." Do not continue.**

## Clarifying Questions

Ask these before proceeding (skip any already answered):

1. What **level of detail** do you need — high-level overview or deep-dive into implementation?
2. What **aspect** are you interested in — data flow, control flow, dependency graph, or a specific class?
3. Is there a **specific question** you want answered (e.g., "Why does X call Y?" or "Where is Z configured?")?

Proceed only after answers are received (skip when invoked as sub-agent — parent provides context).

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill, check if `graphify-out/graph.json` exists. If it does, run `graphify query "<target question>"` or `graphify explain "<TargetName>"` first. Use grep only to supplement graphify results or when graph is unavailable. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Entry Conditions

```bash
# Check: does a knowledge graph exist? (enables graphify-first)
test -f graphify-out/graph.json && echo "✅ Graph found — will use graphify first" || echo "ℹ️ No graph — will use grep discovery"
```
**No hard stop — informational. If graph exists, use graphify query before grepping.**

## Step 1 — Find the Target

```bash
# Locate the class/interface/constant
grep -rn "TargetName" src/ --include="*.java" -l
```
```bash
# ✓ Check before moving on: File path(s) identified. If not found → report "Target not found in codebase" an
echo 'Step done: File path(s) identified. If not found → report "Target not f'
```
## Step 2 — Read and Understand Structure

Read the target file. Identify:
- Class hierarchy (extends/implements)
- Fields and their types (dependency injection points)
- Public methods (the contract)
- Annotations (framework behavior: `@Service`, `@Component`, `@EventListener`, etc.)

```bash
# ✓ Check before moving on: Class role summarized in one sentence with file path and line range.
echo 'Step done: Class role summarized in one sentence with file path and lin'
```
**For classes > 300 lines:**
1. Read fields + constructor FIRST to understand dependencies
2. Group methods by concern (public API → private helpers → static utilities)
3. Identify the dominant design pattern (fan-out? routing? factory? decorator?)
4. Summarize: "This class is primarily a [pattern]. Its core job is [one sentence]. It has [N] dependencies and [M] public methods grouped into [concern groups]."

## Step 3 — Trace Callers (who uses this?)

```bash
grep -rn "TargetName" src/main/java/ --include="*.java" | grep -v "import\|package"
```
```bash
# ✓ Check before moving on: List of callers with file paths and line numbers.
echo 'Step done: List of callers with file paths and line numbers'
```
## Step 4 — Trace Callees (what does this depend on?)

Read the target's constructor/fields. For each dependency:
- Identify the concrete implementation
- Note if it is injected via DI or instantiated directly

```bash
# ✓ Check before moving on: Dependency list with concrete types and injection method.
echo 'Step done: Dependency list with concrete types and injection method'
```
**For external/third-party dependencies:**
[PROJECT-SPECIFIC — examples below reference this codebase's libraries]
When a class depends on a third-party library (e.g., Resilience4j, Braze SDK, Infobip API):
1. Do NOT attempt to read third-party source code
2. Instead, explain the external contract FROM ITS USAGE in this codebase
3. Example: "ConfigServiceCircuitBreakerImpl uses @CircuitBreaker(name='redisService'). From usage, this means: calls to Redis are wrapped; when failures exceed threshold, the circuit opens and fallback method is called directly."

## Step 5 — Map the Flow

Choose the appropriate navigation strategy:

| Strategy | When to Use | Method |
|----------|-------------|--------|
| **Top-down** | "How does request X get processed?" | Entry point → router → handler → service → output |
| **Bottom-up** | "Who uses utility Y?" | Utility → direct callers → their callers → entry points |
| **Breadth-first** | "What are all handlers at this level?" | List all siblings (e.g., all implementations of an interface) |

Trace the flow step-by-step, recording each hop with file path and line number.

```bash
# ✓ Check before moving on: Numbered flow trace from start to end (or root to leaves).
echo 'Step done: Numbered flow trace from start to end (or root to leaves)'
```
## Step 6 — Explain in Context

Synthesize findings into a structured explanation:
1. **What it is** — one-sentence role
2. **How it works** — step-by-step flow with file:line references
3. **Why it matters** — its role in the broader architecture
4. **Related components** — sibling classes, shared interfaces, config files

**Step 6a — Grep-Verify All Class References**

Before delivering the explanation, grep-verify every class name, interface name, and file path referenced in the explanation:
```bash
grep -rn "ClassName" src/main/java/ --include="*.java" -l
```
- If a referenced class does NOT exist: remove it or replace with the verified name.
- If unsure: add footnote: `⚠️ [ClassName] — not verified in current codebase`.

```bash
# ✓ Check before moving on: Explanation delivered with every claim backed by a file:line reference. All clas
echo 'Step done: Explanation delivered with every claim backed by a file:line'
```
```bash
# Verify: explanation covers the requested component
echo "Explanation complete — check that file:line references were included"
```

## Step 7 — Design Rationale Mode (when developer asks "why is it built this way?")

If the developer asks WHY code is structured a certain way (not just HOW):
1. Identify the design pattern in use
2. Identify what ALTERNATIVES could have been used
3. Infer the rationale from the code's constraints:
   - If Map<String, T> injection → "Allows adding new implementations without modifying factory code (OCP)"
   - If CompletableFuture fan-out → "Channels are independent; parallel dispatch reduces total latency"
   - If circuit breaker → "Redis failures should not cascade to block all config lookups"
4. Present as: "This is built using [pattern] because [inferred rationale]. The alternative would be [X], but that would [drawback]."

```bash
# ✓ Check before moving on: Design rationale presented with pattern name, inferred reason, and alternative c
graphify query "What classes are related to <target>?" 2>/dev/null || grep -rn "<TargetClass>" src/ --include="*.java" 2>/dev/null | head -10
```
## Step 8 — Handoff to Blast-Radius (optional)

After completing the exploration, offer:
"Want to see what depends on [explored class]? I can run blast-radius analysis to show all callers and assess change risk."
This creates a natural transition: code-explorer → blast-radius when the developer is considering changes.

```bash
# ✓ Check before moving on: Handoff offer was presented to the developer with the specific class name from e
graphify query "What classes are related to <target>?" 2>/dev/null || grep -rn "<TargetClass>" src/ --include="*.java" 2>/dev/null | head -10
```
## Exit Conditions / Done Definition

- [ ] Target located in codebase with file path confirmed
- [ ] Callers and callees identified with file:line references
- [ ] Flow traced using appropriate navigation strategy
- [ ] Explanation delivered with zero unverified claims
- [ ] Developer confirms understanding (verbal acknowledgment) — **when invoked manually only**

**When invoked as sub-agent**: Exit conditions 1-4 apply. Condition 5 (developer confirmation) is waived — return results to parent skill immediately.

## Sub-Agents

None — this skill is a leaf-node sub-agent. It does not trigger other skills.

## Example Invocation

**"How does X work?"**
```
Developer: "How does the event processing pipeline work?"
AI: Runs Steps 1–6 using top-down strategy. Delivers explanation with file:line references.
```
**"Trace flow from A to B"**
```
Developer: "Trace the flow from message receipt to SMS delivery."
AI: Delivers numbered flow: Consumer(file:line) → Processor(file:line) → Service(file:line).
```
**Auto-triggered by parent skill:**
```
spec-writer: "Use code-explorer to understand existing patterns."
AI: Skips clarifying questions → runs Steps 1–6 → returns pattern summary.
```

## What I Will NOT Do

- Modify code or create files — conversation only
- Assume code exists without grep verification
- Guess at runtime behavior without source code evidence
- Provide explanations without file:line references

---

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 2-4 (exploration) | Cannot find the class/method mentioned | Try partial name grep. Check for typos. If truly missing, report as stale reference. |
| Step 6 (structural) | Code path is too complex to trace (10+ classes) | Summarize at module level first. Deep-dive only into the specific 2-3 classes the developer asks about. |
| Step 8 (blast-radius) | Developer wants to change explored code but blast-radius not yet run | Route to blast-radius: "Before changing this, let's check impact: use the blast-radius skill on [class]" |
| Any step | Dynamic dispatch hides the real implementation | Check factory/map patterns. Grep for interface impls: `grep -rn "implements InterfaceName" src/` |

---

## Step 9 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ code-explorer — done?
  □ Steps 0–9 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Check change impact                    — say: "use the blast-radius skill on [explored class]"
  B) Explore another area                   — say: "use the code-explorer skill — [next area]"
  C) Start building                         — say: "use the spec-writer skill for COM-XXX"
  D) Discuss what you found                 — say: "use the party-mode skill — [topic from exploration]"
  E) Get help                              — say: "help"

⭐ If exploring to prepare for a change → Option 1. If learning → Option 2.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
