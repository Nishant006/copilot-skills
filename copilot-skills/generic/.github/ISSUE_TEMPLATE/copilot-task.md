---
name: Copilot Task
about: Assign a coding task to GitHub Copilot Coding Agent
title: "[Copilot] "
labels: copilot
assignees: copilot
---

## Task Description
<!-- What should Copilot do? Be specific about which files, classes, or behaviors to change. -->

## Acceptance Criteria
- [ ] ...
- [ ] ...
- [ ] `./mvnw verify` passes

## Context
<!-- Relevant files, classes, config keys, or constraints Copilot should know about. -->

**Affected files:**
- 

**Related skills:** (optional — helps Copilot follow the right workflow)
- [ ] Use `spec-writer` approach (new feature)
- [ ] Use `bug-tracer` approach (fix a bug)
- [ ] Use `safe-refactor` approach (structural change)
- [ ] Config/YAML only (no Java logic)

## Constraints
- Follow `AGENTS.md` workflow and `.github/copilot-instructions.md` coding standards
- Run `./mvnw verify` before creating PR
- No PII in logs, no hardcoded secrets
