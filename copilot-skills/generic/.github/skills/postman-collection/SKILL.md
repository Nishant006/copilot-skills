---
name: postman-collection
description: "Auto-generate comprehensive Postman collections with multi-env support, test scripts, and full API coverage"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [blast-radius]
triggered-by: [implement-and-test, pr-preparation, newman-tester]
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Automatically generate production-grade Postman collections and environment files after feature implementation is complete. Collections include:
- Pre-request scripts for multi-environment switching
- Test assertions on EVERY request (status codes, response shape, value extraction)
- Ordered folder structure: Setup → CRUD → Happy Path → Edge Cases → Validation → Auth → Failure → Monitoring → Teardown
- Environment variables with per-env overrides (local/dev/nonprod/preprod/prod)
- Feature-specific collections that can be merged into the main project collection

## Entry Conditions

### Auto-trigger (post-impl)
- `implement-and-test` skill completes successfully (all plan tasks `[x]`)
- Feature has API endpoints (controller/route classes exist)
- Triggered alongside `feature-docs` at post-impl phase

### Manual trigger
- Developer says `"use the postman-collection skill"` or `"generate postman collection"`
- Developer says `"update postman collection"` — checks last month's commits for changes

### Skip conditions (do NOT generate)
- Feature has NO API endpoints (pure library, internal event handler, background job only)
- Feature is config-only change with no new/modified request/response contracts
- `COPILOT_POSTMAN_ENABLED=0` environment variable is set

### Stop if any of these are true
- Stop if **no controller/route classes are found** after the full grep scan: "No API endpoints found in the feature scope. This skill only applies to features with REST endpoints. Use `SKIP` if this is intentional."
- Stop if **blast-radius returns CRITICAL** for an endpoint being documented: "CRITICAL-risk endpoint [path] detected. Verify the implementation is stable before generating a collection that may become immediately stale."
- Stop if **an existing collection has conflicting request IDs** that would be overwritten: "Merge conflict detected in existing collection. Resolve manually or say `overwrite` to replace."

## Clarifying Questions

Ask only the unanswered questions for manual runs. If this skill is auto-triggered and the parent skill already provided the answers, reuse that context instead of re-asking.

- Which feature/endpoint should I generate the collection for — a specific feature, a single endpoint, or the full API surface?
- Which environments should be included — local, dev, nonprod, preprod, prod?
- Should this merge into the existing main collection or stay separate?
- Is this a net-new collection, or an update to existing coverage for endpoints changed recently?
- Are there existing Postman naming, folder, auth, or variable conventions that must be preserved?

Proceed only after answers are received (skip when auto-triggered — parent provides context).

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> **Phase 1: Discovery (What to test)**

## Step 0 — Verify Entry Conditions

```bash
# Detect project stack
ls pom.xml package.json go.mod requirements.txt Cargo.toml 2>/dev/null
# Check: existing Postman collections?
ls postman/*.postman_collection.json 2>/dev/null || echo "No existing collection"
# Check: feature spec/flow docs available?
ls features/*/spec-infobip.md features/*/flow.md features/*/testing.md 2>/dev/null | head -5
```
**No hard stop — use this output to auto-detect stack and adapt grep patterns in Step 1.**

## Step 1 — Identify API surface

**Auto-detect project technology** (adapt grep patterns accordingly):

| Stack | Grep pattern for endpoints |
|---|---|
| Java/Spring | `@RestController\|@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@RequestMapping` in `*.java` |
| Node.js/Express | `router\.\(get\|post\|put\|patch\|delete\)\|app\.\(get\|post\|put\|delete\)` in `*.ts *.js` |
| Python/FastAPI | `@app\.\(get\|post\|put\|patch\|delete\)\|@router\.\(get\|post\|put\|delete\)` in `*.py` |
| Python/Django | `path(\|re_path(` in `urls.py` |
| Go | `HandleFunc\|Handle\|r\.Get\|r\.Post\|r\.Put\|r\.Delete` in `*.go` |
| GraphQL | `type Query\|type Mutation\|@Query\|@Mutation` in `*.graphql *.ts *.java` |
| gRPC | `rpc ` in `*.proto` |

**Detection logic:** Inspect `package.json`, `pom.xml`, `go.mod`, `requirements.txt`, `build.gradle`, or `Cargo.toml` to determine stack. Then use the appropriate grep pattern.

```bash
# Java/Spring Boot (default — override for other stacks)
grep -rn "@RestController\|@Controller\|@RequestMapping\|@GetMapping\|@PostMapping\|@PutMapping\|@PatchMapping\|@DeleteMapping" src/ --include="*.java"
```

After finding candidate controllers/routes, trigger `blast-radius` on each controller, resource, endpoint class, or route module to discover related methods, DTOs, auth filters, exception handlers, and dependent components. Use the combined grep + blast-radius output as the source of truth for endpoint inventory.

For each endpoint, extract:
- HTTP method
- Path (with path variables)
- Request headers (required + optional)
- Request body schema (from DTO class)
- Response codes (from code: `ResponseEntity`, `@ResponseStatus`, exception handlers)
- Auth mechanism (filter chain, interceptor, `@PreAuthorize`)

```bash
# ✓ Check before moving on: All discovered endpoints are inventoried, and the endpoint count is recorded fro
echo 'Step done: All discovered endpoints are inventoried, and the endpoint c'
```
## Step 2 — Identify existing collection

Check `postman/` for existing collections:

```bash
ls postman/*.postman_collection.json 2>/dev/null
```

If a main collection exists:
- Read its folder structure
- Identify which endpoints are already covered
- Note the pre-request script patterns and variable conventions
- Follow the same conventions in the new feature collection

```bash
# ✓ Check before moving on: Existing collection coverage and conventions are documented, or the absence of a
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
## Step 3 — Read spec and flow docs

If `features/<ticket-id>/spec.md` exists → extract acceptance criteria.
If `features/<ticket-id>/flow.md` exists → extract happy, failure, and edge-case paths.
If `features/<ticket-id>/testing.md` exists → extract test scenarios.

These documents define which requests and assertions must be present.

```bash
# ✓ Check before moving on: Acceptance criteria and scenario sources are extracted from available feature do
echo 'Step done: Acceptance criteria and scenario sources are extracted from '
```
## Step 4 — Identify environment variables needed

From the existing environment file plus the discovered endpoints, identify:
- Base URLs (per environment)
- API keys (per env with `<env>_<key>` pattern)
- Auth headers
- Dynamic IDs set by pre-request or test scripts
- Feature-specific config values

```bash
# ✓ Check before moving on: Required environment variables are enumerated for every discovered request and s
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
> **Phase 2: Generate Collection**

## Step 5 — Generate feature collection file

Create `postman/<FeatureName>.postman_collection.json`. Keep numbering; include only applicable folders.

```text
01 – Setup / Prerequisites — create data, verify setup, sync IDs
02 – CRUD Operations — GET one/list, POST, PUT/PATCH, DELETE, auth failures
03 – Happy Path — primary flow, response/header checks, chained IDs
04 – Bulk / Batch Operations — small/medium/large batches, response checks
05 – Edge Cases & Limits — boundary, quota/rate limit, concurrency(manual), 404, 409
06 – Validation Errors — missing/invalid/enum/size/malformed JSON → 400
07 – Authentication & Authorization — missing/invalid auth → 401, wrong role → 403, valid auth
08 – Failure Scenarios — downstream unavailable, timeout(manual), DB down, feature disabled
09 – Monitoring & Status — health, feature status/metrics, cache/bucket inspection
10 – Teardown / Cleanup — delete data, reset state, clear caches/buckets
```

```bash
# ✓ Check before moving on: Collection JSON is generated with the required 8-folder structure and request c
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
## Step 6 — Add pre-request scripts (collection-level)

EVERY collection MUST have a collection-level pre-request script:

```javascript
// Resolve base_url from active_env
const env = pm.environment.get("active_env") || "local";
const urls = {
    local:   pm.environment.get("local_base_url")   || "http://localhost:8080",
    dev:     pm.environment.get("dev_base_url")     || "https://{{service}}-dev.example.com",
    nonprod: pm.environment.get("nonprod_base_url") || "https://{{service}}.example-stg.com",
    preprod: pm.environment.get("preprod_base_url") || "https://{{service}}-preprod.example-stg.com",
    prod:    pm.environment.get("prod_base_url")    || "https://{{service}}.example.com"
};
pm.environment.set("base_url", urls[env] || urls.local);

// API keys — auto-switch based on active_env
const keysToSwitch = [/* list all env-specific keys */];
keysToSwitch.forEach(key => {
    const val = pm.environment.get(`${env}_${key}`);
    if (val) pm.environment.set(key, val);
});
```

```bash
# ✓ Check before moving on: Collection-level pre-request script exists and resolves environment-specific bas
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
## Step 7 — Add test scripts on EVERY request

EVERY request MUST have a test script. At minimum:

```javascript
// 1. Status code assertion
pm.test("Status 200 OK", () => pm.response.to.have.status(200));

// 2. Response shape assertion
pm.test("Response has required fields", () => {
    const body = pm.response.json();
    pm.expect(body).to.have.property("id");
    pm.expect(body).to.have.property("status");
});

// 3. Value extraction (for chaining)
const body = pm.response.json();
pm.environment.set("extracted_id", body.id);
```

For error cases:

```javascript
pm.test("Status 400 Bad Request", () => pm.response.to.have.status(400));
pm.test("Error code present", () => {
    const body = pm.response.json();
    pm.expect(body).to.have.property("errorCode");
    pm.expect(body.errorCode).to.eql("VALIDATION_ERROR");
});
```

Assertions must use real DTO field names, real error codes, and real auth/header behavior verified from source — never guessed.

```bash
# ✓ Check before moving on: Every request has at least one test assertion, and request/test scripts use veri
echo 'Step done: Every request has at least one test assertion, and request/t'
```
## Step 8 — Generate/update environment file

If `postman/<service>.postman_environment.json` exists:
- READ existing variables
- ADD only the new variables needed by this feature (do NOT remove existing ones)
- Maintain the `<env>_<key>` pattern for per-env values
- Set `type: "secret"` for API keys and tokens

If no environment file exists, CREATE one with:
- `active_env` (default: `local`)
- `<env>_base_url` for each environment
- All feature-specific variables
- Placeholder values clearly marked as `replace-with-<env>-<purpose>`

```bash
# ✓ Check before moving on: Environment file is created or updated with every variable referenced by URLs, h
echo 'Step done: Environment file is created or updated with every variable r'
```
> **Phase 3: Quality Validation**

## Step 9 — Structural validation

Verify the generated collection:
- Valid JSON (parse without error)
- Every request has `method`, `url`, and `header`
- Every request has at least one test script
- Collection-level pre-request script exists
- No hardcoded URLs (all use `{{base_url}}`)
- No hardcoded API keys (all use `{{variable_name}}`)
- Folder names are numbered and ordered
- Collection and folders include descriptions where the project convention expects them

```bash
# ✓ Check before moving on: `cat postman/<Feature>.postman_collection.json | python3 -m json.tool > /dev/nul
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
## Step 10 — Coverage validation

Compare against discovery:
- Every endpoint from Step 1 has at least one request
- Happy-path requests exist for all supported endpoints
- Error/validation/auth cases exist where the code supports them
- Every acceptance criterion from `spec.md` has a corresponding request when applicable
- Response assertions use actual field names from DTOs/classes discovered in Step 1

```bash
# ✓ Check before moving on: Coverage report shows 100% endpoint coverage (every discovered endpoint has ≥1 r
echo 'Step done: Coverage report shows 100% endpoint coverage (every discover'
```
## Step 11 — Convention consistency

If existing collections were found in Step 2:
- Use the same pre-request script pattern
- Use the same variable naming convention
- Use the same test assertion style
- Use the same folder numbering scheme
- Keep the environment file structure consistent

> **Phase 4: Merge & Finalize**

## Step 12 — Offer merge into main collection

If a main collection exists (for example, `Dispatcher_V2.postman_collection.json`):

```text
📋 Feature collection generated: postman/<Feature>.postman_collection.json

Would you like to merge this into the main collection?
  - YES   → Add as a new numbered folder in the main collection
  - NO    → Keep separate (merge manually after testing)
  - SHOW  → Display the folder structure before deciding
```

- **`YES`** → merge (Step 12a below)
- **`NO`** → Skip merge. Report: "ℹ️ Feature collection saved separately. Merge later with: postman-collection → update." End this step.
- **`SHOW`** → Display the folder structure of the main collection, then re-prompt: "Merge now? [YES / NO]"
- **Anything else** → Clarify: "I need `YES`, `NO`, or `SHOW`."

If YES:
1. Read the main collection
2. Find the highest folder number
3. Insert the feature folder as the next number
4. Write the updated main collection
5. Keep the feature file as a backup

```bash
# ✓ Check before moving on: Main collection is updated with new folder (path + folder count reported), OR de
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
## Step 13 — Update check (manual `update` flow)

When triggered as an update instead of a net-new feature:
1. Check git log for the last 30 days: `git log --since="30 days ago" --name-only -- "src/**Controller*" "src/**Resource*" "src/**Endpoint*"`
2. If new or modified endpoints are found:
   - Compare against existing collection coverage
   - Generate requests only for uncovered endpoints
   - Offer to add them to the existing collection
3. If no endpoint changes are found, report `Collection is up to date`

```bash
# ✓ Check before moving on: Coverage delta reported (N new endpoints added, or "collection is up to date").
ls postman/*.postman_collection.json 2>/dev/null | head -3
```
## Step 14 — Prepare final report

Summarize using the **Output Format** exactly.
- Include generated/updated collection and environment file paths.
- Include folder count, request count, test-script count, endpoint coverage, and environments.
- Include variable totals, new vs existing counts, secrets count, and missing values.
- Include merge status, validation status, coverage gaps, and the `To run` steps.
- Remove extra prose; keep required fields only.

```bash
# Verify: collection file was created/updated
ls -la postman/*.postman_collection.json 2>/dev/null
# Verify: collection has test scripts
grep -c "pm.test\|pm.expect" postman/*.postman_collection.json 2>/dev/null | head -3
```

```bash
# ✓ Check before moving on: Final report is presented to the developer with file paths, validation results, 
echo "✓ Check: final report above includes collection path, folder count, and coverage %"
```
## Exit Conditions / Done Definition

This skill is done only when all applicable checks pass:
- [ ] Collection JSON is valid and parseable
- [ ] Every discovered endpoint has at least one request in the generated or updated collection
- [ ] Every request has test assertions (status code plus response/body/error checks as applicable)
- [ ] Collection-level pre-request script exists and all requests use variables instead of hardcoded URLs or secrets
- [ ] Environment file defines every variable referenced by request URLs, headers, bodies, and scripts
- [ ] Request fields, response fields, error codes, and auth headers are verified from code/docs rather than guessed
- [ ] Existing collection conventions are preserved when a main collection or environment file already exists
- [ ] Postman/Newman validation passes when Newman is available; otherwise report validation as skipped with reason
- [ ] Merge outcome is explicit: merged into main, kept separate, or not applicable

## Sub-Agents

| Sub-agent | Trigger point | Input | Expected output | Blocking |
|---|---|---|---|---|
| `blast-radius` | Step 1 — endpoint discovery | Each controller, resource, endpoint class, or route module discovered during API surface analysis; change type: `add` or `modify` | Impact map showing handlers, DTOs, auth filters, exception handlers, and related dependencies so endpoint inventory is complete | Yes |

`blast-radius` is used here to avoid missing endpoints or supporting contracts that simple endpoint grep can miss.

## Example Invocation

**Manual trigger — feature-specific collection**
> "use the postman-collection skill for COM-123"

**Natural-language trigger — endpoint scope**
> "generate postman collection for the notification status endpoints"

**Natural-language trigger — update flow**
> "update postman collection for the endpoints changed this month"

**Natural-language trigger — separate output**
> "create a separate Postman collection for the preferences API; don't merge it yet"

## What I Will NOT Do

- Hardcode real credentials or secrets in the collection
- Generate requests without test scripts
- Skip validation, auth, or error test cases when the discovered API surface requires them
- Assume response shapes, error codes, or auth headers without grep-verifying code/docs
- Generate collections for features without API endpoints
- Modify application code
- Auto-merge into the main collection without asking the developer

## Output Format (if applicable)

```text
✅ Postman Collection Generated

📁 postman/<Feature>.postman_collection.json
   • Folders: {{N}}
   • Requests: {{N}} ({{N}} with test scripts)
   • Coverage: {{N}}/{{N}} discovered endpoints covered
   • Environments: local / dev / nonprod / preprod / prod

📁 postman/<service>.postman_environment.json
   • Variables: {{N}} ({{N}} new, {{N}} existing)
   • Secrets: {{N}} (marked as type: secret)
   • Missing values: {{list or none}}

🔗 Merge status: [Merged into main / Kept separate / N/A]
🔎 Validation: [JSON parse ✅ / Newman ✅ / Newman skipped: reason]
⚠️ Coverage gaps: [none / list each endpoint + why]

📋 To run:
   1. Import collection into Postman
   2. Import/update environment file
   3. Set `active_env = local`
   4. Run folder `01 – Setup` first
   5. Run remaining folders in order

   Newman (CLI): newman run postman/<Feature>.postman_collection.json -e postman/<service>.postman_environment.json --env-var active_env=local
```

## Postman Collection Quality Standards

> When generating or extending collections, always follow these standards:

- **Folder structure**: `01 — Setup` → `02 — CRUD` → `03 — Happy Path` → `04 — Edge Cases` → `05 — Validation Errors` → `06 — Auth` → `07 — Error/Failure` → `08 — Teardown`
- **Every request has a test script** — minimum: status code + `pm.expect(pm.response.responseTime).to.be.below(5000)`
- **Environment variables** for all auth and IDs — never hardcode. Use `{{base_url}}`, `{{api_key}}`, `{{resource_id}}`
- **Auto-capture** — when a Create (201) succeeds, capture the resource ID into an env variable
- **Negative cases** — missing required fields → 400, wrong auth → 401, duplicate → 409, not found → 404
- **Idempotent setup/teardown** — running collection twice must be safe

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 1 | No controllers/routes/endpoints found | Stop and report `No API surface detected`; do not generate an empty collection |
| Step 1 | Endpoint ownership is ambiguous after grep/blast-radius | Narrow scope to a specific controller/route module or ask which feature owns the endpoint |
| Step 6-7 | Request/response contract is unclear | Inspect DTOs, exception handlers, and auth filters; if still unclear, ask the developer for the exact contract |
| Step 8 | Environment URLs or secrets are unknown | Keep placeholders for secrets, ask for per-environment values, and clearly report what is still unresolved |
| Step 9-11 | Newman is unavailable or validation fails | Perform JSON/structure checks anyway, then report `Newman skipped` or the exact validation failure |
| Step 12 | Merge would break numbering or conventions | Keep the feature collection separate and provide manual merge guidance |
| Any step | Tool failure | Retry once, then report the exact error and suggest a manual alternative |

---

## Step 15 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ postman-collection — done?
  □ Steps 0–15 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Prepare the PR                         — say: "use the pr-preparation skill"
  B) Test endpoints manually
  C) Fill coverage gaps                     — say: "use the implement-and-test skill"
  D) Re-check endpoint impact               — say: "use the blast-radius skill on [ControllerClass]"
  E) Get help                              — say: "help"

⭐ proceed to PR prep if implementation is complete and tests pass.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
