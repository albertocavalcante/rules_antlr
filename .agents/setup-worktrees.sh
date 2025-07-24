#!/bin/bash

# rules_antlr Multi-Agent Worktree Setup Script
# Creates git worktrees for parallel Claude Code development

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up multi-agent worktrees for rules_antlr bug fixes${NC}"
echo "================================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if we're in the main repository (not already in a worktree)
if [ -f .git ] && grep -q "gitdir:" .git; then
    echo -e "${RED}❌ Error: Already in a worktree. Run this from the main repository${NC}"
    exit 1
fi

# Ensure we're on main branch and up to date
echo -e "${YELLOW}📍 Ensuring main branch is up to date...${NC}"
git checkout main
git pull origin main

# Create parent directory for worktrees
WORKTREE_DIR="../../rules_antlr-worktrees"
mkdir -p "$WORKTREE_DIR"

echo -e "${BLUE}📁 Creating worktrees in: $WORKTREE_DIR${NC}"

# Function to create worktree with error handling
create_worktree() {
    local branch_name="$1"
    local dir_name="$2"
    local description="$3"
    local priority="$4"
    
    local full_path="$WORKTREE_DIR/$dir_name"
    
    echo -e "${YELLOW}Creating worktree: $dir_name${NC}"
    echo "  Branch: $branch_name"
    echo "  Description: $description"
    echo "  Priority: $priority"
    
    if [ -d "$full_path" ]; then
        echo -e "${YELLOW}  ⚠️  Directory already exists, skipping...${NC}"
        return
    fi
    
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo -e "${YELLOW}  ⚠️  Branch $branch_name already exists, using existing branch${NC}"
        git worktree add "$full_path" "$branch_name"
    else
        git worktree add "$full_path" -b "$branch_name"
    fi
    
    # Copy TODO.md to each worktree for reference
    if [ -f ".agents/TODO.md" ]; then
        cp ".agents/TODO.md" "$full_path/"
    elif [ -f "TODO.md" ]; then
        cp "TODO.md" "$full_path/"
    else
        echo -e "${YELLOW}  ⚠️  TODO.md not found in current or .agents directory${NC}"
    fi
    
    echo -e "${GREEN}  ✅ Created: $full_path${NC}"
    echo
}

echo -e "${BLUE}🔴 PHASE 1: Critical NPE Vulnerabilities (Parallel Execution)${NC}"
echo "These can run simultaneously without conflicts:"

create_worktree "fix/npe-environment-variables" "npe-env" \
    "Environment Variable NPE Fixes (AntlrRules.java main method)" "CRITICAL"

create_worktree "fix/npe-builder-parameters" "npe-builder" \
    "Builder Method Parameter NPE Fixes" "CRITICAL"

create_worktree "fix/npe-language-path-conversion" "npe-language" \
    "Language Path Conversion NPE Fixes" "CRITICAL"

create_worktree "fix/npe-utility-methods" "npe-utility" \
    "Utility Method NPE Fixes" "CRITICAL"

echo -e "${BLUE}🟠 PHASE 2: High Priority Bazel Fixes (Parallel Execution)${NC}"
echo "These can run after Phase 1 or in parallel:"

create_worktree "fix/bazel-dict-access" "bazel-dict" \
    "Bazel Starlark Dictionary Access Fix" "HIGH"

create_worktree "fix/bazel-string-methods" "bazel-string" \
    "Bazel String Method Fix" "HIGH"

echo -e "${BLUE}🟡 PHASE 3: Medium Priority Resource Fixes (Parallel Execution)${NC}"
echo "These can run in parallel with other phases:"

create_worktree "fix/process-stream-leaks" "resource-process" \
    "Process Stream Resource Leak Fixes" "MEDIUM"

create_worktree "fix/file-stream-leaks" "resource-file" \
    "File Stream Resource Leak Fixes" "MEDIUM"

echo -e "${BLUE}🟢 PHASE 4: Quality Improvements (Lower Priority)${NC}"
echo "These can run after critical fixes:"

create_worktree "fix/array-bounds-safety" "safety-bounds" \
    "Array Bounds Safety Improvements" "MEDIUM"

create_worktree "fix/error-message-quality" "quality-messages" \
    "Error Message Quality Improvements" "LOW"

echo
echo -e "${GREEN}🎉 Worktree setup complete!${NC}"
echo "================================================="

# Display created worktrees
echo -e "${BLUE}📋 Created Worktrees:${NC}"
git worktree list | grep "$WORKTREE_DIR" | while read -r line; do
    echo "  $line"
done

echo
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Run parallel Claude sessions with: ./run-parallel-claude.sh"
echo "2. Or manually start Claude in each worktree:"
echo
echo -e "${YELLOW}   Critical NPE Fixes (run these first in parallel):${NC}"
echo "   cd \"$WORKTREE_DIR/npe-env\" && claude          # TODO-001"
echo "   cd \"$WORKTREE_DIR/npe-builder\" && claude      # TODO-002" 
echo "   cd \"$WORKTREE_DIR/npe-language\" && claude     # TODO-003"
echo "   cd \"$WORKTREE_DIR/npe-utility\" && claude      # TODO-004"
echo
echo -e "${YELLOW}   High Priority Bazel Fixes:${NC}"
echo "   cd \"$WORKTREE_DIR/bazel-dict\" && claude       # TODO-005 [CANCELLED]"
echo "   cd \"$WORKTREE_DIR/bazel-string\" && claude     # TODO-006"
echo
echo -e "${YELLOW}   Resource Management Fixes:${NC}"
echo "   cd \"$WORKTREE_DIR/resource-process\" && claude # TODO-007"
echo "   cd \"$WORKTREE_DIR/resource-file\" && claude    # TODO-008"
echo
echo -e "${BLUE}💡 Tips:${NC}"
echo "• Use tmux/screen to manage multiple Claude sessions"
echo "• Each worktree has its own copy of TODO.md for reference"
echo "• Start with Phase 1 (Critical NPE fixes) for maximum impact"
echo "• Run ./merge-workflow.sh when ready to create PRs"
echo "• Run ./cleanup-worktrees.sh when finished"

echo
echo -e "${GREEN}✨ Ready for parallel multi-agent development!${NC}"