#!/usr/bin/env bash
#
# graphify_build_all.sh — build/refresh the two-layer knowledge graph.
#
#   Layer 1 (per repo):  <repo>/graphify-out/graph.json
#   Layer 2 (global):    ~/.graphify/global-graph.json
#
# Layer 1 is the detail layer: every node of a single repo, no foreign code.
# Layer 2 is the domain layer: every repo's nodes re-tagged with `repo` and
# id-namespaced as `<repo>::<local_id>`, plus cross-repo edges that show how
# the services integrate.
#
# This script is UPDATE-ONLY and safe to re-run:
#   * `graphify update .`      merges into the existing per-repo graph and
#                              preserves semantic (LLM-extracted) nodes.
#   * `graphify global add`    replaces only that repo's slice of the global
#                              graph (+N / -M pruned), leaving other repos.
#   * graphify_cross_link.py   strips its own previous edges before re-adding.
#
# It never creates a shared `graphify-out` symlink. That pattern makes several
# repos write into one mutable directory, which silently cross-contaminates
# every graph; this script actively detects and repairs it.
#
# Usage:
#   graphify_build_all.sh [--root <dir>] [--policy high|high_medium|all]
#                         [--no-hooks] [--no-global] [--repo <name>]...
#
set -uo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -P "$SCRIPT_DIR/../.." && pwd)"
POLICY="high_medium"
INSTALL_HOOKS=1
DO_GLOBAL=1
ONLY_REPOS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --root)      ROOT="$(cd -P "$2" && pwd)"; shift 2 ;;
    --policy)    POLICY="$2"; shift 2 ;;
    --repo)      ONLY_REPOS+=("$2"); shift 2 ;;
    --no-hooks)  INSTALL_HOOKS=0; shift ;;
    --no-global) DO_GLOBAL=0; shift ;;
    -h|--help)   sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! command -v graphify >/dev/null 2>&1; then
  echo "❌ graphify not installed. Install: uv tool install graphifyy" >&2
  exit 1
fi

# Resolve the interpreter graphify itself runs under, so the cross-linker
# imports the same networkx/graphify build.
GRAPHIFY_PY="$(head -1 "$(command -v graphify)" | tr -d '#!')"
case "$GRAPHIFY_PY" in
  *[!a-zA-Z0-9/_.-]*) GRAPHIFY_PY="python3" ;;
  "")                 GRAPHIFY_PY="python3" ;;
esac
"$GRAPHIFY_PY" -c "import graphify" 2>/dev/null || GRAPHIFY_PY="python3"

echo "🧠 Two-layer graph build"
echo "   root:   $ROOT"
echo "   policy: $POLICY"
echo ""

wanted() {
  [ ${#ONLY_REPOS[@]} -eq 0 ] && return 0
  local name="$1" r
  for r in "${ONLY_REPOS[@]}"; do [ "$r" = "$name" ] && return 0; done
  return 1
}

BUILT=()
FAILED=()
NO_SEMANTIC=()
# Linked worktrees get their own per-repo graph but are deliberately kept out
# of the global layer: their content duplicates the parent repo and would show
# up as a phantom fifth service with hundreds of false "cross-repo" links.
WORKTREES=()

for dir in "$ROOT"/*/; do
  dir="${dir%/}"
  name="$(basename "$dir")"

  # `.git` is a directory in a normal clone and a file in a linked worktree.
  [ -e "$dir/.git" ] || continue
  wanted "$name" || continue

  # Repair the shared-symlink anti-pattern before it can contaminate anything.
  if [ -L "$dir/graphify-out" ]; then
    echo "  ⚠️  $name: graphify-out is a symlink to $(readlink "$dir/graphify-out")"
    echo "      removing it — each repo must own a real graphify-out directory"
    rm -f "$dir/graphify-out"
  fi

  echo "  📦 $name"
  if [ -f "$dir/.git" ]; then
    echo "      ↪ linked worktree — per-repo graph only, excluded from global"
    WORKTREES+=("$name")
  fi
  # `graphify update` merges into the existing graph and, unlike the hooks'
  # AST-only rebuild, is paired with the semantic restore below — so a branch
  # that legitimately removes code shrinks the graph here without tripping
  # graphify's "refusing to overwrite" guard. That guard exists to stop an
  # AST-only rebuild silently wiping LLM-extracted nodes; it is left intact.
  if (cd "$dir" && graphify update . >/dev/null 2>&1); then
    # graphify's cache lives inside graphify-out, so a from-scratch rebuild
    # comes back AST-only. Re-attach the semantic layer from the mirror.
    if [ -f "$SCRIPT_DIR/graphify_semantic_backup.py" ]; then
      "$GRAPHIFY_PY" "$SCRIPT_DIR/graphify_semantic_backup.py" restore "$dir" \
        2>/dev/null | sed 's/^/      ♻️  /'
    fi
    nodes="$("$GRAPHIFY_PY" -c "
import json
try:
    g=json.load(open('$dir/graphify-out/graph.json'))
    n=g['nodes']
    # AST-extracted nodes carry '_origin'; LLM/semantic nodes do not.
    sem=sum(1 for x in n if '_origin' not in x)
    print(f'{len(n)} nodes ({len(n)-sem} AST + {sem} semantic)')
except Exception:
    print('unreadable')
" 2>/dev/null)"
    echo "      ✅ $nodes"
    # An AST-only graph still answers 'what calls what', but has no concept,
    # rationale or config knowledge, so prose queries fall flat. Say so, because
    # 'AST + 0 semantic' is easy to read as success.
    case "$nodes" in
      *"+ 0 semantic"*)
        echo "      ⚠️  no semantic layer — architecture/rationale queries will be thin."
        echo "         Fix: run /graphify . in this repo once to extract it."
        NO_SEMANTIC+=("$name")
        ;;
    esac
    BUILT+=("$name")
    # Mirror the semantic layer outside graphify-out so it survives a wipe.
    if [ -f "$SCRIPT_DIR/graphify_semantic_backup.py" ]; then
      "$GRAPHIFY_PY" "$SCRIPT_DIR/graphify_semantic_backup.py" save "$dir" \
        >/dev/null 2>&1 || true
    fi
  else
    echo "      ⚠️  build failed — keeping previous graph"
    FAILED+=("$name")
    continue
  fi

  if [ "$INSTALL_HOOKS" = "1" ]; then
    # Hooks live in .git/hooks, which git never commits or pushes.
    (cd "$dir" && graphify hook install >/dev/null 2>&1) \
      && echo "      🔗 git hook installed (local only)" || true

    # graphify ships only post-commit and post-checkout. git never fires
    # post-commit for a merge commit, and post-checkout skips while a merge or
    # rebase is in progress — so `git pull`, `git merge` and `git rebase` all
    # leave the graph stale. post-commit takes no positional arguments and its
    # MERGE_HEAD/rebase guards are already clear by the time these two fire,
    # so pointing them at it reuses graphify's hook as-is.
    hooks_dir="$(cd "$dir" && git rev-parse --git-path hooks 2>/dev/null)"
    case "$hooks_dir" in ""|/*) ;; *) hooks_dir="$dir/$hooks_dir" ;; esac
    if [ -n "$hooks_dir" ] && [ -f "$hooks_dir/post-commit" ]; then
      # post-merge: a fast-forward `git pull` advances HEAD by many commits at
      # once, but post-commit only re-extracts HEAD~1..HEAD, so every commit but
      # the last would be missed (verified: a 3-commit pull imported 1 of 3
      # classes). post-checkout re-extracts the whole corpus, so delegate there;
      # its third argument is the "this was a branch switch" flag.
      if [ ! -e "$hooks_dir/post-merge" ] || [ -L "$hooks_dir/post-merge" ] \
         || grep -q 'graphify-merge-shim' "$hooks_dir/post-merge" 2>/dev/null; then
        rm -f "$hooks_dir/post-merge"
        cat > "$hooks_dir/post-merge" <<'SHIM'
#!/bin/sh
# graphify-merge-shim — installed by copilot-skills/tools/graphify_build_all.sh
# post-commit re-extracts only HEAD~1..HEAD, which loses all but the last commit
# of a fast-forward pull. post-checkout re-extracts everything, so use it.
exec "$(dirname "$0")/post-checkout" "" "" 1
SHIM
        chmod +x "$hooks_dir/post-merge"
        echo "      🔗 post-merge → post-checkout (full re-extract)"
      fi
      # post-rewrite: incremental is correct for `commit --amend` (one commit
      # changed), and post-commit's own rebase guard makes it a deliberate
      # no-op mid-rebase — a rebuild there can dirty the tree and break
      # `git rebase --continue` in repos that track graphify-out.
      if [ ! -e "$hooks_dir/post-rewrite" ] || [ -L "$hooks_dir/post-rewrite" ]; then
        ln -sfn post-commit "$hooks_dir/post-rewrite" \
          && echo "      🔗 post-rewrite → post-commit" || true
      fi
    fi
  fi
done

if [ ${#BUILT[@]} -eq 0 ]; then
  echo ""
  echo "❌ No repositories built. Nothing to aggregate."
  exit 1
fi

if [ "$DO_GLOBAL" = "1" ]; then
  echo ""
  echo "🌍 Global domain graph"
  for name in "${BUILT[@]}"; do
    skip=0
    for w in "${WORKTREES[@]:-}"; do [ "$w" = "$name" ] && skip=1; done
    [ "$skip" = "1" ] && continue
    graph="$ROOT/$name/graphify-out/graph.json"
    [ -f "$graph" ] || continue
    # Idempotent: re-adding a tag replaces that repo's slice only.
    out="$(graphify global add "$graph" --as "$name" 2>&1 | tail -1)"
    echo "   $name: $out"
  done

  if [ -f "$SCRIPT_DIR/graphify_cross_link.py" ]; then
    echo ""
    echo "🔗 Cross-repo links"
    "$GRAPHIFY_PY" "$SCRIPT_DIR/graphify_cross_link.py" --policy "$POLICY" 2>&1 | sed 's/^/   /'
  fi
fi

echo ""
echo "✅ Done. ${#BUILT[@]} repo graph(s) updated."
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "⚠️  Failed (previous graphs left intact): ${FAILED[*]}"
fi
if [ ${#NO_SEMANTIC[@]} -gt 0 ]; then
  echo "⚠️  AST-only, no semantic layer: ${NO_SEMANTIC[*]}"
  echo "    Run /graphify . inside each to add concepts, rationale and config nodes."
fi
echo ""
echo "   Per repo: <repo>/graphify-out/graph.json   — full detail, one service"
echo "   Global:   $(graphify global path 2>/dev/null || echo ~/.graphify/global-graph.json)"
echo "             — all services + cross-repo integration edges"
