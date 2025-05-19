#!/usr/bin/env bash
# server-setup.sh - Main server setup script: The entry point for setting up the server environment.
set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/logs/log-utils.sh"
source "$PROJECT_ROOT/configs/config-loader.sh"

# Now use PROJECT_ROOT
log_success "Project root: $PROJECT_ROOT"


if [ "$EUID" -ne 0 ]; then
  log_error "This script must be run as root (or via sudo). Aborting."
  exit 1
fi


log_success "Starting server-setup.sh at $PROJECT_ROOT"


bash "$PROJECT_ROOT/scripts/01-system-preparation.sh"
bash "$PROJECT_ROOT/scripts/02-user-management.sh"
bash "$PROJECT_ROOT/scripts/03-network-configuration.sh"
bash "$PROJECT_ROOT/scripts/03-ssh-hardening.sh"
bash "$PROJECT_ROOT/scripts/04-firewall.sh"
bash "$PROJECT_ROOT/scripts/05-security.sh"
bash "$PROJECT_ROOT/scripts/06-containerization.sh"
bash "$PROJECT_ROOT/scripts/07-backup.sh"
bash "$PROJECT_ROOT/scripts/08-monitoring.sh"

log_success "Server setup complete!"
