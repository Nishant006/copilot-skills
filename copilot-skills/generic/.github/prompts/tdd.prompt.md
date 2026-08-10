---
agent: agent
description: Test-driven development — write the test first, then implement
---

Read and follow the TDD cycle in `.github/skills/implement-and-test/SKILL.md`.

Also read `.github/copilot-instructions.md` §Test Style for project conventions (JUnit5 + Mockito + @ExtendWith).

Key cycle: write failing test (RED) → minimal implementation (GREEN) → refactor (IMPROVE) → `./mvnw test -Dtest=ClassName` after each step.
