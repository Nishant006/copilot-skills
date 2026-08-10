---
name: code-reviewer
description: "Deep code review of a pull request with structured multi-phase analysis"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [blast-radius, newman-tester]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Perform a structured, multi-phase code review on one or more pull requests. Supports PR discovery (list open PRs), single PR deep review, and parallel multi-PR review via comma-separated PR numbers. Evaluates architecture, security, performance, and production readiness. Delivers a categorized verdict per PR and offers to post it directly to GitHub.

## Entry Conditions

- A PR number, comma-separated PR numbers, URL, or the phrase "show me open PRs" / "list PRs" is provided
- If **no PR number and no list request**: ask — *"Which PR would you like me to review? Or say 'show open PRs' and I'll list them."*
- If **PR number(s) provided**: proceed to Clarifying Questions
- If **multiple PR numbers** (comma-separated): ask clarifying questions once — answers apply to all PRs; reviews run in parallel
- If **"show open PRs"** (or equivalent): run Step 0 first, then wait for the developer to pick PR number(s)
- If **PR diff is empty or PR is in draft with no commits**: **STOP. PR #N has no changes to review. Verify the PR has commits pushed. Do not continue.**
- If **blast-radius returns CRITICAL on any changed class**: **STOP. CRITICAL-risk change detected in [class]. Flag it for extra scrutiny and confirm it is intentional before continuing the review. Do not continue.**

## Clarifying Questions

Before proceeding, ask the developer (once — answers apply to all PRs if reviewing multiple):

- What review depth do you want: **quick scan** (architecture + critical issues only) or **deep review** (all 5 phases)?
- Are there specific concerns to focus on (e.g., concurrency, data integrity, backward compatibility)?
- Is there a related spec or plan to verify alignment against?

Proceed only after answers are received.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill for architecture analysis (blast-radius, class relationship tracing), check if `graphify-out/graph.json` exists. If it does, run `graphify query` or `graphify path` first. Use grep only to supplement or verify. See `.github/instructions/graphify.instructions.md` for full protocol.

**Resume support** (see AGENTS.md §Checkpoint & Resume Protocol): On re-invocation with a PR number, check PR comment history for previously posted phase results. If phases 1-3 were already posted, resume from phase 4. Report: "Found previous review phases 1-N posted. Resuming from phase N+1." Ask: "Resume, or re-review from scratch?"

## Step 0 — Verify Entry Conditions

```bash
# Show open PRs (use if no PR number provided)
gh pr list --state open --json number,title,headRefName   --template '{{range .}}#{{.number}} | {{.title}} | {{.headRefName}}{{"
"}}{{end}}' 2>/dev/null | head -10
```

**STOP. If no PR number was provided and the list above is empty, there are no open PRs. Do not continue.**


## Step 1 — Fetch PR diff

Fetch the full diff using `gh pr diff <N>` (where N is the PR number). List all changed files with their change types (added/modified/deleted). If PR number is not known, use `gh pr list --state open` to discover. Verify: file list extracted with line counts.
   ```bash
   # Verify: PR diff was fetched with file list
   gh pr diff <N> --name-only 2>/dev/null | head -20
   ```
## Step 2 — Trigger blast-radius sub-agent

Run blast-radius on ALL changed files without exception. Provide all changed class/file paths with a one-line description of each change. Grep-verify that every class name in the diff exists in `src/` before including it in the blast-radius request. Verify: blast-radius output received for every changed file.
## Step 3 — Run review checklist

Execute items from [pr-checklist.md](../pr-preparation/pr-checklist.md) in external-review mode. Record each item as PASS or FAIL. Verify: all checklist items evaluated.
## Step 4 — Phase 1: Architecture & Design

Evaluate: correct use of existing patterns, separation of concerns, dependency direction, interface contracts, backward compatibility.

   **Architecture Drift Check (mandatory — run for every PR):**
   ```bash
   # Get all changed Java files in this PR (use PR's base branch, not hardcoded main)
   gh pr diff <N> --name-only | grep -E '\.java$'
   ```
   For each new `.java` file (added, not just modified):
   - Extract the class name: `grep "^public class\|^public interface" <file>`
   - Check: is it in a topology path? (`controller/`, `service/impl/`, `security/`, `producer/`, `config/`)
   - If yes and `.github/kt/` is unchanged in this PR → flag as:
     `"⚠️ [ClassName] is new in [path] but not referenced in .github/kt/. MUST FIX: update KT docs (use onboarding skill → Level 2+ → YES)."`
   
   Also check for these specific patterns <!-- [PROJECT-SPECIFIC] -->:
   - New `@RestController` annotation → flag if `system-overview.md` unchanged
   - New `@KafkaListener` annotation → flag if `component-overview.md` unchanged
   - New `SecurityFilter` or auth logic → flag if `architecture.md` unchanged
   - New Kafka topic configuration → flag if `architecture.md` and `component-overview.md` unchanged
   - New `@Scheduled` task → flag if `component-overview.md` unchanged
   
   
**Complete this table for every changed file (done = step is complete):**

| File | Pattern correct? | Concerns separated? | Interface preserved? | Backward compat? | Finding |
|---|---|---|---|---|---|
| [file] | YES/NO | YES/NO | YES/NO | YES/NO | PASS / [finding] |

Verify: findings logged per file.

**⛔ DRIFT GATE**: Architecture drift MUST FIX findings (any finding flagged with "MUST FIX: update KT docs" from the Architecture Drift Check above) count as MUST FIX findings for verdict determination in Step 11. They are NOT ⚠️ warnings — they are blocking. A PR with architecture drift findings MUST receive REQUEST CHANGES, never APPROVE, regardless of code quality. If a developer disagrees, use NEEDS DISCUSSION — never APPROVE over an unresolved drift finding.

## Step 5 — Phase 2: Security (OWASP)

Evaluate: input validation, injection risks, authentication/authorization checks, sensitive data exposure, error message leakage, dependency vulnerabilities.

   Specific CWE checks for this codebase:
   - **CWE-20 (Input Validation)**: Are new inbound DTOs validated with @Valid, @NotBlank, @Size?
   - **CWE-502 (Deserialization)**: Kafka JSON — are Jackson type checks present? No raw Object deserialization?
   - **CWE-798 (Hard-coded Credentials)**: Any API keys/secrets in code or YAML? Must use env vars or secret management.
   - **CWE-918 (SSRF)**: New URLs validated against allow-list before external calls?
   - **CWE-327 (Weak Crypto)**: If encryption used, is it AES-256/SHA-256+? No MD5/SHA-1/DES.
   - **PII in logs**: Check all new log statements for phone, email, name, customer ID. Must use `PIIUtil`.
   - **API key exposure**: Are API keys logged, returned in error responses, or included in stack traces?

   
**Complete Security Checklist table for every changed file:**

| File | S1 validated? | S2 no internal fields? | S3 no raw DB model? | S4 separate namespace? | S5 path vars validated? | S6 body not params? | S7 constant-time? | Finding |
|---|---|---|---|---|---|---|---|---|
| [file] | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO | PASS / 🔴 [issue] |

Verify: findings logged per file.

   ### Security Checklist (PR Review Standards)

   > Run this checklist on every PR, for every language/framework — these are language-agnostic standards.

   For each item, answer YES (no finding) or NO (finding) and record the finding with file:line:

   | # | Check | Finding format | Suggested fix |
   |---|---|---|---|
   | S1 | **Internal storage keys in inputs**: Does any endpoint accept a raw internal storage key (e.g., DB key, cache key, queue name, internal ID format) as a URL param, path variable, or request body field? | 🔴 MUST FIX: `[endpoint]` accepts `[param]` which is an internal `[storage type]` key. Callers learn internal storage topology. | Accept business identifiers (e.g., `serviceId`, `resourceId`) and derive the internal key server-side. Never expose internal key format as part of the public API contract. |
   | S2 | **Internal fields in responses**: Does any response body or header expose DB-internal fields — e.g., entity `id`/`_id`, optimistic lock `version`/`@version`, ORM metadata (`_class`, `__type__`), internal composite key format, or storage-layer prefixes? | 🔴 MUST FIX: `[endpoint]` response exposes `[field]` which is a `[DB/ORM]` internal field. | Create a dedicated response DTO/record that explicitly includes only the fields the API contract needs. Never return raw DB entity/document objects from controllers. |
   | S3 | **Raw DB model as API response**: Is any controller method returning a raw ORM entity, DB document, or persistence model directly (instead of a DTO/record/view model)? | 🔴 MUST FIX: `[Controller#method]` returns `[EntityClass]` directly. Any field added to the persistence model is automatically API-exposed. | Introduce a response record/DTO (e.g., `XxxResponse`) that maps from the entity. This decouples the API contract from the storage schema. |
   | S4 | **Shared infrastructure namespaces**: If multiple subsystems share the same infrastructure (Redis DB, Kafka topic, DB schema), do they use separate namespaces/indexes? A FLUSHDB, topic delete, or schema migration on one subsystem must not affect another. | 🟡 SHOULD FIX: `[SubsystemA]` and `[SubsystemB]` share `[infrastructure]` namespace/index. | Assign separate namespaces: separate Redis DB index, separate Kafka topic prefix, separate DB schema. Controlled by config, not hardcoded. |
   | S5 | **Input validation on path variables and query params**: Do all `@PathVariable`, `@RequestParam`, and equivalent parameters have size, pattern, and nullability constraints? Without constraints, oversized or malformed inputs can reach service/DB layers. | 🔴 MUST FIX: `[endpoint]` param `[name]` has no `@Pattern`/`@Size`/`@NotBlank` constraint. | Add `@NotBlank`, `@Pattern(regexp="^[A-Za-z0-9_-]+$")`, `@Size(max=100)` (or appropriate constraints). Add `@Min`/`@Max` to numeric pagination params. |
   | S6 | **POST/PUT mutation with identifiers in query params**: Do any `POST`, `PUT`, or `PATCH` endpoints accept identifying or sensitive data as `@RequestParam` instead of `@RequestBody`? Query params appear in server access logs, browser history, CDN caches, and WAF captures. | 🔴 MUST FIX: `[endpoint]` sends `[param]` as a query param on a mutation. This leaks `[data type]` to logs. | Move identifying/sensitive params to `@RequestBody`. Reserve `@RequestParam` for `GET`/`HEAD`/`DELETE` operations only (HTTP spec: GET MUST NOT carry a body). |
   | S7 | **Constant-time secret comparison**: Is any API key, token, HMAC, or secret compared using `.equals()`, `==`, or string equality? Early-exit comparison leaks timing information that allows character-by-character key enumeration in low-latency environments (e.g., pod-to-pod calls). | 🔴 MUST FIX: `[class#method]` compares `[secret type]` with `[equals/==]`. Vulnerable to timing side-channel. | Replace with constant-time comparison: `MessageDigest.isEqual(expected.getBytes(), provided.getBytes())` (Java), `hmac.compare_digest()` (Python), `crypto.timingSafeEqual()` (Node.js). Note: `MessageDigest.isEqual` still leaks length — for full protection, compare `SHA-256` digests of both values (both outputs are fixed 32 bytes regardless of input length). |

   **How to report Security Checklist findings:**
   - S1–S3, S5–S7 are 🔴 MUST FIX — a PR with any of these findings MUST receive REQUEST CHANGES.
   - S4 is 🟡 SHOULD FIX — flag it but it does not alone block APPROVE if all other checks pass.
   - Include the checklist table in the review verdict with YES/NO per item even when all pass (confirms the check was run).

## Step 6 — Phase 3: Performance

Evaluate: N+1 queries, unbounded collections, missing pagination, blocking calls in async paths, cache misuse, unnecessary object creation in loops.

   <!-- [PROJECT-SPECIFIC] Dispatcher-specific performance checks: -->
   - Is `KafkaProducer.sendMessage().get()` called synchronously with no timeout? (MUST FIX if missing timeout)
   - Is `Thread.sleep()` used between Kafka sends? Could be interrupted — check error handling (SHOULD FIX)
   - Is `ConfigServiceCircuitBreakerImpl` hit per-request without caching? (SHOULD FIX — batch lookups)
   - In `Scheduler.sendScheduledCommunication()`: are `CompletableFuture.allOf()` results properly collected? (verify no silent failures)
   - Are MongoDB queries using proper indexes? Check `findByConfigId`, `findByTransactionUUID`
   - Is Redis circuit breaker fallback to MongoDB adding latency? Check timeout settings

   
**Performance check per changed file:**

| File | No N+1? | Pagination present? | No blocking calls in async? | Finding |
|---|---|---|---|---|
| [file] | YES/NO | YES/NO | YES/NO | PASS / [issue] |

Verify: findings logged per file.
## Step 7 — Phase 4: Production Readiness

Evaluate: error handling completeness, logging adequacy, monitoring/metrics hooks, graceful degradation, configuration externalization, feature flag usage.

   Spring Boot production-readiness checks:
   - Missing @Transactional boundaries on methods with multiple DB writes?
   - New external integration missing actuator health indicator?
   - New config properties missing from all profile files (local, dev, preprod, prod)?
   - Circuit breaker configured for new external service calls?
   - New Kafka topic referenced but not defined in all profile YAMLs?
   - Error responses leaking internal details (stack traces, class names)?

   
**Production readiness check per changed file:**

| File | Error handling complete? | Config externalized? | Health indicator added? | Finding |
|---|---|---|---|---|
| [file] | YES/NO | YES/NO | YES/NO | PASS / [issue] |

Verify: findings logged per file.
## Step 8 — Phase 5: Java Best Practices

Evaluate against Effective Java (Bloch):
   - Raw type usage (must use generics)
   - Unchecked casts without @SuppressWarnings justification
   - equals() overridden without hashCode() (or vice versa)
   - Mutable public fields (must be private + accessor)
   - Missing toString() on new domain objects and DTOs
   - Checked exceptions used where unchecked is appropriate
   - Builder used for objects with >3 constructor parameters

   
**Java best practices per changed file:**

| File | No raw types? | equals+hashCode? | Builder for >3 params? | Finding |
|---|---|---|---|---|
| [file] | YES/NO | YES/NO | YES/NO | PASS / [issue] |

Verify: findings logged per file.
## Step 9 — Verify spec alignment

Attempt to locate the spec:
   - Extract ticket ID from PR branch name (e.g., `feat/COM-120/...` → `COM-120`)
   - Look for `features/COM-120/spec.md`
   - **If spec found**: verify each acceptance criterion is covered by the changes. Map each criterion to a specific change or flag as missing.
   - **If spec NOT found**: add to verdict — `⚠️ No spec found for [ticket] — acceptance criteria verification skipped.` Then ask: *"Should I use the PR description as an informal spec instead?"* If yes, extract requirements from PR body and verify against diff.
   - Verify: each criterion mapped to a change, or absence explicitly noted.
## Step 10 — Categorize all findings

Assign severity to each finding:
   - 🔴 **MUST FIX** — Bugs, security vulnerabilities, logic errors, data loss risk
   - 🟡 **SHOULD FIX** — Quality issues, pattern violations, missing error handling
   - 💡 **SUGGESTION** — Improvements, readability, minor optimizations
   Verify: every finding has a severity, file path, and line reference.
## Step 11 — Deliver verdict

Present the review in this format:
    ```
    ## Code Review: PR #[N] — [Title]
    ### Summary: [1-2 sentence overview]
    ### Blast Radius: [summary from sub-agent]
    ### Checklist Results: [PASS/FAIL counts]
    ### Issues Found: [categorized list with file:line references]
    ### Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
    ### Reasoning: [justification for the verdict]
    ```
    Verify: verdict delivered with all sections populated.

## Step 12 — Post to GitHub (optional)

After verdict is delivered, ask:
    *"Shall I post this review to GitHub? (YES to post / NO to keep in terminal)"*

    If YES:
    - For `REQUEST CHANGES`: `gh pr review [N] --request-changes --body "[verdict]"`
    - For `APPROVE`: `gh pr review [N] --approve --body "[verdict]"`
    - For `NEEDS DISCUSSION`: `gh pr review [N] --comment --body "[verdict]"`

    Verify posted: `gh pr view [N] --json reviews --jq '.reviews[-1].state'` — confirm the latest review state matches.

    If reviewing **multiple PRs**, ask once per verdict: *"Post PR #42 to GitHub? (YES/NO)"*

## Step 13 — Post-Review: Newman verification offer

```bash
# Check for Postman collection
find postman/ tests/ . -maxdepth 1 -name "*.postman_collection.json" 2>/dev/null
```

If collection found AND code fixes were applied in this session:
```
Code fixes applied. I found a Postman collection at: {path}
The changes touched: {list changed endpoints}
Run Newman to verify nothing broke? [YES / NO]
```
Wait for YES. If YES: invoke `newman-tester` skill (Mode A — post-fix).
Log the outcome: "Newman check: [ran clean / skipped by developer / no collection found]"


## Exit Conditions / Done Definition

- All 5 review phases executed per PR (or phases 1–2 only for quick scan — **must explicitly state in verdict**: "⚠️ Quick scan — phases 3-5 (security, performance, production-readiness) were skipped. Request a deep review if needed.")
- Every finding has severity + file path + line reference
- Blast-radius analysis completed for all changed files
- Review checklist executed in external-review mode
- Spec alignment verified — or explicit warning added if spec not found
- Verdict delivered per PR: APPROVE, REQUEST CHANGES, or NEEDS DISCUSSION
- Developer offered GitHub posting (Step 12); outcome recorded (posted or kept in terminal)

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|---|---|---|---|
| `blast-radius` | Step 2 — always | List of changed file paths + one-line change descriptions | Per-file risk level + list of affected callers/consumers |
| `newman-tester` | Step 13 — when code fixes applied + developer says YES | Collection path, changed endpoints | Newman run results + e2e-test-report.md updated |

## Example Invocation

**Flow 1 — Developer doesn't know the PR number:**
> "Give me all open PRs."

AI runs Step 0 → displays table of open PRs → developer replies `#42, #38` → AI asks clarifying questions once → reviews both in parallel → delivers two verdict blocks → asks "Post #42 to GitHub? Post #38 to GitHub?"

---

**Flow 2 — Developer provides a single PR number:**
> "Review PR #42."

AI asks clarifying questions → reads diff → runs blast-radius → executes all 5 phases → delivers verdict → asks "Shall I post this to GitHub?"

---

**Flow 3 — Multiple PRs, parallel review:**
> "Review PR #42, #38, #35."

AI asks clarifying questions once (depth + concerns apply to all 3) → runs all 3 review pipelines in parallel → delivers:
```
## Code Review: PR #42 — Add x-maf-account validation for KWT
Verdict: REQUEST CHANGES (2 MUST FIX)

## Code Review: PR #38 — Fix Redis circuit breaker timeout
Verdict: APPROVE

## Code Review: PR #35 — Add new API key for fraudservice
Verdict: APPROVE
```
Then asks per PR: "Post #42 to GitHub? (YES/NO)"

## What I Will NOT Do

- Modify code (review only — never push changes)
- Approve without completing blast-radius analysis
- Skip the review checklist
- Deliver a verdict without file:line references for findings
- Post to GitHub without explicit YES from the developer
- Skip spec-alignment warning if spec.md is missing

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 2 (diff) | Cannot fetch PR diff (force-pushed, branch deleted) | Try `gh pr diff N` directly. If still fails, ask developer to re-push. |
| Step 3-7 (review phases) | Finding is ambiguous — unclear if it's a bug or intentional | Flag as SHOULD FIX with explanation. Never skip — always surface. |
| Step 10 (verdict) | Cannot determine severity of a finding | Default to SHOULD FIX (not MUST FIX). Escalate to party-mode if architectural. |
| Any step | PR has 50+ files — too large to review effectively | Suggest splitting PR. Review critical paths first: controllers, services, security. |

---

---

## Step 14 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ code-reviewer — done?
  □ Steps 0–14 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Address MUST FIX items                 — say: "use the implement-and-test skill — fix review findings"
  B) Re-review after fixes                  — say: "use the code-reviewer skill — review PR #N"
  C) Discuss architectural concern          — say: "use the party-mode skill — [concern from review]"
  D) Check broader impact                   — say: "use the blast-radius skill on [changed class]"
  E) Get help                              — say: "help"

⭐ For PR author → Option 1. For reviewer → Option 2 after author pushes fixes.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
