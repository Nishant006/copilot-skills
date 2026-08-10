#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Copilot Skills — Self-Validation                                           ║
# ║  Run: ./validate.sh                                                         ║
# ║  Use in CI or before committing changes to the skills repo.                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Resolve script location
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
while [ -L "$SCRIPT_PATH" ]; do
  DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$DIR/$SCRIPT_PATH"
done
SKILLS_ROOT="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

ERRORS=0
WARNINGS=0

pass() { echo "  ✅ $1"; }
warn() { echo "  ⚠️  $1"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo "  ❌ $1"; ERRORS=$((ERRORS + 1)); }

echo "🔍 Validating .copilot-skills/ integrity..."
echo ""

# ─── Check 1: No hardcoded personal paths ─────────────────────────────────────
echo "── Check 1: No hardcoded personal paths ──"
personal_paths=$(grep -rn '/Users/\|/home/[a-z]' "$SKILLS_ROOT" \
  --include="*.sh" --include="*.js" \
  --exclude-dir=node_modules \
  --exclude="validate.sh" \
  2>/dev/null | grep -v "\.template" | grep -v "QUICKSTART\|SKILL\.md\|README" | grep -v " \*\|^\s*//" | grep -v "//\|/\*\| \* " || true)

if [ -n "$personal_paths" ]; then
  fail "Found hardcoded personal paths in functional files:"
  echo "$personal_paths" | sed 's/^/       /'
else
  pass "No hardcoded personal paths in scripts"
fi

# ─── Check 2: No hardcoded $HOME/IdeaProjects ─────────────────────────────────
echo "── Check 2: No hardcoded workspace paths ──"
workspace_paths=$(grep -rn '\$HOME/IdeaProjects\|~/IdeaProjects' "$SKILLS_ROOT" \
  --include="*.sh" \
  --exclude="validate.sh" \
  2>/dev/null || true)

if [ -n "$workspace_paths" ]; then
  fail "Found hardcoded workspace paths:"
  echo "$workspace_paths" | sed 's/^/       /'
else
  pass "No hardcoded workspace paths in shell scripts"
fi

# ─── Check 3: All skills in AGENTS.md exist as directories ────────────────────
echo "── Check 3: Skill directories exist ──"
skills_dir="$SKILLS_ROOT/generic/.github/skills"
agents_file="$SKILLS_ROOT/generic/AGENTS.md"

if [ -f "$agents_file" ]; then
  # Dynamically discover all skill names from directories (generic + all projects)
  known_skills=""
  for d in "$skills_dir"/*/; do
    [ -d "$d" ] && known_skills="$known_skills $(basename "$d")"
  done
  for project_dir in "$SKILLS_ROOT/projects"/*/; do
    [ -d "$project_dir/.github/skills" ] || continue
    for d in "$project_dir/.github/skills"/*/; do
      [ -d "$d" ] && known_skills="$known_skills $(basename "$d")"
    done
  done
  known_skills=$(echo "$known_skills" | tr ' ' '\n' | sort -u | grep -v '^$')

  # Verify each known skill is referenced in AGENTS.md
  for skill in $known_skills; do
    if grep -q "\`$skill\`" "$agents_file" 2>/dev/null; then
      pass "$skill (in AGENTS.md + directory exists)"
    else
      warn "$skill — directory exists but NOT referenced in AGENTS.md"
    fi
  done

  # Also check if AGENTS.md references skills that don't exist as directories
  agents_skills=$(grep -oE '`[a-z][-a-z]*`' "$agents_file" | tr -d '`' | sort -u | \
    grep -vE '^(src|git|npm|java|spring|redis|kafka|maven|config|test|build|fix|skill-name|triggered-by|triggers-sub-agents|last-updated|project-specific|layer|name|description|status|ref-type|ref-value|turn-index|session-id|file-path|tool-name|agent-name|checkpoint-number|first-seen-at|created-at|updated-at|user-message|assistant-response)$')
  for skill in $agents_skills; do
    if echo "$known_skills" | grep -qx "$skill"; then
      : # already checked above
    elif [ ${#skill} -gt 4 ] && echo "$skill" | grep -qE '^[a-z]+-[a-z]+' && ! echo "$skill" | grep -qE '(sub-agent|cross-cutting|non-negotiable|auto-link|auto-detect|auto-trigger|re-link|pre-check|post-spec|post-plan|post-impl|one-shot)'; then
      # Looks like a skill name (has a hyphen, long enough, not a common compound term)
      if [ ! -d "$skills_dir/$skill" ] && ! find "$SKILLS_ROOT/projects" -path "*/.github/skills/$skill" -type d 2>/dev/null | grep -q .; then
        warn "'$skill' referenced in AGENTS.md but no directory found (may be a concept, not a skill)"
      fi
    fi
  done
else
  fail "AGENTS.md not found at $agents_file"
fi

# ─── Check 4: All SKILL.md have required frontmatter ─────────────────────────
echo "── Check 4: SKILL.md frontmatter ──"
while IFS= read -r -d '' skill_md; do
  skill_name=$(basename "$(dirname "$skill_md")")
  # Check for name/description in frontmatter
  if head -10 "$skill_md" | grep -q "^name:"; then
    pass "$skill_name — has frontmatter"
  else
    warn "$skill_name — missing 'name:' in frontmatter ($(echo "$skill_md" | sed "s|$SKILLS_ROOT/||"))"
  fi
done < <(find "$SKILLS_ROOT" -name "SKILL.md" -not -path "*/node_modules/*" -print0)

# ─── Check 5: Project overlays have required structure ────────────────────────
echo "── Check 5: Project overlay structure ──"
for project_dir in "$SKILLS_ROOT/projects"/*/; do
  [ -d "$project_dir" ] || continue
  project_name=$(basename "$project_dir")

  if [ -d "$project_dir/.github" ]; then
    pass "$project_name — has .github/"
  else
    fail "$project_name — missing .github/ directory"
  fi

  if [ -f "$project_dir/.github/copilot-instructions.md" ]; then
    pass "$project_name — has copilot-instructions.md"
  else
    warn "$project_name — missing copilot-instructions.md"
  fi
done

# ─── Check 6: setup.sh and link-skills.sh are executable ─────────────────────
echo "── Check 6: Scripts executable ──"
for script in "setup.sh" "link-skills.sh"; do
  if [ -x "$SKILLS_ROOT/$script" ]; then
    pass "$script is executable"
  else
    fail "$script is NOT executable (run: chmod +x $script)"
  fi
done

# ─── Check 7: .gitignore exists and covers secrets ───────────────────────────
echo "── Check 7: .gitignore covers secrets ──"
if [ -f "$SKILLS_ROOT/.gitignore" ]; then
  if grep -q "cred.md" "$SKILLS_ROOT/.gitignore"; then
    pass ".gitignore covers cred.md"
  else
    fail ".gitignore does NOT exclude cred.md (secrets could be committed!)"
  fi
else
  fail ".gitignore not found"
fi

# ─── Check 8: Frontmatter last-updated freshness ─────────────────────────────
echo "── Check 8: Frontmatter date freshness ──"
stale_count=0
while IFS= read -r -d '' skill_md; do
  # Skip symlinks for this check (check the real file only)
  [ -L "$skill_md" ] && continue
  skill_name=$(basename "$(dirname "$skill_md")")
  last_updated=$(grep "^last-updated:" "$skill_md" 2>/dev/null | head -1 | sed 's/last-updated: //')
  if [ -z "$last_updated" ]; then
    warn "$skill_name — missing last-updated in frontmatter"
    stale_count=$((stale_count + 1))
  else
    # Check if file was modified after the declared last-updated date
    file_mod=$(date -r "$skill_md" "+%Y-%m-%d" 2>/dev/null || stat -c %y "$skill_md" 2>/dev/null | cut -d' ' -f1)
    if [ -n "$file_mod" ] && [ "$file_mod" \> "$last_updated" ]; then
      warn "$skill_name — file modified ($file_mod) after declared last-updated ($last_updated)"
      stale_count=$((stale_count + 1))
    fi
  fi
done < <(find "$SKILLS_ROOT" -name "SKILL.md" -not -path "*/node_modules/*" -print0)
if [ "$stale_count" -eq 0 ]; then
  pass "All SKILL.md frontmatter dates are current"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
elif [ "$ERRORS" -eq 0 ]; then
  echo "⚠️  Passed with $WARNINGS warning(s)"
  exit 0
else
  echo "❌ FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  echo "   Fix errors before committing."
  exit 1
fi
