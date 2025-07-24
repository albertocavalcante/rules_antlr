#!/bin/bash

# rules_antlr Parallel Claude Code Session Launcher
# Starts multiple Claude sessions in tmux for parallel development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

WORKTREE_DIR="../../rules_antlr-worktrees"

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ Error: tmux is required for parallel sessions${NC}"
    echo -e "${YELLOW}Install tmux:${NC}"
    echo "  macOS: brew install tmux"
    echo "  Ubuntu: sudo apt-get install tmux"
    echo "  Fedora: sudo dnf install tmux"
    echo
    echo -e "${BLUE}Alternative: Manual execution${NC}"
    echo "Open multiple terminals and run:"
    echo "  cd $WORKTREE_DIR/npe-env && claude"
    echo "  cd $WORKTREE_DIR/npe-builder && claude"
    echo "  cd $WORKTREE_DIR/npe-language && claude"
    echo "  cd $WORKTREE_DIR/npe-utility && claude"
    exit 1
fi

# Check if worktrees exist
if [ ! -d "$WORKTREE_DIR" ]; then
    echo -e "${RED}❌ Error: Worktrees not found. Run ./setup-worktrees.sh first${NC}"
    exit 1
fi

# Function to create tmux session with Claude
create_claude_session() {
    local session_name="$1"
    local worktree_path="$2"
    local todo_item="$3"
    local description="$4"
    local agent_prompt="$5"
    
    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}❌ Worktree not found: $worktree_path${NC}"
        return 1
    fi
    
    echo -e "${CYAN}🚀 Starting Claude session: $session_name${NC}"
    echo "   Worktree: $worktree_path"
    echo "   Task: $description"
    
    # Kill existing session if it exists
    tmux kill-session -t "$session_name" 2>/dev/null || true
    
    # Create new session
    tmux new-session -d -s "$session_name" -c "$worktree_path"
    
    # Send the agent prompt as a comment for reference
    tmux send-keys -t "$session_name" "# $todo_item: $description" Enter
    tmux send-keys -t "$session_name" "# Agent Prompt: $agent_prompt" Enter
    tmux send-keys -t "$session_name" "# Working directory: $(pwd)" Enter
    tmux send-keys -t "$session_name" "# Use TODO.md for detailed instructions" Enter
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
    echo "Phases:"
    echo "  critical  - Start only critical NPE fixes (TODO-001 to TODO-004) - RECOMMENDED"
    echo "  bazel     - Start Bazel compatibility fixes (TODO-005, TODO-006)"  
    echo "  resource  - Start resource management fixes (TODO-007, TODO-008)"
    echo "  quality   - Start quality improvement fixes (TODO-009, TODO-010)"
    echo "  all       - Start ALL sessions (10 parallel Claude instances)"
    echo "  status    - Show running sessions"
    echo "  kill      - Kill all Claude sessions"
    echo
    echo "Examples:"
    echo "  $0 critical    # Start 4 critical NPE fix sessions"
    echo "  $0 all         # Start all 10 sessions (high resource usage)"
    echo "  $0 status      # Check which sessions are running"
}

# Function to show session status
show_status() {
    echo -e "${BLUE}🔍 Active Claude Code Sessions:${NC}"
    echo "================================="
    
    if ! tmux list-sessions 2>/dev/null | grep -E "rules-antlr|npe-|bazel-|resource-|quality-"; then
        echo -e "${YELLOW}No Claude sessions running${NC}"
        return
    fi
    
    echo
    echo -e "${BLUE}💡 Attach to sessions:${NC}"
    tmux list-sessions 2>/dev/null | grep -E "rules-antlr|npe-|bazel-|resource-|quality-" | while read -r session; do
        session_name=$(echo "$session" | cut -d: -f1)
        echo "  tmux attach -t $session_name"
    done
}

# Function to kill all Claude sessions
kill_sessions() {
    echo -e "${YELLOW}🛑 Killing all Claude Code sessions...${NC}"
    
    session_patterns=("rules-antlr-npe-" "rules-antlr-bazel-" "rules-antlr-resource-" "rules-antlr-quality-")
    
    for pattern in "${session_patterns[@]}"; do
        tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "$pattern" | xargs -I {} tmux kill-session -t {} 2>/dev/null || true
    done
    
    echo -e "${GREEN}✅ All sessions killed${NC}"
}

# Parse command line arguments
PHASE="${1:-critical}"

case "$PHASE" in
    "critical")
        echo -e "${BLUE}🔴 STARTING CRITICAL NPE FIXES (Phase 1)${NC}"
        echo "Starting 4 parallel Claude sessions for critical vulnerabilities..."
        echo "================================================="
        
        create_claude_session "rules-antlr-npe-env" "$WORKTREE_DIR/npe-env" \
            "TODO-001" "Environment Variable NPE Fixes" \
            "Fix critical NPE vulnerabilities in AntlrRules.java main method where env.get() results are used without null checks"
            
        sleep 2
        
        create_claude_session "rules-antlr-npe-builder" "$WORKTREE_DIR/npe-builder" \
            "TODO-002" "Builder Method Parameter NPE Fixes" \
            "Fix NPE vulnerabilities in AntlrRules builder methods where parameters are used without null checks"
            
        sleep 2
        
        create_claude_session "rules-antlr-npe-language" "$WORKTREE_DIR/npe-language" \
            "TODO-003" "Language Path Conversion NPE Fixes" \
            "Fix NPE vulnerabilities in Language enum toId() methods where path.toString() is called without null checks"
            
        sleep 2
        
        create_claude_session "rules-antlr-npe-utility" "$WORKTREE_DIR/npe-utility" \
            "TODO-004" "Utility Method NPE Fixes" \
            "Fix NPE vulnerabilities in utility methods that use switch statements without null parameter checks"
        ;;
        
    "bazel")
        echo -e "${BLUE}🟠 STARTING BAZEL COMPATIBILITY FIXES (Phase 2)${NC}"
        echo "Starting 2 parallel Claude sessions for Bazel issues..."
        echo "================================================="
        
        create_claude_session "rules-antlr-bazel-dict" "$WORKTREE_DIR/bazel-dict" \
            "TODO-005" "Bazel Starlark Dictionary Access Fix" \
            "Fix Bazel Starlark compatibility issue where lib.keys()[0] breaks in Bazel 6.0+"
            
        sleep 2
        
        create_claude_session "rules-antlr-bazel-string" "$WORKTREE_DIR/bazel-string" \
            "TODO-006" "Bazel String Method Fix" \
            "Fix Bazel Starlark errors where non-existent .elems() method is called on strings"
        ;;
        
    "resource")
        echo -e "${BLUE}🟡 STARTING RESOURCE MANAGEMENT FIXES (Phase 3)${NC}"
        echo "Starting 2 parallel Claude sessions for resource leaks..."
        echo "================================================="
        
        create_claude_session "rules-antlr-resource-process" "$WORKTREE_DIR/resource-process" \
            "TODO-007" "Process Stream Resource Leak Fixes" \
            "Fix resource leak in Command.java where process InputStream is not properly closed"
            
        sleep 2
        
        create_claude_session "rules-antlr-resource-file" "$WORKTREE_DIR/resource-file" \
            "TODO-008" "File Stream Resource Leak Fixes" \
            "Fix resource leak in TestWorkspace.java where Files.walk() Stream is not properly closed"
        ;;
        
    "quality")
        echo -e "${BLUE}🟢 STARTING QUALITY IMPROVEMENTS (Phase 4)${NC}"
        echo "Starting 2 parallel Claude sessions for quality improvements..."
        echo "================================================="
        
        create_claude_session "rules-antlr-quality-bounds" "$WORKTREE_DIR/safety-bounds" \
            "TODO-009" "Array Bounds Safety Improvements" \
            "Fix potential array bounds violation in AntlrRules.java expandSrcJarImports method"
            
        sleep 2
        
        create_claude_session "rules-antlr-quality-messages" "$WORKTREE_DIR/quality-messages" \
            "TODO-010" "Error Message Quality Improvements" \
            "Improve error message formatting by adding missing spaces and consistent formatting"
        ;;
        
    "all")
        echo -e "${BLUE}🚀 STARTING ALL PARALLEL SESSIONS${NC}"
        echo -e "${RED}⚠️  Warning: This will start 10 Claude sessions simultaneously!${NC}"
        echo -e "${YELLOW}High resource usage - ensure you have sufficient RAM/CPU${NC}"
        echo "================================================="
        
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
        
        # Start all phases
        "$0" critical
        sleep 5
        "$0" bazel  
        sleep 5
        "$0" resource
        sleep 5
        "$0" quality
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
        show_usage
        exit 1
        ;;
esac

echo
echo -e "${GREEN}🎉 Claude sessions started successfully!${NC}"
echo "================================================="

# Show how to connect to sessions
echo -e "${BLUE}📱 Connect to sessions:${NC}"
tmux list-sessions 2>/dev/null | grep -E "rules-antlr" | while read -r session; do
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
echo "• Start with 'critical' phase for maximum impact"
echo "• Each Claude session has TODO.md copied for reference"
echo "• Use Ctrl+B, D to detach and switch between sessions"
echo "• Run ./merge-workflow.sh when fixes are ready"
echo "• Monitor system resources with high parallel usage"

echo
echo -e "${GREEN}✨ Happy parallel development!${NC}"