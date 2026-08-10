---
applyTo: "**"
---

# 🔒 Graphify-First Guardrail (NON-NEGOTIABLE — All Projects)

> **This is a MANDATORY enforcement rule, not a suggestion.** It applies to every project that has this file symlinked, every session, every Copilot context. The AI MUST follow this protocol — violations are treated as drift.

## Rule: Graphify Before Grep

**Before using grep, glob, find, rg, or any file-content search tool for architecture/navigation/relationship questions, you MUST first check for and use graphify.** This is a blocking requirement — not optional, not best-effort.

## Enforcement Protocol (execute on EVERY relevant question)

```
Step 1 — DETECT GRAPH: Check if graphify-out/graph.json exists in the project root.
Step 2 — CHECK OVERRIDE: Is COPILOT_GRAPHIFY_ENABLED=0 set? If yes → skip graphify, use grep directly.
Step 3 — CLASSIFY QUESTION: Is this about architecture, relationships, navigation, or code structure?
Step 4 — CHECK STALENESS: If graph exists, is it older than 7 days? (find graphify-out/graph.json -mtime +7)
Step 5 — ROUTE:
  ├── Graph EXISTS + fresh + Architecture question → MUST use graphify FIRST
  │     ├── graphify query "<question>"         → for "how does X work?", "where is X?"
  │     ├── graphify path "<A>" "<B>"           → for "how does A relate to B?"
  │     ├── graphify explain "<concept>"        → for "explain X", "what is X?"
  │     └── Read graphify-out/GRAPH_REPORT.md   → for broad architecture overview
  │
  ├── Graph EXISTS + STALE (>7 days) + Architecture question → STILL use graphify FIRST
  │     Warn: "⚠️ Knowledge graph is older than 7 days. Using it but results may be outdated."
  │     Then proceed with graphify query — stale data > no graph.
  │     Suggest: "Run `graphify . --update` to refresh."
  │
  ├── Graph EXISTS + graphify returned insufficient results → THEN fall back to grep/glob/view
  │     (Document: "Graphify did not surface enough detail. Falling back to grep.")
  │
  ├── Graph MISSING + Architecture question → Suggest building graph first:
  │     "⚠️ No knowledge graph found. Build one with `graphify .` (CLI) or `/graphify` (Copilot Chat).
  │      Falling back to grep/glob for now."
  │     Then proceed with grep/glob/view.
  │
  ├── COPILOT_GRAPHIFY_ENABLED=0 → Use grep/glob/view directly (env opt-out respected)
  │
  └── NOT an architecture/navigation question → Use grep/glob/view directly
        (e.g., specific code edits, test runs, build commands, known file paths)
```

## What Counts as an Architecture/Navigation Question (USE GRAPHIFY)

- "How does X work?"
- "Where is X defined/used?"
- "What calls X?" / "What depends on X?"
- "How does A relate to B?"
- "Explain the architecture"
- "Add/modify a <component>" (need to understand existing structure first)
- "What does this module/class/service do?"
- "Trace the flow from X to Y"
- "What would break if I change X?" (blast-radius-like queries)
- Any question about file relationships, class hierarchies, or cross-module dependencies

## What Does NOT Need Graphify (direct grep/glob/view is fine)

- Searching for a specific string/symbol you need to edit
- Reading a file at a known path
- Running builds, tests, lints
- Making targeted code edits
- Finding a file by name (glob)
- Checking git status/logs

## Available Commands

| Command | Use when |
|---|---|
| `graphify query "<question>"` | Any architecture/navigation question |
| `graphify path "<A>" "<B>"` | Finding how two concepts connect |
| `graphify explain "<concept>"` | Understanding a specific component |
| `graphify export callflow-html` | Generating Mermaid call-flow diagrams |

## Freshness Check (integrated into decision tree above)

The staleness check is part of Step 4 in the enforcement protocol above. No separate action needed — the AI checks graph age as part of the routing flow. Stale graphs are still used (with a warning); they are never silently skipped.

## Fallback Conditions (ONLY these justify skipping graphify)

1. `graphify-out/graph.json` does not exist → warn user, fall back to grep
2. `graphify query` returned no relevant results → document failure, fall back
3. Graph is stale (> 7 days old) → warn user, use graph anyway but note staleness
4. Question is purely about file content (not structure) → grep directly
5. User explicitly said "don't use graphify" or "just grep" → respect override
6. `COPILOT_GRAPHIFY_ENABLED=0` is set in environment → respect env opt-out, use grep directly

**Any other reason for skipping graphify is a protocol violation.**

## Anti-Drift: Self-Check Before Any Search

Before issuing grep/glob/rg/find for a code navigation question, the AI MUST pause and verify:
```
□ Did I check if graphify-out/graph.json exists?
□ Did I try graphify query/path/explain first?
□ If I'm skipping graphify, do I have a valid reason from the Fallback Conditions list?
□ If graphify is unavailable, did I inform the user?
```

If ANY answer is "no" → STOP, go back, and use graphify first.

## Graph Not Found — One-Time Suggestion (per session)

The first time graphify-out/graph.json is missing in a session, say:
> "💡 No knowledge graph found for this project. Build one with `graphify .` (CLI) or `/graphify` (Copilot Chat) — it makes architecture questions 5-10x faster and more accurate."

Say this ONCE per session. Then proceed with grep/glob fallback.

## Configuration

Graphify is controlled by the `COPILOT_GRAPHIFY_ENABLED` environment variable:
- `1` (default if graphify is installed) — graphify-first behavior active
- `0` — skip graphify, use grep/view directly (user explicitly opted out)

## What Graphify Provides

- **God nodes** — the most-connected concepts (entry points, shared services)
- **Surprising connections** — links between things in different modules
- **Confidence tags** — `EXTRACTED`, `INFERRED`, or `AMBIGUOUS` on every relationship
- **Cross-file relationships** — class hierarchies, method calls, event flows, config dependencies
- **Suggested questions** — what the graph is best positioned to answer

## Integration with Skills (MANDATORY — not optional)

| Skill | How it MUST use graphify |
|---|---|
| `code-explorer` | `graphify query` BEFORE grep for navigation questions |
| `blast-radius` | `graphify path` to find all callers/dependents BEFORE grep |
| `onboarding` | `graphify explain` for component overviews BEFORE reading files |
| `feature-docs` | `graphify query` to verify architecture references |
| `bug-tracer` | `graphify path` to trace call chains BEFORE manual grep |
| `architecture-diagrammer` | `graphify export callflow-html` for accurate diagrams |
| `spec-writer` | `graphify query` to understand existing patterns before speccing |
| `impl-planner` | `graphify path` to identify all affected components |
| `implement-and-test` | `graphify query`/`path` to verify class references (Step 2) and understand dependencies before modifying code |

> Skills that skip graphify when the graph exists are in violation of this guardrail.

## Wiki (if available)

If `graphify-out/wiki/index.md` exists, use it for broad navigation before diving into specific
queries. The wiki provides a structured overview of all major concepts.

## GRAPH_REPORT.md

Read `graphify-out/GRAPH_REPORT.md` only for:
- Broad architecture review (first-time onboarding)
- When query/path/explain do not surface enough context
- Understanding god nodes and surprising connections

Do NOT read the full report for every question — it's expensive on context. Prefer scoped queries.
