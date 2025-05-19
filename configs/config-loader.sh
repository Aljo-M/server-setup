#!/usr/bin/env bash
# config-loader.sh: Enhanced configuration loader for production server setup
# Handles configuration loading, validation, and .env file management with
# support for non-interactive mode and security best practices.

set -euo pipefail

trap 'handle_error $LINENO' ERR

# Determine PROJECT_ROOT (more robust)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/..")"

# Make sure log-utils.sh is sourced, even if run standalone
if ! declare -f log_info >/dev/null; then
    source "$PROJECT_ROOT/logs/log-utils.sh"
fi

# Constants
ENV_FILE="$PROJECT_ROOT/.env"
ENV_TEMPLATE="$PROJECT_ROOT/configs/env.template"
CONFIG_DIR="$PROJECT_ROOT/configs"

# Load variables from .env file if it exists
load_env_file() {
    if [ -f "$ENV_FILE" ]; then
        log_info "Loading configuration from $ENV_FILE"
        
        # Export variables from .env file, skipping comments
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            # Export the variable
            export "$line"
        done < "$ENV_FILE"
    else
        if [ -f "$ENV_TEMPLATE" ]; then
            log_info "Creating .env file from template"
            cp "$ENV_TEMPLATE" "$ENV_FILE"
            chmod 600 "$ENV_FILE"  # Secure permissions for .env
            load_env_file  # Recursively load the newly created file
        else
            log_warning ".env file not found in the project root. Creating a new one."
            touch "$ENV_FILE"
            chmod 600 "$ENV_FILE"  # Secure permissions for new .env
        fi
    fi
    
    # Verify .env file permissions
    local current_perms=$(stat -c "%a" "$ENV_FILE")
    if [ "$current_perms" != "600" ]; then
        log_warning ".env file has insecure permissions ($current_perms). Fixing..."
        chmod 600 "$ENV_FILE"
    fi
}

# Enhanced load_var function with validation, non-interactive mode, and improved security
load_var() {
    local var_name=$1
    local default_value=${2:-""}
    local validation_regex=${3:-""}
    local description=${4:-""}
    local is_secret=${5:-false}
    local current_value
    local user_input
    local confirm
    local non_interactive=${NON_INTERACTIVE:-false}

    # Evaluate the current value from environment if it exists
    eval "current_value=\${$var_name:-}"
    
    # Format description for display
    local display_desc=""
    [[ -n "$description" ]] && display_desc=" ($description)"
    
    # Log masking for secrets
    local log_value
    local display_value
    
    mask_if_secret() {
        local val=$1
        if [[ "$is_secret" == true && -n "$val" ]]; then
            echo "********"
        else
            echo "$val"
        fi
    }

    # Non-interactive mode handling
    if [[ "$non_interactive" == true ]]; then
        if [[ -n "$current_value" ]]; then
            log_info "Using existing value for $var_name: $(mask_if_secret "$current_value")"
            eval "export $var_name=\"$current_value\""
            return 0
        elif [[ -n "$default_value" ]]; then
            log_info "Using default value for $var_name: $(mask_if_secret "$default_value")"
            eval "export $var_name=\"$default_value\""
            update_env_file "$var_name" "$default_value"
            return 0
        else
            log_error "Required variable $var_name has no value in non-interactive mode!"
            exit 1
        fi
    fi

    # Interactive mode flow
    if [[ -n "$current_value" ]]; then
        display_value=$(mask_if_secret "$current_value")
        log_info "Found existing value for $var_name$display_desc: $display_value"
        read -p "Keep this value? (Y/n): " confirm

        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            prompt_for_value
        else
            log_info "Keeping existing value for $var_name"
            # We keep the value but still export it to ensure it's in the environment
            eval "export $var_name=\"$current_value\""
        fi
    elif [[ -n "$default_value" ]]; then
        display_value=$(mask_if_secret "$default_value")
        log_info "$var_name$display_desc is not set. Default: $display_value"
        read -p "Use default value? (Y/n): " confirm

        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            prompt_for_value
        else
            eval "export $var_name=\"$default_value\""
            log_info "$var_name is now set to default"
            update_env_file "$var_name" "$default_value"
        fi
    else
        log_warning "$var_name$display_desc is not set and has no default."
        prompt_for_value
    fi

    # Function to handle prompting for and validating values
    function prompt_for_value() {
        local prompt_text="Enter value for $var_name$display_desc"
        [[ "$is_secret" == true ]] && prompt_text="$prompt_text (input hidden)"
        
        while true; do
            if [[ "$is_secret" == true ]]; then
                read -s -p "$prompt_text: " user_input
                echo "" # Add newline after hidden input
            else
                read -p "$prompt_text: " user_input
            fi
            
            # Empty check
            if [[ -z "$user_input" ]]; then
                log_warning "Error: Value cannot be empty. Please enter a value."
                continue
            fi
            
            # Validation check
            if [[ -n "$validation_regex" && ! "$user_input" =~ $validation_regex ]]; then
                log_warning "Error: Invalid format. Value must match pattern: $validation_regex"
                continue
            fi
            
            # Value looks good
            eval "export $var_name=\"$user_input\""
            log_info "$var_name is now set"
            update_env_file "$var_name" "$user_input"
            break
        done
    }
}

# Helper function to update or add a variable in the .env file
update_env_file() {
    local var_name=$1
    local var_value=$2
    local backup_file="$ENV_FILE.bak"
    
    # Create a backup of the .env file
    cp "$ENV_FILE" "$backup_file"
    
    # Check if the variable already exists in the .env file
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        # Variable exists, update it
        sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$ENV_FILE"
        log_debug "Updated $var_name in .env file."
    else
        # Variable doesn't exist, append it
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
        log_debug "Added $var_name to .env file."
    fi
    
    # Ensure .env file has correct permissions
    chmod 600 "$ENV_FILE"
}

# Function to load a predefined configuration file
load_config_file() {
    local config_name=$1
    local config_file="$CONFIG_DIR/${config_name}.conf"
    
    if [ -f "$config_file" ]; then
        log_info "Loading configuration from $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
    else
        log_warning "Configuration file $config_file not found."
    fi
}

# Generate a secure random password
generate_password() {
    local length=${1:-16}
    local chars="A-Za-z0-9!#$%&()*+,-./:;<=>?@[]^_\`{|}~"
    
    # Use /dev/urandom for better entropy
    </dev/urandom tr -dc "$chars" | head -c "$length"
}

# Function to validate IP address format
validate_ip() {
    local ip=$1
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ ! $ip =~ $regex ]]; then
        return 1
    fi
    
    # Validate each octet
    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ $octet -gt 255 ]]; then
            return 1
        fi
    done
    
    return 0
}

# Error handling function
handle_error() {
    local line="$1"
    log_error "An error occurred in $(basename "${BASH_SOURCE[1]}") at line $line"
    
    # Print stack trace
    local i=0
    local FRAMES=${#BASH_SOURCE[@]}
    
    echo "=== Stack trace ==="
    for ((i=1; i<FRAMES; i++)); do
        echo "  $i: ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]} in function ${FUNCNAME[$i]}"
    done
    
    exit 1
}

# Load environment variables
load_env_file

# Usage examples:
# Simple variable: load_var "HOSTNAME" "my-server"
# With validation: load_var "EMAIL" "" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Valid email address"
# Password/secret: load_var "DB_PASSWORD" "" "" "Database password" true
# IP address: load_var "SERVER_IP" "192.168.1.1" "^([0-9]{1,3}\.){3}[0-9]{1,3}$" "IPv4 address"