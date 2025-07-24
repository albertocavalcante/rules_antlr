# rules_antlr Multi-Agent Parallel Development Workflow

## Overview

This workflow enables **parallel Claude Code development** using git worktrees to fix multiple critical bugs simultaneously. Instead of fixing bugs sequentially, you can run **4+ Claude sessions in parallel**, each working on independent code fixes.

## 🚀 Quick Start

### 1. Setup (One-time)
```bash
# Create all worktrees for parallel development
./setup-worktrees.sh
```

### 2. Launch Parallel Claude Sessions
```bash
# Start 4 critical NPE fix sessions (RECOMMENDED first step)
./run-parallel-claude.sh critical

# Or start all sessions (high resource usage)
./run-parallel-claude.sh all
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
# Create PRs for completed critical fixes
./merge-workflow.sh critical

# Or check status of all worktrees
./merge-workflow.sh status
```

### 5. Cleanup When Done
```bash
# Remove all worktrees and cleanup environment
./cleanup-worktrees.sh all
```

## 📋 Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup-worktrees.sh` | Create git worktrees for parallel development | `./setup-worktrees.sh` |
| `run-parallel-claude.sh` | Launch multiple Claude sessions in tmux | `./run-parallel-claude.sh critical` |
| `merge-workflow.sh` | Create PRs and coordinate merging | `./merge-workflow.sh status` |
| `cleanup-worktrees.sh` | Remove worktrees and cleanup | `./cleanup-worktrees.sh all` |
| `test-workflow.sh` | Test the entire workflow system | `./test-workflow.sh` |

## 🎯 TODO Items by Priority

### 🔴 Critical NPE Fixes (Phase 1) - Parallel Execution
- **TODO-001**: Environment Variable NPE Fixes  
- **TODO-002**: Builder Method Parameter NPE Fixes
- **TODO-003**: Language Path Conversion NPE Fixes
- **TODO-004**: Utility Method NPE Fixes

### 🟠 High Priority Bazel Fixes (Phase 2) - Parallel Execution  
- **TODO-005**: Bazel Starlark Dictionary Access Fix
- **TODO-006**: Bazel String Method Fix

### 🟡 Medium Priority Resource Fixes (Phase 3) - Parallel Execution
- **TODO-007**: Process Stream Resource Leak Fixes
- **TODO-008**: File Stream Resource Leak Fixes

### 🟢 Quality Improvements (Phase 4)
- **TODO-009**: Array Bounds Safety Improvements
- **TODO-010**: Error Message Quality Improvements

## 🔧 System Requirements

### Required
- **Git** (for worktree management)
- **Bash 4+** (for script functionality)
- **Claude Code CLI** (for parallel development)

### Optional (but recommended)
- **tmux** (for parallel session management)
- **GitHub CLI** (for automated PR creation)

## 📊 Testing the Workflow

```bash
# Test entire workflow system
./test-workflow.sh

# Test specific components
./test-workflow.sh scripts    # Test script functionality
./test-workflow.sh e2e        # End-to-end workflow test
./test-workflow.sh deps       # Check system dependencies
```

## 🎮 tmux Session Management

### Useful tmux Commands
```bash
# List all sessions
tmux list-sessions

# Attach to specific session
tmux attach -t rules-antlr-npe-env

# Detach from session (inside tmux)
Ctrl+B, D

# Kill specific session
tmux kill-session -t rules-antlr-npe-env

# Kill all Claude sessions
./run-parallel-claude.sh kill
```

### Session Naming Convention
- `rules-antlr-npe-*` - Critical NPE fix sessions
- `rules-antlr-bazel-*` - Bazel compatibility sessions  
- `rules-antlr-resource-*` - Resource management sessions
- `rules-antlr-quality-*` - Quality improvement sessions

## 📁 Directory Structure

```
rules_antlr/                           # Main repository
├── TODO.md                            # Detailed task specifications
├── WORKFLOW.md                        # This document
├── setup-worktrees.sh                 # Worktree creation
├── run-parallel-claude.sh             # Parallel session launcher
├── merge-workflow.sh                  # PR creation and coordination
├── cleanup-worktrees.sh               # Environment cleanup
├── test-workflow.sh                   # Workflow testing
└── ../rules_antlr-worktrees/          # Parallel development worktrees
    ├── npe-env/                       # TODO-001 worktree
    ├── npe-builder/                   # TODO-002 worktree
    ├── npe-language/                  # TODO-003 worktree
    ├── npe-utility/                   # TODO-004 worktree
    ├── bazel-dict/                    # TODO-005 worktree
    ├── bazel-string/                  # TODO-006 worktree
    ├── resource-process/              # TODO-007 worktree
    ├── resource-file/                 # TODO-008 worktree
    ├── safety-bounds/                 # TODO-009 worktree
    └── quality-messages/              # TODO-010 worktree
```

## 🚦Status Management

### Check Workflow Status
```bash
# Check all worktree status
./merge-workflow.sh status

# Check active Claude sessions
./run-parallel-claude.sh status

# Check cleanup status  
./cleanup-worktrees.sh status
```

## 🔄 Recommended Workflow

### Phase 1: Critical Bug Fixes (Highest Impact)
1. `./setup-worktrees.sh` - Create development environment
2. `./run-parallel-claude.sh critical` - Start 4 critical fix sessions
3. Work in parallel on TODO-001 through TODO-004
4. `./merge-workflow.sh critical` - Create PRs for critical fixes
5. **Merge critical fixes first** before proceeding

### Phase 2: High Priority Fixes
1. `./run-parallel-claude.sh bazel` - Start Bazel compatibility sessions
2. Work on TODO-005 and TODO-006
3. `./merge-workflow.sh bazel` - Create PRs for Bazel fixes

### Phase 3: Resource and Quality Fixes
1. `./run-parallel-claude.sh resource` - Start resource management sessions
2. `./run-parallel-claude.sh quality` - Start quality improvement sessions  
3. Work on remaining TODO items
4. `./merge-workflow.sh all` - Create PRs for remaining fixes

### Phase 4: Integration and Cleanup
1. **Integration testing** after all merges
2. `./cleanup-worktrees.sh all` - Clean up development environment
3. **Validate** that all 20 critical bugs are resolved

## 💡 Tips and Best Practices

### Parallel Development
- **Start with critical fixes** (TODO-001 to TODO-004) for maximum impact
- **Use tmux sessions** to easily switch between Claude instances
- **Each Claude session** has its own isolated file state
- **Monitor system resources** when running many parallel sessions

### Code Quality
- **Each TODO item** includes detailed fix instructions and verification steps
- **Each worktree** gets its own copy of TODO.md for reference
- **Test each fix** independently before creating PRs
- **Follow dependency order** when merging (critical → high → medium → low)

### Troubleshooting
- Use `./test-workflow.sh` to validate system setup
- Check `./cleanup-worktrees.sh status` if worktrees seem stuck
- Use `./run-parallel-claude.sh kill` to reset Claude sessions
- Refer to `TODO.md` for detailed context on each issue

## 🎉 Benefits

### Speed
- **4x faster** for critical fixes (parallel vs sequential)
- **Independent development** prevents conflicts
- **Immediate PR creation** for completed fixes

### Quality  
- **Specialized context** for each Claude session
- **Independent testing** of each fix
- **Systematic approach** to complex bug remediation

### Organization
- **Clear priority ordering** (critical → high → medium → low)
- **Traceable progress** through session management
- **Clean integration** via coordinated PR workflow

This workflow transforms traditional sequential bug fixing into a **parallel, scalable development process** using Claude Code's native capabilities with git worktrees.