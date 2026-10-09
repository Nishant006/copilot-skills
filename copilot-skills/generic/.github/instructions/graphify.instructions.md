---
applyTo: "**"
---

# 🔒 Graphify-First Guardrail (NON-NEGOTIABLE — All Projects)

> **This is a MANDATORY enforcement rule, not a suggestion.** It applies to every project that has this file symlinked, every session, every Copilot context. The AI MUST follow this protocol — violations are treated as drift.

## Rule: Graphify Before Grep

**Before using grep, glob, find, rg, or any file-content search tool for architecture/navigation/relationship questions, you MUST first check for and use graphify.** This is a blocking requirement — not optional, not best-effort.

## ⚠️ Step 0 — Normalise the working directory FIRST (most common cause of false "no graph")

`graphify` resolves `graphify-out/graph.json` **relative to the current working
directory**, not to the repo root. Running it from any subdirectory fails with
`error: graph file not found: .../src/main/java/graphify-out/graph.json`, which looks
identical to "this repo has no graph". **It is not. The graph is there — you are in the
wrong directory.**

Never conclude "no graph found" from a bare `graphify query`. Always anchor first:

```bash
# ALWAYS do this before any graphify command
cd "$(git rev-parse --show-toplevel)" && graphify query "<Identifier>"
```

This works for normal clones **and** linked worktrees (`--show-toplevel` returns the
worktree root, which the builder gives its own graph).

If the directory is not inside a git repo at all (e.g. a stray IDE-created folder),
point graphify at a graph explicitly with the existing `GRAPHIFY_OUT` env var:

```bash
GRAPHIFY_OUT=/path/to/<repo>/graphify-out graphify query "<Identifier>"
```

Only after **both** of these fail may you treat the graph as genuinely missing.

## Enforcement Protocol (execute on EVERY relevant question)

```
Step 0 — ANCHOR: cd "$(git rev-parse --show-toplevel)" (see Step 0 section above).
         A "graph file not found" error from a subdirectory is NOT a missing graph.
Step 1 — DETECT GRAPH: Check if graphify-out/graph.json exists in the project root.
Step 2 — CHECK OVERRIDE: Is COPILOT_GRAPHIFY_ENABLED=0 set? If yes → skip graphify, use grep directly.
Step 3 — CLASSIFY QUESTION: Is this about architecture, relationships, navigation, or code structure?
Step 3b — CHECK SCOPE: Does the question span MORE THAN ONE service/repo?
          (e.g. "which services use X", "how does service A talk to service B")
Step 4 — CHECK STALENESS: If graph exists, is it older than 7 days? (find graphify-out/graph.json -mtime +7)
Step 5 — ROUTE:
  ├── CROSS-REPO question → use the GLOBAL graph: ~/.graphify/global-graph.json
  │     Nodes are tagged with `repo` and ids are namespaced `<repo>::<local_id>`.
  │     Edges with `_cross_link: true` mark shared contracts between services,
  │     tiered HIGH (events/topics/DTOs/clients) or MEDIUM (shared types).
  │     Then drop into the owning repo's per-repo graph for implementation detail.
  │
  ├── Graph EXISTS + fresh + Architecture question → MUST use graphify FIRST
  │     ├── graphify query "<question>"         → for "how does X work?", "where is X?"
  │     ├── graphify path "<A>" "<B>"           → for "how does A relate to B?"
  │     ├── graphify explain "<concept>"        → for "explain X", "what is X?"
  │     └── Read graphify-out/GRAPH_REPORT.md   → for broad architecture overview
  │
  ├── Graph EXISTS + STALE (>7 days) + Architecture question → STILL use graphify FIRST
  │     Warn: "⚠️ Knowledge graph is older than 7 days. Using it but results may be outdated."
  │     Then proceed with graphify query — stale data > no graph.
  │     Suggest: "Run `copilot-skills graphify rebuild` to refresh."
  │
  ├── Graph EXISTS + broad query returned mostly generic nodes → RETRY before falling back
  │     A vague question ("how does X work?") can surface low-value schema leaves
  │     (`payload`, `properties`, `type`). Re-query with the concrete identifier
  │     (e.g. `graphify query "BrazeEventTrackingService"`) or use `graphify explain`.
  │     Only fall back to grep if a TARGETED query also comes up short.
  │
  ├── Graph EXISTS + graphify returned insufficient results → THEN fall back to grep/glob/view
  │     (Document: "Graphify did not surface enough detail. Falling back to grep.")
  │
  ├── Graph MISSING + Architecture question → Suggest building graph first:
  │     "⚠️ No knowledge graph found. Build one with `copilot-skills graphify rebuild`
  │      (this repo) or `rebuild-all` (every repo + global). Falling back to grep for now."
  │     Then proceed with grep/glob/view.
  │
  ├── COPILOT_GRAPHIFY_ENABLED=0 → Use grep/glob/view directly (env opt-out respected)
  │
  └── NOT an architecture/navigation question → Use grep/glob/view directly
        (e.g., specific code edits, test runs, build commands, known file paths)
```

## Two-layer graph model

| Layer | Path | Scope |
|---|---|---|
| Per repo | `<repo>/graphify-out/graph.json` | One service, full detail (AST + semantic) |
| Global | `~/.graphify/global-graph.json` | All services, repo-tagged + cross-repo edges |

A per-repo graph must contain **only its own repo**. If a query from repo A returns
files belonging to repo B, the graph is contaminated — rebuild with
`copilot-skills graphify rebuild-all`.

> ⛔ Never symlink several repos at one shared `graphify-out`. `graphify update` merges
> into whatever graph it finds, and AST nodes carry only a relative path with no repo
> attribute, so a shared directory silently mixes every service together. Cross-repo
> knowledge belongs in the global graph, which re-tags nodes per repo on the way in.

### Cross-repo lookup recipe

Use this whenever a question involves a **shared contract** — a DTO, event payload,
Kafka topic, Service Bus queue, REST path, header name, or enum value that more than
one service touches. The per-repo graph physically cannot see those consumers, so
relying on it alone produces a falsely narrow answer.

```bash
python3 - "SymbolName" <<'PY'
import json, os, sys
term = sys.argv[1].lower()
path = os.path.expanduser("~/.graphify/global-graph.json")
if not os.path.exists(path):
    sys.exit("global graph missing — run ./setup.sh (cross-repo impact UNVERIFIED)")
g = json.load(open(path))
byid = {n["id"]: n for n in g["nodes"]}
hits = [n for n in g["nodes"] if term in (n.get("label") or "").lower()]
repos = {}
for n in hits:
    repos.setdefault(n.get("repo", "?"), []).append(n["label"])
print(f"'{sys.argv[1]}' appears in {len(repos)} repo(s):")
for r, v in sorted(repos.items()):
    print(f"  {r}: {len(v)} node(s) — e.g. {v[:3]}")
ids = {n["id"] for n in hits}
x = [e for e in g.get("links", [])
     if e.get("_cross_link") and (e["source"] in ids or e["target"] in ids)]
print(f"cross-repo edges touching it: {len(x)}")
for e in x[:10]:
    s, d = byid.get(e["source"], {}), byid.get(e["target"], {})
    print(f"  {s.get('repo')}:{s.get('label')} -> {d.get('repo')}:{d.get('label')}")
PY
```

Rules:
* More than one repo in the output ⇒ the answer **must** name every affected service.
* Global graph missing ⇒ say so and mark cross-repo impact **unverified**. Never
  report it as zero.
* Always return to the owning repo's graph for line-level detail; the global layer is
  for *who is involved*, not *how it works*.


## Query Phrasing — the single most common failure

Graphify seeds its traversal from ~2-3 tokens in your query. A long prose sentence
donates its most generic words as seeds and lands you in schema/doc noise instead of
source code.

| ❌ Vague (fails) | ✅ Targeted (works) |
|---|---|
| `"Alecto out of stock substitution flow: which classes send the WhatsApp message"` | `"AlectoClient"` |
| `"How does Braze event tracking work?"` | `"BrazeEventTrackingService"` |

**Always query the concrete identifier first** — class, method, topic, or config key.
Use prose only after an identifier query has already given you an anchor.

A vague query that returns only generic or `.ai/` doc nodes is **not** grounds to fall
back to grep — retry with the concrete identifier first. Falling back after only a
vague query is a protocol violation (see Fallback Conditions below).


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

## Branch switches and uncommitted work

Each repo has these local git hooks (they live in `.git/hooks`, so they are never
committed or pushed). `rebuild-all` installs them:

| Hook | Fires on | Effect |
|---|---|---|
| `post-commit` | every commit | incremental AST rebuild of changed files |
| `post-checkout` | real branch switch only | full background AST rebuild, 600s cap, logs to `~/.cache/graphify-rebuild.log` |
| `post-merge` | `git merge` / `git pull` | symlink to `post-commit` |
| `post-rewrite` | `git rebase`, `git commit --amend` | symlink to `post-commit` |

The last two are symlinks because graphify ships only the first two, and git never
fires `post-commit` for a merge commit — without them every `git pull` left the
graph stale.

Three limits still apply:

1. **Hooks are AST-only.** They never call an LLM, so new `.ai/` docs, rationale and
   config knowledge are *not* picked up. Run `/graphify .` for those.
2. **Uncommitted work is invisible.** Code written but not yet committed is in no
   graph. If a query about code you just wrote returns nothing, that is expected —
   commit, or run `graphify update .`, before trusting the answer.
3. **The graph is not branch-aware.** There is one graph per directory, stamped with
   `built_at_commit`. Switching branches rewrites it in place.

> If an AST-only rebuild would produce fewer nodes than the stored graph, graphify
> refuses to overwrite it (`Refusing to overwrite`). That guard is deliberate: it
> stops a code-only rebuild from wiping LLM-extracted semantic nodes. Do **not**
> force past it in a hook. `rebuild-all` is the correct fix — it re-attaches the
> semantic layer from `~/.graphify/semantic-backup/` after every update.


## Fallback Conditions (ONLY these justify skipping graphify)

1. `graphify-out/graph.json` does not exist **after anchoring to the repo root**
   (`cd "$(git rev-parse --show-toplevel)"`) → warn user, fall back to grep.
   A `graph file not found` error raised from a subdirectory does **not** satisfy this
   condition — re-run from the repo root first. Falling back on an un-anchored error
   is a protocol violation.
2. A **targeted** `graphify query`/`explain` on the concrete identifier returned no
   relevant results → document failure, fall back.
   A broad, vaguely-worded query returning generic nodes is **not** sufficient grounds:
   retry with the specific class/method/topic name first. Falling back after only a
   vague query is a protocol violation.
3. Graph is stale (> 7 days old) → warn user, use graph anyway but note staleness
4. Question is purely about file content (not structure) → grep directly
5. User explicitly said "don't use graphify" or "just grep" → respect override
6. `COPILOT_GRAPHIFY_ENABLED=0` is set in environment → respect env opt-out, use grep directly

**Any other reason for skipping graphify is a protocol violation.**

## Anti-Drift: Self-Check Before Any Search

Before issuing grep/glob/rg/find for a code navigation question, the AI MUST pause and verify:
```
□ Did I `cd "$(git rev-parse --show-toplevel)"` before running graphify?
□ Did I check if graphify-out/graph.json exists?
□ Did I try graphify query/path/explain first?
□ Was my query TARGETED (a concrete identifier), not just a vague sentence?
□ Is this a cross-repo question? If so, did I check ~/.graphify/global-graph.json?
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
