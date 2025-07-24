#!/bin/bash

# rules_antlr Merge Workflow Coordination Script  
# Manages PR creation and merge coordination for parallel bug fixes
# Now fully driven by todos.yaml configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODOS_YAML="$SCRIPT_DIR/todos.yaml"

# Use absolute path for robustness across different execution contexts
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)/..")"

# Check if yq is available for YAML parsing
if ! command -v yq &> /dev/null; then
    echo -e "${RED}❌ Error: yq is required for YAML parsing${NC}"
    echo -e "${YELLOW}Install yq:${NC}"
    echo "  macOS: brew install yq"
    echo "  Ubuntu: sudo apt-get install yq"
    echo "  Arch: sudo pacman -S yq"
    echo "  Or download from: https://github.com/mikefarah/yq/releases"
    exit 1
fi

# Check if todos.yaml exists and is valid
if [ ! -f "$TODOS_YAML" ]; then
    echo -e "${RED}❌ Error: todos.yaml not found at $TODOS_YAML${NC}"
    exit 1
fi

if ! yq eval '.' "$TODOS_YAML" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Invalid YAML syntax in todos.yaml${NC}"
    exit 1
fi

# Read configuration from YAML
WORKTREE_BASE_DIR=$(yq eval '.config.worktree_base_dir' "$TODOS_YAML")
WORKTREE_DIR="${REPO_ROOT}/${WORKTREE_BASE_DIR}"

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

# Function to check worktree status from YAML data
check_worktree_status() {
    local todo_index="$1"
    
    # Extract data from YAML
    local todo_id
    local todo_status
    local branch_name
    local worktree_dir
    
    todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
    todo_status=$(yq eval ".todos[${todo_index}].status // \"active\"" "$TODOS_YAML")
    branch_name=$(yq eval ".todos[${todo_index}].git.branch" "$TODOS_YAML")
    worktree_dir=$(yq eval ".todos[${todo_index}].git.worktree_dir" "$TODOS_YAML")
    
    local worktree_path="$WORKTREE_DIR/$worktree_dir"
    
    # Skip cancelled TODOs
    if [ "$todo_status" = "cancelled" ]; then
        echo -e "${YELLOW}⚠️  $todo_id: CANCELLED${NC}"
        echo "   Reason: $(yq eval ".todos[${todo_index}].cancellation_reason // \"See YAML for details\"" "$TODOS_YAML")"
        return 4
    fi
    
    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}❌ Worktree not found: $worktree_path${NC}"
        return 1
    fi
    
    # Check if there are changes to commit
    if ! (cd "$worktree_path" && git diff --quiet && git diff --cached --quiet); then
        echo -e "${YELLOW}⚠️  $todo_id has uncommitted changes${NC}"
        return 2
    fi
    
    # Check if branch is ahead of main
    local default_branch
    local ahead
    
    default_branch=$(yq eval '.config.default_branch_base' "$TODOS_YAML")
    if ! ahead=$(cd "$worktree_path" && git rev-list --count "${default_branch}..$branch_name" 2>/dev/null); then
        ahead=0
    fi
    if [ "$ahead" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  $todo_id has no commits (nothing to merge)${NC}"
        return 3
    fi
    
    echo -e "${GREEN}✅ $todo_id ready ($ahead commits)${NC}"
    return 0
}

# Function to run tests in worktree using YAML data
run_tests() {
    local todo_index="$1"
    
    # Extract data from YAML
    local todo_id
    local worktree_dir
    
    todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
    worktree_dir=$(yq eval ".todos[${todo_index}].git.worktree_dir" "$TODOS_YAML")
    local worktree_path="$WORKTREE_DIR/$worktree_dir"
    
    echo -e "${BLUE}🧪 Running tests for $todo_id...${NC}"
    
    # Check if there's a test script or standard test command
    if [ -f "$worktree_path/ci.sh" ]; then
        echo "Running ./ci.sh..."
        if ! (cd "$worktree_path" && ./ci.sh); then
            echo -e "${RED}❌ Tests failed for $todo_id${NC}"
            return 1
        fi
    elif [ -f "$worktree_path/BUILD.bazel" ]; then
        echo "Running bazel test..."
        if ! (cd "$worktree_path" && bazel test //...); then
            echo -e "${RED}❌ Bazel tests failed for $todo_id${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  No test command found, skipping tests${NC}"
    fi
    
    echo -e "${GREEN}✅ Tests passed for $todo_id${NC}"
    return 0
}

# Function to create PR using YAML data
create_pr() {
    local todo_index="$1"
    
    # Extract data from YAML
    local todo_id
    local todo_title
    local todo_description
    local branch_name
    local worktree_dir
    local priority
    local phase
    
    todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
    todo_title=$(yq eval ".todos[${todo_index}].title" "$TODOS_YAML")
    todo_description=$(yq eval ".todos[${todo_index}].description" "$TODOS_YAML")
    branch_name=$(yq eval ".todos[${todo_index}].git.branch" "$TODOS_YAML")
    worktree_dir=$(yq eval ".todos[${todo_index}].git.worktree_dir" "$TODOS_YAML")
    priority=$(yq eval ".todos[${todo_index}].priority" "$TODOS_YAML")
    phase=$(yq eval ".todos[${todo_index}].phase" "$TODOS_YAML")
    
    local worktree_path="$WORKTREE_DIR/$worktree_dir"
    
    echo -e "${PURPLE}📝 Creating PR for $todo_id...${NC}"
    
    # Push branch to origin
    (cd "$worktree_path" && git push -u origin "$branch_name")
    
    # Create PR body with structured information
    local default_branch
    local pr_body
    
    default_branch=$(yq eval '.config.default_branch_base' "$TODOS_YAML")
    pr_body="## $todo_id: $todo_title

**Priority**: $priority
**Phase**: $phase
**Branch**: \`$branch_name\`

### Problem Description
$todo_description

### Changes Made
<!-- Auto-generated commit list -->
$(cd "$worktree_path" && git log --oneline "${default_branch}".."$branch_name" | sed 's/^/- /')

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
*This PR was generated as part of the YAML-driven multi-agent bug fixing workflow.*
*See todos.yaml for detailed context, agent prompts, and fix strategies.*

**Related TODO Items**: $todo_id
**Part of**: Multi-Agent Critical Bug Fixes Initiative (Phase: $phase)"

    # Create the PR
    local pr_url
    pr_url=$(gh pr create \
        --title "$todo_id: $todo_title" \
        --body "$pr_body" \
        --label "bug,automated-fix,$priority" \
        --assignee "@me")
    
    echo -e "${GREEN}✅ PR created: $pr_url${NC}"
    echo "$pr_url" >> "${REPO_ROOT}/.agents/pr_urls.txt"
    
    return 0
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [command]${NC}"
    echo
    echo "Commands:"
    echo "  status     - Check status of all worktrees"
    echo "  test       - Run tests in all worktrees with changes"
    
    # Dynamically generate phase commands from YAML
    while IFS= read -r phase_name; do
        if [ "$phase_name" != "null" ] && [ -n "$phase_name" ]; then
            local phase_display_name
            phase_display_name=$(yq eval ".phases.${phase_name}.name" "$TODOS_YAML")
            local phase_emoji
            phase_emoji=$(yq eval ".phases.${phase_name}.emoji" "$TODOS_YAML")
            echo "  $phase_name  - $phase_emoji Create PRs for $phase_display_name"
        fi
    done < <(yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML")
    
    echo "  all        - Create PRs for all completed fixes"
    echo "  list-prs   - List all created PRs"
    echo "  merge      - Interactive merge workflow (with dependency management)"
    echo
    echo "Examples:"
    echo "  $0 status       # Check what's ready to merge"
    local first_phase
    first_phase=$(yq eval '.phases | to_entries | sort_by(.value.priority) | .[0].key' "$TODOS_YAML")
    echo "  $0 $first_phase     # Create PRs for highest priority phase"
    echo "  $0 all          # Create PRs for everything ready"
}

# Function to check all worktree status using YAML data
check_all_status() {
    echo -e "${BLUE}📊 Checking status of all worktrees from YAML...${NC}"
    echo "================================================="
    
    local ready_count=0
    local not_ready_count=0
    local cancelled_count=0
    
    # Check status of all TODOs
    local total_todos
    total_todos=$(yq eval '.todos | length' "$TODOS_YAML")
    for (( i=0; i<total_todos; i++ )); do
        local todo_id
        todo_id=$(yq eval ".todos[${i}].id" "$TODOS_YAML")
        local priority
        priority=$(yq eval ".todos[${i}].priority" "$TODOS_YAML")
        
        echo -e "${CYAN}Checking $todo_id ($priority priority)...${NC}"
        
        local status_result
        check_worktree_status "$i"
        status_result=$?
        
        case $status_result in
            0)
                ((ready_count++))
                ;;
            4)
                ((cancelled_count++))
                ;;
            *)
                ((not_ready_count++))
                ;;
        esac
        echo
    done
    
    echo -e "${BLUE}📈 Summary:${NC}"
    echo -e "  Ready for PR: ${GREEN}$ready_count${NC}"
    echo -e "  Not ready: ${YELLOW}$not_ready_count${NC}"
    echo -e "  Cancelled: ${PURPLE}$cancelled_count${NC}"
}

# Function to create PRs for a specific phase using YAML data
create_phase_prs() {
    local phase_name="$1"
    
    # Get phase information from YAML
    local phase_display_name
    phase_display_name=$(yq eval ".phases.${phase_name}.name" "$TODOS_YAML")
    local phase_emoji
    phase_emoji=$(yq eval ".phases.${phase_name}.emoji" "$TODOS_YAML")
    
    if [ "$phase_display_name" = "null" ]; then
        echo -e "${RED}❌ Error: Unknown phase '$phase_name'${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}🚀 Creating PRs for ${phase_emoji} ${phase_display_name}...${NC}"
    echo "================================================="
    
    local created_count=0
    local skipped_count=0
    
    # Get all TODOs for this phase and create PRs
    while IFS= read -r todo_index; do
        if [ "$todo_index" != "null" ] && [ -n "$todo_index" ]; then
            local todo_id
            todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
            
            echo -e "${CYAN}Processing $todo_id...${NC}"
            
            # Check worktree status
            local status_result
            check_worktree_status "$todo_index"
            status_result=$?
            
            case $status_result in
                0)
                    # Ready - run tests and create PR
                    if run_tests "$todo_index"; then
                        if create_pr "$todo_index"; then
                            ((created_count++))
                        fi
                    else
                        echo -e "${RED}⚠️  Skipping PR creation due to test failures${NC}"
                        ((skipped_count++))
                    fi
                    ;;
                4)
                    # Cancelled - already handled in check_worktree_status
                    ((skipped_count++))
                    ;;
                *)
                    # Not ready
                    echo -e "${YELLOW}⚠️  Skipping $todo_id (not ready)${NC}"
                    ((skipped_count++))
                    ;;
            esac
            echo
        fi
    done < <(yq eval ".todos | to_entries | map(select(.value.phase == \"$phase_name\")) | .[].key" "$TODOS_YAML")
    
    echo -e "${GREEN}✅ Created $created_count PRs for $phase_display_name${NC}"
    if [ $skipped_count -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Skipped $skipped_count TODOs${NC}"
    fi
}

# Main command processing
case "${1:-status}" in
    "status")
        check_all_status
        ;;
    
    "test")
        echo -e "${BLUE}🧪 Running tests in all worktrees...${NC}"
        echo "Running tests for all TODOs with worktrees..."
        echo "================================================="
        
        total_todos=$(yq eval '.todos | length' "$TODOS_YAML")
        for (( i=0; i<total_todos; i++ )); do
            todo_id=$(yq eval ".todos[${i}].id" "$TODOS_YAML")
            todo_status=$(yq eval ".todos[${i}].status // \"active\"" "$TODOS_YAML")
            worktree_dir=$(yq eval ".todos[${i}].git.worktree_dir" "$TODOS_YAML")
            
            if [ "$todo_status" != "cancelled" ] && [ -d "$WORKTREE_DIR/$worktree_dir" ]; then
                echo -e "${CYAN}Testing $todo_id...${NC}"
                run_tests "$i"
                echo
            fi
        done
        ;;
    
    "all")
        echo -e "${PURPLE}🚀 Creating PRs for ALL completed fixes...${NC}"
        echo "================================================="
        
        # Create PRs for all phases in priority order
        while IFS= read -r phase_name; do
            if [ "$phase_name" != "null" ] && [ -n "$phase_name" ]; then
                create_phase_prs "$phase_name"
                echo
            fi
        done < <(yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML")
        ;;
    
    "list-prs")
        if [ -f "${REPO_ROOT}/.agents/pr_urls.txt" ]; then
            echo -e "${BLUE}📋 Created PRs:${NC}"
            cat "${REPO_ROOT}/.agents/pr_urls.txt"
        else
            echo -e "${YELLOW}No PRs created yet${NC}"
        fi
        ;;
    
    "merge")
        echo -e "${BLUE}🔄 Interactive merge workflow coming soon...${NC}"
        echo "This will provide guided merge order with dependency management"
        ;;
    
    *)
        # Check if it's a valid phase name
        if yq eval ".phases | has(\"$1\")" "$TODOS_YAML" | grep -q "true"; then
            create_phase_prs "$1"
        else
            echo -e "${RED}❌ Error: Unknown command or phase '$1'${NC}"
            echo
            show_usage
            exit 1
        fi
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