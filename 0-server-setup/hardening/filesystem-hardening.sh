#!/usr/bin/env bash

set -euo pipefail

# --- Load helpers ---
source /0-server-setup/functions/log_utils.sh

log "INFO" "[Filesystem Hardening] Starting..."

# --- Variables ---
SYSCTL_FS_HARDENING="/etc/sysctl.d/50-fs-hardening.conf"
FSTAB="/etc/fstab"
TMP_OPTIONS="defaults,noexec,nosuid,nodev"
SHM_OPTIONS="defaults,noexec,nosuid,nodev"
UNCOMMON_FS_CONF="/etc/modprobe.d/uncommon-fs.conf"

# --- 1. Protect hardlinks and symlinks ---
log "INFO" "Configuring protected_hardlinks and protected_symlinks"
cat > "$SYSCTL_FS_HARDENING" <<EOF
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

# --- 2. Secure /tmp and /dev/shm ---
log "INFO" "Securing /tmp and /dev/shm mounts"

# Backup fstab first
cp "$FSTAB" "${FSTAB}.bak.$(date +%F-%H%M%S)" || handle_error $LINENO

# Ensure tmpfs entries for /tmp and /dev/shm
grep -q '^[^#]*[[:space:]]/tmp[[:space:]]' "$FSTAB" || echo "tmpfs /tmp tmpfs $TMP_OPTIONS 0 0" >> "$FSTAB"
grep -q '^[^#]*[[:space:]]/dev/shm[[:space:]]' "$FSTAB" || echo "tmpfs /dev/shm tmpfs $SHM_OPTIONS 0 0" >> "$FSTAB"

# Remount immediately
mount -o remount,"$TMP_OPTIONS" /tmp || handle_error $LINENO
mount -o remount,"$SHM_OPTIONS" /dev/shm || handle_error $LINENO

# --- 3. Restrict /home directory permissions ---
log "INFO" "Restricting /home/* permissions"
find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 0700 {} \; || true

# --- 4. Disable uncommon/insecure filesystems ---
log "INFO" "Blacklisting uncommon filesystems"
cat > "$UNCOMMON_FS_CONF" <<EOF
install cramfs /bin/false
install freevxfs /bin/false
install jffs2 /bin/false
install hfs /bin/false
install hfsplus /bin/false
install squashfs /bin/false
install udf /bin/false
install fat /bin/false
install vfat /bin/false
install nfs /bin/false
install gfs2 /bin/false
EOF

# --- 5. Restrict GRUB directory ---
log "INFO" "Locking down /etc/grub.d"
chown root:root /etc/grub.d
chmod -R og-rwx /etc/grub.d

# --- 6. Harden critical auth files ---
log "INFO" "Setting strict permissions on /etc/shadow and /etc/gshadow"
chmod 000 /etc/shadow /etc/gshadow

# --- 7. Apply sysctl settings ---
log "INFO" "Applying sysctl settings"
sysctl --system || handle_error $LINENO

log "INFO" "[Filesystem Hardening] Complete. Reboot recommended."
