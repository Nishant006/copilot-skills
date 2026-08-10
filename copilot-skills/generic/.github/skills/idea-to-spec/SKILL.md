---
name: idea-to-spec
description: "Structured 15-minute discovery conversation — turns a rough idea into a brief.md that feeds spec-writer"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: [code-explorer]
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Turn "we should notify customers when X" into a structured brief.md. Bridge between informal idea and formal spec-writing. Does NOT replace spec-writer — it feeds it. The brief captures the developer's intent in a structured format so spec-writer can pre-populate answers instead of repeating questions.

## Entry Conditions

- Developer has a rough idea but no requirements document
- No Jira ticket required (ticket may not exist yet)
- If `features/<ticket-id>/spec.md` already exists: **STOP. A spec already exists for this ticket. Use spec-writer to update it, or use a different ticket ID. Do not continue.**

### Resume Support

If `features/<idea-slug>/brief.md` already exists with `Status: DRAFT`:
- Read the existing brief
- Report: "Found an in-progress brief for [idea-slug]. It has answers for [N/5] questions."
- Ask: "Resume from question [N+1], or start fresh?"
- If **resume**: skip already-answered questions, continue from next unanswered
- If **start fresh**: overwrite the existing brief

## Clarifying Questions

NONE upfront — the 5 structured discovery questions in Steps 1-2 ARE the clarification process. Each question in the step-by-step process below acts as a gate: ask the question, wait for the answer, then proceed to the next question. Do not ask multiple questions simultaneously. Do not ask additional questions outside of the defined 5.

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

## Step 0 — Verify Entry Conditions

```bash
# Check: is there already a brief.md or spec-infobip.md for this idea?
ls features/ 2>/dev/null | head -5
```
**No hard stop — informational. If a brief.md already exists, offer to extend it rather than start fresh.**

## Step 1 — Capture the Idea

Ask: "Describe the idea in one or two sentences — what problem are you solving?"

Listen without interrupting. Do not ask follow-up questions yet. Record the raw idea verbatim.

```bash
# ✓ Check before moving on: Idea captured and understood.
echo 'Step done: Idea captured and understood'
```
## Step 2 — Run 5 Structured Discovery Questions (in order, one at a time)

**Q1**: "Who is the customer and what do they want to feel or know when they get this?"

**Q2**: "What event or action triggers this? Where does it originate?"

**Q3**: "Which communication channels should be used? (push / email / SMS / WhatsApp)"
[PROJECT-SPECIFIC: adjust channel options per project]

**Q4**: "What does success look like? Give me 2-3 acceptance criteria in plain English."

**Q5**: "What is explicitly NOT included in this idea? What are you NOT trying to solve?"

**Rules for asking:**
- One question at a time — wait for full answer before next question
- Do not interpret or pre-fill answers — record what the developer says
- If answer is vague: ask ONE follow-up ("Can you be more specific about X?") then move on
- Total target: 10-15 minutes of conversation
- Maximum questions: 5 + up to 5 follow-ups = 10 total

```bash
# ✓ Check before moving on: All 5 questions answered.
echo 'Step done: All 5 questions answered'
```
## Step 3 — Check for Existing Patterns

If Q2 reveals a new event type or integration: auto-trigger **code-explorer** to verify whether a similar pattern already exists in the codebase.

Say: "Let me quickly check if something similar already exists..."

code-explorer returns: existing pattern with file:line references OR "no similar pattern found"

Include finding in brief.md under "Existing Patterns".

**Skip condition**: Only skip this step if the idea is purely non-code (e.g., process change, documentation-only). In that case, write "N/A — non-code idea" in the Existing Patterns section.

```bash
# ✓ Check before moving on: Existing pattern check completed OR explicitly marked N/A with reason.
echo 'Step done: Existing pattern check completed OR explicitly marked N/A wi'
```
## Step 4 — Generate brief.md

Save to: `features/<ticket-id>/brief.md`

If no Jira ID given: ask "Do you have a ticket number? (COM-XXX or type 'skip')"
If skipped: ask for a short label (e.g., "wishlist-sale") and save to `features/<label>/brief.md`

**brief.md format:**
```markdown
# Brief: [idea title]

**Status**: DRAFT
**Date**: [today]
**Author**: [developer]

## Problem Statement
[2-3 sentences: what problem are we solving and for whom? — from Step 1 + Q1]

## Proposed Solution
[2-3 sentences: what will we build and how? — synthesized from Q2 + Q3]

## Acceptance Criteria (Plain English)
1. [AC1 from Q4]
2. [AC2 from Q4]
3. [AC3 from Q4]

## Scope

### In Scope
[channels, sites, trigger event — from Q2 and Q3]

### Out of Scope
[explicitly excluded — from Q5]

## Existing Patterns
[result from Step 3 code-explorer check, or "No similar pattern found"]

## Next Step
Use the spec-writer skill: "use the spec-writer skill for [JIRA-ID] — [one-line description]"
The brief.md will be read automatically by spec-writer.
```

```bash
# ✓ Check before moving on: brief.md created on disk at the correct path.
ls features/*/brief.md 2>/dev/null && head -3 features/*/brief.md
```
## Step 5 — Handoff

Tell the developer:
```
brief.md is saved at features/{label}/brief.md.

To build the spec from this brief, say:
  "use the spec-writer skill for {ticket-id}"

The spec-writer will read brief.md and pre-populate answers — you'll only be asked about gaps.
```

```bash
# Verify: brief.md exists
ls features/*/brief.md && head -5 features/*/brief.md
```


## Smart Defaults

```
"Describe your idea in one or two sentences. I'll ask 5 structured questions
to turn it into a brief.md, then hand off to spec-writer.
No Jira ticket needed — we can create one later."
```

## Exit Conditions / Done Definition

- [ ] brief.md created at `features/<ticket-id>/brief.md`
- [ ] Developer has the exact spec-writer invocation phrase
- [ ] OR: spec-writer has been invoked directly (Step 5 YES path)

## Sub-Agents

| Sub-Agent | Trigger | Input | Output |
|-----------|---------|-------|--------|
| code-explorer | Step 3 — when Q2 reveals a new event type or pattern | Event name or pattern description | Existing similar implementation with file:line OR "no similar pattern found" |

## Example Invocation

**Example 1: With Jira ticket**
```
Developer: "use the idea-to-spec skill for COM-612 — wishlist sale notification"
AI: "Great! Describe the idea in one or two sentences."
Developer: "When a wishlist item goes on sale, we should push-notify the customer."
AI: [Asks Q1-Q5, one at a time, 10 min total]
AI: [Triggers code-explorer: "Any existing wishlist-related EventProcessor?"]
AI: "brief.md created at features/COM-612/brief.md
     Next step: 'use the spec-writer skill for COM-612 — wishlist sale push notification'
     Shall I invoke spec-writer now?"
```

**Example 2: Without Jira ticket**
```
Developer: "use the idea-to-spec skill — I think we should notify customers when their refund is processed"
AI: "Describe the idea in one or two sentences."
Developer: "Customer should get SMS+push when refund is confirmed by payment gateway."
AI: [Asks Q1-Q5]
AI: "Do you have a Jira ticket number? (COM-XXX or type 'skip')"
Developer: "skip"
AI: "brief.md created at features/refund-notification/brief.md
     Create a Jira ticket, then invoke:
     'use the spec-writer skill for COM-XXX — refund processed notification'"
```

## What I Will NOT Do

- Replace spec-writer — brief.md is a pre-spec document, not a spec
- Write code or implementation details
- Ask more than 5 + 5 follow-up questions (10 total)
- Pre-fill or assume answers — record what the developer actually says
- Skip Q5 (out-of-scope) — this prevents scope creep in spec-writer

---

### ⚡ Escalation Path

| Stuck At | What Happened | Do This |
|---|---|---|
| Step 2 (discovery) | Developer can't articulate the idea clearly | Ask for a concrete example: "Give me one specific scenario where this would be used." |
| Step 3 (code-explorer) | Existing code already does what the idea describes | **STOP. This already exists in [class]. Did you mean to extend it? Do not continue.** Route to enhancement path. |
| Step 4 (brief writing) | Brief scope is too large for one feature | Suggest splitting: "This sounds like 2-3 features. Let's brief the highest priority one first." |
| Step 5 (handoff) | Developer doesn't have a Jira ticket yet | That's fine — brief.md works without a ticket. Suggest creating one before spec-writer. |

---

## Step 6 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ idea-to-spec — done?
  □ Steps 0–6 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Explore implementation area            — say: "use the code-explorer skill — [area from brief]"
  B) Discuss feasibility                    — say: "use the party-mode skill — [feasibility question from brief]"
  C) Discuss tradeoffs                      — say: "use the party-mode skill — [topic]"
  D) Get help                              — say: "help"

⭐ brief is done, let spec-writer formalize it.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
