#!/usr/bin/env bash
# scripts/update_and_upgrade.sh
# Idempotent system update & unattended-upgrade module

set -euo pipefail

# 1. Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Load centralized logging & error-handling (defines log(), handle_error())
source "$SCRIPT_DIR/functions/log-utils.sh"

# 3. Register ERR trap to use your handle_error()
trap 'handle_error $LINENO' ERR

# === CONFIGURATION ===
LOCKFILE="/var/lock/update_and_upgrade.lock"

# 4. Ensure single instance
if [[ -e "$LOCKFILE" ]]; then
  log "INFO" "Update already in progress or completed; exiting."
  exit 0
fi
touch "$LOCKFILE"

log "INFO" "Starting system update & upgrade"

# 5. Non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# 6. Refresh package lists
log "INFO" "Running apt update"
apt update -y

# 7. Apply all upgrades
log "INFO" "Running apt full-upgrade"
apt full-upgrade -y
log "INFO" "Running apt dist-upgrade"
apt dist-upgrade -y

# 8. Install & configure unattended-upgrades
log "INFO" "Ensuring unattended-upgrades is installed"
apt install -y unattended-upgrades
log "INFO" "Configuring unattended-upgrades"
dpkg-reconfigure --priority=low unattended-upgrades

# 9. Cleanup
log "INFO" "Removing obsolete packages"
apt autoremove --purge -y

unset DEBIAN_FRONTEND
log "INFO" "System update & upgrade completed successfully"

# 11. Release lock
rm -f "$LOCKFILE"
log "INFO" "Update-and-upgrade module finished."
