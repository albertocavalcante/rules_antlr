#!/bin/bash

# rules_antlr Parallel Claude Code Session Launcher
# Starts multiple Claude sessions in tmux for parallel development
# Now fully driven by todos.yaml configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
TMUX_SESSION_PREFIX=$(yq eval '.config.tmux_session_prefix' "$TODOS_YAML")

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ Error: tmux is required for parallel sessions${NC}"
    echo -e "${YELLOW}Install tmux:${NC}"
    echo "  macOS: brew install tmux"
    echo "  Ubuntu: sudo apt-get install tmux"
    echo "  Fedora: sudo dnf install tmux"
    echo
    echo -e "${BLUE}Alternative: Manual execution${NC}"
    echo "Open multiple terminals and run claude in each worktree:"
    echo "Check todos.yaml for worktree paths or run ./setup-worktrees.sh to see directories"
    exit 1
fi

# Check if worktrees exist
if [ ! -d "$WORKTREE_DIR" ]; then
    echo -e "${RED}❌ Error: Worktrees not found. Run ./setup-worktrees.sh first${NC}"
    exit 1
fi

# Function to create tmux session with Claude from YAML data
create_claude_session() {
    local todo_index="$1"
    
    # Extract data from YAML
    local todo_id
    todo_id=$(yq eval ".todos[${todo_index}].id" "$TODOS_YAML")
    local todo_title
    todo_title=$(yq eval ".todos[${todo_index}].title" "$TODOS_YAML")
    local todo_status
    todo_status=$(yq eval ".todos[${todo_index}].status // \"active\"" "$TODOS_YAML")
    local session_name
    session_name=$(yq eval ".todos[${todo_index}].git.tmux_session" "$TODOS_YAML")
    local worktree_dir
    worktree_dir=$(yq eval ".todos[${todo_index}].git.worktree_dir" "$TODOS_YAML")
    local agent_prompt
    agent_prompt=$(yq eval ".todos[${todo_index}].agent_prompt" "$TODOS_YAML")
    local priority
    priority=$(yq eval ".todos[${todo_index}].priority" "$TODOS_YAML")
    
    local worktree_path="$WORKTREE_DIR/$worktree_dir"
    
    # Skip cancelled TODOs
    if [ "$todo_status" = "cancelled" ]; then
        echo -e "${YELLOW}⚠️  Skipping $todo_id: CANCELLED${NC}"
        echo "   Reason: $(yq eval ".todos[${todo_index}].cancellation_reason // \"See YAML for details\"" "$TODOS_YAML")"
        echo
        return 0
    fi
    
    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}❌ Worktree not found: $worktree_path${NC}"
        echo "   Run ./setup-worktrees.sh first to create worktrees"
        return 1
    fi
    
    echo -e "${CYAN}🚀 Starting Claude session: $session_name${NC}"
    echo "   TODO: $todo_id ($priority priority)"
    echo "   Title: $todo_title"
    echo "   Worktree: $worktree_path"
    
    # Kill existing session if it exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "   ${YELLOW}Killing existing session: $session_name${NC}"
        tmux kill-session -t "$session_name" 2>/dev/null || true
        sleep 1  # Give time for cleanup
    fi
    
    # Create new session with error handling
    if ! tmux new-session -d -s "$session_name" -c "$worktree_path"; then
        echo -e "${RED}❌ Failed to create tmux session: $session_name${NC}"
        return 1
    fi
    
    # Send comprehensive context as comments for reference
    tmux send-keys -t "$session_name" "# $todo_id: $todo_title ($priority priority)" Enter
    tmux send-keys -t "$session_name" "# Working directory: $worktree_path" Enter
    tmux send-keys -t "$session_name" "# Reference: Check todos.yaml for full agent prompt and fix strategy" Enter
    tmux send-keys -t "$session_name" "# " Enter
    
    # Send a shortened version of the agent prompt as a comment (first few lines)
    local prompt_preview
    prompt_preview=$(echo "$agent_prompt" | head -3 | sed 's/^/# /')
    echo "$prompt_preview" | while IFS= read -r line; do
        tmux send-keys -t "$session_name" "$line" Enter
    done
    
    tmux send-keys -t "$session_name" "# [... see todos.yaml for complete prompt]" Enter
    tmux send-keys -t "$session_name" "" Enter
    
    # Start Claude
    tmux send-keys -t "$session_name" "claude" Enter
    
    echo -e "${GREEN}   ✅ Session started: tmux attach -t $session_name${NC}"
    echo
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [phase]${NC}"
    echo
    echo "Phases (from todos.yaml):"
    
    # Dynamically generate phase list from YAML
    while IFS= read -r phase_name; do
        if [ "$phase_name" != "null" ] && [ -n "$phase_name" ]; then
            local phase_display_name
            phase_display_name=$(yq eval ".phases.${phase_name}.name" "$TODOS_YAML")
            local phase_emoji
            phase_emoji=$(yq eval ".phases.${phase_name}.emoji" "$TODOS_YAML")
            local phase_description
            phase_description=$(yq eval ".phases.${phase_name}.description" "$TODOS_YAML")
            local active_todos
            active_todos=$(yq eval ".todos | map(select(.phase == \"$phase_name\" and (.status // \"active\") != \"cancelled\")) | length" "$TODOS_YAML")
            
            echo "  $phase_name  - $phase_emoji $phase_display_name ($active_todos TODOs)"
            echo "           $phase_description"
        fi
    done < <(yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML")
    
    echo
    echo "Special commands:"
    echo "  all       - Start ALL active sessions (high resource usage)"
    echo "  status    - Show running sessions"  
    echo "  kill      - Kill all Claude sessions"
    echo
    echo "Examples:"
    local first_phase
    first_phase=$(yq eval '.phases | to_entries | sort_by(.value.priority) | .[0].key' "$TODOS_YAML")
    echo "  $0 $first_phase    # Start highest priority phase"
    echo "  $0 all         # Start all active sessions"
    echo "  $0 status      # Check which sessions are running"
}

# Function to show session status
show_status() {
    echo -e "${BLUE}🔍 Active Claude Code Sessions:${NC}"
    echo "================================="
    
    local session_prefix="$TMUX_SESSION_PREFIX"
    
    if ! tmux list-sessions 2>/dev/null | grep -E "^${session_prefix}"; then
        echo -e "${YELLOW}No Claude sessions running${NC}"
        return
    fi
    
    echo
    echo -e "${BLUE}💡 Attach to sessions:${NC}"
    tmux list-sessions 2>/dev/null | grep -E "^${session_prefix}" | while read -r session; do
        session_name=$(echo "$session" | cut -d: -f1)
        echo "  tmux attach -t $session_name"
    done
}

# Function to kill all Claude sessions
kill_sessions() {
    echo -e "${YELLOW}🛑 Killing all Claude Code sessions...${NC}"
    
    local session_prefix="$TMUX_SESSION_PREFIX"
    local sessions_killed=0
    
    # Find all sessions with our prefix and kill them
    while IFS= read -r session_name; do
        if [ -n "$session_name" ]; then
            echo -e "   Killing session: ${session_name}"
            if tmux kill-session -t "$session_name" 2>/dev/null; then
                ((sessions_killed++))
            else
                echo -e "   ${YELLOW}⚠️  Failed to kill session: $session_name${NC}"
            fi
        fi
    done < <(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${session_prefix}" || true)
    
    if [ $sessions_killed -gt 0 ]; then
        echo -e "${GREEN}✅ Killed $sessions_killed Claude sessions${NC}"
    else
        echo -e "${YELLOW}No active Claude sessions found${NC}"
    fi
}

# Function to start sessions for a specific phase
start_phase_sessions() {
    local phase_name="$1"
    
    # Get phase information from YAML
    local phase_display_name
    phase_display_name=$(yq eval ".phases.${phase_name}.name" "$TODOS_YAML")
    local phase_description
    phase_description=$(yq eval ".phases.${phase_name}.description" "$TODOS_YAML")
    local phase_emoji
    phase_emoji=$(yq eval ".phases.${phase_name}.emoji" "$TODOS_YAML")
    local phase_parallel
    phase_parallel=$(yq eval ".phases.${phase_name}.parallel" "$TODOS_YAML")
    
    if [ "$phase_display_name" = "null" ]; then
        echo -e "${RED}❌ Error: Unknown phase '$phase_name'${NC}"
        echo "Use '$0' without arguments to see available phases"
        return 1
    fi
    
    echo -e "${BLUE}${phase_emoji} STARTING ${phase_display_name^^}${NC}"
    echo "Description: $phase_description"
    if [ "$phase_parallel" = "true" ]; then
        echo "Execution: Parallel sessions"
    else
        echo "Execution: Sequential sessions"
    fi
    echo "================================================="
    
    # Get all TODOs for this phase and start sessions
    local session_count=0
    while IFS= read -r todo_index; do
        if [ "$todo_index" != "null" ] && [ -n "$todo_index" ]; then
            create_claude_session "$todo_index"
            ((session_count++))
            
            # Add delay between sessions if parallel execution
            if [ "$phase_parallel" = "true" ] && [ $session_count -gt 0 ]; then
                sleep 2
            fi
        fi
    done < <(yq eval ".todos | to_entries | map(select(.value.phase == \"$phase_name\")) | .[].key" "$TODOS_YAML")
    
    if [ $session_count -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No active TODOs found for phase: $phase_name${NC}"
    else
        echo -e "${GREEN}✅ Started $session_count Claude sessions for $phase_display_name${NC}"
    fi
}

# Parse command line arguments
# Default to first phase by priority if no argument provided
DEFAULT_PHASE=$(yq eval '.phases | to_entries | sort_by(.value.priority) | .[0].key' "$TODOS_YAML")
PHASE="${1:-$DEFAULT_PHASE}"

case "$PHASE" in
    "all")
        echo -e "${BLUE}🚀 STARTING ALL PARALLEL SESSIONS${NC}"
        total_todos=$(yq eval '.todos | map(select((.status // "active") != "cancelled")) | length' "$TODOS_YAML")
        echo -e "${RED}⚠️  Warning: This will start $total_todos Claude sessions simultaneously!${NC}"
        echo -e "${YELLOW}High resource usage - ensure you have sufficient RAM/CPU${NC}"
        echo "================================================="
        
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
        
        # Start all phases in priority order
        while IFS= read -r phase_name; do
            if [ "$phase_name" != "null" ] && [ -n "$phase_name" ]; then
                start_phase_sessions "$phase_name"
                sleep 5
                echo
            fi
        done < <(yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML")
        ;;
        
    "status")
        show_status
        exit 0
        ;;
        
    "kill")
        kill_sessions
        exit 0
        ;;
        
    *)
        # Check if it's a valid phase name
        if yq eval ".phases | has(\"$PHASE\")" "$TODOS_YAML" | grep -q "true"; then
            start_phase_sessions "$PHASE"
        else
            echo -e "${RED}❌ Error: Unknown phase or command '$PHASE'${NC}"
            echo
            show_usage
            exit 1
        fi
        ;;
esac

echo
echo -e "${GREEN}🎉 Claude sessions started successfully!${NC}"
echo "================================================="

# Show how to connect to sessions
echo -e "${BLUE}📱 Connect to sessions:${NC}"
session_prefix="$TMUX_SESSION_PREFIX"
tmux list-sessions 2>/dev/null | grep -E "^${session_prefix}" | while read -r session; do
    session_name=$(echo "$session" | cut -d: -f1)
    echo "  tmux attach -t $session_name"
done

echo
echo -e "${BLUE}💡 Useful tmux commands:${NC}"
echo "  tmux list-sessions              # List all sessions"
echo "  tmux attach -t <session-name>   # Attach to specific session"
echo "  Ctrl+B, D                       # Detach from session (inside tmux)"
echo "  tmux kill-session -t <name>     # Kill specific session"
echo "  ./run-parallel-claude.sh kill   # Kill all Claude sessions"
echo "  ./run-parallel-claude.sh status # Check session status"

echo
echo -e "${YELLOW}⚡ Workflow Tips:${NC}"
highest_priority_phase=$(yq eval '.phases | to_entries | sort_by(.value.priority) | .[0].key' "$TODOS_YAML")
echo "• Start with '$highest_priority_phase' phase for maximum impact"
echo "• Each Claude session has todos.yaml copied for reference"  
echo "• Use Ctrl+B, D to detach and switch between sessions"
echo "• Run ./merge-workflow.sh when fixes are ready"
echo "• Monitor system resources with high parallel usage"
echo "• Check todos.yaml for detailed agent prompts and fix strategies"

echo
echo -e "${GREEN}✨ Happy YAML-driven parallel development!${NC}"