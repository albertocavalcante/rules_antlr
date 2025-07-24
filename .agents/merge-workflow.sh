#!/bin/bash

# rules_antlr Merge Workflow Coordination Script  
# Manages PR creation and merge coordination for parallel bug fixes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

WORKTREE_DIR="../../rules_antlr-worktrees"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is required for PR management${NC}"
    echo -e "${YELLOW}Install GitHub CLI:${NC}"
    echo "  macOS: brew install gh"
    echo "  Ubuntu: sudo apt install gh"
    echo "  Or download from: https://cli.github.com/"
    echo
    echo -e "${BLUE}Alternative: Manual PR creation${NC}"
    echo "Push branches manually and create PRs via GitHub web interface"
    exit 1
fi

# Function to check worktree status
check_worktree_status() {
    local worktree_path="$1"
    local branch_name="$2"
    local todo_id="$3"
    
    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}❌ Worktree not found: $worktree_path${NC}"
        return 1
    fi
    
    cd "$worktree_path"
    
    # Check if there are changes to commit
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  $todo_id has uncommitted changes${NC}"
        return 2
    fi
    
    # Check if branch is ahead of main
    local ahead=$(git rev-list --count main..$branch_name 2>/dev/null || echo "0")
    if [ "$ahead" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  $todo_id has no commits (nothing to merge)${NC}"
        return 3
    fi
    
    echo -e "${GREEN}✅ $todo_id ready ($ahead commits)${NC}"
    return 0
}

# Function to run tests in worktree
run_tests() {
    local worktree_path="$1"
    local todo_id="$2"
    
    echo -e "${BLUE}🧪 Running tests for $todo_id...${NC}"
    cd "$worktree_path"
    
    # Check if there's a test script or standard test command
    if [ -f "./ci.sh" ]; then
        echo "Running ./ci.sh..."
        if ! ./ci.sh; then
            echo -e "${RED}❌ Tests failed for $todo_id${NC}"
            return 1
        fi
    elif [ -f "BUILD.bazel" ]; then
        echo "Running bazel test..."
        if ! bazel test //...; then
            echo -e "${RED}❌ Bazel tests failed for $todo_id${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  No test command found, skipping tests${NC}"
    fi
    
    echo -e "${GREEN}✅ Tests passed for $todo_id${NC}"
    return 0
}

# Function to create PR
create_pr() {
    local worktree_path="$1"
    local branch_name="$2"
    local todo_id="$3"
    local title="$4"
    local description="$5"
    local priority="$6"
    
    echo -e "${PURPLE}📝 Creating PR for $todo_id...${NC}"
    cd "$worktree_path"
    
    # Push branch to origin
    git push -u origin "$branch_name"
    
    # Create PR body with structured information
    local pr_body="## $todo_id: $title

**Priority**: $priority
**Branch**: \`$branch_name\`

### Problem Description
$description

### Changes Made
<!-- Auto-generated commit list -->
$(git log --oneline main..$branch_name | sed 's/^/- /')

### Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] No regressions introduced

### Review Checklist
- [ ] Code follows project conventions
- [ ] Error handling is appropriate
- [ ] Documentation updated if needed
- [ ] Security implications reviewed

---
*This PR was generated as part of the multi-agent bug fixing workflow.*
*See TODO.md for detailed context and related issues.*

**Related TODO Items**: $todo_id
**Part of**: Multi-Agent Critical Bug Fixes Initiative"

    # Create the PR
    local pr_url
    pr_url=$(gh pr create \
        --title "$todo_id: $title" \
        --body "$pr_body" \
        --label "bug,automated-fix,$priority" \
        --assignee "@me")
    
    echo -e "${GREEN}✅ PR created: $pr_url${NC}"
    echo "$pr_url" >> ../../pr_urls.txt
    
    return 0
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [command]${NC}"
    echo
    echo "Commands:"
    echo "  status     - Check status of all worktrees"
    echo "  test       - Run tests in all worktrees with changes"
    echo "  critical   - Create PRs for critical NPE fixes (TODO-001 to TODO-004)"
    echo "  bazel      - Create PRs for Bazel compatibility fixes (TODO-005, TODO-006)"
    echo "  resource   - Create PRs for resource management fixes (TODO-007, TODO-008)"
    echo "  quality    - Create PRs for quality improvements (TODO-009, TODO-010)"
    echo "  all        - Create PRs for all completed fixes"
    echo "  list-prs   - List all created PRs"
    echo "  merge      - Interactive merge workflow (with dependency management)"
    echo
    echo "Examples:"
    echo "  $0 status       # Check what's ready to merge"
    echo "  $0 critical     # Create PRs for critical fixes"
    echo "  $0 all          # Create PRs for everything ready"
}

# Function to check all worktree status
check_all_status() {
    echo -e "${BLUE}📊 Checking status of all worktrees...${NC}"
    echo "================================================="
    
    local worktrees=(
        "npe-env:fix/npe-environment-variables:TODO-001:Critical"
        "npe-builder:fix/npe-builder-parameters:TODO-002:Critical"
        "npe-language:fix/npe-language-path-conversion:TODO-003:Critical"
        "npe-utility:fix/npe-utility-methods:TODO-004:Critical"
        "bazel-dict:fix/bazel-dict-access:TODO-005:High"
        "bazel-string:fix/bazel-string-methods:TODO-006:High"
        "resource-process:fix/process-stream-leaks:TODO-007:Medium"
        "resource-file:fix/file-stream-leaks:TODO-008:Medium"
        "safety-bounds:fix/array-bounds-safety:TODO-009:Medium"
        "quality-messages:fix/error-message-quality:TODO-010:Low"
    )
    
    local ready_count=0
    local not_ready_count=0
    
    for worktree_info in "${worktrees[@]}"; do
        IFS=':' read -r dir branch todo priority <<< "$worktree_info"
        local full_path="$WORKTREE_DIR/$dir"
        
        echo -e "${CYAN}Checking $todo ($priority priority)...${NC}"
        
        if check_worktree_status "$full_path" "$branch" "$todo"; then
            ((ready_count++))
        else
            ((not_ready_count++))
        fi
        echo
    done
    
    echo -e "${BLUE}📈 Summary:${NC}"
    echo -e "  Ready for PR: ${GREEN}$ready_count${NC}"
    echo -e "  Not ready: ${YELLOW}$not_ready_count${NC}"
}

# Function to create PRs for a specific phase
create_phase_prs() {
    local phase="$1"
    local phase_name="$2"
    
    echo -e "${PURPLE}🚀 Creating PRs for $phase_name...${NC}"
    echo "================================================="
    
    case "$phase" in
        "critical")
            local worktrees=(
                "npe-env:fix/npe-environment-variables:TODO-001:Environment Variable NPE Fixes:Critical NPE vulnerabilities in AntlrRules main method:critical"
                "npe-builder:fix/npe-builder-parameters:TODO-002:Builder Method Parameter NPE Fixes:NPE vulnerabilities in builder methods:critical"
                "npe-language:fix/npe-language-path-conversion:TODO-003:Language Path Conversion NPE Fixes:NPE vulnerabilities in Language enum methods:critical"
                "npe-utility:fix/npe-utility-methods:TODO-004:Utility Method NPE Fixes:NPE vulnerabilities in utility methods:critical"
            )
            ;;
        "bazel")
            local worktrees=(
                "bazel-dict:fix/bazel-dict-access:TODO-005:Bazel Starlark Dictionary Access Fix:Bazel 6.0+ compatibility issue with dict.keys() indexing:high"
                "bazel-string:fix/bazel-string-methods:TODO-006:Bazel String Method Fix:Non-existent .elems() method calls in Starlark:high"
            )
            ;;
        "resource")
            local worktrees=(
                "resource-process:fix/process-stream-leaks:TODO-007:Process Stream Resource Leak Fixes:Resource leaks in Command.java process handling:medium"
                "resource-file:fix/file-stream-leaks:TODO-008:File Stream Resource Leak Fixes:Resource leaks in TestWorkspace file handling:medium"
            )
            ;;
        "quality")
            local worktrees=(
                "safety-bounds:fix/array-bounds-safety:TODO-009:Array Bounds Safety Improvements:Array bounds checking in AntlrRules:medium"
                "quality-messages:fix/error-message-quality:TODO-010:Error Message Quality Improvements:Improve error message formatting:low"
            )
            ;;
    esac
    
    local created_count=0
    
    for worktree_info in "${worktrees[@]}"; do
        IFS=':' read -r dir branch todo title description priority <<< "$worktree_info"
        local full_path="$WORKTREE_DIR/$dir"
        
        echo -e "${CYAN}Processing $todo...${NC}"
        
        if check_worktree_status "$full_path" "$branch" "$todo"; then
            if run_tests "$full_path" "$todo"; then
                if create_pr "$full_path" "$branch" "$todo" "$title" "$description" "$priority"; then
                    ((created_count++))
                fi
            else
                echo -e "${RED}⚠️  Skipping PR creation due to test failures${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Skipping $todo (not ready)${NC}"
        fi
        echo
    done
    
    echo -e "${GREEN}✅ Created $created_count PRs for $phase_name${NC}"
}

# Main command processing
case "${1:-status}" in
    "status")
        check_all_status
        ;;
    
    "test")
        echo -e "${BLUE}🧪 Running tests in all worktrees...${NC}"
        # Implementation for running tests in all worktrees
        echo "Test functionality coming soon..."
        ;;
    
    "critical")
        create_phase_prs "critical" "Critical NPE Fixes"
        ;;
    
    "bazel")
        create_phase_prs "bazel" "Bazel Compatibility Fixes"
        ;;
    
    "resource")
        create_phase_prs "resource" "Resource Management Fixes"
        ;;
    
    "quality")
        create_phase_prs "quality" "Quality Improvements"
        ;;
    
    "all")
        echo -e "${PURPLE}🚀 Creating PRs for ALL completed fixes...${NC}"
        echo "================================================="
        create_phase_prs "critical" "Critical NPE Fixes"
        echo
        create_phase_prs "bazel" "Bazel Compatibility Fixes"
        echo
        create_phase_prs "resource" "Resource Management Fixes"
        echo
        create_phase_prs "quality" "Quality Improvements"
        ;;
    
    "list-prs")
        if [ -f "../../pr_urls.txt" ]; then
            echo -e "${BLUE}📋 Created PRs:${NC}"
            cat ../../pr_urls.txt
        else
            echo -e "${YELLOW}No PRs created yet${NC}"
        fi
        ;;
    
    "merge")
        echo -e "${BLUE}🔄 Interactive merge workflow coming soon...${NC}"
        echo "This will provide guided merge order with dependency management"
        ;;
    
    *)
        show_usage
        exit 1
        ;;
esac

echo
echo -e "${GREEN}✨ Merge workflow coordination complete!${NC}"

# Show helpful next steps
echo
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "• Review created PRs on GitHub"
echo "• Merge critical fixes first (TODO-001 to TODO-004)"
echo "• Run integration tests after each merge"
echo "• Use './merge-workflow.sh list-prs' to see all PR URLs"
echo "• Clean up worktrees with './cleanup-worktrees.sh' when done"