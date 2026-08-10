# 🧠 Copilot Skills — Shared AI Workflow Engine

A centralized, portable skill system for GitHub Copilot CLI that works across **any** project. One setup, all projects get AI-powered development workflows (spec → plan → implement → test → PR).

---

## ⚡ Quick Start (One Command)

```bash
# 1. Clone/pull the branch containing this folder
git clone <repo-url> -b <skills-branch> /path/to/your-projects/.copilot-skills

# 2. Run setup (one time)
cd /path/to/your-projects/.copilot-skills
./setup.sh && source ~/.zshrc

# 3. Done! Skills are auto-linked to all sibling projects.
#    To check status anytime:
copilot-skills
```

That's it. You now have 18+ AI skills available in your projects via any Copilot interface (CLI, VS Code, IntelliJ).

**One command to rule them all:** `copilot-skills` — it auto-detects context and does the right thing.

---

## 📋 Prerequisites

| # | Tool | Check | Install |
|---|---|---|---|
| 1 | Git | `git --version` | [git-scm.com](https://git-scm.com) |
| 2 | GitHub CLI | `gh --version` | `brew install gh` |
| 3 | Copilot (any one) | See below | See below |
| 4 | Node.js (optional) | `node --version` | `brew install node` (for api-tester) |

**Copilot access** (any ONE is sufficient):
- **Copilot CLI** (terminal): `brew install copilot-cli`
- **VS Code**: Install "GitHub Copilot" extension
- **IntelliJ/JetBrains**: Install "GitHub Copilot" plugin

> 💡 Run `copilot-skills` in any project — it checks everything and auto-fixes issues.

---

## 📁 Folder Structure

```
.copilot-skills/
├── setup.sh                  ← One-command installer (run this first)
├── link-skills.sh            ← Core linker (auto-sourced by shell functions)
├── README.md                 ← You are here
├── .gitignore                ← Ignores secrets, node_modules, reports
├── generic/                  ← Shared skills (work in ANY project)
│   ├── AGENTS.md             ← Workflow engine (phases, routing, protocol)
│   ├── AI-WORKFLOW.md        ← Team quick-start guide
│   └── .github/
│       ├── skills/           ← 17 skill definitions (SKILL.md each)
│       └── instructions/     ← Auto-loaded Copilot instructions
├── projects/                 ← Project-specific overlays
│   ├── communication-dispatcher/
│   │   ├── .github/copilot-instructions.md
│   │   ├── .github/skills/api-tester/
│   │   ├── .github/skills/setup-check/  ← project-specific setup overlay
│   │   ├── .github/instructions/
│   │   └── AGENTS-overlay.md
│   └── communication-service/
│       ├── .github/copilot-instructions.md
│       ├── .github/skills/implement-and-test/
│       └── AGENTS-overlay.md
└── link-skills.sh            ← Symlinks generic + project skills into target repos
```

---

## 🔧 Available Commands

After running `./setup.sh`, these commands are available in any terminal:

| Command | Description |
|---|---|
| **`copilot-skills`** | **THE one command** — smart mode, auto-detects what to do |
| `copilot-skills sync` | Pull latest from remote + re-link all projects |
| `copilot-skills check` | Check if skills are up to date |
| `copilot-skills link` | Link skills into current project |
| `copilot-skills update` | Re-link + verify |
| `copilot-skills setup` | Full re-install (safe to repeat anytime) |
| `copilot-skills --all` | Apply to all sibling projects |
| `copilot-skills edit [name]` | Open skills source for editing |
| `copilot-skills new <name>` | Create a new project overlay |
| `copilot-skills graphify` | Knowledge graph management |

> 💡 **Just remember `copilot-skills`**. It has tab completion. Run it without arguments and it figures out what to do.

Legacy commands still work: `copilot-link-skills`, `copilot-check-skills`, `copilot-update-skills`, `copilot-sync-skills`.

---

## 🔗 How It Works

1. **Generic skills** (`generic/`) contain workflow logic that works in any Java/Spring Boot project (spec-writer, impl-planner, implement-and-test, etc.)
2. **Project overlays** (`projects/<name>/`) add project-specific context (architecture knowledge, custom skills like api-tester, coding standards)
3. **`copilot-skills`** (or `copilot-link-skills`) merges generic + overlay via symlinks into your project's `.github/` directory
4. Copilot (CLI, VS Code, or IntelliJ) auto-loads `.github/skills/`, `.github/instructions/`, and `AGENTS.md` — giving you the full AI workflow

### Linking Strategy

```
Your project/.github/skills/blast-radius/ → symlink → .copilot-skills/generic/.github/skills/blast-radius/
Your project/.github/skills/api-tester/   → symlink → .copilot-skills/projects/dispatcher/.github/skills/api-tester/
Your project/AGENTS.md                    → generated (base + overlay merged)
```

- Skills tracked in git (e.g., from a dedicated branch) are **never overwritten**
- Running `copilot-link-skills` is safe and idempotent

---

## ➕ Adding Your Own Project

```bash
# Create overlay structure
copilot-new-project my-service

# This creates:
# .copilot-skills/projects/my-service/
#   ├── .github/
#   │   ├── copilot-instructions.md   ← Your architecture docs
#   │   ├── skills/                    ← Project-only skills
#   │   └── instructions/              ← Custom Copilot instructions
#   ├── AGENTS-overlay.md              ← Additions to AGENTS.md
#   └── AI-WORKFLOW-overlay.md         ← Additions to AI-WORKFLOW.md
```

Then populate:
- `.github/copilot-instructions.md` — architecture, patterns, coding standards for YOUR project
- `.github/skills/<skill>/SKILL.md` — any project-specific skill definitions
- `AGENTS-overlay.md` — project-specific additions to the workflow engine

---

## 🔀 Available Skills (18 generic + project-specific)

| Skill | Purpose | Type |
|---|---|---|
| `spec-writer` | Create structured feature specs | Phase 1 |
| `lifecycle-flow` | Cross-service flow diagrams | Phase 2 |
| `impl-planner` | Implementation plan with blast-radius | Phase 3 |
| `implement-and-test` | Code + test execution | Phase 4 |
| `pr-preparation` | Commit + PR creation | Phase 5 |
| `code-reviewer` | Multi-phase PR review | Phase 6 |
| `blast-radius` | Impact analysis (sub-agent) | Sub-agent |
| `code-explorer` | Code navigation (sub-agent) | Sub-agent |
| `architecture-diagrammer` | Mermaid diagrams from source | Standalone |
| `bug-tracer` | Root cause analysis | Fast-track |
| `safe-refactor` | Zero-behavior-change refactoring | Fast-track |
| `onboarding` | New developer guide + KT docs | Standalone |
| `idea-to-spec` | Rough idea → brief.md | Pre-Phase 1 |
| `party-mode` | Multi-persona architectural debate | Standalone |
| `workflow-help` | Router for ambiguous requests | Standalone |
| `setup-check` | Verify prerequisites | Standalone |
| `api-tester` | API testing with drift detection | Project-specific |

Usage in Copilot CLI:
```
"use the spec-writer skill for JIRA-123"
"use the bug-tracer skill — login returns 500"
"use the code-explorer skill"
"help"
```

---

## ⚙️ Configuration (Optional)

### Environment Variables

| Variable | Purpose | Default |
|---|---|---|
| `COPILOT_SKILLS_ROOT` | Override skills location | Auto-detected from setup.sh |
| `COPILOT_GRAPHIFY_PATH` | Custom graphify-out location | Auto-detected (parent dir or sibling) |

### Graphify Integration

If you use [graphify](https://github.com/nicosalm/graphify) for codebase knowledge graphs:
- Place `graphify-out/` as a sibling to `.copilot-skills/` (same parent directory)
- Or set `COPILOT_GRAPHIFY_PATH=/path/to/graphify-out`
- `copilot-link-skills` will auto-link it into each project

---

## 🔄 Updating Skills

When new skills or updates are pushed to the branch:

```bash
# Pull latest
cd /path/to/.copilot-skills
git pull

# Re-link in each project (or use --all future enhancement)
cd ~/YourProjects/my-service
copilot-link-skills
```

---

## 🗑️ Uninstall

```bash
cd /path/to/.copilot-skills
./setup.sh --uninstall
exec $SHELL
```

This removes shell functions from `~/.zshrc` and `~/.bashrc`. Symlinks in projects remain until manually deleted.

---

## 🤝 Contributing

1. Generic skills go in `generic/.github/skills/<skill-name>/SKILL.md`
2. Project-specific additions go in `projects/<project-name>/`
3. After modifying skills, run `copilot-link-skills` in affected projects to update symlinks
4. See `generic/AGENTS.md` §Adding a New Skill — Recipe for the full checklist

---

## ❓ Troubleshooting

| Issue | Fix |
|---|---|
| `copilot-link-skills: command not found` | Run `./setup.sh` again, then `exec $SHELL` |
| `❌ Not a git repo` | Run `copilot-link-skills` from your project root (where `.git/` is) |
| Skills not loading in Copilot | Check symlinks: `ls -la .github/skills/` |
| Stale skills after update | Run `copilot-update-skills` |
| Wrong project detected | Specify explicitly: `copilot-link-skills my-project-name` |
