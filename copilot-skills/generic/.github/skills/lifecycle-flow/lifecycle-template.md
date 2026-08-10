---

> **[PROJECT-SPECIFIC]** — Replace this file when porting to another repository.
Jira: COM-XXX
Spec: features/<ticket-id>/spec.md
Created: [date]
---

# Lifecycle Flow: [Title]

## Trigger
[What event starts this flow]

## Sequence Diagram
```mermaid
sequenceDiagram
    participant K as Kafka
    participant MC as MessageProcessor
    participant EP as EventProcessor
    participant NS as NotificationServiceV2
    participant CH as [Channel]
```

## Components Touched
| Component | Role in Flow | Impact |
|---|---|---|

## Cross-Service Dependencies
[Other services affected, Kafka schemas shared, etc.]
