#!/usr/bin/env bash
# Logging utilities with a darker 256‑color ANSI palette

COLOR_RESET="\033[0m"

# Darkened variants of the original hues
COLOR_INFO="\033[38;5;23m"     # darker slate blue (vs. 75)
COLOR_SUCCESS="\033[38;5;82m"  # darker spring green (vs. 114) 
COLOR_WARNING="\033[38;5;178m" # darker gold (vs. 220)
COLOR_ERROR="\033[38;5;160m"   # darker orange‑red (vs. 196)

log_to_file() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> "$PROJECT_ROOT/logs/setup-logs.txt"
}

log_info() {
  local msg="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${COLOR_INFO}[INFO] $msg${COLOR_RESET}"
  log_to_file "INFO" "$msg"
}

log_success() {
  local msg="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${COLOR_SUCCESS}[SUCCESS] $msg${COLOR_RESET}"
  log_to_file "SUCCESS" "$msg"
}

log_warning() {
  local msg="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${COLOR_WARNING}[WARNING] $msg${COLOR_RESET}"
  log_to_file "WARNING" "$msg"
}

log_error() {
  local msg="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${COLOR_ERROR}[ERROR] $msg${COLOR_RESET}"
  log_to_file "ERROR" "$msg"
}

handle_error() {
  local line="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${COLOR_ERROR}[ERROR] at line $line${COLOR_RESET}"
  log_to_file "ERROR" "at line $line"
  exit 1
}
