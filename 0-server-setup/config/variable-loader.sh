#!/usr/bin/env bash
# lib/variable_loader.sh — reusable argument loader
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/../config/variable_loader.sh" "$@"

# 1. find_root: walk up until finding server-setup.sh
find_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/server-setup.sh" ]] && { echo "$dir"; return; }
    dir="$(dirname "$dir")"
  done
  echo "ERROR: server-setup.sh not found" >&2
  exit 1
}

# 2. Load config
PROJECT_ROOT="$(find_root)"
VARIABLES_CONFIG="$PROJECT_ROOT/config/variables.conf"

if [[ -f "$VARIABLES_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$VARIABLES_CONFIG"
else
    echo "ERROR: variables.conf not found in $VARIABLES_CONFIG" >&2
    exit 1
fi

# 3. help text
show_help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  for key in "${!ARG_VAR_NAME[@]}"; do
    var="${ARG_VAR_NAME[$key]}"
    desc="${ARG_DESC[$key]}"
    def="${ARG_DEFAULT[$key]:-<required>}"
    printf "  %-15s %-12s %s (default: %s)\n" \
           "$key" "$var" "$desc" "$def"
  done
  echo
}

# 4. init defaults
for key in "${!ARG_VAR_NAME[@]}"; do
  var="${ARG_VAR_NAME[$key]}"
  def="${ARG_DEFAULT[$key]}"
  declare "${var}=${!var:-$def}"
done

# 5. parse overrides
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) show_help; exit 0 ;;
        --?*)
            opt="$1"; shift
            if [[ -z "${ARG_VAR_NAME[$opt]+x}" ]]; then
                echo "Unknown option: $opt" >&2
                show_help
                exit 1
            fi
            var="${ARG_VAR_NAME[$opt]}"
            val="$1"; shift
            declare "${var}=$val"
            ;;
        *)
            echo "Unknown argument: $1" >&2
            show_help
            exit 1 ;;
    esac
done

# 6. prompt for required/unset
for key in "${!ARG_VAR_NAME[@]}"; do
    var="${ARG_VAR_NAME[$key]}"
    desc="${ARG_DESC[$key]}"
    if [[ -z "${!var}" ]]; then
        read -rp "Enter ${key#--} ($desc): " val
        declare "${var}=$val"
    fi
done

# 7. export for children
# for key in "${!ARG_VAR_NAME[@]}"; do
#   var="${ARG_VAR_NAME[$key]}"
#   export "$var"
# done

# 8. echo all loaded variables
# echo
# echo "=== Loaded Configuration Variables ==="
# for key in "${!ARG_VAR_NAME[@]}"; do
#   var="${ARG_VAR_NAME[$key]}"
#   # Indirect expansion to get the variable's value
#   printf "%-20s = %s\n" "$var" "${!var}"
# done
# echo "======================================"
