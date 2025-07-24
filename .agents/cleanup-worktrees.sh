#!/bin/bash

# rules_antlr Worktree Cleanup Script
# Safely removes worktrees and cleans up the multi-agent development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

WORKTREE_DIR="../../rules_antlr-worktrees"

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [command] [options]${NC}"
    echo
    echo "Commands:"
    echo "  all        - Remove all worktrees and cleanup everything (DEFAULT)"
    echo "  sessions   - Kill all Claude tmux sessions only"
    echo "  worktrees  - Remove all worktrees only (keep sessions)"
    echo "  branches   - Clean up remote branches only"
    echo "  selective  - Interactive cleanup (choose what to remove)"
    echo "  status     - Show what would be cleaned up"
    echo
    echo "Options:"
    echo "  --force    - Skip confirmation prompts"
    echo "  --dry-run  - Show what would be done without actually doing it"
    echo
    echo "Examples:"
    echo "  $0              # Interactive cleanup of everything"
    echo "  $0 all --force  # Remove everything without prompts"
    echo "  $0 sessions     # Kill Claude sessions only"
    echo "  $0 status       # Show current state"
}

# Function to kill Claude tmux sessions
kill_claude_sessions() {
    local dry_run="$1"
    
    echo -e "${YELLOW}🛑 Killing Claude Code tmux sessions...${NC}"
    
    local session_patterns=(
        "rules-antlr-npe-"
        "rules-antlr-bazel-" 
        "rules-antlr-resource-"
        "rules-antlr-quality-"
    )
    
    local killed_count=0
    
    for pattern in "${session_patterns[@]}"; do
        if command -v tmux &> /dev/null; then
            local sessions
            sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "$pattern" || true)
            
            for session in $sessions; do
                echo -e "  Killing session: ${CYAN}$session${NC}"
                if [ "$dry_run" != "true" ]; then
                    tmux kill-session -t "$session" 2>/dev/null || true
                fi
                ((killed_count++))
            done
        fi
    done
    
    if [ $killed_count -eq 0 ]; then
        echo -e "  ${GREEN}No Claude sessions found${NC}"
    else
        echo -e "  ${GREEN}✅ Killed $killed_count Claude sessions${NC}"
    fi
}

# Function to remove worktrees
remove_worktrees() {
    local dry_run="$1"
    
    echo -e "${YELLOW}🗂️  Removing git worktrees...${NC}"
    
    local worktree_dirs=(
        "npe-env"
        "npe-builder"
        "npe-language"
        "npe-utility"
        "bazel-dict"
        "bazel-string"
        "resource-process"
        "resource-file"
        "safety-bounds"
        "quality-messages"
    )
    
    local removed_count=0
    
    # Check if worktree directory exists
    if [ ! -d "$WORKTREE_DIR" ]; then
        echo -e "  ${GREEN}No worktree directory found: $WORKTREE_DIR${NC}"
        return
    fi
    
    for dir in "${worktree_dirs[@]}"; do
        local full_path="$WORKTREE_DIR/$dir"
        
        if [ -d "$full_path" ]; then
            echo -e "  Removing worktree: ${CYAN}$full_path${NC}"
            
            if [ "$dry_run" != "true" ]; then
                # Remove the worktree using git
                git worktree remove "$full_path" --force 2>/dev/null || {
                    # If git worktree remove fails, try manual cleanup
                    echo -e "    ${YELLOW}Git cleanup failed, removing directory manually...${NC}"
                    rm -rf "$full_path"
                }
            fi
            ((removed_count++))
        fi
    done
    
    # Remove the parent directory if empty
    if [ "$dry_run" != "true" ] && [ -d "$WORKTREE_DIR" ]; then
        if [ -z "$(ls -A "$WORKTREE_DIR")" ]; then
            echo -e "  Removing empty worktree directory: ${CYAN}$WORKTREE_DIR${NC}"
            rmdir "$WORKTREE_DIR"
        fi
    fi
    
    if [ $removed_count -eq 0 ]; then
        echo -e "  ${GREEN}No worktrees found to remove${NC}"
    else
        echo -e "  ${GREEN}✅ Removed $removed_count worktrees${NC}"
    fi
}

# Function to clean up branches
cleanup_branches() {
    local dry_run="$1"
    local force="$2"
    
    echo -e "${YELLOW}🌿 Cleaning up git branches...${NC}"
    
    local branches=(
        "fix/npe-environment-variables"
        "fix/npe-builder-parameters"
        "fix/npe-language-path-conversion"
        "fix/npe-utility-methods"
        "fix/bazel-dict-access"
        "fix/bazel-string-methods"
        "fix/process-stream-leaks"
        "fix/file-stream-leaks"
        "fix/array-bounds-safety"
        "fix/error-message-quality"
    )
    
    local deleted_count=0
    
    for branch in "${branches[@]}"; do
        # Check if branch exists locally
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            echo -e "  Local branch found: ${CYAN}$branch${NC}"
            
            if [ "$force" = "true" ] || [ "$dry_run" = "true" ]; then
                local delete_local="y"
            else
                read -p "    Delete local branch '$branch'? (y/N): " -n 1 -r delete_local
                echo
            fi
            
            if [[ $delete_local =~ ^[Yy]$ ]]; then
                if [ "$dry_run" != "true" ]; then
                    git branch -D "$branch" 2>/dev/null || true
                fi
                echo -e "    ${GREEN}✅ Deleted local branch${NC}"
                ((deleted_count++))
            fi
        fi
        
        # Check if branch exists on remote
        if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
            echo -e "  Remote branch found: ${CYAN}origin/$branch${NC}"
            
            if [ "$force" = "true" ] || [ "$dry_run" = "true" ]; then
                local delete_remote="y"
            else
                read -p "    Delete remote branch 'origin/$branch'? (y/N): " -n 1 -r delete_remote
                echo
            fi
            
            if [[ $delete_remote =~ ^[Yy]$ ]]; then
                if [ "$dry_run" != "true" ]; then
                    git push origin --delete "$branch" 2>/dev/null || true
                fi
                echo -e "    ${GREEN}✅ Deleted remote branch${NC}"
                ((deleted_count++))
            fi
        fi
    done
    
    if [ $deleted_count -eq 0 ]; then
        echo -e "  ${GREEN}No branches found to delete${NC}"
    else
        echo -e "  ${GREEN}✅ Deleted $deleted_count branches${NC}"
    fi
}

# Function to clean up temporary files
cleanup_temp_files() {
    local dry_run="$1"
    
    echo -e "${YELLOW}🗑️  Cleaning up temporary files...${NC}"
    
    local temp_files=(
        "../../pr_urls.txt"
        "../../parallel_session.log"
        "./.tmux_session_info"
    )
    
    local removed_count=0
    
    for file in "${temp_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  Removing: ${CYAN}$file${NC}"
            if [ "$dry_run" != "true" ]; then
                rm -f "$file"
            fi
            ((removed_count++))
        fi
    done
    
    if [ $removed_count -eq 0 ]; then
        echo -e "  ${GREEN}No temporary files found${NC}"
    else
        echo -e "  ${GREEN}✅ Removed $removed_count temporary files${NC}"
    fi
}

# Function to show current status
show_status() {
    echo -e "${BLUE}📊 Current Multi-Agent Environment Status${NC}"
    echo "=============================================="
    
    # Check tmux sessions
    echo -e "${CYAN}Claude Code Sessions:${NC}"
    if command -v tmux &> /dev/null; then
        local claude_sessions
        claude_sessions=$(tmux list-sessions 2>/dev/null | grep -E "rules-antlr" || true)
        if [ -n "$claude_sessions" ]; then
            echo "$claude_sessions" | sed 's/^/  /'
        else
            echo "  No Claude sessions running"
        fi
    else
        echo "  tmux not available"
    fi
    
    echo
    
    # Check worktrees
    echo -e "${CYAN}Git Worktrees:${NC}"
    local worktree_list
    worktree_list=$(git worktree list | grep "$WORKTREE_DIR" || true)
    if [ -n "$worktree_list" ]; then
        echo "$worktree_list" | sed 's/^/  /'
    else
        echo "  No worktrees found"
    fi
    
    echo
    
    # Check branches
    echo -e "${CYAN}Fix Branches:${NC}"
    local fix_branches
    fix_branches=$(git branch | grep "fix/" || true)
    if [ -n "$fix_branches" ]; then
        echo "$fix_branches" | sed 's/^/  /'
    else
        echo "  No fix branches found"
    fi
    
    echo
    
    # Check temporary files
    echo -e "${CYAN}Temporary Files:${NC}"
    local temp_found=false
    for file in "../../pr_urls.txt" "../../parallel_session.log" "./.tmux_session_info"; do
        if [ -f "$file" ]; then
            echo "  $file"
            temp_found=true
        fi
    done
    if [ "$temp_found" = false ]; then
        echo "  No temporary files found"
    fi
}

# Function for interactive cleanup
interactive_cleanup() {
    local dry_run="$1"
    local force="$2"
    
    echo -e "${BLUE}🔧 Interactive Multi-Agent Environment Cleanup${NC}"
    echo "=============================================="
    
    if [ "$force" != "true" ]; then
        echo -e "${YELLOW}What would you like to clean up?${NC}"
        echo
        
        read -p "Kill Claude tmux sessions? (y/N): " -n 1 -r kill_sessions
        echo
        
        read -p "Remove git worktrees? (y/N): " -n 1 -r remove_wt
        echo
        
        read -p "Delete git branches? (y/N): " -n 1 -r delete_branches
        echo
        
        read -p "Remove temporary files? (y/N): " -n 1 -r remove_temp
        echo
        
        echo
    else
        kill_sessions="y"
        remove_wt="y"
        delete_branches="y"
        remove_temp="y"
    fi
    
    if [[ $kill_sessions =~ ^[Yy]$ ]]; then
        kill_claude_sessions "$dry_run"
        echo
    fi
    
    if [[ $remove_wt =~ ^[Yy]$ ]]; then
        remove_worktrees "$dry_run"
        echo
    fi
    
    if [[ $delete_branches =~ ^[Yy]$ ]]; then
        cleanup_branches "$dry_run" "$force"
        echo
    fi
    
    if [[ $remove_temp =~ ^[Yy]$ ]]; then
        cleanup_temp_files "$dry_run"
        echo
    fi
}

# Parse command line arguments
DRY_RUN=false
FORCE=false
COMMAND="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        all|sessions|worktrees|branches|selective|status)
            COMMAND=$1
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Show dry run notice
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo
fi

# Execute command
case "$COMMAND" in
    "status")
        show_status
        ;;
    
    "sessions")
        kill_claude_sessions "$DRY_RUN"
        ;;
    
    "worktrees")
        remove_worktrees "$DRY_RUN"
        ;;
    
    "branches")
        cleanup_branches "$DRY_RUN" "$FORCE"
        ;;
    
    "selective")
        interactive_cleanup "$DRY_RUN" "$FORCE"
        ;;
    
    "all")
        echo -e "${BLUE}🧹 Complete Multi-Agent Environment Cleanup${NC}"
        echo "=============================================="
        
        if [ "$FORCE" != "true" ] && [ "$DRY_RUN" != "true" ]; then
            echo -e "${YELLOW}⚠️  This will remove ALL worktrees, sessions, branches, and temporary files${NC}"
            read -p "Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Cancelled."
                exit 0
            fi
            echo
        fi
        
        kill_claude_sessions "$DRY_RUN"
        echo
        remove_worktrees "$DRY_RUN"
        echo
        cleanup_branches "$DRY_RUN" "$FORCE"
        echo
        cleanup_temp_files "$DRY_RUN"
        ;;
    
    *)
        show_usage
        exit 1
        ;;
esac

echo
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}✨ Dry run complete! Use without --dry-run to actually perform cleanup.${NC}"
else
    echo -e "${GREEN}✨ Cleanup complete!${NC}"
    
    echo
    echo -e "${BLUE}💡 Next Steps:${NC}"
    echo "• Run 'git worktree list' to verify worktrees are removed"
    echo "• Run 'git branch' to check remaining branches"
    echo "• Use './setup-worktrees.sh' to recreate the environment if needed"
    echo "• Check 'tmux list-sessions' to verify no Claude sessions remain"
fi