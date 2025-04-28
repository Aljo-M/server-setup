#!/usr/bin/env bash
# ufw-hardening.sh: Harden the UFW firewall with improved checks and user feedback
# Usage: sudo ./ufw-hardening.sh
# Ensure UFW_PORTS and SSH_PORT are set if defaults (80, 443 for UFW_PORTS; 22 for SSH_PORT) are not desired.

set -euo pipefail

# 1. Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Load logging & error‐handling
source "$SCRIPT_DIR/../functions/log-utils.sh"

# Define default variables if not set
SSH_PORT="${SSH_PORT:-22}"              # Default SSH port
UFW_PORTS=("${UFW_PORTS[@]:-80 443}")   # Default ports to allow (e.g., HTTP, HTTPS)

# Set trap for error handling
trap 'handle_error $LINENO' ERR

# Function to check if a port is already allowed in UFW
is_port_allowed() {
  local port=$1
  ufw status | grep -q "$port" && return 0 || return 1
}

log "INFO" "=== Setting up UFW Firewall ==="

# 1. Check if UFW is installed
if ! command -v ufw &>/dev/null; then
  log "ERROR" "UFW is not installed. Please install UFW and try again."
  exit 1
fi

# 2. Validate SSH_PORT
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
  log "ERROR" "Invalid SSH_PORT: $SSH_PORT. Must be a number between 1 and 65535."
  exit 1
fi

# 3. Display planned actions
log "INFO" "The following actions will be performed:"
log "INFO" "- Reset UFW firewall (if active)"
log "INFO" "- Set default deny incoming and allow outgoing"
log "INFO" "- Allow specified ports: ${UFW_PORTS[*]}"
log "INFO" "- Apply rate limiting for SSH on port $SSH_PORT"
log "INFO" "- Enable UFW"
log "INFO" "- Restart SSH service"

# 4. Reset UFW only if necessary
if ufw status | grep -q "Status: active"; then
  log "INFO" "UFW is active. Resetting UFW firewall."
  ufw --force reset
else
  log "INFO" "UFW is not active. Initializing UFW."
fi

# 5. Set default policies
log "INFO" "Setting default deny incoming and allow outgoing"
ufw default deny incoming
ufw default allow outgoing

# 6. Allow specified ports idempotently
log "INFO" "Allowing specified ports"
for port in "${UFW_PORTS[@]}"; do
  if is_port_allowed "$port"; then
    log "INFO" "Port $port is already allowed."
  else
    ufw allow "$port"
    log "INFO" "Allowed port $port"
  fi
done

# 7. Apply SSH rate limiting idempotently
log "INFO" "Checking rate limiting for SSH on port $SSH_PORT"
if ufw status | grep -q "$SSH_PORT/tcp.*LIMIT"; then
  log "INFO" "Rate limiting already applied for SSH on port $SSH_PORT."
else
  ufw limit "$SSH_PORT/tcp"
  log "INFO" "Applied rate limiting for SSH on port $SSH_PORT"
fi

# 8. Enable UFW idempotently
if ufw status | grep -q "Status: inactive"; then
  log "INFO" "Enabling UFW"
  ufw --force enable
else
  log "INFO" "UFW is already enabled."
fi

# 9. Restart SSH service
log "INFO" "Restarting SSH service"
systemctl restart ssh

# 10. Verify SSH accessibility
if nc -z localhost "$SSH_PORT" 2>/dev/null; then
  log "INFO" "SSH is accessible on port $SSH_PORT."
else
  log "WARN" "SSH may not be accessible on port $SSH_PORT. Please check the configuration."
fi

# 11. Log final UFW status
log "INFO" "Final UFW status:"
ufw status verbose

log "INFO" "=== UFW Firewall setup completed ==="