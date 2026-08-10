# Blast Radius Report Template

> **[PROJECT-SPECIFIC]** — Replace this file when porting to another repository.

Use this template for the output of every blast-radius analysis.

```markdown
---
Target: [ClassName.methodName() or FieldName]
Analyzed: [date]
Method: [IntelliJ Find Usages / CLI grep / both]
---

## Blast Radius Report: [Target]

### Direct Callers (d=1) — WILL BREAK
| File | Line | Usage |
|---|---|---|
| | | |

### Spring DI Wiring
| File | Injection Type |
|---|---|
| | |

### DTO Field Propagation
| File | Field Access |
|---|---|
| | |

### Message Flow Impact
- Kafka topics affected: [none / list]
- ServiceBus queues affected: [none / list]
- Cross-service impact: [none / describe]

### Risk Assessment
- Direct callers: [count]
- DI references: [count]
- Core pipeline component: [Yes/No]
- **Risk Level: [LOW / MEDIUM / HIGH / CRITICAL]**

### ⚠️ grep Limitations for This Target
[Specific things grep cannot detect for this particular class/method]

### Recommendations
1. [What to test after making the change]
2. [Which files need manual review]
3. [Whether IntelliJ verification is recommended]

### ⚠️ Dynamic Dispatch Risk

The following patterns in this codebase WILL NOT be detected by grep:

| Pattern | Example | Why grep misses it |
|---------|---------|-------------------|
| Spring Map injection | `Map<String, EventProcessor>` | Callers use the Map, not the class name |
| Factory selection | `SmsClientFactory.getClient(storeId)` | Vendor selected at runtime from YAML config |
| AOP proxy | `@LogExecutionTime`, `@CircuitBreaker` | Proxy wraps the bean; callers call the proxy |
| Reflection | Any Spring `@Autowired` by type | Bean resolved by interface, not concrete class |
| Lambda capture | `CompletableFuture.thenApply(x -> service.method())` | Grep may miss the lambda capture |

**Action**: For any target with 0 grep results, check these patterns before declaring "no impact".

### Confidence Level

Every blast-radius report MUST declare:
- `grep confidence: HIGH` — all callers are direct, no dynamic dispatch involved
- `grep confidence: MEDIUM` — some callers may use dynamic dispatch (factory/map/AOP)
- `grep confidence: LOW` — target is primarily accessed via dynamic dispatch; grep results are partial

When confidence is MEDIUM or LOW, recommend IDE Find Usages for authoritative results.

### Cross-Module Consideration

If the project becomes multi-module:
- grep must search ALL modules, not just the current module
- Check shared DTOs and interfaces in common/api modules
- Kafka message schemas are cross-service contracts — changes affect ALL consumers
- Azure Service Bus message formats are shared contracts
```
