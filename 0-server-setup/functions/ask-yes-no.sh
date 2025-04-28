#!/usr/bin/env bash
# File: functions/ask_yes_no.sh
# A reusable yes/no prompt function with default answer handling

# ask_yes_no: Prompts user with a yes/no question and returns 0 (true) for yes or 1 (false) for no
# Parameters:
#   $1: The prompt question to display (default: "Are you sure?")
#   $2: The default answer when user presses Enter without input (default: "Y")
ask_yes_no() {
    local prompt="${1:-Are you sure?}"  # Default question if none provided
    local default="${2:-Y}"             # Default answer (Y or N)

    while true; do
        # Format prompt depending on default answer
        if [[ "${default^^}" == "Y" ]]; then
            read -rp "$prompt [Y/n]: " yn
        else
            read -rp "$prompt [y/N]: " yn
        fi

        # If user just presses ENTER, use default
        yn="${yn:-$default}"

        # Convert input to lowercase for case-insensitive comparison
        case "${yn,,}" in
            y|yes) return 0 ;;  # Yes response
            n|no)  return 1 ;;  # No response
            *)     # Invalid input
                echo "❗ Please answer yes (y) or no (n)." ;;
        esac
    done
}

# Example usage:
# ask_yes_no "Do you want to continue?" "Y"
# result=$?

# if [[ $result -eq 0 ]]; then
#     echo "You chose Yes."
# else
#     echo "You chose No."
# fi
