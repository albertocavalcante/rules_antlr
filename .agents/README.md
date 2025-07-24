# Multi-Agent Development System

## Problem Context

When a codebase has multiple issues that need to be fixed simultaneously, traditional sequential development becomes inefficient. Working on all issues in the same branch creates conflicts and makes it difficult to track individual fixes. This system addresses these challenges by providing isolated development environments for parallel work.

## How It Works

This system uses git worktrees to create separate working copies of the repository, each isolated from the others. Each worktree is assigned to a specific bug fix, allowing multiple Claude Code sessions to work on different issues simultaneously without conflicts.

The entire system configuration is stored in `todos.yaml`, which defines:
- Individual TODO items with detailed agent prompts
- Phases that group related work
- Git configuration (branches, worktree directories, tmux session names)
- Workflow orchestration rules

Scripts read this YAML configuration to dynamically create worktrees, launch tmux sessions, and manage the development workflow.

## System Architecture

- **Git Worktrees**: Isolated copies of the repository for each TODO item
- **YAML Configuration**: Central definition of all tasks, phases, and settings
- **Tmux Sessions**: Parallel Claude Code instances, one per worktree
- **Bash Scripts**: Automation for setup, session management, and cleanup
- **Utility Layer**: Shared functions for YAML parsing and validation

## Configuration Schema

The `todos.yaml` file contains four main sections:

### Global Configuration
```yaml
config:
  worktree_base_dir: "../rules_antlr-worktrees"
  tmux_session_prefix: "rules-antlr"
  default_branch_base: "main"
```

### Phases
Groups of related TODO items with execution metadata:
```yaml
phases:
  high_priority:
    name: "High Priority Fixes"
    priority: 1
    parallel: true
    description: "Critical issues that need immediate attention"
```

### TODO Items
Individual tasks with detailed configuration:
```yaml
todos:
  - id: "TODO-001"
    title: "Fix Type A"
    phase: "high_priority"
    priority: "CRITICAL"
    git:
      branch: "fix/issue-type-a"
      worktree_dir: "fix-a"
      tmux_session: "project-fix-a"
    files:
      - "src/main/java/com/example/Component.java:88-99"
    agent_prompt: |-
      [Detailed multiline prompt with implementation steps,
       context, and verification requirements]
```

### Agent Types
Specialization definitions for different types of fixes:
```yaml
agent_types:
  Bug-Specialist:
    description: "Focuses on specific vulnerability types"
    expertise: ["error handling", "defensive programming"]
```

## Dependencies

### Required
- **Git** (with worktree support)
- **Bash** 4.0 or later
- **Claude Code CLI**

### Optional
- **yq** - For YAML parsing (enables full functionality)
- **tmux** - For session management (enables parallel workflow)
- **GitHub CLI** (gh) - For automated PR creation

### Installation
```bash
# macOS
brew install yq tmux gh

# Ubuntu/Debian
sudo apt-get install yq tmux gh

# Arch Linux
sudo pacman -S yq tmux github-cli
```bash

## Usage

### 1. Environment Setup
```bashbash
./setup-worktrees.sh
```bash
Creates git worktrees for all active TODO items defined in `todos.yaml`. Each worktree is created in a separate directory with its own branch.

### 2. Start Development Sessions
```bash
# Start specific phase
./run-parallel-claude.sh high_priority

# Start all phases
./run-parallel-claude.sh all

# View available phases
./run-parallel-claude.sh
```

### 3. Session Management
```bash
# Check active sessions
./run-parallel-claude.sh status

# Connect to specific session
tmux attach -t project-fix-a

# Kill all sessions
./run-parallel-claude.sh kill
```

### 4. Pull Request Creation
```bash
# Check status of all worktrees
./merge-workflow.sh status

# Create PRs for completed work
./merge-workflow.sh high_priority
./merge-workflow.sh all
```

### 5. Environment Cleanup
```bash
# Remove everything
./cleanup-worktrees.sh all

# Selective cleanup
./cleanup-worktrees.sh sessions    # Kill tmux sessions only
./cleanup-worktrees.sh worktrees   # Remove worktrees only
./cleanup-worktrees.sh branches    # Delete git branches only
```

## File Structure

```
.agents/
├── todos.yaml              # Central configuration file
├── yaml-utils.sh          # Shared YAML parsing utilities
├── setup-worktrees.sh     # Creates git worktrees from YAML
├── run-parallel-claude.sh # Launches Claude sessions in tmux
├── merge-workflow.sh      # Manages PR creation and merging
├── cleanup-worktrees.sh   # Environment cleanup
└── README.md             # This documentation
```

### Script Functions

**setup-worktrees.sh**
- Reads TODO items from YAML
- Creates git worktrees in configured directories
- Sets up branches for each TODO item
- Copies configuration files to each worktree

**run-parallel-claude.sh**
- Launches tmux sessions for TODO items in a phase
- Starts Claude Code in each worktree directory
- Provides session status and management commands
- Handles session cleanup

**merge-workflow.sh**
- Checks worktree status and commit readiness
- Runs tests in each worktree (if configured)
- Creates GitHub pull requests with detailed descriptions
- Manages merge workflow coordination

**cleanup-worktrees.sh**
- Removes git worktrees and their directories
- Kills tmux sessions
- Deletes git branches (local and remote)
- Cleans up temporary files

## YAML Utility Functions

The `yaml-utils.sh` file provides functions for working with configuration data:

```bash
source "./yaml-utils.sh"
init_yaml_utils "todos.yaml"

# Configuration queries
get_config "worktree_base_dir"          # Get config values
get_fallback_config "tmux_session_prefix"  # Get defaults

# TODO queries  
get_all_todo_indices                    # List all TODO indices
get_todo_field 0 "title"               # Get specific TODO field
is_todo_active 0                       # Check if TODO is not cancelled

# Phase queries
get_all_phases                          # Get phases by priority
get_phase_todo_indices "high_priority"  # Get TODOs in a phase
validate_phase "high_priority"          # Check if phase exists

# Validation
validate_yaml_schema                    # Validate YAML structure
show_yaml_status                        # Show configuration info
```

## Configuration

### Adding TODO Items

Edit `todos.yaml` to add new tasks:

```yaml
todos:
  - id: "TODO-011"
    title: "New Task"
    description: "Task description"
    phase: "quality"
    priority: "MEDIUM"
    git:
      branch: "fix/new-task"
      worktree_dir: "new-task"
      tmux_session: "rules-antlr-new-task"
    agent_prompt: |-
      Detailed instructions for the task...
```

Run `./setup-worktrees.sh` to create the new worktree.

### Adding Phases

Define new phases in `todos.yaml`:

```yaml
phases:
  performance:
    name: "Performance Optimizations"
    description: "Speed and memory improvements"
    priority: 5
    parallel: true
```

All scripts automatically recognize new phases defined in the YAML file.

### Project Adaptation

To use this system for other projects:

1. Replace `todos.yaml` with your project's tasks and phases
2. Update the `config` section with your preferred paths and naming
3. Modify agent prompts and fix strategies for your specific issues
4. Scripts will automatically adapt to the new configuration

## Current Configuration

The current tasks and phases are defined in `todos.yaml`. Check that file for:

- **Active TODO Items** - Specific tasks with detailed prompts and fix strategies
- **Phase Definitions** - Groups of related work with priority and execution rules
- **Agent Specializations** - Types of expertise assigned to different categories of work

The YAML file serves as the single source of truth for all current work items and their configuration.

## Limitations

- Requires yq for full functionality (falls back to limited features without it)
- Tmux sessions are local to the machine running the scripts
- Git worktrees share the same .git directory (objects and refs)
- Each worktree requires separate disk space for the working directory
- GitHub CLI integration requires authentication setup

## Troubleshooting

**Worktree creation fails**
- Ensure you're in the main repository (not already in a worktree)
- Check that branch names in YAML don't conflict with existing branches
- Verify you have write access to the parent directory

**Session startup issues**
- Confirm tmux is installed and working
- Check that Claude Code CLI is in your PATH
- Verify worktree directories exist and are accessible

**YAML parsing errors**
- Install yq or accept reduced functionality
- Validate YAML syntax using `yq eval '.' todos.yaml`
- Check for proper indentation and structure