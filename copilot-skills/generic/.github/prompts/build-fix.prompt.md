---
agent: agent
description: Systematically diagnose and fix build/test failures
---

Read and follow the bug diagnosis workflow in `.github/skills/bug-tracer/SKILL.md`.

Also read `.github/copilot-instructions.md` §Build & Test for project build commands.

Key steps: capture full error → categorize (compilation/dependency/test/spring-context/config) → trace root cause → suggest fix. Run `./mvnw test -Dtest=FailingClass` to verify.
