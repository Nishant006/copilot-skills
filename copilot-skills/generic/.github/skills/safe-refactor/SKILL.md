---
name: safe-refactor
description: "Plan and execute safe refactoring with blast-radius awareness and phase gates"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [blast-radius]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Execute structural code changes (rename, extract, move, inline) with zero behavior change. Runs blast-radius analysis first, then applies changes bottom-up with test verification after every file. Use when a developer requests any refactoring operation.

## Entry Conditions

1. Developer specifies the **refactoring target** and **type** (rename, extract method, extract class, move, inline, change signature).
2. All existing tests pass before starting (`./mvnw test` or equivalent — run and confirm).
3. If the target is ambiguous → **STOP. Ask for the exact class/method and refactoring type. Do not continue.**

## Clarifying Questions

Ask these before proceeding:

1. What **type of refactoring**? (rename, extract method, extract class, move class, inline, change signature)
2. What is the **exact scope**? (specific class/method, or broader pattern?)
3. Are there any **exceptions** to strict behavior preservation? (Default: NO behavior changes allowed. If the developer needs behavior changes, redirect to enhancement/spec-writer workflow instead.)
4. What is the **test coverage** of the affected code? (run `./mvnw verify` if unknown)

Proceed only after answers are received.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill, anchor to the repo root with `cd "$(git rev-parse --show-toplevel)"`, then check if `graphify-out/graph.json` exists (a "graph file not found" error from a subdirectory is NOT a missing graph). If it does, run `graphify path "<TargetClass>" "*"` to identify all callers/dependents from the knowledge graph. Use grep only to supplement or verify. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Entry Conditions

```bash
# Verify: clean working tree before starting any refactor
git status --short 2>/dev/null | head -10
git stash list 2>/dev/null | head -3
```
**STOP. If you have uncommitted changes, commit or stash them before starting.**
- Phase 1 — Blast-Radius Analysis: Run `blast-radius`, review risk, require explicit `APPROVE-REFACTOR` token for **HIGH or CRITICAL** risk.
- Phase 2 — Plan Refactoring Order: Write the file-change order before editing.
- Phase 3 — Execute Changes: Change one file at a time and run tests after each file.
- Phase 4 — Final Verification: Run full verify and confirm no behavior change or coverage regression.
- Phase 5 — Stale Reference Detection: Grep for old names/references across code and fix or mark intentional.
```bash
# ✓ Check: working tree is clean before starting
git status --short 2>/dev/null && git stash list 2>/dev/null | head -3
```

## Phase 1 — Blast-Radius Analysis

Auto-trigger `blast-radius` on the refactoring target:
```bash
# Verify blast-radius was run
echo "blast-radius triggered for: [target class/method]"
```
**STOP. If blast-radius returns HIGH or CRITICAL risk: require explicit `APPROVE-REFACTOR` token before continuing. Do not proceed without it.**

## Phase 2 — Plan Refactoring Order

Write the change sequence bottom-up: leaf classes first, callers second, entry points last. Document:
- Files to change (in order)
- Test to run after each file
```bash
# Verify: plan written — confirm file list before starting Phase 3
echo "Files to change in order: [list]"
```

## Phase 3 — Execute Changes (one file at a time)

For each file in the Phase 2 order:
1. Apply the structural change to that file only
2. Run tests immediately:
```bash
./mvnw test 2>/dev/null || npm test 2>/dev/null || go test ./... 2>/dev/null
```
**STOP. If tests fail after any single file: revert that file, diagnose, fix, then retry. Never accumulate failures across files.**

## Phase 4 — Final Verification

```bash
# Full verify after all files changed
./mvnw verify 2>/dev/null || go test ./... 2>/dev/null || npm test 2>/dev/null
```
**STOP. If coverage drops below pre-refactor baseline or behavior tests fail: investigate before proceeding.**

## Phase 5 — Stale Reference Detection

```bash
# Grep for any remaining references to the OLD name
grep -rn "[old_name]" src/ --include="*.java" 2>/dev/null | head -10
grep -rn "[old_name]" src/ --include="*.ts" 2>/dev/null | head -10
```
For each hit found: either update it or mark as intentional with a comment. Do NOT proceed to PR with unresolved stale references.

## Exit Conditions / Done Definition

- All files changed with correct structural transformation
- All tests pass (full `./mvnw verify` or equivalent)
- No behavior change introduced
- No stale references remaining
- blast-radius confirms no unexpected callers missed

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|---|---|---|---|
| `blast-radius` | Phase 1 — always | Target class/method + change type | Risk level + caller list |

## Example Invocation

> "use the safe-refactor skill — rename SmsClientFactory.getClient to resolveVendor"

AI asks: type (rename), scope (one method), behavior change allowed (No), test coverage (85%).
Runs blast-radius → LOW risk → applies rename bottom-up → tests pass → PR ready.

## What I Will NOT Do

- Change behavior while refactoring (any behavior change → route to enhancement workflow)
- Rename multiple targets in parallel (one target per skill invocation)
- Skip blast-radius analysis before starting
- Proceed past a test failure without resolving it
- Commit code (that is pr-preparation's responsibility)

---

## Step 6 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ safe-refactor — done?
  □ Phases 0–5 executed (0=verify, 1=blast-radius, 2=plan, 3=execute, 4=verify, 5=stale-check)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Create PR                              — say: "use the pr-preparation skill for COM-XXX"
  B) Verify post-refactor                   — say: "use the blast-radius skill on [refactored class]"
  C) Fix failing tests                      — say: "use the implement-and-test skill — fix test failures"
  D) Discuss alternative approach           — say: "use the party-mode skill — [refactoring strategy]"
  E) Get help                              — say: "help"

⭐ refactoring is done, ship it.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
