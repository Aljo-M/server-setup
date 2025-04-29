#!/usr/bin/env bash
# Run as root. chmod +x setup_server.sh
set -euo pipefail

# === LOAD CONFIGURATION & UTILITIES ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized utilities
if [ ! -f "$SCRIPT_DIR/functions/log-utils.sh" ]; then
    echo "ERROR: Required utility files not found!"
    exit 1
fi

source "$SCRIPT_DIR/functions/log-utils.sh"
source "$SCRIPT_DIR/config/variable-loader.sh" "$@" || {
    log "ERROR" "Failed to load configuration variables"
    exit 1
}
source "$SCRIPT_DIR/functions/input-utils.sh"
source "$SCRIPT_DIR/functions/ask-yes-no.sh"

log "INFO" "Server setup script started (version: 1.2.0)"
trap 'handle_error $LINENO' ERR

# === PRE-FLIGHT CHECKS ===
if [[ $EUID -ne 0 ]]; then
    log "ERROR" "This script must run as root"
    exit 1
fi

# Create lockfile directory if it doesn't exist
LOCKFILE="${LOCKFILE:-/var/lock/setup_server.lock}"
mkdir -p "$(dirname "$LOCKFILE")" 2>/dev/null || true

if [[ -e "$LOCKFILE" ]]; then
    if ! ask_yes_no "Setup appears to have run before. Continue anyway?" "N"; then
        log "INFO" "Setup aborted by user"
        exit 0
    else
        log "INFO" "Continuing with setup despite existing lock file"
    fi
fi

# Check internet connectivity
if ! ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
    log "WARNING" "Internet connectivity check failed"
    if ! ask_yes_no "Internet connection appears to be down. Continue anyway?" "N"; then
        log "ERROR" "Setup aborted: no internet connection"
        exit 1
    fi
fi

# === SYSTEM UPDATES & UNATTENDED UPGRADES ===
log "INFO" "Starting full system upgrade"
bash "$SCRIPT_DIR/hardening/update-and-upgrade.sh" || {
    log "ERROR" "System update failed"
    if ! ask_yes_no "Continue despite system update failure?" "N"; then
        exit 1
    fi
}

# === CONTAINER RUNTIME & ORCHESTRATION ===
log "INFO" "Installing Docker & Kubernetes"
if ! bash "$SCRIPT_DIR/install-kubernetes-docker.sh"; then
    log "ERROR" "Docker/Kubernetes installation failed"
    if ! ask_yes_no "Continue despite Docker/Kubernetes installation failure?" "N"; then
        exit 1
    fi
fi

# === CORE SECURITY SERVICES ===
log "INFO" "Installing core security services"
if ! bash "$SCRIPT_DIR/hardening/install-security-services.sh"; then
    log "WARNING" "Some security services may not be installed correctly"
    if ! ask_yes_no "Continue despite security services installation issues?" "Y"; then
        exit 1
    fi
fi

# === HARDENING SCRIPTS ===
# Password hardening (non-interactive mode for automation)
log "INFO" "Running password hardening"
export AUTOMATED_PASSWORD_UPDATE="${AUTOMATED_PASSWORD_UPDATE:-false}"
if [[ "$AUTOMATED_PASSWORD_UPDATE" == "true" && -n "${ROOT_PASSWORD:-}" ]]; then
    # For automated deployments with preset password
    echo "root:$ROOT_PASSWORD" | chpasswd
    log "INFO" "Root password updated automatically"
else
    bash "$SCRIPT_DIR/hardening/password-hardening.sh" || log "WARNING" "Password hardening encountered issues"
fi

# Kernel hardening
log "INFO" "Running kernel hardening"
bash "$SCRIPT_DIR/hardening/kernel-hardening.sh" || log "WARNING" "Kernel hardening encountered issues"

# Filesystem hardening
log "INFO" "Running filesystem hardening"
bash "$SCRIPT_DIR/hardening/filesystem-hardening.sh" || log "WARNING" "Filesystem hardening encountered issues"

# Audit logging hardening
log "INFO" "Running audit-logging hardening"
bash "$SCRIPT_DIR/hardening/audit-logging-hardening.sh" || log "WARNING" "Audit logging setup encountered issues"

# SSH hardening
log "INFO" "Running SSH hardening"
bash "$SCRIPT_DIR/hardening/ssh-hardening.sh" || log "WARNING" "SSH hardening encountered issues"

# === USER MANAGEMENT ===
if [[ "${AUTOMATED_SETUP:-false}" != "true" ]]; then
    # Interactive user creation
    while ask_yes_no "Do you want to create a new user?" "Y"; do
        bash "$SCRIPT_DIR/users/create-user.sh" || log "WARNING" "User creation failed"
    done
elif [[ -n "${DEFAULT_USERNAME:-}" && -n "${DEFAULT_PASSWORD:-}" ]]; then
    # Automated user creation with preset credentials
    log "INFO" "Creating default user $DEFAULT_USERNAME"
    useradd -m -s /bin/bash "$DEFAULT_USERNAME"
    echo "$DEFAULT_USERNAME:$DEFAULT_PASSWORD" | chpasswd
    if [[ -n "${DEFAULT_SUDO:-}" ]] && [[ "$DEFAULT_SUDO" == "true" ]]; then
        usermod -aG sudo "$DEFAULT_USERNAME"
    fi
    log "INFO" "Default user created"
fi

# === FIREWALL SETUP (UFW) ===
log "INFO" "Configuring UFW firewall"
bash "$SCRIPT_DIR/hardening/ufw-hardening.sh" || log "WARNING" "Firewall setup encountered issues"

# === TIME SYNCHRONIZATION ===
log "INFO" "Installing and enabling chrony"
apt-get update -qq
apt-get install -y chrony || log "WARNING" "Chrony installation failed"
systemctl enable --now chrony || log "WARNING" "Failed to enable chrony service"

# === MONITORING ===
log "INFO" "Installing Netdata"
if ! bash "$SCRIPT_DIR/install-netdata.sh"; then
    log "WARNING" "Netdata installation failed"
    if ! ask_yes_no "Continue despite monitoring setup failure?" "Y"; then
        exit 1
    fi
fi

# === FULL SYSTEM BACKUP ===
log "INFO" "Configuring full-system backup"
if ! bash "$SCRIPT_DIR/backup/full-system-backup.sh"; then
    log "WARNING" "Backup configuration failed"
    if ! ask_yes_no "Continue despite backup setup failure?" "Y"; then
        exit 1
    fi
fi

# === MARK COMPLETION ===
touch "$LOCKFILE" || log "WARNING" "Could not create lock file"
log "INFO" "Production server setup complete. A system reboot is recommended."

# Final instructions
cat <<EOF
=====================================================================
SERVER SETUP COMPLETE - IMPORTANT NEXT STEPS
=====================================================================
1. Review logs for any warnings or errors
2. Reboot the server to apply all changes:
   $ sudo reboot

For security best practices:
- Ensure root login via SSH is disabled
- Use key-based authentication rather than passwords
- Keep the system regularly updated
- Monitor logs for suspicious activities
=====================================================================
EOF