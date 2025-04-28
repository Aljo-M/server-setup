#!/usr/bin/env bash
# scripts/ssh-hardening.sh
# Idempotent SSH hardening: configures /etc/ssh/sshd_config and reloads sshd

set -euo pipefail

# 1. Determine script directory & load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/functions/log-utils.sh"       # defines log(), handle_error()
source "$SCRIPT_DIR/config/variable-loader.sh" "$@"
source "$SCRIPT_DIR/functions/ask-yes-no.sh"

# 2. Register error trap (after handle_error is defined)
trap 'handle_error $LINENO' ERR

# 3. CLI parsing
SSH_PORT_DEFAULT=${SSH_PORT:-22}
SSH_PORT="$SSH_PORT_DEFAULT"

show_help() {
  cat <<EOF
Usage: $0 [--ssh-port PORT] [--help]

Options:
  --ssh-port PORT  Port SSH will listen on (default: $SSH_PORT_DEFAULT)
  --help           Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh-port)
      SSH_PORT="$2"; shift 2;;
    --help)
      show_help;;
    *)
      log "WARNING" "Unknown option: $1"; show_help;;
  esac
done

# 4. Pre-flight: Must be root
if [[ $EUID -ne 0 ]]; then
  log "ERROR" "Must run as root."
  exit 1
fi

# 5. Backup sshd_config once
BACKUP="/etc/ssh/sshd_config.bak"
if [[ ! -f "$BACKUP" ]]; then
  log "INFO" "Backing up /etc/ssh/sshd_config → $BACKUP"
  cp /etc/ssh/sshd_config "$BACKUP"
else
  log "INFO" "Backup already exists at $BACKUP"
fi

# 6. Apply hardening settings
log "INFO" "Applying SSH hardening settings (port: $SSH_PORT)"
sed -ri "
  s/^#?Port .*/Port $SSH_PORT/;
  s/^#?Protocol .*/Protocol 2/;
  s/^#?PermitRootLogin .*/PermitRootLogin no/;
  s/^#?PasswordAuthentication .*/PasswordAuthentication no/;
  s/^#?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/;
  s/^#?KerberosAuthentication .*/KerberosAuthentication no/;
  s/^#?GSSAPIAuthentication .*/GSSAPIAuthentication no/;
  s/^#?HostbasedAuthentication .*/HostbasedAuthentication no/;
  s/^#?MaxAuthTries .*/MaxAuthTries 3/;
  s/^#?LoginGraceTime .*/LoginGraceTime 20/;
  s/^#?AllowTcpForwarding .*/AllowTcpForwarding no/;
  s/^#?PermitUserEnvironment .*/PermitUserEnvironment no/;
  s/^#?X11Forwarding .*/X11Forwarding no/;
  s/^#?ClientAliveInterval .*/ClientAliveInterval 300/;
  s/^#?ClientAliveCountMax .*/ClientAliveCountMax 1/;
  s|^#?Banner .*|Banner /etc/issue.net|
" /etc/ssh/sshd_config

log "INFO" "SSH configuration updated successfully"

# 7. Reload SSH daemon
log "INFO" "Reloading sshd service"
systemctl reload sshd

log "INFO" "=== ✅ SSH hardening complete (port: $SSH_PORT) ==="
