#!/bin/bash

# rules_antlr Multi-Agent Worktree Setup Script
# Creates git worktrees for parallel Claude Code development
# Now fully driven by todos.yaml configuration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'  
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load YAML utilities
source "$SCRIPT_DIR/yaml-utils.sh"

echo -e "${BLUE}🚀 Setting up YAML-driven multi-agent worktrees${NC}"
echo "================================================="

# Initialize YAML utilities
init_yaml_utils "$SCRIPT_DIR/todos.yaml"

# Exit if YAML is not available
if ! require_yaml; then
    echo -e "${BLUE}Alternative: Manual worktree creation${NC}"
    echo "Check todos.yaml for git.branch and git.worktree_dir values"
    exit 1
fi

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

# Read configuration from YAML
echo -e "${CYAN}📖 Reading configuration from todos.yaml...${NC}"
WORKTREE_BASE_DIR=$(get_config "worktree_base_dir")
DEFAULT_BRANCH=$(get_config "default_branch_base")

# Ensure we're on main branch and up to date
echo -e "${YELLOW}📍 Ensuring $DEFAULT_BRANCH branch is up to date...${NC}"

# Fetch latest changes from remote
echo -e "  Fetching latest changes from remote..."
if ! git fetch origin "$DEFAULT_BRANCH"; then
    echo -e "${RED}❌ Error: Failed to fetch from remote${NC}"
    echo -e "${YELLOW}💡 This might be due to network issues or authentication problems${NC}"
    exit 1
fi

# Switch to default branch
echo -e "  Switching to $DEFAULT_BRANCH branch..."
if ! git checkout "$DEFAULT_BRANCH"; then
    echo -e "${RED}❌ Error: Failed to checkout $DEFAULT_BRANCH branch${NC}"
    echo -e "${YELLOW}💡 Make sure you have no uncommitted changes or use 'git stash' first${NC}"
    exit 1
fi

# Update local branch with remote changes
echo -e "  Updating $DEFAULT_BRANCH with remote changes..."
local_commit=$(git rev-parse HEAD)
remote_commit=$(git rev-parse "origin/$DEFAULT_BRANCH")

if [ "$local_commit" != "$remote_commit" ]; then
    echo -e "  ${CYAN}Local and remote branches differ, updating...${NC}"
    if ! git pull origin "$DEFAULT_BRANCH"; then
        echo -e "${RED}❌ Error: Failed to pull changes from remote${NC}"
        echo -e "${YELLOW}💡 This might be due to merge conflicts or force-push scenarios${NC}"
        echo -e "${YELLOW}💡 Consider using 'git reset --hard origin/$DEFAULT_BRANCH' if you want to discard local changes${NC}"
        exit 1
    fi
else
    echo -e "  ${GREEN}✅ $DEFAULT_BRANCH is already up to date${NC}"
fi

# Create parent directory for worktrees (use absolute path for robustness)
REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKTREE_DIR="${REPO_ROOT}/${WORKTREE_BASE_DIR}"
mkdir -p "$WORKTREE_DIR"

echo -e "${BLUE}📁 Creating worktrees in: $WORKTREE_DIR${NC}"

# Function to create worktree with error handling
create_worktree() {
    local todo_id="$1"
    local title="$2"
    local branch_name="$3"
    local dir_name="$4"
    local priority="$5"
    local phase="$6"
    
    local full_path="$WORKTREE_DIR/$dir_name"
    
    echo -e "${YELLOW}Creating worktree: $dir_name${NC}"
    echo "  TODO: $todo_id"
    echo "  Title: $title"
    echo "  Branch: $branch_name"
    echo "  Priority: $priority"
    echo "  Phase: $phase"
    
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
    
    # Copy todos.yaml to each worktree for reference
    if [ -f "$TODOS_YAML" ]; then
        cp "$TODOS_YAML" "$full_path/"
    fi
    
    # Also copy legacy TODO.md if it exists for backwards compatibility
    if [ -f ".agents/TODO.md" ]; then
        cp ".agents/TODO.md" "$full_path/"
    elif [ -f "TODO.md" ]; then
        cp "TODO.md" "$full_path/"
    fi
    
    echo -e "${GREEN}  ✅ Created: $full_path${NC}"
    echo
}

# Function to get phase color/emoji from YAML
get_phase_info() {
    local phase_name="$1"
    local info_type="$2"  # "color", "emoji", "name", "description"
    
    yq eval ".phases.${phase_name}.${info_type}" "$TODOS_YAML"
}

# Function to create worktrees for a specific phase
create_phase_worktrees() {
    local phase_name="$1"
    
    local phase_display_name=$(get_phase_info "$phase_name" "name")
    local phase_description=$(get_phase_info "$phase_name" "description")
    local phase_emoji=$(get_phase_info "$phase_name" "emoji")
    local phase_parallel=$(yq eval ".phases.${phase_name}.parallel" "$TODOS_YAML")
    
    echo -e "${BLUE}${phase_emoji} PHASE: ${phase_display_name}${NC}"
    echo "Description: $phase_description"
    if [ "$phase_parallel" = "true" ]; then
        echo "Execution: Parallel (can run simultaneously)"
    else
        echo "Execution: Sequential"
    fi
    echo
    
    # Get all TODOs for this phase
    local todo_count=0
    while IFS= read -r todo_index; do
        # Skip if no todos found
        if [ "$todo_index" = "null" ] || [ -z "$todo_index" ]; then
            continue
        fi
        
        local todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
        local todo_title=$(yq eval ".todos[${todo_index}].title" "$TODOS_YAML")
        local todo_status=$(yq eval ".todos[${todo_index}].status // \"active\"" "$TODOS_YAML")
        local branch_name=$(yq eval ".todos[${todo_index}].git.branch" "$TODOS_YAML")
        local worktree_dir=$(yq eval ".todos[${todo_index}].git.worktree_dir" "$TODOS_YAML")
        local priority=$(yq eval ".todos[${todo_index}].priority" "$TODOS_YAML")
        
        # Skip cancelled TODOs
        if [ "$todo_status" = "cancelled" ]; then
            echo -e "${YELLOW}⚠️  Skipping $todo_id: CANCELLED${NC}"
            echo "   Reason: $(yq eval ".todos[${todo_index}].cancellation_reason // \"See YAML for details\"" "$TODOS_YAML")"
            echo
            continue
        fi
        
        create_worktree "$todo_id" "$todo_title" "$branch_name" "$worktree_dir" "$priority" "$phase_name"
        ((todo_count++))
        
    done < <(yq eval ".todos | to_entries | map(select(.value.phase == \"$phase_name\")) | .[].key" "$TODOS_YAML")
    
    if [ $todo_count -eq 0 ]; then
        echo -e "${YELLOW}  No active TODOs found for phase: $phase_name${NC}"
        echo
    fi
}

# Create worktrees for all phases dynamically from YAML
echo -e "${CYAN}📋 Creating worktrees for all phases...${NC}"
echo

# Get all phase names from YAML and create worktrees in priority order
while IFS= read -r phase_name; do
    if [ "$phase_name" != "null" ] && [ -n "$phase_name" ]; then
        create_phase_worktrees "$phase_name"
    fi
done < <(yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML")

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

# Generate next steps dynamically from YAML
generate_next_steps() {
    local phase_name="$1"
    
    local phase_display_name=$(get_phase_info "$phase_name" "name")
    local phase_emoji=$(get_phase_info "$phase_name" "emoji")
    
    echo -e "${YELLOW}   ${phase_emoji} ${phase_display_name}:${NC}"
    
    # Get all active TODOs for this phase
    while IFS= read -r todo_index; do
        if [ "$todo_index" = "null" ] || [ -z "$todo_index" ]; then
            continue
        fi
        
        local todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
        local todo_status=$(yq eval ".todos[${todo_index}].status // \"active\"" "$TODOS_YAML")
        local worktree_dir=$(yq eval ".todos[${todo_index}].git.worktree_dir" "$TODOS_YAML")
        
        if [ "$todo_status" = "cancelled" ]; then
            echo "   # $todo_id [CANCELLED] - $(yq eval ".todos[${todo_index}].cancellation_reason // \"See YAML for details\"" "$TODOS_YAML")"
        else
            echo "   cd \"$WORKTREE_DIR/$worktree_dir\" && claude     # $todo_id"
        fi
        
    done < <(yq eval ".todos | to_entries | map(select(.value.phase == \"$phase_name\")) | .[].key" "$TODOS_YAML")
    echo
}

# Generate next steps for all phases in priority order
while IFS= read -r phase_name; do
    if [ "$phase_name" != "null" ] && [ -n "$phase_name" ]; then
        generate_next_steps "$phase_name"
    fi
done < <(yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML")

echo -e "${BLUE}💡 Tips:${NC}"
echo "• Use tmux/screen to manage multiple Claude sessions"
echo "• Each worktree has its own copy of todos.yaml for reference"
echo "• Start with highest priority phase for maximum impact"
echo "• Run ./merge-workflow.sh when ready to create PRs"
echo "• Run ./cleanup-worktrees.sh when finished"
echo "• Check todos.yaml for detailed agent prompts and fix strategies"

echo
echo -e "${GREEN}✨ Ready for YAML-driven parallel multi-agent development!${NC}"