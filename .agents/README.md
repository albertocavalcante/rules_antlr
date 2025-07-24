# Multi-Agent Parallel Development System

## Overview

This directory contains a **revolutionary parallel development system** that enables **4x faster bug fixing** by running multiple Claude Code sessions simultaneously using git worktrees. Instead of fixing bugs sequentially, you can now tackle **20 critical vulnerabilities** in parallel.

## Key Benefits

- **🚀 4x Speed Improvement** - Fix 4 critical bugs simultaneously instead of one at a time
- **🔒 Perfect Isolation** - Each Claude session works in independent file state via git worktrees
- **🎯 Specialized Context** - Each agent becomes expert in specific vulnerability types
- **⚡ True Parallelization** - Leverage multiple CPU cores and Claude sessions concurrently

## Quick Start

### 1. Setup (One-time)
```bash
# Create all worktrees for parallel development
./setup-worktrees.sh
```

### 2. Launch Critical Fixes (Recommended First Step)
```bash
# Start 4 parallel Claude sessions for critical NPE vulnerabilities
./run-parallel-claude.sh critical
```

### 3. Connect to Claude Sessions
```bash
# Attach to specific sessions via tmux
tmux attach -t rules-antlr-npe-env      # TODO-001: Environment Variable NPE Fixes
tmux attach -t rules-antlr-npe-builder  # TODO-002: Builder Method Parameter NPE Fixes
tmux attach -t rules-antlr-npe-language # TODO-003: Language Path Conversion NPE Fixes
tmux attach -t rules-antlr-npe-utility  # TODO-004: Utility Method NPE Fixes
```

### 4. Create Pull Requests
```bash
# Create PRs for completed fixes
./merge-workflow.sh critical

# Check status of all worktrees
./merge-workflow.sh status
```

### 5. Cleanup
```bash
# Remove all worktrees and cleanup environment
./cleanup-worktrees.sh all
```

## System Components

| File | Purpose |
|------|---------|
| **`README.md`** | This overview and quick start guide |
| **`TODO.md`** | Detailed specifications for all 20 critical bug fixes with agent prompts |
| **`WORKFLOW.md`** | Comprehensive workflow documentation with examples and troubleshooting |
| **`setup-worktrees.sh`** | Creates git worktrees for parallel development |
| **`run-parallel-claude.sh`** | Launches multiple Claude sessions in tmux |
| **`merge-workflow.sh`** | Coordinates PR creation and merge workflow |
| **`cleanup-worktrees.sh`** | Removes worktrees and cleans up environment |
| **`test-workflow.sh`** | Tests the entire workflow system |

## Critical Bugs Being Fixed

### 🔴 Phase 1: Critical NPE Vulnerabilities (Parallel Execution)
- **TODO-001**: Environment Variable NPE Fixes (AntlrRules.java main method)
- **TODO-002**: Builder Method Parameter NPE Fixes  
- **TODO-003**: Language Path Conversion NPE Fixes
- **TODO-004**: Utility Method NPE Fixes

### 🟠 Phase 2: High Priority Bazel Fixes (Parallel Execution)
- **TODO-005**: Bazel Starlark Dictionary Access Fix (Bazel 6.0+ compatibility)
- **TODO-006**: Bazel String Method Fix (Non-existent .elems() calls)

### 🟡 Phase 3: Resource Management (Parallel Execution)
- **TODO-007**: Process Stream Resource Leak Fixes
- **TODO-008**: File Stream Resource Leak Fixes

### 🟢 Phase 4: Quality Improvements
- **TODO-009**: Array Bounds Safety Improvements
- **TODO-010**: Error Message Quality Improvements

## System Requirements

### Required
- **Git** - For worktree management
- **Bash 4+** - For script functionality  
- **Claude Code CLI** - For parallel development

### Optional (Recommended)
- **tmux** - For parallel session management (enables true parallel workflow)
- **GitHub CLI** - For automated PR creation

## Usage Examples

### Start All Critical Fixes at Once
```bash
./setup-worktrees.sh                    # Create development environment
./run-parallel-claude.sh critical       # Start 4 parallel sessions
```

### Work on Specific Priority Levels
```bash
./run-parallel-claude.sh bazel          # Bazel compatibility fixes
./run-parallel-claude.sh resource       # Resource management fixes
./run-parallel-claude.sh quality        # Quality improvements
```

### Manage Sessions
```bash
./run-parallel-claude.sh status         # Check active sessions
./run-parallel-claude.sh kill           # Kill all sessions
tmux list-sessions                       # List all tmux sessions
```

### Create Pull Requests
```bash
./merge-workflow.sh status              # Check what's ready for PR
./merge-workflow.sh critical            # Create PRs for critical fixes
./merge-workflow.sh all                 # Create PRs for all completed fixes
```

## Detailed Documentation

- **`./TODO.md`** - Complete specifications for all 20 bug fixes with detailed agent prompts
- **`./WORKFLOW.md`** - Comprehensive usage guide with troubleshooting and best practices

## Testing the System

```bash
# Test entire workflow
./test-workflow.sh

# Test specific components
./test-workflow.sh scripts              # Test script functionality
./test-workflow.sh e2e                  # End-to-end workflow test
```

## How It Works

1. **Git Worktrees** create isolated copies of the repository for each bug fix
2. **Claude Code sessions** run in parallel via tmux, each in its own worktree
3. **Specialized prompts** from TODO.md give each Claude specific context
4. **Independent development** prevents conflicts between parallel fixes
5. **Coordinated merging** ensures proper integration order

## Integration with rules_antlr

This multi-agent system is designed specifically for the **rules_antlr** project to address:
- **15 Critical NPE vulnerabilities** that could cause JVM crashes
- **3 High-priority Bazel logic errors** breaking compatibility with newer versions
- **2 Resource management issues** causing gradual system degradation

The system maintains full compatibility with existing rules_antlr development workflows while providing a **parallel alternative** for large-scale bug remediation.

---

**Ready to start? Run `./setup-worktrees.sh` and begin parallel development! 🚀**