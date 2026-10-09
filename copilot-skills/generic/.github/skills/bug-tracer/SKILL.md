---
name: bug-tracer
description: "Trace a bug through the codebase to identify root cause and suggest a fix"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [code-explorer, blast-radius]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Systematically trace a bug from its symptom to its root cause by following the code's call chain. Produces a root cause analysis with exact file:line references and a suggested fix, then hands off to implement-and-test for resolution. Use this skill when a developer reports a bug, error, or unexpected behavior.

## Entry Conditions

- Developer describes a bug symptom (error message, unexpected behavior, failed operation, log excerpt)
- If no symptom is provided: **STOP. Ask: "Please describe the bug — error message, unexpected behavior, or log excerpt." Do not continue.**

## Clarifying Questions

Before proceeding, ask the developer:

- Which environment is this occurring in (production, staging, dev, local)?
- When did this start happening (approximate date/time or "always")?
- Were there any recent deployments or config changes before this started?
- What is the exact error message or log output (paste if available)?
- How many users/requests are affected (isolated vs. widespread)?
- Is this reproducible on demand, or intermittent?

Proceed only after answers are received.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill, anchor to the repo root with `cd "$(git rev-parse --show-toplevel)"`, then check if `graphify-out/graph.json` exists (a "graph file not found" error from a subdirectory is NOT a missing graph). If it does, run `graphify path "<SymptomArea>" "<SuspectedCause>"` or `graphify query "<bug description>"` first to identify the call chain. Use grep only to supplement or when graph is unavailable. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Entry Conditions

```bash
# Check: symptom was provided
git log --oneline -3 2>/dev/null   # Check recent commits for context
```
**STOP. If no bug symptom was provided, ask: "Please describe the bug — error message, unexpected behavior, or log excerpt." Do not continue.**

## Step 1 — Extract search terms

From the symptom description, extract: error class names, exception types, log message fragments, method names, endpoint paths, event names.
   ```bash
# ✓ Check before moving on: At least 2 search terms are extracted from the symptom description.
echo 'Step done: At least 2 search terms are extracted from the symptom descr'
```
## Step 2 — Trigger code-explorer sub-agent

ℹ️ *Tell the developer: "I will now auto-trigger code-explorer to map the affected call chain."* Provide the search terms and symptom description. The sub-agent returns: entry points (controllers, consumers, listeners) that handle the affected flow, plus the call chain from entry point to the area of failure.
   ```bash
# ✓ Check before moving on: Sub-agent output is received with file paths and call-chain context.
# Sub-agent output logged above
```
## Step 3 — Trace the call chain

Starting from the identified entry point, follow the code path step by step. At each method call, read the target method. Document the chain as: `ClassA.method() → ClassB.method() → ClassC.method()`.
   ```bash
# ✓ Check before moving on: The call chain is documented with `file:line` references for each hop.
# Call chain documented in output above with file:line references
```
## Step 4 — Check error handling

At each point in the chain, check for: swallowed exceptions (empty catch blocks), missing null checks, incorrect fallback values, silent failures, unchecked return values.
   ```bash
# ✓ Check before moving on: Each error-handling checkpoint is marked as SAFE or SUSPECT with supporting note
echo 'Step done: Each error-handling checkpoint is marked as SAFE or SUSPECT '
```
## Step 5 — Check configuration

Read the relevant config files (YAML, properties) and verify: feature flags, environment-specific values, mapping entries. If [debugging-patterns.md](debugging-patterns.md) exists [PROJECT-SPECIFIC], consult it for common config issues and entry points. If it doesn't exist, use grep to locate config files relevant to the affected class.
   ```bash
# ✓ Check before moving on: Relevant config values are identified and logged for the affected flow.
echo 'Step done: Relevant config values are identified and logged for the aff'
```
## Step 6 — Intermittent Bug Investigation (if bug is not consistently reproducible)

If the bug is intermittent:
1. Check for **race conditions** in CompletableFuture chains — are shared variables accessed without synchronization?
2. Check for **swallowed exceptions** — does `.thenApply()` silently ignore failures? Look for missing `.exceptionally()` or `.handle()`
3. Check for **timing-dependent failures** — does the code assume a response within a timeframe without explicit timeout?
4. Check for **thread pool exhaustion** — is the executor bounded? Could all threads be blocked on slow vendor calls?
5. Check for **stale cache** — could Caffeine or Redis be serving outdated config that causes the failure intermittently?

Document which of these patterns (if any) applies.

```bash
# ✓ Check before moving on: At least one intermittent-bug pattern is confirmed or eliminated with file:line 
echo 'Step done: At least one intermittent-bug pattern is confirmed or elimin'
```
## Step 7 — Config-First Elimination (always check before blaming code)

Before concluding the bug is in Java code, eliminate config issues:
1. Check feature flags: is the feature enabled for the affected site? (`GrowthBookService` evaluation)
2. Check supported-sites-events YAML: is the site + event combination registered?
3. Check vendor mappings: is the SMS vendor correctly mapped for the affected storeId?
4. Check profile-specific config: does `application-prod.yml` differ from `application-dev.yml` for this feature?
5. If bug exists in prod but not dev: compare config files diff first, then check code.

```bash
# ✓ Check before moving on: Config is either confirmed as the root cause (with specific key:value evidence) 
./mvnw test 2>/dev/null | tail -5 || npm test 2>/dev/null | tail -5 || go test ./... 2>/dev/null | tail -5
```
## Step 8 — Multi-Environment Divergence (when bug exists in one env but not another)

If the bug is environment-specific:
1. **Config diff**: Compare application-{env1}.yml vs application-{env2}.yml for the affected feature
2. **Feature flag diff**: Check GrowthBook — is the flag enabled differently per environment?
3. **Version diff**: Are the deployed versions identical? Check deployment pipeline.
4. **Data diff**: Is the test data different? (different site codes, different event types)
5. Report: "Bug is environment-specific. Root cause is [config/flag/version/data] divergence: [details]."

## Step 9 — Identify root cause

Pinpoint the exact class, method, and line where the bug originates. State the root cause as: `"[ClassName.java:LINE] — [description of what goes wrong and why]"`.

   **Distinguish between:**
   - **Root cause**: The specific code/config defect that directly causes the bug (e.g., "null check missing at line 87")
   - **Contributing cause**: Why the system reached the buggy state (e.g., "upstream service sends null field that was previously always populated")

   Both must be documented in the handoff:
   - Root cause: [ClassName.java:LINE] — [what is broken]
   - Contributing cause: [description of how the buggy state is reached]
   - Fix addresses: root cause / contributing cause / both

   ```bash
# ✓ Check before moving on: Root cause is identified with an exact `file:line` reference and a causal explan
echo 'Step done: Root cause is identified with an exact `file:line` reference'
```
## Step 10 — Trigger blast-radius sub-agent on root cause

ℹ️ *Tell the developer: "I will now auto-trigger blast-radius on the root cause to assess fix impact."* Provide the identified file and the proposed fix description.
   ```bash
# ✓ Check before moving on: Impact report is received with a risk tier and the affected callers/consumers.
echo 'Step done: Impact report is received with a risk tier and the affected '
```
## Step 11 — Suggest fix and present findings

Describe the fix without implementing it. Include: what to change, where, and why. Reference the blast-radius output to note any downstream impacts. End with the handoff message: `"Root cause: [ClassName.java:LINE] — [description]. Suggested fix: [description]. Blast risk: [LEVEL]. Use implement-and-test skill to fix? (bug-fix fast-track)"`
   ```bash
# ✓ Check before moving on: Root cause analysis is delivered with all claims backed by `file:line` evidence 
echo 'Step done: Root cause analysis is delivered with all claims backed by `'
```
## Exit Conditions / Done Definition

- Root cause identified with exact file path and line number
- Call chain documented from entry point to root cause
- Suggested fix described with specific file:line references
- Blast-radius analysis completed on the root cause location
- Handoff message presented to developer for implement-and-test

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|---|---|---|---|
| `code-explorer` | Step 2 — always | Search terms + symptom description | Entry points, call chain, related classes |
| `blast-radius` | Step 10 — always | Root cause file path + proposed fix description | Risk level + affected callers/consumers |

## Example Invocation

**Developer says:**
> "Users in region X are not receiving notifications for return approvals. Started yesterday."

**AI responds:**
> "Before I trace this, I need a few details:
> 1. Is this happening in production or staging?
> 2. Any deployments or config changes yesterday?
> 3. Do you have a specific error message or log excerpt?
> 4. Is this all UAE users or specific orders?
> 5. Is it reproducible on demand?
> 6. Are other notification channels (email, SMS) working for the same event?"

*(After answers, AI traces the call chain, identifies root cause, runs blast-radius, and presents handoff.)*

> "Root cause: `ChannelRouter.java:87` — region code missing from channel mapping added in yesterday's config deployment. Suggested fix: add the missing region entry to the channel mapping in config. Blast risk: LOW. Use implement-and-test to fix? (bug-fix fast-track)"

## What I Will NOT Do

- Fix the bug (analysis only, then hand off to implement-and-test)
- Guess at runtime state without evidence from source code or config files
- Assume config values — read the actual files
- Skip the call chain trace and jump to conclusions

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 3 (call chain) | Cannot reproduce the bug from description | **STOP. Ask for logs, stack trace, or exact steps to reproduce. Do not continue.** |
| Step 9 (root cause) | Multiple possible root causes found | Present all candidates with likelihood. Ask developer which to investigate first. |
| Step 10 (blast-radius) | Fix touches a CRITICAL class | Present blast-radius report. Recommend feature flag wrapper for the fix. |
| Step 9 (fix suggestion) | Fix would change method signature | Run blast-radius on that method first. Present safe change patterns. |

---

---

## Step 12 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ bug-tracer — done?
  □ Steps 0–12 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Fix the bug                            — say: "use the implement-and-test skill — fix [bug description]"
  B) Check fix impact                       — say: "use the blast-radius skill on [class with bug]"
  C) Explore related code                   — say: "use the code-explorer skill — [related area]"
  D) Discuss fix approach                   — say: "use the party-mode skill — [fix A vs fix B tradeoff]"
  E) Get help                              — say: "help"

⭐ once root cause is confirmed, go straight to fix + regression test.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
