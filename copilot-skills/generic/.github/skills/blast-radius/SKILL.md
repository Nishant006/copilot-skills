---
name: blast-radius
description: "Analyze what code will break if a specific class, method, or field is changed"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: []
triggered-by: [impl-planner, implement-and-test, code-reviewer, pr-preparation, safe-refactor, bug-tracer, postman-collection]
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Canonical sub-agent for impact analysis. Invoke before any rename, removal, signature change, or field modification to enumerate every caller, injection site, and message-flow dependency. Other skills delegate here — they do not duplicate these patterns.

## When to Use / When NOT to Use

| ✅ Use blast-radius when... | ❌ Do NOT use blast-radius when... |
|---|---|
| Renaming a class, method, or field | Adding a **new** class with no existing callers |
| Removing a class, method, or field | Changing YAML/properties config only (no Java) |
| Changing a method signature (params, return type) | Adding a new method to an existing class (no callers yet) |
| Modifying a DTO field used across services | Updating documentation or KT files |
| Before refactoring a core pipeline class | Writing new tests for existing code |
| Parent skill requires impact analysis | Always run — even if 0 callers found, report LOW risk so parent has a record |

**Rule**: Always run blast-radius when triggered. For purely additive changes with 0 callers, report LOW risk — never skip. The caller count IS the output.

## Entry Conditions

1. Developer (or parent skill) specifies an **exact target**: fully-qualified class name, method signature, DTO field, or config key.
2. If the target is ambiguous → **STOP. Ask "Which exact class/method? Provide the fully-qualified name or unambiguous short name." Do not continue.**
3. The repository must be cloned locally with source under `src/`.

## Clarifying Questions

**When invoked manually** (developer directly calls blast-radius): Ask these before proceeding:

1. What is the **exact class/method/field** to analyze?
2. What type of change is planned — **rename, removal, or signature change**?
3. What is the expected scope — **single module or cross-module**?

**When invoked as sub-agent** (triggered by parent skill): Skip clarifying questions — the parent provides target and context in the trigger payload. Proceed directly to Step 2 (skip Step 1 IDE recommendation).

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill, check if `graphify-out/graph.json` exists. If it does, run `graphify path "TargetName" "*"` first to get callers and dependents from the knowledge graph. Use grep only to supplement or verify graphify results. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Target

```bash
# Confirm target is specified before starting analysis
echo "Target to analyze: [class/method/field name provided]"
```

Confirm a specific target was provided (class name, method name, field, config key, or file path).

**STOP. If no specific target was named, ask: "What specific class, method, or field do you want to analyze? Provide the exact name." Do not start analysis without a concrete target.**

## Step 1 — IDE-First Recommendation (manual invocation only)

> **Skip this step when running as a sub-agent.** Sub-agents need fast automated results.

Recommend IDE tooling first — it is 100% accurate unlike text search:
```
Find Usages:       Alt+F7 (IntelliJ) / Shift+F12 (VS Code) → complete caller graph
Call Hierarchy:    Ctrl+Alt+H → full upstream call chain
Data Flow:         Analyze Data Flow → tracks field propagation
```
```bash
# ✓ Check before moving on: Developer confirms IDE is unavailable or results are shared.
echo 'Step done: Developer confirms IDE is unavailable or results are shared'
```
## Step 2 — CLI Grep Analysis (fallback — ~50-60% accurate for Java)

```bash
grep -rn "TargetName" src/main/java/ --include="*.java"                  # d=1: direct callers
grep -rn "@Autowired\|@Inject\|@RequiredArgsConstructor" src/ --include="*.java" | grep "TargetName"  # DI wiring
grep -rn "\.fieldName\|getFieldName\|setFieldName" src/main/java/ --include="*.java"  # field-level
grep -rn "Listener\|Template\|Producer\|Consumer" src/ --include="*.java" | grep -i "TargetName"  # message brokers
grep -rn "Factory\|Map<String" src/ --include="*.java" | grep "TargetName"  # dynamic dispatch
```
```bash
# Verify: grep found callers (or confirmed none exist)
grep -rn "ClassName\|methodName" src/ --include="*.java" 2>/dev/null | grep -v "^Binary" | head -15
```
(Replace `ClassName` / `methodName` with the actual target from the request.)
```bash
# ✓ Check before moving on: Grep results saved; count of direct callers recorded.
echo 'Step done: Grep results saved; count of direct callers recorded'
```
## Step 3 — Risk Assessment

| References Found | Risk Level | Notes |
|------------------|------------|-------|
| < 5 | LOW | Localized change |
| 5–15 | MEDIUM | Cross-cutting; review callers |
| > 15 | HIGH | Broad impact; consider phased rollout |
| Core component* | CRITICAL | Regardless of count |

\* Core components are project-specific — see `core-components.md` [PROJECT-SPECIFIC] if it exists. If the file is not present, use caller-count heuristic from §Decision Matrix: <5 = LOW, 5-15 = MEDIUM, >15 = HIGH. Classes with >20 callers are potentially CRITICAL — flag to developer: "This class has N callers and may be a core component. Confirm risk level: HIGH or CRITICAL?"

```bash
# ✓ Check before moving on: Risk level assigned with justification.
echo 'Step done: Risk level assigned with justification'
```
## Step 4 — Generate Report

Produce the report using the output format below. Every section must be filled or explicitly marked "None found."

```bash
# ✓ Check before moving on: Report written in markdown with caller table, risk level, and limitations.
echo 'Step done: Report written in markdown with caller table, risk level, an'
```
## Step 5 — "So What?" Decision Framework

Use this output:
```markdown
### 💡 Decision Framework
**Change**: [one line]
**Risk Level**: [from Step 3]
**Direct Callers Affected**: [count]
| Risk Level | Recommendation | Action |
|---|---|---|
| LOW (< 5 callers) | ✅ PROCEED | Change directly, then verify |
| MEDIUM (5-15 callers) | ⚠️ PROCEED WITH CAUTION | Review each caller, then change |
| HIGH (> 15 callers) | 🔶 DEFER | Plan phased migration unless all callers are in one package |
| CRITICAL (core component) | 🔴 REDESIGN | Use deprecation/Strangler Fig; proceed only with explicit approval + full coverage |
**Recommendation**: [PROCEED / PROCEED WITH CAUTION / DEFER / REDESIGN]
**Rationale**: [1-2 sentences]
```
- Present this with the report.
- State one clear recommendation.
- State the immediate next action.
```bash
# ✓ Check before moving on: Decision framework presented with clear recommendation.
echo "Risk assessment complete. Review the report above."
```
## Exit Conditions / Done Definition

- Risk tier assigned (LOW / MEDIUM / HIGH / CRITICAL) for the target
- All direct callers and injection sites identified with file:line references
- "So What?" decision presented to developer
- No unverified claims — every caller backed by grep or graph evidence

## Sub-Agents

blast-radius is itself a sub-agent. It does NOT trigger other sub-agents.

## Example Invocation

> "use the blast-radius skill on ProducerServiceImpl"

AI: runs graphify path first (if graph exists), then grep for all call sites, produces risk table.

## What I Will NOT Do

- Modify any code (read-only analysis only)
- Invent callers that don't exist in source
- Assign HIGH risk without evidence of callers
- Proceed if target class/method name is ambiguous

---

## Step 6 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ blast-radius — done?
  □ Steps 0–6 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Proceed with change                    — say: "use the safe-refactor skill — [change description]"
  B) Explore target deeper                  — say: "use the code-explorer skill — [target class]"
  C) Discuss approach                       — say: "use the party-mode skill — [question about change]"
  D) Proceed with caution                   — say: "use the safe-refactor skill — [change]"
  E) Explore callers                        — say: "use the code-explorer skill — trace callers of [target]"
  F) Get help                              — say: "help"

⭐ Select based on risk level — always provide exactly one highlighted option with ratio

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
