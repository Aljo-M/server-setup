#!/usr/bin/env bash
# audit_logging_hardening.sh: Enhance audit and logging on Linux
# Run as root

set -euo pipefail

# Load log utilities if available (optional)
[[ -f /0-server-setup/functions/log_utils.sh ]] && source /0-server-setup/functions/log_utils.sh

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "INFO" "=== [Audit & Logging Hardening] Starting ==="

# 1. Install auditd if not present
if ! command -v auditd &>/dev/null; then
  log "INFO" "Installing auditd and plugins"
  apt-get update -qq
  apt-get install -y auditd audispd-plugins
else
  log "INFO" "auditd already installed"
fi

# 2. Enable and start auditd service
log "INFO" "Enabling and starting auditd service"
systemctl enable --now auditd

# 3. Deploy best-practice auditd.conf for log rotation and disk space management
log "INFO" "Configuring /etc/audit/auditd.conf"
cat > /etc/audit/auditd.conf <<'EOF'
log_file = /var/log/audit/audit.log
log_format = RAW
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 20
num_logs = 10
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
EOF

# 4. Deploy a strong set of audit rules
log "INFO" "Setting audit rules in /etc/audit/rules.d/hardening.rules"
cat > /etc/audit/rules.d/hardening.rules <<'EOF'
# Monitor changes to critical authentication files
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity

# Monitor sudoers and SSH configurations
-w /etc/sudoers -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd

# Monitor user and group management binaries
-w /usr/sbin/useradd -p x -k user_mgmt
-w /usr/sbin/userdel -p x -k user_mgmt
-w /usr/sbin/usermod -p x -k user_mgmt

# Monitor privileged command executions
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged

# Monitor network environment changes
-w /etc/hosts -p wa -k network
-w /etc/hostname -p wa -k network
-w /etc/resolv.conf -p wa -k network

# Monitor kernel module loading/unloading
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
EOF

# 5. Reload audit rules safely
log "INFO" "Reloading audit rules"
augenrules --load

# 6. Restart auditd to apply all changes
log "INFO" "Restarting auditd service"
systemctl restart auditd

log "INFO" "=== [Audit & Logging Hardening] Complete ==="
log "INFO" "You can now use 'ausearch' or 'aureport' to review audit logs."

exit 0
