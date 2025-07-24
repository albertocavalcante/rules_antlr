#!/bin/bash

# YAML Utility Functions for rules_antlr Multi-Agent System
# Shared utilities for YAML parsing, validation, and dependency checking
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/yaml-utils.sh"

# Colors for output (if not already defined)
if [ -z "$RED" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
fi

# Global variables
YAML_UTILS_INITIALIZED=false
YAML_AVAILABLE=false
TODOS_YAML_PATH=""

# Function to initialize YAML utilities
# Usage: init_yaml_utils [path_to_todos_yaml]
init_yaml_utils() {
    local todos_yaml_path="${1:-$(dirname "${BASH_SOURCE[0]}")/todos.yaml}"
    
    TODOS_YAML_PATH="$todos_yaml_path"
    
    # Check if yq is available
    if ! command -v yq &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: yq not found. YAML features disabled.${NC}" >&2
        echo -e "${BLUE}Install yq for full YAML support:${NC}" >&2
        echo "  macOS: brew install yq" >&2
        echo "  Ubuntu: sudo apt-get install yq" >&2
        echo "  Arch: sudo pacman -S yq" >&2
        echo "  Or download from: https://github.com/mikefarah/yq/releases" >&2
        YAML_AVAILABLE=false
    else
        YAML_AVAILABLE=true
    fi
    
    # Validate YAML file if yq is available
    if [ "$YAML_AVAILABLE" = "true" ]; then
        if [ ! -f "$TODOS_YAML_PATH" ]; then
            echo -e "${RED}❌ Error: todos.yaml not found at $TODOS_YAML_PATH${NC}" >&2
            YAML_AVAILABLE=false
        elif ! yq eval '.' "$TODOS_YAML_PATH" > /dev/null 2>&1; then
            echo -e "${RED}❌ Error: Invalid YAML syntax in $TODOS_YAML_PATH${NC}" >&2
            YAML_AVAILABLE=false
        else
            echo -e "${GREEN}✅ YAML configuration loaded successfully${NC}" >&2
        fi
    fi
    
    YAML_UTILS_INITIALIZED=true
}

# Function to check if YAML utilities are initialized and available
require_yaml() {
    if [ "$YAML_UTILS_INITIALIZED" != "true" ]; then
        echo -e "${RED}❌ Error: YAML utilities not initialized. Call init_yaml_utils first.${NC}" >&2
        return 1
    fi
    
    if [ "$YAML_AVAILABLE" != "true" ]; then
        echo -e "${RED}❌ Error: YAML functionality not available.${NC}" >&2
        return 1
    fi
    
    return 0
}

# Function to get a YAML value with fallback
# Usage: yaml_get_or_default <yaml_path> <default_value>
yaml_get_or_default() {
    local yaml_path="$1"
    local default_value="$2"
    
    if ! require_yaml; then
        echo "$default_value"
        return 0
    fi
    
    local result
    result=$(yq eval "$yaml_path" "$TODOS_YAML_PATH" 2>/dev/null)
    
    if [ "$result" = "null" ] || [ -z "$result" ]; then
        echo "$default_value"
    else
        echo "$result"
    fi
}

# Function to get all TODO indices
# Usage: get_all_todo_indices
get_all_todo_indices() {
    if ! require_yaml; then
        return 1
    fi
    
    local total_todos
    total_todos=$(yq eval '.todos | length' "$TODOS_YAML_PATH")
    
    for (( i=0; i<total_todos; i++ )); do
        echo "$i"
    done
}

# Function to get TODO indices for a specific phase
# Usage: get_phase_todo_indices <phase_name>
get_phase_todo_indices() {
    local phase_name="$1"
    
    if ! require_yaml; then
        return 1
    fi
    
    yq eval ".todos | to_entries | map(select(.value.phase == \"$phase_name\")) | .[].key" "$TODOS_YAML_PATH"
}

# Function to get all phase names sorted by priority
# Usage: get_all_phases
get_all_phases() {
    if ! require_yaml; then
        return 1
    fi
    
    yq eval '.phases | to_entries | sort_by(.value.priority) | .[].key' "$TODOS_YAML_PATH"
}

# Function to get TODO field value
# Usage: get_todo_field <todo_index> <field_path>
get_todo_field() {
    local todo_index="$1"
    local field_path="$2"
    
    if ! require_yaml; then
        return 1
    fi
    
    yq eval ".todos[${todo_index}].${field_path}" "$TODOS_YAML_PATH"
}

# Function to get phase field value
# Usage: get_phase_field <phase_name> <field_path>
get_phase_field() {
    local phase_name="$1"
    local field_path="$2"
    
    if ! require_yaml; then
        return 1
    fi
    
    yq eval ".phases.${phase_name}.${field_path}" "$TODOS_YAML_PATH"
}

# Function to get configuration value
# Usage: get_config <config_path>
get_config() {
    local config_path="$1"
    
    if ! require_yaml; then
        return 1
    fi
    
    yq eval ".config.${config_path}" "$TODOS_YAML_PATH"
}

# Function to validate phase exists
# Usage: validate_phase <phase_name>
validate_phase() {
    local phase_name="$1"
    
    if ! require_yaml; then
        return 1
    fi
    
    yq eval ".phases | has(\"$phase_name\")" "$TODOS_YAML_PATH" | grep -q "true"
}

# Function to check if TODO is active (not cancelled)
# Usage: is_todo_active <todo_index>
is_todo_active() {
    local todo_index="$1"
    
    if ! require_yaml; then
        return 1
    fi
    
    local status
    status=$(yq eval ".todos[${todo_index}].status // \"active\"" "$TODOS_YAML_PATH")
    
    [ "$status" != "cancelled" ]
}

# Function to get active TODO count for a phase
# Usage: get_active_todo_count <phase_name>
get_active_todo_count() {
    local phase_name="$1"
    
    if ! require_yaml; then
        return 1
    fi
    
    yq eval ".todos | map(select(.phase == \"$phase_name\" and (.status // \"active\") != \"cancelled\")) | length" "$TODOS_YAML_PATH"
}

# Function to get total active TODO count
# Usage: get_total_active_todo_count
get_total_active_todo_count() {
    if ! require_yaml; then
        return 1
    fi
    
    yq eval '.todos | map(select((.status // "active") != "cancelled")) | length' "$TODOS_YAML_PATH"
}

# Function to check YAML schema validity
# Usage: validate_yaml_schema
validate_yaml_schema() {
    if ! require_yaml; then
        return 1
    fi
    
    echo -e "${BLUE}🔍 Validating YAML schema...${NC}" >&2
    
    # Check required top-level keys
    local required_keys=("version" "project" "config" "phases" "todos")
    for key in "${required_keys[@]}"; do
        if ! yq eval "has(\"$key\")" "$TODOS_YAML_PATH" | grep -q "true"; then
            echo -e "${RED}❌ Missing required key: $key${NC}" >&2
            return 1
        fi
    done
    
    # Check config structure
    local config_keys=("worktree_base_dir" "tmux_session_prefix" "default_branch_base")
    for key in "${config_keys[@]}"; do
        if ! yq eval ".config | has(\"$key\")" "$TODOS_YAML_PATH" | grep -q "true"; then
            echo -e "${RED}❌ Missing required config key: $key${NC}" >&2
            return 1
        fi
    done
    
    # Validate each TODO has required fields
    local total_todos
    total_todos=$(yq eval '.todos | length' "$TODOS_YAML_PATH")
    
    for (( i=0; i<total_todos; i++ )); do
        local todo_id
        todo_id=$(yq eval ".todos[${i}].id" "$TODOS_YAML_PATH")
        
        local required_todo_keys=("id" "title" "description" "phase" "priority" "git")
        for key in "${required_todo_keys[@]}"; do
            if ! yq eval ".todos[${i}] | has(\"$key\")" "$TODOS_YAML_PATH" | grep -q "true"; then
                echo -e "${RED}❌ TODO $todo_id missing required key: $key${NC}" >&2
                return 1
            fi
        done
        
        # Check git configuration
        local git_keys=("branch" "worktree_dir" "tmux_session")
        for key in "${git_keys[@]}"; do
            if ! yq eval ".todos[${i}].git | has(\"$key\")" "$TODOS_YAML_PATH" | grep -q "true"; then
                echo -e "${RED}❌ TODO $todo_id missing required git key: $key${NC}" >&2
                return 1
            fi
        done
    done
    
    echo -e "${GREEN}✅ YAML schema validation passed${NC}" >&2
    return 0
}

# Function to show YAML status
# Usage: show_yaml_status
show_yaml_status() {
    echo -e "${BLUE}📊 YAML Configuration Status${NC}" >&2
    echo "================================" >&2
    
    if [ "$YAML_UTILS_INITIALIZED" != "true" ]; then
        echo -e "${YELLOW}YAML utilities not initialized${NC}" >&2
        return 0
    fi
    
    echo "YAML File: $TODOS_YAML_PATH" >&2
    echo "YQ Available: $([ "$YAML_AVAILABLE" = "true" ] && echo -e "${GREEN}Yes${NC}" || echo -e "${RED}No${NC}")" >&2
    
    if [ "$YAML_AVAILABLE" = "true" ]; then
        local version project total_todos total_phases
        version=$(get_config "version" 2>/dev/null || echo "unknown")
        project=$(yaml_get_or_default ".project" "unknown")
        total_todos=$(yq eval '.todos | length' "$TODOS_YAML_PATH")
        total_phases=$(yq eval '.phases | length' "$TODOS_YAML_PATH")
        
        echo "Project: $project" >&2
        echo "Version: $version" >&2
        echo "Total TODOs: $total_todos" >&2
        echo "Total Phases: $total_phases" >&2
        echo "Active TODOs: $(get_total_active_todo_count)" >&2
    fi
}

# Function to get fallback configuration values
# Usage: get_fallback_config <config_type>
get_fallback_config() {
    local config_type="$1"
    
    case "$config_type" in
        "worktree_base_dir")
            echo "../rules_antlr-worktrees"
            ;;
        "tmux_session_prefix")
            echo "rules-antlr"
            ;;
        "default_branch_base")
            echo "main"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to print YAML utility usage
# Usage: yaml_utils_usage
yaml_utils_usage() {
    echo -e "${BLUE}YAML Utilities Usage${NC}"
    echo "===================="
    echo
    echo "Initialization:"
    echo "  init_yaml_utils [path_to_todos_yaml]"
    echo
    echo "Configuration:"
    echo "  get_config <config_path>"
    echo "  get_fallback_config <config_type>"
    echo
    echo "TODO queries:"
    echo "  get_all_todo_indices"
    echo "  get_phase_todo_indices <phase_name>"
    echo "  get_todo_field <todo_index> <field_path>"
    echo "  is_todo_active <todo_index>"
    echo "  get_active_todo_count <phase_name>"
    echo "  get_total_active_todo_count"
    echo
    echo "Phase queries:"
    echo "  get_all_phases"
    echo "  get_phase_field <phase_name> <field_path>"
    echo "  validate_phase <phase_name>"
    echo
    echo "Utilities:"
    echo "  yaml_get_or_default <yaml_path> <default_value>"
    echo "  validate_yaml_schema"
    echo "  show_yaml_status"
    echo "  require_yaml"
}

# Export functions for use in other scripts
export -f init_yaml_utils require_yaml yaml_get_or_default
export -f get_all_todo_indices get_phase_todo_indices get_all_phases
export -f get_todo_field get_phase_field get_config
export -f validate_phase is_todo_active get_active_todo_count get_total_active_todo_count
export -f validate_yaml_schema show_yaml_status get_fallback_config yaml_utils_usage