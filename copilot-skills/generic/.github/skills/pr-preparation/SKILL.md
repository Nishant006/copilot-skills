---
name: pr-preparation
description: "Run pre-PR checklist, create commit, and open pull request"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [blast-radius, feature-docs, postman-collection, architecture-diagrammer]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Prepare and open a pull request after implementation is complete. Runs the project checklist in self-review mode, generates a blast-radius summary, validates the commit message, and creates the PR — only after explicit developer approval. Use this skill after implement-and-test completes.

## Entry Conditions

- ALL tasks in `plan.md` marked `- [x]` (or fast-track: code changes done + tests pass)
- Full build verification passes with zero test failures
- No pending stop conditions from implement-and-test
- **Feature docs are fresh** (no src/ commits after docs generation — see Step 0b)
- **Postman collection is fresh** (no endpoint changes after collection generation — see Step 0b)
- If any condition is not met: **STOP. Resolve the missing condition before starting PR preparation. Do not continue.**

## Clarifying Questions

Before proceeding, ask the developer:

- What is the target branch for this PR (e.g., `release`, `master`, `release/x.y`)?
- Should specific reviewers be assigned? If so, provide GitHub usernames.
- Any additional context or notes for the reviewer?
- Should this be opened as a draft PR? (use `--draft` flag when code is ready but reviewer not yet assigned)

Proceed only after answers are received.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

## Step 0 — Verify Entry Conditions

```bash
# Verify: plan.md is APPROVED and all tasks complete
grep "Status:" features/*/plan.md 2>/dev/null | head -3
grep -c "\- \[x\]" features/*/plan.md 2>/dev/null | head -3
grep -c "\- \[ \]" features/*/plan.md 2>/dev/null | head -3
git status --short 2>/dev/null | head -5
```
**STOP. If plan.md shows `Status: DRAFT` (not APPROVED), get APPROVE from developer first.**
**STOP. If any tasks show `- [ ]` (not done), complete them first in implement-and-test. Do not start PR preparation until all tasks are marked [x].**


## Step 0b — Artifact Freshness Gate (BLOCKING)

```bash
# Check if feature-docs and postman-collection are fresh vs latest src/ commit
LATEST_SRC=$(git log -1 --format=%ct -- "src/" 2>/dev/null || echo 0)
DOCS_TS=$(stat -f %m features/*/testing.md 2>/dev/null | sort | tail -1 || echo 0)
POSTMAN_TS=$(stat -f %m postman/*.postman_collection.json 2>/dev/null | sort | tail -1 || echo 0)
echo "src_last=$LATEST_SRC docs_ts=$DOCS_TS postman_ts=$POSTMAN_TS"
```

**STOP. If `src_last > docs_ts`: feature-docs is stale — re-run implement-and-test to sync.**
**STOP. If `src_last > postman_ts`: postman-collection is stale — re-run implement-and-test to sync.**


## Step 1 — Run self-review checklist

Execute every item in the Self-Review section of [pr-checklist.md](pr-checklist.md). Record each item as PASS or FAIL.

   If any checklist item FAILs:
   - Report the specific failing item with context
   - **Do NOT create a partial PR** — hand back to implement-and-test with: "Checklist item '[item]' failed: [details]. Fix this before PR can be created."
   - The developer must re-invoke pr-preparation after the fix

```bash
# ✓ Check before moving on: Checklist completed; all items pass or exceptions are documented before continui
./mvnw test 2>/dev/null | tail -5 || npm test 2>/dev/null | tail -5 || go test ./... 2>/dev/null | tail -5
```
## Step 2 — Trigger `blast-radius` sub-agent

Provide the list of all changed files with a one-line description of each change.

```bash
# ✓ Check before moving on: Impact report received and aggregate risk tier recorded for the PR summary.
git diff --staged --name-only 2>/dev/null | head -10
```
## Step 3 — Validate branch, commit message, and stage changes

- Verify current branch name matches convention <!-- [PROJECT-SPECIFIC] -->: `feat/COM-XXX/slug`, `fix/COM-XXX/slug`, `config/COM-XXX/slug`, `refactor/COM-XXX/slug`, `build/COM-XXX/slug`
- If branch name does not match: **STOP. Branch name '[name]' does not follow convention. Expected: [type]/[TICKET]/[description]. Rename with `git branch -m [new-name]`. Do not continue.**
- Branch prefix pattern (`COM-XXX`) and allowed types come from AGENTS.md §Branch Naming. Update when porting.
- Ensure the commit message follows the project convention: `type(scope): description [TICKET-ID]`. Types: `feat`, `fix`, `refactor`, `config`, `build` (per §Commit Convention in AGENTS.md). Scope: affected module or component.
- Stage the intended files and inspect `git status` for unexpected untracked or unrelated changes before presenting the diff.

```bash
# ✓ Check before moving on: `git status` shows the expected staged files only, and no untracked surprises re
git diff --staged --name-only 2>/dev/null | head -10
```
## Step 4 — Show diff and PR summary to developer

Present:
- Files changed (count and list)
- Tests added / modified (count)
- Config changes (if any)
- Blast-radius risk level and key impacts
- Proposed commit message
- Target branch and reviewers
- The staged diff for developer review

```bash
# ✓ Check before moving on: Diff + commit message shown to the developer.
git log --oneline -3 2>/dev/null
```
## Step 5 — Wait for COMMIT YES

Present the full diff and commit message, then: `"Review the diff and commit message above. Type COMMIT YES to commit, or REVISE: [feedback] to adjust."`

   Wait for developer input:
   - **COMMIT YES** → Create commit with validated message. Proceed to Step 6.
   - **REVISE: [feedback]** → Adjust commit message or changes per feedback. Return to Step 4.
   - **Anything else** → Reply: `"Gate requires exact token: COMMIT YES or REVISE: [your feedback]. Please re-enter."`

```bash
# ✓ Check before moving on: Exact token `COMMIT YES` received and the commit is created.
git log --oneline -3 2>/dev/null
```
```bash
# Verify: commit was created
git log --oneline -3 2>/dev/null
```

## Step 6 — Push branch

After Step 5 (commit created) but before push, run the topology-change check:

```bash
git diff --name-only HEAD~1 | grep -E "controller/|service/impl/|security/|producer/|config/|application-.*.yml"
```

If ANY matches are found:

Present to the developer:
```
⚠️ This PR touches topology-changing paths:
[list matched files]

Architecture docs may need updating.
  A) Run architecture-diagrammer refresh now (recommended): type YES
  B) Skip with justification: type SKIP: [your reason]
  C) Already updated in this PR: type DONE
```

**On YES**: Output `"ℹ️ I will now invoke architecture-diagrammer in refresh mode."` Then invoke the architecture-diagrammer skill with mode=refresh. After it completes, **stage the new `.github/kt/` changes, show the updated diff, and require a fresh `COMMIT YES`** before creating the amended commit. Never amend silently.

**On SKIP**: **⛔ SKIP GATE** — Before accepting SKIP, warn the developer:
  ```
  ⚠️ CI WARNING: copilot-enforce.yml does NOT honour arch-skip comments.
  Choosing SKIP means the CI architecture-drift-check will flag this PR.
  You will need to manually resolve or suppress the CI failure before merging.
  Type SKIP again to confirm you accept the CI risk, or YES to run refresh now.
  ```
  Only proceed with SKIP after developer types it a second time. Add the justification as a comment in the PR body: `<!-- arch-skip: [developer's reason] -->` AND add a visible PR body warning: `> ⚠️ KT docs not updated — see arch-skip comment. CI architecture-drift-check may fail.`

**On DONE**: Verify that `git diff --name-only HEAD~1 -- .github/kt/` returns at least one file. If not, warn: "No `.github/kt/` files are in this commit. Are you sure? Type DONE again to confirm, or YES to run refresh."

<!-- [PROJECT-SPECIFIC]: the topology paths (controller/, service/impl/, security/, producer/, application-*.yml) are specific to this project. Update for your project structure. -->

After the topology check resolves:

- **Show push target** — Present: `"Push to {remote}/{branch}? This will push N commit(s). Type PUSH YES to proceed."`
- **Wait for PUSH YES** — Only push after receiving explicit `PUSH YES`.
- **Push branch**:
  - If no PR exists for this branch, push normally.
  - If a PR already exists for this branch and the local history was amended/rebased:
    - **⚠️ FORCE-PUSH WARNING**: Present: `"PR already exists. This will force-push to update it. Confirm: PUSH YES"`
    - Only force-push after a second explicit `PUSH YES` confirmation.

```bash
# ✓ Check before moving on: Exact token `PUSH YES` received and the branch push succeeds.
echo 'Step done: Exact token `PUSH YES` received and the branch push succeeds'
```
## Step 7 — Create/update PR

- Show the PR title, target branch, and body summary to the developer.
- Ask: "Ready to create this PR? Type YES to proceed."
- On YES:
  - If no PR exists for this branch: create a new PR with checklist results, blast-radius summary, and reviewer context in the body.
  - If a PR already exists (`gh pr list --head <branch>`): update the PR body and add a comment such as `"Updated with latest changes. Blast risk: [LEVEL]."`
  - If topology-changing paths were detected and refreshed, include the architecture context in the PR description; if the developer accepted a skip, include the skip warning/comment.
- Report the PR URL to the developer.

```bash
# ✓ Check before moving on: Developer confirmed PR creation with YES. PR created or updated on GitHub and th
git diff --staged --name-only 2>/dev/null | head -10
```
## Exit Conditions / Done Definition

- PR is created on GitHub with a valid URL
- PR body contains blast-radius summary and checklist results
- Commit message matches the validated format
- Developer has explicitly typed COMMIT YES before commit
- Developer has explicitly typed PUSH YES before push
- PR targets the correct branch with correct reviewers (if specified)

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|---|---|---|---|
| `blast-radius` | Step 2 — always | List of changed files + one-line change descriptions | Aggregate risk level + impact summary for PR body |
| `feature-docs` | Staleness detected at Step 0b → redirects to `implement-and-test` to regenerate | Feature ticket-id | Fresh docs (via implement-and-test re-run) |
| `postman-collection` | Staleness detected at Step 0b → redirects to `implement-and-test` to regenerate | Feature endpoints | Fresh collection (via implement-and-test re-run) | regeneration |
| `architecture-diagrammer` | Step 6 — topology change detected | Changed components | Architecture context for PR |

## Example Invocation

**Developer says:**
> "Prepare the PR for COM-045."

**AI responds:**
> "Before I prepare the PR:
> 1. What's the target branch? (e.g., release, master)
> 2. Should I assign specific reviewers? Provide GitHub usernames if so.
> 3. Any notes for the reviewer?"

*(After answers, AI runs checklist, blast-radius, validates commit, shows summary, waits for COMMIT YES, pushes after PUSH YES, then creates PR.)*

> "PR #42 created on `release`. Reviewers: @alice, @bob. Blast risk: LOW. Ready for code review."

## What I Will NOT Do

- Commit without explicit COMMIT YES from the developer
- Push without explicit PUSH YES from the developer
- Skip the self-review checklist
- Skip the blast-radius summary
- Create a PR with failing tests or unresolved stop conditions

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 1 (checklist) | Checklist item FAILs | Do NOT create PR. Run `implement-and-test` to fix. |
| Step 5 (commit gate) | Merge conflicts on target branch | Rebase: `git rebase origin/release`. If complex, ask developer to resolve manually. |
| Step 6 (push) | Push rejected (force push needed) | Rebase first: `git rebase origin/<target>`. If updating YOUR OWN PR branch after rebase/amend, force-push is allowed with double `PUSH YES` (see Step 6). NEVER force-push to shared/protected branches (`main`, `master`, `release`). |
| Step 6 (topology check) | Topology paths changed but KT docs not updated | Run onboarding skill Level 2+ → YES to refresh KT docs before PR. |

---

---

## Step 8 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ pr-preparation — done?
  □ Steps 0–8 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Self-review the PR                     — say: "use the code-reviewer skill — review PR #N"
  B) Fix pre-push failures                  — say: "use the implement-and-test skill — fix [failure]"
  C) Check impact summary                   — say: "use the blast-radius skill on [changed class]"
  D) Get help                              — say: "help"

⭐ run a self-review before assigning human reviewers.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
