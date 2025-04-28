#!/bin/bash
set -euo pipefail

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/functions/log-utils.sh"
source "$SCRIPT_DIR/lib/variable-loader.sh" "$@"

trap 'handle_error $LINENO' ERR

log "INFO" "Starting user setup process"

# Check if user exists
if id "$USERNAME" &>/dev/null; then
  log "ERROR" "User $USERNAME already exists"
  exit 1
fi

# Create user
log "INFO" "Creating user: $USERNAME"
adduser --disabled-password --gecos "" "$USERNAME"

USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Setup SSH directory
log "INFO" "Configuring SSH keys for $USERNAME"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
echo "$PUBLIC_KEY" | tee -a "$AUTHORIZED_KEYS" >/dev/null
chmod 600 "$AUTHORIZED_KEYS"
chown -R "$USERNAME:$USERNAME" "$SSH_DIR"

# Configure sudo access
if [[ "${ADD_TO_SUDO:-no}" == "yes" ]]; then
  log "INFO" "Adding $USERNAME to sudoers"
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/$USERNAME" >/dev/null
  chmod 0440 "/etc/sudoers.d/$USERNAME"
fi

# Configure Docker access
if [[ "${ADD_TO_DOCKER:-no}" == "yes" ]]; then
  log "INFO" "Adding $USERNAME to docker group"
  
  if ! command -v docker &>/dev/null; then
    log "WARN" "Docker not found - attempting installation"
    bash "$PROJECT_ROOT/scripts/install_docker.sh"
  fi
  
  usermod -aG docker "$USERNAME"
fi

log "INFO" "Setup completed successfully for user: $USERNAME"