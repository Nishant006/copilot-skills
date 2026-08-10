---

> **[PROJECT-SPECIFIC]** — Replace this file when porting to another repository.
Status: DRAFT
Jira: COM-XXX
Created: [date]
---

# Feature Spec: [Title]

## 1. Summary
[One paragraph describing the feature]

## 2. Event Identification
- Event name: [MUST exist in or be added to Constants.CommunicationEvent]
- Channels: [push / email / SMS / WhatsApp — which ones]
- Sites: [site codes from supported-sites-events YAML]

## 3. Business Rules
[Numbered list of business rules / conditions]

## 4. Acceptance Criteria
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]

## 5. Out of Scope
[Explicitly list what this feature does NOT include]

## 6. Dependencies
[External services, config changes, other teams needed]

## 7. Lifecycle Impact
- Cross-cutting: [Yes/No — if Yes, lifecycle-flow phase should be triggered]
- Reason: [Why this affects multiple components, or "Single component change"]

## 8. Non-Functional Requirements
- **Performance SLA**: [Expected processing time per notification, e.g., <500ms for push, <2s for SMS]
- **Error rate tolerance**: [Acceptable failure rate, e.g., <1% for push, <5% for SMS vendor]
- **Retry behavior**: [Should failed notifications retry? How many times? Backoff strategy?]
- **Monitoring**: [What COMMS_ log events should ops monitor? Any new alert thresholds?]
- **Scalability**: [Expected volume — messages/minute? Burst capacity needed?]
