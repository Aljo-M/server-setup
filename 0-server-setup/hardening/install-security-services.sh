#!/usr/bin/env bash
# hardening/install_security_services.sh
# Idempotent install & configuration of auditd, Fail2Ban & AppArmor

set -euo pipefail

# 1. Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Load logging & error‐handling
source "$SCRIPT_DIR/functions/log-utils.sh"
trap 'handle_error $LINENO' ERR

# === CONFIGURATION ===
LOCKFILE="/var/lock/install_security_services.lock"
PKGS=(auditd fail2ban apparmor-utils)
SERVICES=(auditd fail2ban)

# 4. Prevent concurrent runs
if [[ -e "$LOCKFILE" ]]; then
  log "INFO" "Security services already installed/configured; exiting."
  exit 0
fi
touch "$LOCKFILE"

log "INFO" "Installing packages: ${PKGS[*]}"
apt-get update -y               || handle_error $LINENO
apt-get install -y "${PKGS[@]}" || handle_error $LINENO

# 5. Enforce AppArmor profiles
log "INFO" "Enforcing AppArmor profile for sshd"
if aa-status | grep -q usr.bin.sshd; then
  aa-enforce /etc/apparmor.d/usr.bin.sshd || handle_error $LINENO
else
  log "WARNING" "sshd AppArmor profile not found; skipping enforcement"
fi

# 6. Enable & start services
for svc in "${SERVICES[@]}"; do
  if systemctl is-enabled "$svc" &>/dev/null; then
    log "INFO" "$svc already enabled"
  else
    log "INFO" "Enabling $svc"
    systemctl enable "$svc" || handle_error $LINENO
  fi

  if systemctl is-active "$svc" &>/dev/null; then
    log "INFO" "$svc already running"
  else
    log "INFO" "Starting $svc"
    systemctl start "$svc" || handle_error $LINENO
  fi
done

log "INFO" "Core security services installed and running"

# 7. Cleanup
rm -f "$LOCKFILE"
log "INFO" "install_security_services.sh completed successfully."
