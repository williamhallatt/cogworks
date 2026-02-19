#!/bin/bash
# Cogworks Installation Script
# Interactive installer for cogworks agent and skills
#
# Usage:
#   ./install.sh              # Interactive mode
#   ./install.sh --local      # Install to project .claude/
#   ./install.sh --global     # Install to ~/.claude/
#   ./install.sh --force      # Skip overwrite confirmations
#   ./install.sh --dry-run    # Preview changes without modifying files
#   ./install.sh --help       # Show usage information

set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required components
readonly AGENT_FILE="cogworks.md"
readonly REQUIRED_SKILLS=("cogworks-encode" "cogworks-learn")
readonly OPTIONAL_SKILLS=("cogworks-test")
readonly TEST_FRAMEWORK_DIR="test-framework"

# Installation modes
readonly MODE_LOCAL=".claude"
readonly MODE_GLOBAL="${HOME}/.claude"

# Color codes for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'

# Global state
INSTALL_PATH=""
FORCE_MODE=false
DRY_RUN_MODE=false
INTERACTIVE_MODE=true

# Results tracking
ERRORS=()
WARNINGS=()
INSTALLED_FILES=()

#
# Utility Functions: Output formatting
#

print_header() {
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}=== $1 ===${COLOR_RESET}\n"
}

print_section() {
    echo -e "\n${COLOR_BOLD}$1${COLOR_RESET}"
}

print_success() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_RED}✗${COLOR_RESET} $1" >&2
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $1"
}

print_info() {
    echo -e "${COLOR_BLUE}ℹ${COLOR_RESET} $1"
}

print_dim() {
    echo -e "\033[2m$1${COLOR_RESET}"
}

#
# Utility Functions: Error handling and user interaction
#

die() {
    print_error "$1"
    exit 1
}

handle_error() {
    ERRORS+=("$1")
    print_error "$1"
}

log_warning() {
    WARNINGS+=("$1")
    print_warning "$1"
}

log_installed() {
    INSTALLED_FILES+=("$1")
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local yn

    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n] " yn
            yn="${yn:-y}"
        else
            read -p "$prompt [y/N] " yn
            yn="${yn:-n}"
        fi

        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    echo "$prompt"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done

    while true; do
        read -p "Enter choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            return $((choice - 1))
        fi
        echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
    done
}

press_any_key() {
    read -n 1 -s -r -p "Press any key to continue..."
    echo
}

#
# Validation Functions
#

validate_source_archive() {
    print_section "Validating source archive..."

    local valid=true

    # Check we're in the extracted archive directory
    if [[ ! -f "${SCRIPT_DIR}/README.md" ]] || [[ ! -f "${SCRIPT_DIR}/LICENSE" ]]; then
        handle_error "Not running from extracted cogworks archive (README.md or LICENSE missing)"
        valid=false
    fi

    # Check agent file exists
    if [[ ! -f "${SCRIPT_DIR}/.claude/agents/${AGENT_FILE}" ]]; then
        handle_error "Agent file not found: .claude/agents/${AGENT_FILE}"
        valid=false
    else
        print_success "Found agent: ${AGENT_FILE}"
    fi

    # Check required skills exist
    for skill in "${REQUIRED_SKILLS[@]}"; do
        if [[ ! -d "${SCRIPT_DIR}/.claude/skills/${skill}" ]]; then
            handle_error "Required skill not found: ${skill}"
            valid=false
        elif [[ ! -f "${SCRIPT_DIR}/.claude/skills/${skill}/SKILL.md" ]]; then
            handle_error "SKILL.md missing in required skill: ${skill}"
            valid=false
        else
            print_success "Found required skill: ${skill}"
        fi
    done

    # Check optional components (warnings only)
    for skill in "${OPTIONAL_SKILLS[@]}"; do
        if [[ ! -d "${SCRIPT_DIR}/.claude/skills/${skill}" ]]; then
            log_warning "Optional skill not found: ${skill}"
        elif [[ ! -f "${SCRIPT_DIR}/.claude/skills/${skill}/SKILL.md" ]]; then
            log_warning "SKILL.md missing in optional skill: ${skill}"
        else
            print_success "Found optional skill: ${skill}"
        fi
    done

    # Check test framework
    if [[ ! -d "${SCRIPT_DIR}/.claude/${TEST_FRAMEWORK_DIR}" ]]; then
        log_warning "Test framework not found (required by cogworks-test)"
    else
        print_success "Found test framework"
    fi

    if ! $valid; then
        die "Source validation failed. Cannot proceed with installation."
    fi

    echo
}

check_existing_installation() {
    local target_path="$1"

    if [[ ! -d "$target_path" ]]; then
        return 1
    fi

    # Check for existing cogworks components
    local existing_components=()

    if [[ -f "${target_path}/agents/${AGENT_FILE}" ]]; then
        existing_components+=("cogworks agent")
    fi

    for skill in "${REQUIRED_SKILLS[@]}" "${OPTIONAL_SKILLS[@]}"; do
        if [[ -d "${target_path}/skills/${skill}" ]]; then
            existing_components+=("${skill} skill")
        fi
    done

    if [[ -d "${target_path}/${TEST_FRAMEWORK_DIR}" ]]; then
        existing_components+=("test framework")
    fi

    if [[ ${#existing_components[@]} -gt 0 ]]; then
        print_warning "Existing cogworks installation detected:"
        for component in "${existing_components[@]}"; do
            echo "    - $component"
        done
        echo
        return 0
    fi

    return 1
}

validate_target_path() {
    local target_path="$1"

    # If target is relative, resolve to absolute
    if [[ "$target_path" != /* ]]; then
        target_path="$(pwd)/${target_path}"
    fi

    # Normalize paths for comparison
    local normalized_target="$(cd "$(dirname "$target_path")" 2>/dev/null && pwd)/$(basename "$target_path")"
    local normalized_source="${SCRIPT_DIR}/.claude"

    # Prevent installing to the source location
    if [[ "$normalized_target" == "$normalized_source" ]]; then
        die "Cannot install to source location. Please choose a different installation path."
    fi

    # Get parent directory
    local parent_dir="$(dirname "$target_path")"

    # Check parent directory exists and is writable
    if [[ ! -d "$parent_dir" ]]; then
        die "Parent directory does not exist: $parent_dir"
    fi

    if [[ ! -w "$parent_dir" ]]; then
        die "No write permission for: $parent_dir"
    fi

    # If target exists, check it's writable
    if [[ -d "$target_path" ]] && [[ ! -w "$target_path" ]]; then
        die "No write permission for: $target_path"
    fi

    echo "$target_path"
}

#
# Installation Functions
#

create_directory_structure() {
    local target_path="$1"

    print_section "Creating directory structure..."

    local dirs=(
        "${target_path}"
        "${target_path}/agents"
        "${target_path}/skills"
        "${target_path}/${TEST_FRAMEWORK_DIR}"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if $DRY_RUN_MODE; then
                print_info "[DRY RUN] Would create: $dir"
            else
                mkdir -p "$dir"
                print_success "Created: $dir"
            fi
        else
            print_dim "Exists: $dir"
        fi
    done

    echo
}

install_agent() {
    local target_path="$1"
    local source_file="${SCRIPT_DIR}/.claude/agents/${AGENT_FILE}"
    local target_file="${target_path}/agents/${AGENT_FILE}"

    print_section "Installing cogworks agent..."

    if [[ -f "$target_file" ]]; then
        if $FORCE_MODE; then
            print_info "Overwriting existing agent (--force mode)"
        elif $INTERACTIVE_MODE; then
            if ! ask_yes_no "Agent already exists. Overwrite?" "n"; then
                log_warning "Skipped agent installation"
                return 0
            fi
        else
            log_warning "Agent exists, skipping (use --force to overwrite)"
            return 0
        fi
    fi

    if $DRY_RUN_MODE; then
        print_info "[DRY RUN] Would install: ${AGENT_FILE}"
    else
        cp "$source_file" "$target_file"
        log_installed "agents/${AGENT_FILE}"
        print_success "Installed: ${AGENT_FILE}"
    fi

    echo
}

install_skills() {
    local target_path="$1"

    print_section "Installing skills..."

    # Install required skills
    for skill in "${REQUIRED_SKILLS[@]}"; do
        local source_dir="${SCRIPT_DIR}/.claude/skills/${skill}"
        local target_dir="${target_path}/skills/${skill}"

        if [[ ! -d "$source_dir" ]]; then
            handle_error "Source skill directory not found: ${skill}"
            continue
        fi

        if [[ -d "$target_dir" ]]; then
            if $FORCE_MODE; then
                print_info "Overwriting existing skill: ${skill} (--force mode)"
            elif $INTERACTIVE_MODE; then
                if ! ask_yes_no "Skill '${skill}' already exists. Overwrite?" "n"; then
                    log_warning "Skipped: ${skill}"
                    continue
                fi
            else
                log_warning "Skill '${skill}' exists, skipping (use --force to overwrite)"
                continue
            fi
        fi

        if $DRY_RUN_MODE; then
            print_info "[DRY RUN] Would install required skill: ${skill}"
        else
            cp -r "$source_dir" "$target_dir"
            log_installed "skills/${skill}/"
            print_success "Installed required skill: ${skill}"
        fi
    done

    # Install optional skills
    for skill in "${OPTIONAL_SKILLS[@]}"; do
        local source_dir="${SCRIPT_DIR}/.claude/skills/${skill}"
        local target_dir="${target_path}/skills/${skill}"

        if [[ ! -d "$source_dir" ]]; then
            print_dim "Optional skill not found in archive: ${skill}"
            continue
        fi

        if [[ -d "$target_dir" ]]; then
            if $FORCE_MODE; then
                print_info "Overwriting existing skill: ${skill} (--force mode)"
            elif $INTERACTIVE_MODE; then
                if ! ask_yes_no "Skill '${skill}' already exists. Overwrite?" "n"; then
                    log_warning "Skipped: ${skill}"
                    continue
                fi
            else
                log_warning "Skill '${skill}' exists, skipping (use --force to overwrite)"
                continue
            fi
        fi

        if $DRY_RUN_MODE; then
            print_info "[DRY RUN] Would install optional skill: ${skill}"
        else
            cp -r "$source_dir" "$target_dir"
            log_installed "skills/${skill}/"
            print_success "Installed optional skill: ${skill}"
        fi
    done

    echo
}

install_test_framework() {
    local target_path="$1"
    local source_dir="${SCRIPT_DIR}/.claude/${TEST_FRAMEWORK_DIR}"
    local target_dir="${target_path}/${TEST_FRAMEWORK_DIR}"

    if [[ ! -d "$source_dir" ]]; then
        print_dim "Test framework not found in archive"
        return 0
    fi

    print_section "Installing test framework..."

    if [[ -d "$target_dir" ]]; then
        if $FORCE_MODE; then
            print_info "Overwriting existing test framework (--force mode)"
        elif $INTERACTIVE_MODE; then
            if ! ask_yes_no "Test framework already exists. Overwrite?" "n"; then
                log_warning "Skipped test framework installation"
                return 0
            fi
        else
            log_warning "Test framework exists, skipping (use --force to overwrite)"
            return 0
        fi
    fi

    if $DRY_RUN_MODE; then
        print_info "[DRY RUN] Would install: test-framework/"
    else
        # Create target directory if it doesn't exist
        mkdir -p "$target_dir"
        # Copy contents (not the directory itself)
        cp -r "$source_dir"/* "$target_dir"/
        log_installed "${TEST_FRAMEWORK_DIR}/"
        print_success "Installed: test-framework"
    fi

    echo
}

verify_installation() {
    local target_path="$1"

    if $DRY_RUN_MODE; then
        print_info "Skipping verification in dry-run mode"
        return 0
    fi

    print_section "Verifying installation..."

    local verification_passed=true

    # Verify agent
    if [[ -f "${target_path}/agents/${AGENT_FILE}" ]]; then
        print_success "Agent installed: ${AGENT_FILE}"
    else
        handle_error "Agent not found: ${AGENT_FILE}"
        verification_passed=false
    fi

    # Verify required skills
    for skill in "${REQUIRED_SKILLS[@]}"; do
        if [[ -f "${target_path}/skills/${skill}/SKILL.md" ]]; then
            print_success "Required skill installed: ${skill}"
        else
            handle_error "Required skill not found: ${skill}"
            verification_passed=false
        fi
    done

    # Verify optional skills (warnings only)
    for skill in "${OPTIONAL_SKILLS[@]}"; do
        if [[ -f "${target_path}/skills/${skill}/SKILL.md" ]]; then
            print_success "Optional skill installed: ${skill}"
        else
            print_dim "Optional skill not installed: ${skill}"
        fi
    done

    echo

    if ! $verification_passed; then
        die "Installation verification failed"
    fi
}

#
# Main Flow Control
#

show_installation_menu() {
    print_header "Cogworks Installation"

    echo "This script will install the cogworks agent and its skills to your chosen location."
    echo
    echo "Choose an installation mode:"
    echo
    echo "  1) Local (project)   - Install to ./.claude/"
    echo "     Use this for project-specific installation (shared via git)"
    echo
    echo "  2) Global (personal) - Install to ~/.claude/"
    echo "     Use this for personal installation (available across all projects)"
    echo
    echo "  3) Custom path       - Specify a custom installation path"
    echo
    echo "  4) Exit"
    echo

    local choice
    while true; do
        read -p "Enter your choice [1-4]: " choice
        case "$choice" in
            1)
                INSTALL_PATH="${MODE_LOCAL}"
                return 0
                ;;
            2)
                INSTALL_PATH="${MODE_GLOBAL}"
                return 0
                ;;
            3)
                read -p "Enter custom installation path: " INSTALL_PATH
                if [[ -z "$INSTALL_PATH" ]]; then
                    echo "Invalid path. Please try again."
                    continue
                fi
                return 0
                ;;
            4)
                echo "Installation cancelled."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
}

get_installation_path() {
    local mode="$1"

    case "$mode" in
        --local)
            echo "${MODE_LOCAL}"
            ;;
        --global)
            echo "${MODE_GLOBAL}"
            ;;
        *)
            die "Unknown installation mode: $mode"
            ;;
    esac
}

show_installation_summary() {
    local target_path="$1"

    print_header "Installation Summary"

    echo "Installation path: ${COLOR_BOLD}${target_path}${COLOR_RESET}"
    echo
    echo "Components to install:"
    echo "  - cogworks agent (${AGENT_FILE})"
    for skill in "${REQUIRED_SKILLS[@]}"; do
        echo "  - ${skill} skill (required)"
    done
    for skill in "${OPTIONAL_SKILLS[@]}"; do
        if [[ -d "${SCRIPT_DIR}/.claude/skills/${skill}" ]]; then
            echo "  - ${skill} skill (optional)"
        fi
    done
    if [[ -d "${SCRIPT_DIR}/.claude/${TEST_FRAMEWORK_DIR}" ]]; then
        echo "  - test-framework (optional)"
    fi
    echo

    # Check for existing installation
    if check_existing_installation "$target_path"; then
        if $FORCE_MODE; then
            print_info "Existing files will be overwritten (--force mode)"
        else
            print_warning "You will be prompted before overwriting existing files"
        fi
        echo
    fi

    if $DRY_RUN_MODE; then
        print_info "DRY RUN MODE: No files will be modified"
        echo
    fi
}

run_installation() {
    local target_path="$1"

    # Validate and normalize target path
    target_path="$(validate_target_path "$target_path")"

    # Show summary and confirm
    show_installation_summary "$target_path"

    if $INTERACTIVE_MODE && ! $DRY_RUN_MODE; then
        if ! ask_yes_no "Proceed with installation?" "y"; then
            echo "Installation cancelled."
            exit 0
        fi
        echo
    fi

    # Run installation steps
    create_directory_structure "$target_path"
    install_agent "$target_path"
    install_skills "$target_path"
    install_test_framework "$target_path"
    verify_installation "$target_path"

    # Show results
    show_success_message "$target_path"
}

show_success_message() {
    local target_path="$1"

    if $DRY_RUN_MODE; then
        print_header "Dry Run Complete"
        echo "No files were modified."
        return 0
    fi

    print_header "Installation Complete"

    if [[ ${#INSTALLED_FILES[@]} -gt 0 ]]; then
        echo "Successfully installed ${#INSTALLED_FILES[@]} component(s) to:"
        echo "  ${COLOR_BOLD}${target_path}${COLOR_RESET}"
        echo
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        print_warning "Installation completed with ${#WARNINGS[@]} warning(s)"
        for warning in "${WARNINGS[@]}"; do
            echo "    - $warning"
        done
        echo
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        print_error "Installation completed with ${#ERRORS[@]} error(s)"
        for error in "${ERRORS[@]}"; do
            echo "    - $error"
        done
        echo
        exit 1
    fi

    print_success "Cogworks is ready to use!"
    echo
    echo "Next steps:"
    echo "  1. Start Claude Code in your project directory"
    echo "  2. Use the cogworks agent: ${COLOR_BOLD}@cogworks encode <sources>${COLOR_RESET}"
    echo "  3. Or invoke skills directly: ${COLOR_BOLD}/cogworks-encode${COLOR_RESET} or ${COLOR_BOLD}/cogworks-learn${COLOR_RESET}"
    echo
    echo "For documentation, see:"
    echo "  - ${SCRIPT_DIR}/README.md"
    echo "  - https://github.com/williamhallatt/cogworks"
    echo
}

show_help() {
    cat << EOF
Cogworks Installation Script v${VERSION}

Usage:
  ./install.sh [OPTIONS]

Options:
  --local      Install to project directory (./.claude/)
  --global     Install to personal directory (~/.claude/)
  --force      Skip overwrite confirmations
  --dry-run    Preview changes without modifying files
  --help       Show this help message

Examples:
  ./install.sh                  # Interactive installation (recommended)
  ./install.sh --local          # Install to project
  ./install.sh --global         # Install to personal directory
  ./install.sh --global --force # Install to personal directory, overwrite existing

Interactive Mode (default):
  - Prompts for installation location
  - Shows summary before proceeding
  - Asks before overwriting existing files
  - Provides detailed progress updates

Non-Interactive Mode:
  - Use --local or --global to specify installation target
  - Use --force to skip overwrite prompts
  - Useful for automation and CI/CD

For more information, see INSTALL.md or visit:
https://github.com/williamhallatt/cogworks

EOF
}

#
# Argument Parsing & Entry Point
#

parse_arguments() {
    local mode=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local)
                mode="--local"
                INTERACTIVE_MODE=false
                shift
                ;;
            --global)
                mode="--global"
                INTERACTIVE_MODE=false
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN_MODE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                die "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done

    if [[ -n "$mode" ]]; then
        INSTALL_PATH="$(get_installation_path "$mode")"
    fi
}

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Validate source archive
    validate_source_archive

    # Interactive menu if no mode specified
    if [[ -z "$INSTALL_PATH" ]]; then
        show_installation_menu
    fi

    # Run installation
    run_installation "$INSTALL_PATH"
}

# Execute main function
main "$@"
