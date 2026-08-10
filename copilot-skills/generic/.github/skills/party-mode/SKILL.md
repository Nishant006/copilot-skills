---
name: party-mode
description: "Multi-persona discussion mode — brings PM, Architect, Dev, SecRev, SRE into one session for architectural decisions and tradeoffs"
last-updated: 2026-06-09
layer: 1
triggers-sub-agents: []
triggered-by: []
---

> **EXECUTE AS SCRIPT**: Read Steps 0–N in order. Do not skip any step. Do not proceed to the next step until the current step's check passes.


## Purpose

Simulate a structured team discussion for hard decisions. The AI plays multiple expert personas simultaneously, each contributing their perspective. Personas can agree, disagree, challenge, and ask each other questions. Ends with a structured decision summary and concrete code-level implications.

**Use when**: architectural tradeoff, design decision, technology choice, post-mortem, or sprint retrospective — any question where multiple valid approaches exist.

## Entry Conditions

- Developer poses a question, decision, or scenario involving tradeoffs
- Topic should have at least 2 valid approaches (otherwise use code-explorer or blast-radius)
- If the question is purely factual ("how does X work?"): **REDIRECT** to code-explorer
- If the question is about impact ("what breaks if I change X?"): **REDIRECT** to blast-radius
- If the question is **too vague** to generate meaningful debate (e.g., "discuss my project"): **STOP. Report: "Your question is too broad for structured debate. Please provide: 1) A specific decision with 2+ options, or 2) A tradeoff scenario. Example: 'Should we use Redis or Kafka for event deduplication?'" Do not continue.**
- If **no codebase context** is available for a codebase-dependent question: **STOP. Report: "I need access to the repository to ground this discussion. Confirm I'm in the right directory." Do not continue.**

## Clarifying Questions

Ask these before proceeding:

1. "Who do you want leading the discussion?" (show persona table below; all 5 personas still contribute in Round 1, your selection only determines where follow-up emphasis goes)
2. "What is the specific decision or tradeoff to debate?" (must be concrete enough for structured discussion)

If developer says "you decide" or "all of them" for question 1: AI uses all 5 personas, and may give extra follow-up emphasis to the 2-3 most relevant ones based on topic. Explain why: "I'll include all 5 personas, with extra emphasis on [Arch], [Dev], and [SRE] because this topic involves design tradeoffs, implementation feasibility, and production reliability."

Proceed only after answers are received (at minimum: the topic/decision must be confirmed).

> **Breadcrumb rule**: Prefix every action with `Step N/M:` per AGENTS.md §Anti-Drift & Context Persistence Protocol.

> 🔒 **Graphify-First (mandatory)**: Before ANY grep in this skill for class/architecture reference verification, check if `graphify-out/graph.json` exists. If it does, run `graphify query` first. Use grep only to supplement or verify. See `.github/instructions/graphify.instructions.md` for full protocol.

## Step 0 — Verify Topic

Confirm the developer has presented a question or scenario with at least 2 valid approaches.

**STOP. If no concrete question or decision was stated, ask: "What is the architectural question or decision you want the panel to discuss?" Do not assemble the panel until the question is clear.**

## Step 1 — Assemble the Panel

Present the available personas:

[PROJECT-SPECIFIC — adapt expertise descriptions per codebase]

| Persona | Label | Expertise | When Most Useful |
|---------|-------|-----------|-----------------|
| Product Manager | **[PM]** | Business rules, acceptance criteria, multi-site impact, customer value, priority tradeoffs | When requirements are unclear or multi-site decisions needed |
| Architect | **[Arch]** | System design, EventProcessor patterns, blast radius, scalability, ADRs, design patterns | When design tradeoffs or new patterns are involved |
| Developer | **[Dev]** | Implementation feasibility, code patterns, test coverage, time estimates, existing code constraints | When implementation approach is unclear |
| Security Reviewer | **[SecRev]** | PII handling, CWE risks, credential management, OWASP Top 10, input validation, log masking | When security implications exist |
| SRE | **[SRE]** | Circuit breakers, dead-letter queues, observability, failure modes, alerting, capacity, SLAs | When reliability or production concerns exist |

Confirm panel and topic. Say:
"Panel confirmed: [personas]. Discussing: [topic]. I'll run the discussion."

```bash
# ✓ Check before moving on: Panel selected, topic confirmed.
echo 'Step done: Panel selected, topic confirmed'
```
## Step 2 — Facilitate the Discussion

**Facilitation Rules:**
- All 5 personas contribute in Round 1 minimum. Round 2+ is optional if consensus is reached early.
- After all personas have spoken: open the floor for cross-discussion (personas respond to each other: "[Arch] to [Dev]: Your approach works but...")
- AI labels every response: "**[Persona]:** [response]"
- Personas MUST disagree where their expertise conflicts — agreement theatre is useless
- Maximum 3 rounds before summary (to prevent endless loops)
- Developer can direct questions to specific personas: "@Arch what about the blast radius?"
- Developer can say "summarize" or "wrap up" at any time to skip to Step 3

**Round 1 — Initial Positions** (all 5 personas speak once):
Each persona gives:
1. Their position on the topic
2. Their reasoning (from their domain expertise)
3. One concern about the alternative approach(es)

**Round 2 — Cross-Discussion** (optional, skip if consensus reached in Round 1):
- Personas respond to each other's concerns
- At least one disagreement must be surfaced and explored
- Developer can ask follow-up questions to any persona

**Round 3 — Resolution** (if needed):
Each persona states: "My position has [changed / not changed] because [reason]."

```bash
# ✓ Check before moving on: All 5 personas have spoken, disagreements surfaced.
echo 'Step done: All 5 personas have spoken, disagreements surfaced'
```
## Step 3 — Decision Summary
```bash
grep -rn "ClassName" src/main/java/ --include="*.java" -l
```
- Remove/correct unverified references or mark them `⚠️ [Name] — not verified in current codebase`.
```markdown
## Discussion Summary: [topic]
**Fill in after Step 3:**

| Dimension | PM view | Architect view | Dev view | SecRev view | SRE view |
|---|---|---|---|---|---|
| [key tradeoff] | [opinion] | [opinion] | [opinion] | [opinion] | [opinion] |

**Recommendation**: [one sentence — what to do and why]
**Code-level implications**: [specific files/classes/patterns that will change]
**Next action**: [what developer should do immediately after this discussion]

### Positions
| Persona | Position | Key Concern |
|---|---|---|
| [Persona] | [one line] | [one line] |
### Points of Agreement
- [...]
### Points of Disagreement
- [...]
### Recommended Decision
[one paragraph]
### Code Implications
- Classes/files: [list with paths]
- New patterns: [if any]
- Test impact: [what tests need updating]
### Trade-offs Accepted
- [...]
### Open Questions (if any) — [...]
### Next Skill — [exact invocation phrase]
```
```bash
# ✓ Check before moving on: Summary delivered with all sections populated, including Code Implications.
echo 'Step done: Summary delivered with all sections populated, including Code Implications'
```
## Exit Conditions / Done Definition

- All 5 personas have contributed in Round 1
- Additional rounds were run only if needed to resolve disagreement or clarify tradeoffs
- A decision summary with clear recommendation has been produced
- Code-level implications are explicitly stated (not just abstract tradeoffs)
- Developer has received a concrete recommendation they can act on

## Sub-Agents

party-mode is discussion-only. It does NOT trigger sub-agents.

## Example Invocation

> "use the party-mode skill — should we use Redis Pub/Sub or Kafka for real-time notifications?"

Panel assembled: PM, Architect, Dev, SecRev, SRE. 3 rounds of debate → decision summary with cost/complexity tradeoff.

## What I Will NOT Do

- Modify any code or files (discussion only)
- Give only one viewpoint — all 5 personas must contribute in Round 1
- Avoid reaching a conclusion — always present a clear recommendation
- Replace the dev team's final judgment — recommendation is input, not mandate

---

## Step 4 — What To Do Next (Always Show This)

**Present this at the end of every run, unconditionally:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ party-mode — done?
  □ Steps 0–4 executed (including this step)
  □ Verifiable outcomes confirmed
  □ No unresolved stops remain

What next?
  A) Write spec from decision               — say: "use the spec-writer skill for COM-XXX"
  B) Plan implementation                    — say: "use the impl-planner skill for COM-XXX"
  C) Check impact of decision               — say: "use the blast-radius skill on [class affected by decision]"
  D) Explore code before deciding           — say: "use the code-explorer skill — [area under discussion]"
  E) Get help                              — say: "help"

⭐ Based on discussion outcome — if a decision was made → Option 1 or 2. If it was deferred pending more context → Option 3 or 4.

💾 Save output? "Save as MD? (YES — path / NO)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
