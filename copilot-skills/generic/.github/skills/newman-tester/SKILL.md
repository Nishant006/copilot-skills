---
name: newman-tester
description: "Run Postman collections via Newman, detect failures with full diagnosis, fix with approval, update e2e-test-report.md"
last-updated: 2026-06-18
layer: 1
triggers-sub-agents: [postman-collection]
triggered-by: [implement-and-test, code-reviewer]
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Run a project's Postman collection against a live server using Newman. For every failure: present exact diagnosis and options — never silently fix or modify the collection. Update (or create) `e2e-test-report.md` after a clean run.

## 🔒 Non-Negotiable Guardrails

> These rules override everything in this skill. No exception.

1. **NEVER modify a Postman collection test without explicit approval.**
   Always: show what failed → diagnose why → propose change → wait for `[FIX]` token.
   Use `--folder` exclusion to skip incompatible tests instead of modifying them.

2. **NEVER run Newman without user confirmation.**
   Always present what will be run (collection path, folder count, excluded folders) first. Wait for `[YES]` before executing.

3. **NEVER include `.gitignore` in any commit triggered by this skill.**
   Before any git operation: run `git status` and check for uncommitted `.gitignore` changes.
   If found: ask "Your `.gitignore` has uncommitted changes. Include it in this commit? [YES/NO]"
   Wait for answer. Default is NO.

4. **NEVER fix code bugs** — this skill only runs tests and fixes Postman assertions.
   If a failure is a CODE BUG: report it, stop, and tell the user to fix the code first.

---

## Entry Conditions

### Mode A — Post-fix (auto-triggered after `implement-and-test` or `code-reviewer` applies changes)
- Code changes were just made in the current session
- Invoked by parent skill OR developer says "run newman" / "test the collection" after a fix

### Mode B — Full project (standalone invocation)
- Developer says "run api tests", "test with newman", "run postman", "verify api", or "use the newman-tester skill"
- No specific code change context required

### Stop conditions
- Server is not running (health check fails) → guide user to start server first
- Newman is not installed → ask permission to install
- Auth credentials are placeholder values → list exact variables that need to be set

---

## Clarifying Questions

For Mode A (auto-triggered): skip clarifying questions — use context from parent skill.

For Mode B (standalone), ask once:
- Which collection should I run — all collections in `postman/`, a specific one, or should I search the project?
- Are there folders to skip for this run (e.g., manual tests, environment-specific tests)?
- Which environment should I use (local / dev / preprod)?

Proceed only after answers are received.

---

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

## Step 0 — Verify Mode and Prerequisites

```bash
# Check: does a Postman collection exist anywhere in the project?
find postman/ tests/ . -maxdepth 2 -name "*.postman_collection.json" 2>/dev/null \
  || echo "INFO: No collection found yet — will present options"
# Check: is Newman installed?
which newman 2>/dev/null && newman --version 2>/dev/null || echo "Newman not installed — will offer install"
```
**No hard stop here — use this output to route to Mode A or Mode B and to the prerequisite check in Step 2.**

## Step 1 — Discover collections and assess coverage

**Mode A:**
1. Search for `*.postman_collection.json` in `postman/`, `tests/`, project root
2. If found: present assessment to user:
   ```
   I found a Postman collection at: {path}
   Folders: {N} | Requests: {count} (approx — from file scan)
   Your changes touched: {list changed endpoints}
   Collection covers: {M} of those endpoints
   Excluded folders: {list any previously flagged as skip}

   Shall I run this to verify nothing broke? [YES / PARTIAL: only changed endpoint folders / NO]
   ```
3. Wait for explicit user response. Do NOT proceed without it.

**Mode B:**
1. Anchor to the repo root (`cd "$(git rev-parse --show-toplevel)"`), then check if `graphify-out/graph.json` exists (a "graph file not found" error from a subdirectory is NOT a missing graph — see `.github/instructions/graphify.instructions.md` for the full protocol):
   - If YES: run `graphify query "list all REST API endpoints"` to understand full API surface
   - If NO: warn "⚠️ No knowledge graph found. Using grep-based discovery." Then: `grep -rn "@RestController\|@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@RequestMapping" src/ --include="*.java"` (adapt for project stack)
2. Search for existing collections in `postman/`, `tests/`, root
3. Present assessment:
   ```
   Collections found:
   - {path}: covers [{list endpoints}], last modified {date}, estimated coverage: {%}
   - {path}: ...

   Uncovered endpoints: [{list}]

   How would you like to proceed?
   (a) Run existing collection(s) as-is
   (b) Extend existing collection for uncovered endpoints first, then run
   (c) Generate a fresh collection from scratch, then run
   ```
4. Wait for user choice.
5. If (b) or (c): trigger `postman-collection` skill. Return here once collection is ready.

## Step 2 — Prerequisite check (mandatory before ANY execution)

Run checks in order. Stop at first failure:

1. **Newman installed?**
   ```bash
   which newman
   ```
   If missing: "Newman is not installed. Run: `npm install -g newman`. Approve? [YES/NO]"
   Wait for YES before installing. If NO: **STOP. Do not continue.**

2. **Server health?**
   - Detect base URL from: (a) environment file `base_url` variable, (b) `application.yml`/`application.properties`, (c) ask user
   - Try: `curl -s {base_url}/actuator/health` → if fails, try `curl -s {base_url}/health`
   - If neither responds with 2xx: **STOP. Tell the user: "Server is not running on {base_url}. Start it first, then say 'started' and I will continue." Do not continue.**

3. **Auth credentials populated?**
   - Find environment file (`.postman_environment.json`)
   - Check all required variables (API keys, auth tokens, base URL) — flag any that are empty or contain placeholder text (e.g., `replace-with-`, `YOUR_KEY_HERE`, `<...>`)
   - If any placeholder found: **STOP. Tell the user: "These variables need real values before I can run: [{list}]. Update them in the environment file, then re-run." Do not continue.**

```bash
# ✓ Check before moving on: All 3 checks pass before Step 3 executes.
./mvnw test 2>/dev/null | tail -5 || npm test 2>/dev/null | tail -5 || go test ./... 2>/dev/null | tail -5
```
## Step 3 — Present run plan and wait for approval

Before running Newman, show exactly what will execute:

```
📋 Run plan:
  Collection: {path}
  Environment: {path}
  Folders included: {list or "all"}
  Folders excluded: {list with reason — e.g., "Folder 23: manual test requiring Redis shutdown",
                                              "Folder 33: endpoint not deployed on this branch"}
  Newman flags: --timeout-request 10000 --delay-request 100

Proceed? [YES / ADJUST: tell me what to change / NO]
```

Wait for explicit YES. If ADJUST: update the run plan and re-present.

## Step 4 — Execute Newman

```bash
newman run {collection_path} \
  --environment {env_path} \
  --timeout-request 10000 \
  --delay-request 100 \
  [--folder "Folder Name" ...for each included folder]
```

```bash
newman run {collection_path} \
  --environment {env_path} \
  --timeout-request 10000 \
  --delay-request 100 \
  --reporters cli 2>&1 | tee ./newman-output.txt
# Capture exit code to detect failures
echo "Newman exit code: $?"
```

Capture full output. Display it live and save it for parsing. Do not truncate.

```bash
# ✓ Check before moving on: Newman exits with output captured and exit code recorded.
echo 'Step done: Newman exits with output captured and exit code recorded'
```
## Step 5 — Parse results and route

**If 0 failures**: proceed to Step 7 (report).

**If failures**: proceed to Step 6 (diagnosis loop).

## Step 6 — Failure diagnosis loop

For each failure, execute this exact sequence. Do NOT batch multiple failures — handle one at a time:

**6a. Present failure details:**
```
❌ Failure #{N}:
  Folder:     {folder name}
  Request:    {request name}
  Method/URL: {method} {url}
  Assertion:  "{assertion text}"
  Expected:   {expected value}
  Actual:     {actual value}
  HTTP Status: {status code}
```

**6b. Diagnose root cause.** Categorize as exactly one of:
- **CODE BUG**: The API response is wrong — the implementation has a bug. Example: field `id` missing from response because service layer didn't map it.
- **STALE ASSERTION**: The collection test no longer matches the current API contract. Example: test checks for `key` field but PR review changed it to `id`.
- **ENV CONFIG**: The environment variable is missing, wrong, or expired. Example: API key placeholder not replaced.
- **INCOMPATIBLE FOLDER**: This test requires an endpoint or service not available on this branch/environment. Example: `/user/v2/profile` returns 404 on a rate-limiter-only branch because UserProfile controller isn't deployed here.

**6c. Present diagnosis and options:**
```
🔍 Root cause: {CATEGORY} — {one sentence explanation}

Proposed action: {precise fix description with reasoning}
Example: "Change assertion from pm.response.to.have.status(202) to check the
X-RateLimit-Api-Remaining header instead — the 202 check is INCOMPATIBLE because
/user/v2/profile is not deployed on feat/COM-612/rate-limiting."

How would you like to handle this?
[FIX]         — apply the proposed change to the collection (I'll show the exact diff first)
[SKIP]        — exclude this folder via --folder flag for this run only. Collection is NOT modified.
[INVESTIGATE] — show me the full raw response body for this request
[STOP]        — abort the Newman run
```

Wait for explicit user choice. NEVER auto-apply any action.

**6d. Execute chosen action:**

- **FIX**: Show the exact JSON diff of the collection change. Ask "Apply this change? [YES/NO]". If YES: apply minimal targeted change to the collection file. Then proceed to Step 6e.
- **SKIP**: Add this folder to the `--folder` exclusion list. Re-run Newman (Step 4) with updated exclusion. Do NOT modify the collection.
- **INVESTIGATE**: Run `curl` against the failing endpoint with the same auth, show the raw response. Return to 6c with more context.
- **STOP**: Abort. Report how many passed before stopping. Skip to Step 7 with note "Run aborted by user at failure #{N}".

**6e. After FIX or SKIP**: Re-run the full Newman suite (Step 4). Return to Step 5.

Repeat until 0 failures OR user types STOP.

## Step 7 — Update or create e2e-test-report.md
Locate `features/{ticket-id}/e2e-test-report.md` or use project root; if it exists, update Summary, Run date, Duration, Skipped folders, and append one `## Run History` row; otherwise create:
```markdown
# E2E Test Report — {Project or Feature name}
> **Collection**: {collection name} · **Run date**: {date time timezone} · **Branch**: `{git branch}` · **Environment**: {env name} ({base URL}) · **Duration**: {total time} · **Skipped folders**: {list with reason, or "None"}
## Summary
| Metric | Value |
|---|---|
| Total requests | **{N}** |
| Passed requests | **{N}** ✅ |
| Failed requests | **0** |
| Skipped folders | **{N}** (see above) |
| Total assertions | **{N}** |
| Overall result | ✅ **PASSED** |
## Folder Results
| # | Folder | Requests | Assertions | Result |
|---|---|---|---|---|
| 1 | {folder name} | {N} | {N} | ✅ PASS |
## What Was Not Tested
| Folder | Reason |
|---|---|
| {folder name} | {reason — e.g., "Requires manual Redis shutdown", "Endpoint not deployed on this branch"} |
## Run History
| Date | Branch | Requests | Assertions | Failures | Duration |
|---|---|---|---|---|---|
| {date} | `{branch}` | {N} | {N} | 0 | {time} |
```
```bash
echo 'Step done: Report file exists and contains updated counts from this run'
```
## Postman Collection Quality Standards

> When generating or extending collections via the `postman-collection` skill, the AI must follow these standards. This applies to any project, any language/framework.

- **Folder structure**: `01 — Setup` → `02 — CRUD` → `03 — Happy Path` → `04 — Edge Cases` → `05 — Validation Errors` → `06 — Auth` → `07 — Error/Failure` → `08 — Teardown`. Number folders with `01 —`, `02 —` prefixes.
- **Every request has a test script** — minimum: status code check + `pm.test('Response time < 5s', () => pm.expect(pm.response.responseTime).to.be.below(5000))`. Mutation requests: also check response shape (key fields present and correct values).
- **Environment variables for all auth and IDs** — never hardcode API keys, resource IDs, or base URLs in request URLs. Use `{{base_url}}`, `{{api_key}}`, `{{resource_id}}` etc.
- **Auto-capture in test scripts** — when a Create (201) request succeeds, capture the created resource ID into an environment variable for downstream requests.
- **Pre-request scripts for env switching** — multi-environment support using `pm.environment.get('base_url')` pattern.
- **Setup and teardown are idempotent** — running the collection twice must be safe. Setup creates resources if they don't exist; teardown deletes them.
- **Test isolation** — each folder/scenario must clean up after itself.
- **Negative cases included** — missing required fields → 400, wrong auth → 401, duplicate → 409, not found → 404. Each with assertion on error message format (not just status code).

---

## Exit Conditions / Done Definition

- Newman run completed with 0 failures (or user explicitly stopped)
- Every failure was diagnosed, presented to user, and resolved via FIX or SKIP (user approved each)
- No collection was modified without showing diff and receiving explicit YES
- No `.gitignore` included in any commit without explicit YES
- e2e-test-report.md created or updated

---

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|---|---|---|---|
| `postman-collection` | Step 1 Mode B — if user chooses (b) or (c) | Endpoint list, project stack | Updated/generated collection JSON |

---

## Example Invocations

**Mode A (auto-triggered after implement-and-test):**
> Parent skill completes → newman-tester receives context of changed endpoints → presents assessment → user says YES → prerequisites checked → run plan shown → user confirms → Newman executes → results parsed → report updated.

**Mode B (standalone):**
> "use the newman-tester skill"
> → AI asks: which collection, which folders to skip, which environment
> → discovers collections, presents assessment
> → user says "run all, skip folder 23"
> → prerequisites checked
> → run plan shown: "Folders: all except 23. Newman flags: ..."
> → user says YES
> → Newman runs
> → 1 failure found → full diagnosis shown → user says SKIP → re-run → 0 failures → report created

---

## What I Will NOT Do

- Modify the Postman collection without showing the diff and receiving explicit `[FIX]` + `[YES]`
- Run Newman without user confirmation of the run plan
- Auto-skip a failing folder without user choosing `[SKIP]`
- Fix code bugs (report them and stop)
- Include `.gitignore` in a commit without asking
- Generate a report if there are unresolved failures

---

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 2 (health check) | Server URL not found in any config file | Ask user: "What is your server's base URL?" |
| Step 2 (auth) | Environment file not found | Search for `*.postman_environment.json` in project. If none: ask user to provide auth values. |
| Step 6 (diagnosis) | Cannot determine if failure is CODE BUG or STALE ASSERTION | Show full response body to user. Ask: "Is the API response correct? [YES — stale assertion / NO — code bug]" |
| Step 6 (FIX) | Proposed collection change is complex / affects multiple requests | **STOP. Tell the user: "This fix affects N requests. I recommend reviewing the collection manually. I'll skip this folder for now." Do not continue.** |
| Step 7 (report) | No features/ directory and no ticket ID detectable | Save report as `e2e-test-report.md` in project root. |

---

---

## Step 8 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ newman-tester — done?
  □ Steps 0–8 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Fix failing code (if CODE BUG found)   — say: "use the implement-and-test skill — fix [description]"
  B) Extend collection coverage             — say: "use the postman-collection skill"
  C) Prepare PR                             — say: "use the pr-preparation skill"
  D) Review code before testing             — say: "use the code-reviewer skill — review PR #N"
  E) Get help                              — say: "help"

⭐ If 0 failures → Option 3. If CODE BUG found → Option 1. If collection gaps found → Op

💾 Report auto-saved to e2e-test-report.md after every clean run. No manual save needed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
