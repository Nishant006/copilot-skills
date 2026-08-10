# Adding a New Skill — Recipe & Portability Guide

> This file was extracted from AGENTS.md to reduce its size. Reference it when creating or porting skills.

## Adding a New Skill — Recipe

Follow this checklist when creating a new skill. Every step is required.

### 1. Create Skill Directory

```
.github/skills/<skill-name>/SKILL.md        # Required — must follow standard structure
.github/skills/<skill-name>/companion.md     # Optional — project-specific patterns [PROJECT-SPECIFIC]
```

### 2. SKILL.md Standard Structure

Every SKILL.md must contain these sections in order:

```markdown
---
name: <skill-name>
description: "<one-line purpose>"
last-updated: YYYY-MM-DD
layer: 1 | 2
triggers-sub-agents: [<list>]
triggered-by: [<list>]
---
## Purpose
## Entry Conditions
## Clarifying Questions
## Step-by-Step Process
## Exit Conditions / Done Definition
## Sub-Agents
## Example Invocation
## What I Will NOT Do
## Output Format (if applicable)
## Skill Completion                        # Reference AGENTS.md §Skill Completion Protocol
## References
```

> **Step formatting**: Skills may use `### Step N — Title` or `### Step N: Title` (both acceptable). The mandatory requirement is numbered, sequential steps with verifiable outcomes.

### 3. Register the Skill

Update these files (all required):

| File | Section to Update | What to Add |
|---|---|---|
| `ROUTING.md` | §Skill Registry table | Row with skill name, phase, sub-agents, triggers, constraints |
| `ROUTING.md` | §Quick Reference: Which Skill Do I Use? | Row with "I want to…" → skill name |
| `ROUTING.md` | §Work-Type Router (if new work type) | New row mapping detection signal → route |
| `.github/copilot-instructions.md` | §File Responsibility Map (if companion exists) | Add companion file entry |
| `AI-WORKFLOW.md` | §4. Skill Map | Add to the skill list |

### 4. Wire Sub-Agent Contracts (if applicable)

If the new skill triggers or is triggered by other skills:
- Update `.github/skills/SUB-AGENT-CONTRACTS.md` — add trigger protocol
- Update the **other** skill's `triggers-sub-agents` or `triggered-by` frontmatter

### 5. Verify

```bash
# Confirm skill file exists and has correct frontmatter
head -10 .github/skills/<skill-name>/SKILL.md

# Confirm no orphan references
grep -rn "<skill-name>" .github/ AGENTS.md ROUTING.md AI-WORKFLOW.md

# Confirm registry consistency (count skill dirs vs registry rows)
ls .github/skills/ | wc -l                      # Filesystem count
grep -c "^\| \`" AGENTS.md | head -1            # Registry row count (should match)
```

---

## Portability — Adapting to Another Repository

**Change** (project-specific):
- `.github/copilot-instructions.md` sections marked [PROJECT-SPECIFIC]
- `.github/kt/` docs (regenerate using `onboarding skill` → Level 2+ → YES)
- `AGENTS.md` §Build commands block (update `./mvnw` → your build tool) and §Jira Format / §Branch Naming / §Commit Convention
- Companion files in `.github/skills/` marked [PROJECT-SPECIFIC]
- Issue templates (adapt to the new service domain)
- Layer 2 skills (api-tester — rewrite for the new domain)

**Keep as-is** (reusable — with caveats):
- `AGENTS.md` Work-Type Router, Phase Definitions, Human-First Protocol, Error Recovery. **Note**: Phase Definitions contain `[PROJECT-SPECIFIC]` examples (Kafka, MongoDB, Azure references) that are illustrative — adapt or remove for your project.
- All Layer 1 SKILL.md files (workflow-generic — search for `[PROJECT-SPECIFIC]` comments/tags to find sections requiring updates; examples using project class names are illustrative and can be replaced)
- `.github/skills/SUB-AGENT-CONTRACTS.md` (reusable protocol)
- `.github/workflows/copilot-enforce.yml` [PLANNED — create per-project when CI is configured] (adjust build command and [PROJECT-SPECIFIC] count commands)
