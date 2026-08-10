# PR Checklist

This checklist is shared by two skills:
- `pr-preparation` uses it in self-review mode before commit/PR creation. Every checklist item should be evaluated and recorded as **PASS** or **FAIL**.
- `code-reviewer` uses it as the validation baseline for what was checked during review.

Layer: **1 (portable)** for Java/Spring Boot projects. Items marked **[PROJECT-SPECIFIC]** should be adapted to the repository's conventions, profiles, architecture rules, and release process.

## PR Self-Review Checklist

Evaluate every checkbox below as **PASS** or **FAIL**.

### 1. Code Quality
- [ ] Class, method, variable, and package names are clear, consistent, and aligned with existing naming patterns.
- [ ] No dead code, commented-out code, unused imports, or unused private members were introduced.
- [ ] No `TODO`, `FIXME`, placeholder logic, or temporary debug code was left behind.
- [ ] Code follows the existing style and idioms used in the surrounding Java/Spring Boot code.
- [ ] Complex logic is small enough to understand or is extracted into well-named methods/components.

### 2. Testing
- [ ] New or changed behavior is covered by unit tests at the appropriate level.
- [ ] Edge cases, null/empty inputs, invalid inputs, and failure paths are tested where relevant.
- [ ] Existing tests were updated when behavior or contracts changed.
- [ ] No tests were skipped, disabled, or weakened to make the build pass.
- [ ] Coverage is maintained for the touched area, with no unexplained regression.

### 3. Build Verification
- [ ] `./mvnw verify` passes locally for the final state of the branch.
- [ ] No new compiler, test, or plugin warnings were introduced without justification.
- [ ] Generated sources, formatting, and annotation-processor outputs are in the expected state.
- [ ] The PR is free of build-only breakage such as missing resources, bad imports, or broken dependency wiring.

### 4. Architecture Compliance [PROJECT-SPECIFIC]
- [ ] The change follows existing architectural and package patterns already used in the project.
- [ ] No new circular dependencies were introduced across packages, modules, or layers.
- [ ] Layer boundaries are respected (for example: controller -> service -> repository, not bypassed).
- [ ] New abstractions are necessary and fit the current design rather than adding accidental complexity.
- [ ] Dependency injection, transaction boundaries, and component responsibilities match existing project conventions.

### 5. Security
- [ ] No secrets, credentials, tokens, certificates, or sensitive sample data were added to code, tests, or config.
- [ ] Inputs from controllers, events, schedulers, and external integrations are validated appropriately.
- [ ] Authentication and authorization checks are present anywhere access rules apply.
- [ ] Logs, errors, and responses do not leak secrets, PII, stack traces, or internal implementation details.
- [ ] New dependencies, algorithms, or integrations do not introduce obvious security risks.

### 6. API Contract [PROJECT-SPECIFIC]
- [ ] DTO, request, response, and event contract changes are backward-compatible unless the change is explicitly intended to break compatibility.
- [ ] Validation annotations, serialization rules, enums, and default values are correct for the updated contract.
- [ ] API documentation, examples, and sample payloads were updated when contract changes were made.
- [ ] Consumers of the changed API/event contract were considered and verified.
- [ ] Versioning or migration notes were added when compatibility cannot be preserved.

### 7. Configuration [PROJECT-SPECIFIC]
- [ ] New configuration keys are externalized and not hardcoded in Java classes or tests.
- [ ] All required Spring profiles and environment-specific config files were updated consistently.
- [ ] Defaults are safe, documented, and appropriate for local and deployed environments.
- [ ] Feature flags, toggles, URLs, topic names, and timeouts follow project configuration conventions.
- [ ] Obsolete or conflicting configuration entries were not left behind.

### 8. Cross-cutting [PROJECT-SPECIFIC]
- [ ] Logging is sufficient for supportability without creating noise or exposing sensitive data.
- [ ] Metrics, tracing, health checks, or monitoring hooks were added or updated where operationally relevant.
- [ ] Error handling is consistent with the project's exception and response strategy.
- [ ] Retries, timeouts, circuit breakers, and fallback behavior were considered for external calls where relevant.
- [ ] The change remains observable and diagnosable in production.

### 9. Documentation [PROJECT-SPECIFIC]
- [ ] Feature documentation was refreshed to match the final implementation.
- [ ] `README` or module-level usage documentation was updated if developer-facing behavior changed.
- [ ] A `CHANGELOG` entry was added if the repository or release process requires one.
- [ ] Any required runbook, architecture, API, or operational documentation was updated.
- [ ] Examples, diagrams, or onboarding notes remain accurate after this change.

### 10. Git Hygiene [PROJECT-SPECIFIC]
- [ ] Commit message(s) follow the project's commit convention and clearly describe the change.
- [ ] Branch naming follows the repository convention.
- [ ] The PR contains no unrelated file changes, accidental formatting-only churn, or leftover merge artifacts.
- [ ] Generated files are included only when they are intentionally versioned.
- [ ] The diff is reviewable in size and logically grouped for reviewers.
