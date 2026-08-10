---
agent: agent
description: Safe refactoring — structural changes with zero behavior change
---

Read and follow the complete refactoring workflow in `.github/skills/safe-refactor/SKILL.md`.

Also read `AGENTS.md` §Refactoring fast-track path and `.github/copilot-instructions.md` §Design Patterns for existing patterns.

Key steps: blast-radius analysis → plan bottom-up order (leaf → callers → entry points) → apply one file at a time → `./mvnw test` after each change → verify zero behavior change.
