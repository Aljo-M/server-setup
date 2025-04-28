#!/usr/bin/env bash
# scripts/kernel-hardening.sh
# Idempotent kernel hardening: sysctl tweaks and module blacklisting

set -euo pipefail

# --- 1. Determine script directory & load helpers ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../functions/log-utils.sh"   # defines log(), handle_error()

trap 'handle_error $LINENO' ERR

# --- 2. Configuration ---
LOCKFILE="/var/lock/kernel_hardening.lock"
SYSCTL_CONF="/etc/sysctl.d/99-kernel-hardening.conf"
BLACKLIST_CONF="/etc/modprobe.d/blacklist-harden.conf"
SYSCTL_BACKUP="${SYSCTL_CONF}.bak"
TIMESTAMP="$(date +%F-%H%M%S)"

# --- 3. Prevent concurrent runs ---
if [[ -e "$LOCKFILE" ]]; then
  log "INFO" "Kernel hardening already applied; exiting."
  exit 0
fi

touch "$LOCKFILE"

# --- 4. Backup existing sysctl settings once ---
if [[ ! -f "$SYSCTL_BACKUP" ]]; then
  log "INFO" "Backing up existing sysctl config → ${SYSCTL_BACKUP}.${TIMESTAMP}"
  cp "$SYSCTL_CONF" "${SYSCTL_BACKUP}.${TIMESTAMP}" 2>/dev/null || \
    cp /etc/sysctl.conf "${SYSCTL_BACKUP}.${TIMESTAMP}"
else
  log "INFO" "Sysctl backup already exists at ${SYSCTL_BACKUP}.{timestamp}"  # placeholder note
fi

# --- 5. Write kernel hardening parameters ---
log "INFO" "Writing kernel hardening sysctl parameters to $SYSCTL_CONF"
cat > "$SYSCTL_CONF" <<EOF
# Kernel hardening - sysctl parameters

# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable IPv6 if not needed (uncomment if you don't use IPv6)
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1

# Kernel pointer restrictions
kernel.kptr_restrict = 2

# Restrict dmesg
kernel.dmesg_restrict = 1

# Disable core dumps
fs.suid_dumpable = 0

# Harden symlinks and hardlinks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Randomize virtual address space
kernel.randomize_va_space = 2

# Restrict ptrace
kernel.yama.ptrace_scope = 2

# Disable magic SysRq key
kernel.sysrq = 0
EOF

# --- 6. Apply sysctl ---
log "INFO" "Applying sysctl settings"
sysctl --system

# --- 7. Blacklist insecure modules ---
log "INFO" "Writing module blacklist to $BLACKLIST_CONF"
cat > "$BLACKLIST_CONF" <<EOF
# Blacklist uncommon/insecure filesystems and protocols
blacklist cramfs
blacklist freevxfs
blacklist jffs2
blacklist hfs
blacklist hfsplus
blacklist squashfs
blacklist udf
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
EOF

# --- 8. Update initramfs if available ---
if command -v update-initramfs &>/dev/null; then
  log "INFO" "Updating initramfs to apply module blacklist"
  update-initramfs -u
else
  log "WARNING" "update-initramfs not found; skipping initramfs update"
fi

# --- 9. Cleanup ---
rm -f "$LOCKFILE"
log "INFO" "Kernel hardening complete (reboot recommended)."
