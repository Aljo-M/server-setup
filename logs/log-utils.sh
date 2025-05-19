#!/usr/bin/env bash
# logs/log-utils.sh - Production-ready logging utilities with ANSI color support
#
# Usage:
#   1. Place this script in your project, e.g., logs/log-utils.sh
#
#   2. Optionally configure before sourcing:
#        export LOG_FILE="/path/to/your/logfile.log"   # Default: logs/error.log next to this script
#        export LOG_LEVEL="WARNING"                    # Options: ERROR, WARNING, INFO, SUCCESS (default SUCCESS)
#        export ENABLE_COPROC_LOGGING=0                # Optional: redirect stderr to logger (enabled by default)
#        export LOG_ROTATE_SIZE="10M"  
#        export USE_SYSLOG=1                            # Optional: send logs to syslog (disabled by default)
#
#   3. Source it in your Bash scripts to enable logging functions:
#        source logs/log-utils.sh
#
#   4. Use the logging functions in your script:
#        log_info "Informational message"
#        log_success "Operation succeeded"
#        log_warning "Warning message"
#        log_error "Error message"
#
#   5. The script automatically traps errors and logs them with details.
#
# Features:
#   - Colorized console output with timestamps
#   - Timestamped log file entries
#   - Configurable log file location and log level filtering
#   - Automatic error trapping with detailed stack traces
#   - Safe and portable Bash code
#   - Optional stderr redirection via coprocess
#   - Optional syslog integration

set -euo pipefail

# === Configuration Section ===
# Define default values and environment variables for logging behavior

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Resolve the directory of this script (supports sourcing)
LOG_FILE="${LOG_FILE:-${SCRIPT_DIR}/error.log}" # Configurable log file path (default to logs/error.log)
LOG_LEVEL="${LOG_LEVEL:-SUCCESS}" # Default log level: ERROR, WARNING, INFO, SUCCESS
LOG_ROTATE_SIZE="${LOG_ROTATE_SIZE:-10M}"  # Default log rotation size
ENABLE_COPROC_LOGGING="${ENABLE_COPROC_LOGGING:-1}" # Enabled by default
USE_SYSLOG="${USE_SYSLOG:-0}"

# === Setup ===

# Ensure the log directory exists before redirecting stderr
if ! mkdir -p "$(dirname "$LOG_FILE")"; then
  echo "Failed to create log directory for $LOG_FILE" >&2
  exit 1
fi

# Validate the configured LOG_LEVEL value
declare -A _LOG_LEVELS=( ["ERROR"]=0 ["WARNING"]=1 ["INFO"]=2 ["SUCCESS"]=2 )
if [[ -z "${_LOG_LEVELS[$LOG_LEVEL]+x}" ]]; then
  echo "Invalid LOG_LEVEL: $LOG_LEVEL. Valid levels: ${!_LOG_LEVELS[*]}" >&2
  exit 1
fi

# === ANSI Color Codes ===
# Using a darker color palette for better readability
readonly COLOR_RESET="\033[0m"
readonly COLOR_INFO="\033[38;5;23m"     # darker slate blue
readonly COLOR_SUCCESS="\033[38;5;82m"  # darker spring green
readonly COLOR_WARNING="\033[38;5;178m" # darker gold
readonly COLOR_ERROR="\033[38;5;160m"   # darker orange-red

# === Internal Helper Functions ===
# Core functions implementing logging behavior

# Check if a message should be logged based on current LOG_LEVEL
_should_log() {
  local level="$1"
  [[ ${_LOG_LEVELS[$level]} -le ${_LOG_LEVELS[$LOG_LEVEL]} ]]
}

# Write timestamped message to log file
_log_to_file() {
  local level="$1"
  local message="$2"
  if _should_log "$level"; then
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >> "$LOG_FILE"
  fi
}

# Send message to syslog if enabled
_log_to_syslog() {
  local level="$1"
  local message="$2"
  if [[ "$USE_SYSLOG" = "1" && -x "$(command -v logger)" && $_LOG_LEVELS["$level"] -le 1 ]]; then
    logger -t "script_logger" -p "user.${level,,}" -- "$message"
  fi
}

# General log function: color output + file output
_log() {
  local level="$1"
  local color="$2"
  local message="$3"
  if _should_log "$level"; then
    # Print to stdout with color
    printf '%s %b[%s] %s%b\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$color" "$level" "$message" "$COLOR_RESET"
    # Append to log file
    _log_to_file "$level" "$message"
    # Optional syslog
    _log_to_syslog "$level" "$message"
  fi
}

# === Public logging functions ===

log_info()    { _log "INFO"    "$COLOR_INFO"    "$@"; }
log_success() { _log "SUCCESS" "$COLOR_SUCCESS" "$@"; }
log_warning() { _log "WARNING" "$COLOR_WARNING" "$@"; }
log_error()   { _log "ERROR"   "$COLOR_ERROR"   "$@"; }

# === Error Handling Mechanism ===
# Sets up error trapping with detailed diagnostics

handle_error() {
  local exit_code=$?
  local line_no=${BASH_LINENO[0]:-unknown}
  local func="${FUNCNAME[1]:-MAIN}"
  local script_name
  script_name="$(basename "${BASH_SOURCE[1]:-${0}}")"

  log_error "Script '${script_name}', function '${func}', line ${line_no}: exited with status ${exit_code}"

  # Print stack trace for debugging
  log_error "=== Stack trace ==="
  local i=0
  while caller "$i"; do
    ((i++))
  done

  exit "$exit_code"
}

trap 'handle_error' ERR


# === Log Rotation Management ===
# Handles log file size limits and rotation

rotate_log_if_needed() {
  local max_size_kb
  max_size_kb=$(echo "$LOG_ROTATE_SIZE" | sed -E 's/([0-9]+).*/\1/')

  case "$LOG_ROTATE_SIZE" in
    *K) max_size_kb="$max_size_kb";;
    *M) max_size_kb=$((max_size_kb * 1024));;
    *G) max_size_kb=$((max_size_kb * 1024 * 1024));;
    *)  max_size_kb=10240;; # default to 10MB
  esac

  if [[ -f "$LOG_FILE" ]]; then
    local current_size_kb
    current_size_kb=$(du -k "$LOG_FILE" | awk '{print $1}')
    if (( current_size_kb > max_size_kb )); then
      if mv "$LOG_FILE"{,.old} && touch "$LOG_FILE"; then
        log_info "Successfully rotated log file: $LOG_FILE"
      else
        log_error "Failed to rotate log file: $LOG_FILE"
      fi
    fi
  fi
}

# Run log rotation at start
rotate_log_if_needed


# === Advanced STDERR Redirection (Optional) ===
# WARNING: This feature may cause deadlocks with high stderr output volume.
# Use only after verifying script behavior under expected load conditions.
# Enable only when you're sure your script won't flood stderr
if [[ "$ENABLE_COPROC_LOGGING" = "1" ]]; then
  exec 3>&2
  coproc LOG_ERRORS {
    while IFS= read -r line; do
      log_error "$line"
    done
  }
  exec 2>&"${LOG_ERRORS[1]}"
fi

# === End of log-utils.sh ===
