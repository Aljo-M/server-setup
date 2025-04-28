#!/usr/bin/env bash

# Logging function
log() {
  local level=$1
  local message=$2
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message"
}

# Error handling function
handle_error() {
  local exit_code=$?
  local line_no=$1
  log "ERROR" "Line $line_no: Command failed with exit code $exit_code"
  exit $exit_code
}