#!/usr/bin/env bash
# copilot-link-skills v5 — Central skill linker (self-locating)
# Links generic + project-specific skills into the current project via symlinks.
#
# Usage: copilot-link-skills [project-name]
#   If project-name is omitted, auto-detects from git remote or dirname.

# NOTE: Do NOT use set -euo pipefail here.
# This script is sourced into the user's shell via copilot-link-skills().
# set -e would kill the entire shell session on any non-zero exit code.

# Zsh compat: helper to enable null_glob locally within functions.
# Do NOT set globally — it leaks into the user's shell session.
# Instead, each function that needs it should call: _cs_nullglob_on
# and at the end call: _cs_nullglob_off
_cs_nullglob_on() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt LOCAL_OPTIONS NULL_GLOB 2>/dev/null
  fi
}
_cs_nullglob_off() {
  : # no-op — LOCAL_OPTIONS handles Zsh automatically; Bash has no nullglob issue here
}

# ─── Helper: check if a directory is a git repo (supports worktrees) ──────────
_is_git_repo() {
  [ -d "$1/.git" ] || [ -f "$1/.git" ]
}

# ─── Self-locate: resolve SKILLS_ROOT from this script's actual location ──────
# Works whether script is sourced, executed directly, or invoked via symlink.
_resolve_skills_root() {
  local script_path=""
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    script_path="${BASH_SOURCE[0]}"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    script_path="${(%):-%x}"
  else
    script_path="$0"
  fi
  # Resolve symlinks to get the real path
  while [ -L "$script_path" ]; do
    local dir="$(cd -P "$(dirname "$script_path")" && pwd)"
    script_path="$(readlink "$script_path")"
    # Handle relative symlinks
    [[ "$script_path" != /* ]] && script_path="$dir/$script_path"
  done
  cd -P "$(dirname "$script_path")" && pwd
}

# If COPILOT_SKILLS_ROOT is set externally (e.g., by setup.sh), use it.
# Otherwise, auto-detect from script location.
SKILLS_ROOT="${COPILOT_SKILLS_ROOT:-$(_resolve_skills_root)}"
GENERIC="$SKILLS_ROOT/generic"
PROJECTS="$SKILLS_ROOT/projects"

# ─── Detect project name ─────────────────────────────────────────────────────
detect_project() {
  local name=""
  # Try git remote
  if git remote get-url origin &>/dev/null; then
    name=$(git remote get-url origin | sed 's|.*/||; s|\.git$||')
  fi
  # Fallback to directory name
  if [ -z "$name" ]; then
    name=$(basename "$PWD")
  fi
  echo "$name"
}


# ─── Main ────────────────────────────────────────────────────────────────────
link_skills() {
  # Prevent zsh from erroring on empty glob patterns (e.g. dirs with no subdirs)
  if [ -n "${ZSH_VERSION:-}" ]; then setopt localoptions nullglob; fi

  if ! _is_git_repo "."; then
    echo "❌ Not a git repo (no .git directory or worktree file). Run this from your project root."
    return 1
  fi

  # Safety: ensure we're operating at the git repo root
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -n "$repo_root" ] && [ "$(cd "$PWD" && pwd)" != "$(cd "$repo_root" && pwd)" ]; then
    echo "⚠️  Not at repo root. Changing to: $repo_root"
    cd "$repo_root" || return 1
  fi

  local project="${1:-$(detect_project)}"
  local project_overlay="$PROJECTS/$project"
  local linked=0 skipped=0
  local total_skills=$(ls -d "$GENERIC/.github/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')

  echo "┌────────────────────────────────────────────────┐"
  echo "│  copilot-skills link — $(basename "$PWD")"
  echo "│  Source: v$(cat "$SKILLS_ROOT/VERSION" 2>/dev/null | tr -d '[:space:]' || echo '?') · $([ -d "$project_overlay" ] && echo "overlay: yes" || echo "generic only")"
  echo "└────────────────────────────────────────────────┘"
  echo ""

  mkdir -p .github/skills .github/instructions

  # ─── Step 1: Link skill directories ──────────────────────────────────────
  # For each generic skill, check if project has overlay files for it
  for skill_dir in "$GENERIC/.github/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill=$(basename "$skill_dir")
    local target=".github/skills/$skill"

    # Skip if tracked in git (e.g. enterprise-skills branch checked out)
    if [ -e "$target" ] && git ls-files -- "$target" 2>/dev/null | grep -q .; then
      echo "  ⚠️  $target — tracked in git, skipping"
      skipped=$((skipped + 1))
      continue
    fi

    # Remove existing (symlink or untracked dir)
    rm -rf "$target"

    if [ -d "$project_overlay/.github/skills/$skill" ]; then
      # Project has overlay files for this skill → individual file symlinks
      mkdir -p "$target"
      # Link all generic files first
      for f in "$skill_dir"*; do
        [ -f "$f" ] || continue
        ln -sfn "$f" "$target/$(basename "$f")"
      done
      # Link generic subdirs
      for d in "$skill_dir"*/; do
        [ -d "$d" ] || continue
        local subdir=$(basename "$d")
        mkdir -p "$target/$subdir"
        for f in "$d"*; do
          [ -f "$f" ] || continue
          ln -sfn "$f" "$target/$subdir/$(basename "$f")"
        done
      done
      # Overlay project-specific files (overwrite generic if same name)
      for f in "$project_overlay/.github/skills/$skill"/*; do
        [ -f "$f" ] || continue
        ln -sfn "$f" "$target/$(basename "$f")"
      done
      # Overlay project-specific subdirs
      for d in "$project_overlay/.github/skills/$skill"/*/; do
        [ -d "$d" ] || continue
        local subdir=$(basename "$d")
        mkdir -p "$target/$subdir"
        for f in "$d"*; do
          [ -f "$f" ] || continue
          ln -sfn "$f" "$target/$subdir/$(basename "$f")"
        done
      done
      echo "  [$((linked + skipped + 1))/$total_skills] ✅ $skill (merged: generic + overlay)"
    else
      # No overlay — symlink entire directory
      ln -sfn "$skill_dir" "$target"
      echo "  [$((linked + skipped + 1))/$total_skills] ✅ $skill (generic)"
    fi
    linked=$((linked + 1))
  done

  # ─── Step 2: Link project-only skills (e.g. api-tester) ─────────────────
  if [ -d "$project_overlay/.github/skills" ]; then
    for skill_dir in "$project_overlay/.github/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local skill=$(basename "$skill_dir")
      local target=".github/skills/$skill"
      # Skip if already handled above
      [ -e "$target" ] && continue
      # Skip if tracked in git
      if git ls-files -- "$target" 2>/dev/null | grep -q .; then
        echo "  ⚠️  $target — tracked in git, skipping"
        skipped=$((skipped + 1))
        continue
      fi
      rm -rf "$target"
      ln -sfn "$skill_dir" "$target"
      echo "  ✅ $skill (project-only)"
      linked=$((linked + 1))
    done
  fi

  # ─── Step 3: Link top-level skill files (README, SUB-AGENT-CONTRACTS) ───
  for f in "$GENERIC/.github/skills"/*.md; do
    [ -f "$f" ] || continue
    local target=".github/skills/$(basename "$f")"
    if [ -e "$target" ] && git ls-files -- "$target" 2>/dev/null | grep -q .; then
      skipped=$((skipped + 1))
      continue
    fi
    rm -f "$target"
    ln -sfn "$f" "$target"
  done

  # ─── Step 4: Generate AGENTS.md (base + overlay) ────────────────────────
  local agents_target="AGENTS.md"
  if [ -e "$agents_target" ] && git ls-files -- "$agents_target" 2>/dev/null | grep -q .; then
    echo "  ⚠️  AGENTS.md — tracked in git, skipping"
  else
    rm -f "$agents_target"
    cat "$GENERIC/AGENTS.md" > "$agents_target"
    if [ -f "$project_overlay/AGENTS-overlay.md" ]; then
      echo "" >> "$agents_target"
      cat "$project_overlay/AGENTS-overlay.md" >> "$agents_target"
    fi
    echo "  ✅ AGENTS.md (generated: base + overlay)"
  fi

  # ─── Step 5: Generate AI-WORKFLOW.md (base + overlay) ───────────────────
  local workflow_target="AI-WORKFLOW.md"
  if [ -e "$workflow_target" ] && git ls-files -- "$workflow_target" 2>/dev/null | grep -q .; then
    echo "  ⚠️  AI-WORKFLOW.md — tracked in git, skipping"
  else
    rm -f "$workflow_target"
    cat "$GENERIC/AI-WORKFLOW.md" > "$workflow_target"
    if [ -f "$project_overlay/AI-WORKFLOW-overlay.md" ]; then
      echo "" >> "$workflow_target"
      cat "$project_overlay/AI-WORKFLOW-overlay.md" >> "$workflow_target"
    fi
    echo "  ✅ AI-WORKFLOW.md (generated: base + overlay)"
  fi

  # ─── Step 6: Link instructions ─────────────────────────────────────────
  # Link all .instructions.md files from generic and project overlay
  mkdir -p .github/instructions
  
  # First: link all generic instruction files
  if [ -d "$GENERIC/.github/instructions" ]; then
    for instr_file in "$GENERIC/.github/instructions"/*.instructions.md; do
      [ -f "$instr_file" ] || continue
      local instr_name=$(basename "$instr_file")
      local instr_target=".github/instructions/$instr_name"
      if [ -e "$instr_target" ] && git ls-files -- "$instr_target" 2>/dev/null | grep -q .; then
        continue
      fi
      rm -f "$instr_target"
      ln -sfn "$instr_file" "$instr_target"
    done
  fi

  # Second: project overlay instructions override generic ones
  if [ -d "$project_overlay/.github/instructions" ]; then
    for instr_file in "$project_overlay/.github/instructions"/*.instructions.md; do
      [ -f "$instr_file" ] || continue
      local instr_name=$(basename "$instr_file")
      local instr_target=".github/instructions/$instr_name"
      if [ -e "$instr_target" ] && git ls-files -- "$instr_target" 2>/dev/null | grep -q .; then
        continue
      fi
      rm -f "$instr_target"
      ln -sfn "$instr_file" "$instr_target"
    done
  fi
  echo "  ✅ instructions/ ($(ls .github/instructions/*.instructions.md 2>/dev/null | wc -l | tr -d ' ') files)"

  # ─── Step 7: Link copilot-instructions.md ──────────────────────────────
  local ci_target=".github/copilot-instructions.md"
  if [ -e "$ci_target" ] && git ls-files -- "$ci_target" 2>/dev/null | grep -q .; then
    echo "  ⚠️  copilot-instructions.md — tracked in git, skipping"
  else
    if [ -f "$project_overlay/.github/copilot-instructions.md" ]; then
      rm -f "$ci_target"
      ln -sfn "$project_overlay/.github/copilot-instructions.md" "$ci_target"
      echo "  ✅ copilot-instructions.md (project)"
    fi
  fi

  # ─── Step 8: Link prompts (VS Code Copilot Chat slash commands) ────────
  if [ -d "$GENERIC/.github/prompts" ]; then
    mkdir -p .github/prompts
    for prompt_file in "$GENERIC/.github/prompts"/*.prompt.md; do
      [ -f "$prompt_file" ] || continue
      local prompt_name=$(basename "$prompt_file")
      local prompt_target=".github/prompts/$prompt_name"
      if [ -e "$prompt_target" ] && git ls-files -- "$prompt_target" 2>/dev/null | grep -q .; then
        continue
      fi
      rm -f "$prompt_target"
      ln -sfn "$prompt_file" "$prompt_target"
    done
    echo "  ✅ prompts/ (VS Code slash commands)"
  fi

  # ─── Step 9: Link issue templates (Copilot Coding Agent) ────────────────
  if [ -d "$GENERIC/.github/ISSUE_TEMPLATE" ]; then
    mkdir -p .github/ISSUE_TEMPLATE
    for tmpl_file in "$GENERIC/.github/ISSUE_TEMPLATE"/*; do
      [ -f "$tmpl_file" ] || continue
      local tmpl_name=$(basename "$tmpl_file")
      local tmpl_target=".github/ISSUE_TEMPLATE/$tmpl_name"
      if [ -e "$tmpl_target" ] && git ls-files -- "$tmpl_target" 2>/dev/null | grep -q .; then
        continue
      fi
      rm -f "$tmpl_target"
      ln -sfn "$tmpl_file" "$tmpl_target"
    done
    echo "  ✅ ISSUE_TEMPLATE/ (Copilot Coding Agent)"
  fi

  # ─── Step 10: Version stamp ─────────────────────────────────────────────
  if [ -f "$SKILLS_ROOT/VERSION" ]; then
    local current_version=$(cat "$SKILLS_ROOT/VERSION" | tr -d '[:space:]')
    local stamp_file=".github/.copilot-skills-version"
    mkdir -p .github
    echo "$current_version" > "$stamp_file"
  fi

  # ─── Step 11: Auto-update .gitignore (prevent accidental commits) ───────
  local gitignore_marker_start="### Copilot Skills (auto-linked) ###"
  local gitignore_marker_end="### /Copilot Skills ###"
  local gitignore_block="${gitignore_marker_start}
AGENTS.md
AI-WORKFLOW.md
.github/copilot-instructions.md
.github/skills/
.github/instructions/
.github/prompts/
.github/ISSUE_TEMPLATE/
.github/.copilot-skills-version
graphify-out*
features/
postman/
${gitignore_marker_end}"

  if [ -f ".gitignore" ] && grep -q "### Copilot Skills" ".gitignore" 2>/dev/null; then
    # Remove old block (between any copilot skills markers) and rewrite
    local tmp_gi=".gitignore.copilot-tmp"
    sed '/### Copilot Skills/,/### \/Copilot Skills ###/d' ".gitignore" 2>/dev/null | \
      sed '/### Copilot Skills (auto-linked) ###/,$d' > "$tmp_gi"
    # Append fresh block
    echo "" >> "$tmp_gi"
    echo "$gitignore_block" >> "$tmp_gi"
    mv "$tmp_gi" ".gitignore"
    echo "  ✅ .gitignore refreshed (copilot-skills block rewritten)"
  elif [ -f ".gitignore" ]; then
    echo "" >> .gitignore
    echo "$gitignore_block" >> .gitignore
    echo "  ✅ .gitignore updated (copilot-skills entries added)"
  else
    echo "$gitignore_block" > .gitignore
    echo "  ✅ .gitignore created (copilot-skills entries)"
  fi

  echo ""
  # Step 12: Ensure per-repo graphify graph
  link_graphify
  local current_version=$(cat "$SKILLS_ROOT/VERSION" 2>/dev/null | tr -d '[:space:]' || echo '?')
  echo ""
  echo "━━━ Summary ━━━"
  echo "  Linked: $linked skills"
  echo "  Skipped: $skipped (tracked in git)"
  echo "  Version: v$current_version"
  echo "  Linked at: $(date '+%Y-%m-%d %H:%M')"
  echo "To edit skills: cd $SKILLS_ROOT"
}

# ─── Status / Check Mode ─────────────────────────────────────────────────────
check_skills() {
  # Prevent zsh from erroring on empty glob patterns
  if [ -n "${ZSH_VERSION:-}" ]; then setopt localoptions nullglob; fi

  if ! _is_git_repo "."; then
    echo "❌ Not a git repo (no .git directory or worktree file)."
    return 1
  fi

  local project="${1:-$(detect_project)}"
  local project_overlay="$PROJECTS/$project"
  local missing=0 outdated=0 ok=0

  echo "🔍 Checking skills status for $(basename "$PWD") (project: $project) ..."
  echo ""

  # Version check
  if [ -f "$SKILLS_ROOT/VERSION" ]; then
    local source_version=$(cat "$SKILLS_ROOT/VERSION" | tr -d '[:space:]')
    local stamp_file=".github/.copilot-skills-version"
    if [ -f "$stamp_file" ]; then
      local linked_version=$(cat "$stamp_file" | tr -d '[:space:]')
      if [ "$linked_version" != "$source_version" ]; then
        echo "  ⚠️  VERSION MISMATCH: linked v$linked_version → source v$source_version"
        echo "     Run 'copilot-link-skills' to update."
        outdated=$((outdated + 1))
      else
        echo "  ✅ Version: v$source_version (up to date)"
      fi
    else
      echo "  ⚠️  No version stamp — run 'copilot-link-skills' to initialize"
      outdated=$((outdated + 1))
    fi
    echo ""
  fi

  # Shell block version check (derives expected version from VERSION file)
  local shell_block_version=$(cat "$SKILLS_ROOT/VERSION" 2>/dev/null | tr -d '[:space:]')
  local rc_file="${HOME}/.zshrc"
  [ -f "$rc_file" ] || rc_file="${HOME}/.bashrc"
  if [ -f "$rc_file" ]; then
    local installed_version=$(grep "# Copilot Skills v" "$rc_file" 2>/dev/null | grep -oE "v[0-9]+" | tr -d 'v')
    if [ -n "$installed_version" ] && [ "$installed_version" != "$shell_block_version" ]; then
      echo "  ⚠️  Shell block: v$installed_version installed → v$shell_block_version available"
      echo "     Run 'cd $SKILLS_ROOT && ./setup.sh' to upgrade"
      outdated=$((outdated + 1))
    elif [ -n "$installed_version" ]; then
      echo "  ✅ Shell block: v$installed_version (up to date)"
    fi
  fi

  mkdir -p .github/skills

  # Check generic skills
  for skill_dir in "$GENERIC/.github/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill=$(basename "$skill_dir")
    local target=".github/skills/$skill"

    if [ ! -e "$target" ]; then
      echo "  ❌ MISSING: $skill"
      missing=$((missing + 1))
    elif [ -L "$target" ]; then
      # Symlinked directory - always up to date (points to source)
      echo "  ✅ $skill (symlinked → always current)"
      ok=$((ok + 1))
    elif [ -d "$target" ]; then
      # Merged directory - check each file (top-level + nested subdirs)
      local stale=0
      # Check top-level files
      for f in "$skill_dir"*; do
        [ -f "$f" ] || continue
        local tgt="$target/$(basename "$f")"
        if [ ! -e "$tgt" ]; then
          echo "  ⚠️  $skill/$(basename "$f") — MISSING (new file in generic)"
          stale=1
        elif [ -L "$tgt" ]; then
          local actual=$(readlink "$tgt")
          local overlay_f="$project_overlay/.github/skills/$skill/$(basename "$f")"
          if [ -f "$overlay_f" ]; then
            if [ "$actual" != "$overlay_f" ]; then
              echo "  ⚠️  $skill/$(basename "$f") — STALE (should point to overlay)"
              stale=1
            fi
          elif [ "$actual" != "$f" ]; then
            echo "  ⚠️  $skill/$(basename "$f") — STALE (points to wrong source)"
            stale=1
          fi
        fi
      done
      # Check nested subdirectories (scripts/, docs/, etc.)
      for subdir in "$skill_dir"*/; do
        [ -d "$subdir" ] || continue
        local subname=$(basename "$subdir")
        for f in "$subdir"*; do
          [ -f "$f" ] || continue
          local tgt="$target/$subname/$(basename "$f")"
          if [ ! -e "$tgt" ]; then
            echo "  ⚠️  $skill/$subname/$(basename "$f") — MISSING (new nested file)"
            stale=1
          elif [ -L "$tgt" ]; then
            local actual=$(readlink "$tgt")
            if [ "$actual" != "$f" ]; then
              local overlay_f="$project_overlay/.github/skills/$skill/$subname/$(basename "$f")"
              [ -f "$overlay_f" ] || {
                echo "  ⚠️  $skill/$subname/$(basename "$f") — STALE"
                stale=1
              }
            fi
          fi
        done
      done
      # Check overlay files
      if [ -d "$project_overlay/.github/skills/$skill" ]; then
        for f in "$project_overlay/.github/skills/$skill"/*; do
          [ -f "$f" ] || continue
          local tgt="$target/$(basename "$f")"
          if [ ! -e "$tgt" ]; then
            echo "  ⚠️  $skill/$(basename "$f") — MISSING (new overlay file)"
            stale=1
          fi
        done
        # Check overlay subdirs
        for subdir in "$project_overlay/.github/skills/$skill"/*/; do
          [ -d "$subdir" ] || continue
          local subname=$(basename "$subdir")
          for f in "$subdir"*; do
            [ -f "$f" ] || continue
            local tgt="$target/$subname/$(basename "$f")"
            if [ ! -e "$tgt" ]; then
              echo "  ⚠️  $skill/$subname/$(basename "$f") — MISSING (new overlay nested file)"
              stale=1
            fi
          done
        done
      fi
      if [ "$stale" -eq 1 ]; then
        outdated=$((outdated + 1))
      else
        echo "  ✅ $skill (merged, up to date)"
        ok=$((ok + 1))
      fi
    fi
  done

  # Check project-only skills
  if [ -d "$project_overlay/.github/skills" ]; then
    for skill_dir in "$project_overlay/.github/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local skill=$(basename "$skill_dir")
      local target=".github/skills/$skill"
      [ -d "$GENERIC/.github/skills/$skill" ] && continue  # already checked
      if [ ! -e "$target" ]; then
        echo "  ❌ MISSING: $skill (project-only)"
        missing=$((missing + 1))
      else
        echo "  ✅ $skill (project-only)"
        ok=$((ok + 1))
      fi
    done
  fi

  # Check AGENTS.md freshness (generic base + overlay)
  if [ -f "AGENTS.md" ] && [ -f "$GENERIC/AGENTS.md" ]; then
    local gen_time=$(stat -f %m "$GENERIC/AGENTS.md" 2>/dev/null || stat -c %Y "$GENERIC/AGENTS.md" 2>/dev/null)
    local tgt_time=$(stat -f %m "AGENTS.md" 2>/dev/null || stat -c %Y "AGENTS.md" 2>/dev/null)
    local agents_stale=0
    if [ "$gen_time" -gt "$tgt_time" ] 2>/dev/null; then
      agents_stale=1
    fi
    # Also check overlay mtime
    if [ -f "$project_overlay/AGENTS-overlay.md" ]; then
      local overlay_time=$(stat -f %m "$project_overlay/AGENTS-overlay.md" 2>/dev/null || stat -c %Y "$project_overlay/AGENTS-overlay.md" 2>/dev/null)
      if [ "$overlay_time" -gt "$tgt_time" ] 2>/dev/null; then
        agents_stale=1
      fi
    fi
    if [ "$agents_stale" -eq 1 ]; then
      echo "  ⚠️  AGENTS.md — STALE (source updated after last link)"
      outdated=$((outdated + 1))
    fi
  elif [ ! -f "AGENTS.md" ]; then
    echo "  ❌ MISSING: AGENTS.md"
    missing=$((missing + 1))
  fi

  # Check AI-WORKFLOW.md
  if [ ! -f "AI-WORKFLOW.md" ] && ! git ls-files -- "AI-WORKFLOW.md" 2>/dev/null | grep -q .; then
    echo "  ❌ MISSING: AI-WORKFLOW.md"
    missing=$((missing + 1))
  fi

  # Check copilot-instructions.md
  local ci_target=".github/copilot-instructions.md"
  if [ -f "$project_overlay/.github/copilot-instructions.md" ]; then
    if [ ! -e "$ci_target" ]; then
      echo "  ❌ MISSING: copilot-instructions.md (project overlay has one)"
      missing=$((missing + 1))
    elif [ -L "$ci_target" ]; then
      echo "  ✅ copilot-instructions.md (symlinked)"
      ok=$((ok + 1))
    elif git ls-files -- "$ci_target" 2>/dev/null | grep -q .; then
      echo "  ℹ️  copilot-instructions.md (tracked in git — not managed)"
    fi
  fi

  # Check .gitignore has copilot-skills entries
  if [ -f ".gitignore" ]; then
    if ! grep -q "### Copilot Skills" ".gitignore" 2>/dev/null; then
      echo "  ⚠️  .gitignore — missing copilot-skills entries (run copilot-link-skills)"
      outdated=$((outdated + 1))
    fi
  else
    echo "  ⚠️  .gitignore — MISSING (symlinked files may get committed)"
    outdated=$((outdated + 1))
  fi

  # Check graphify (optional — only if enabled)
  if [ "${COPILOT_GRAPHIFY_ENABLED:-1}" != "0" ]; then
    if command -v graphify &>/dev/null; then
      if [ -f "graphify-out/graph.json" ] || ([ -L "graphify-out" ] && [ -f "graphify-out/graph.json" ]); then
        local stale_graph
        stale_graph="$(find graphify-out/graph.json -mtime +7 -print 2>/dev/null)"
        if [ -n "$stale_graph" ]; then
          echo "  ⚠️  graphify-out/graph.json — STALE (>7 days, run: graphify . --update)"
          outdated=$((outdated + 1))
        else
          echo "  ✅ graphify-out/graph.json (fresh)"
          ok=$((ok + 1))
        fi
      else
        echo "  ⚠️  graphify-out/graph.json — MISSING (run: graphify .)"
        outdated=$((outdated + 1))
      fi
    else
      echo "  ℹ️  graphify — not installed (optional: uv tool install graphifyy)"
    fi
  fi

  echo ""
  echo "━━━ Summary ━━━"
  local summary="  $ok up-to-date"
  [ "$outdated" -gt 0 ] && summary="$summary · $outdated stale"
  [ "$missing" -gt 0 ] && summary="$summary · $missing missing"
  if [ $((outdated + missing)) -gt 0 ]; then
    echo "  ⚠️  $summary"
    echo "  Fix: copilot-skills link"
    return 1
  else
    echo "  ✅ $summary"
    return 0
  fi
}

# ─── Update mode (alias for link with status) ────────────────────────────────
update_skills() {
  echo "🔄 Updating skills..."
  echo ""
  link_skills "$@"
  echo ""
  echo "🔍 Post-update check:"
  check_skills "$@"
}

# ─── Update All — re-link all + aggregate check ──────────────────────────────
update_all() {
  link_all
  echo ""
  echo "🔍 Post-update health check:"
  echo ""
  local parent_dir="$(cd "$SKILLS_ROOT/.." && pwd)"
  local healthy=0 unhealthy=0
  for dir in "$parent_dir"/*/; do
    [ -d "$dir" ] || continue
    local dirname="$(basename "$dir")"
    [ "$dirname" = ".copilot-skills" ] && continue
    [[ "$dirname" == .* ]] && continue
    _is_git_repo "$dir" || continue
    if (cd "$dir" && check_skills >/dev/null 2>&1); then
      healthy=$((healthy + 1))
    else
      echo "  ⚠️  $dirname — has issues (run: cd $dir && copilot-check-skills)"
      unhealthy=$((unhealthy + 1))
    fi
  done
  if [ "$unhealthy" -eq 0 ]; then
    echo "  ✅ All $healthy projects verified healthy!"
  else
    echo "  $unhealthy project(s) still have issues after update."
  fi
}

# ─── Step 8: Ensure a per-repo graphify-out ───────────────────────────────────
# Each repo owns a REAL graphify-out directory. Symlinking several repos at one
# shared graphify-out makes them all write into the same mutable graph, which
# cross-contaminates every project's nodes (AST nodes carry relative paths and
# no repo tag, so they become unattributable). Cross-repo knowledge belongs in
# the global graph (~/.graphify/global-graph.json), which re-tags nodes per repo
# — see tools/graphify_build_all.sh.
#
# Respects: COPILOT_GRAPHIFY_ENABLED=0 to skip entirely
link_graphify() {
  # Skip if graphify is disabled
  if [ "${COPILOT_GRAPHIFY_ENABLED:-1}" = "0" ]; then
    return
  fi

  local target="graphify-out"

  # Repair the legacy shared-symlink layout.
  if [ -L "$target" ]; then
    echo "  ⚠️  graphify-out was a symlink → $(readlink "$target") — removing"
    echo "     (shared graphs cross-contaminate; each repo needs its own)"
    rm -f "$target"
  fi

  # Project already owns a real graph — nothing to do.
  if [ -d "$target" ] && [ -f "$target/graph.json" ]; then
    return
  fi

  if ! command -v graphify &>/dev/null; then
    return
  fi

  echo "  🔄 Building per-repo knowledge graph (AST-only, no API key)..."
  if graphify update . >/dev/null 2>&1 && [ -f "$target/graph.json" ]; then
    local n
    n="$(grep -o '"id"' "$target/graph.json" 2>/dev/null | wc -l | tr -d ' ')"
    echo "  ✅ graphify-out/graph.json built (~$n nodes)"
    # Register this repo's slice in the global domain graph.
    graphify global add "$target/graph.json" --as "$(basename "$PWD")" >/dev/null 2>&1 \
      && echo "  🌍 registered in global graph" || true
  else
    echo "  ⚠️  graph build failed — run: copilot-graphify rebuild"
  fi
}

# ─── Link All — find all git repos in SKILLS_ROOT parent and link each ────────
link_all() {
  # Prevent zsh from erroring on empty glob patterns
  if [ -n "${ZSH_VERSION:-}" ]; then setopt localoptions nullglob; fi

  local parent_dir="$(cd "$SKILLS_ROOT/.." && pwd)"
  local success=0 skipped=0 failed=0

  echo "🔗 Linking skills into ALL projects under: $parent_dir"
  echo ""

  for dir in "$parent_dir"/*/; do
    [ -d "$dir" ] || continue

    # Skip .copilot-skills itself
    local dirname="$(basename "$dir")"
    if [ "$dirname" = ".copilot-skills" ]; then
      continue
    fi

    # Skip hidden directories
    if [[ "$dirname" == .* ]]; then
      continue
    fi

    # Only process git repositories (supports worktrees via .git file)
    if ! _is_git_repo "$dir"; then
      skipped=$((skipped + 1))
      continue
    fi

    echo "━━━ $dirname ━━━"
    local link_exit=0
    (cd "$dir" && link_skills) 2>&1 | sed 's/^/  /'
    # Capture pipe exit immediately — no command between pipe and read!
    # In Bash: PIPESTATUS[0] has left side exit code
    # In Zsh: pipestatus[1] has left side exit code (1-indexed)
    # Plain assignment doesn't reset PIPESTATUS; `if`/`[` would.
    link_exit=${PIPESTATUS[0]:-${pipestatus[1]:-0}}
    if [ "$link_exit" -eq 0 ]; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
    fi
    echo ""
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Done! $success projects linked, $skipped skipped (not git repos), $failed failed"
}

# ─── Direct execution entry point ─────────────────────────────────────────────
# MUST stay at the very bottom. When this file is sourced (the normal path, via
# the copilot-link-skills shell function) the whole file is parsed before any
# call, so helper order does not matter. When it is EXECUTED, bash runs each
# statement as it is parsed — so a dispatch placed mid-file calls functions that
# have not been defined yet (link_graphify, defined further down, failed with
# "command not found" this way). Keeping the dispatch last makes both paths
# behave identically.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ "${1:-}" = "--all" ] || [ "${1:-}" = "-a" ]; then
    link_all
  else
    link_skills "$@"
  fi
fi
