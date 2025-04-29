#!/usr/bin/env bash
set -euo pipefail

# 1. Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Load logging & error‐handling
source "$SCRIPT_DIR/../functions/log-utils.sh"
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
fs.protected_fifos = 1
fs.protected_regular = 1
EOF

# --- 2. Secure /tmp and /dev/shm ---
log "INFO" "Securing /tmp and /dev/shm mounts"

# Backup fstab first
cp "$FSTAB" "${FSTAB}.bak.$(date +%F-%H%M%S)" || handle_error $LINENO

# Check if /tmp is already mounted as tmpfs
if ! grep -q '^[^#]*[[:space:]]/tmp[[:space:]]' "$FSTAB"; then
    log "INFO" "Adding /tmp mount entry to fstab"
    echo "tmpfs /tmp tmpfs $TMP_OPTIONS 0 0" >> "$FSTAB"
    
    # Check if /tmp exists and create it if needed
    if [ ! -d "/tmp" ]; then
        mkdir -p /tmp
        chmod 1777 /tmp
    fi
fi

# Check if /dev/shm is already mounted
if ! grep -q '^[^#]*[[:space:]]/dev/shm[[:space:]]' "$FSTAB"; then
    log "INFO" "Adding /dev/shm mount entry to fstab"
    echo "tmpfs /dev/shm tmpfs $SHM_OPTIONS 0 0" >> "$FSTAB"
    
    # Check if /dev/shm exists and create it if needed
    if [ ! -d "/dev/shm" ]; then
        mkdir -p /dev/shm
        chmod 1777 /dev/shm
    fi
fi

# Remount with proper options if already mounted
if mount | grep -q "on /tmp type"; then
    log "INFO" "Remounting /tmp with hardened options"
    mount -o remount,"$TMP_OPTIONS" /tmp || log "WARNING" "Failed to remount /tmp, will be applied after reboot"
else
    log "INFO" "/tmp will be mounted with hardened options after reboot"
fi

if mount | grep -q "on /dev/shm type"; then
    log "INFO" "Remounting /dev/shm with hardened options"
    mount -o remount,"$SHM_OPTIONS" /dev/shm || log "WARNING" "Failed to remount /dev/shm, will be applied after reboot"
else
    log "INFO" "/dev/shm will be mounted with hardened options after reboot"
fi

# --- 3. Restrict /home directory permissions ---
log "INFO" "Restricting /home/* permissions"
if [ -d "/home" ]; then
    find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 0700 {} \; || log "WARNING" "Some home directories could not be restricted"
else
    log "WARNING" "/home directory not found"
fi

# --- 4. Disable uncommon/insecure filesystems ---
log "INFO" "Blacklisting uncommon filesystems"
cat > "$UNCOMMON_FS_CONF" <<EOF
# Blacklist uncommon and potentially insecure filesystems
install cramfs /bin/false
install freevxfs /bin/false
install jffs2 /bin/false
install hfs /bin/false
install hfsplus /bin/false
install squashfs /bin/false
install udf /bin/false
install fat /bin/false
install vfat /bin/false
install gfs2 /bin/false
EOF

# Don't blacklist NFS if it's needed (check if it's in use first)
if ! mount | grep -q "type nfs" && ! grep -q "nfs" /etc/fstab; then
    echo "install nfs /bin/false" >> "$UNCOMMON_FS_CONF"
fi

# --- 5. Restrict GRUB directory ---
if [ -d "/etc/grub.d" ]; then
    log "INFO" "Locking down /etc/grub.d"
    chown root:root /etc/grub.d
    chmod -R og-rwx /etc/grub.d
else
    log "WARNING" "/etc/grub.d directory not found"
fi

# --- 6. Harden critical auth files ---
if [ -f "/etc/shadow" ] && [ -f "/etc/gshadow" ]; then
    log "INFO" "Setting strict permissions on /etc/shadow and /etc/gshadow"
    chmod 0000 /etc/shadow /etc/gshadow
    chown root:shadow /etc/shadow /etc/gshadow
else
    log "WARNING" "Shadow password files not found"
fi

# --- 7. Apply sysctl settings ---
log "INFO" "Applying sysctl settings"
if sysctl --system; then
    log "INFO" "Sysctl settings applied successfully"
else
    log "WARNING" "Some sysctl settings may not have been applied properly"
fi

# --- 8. Update the initramfs to apply changes ---
log "INFO" "Updating initramfs to apply filesystem hardening changes"
update-initramfs -u || log "WARNING" "Failed to update initramfs"

log "INFO" "[Filesystem Hardening] Complete. Reboot recommended."