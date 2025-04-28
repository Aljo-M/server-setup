#!/usr/bin/env bash
# Run as root. chmod +x setup_server.sh

set -euo pipefail

# === LOAD CONFIGURATION & UTILITIES ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source your centralized log‐utils (defines log() and handle_error())
source "$SCRIPT_DIR/functions/log-utils.sh"
source "$SCRIPT_DIR/config/variable-loader.sh" "$@"
source "$SCRIPT_DIR/functions/input-utils.sh"
source "$SCRIPT_DIR/functions/ask-yes-no.sh"
source "$SCRIPT_DIR/functions/log-utils.sh"

trap 'handle_error $LINENO' ERR

# === 2. PRE-FLIGHT CHECKS ===
if [[ $EUID -ne 0 ]]; then
  log "ERROR" "Must run as root."
  exit 1
fi
if [[ -e "${LOCKFILE:-/var/lock/setup_server.lock}" ]]; then
  log "INFO" "Setup already completed; exiting."
  exit 0
fi


# === 3. SYSTEM UPDATES & UNATTENDED UPGRADES ===
log "INFO" "Starting full system upgrade"
bash "$SCRIPT_DIR/hardening/update-and-upgrade.sh" || handle_error $LINENO

# === CONTAINER RUNTIME & ORCHESTRATION ===
log "INFO" "Installing Docker & Kubernetes"
bash "/install-kubernetes-docker.sh" || handle_error $LINENO

# === 4. CORE SECURITY SERVICES ===
bash "$SCRIPT_DIR/hardening/install-security-services.sh" || handle_error $LINENO

# === 5. HARDENING SCRIPTS ===
log "INFO" "Running password hardening"
bash "$SCRIPT_DIR/hardening/password-hardening.sh" || handle_error $LINENO

log "INFO" "Running kernel hardening"
bash "$SCRIPT_DIR/hardening/kernel-hardening.sh" || handle_error $LINENO

log "INFO" "Running filesystem hardening"
bash "$SCRIPT_DIR/hardening/filesystem-hardening.sh" || handle_error $LINENO

log "INFO" "Running audit-logging hardening"
bash "$SCRIPT_DIR/hardening/audit-logging-hardening.sh" || handle_error $LINENO

log "INFO" "Running SSH hardening"
bash "$SCRIPT_DIR/hardening/ssh-hardening.sh" || handle_error $LINENO

# === 6. USER MANAGEMENT ===
while ask_yes_no "Do you want to create a new user?" "Y"; do
  bash "$SCRIPT_DIR/users/create-user.sh" || handle_error $LINENO
done

# === 7. FIREWALL SETUP (UFW) ===
log "INFO" "Configuring UFW firewall"
bash "$SCRIPT_DIR/hardening/ufw-hardening.sh" || handle_error $LINENO

# === 8. TIME SYNCHRONIZATION ===
log "INFO" "Installing and enabling chrony"
apt install -y chrony || handle_error $LINENO
systemctl enable --now chrony || handle_error $LINENO

# === 9. MONITORING ===
log "INFO" "Installing Netdata"
bash "$SCRIPT_DIR/install-netdata.sh" || handle_error $LINENO

# === 11. FULL SYSTEM BACKUP ===
log "INFO" "Configuring full-system backup"
bash "$SCRIPT_DIR/backup/full-system-backup.sh" || handle_error $LINENO

# === 12. MARK COMPLETION ===
touch "${LOCKFILE:-/var/lock/setup_server.lock}" || handle_error $LINENO
log "INFO" "Production server setup complete."
