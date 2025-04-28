# input_utils.sh

# Function: get_input()
# Prompts user for input with a default value and validation
# Usage: result=$(get_input "Prompt text" "default_value")
get_input() {
    # Declare local variables to avoid conflicts with global variables
    local prompt="$1"    # First argument: Text to show the user
    local default="$2"   # Second argument: Default value if user presses Enter
    local input          # Variable to store user's input

    # Keep asking until valid input is received
    while true; do
        # -r: Backslash doesn't escape characters
        # -p: Show prompt before reading input
        read -rp "$prompt [$default]: " input
        
        # If input is empty, use the default value
        # ${var:-default} returns 'default' if $var is unset or empty
        input="${input:-$default}"
        
        # Final validation check (in case default was empty)
        if [ -z "$input" ]; then
            # Show error to standard error (>&2)
            echo "Error: Input cannot be empty" >&2
        else
            # Valid input received - exit the loop
            break
        fi
    done
    
    # Return the collected input to the caller
    echo "$input"
}

# How to use in other scripts:
# source ../functions/input_utils.sh
# username=$(get_input "Enter username" "admin")
# echo "You entered: $username"
