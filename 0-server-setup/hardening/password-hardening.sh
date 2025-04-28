#!/usr/bin/env bash
# hardening/password-hardening.sh
# Idempotent password complexity enforcement via PAM (libpam-pwquality)

set -euo pipefail

# --- 1. Setup & Helpers ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/functions/log-utils.sh"    # defines log() & handle_error()
source "$SCRIPT_DIR/functions/ask_yes_no.sh"   # defines ask_yes_no()

trap 'handle_error $LINENO' ERR

# --- 2. Configuration ---
LOCKFILE="/var/lock/password_hardening.lock"
PAM_COMMON="/etc/pam.d/common-password"
BACKUP="$PAM_COMMON.bak"

# --- 3. Prevent re‐runs ---
if [[ -e "$LOCKFILE" ]]; then
  log "INFO" "Password hardening already applied; exiting."
  exit 0
fi
touch "$LOCKFILE"

# --- 4. Install pam_pwquality ---
log "INFO" "Ensuring libpam-pwquality is installed"
if ! dpkg -l libpam-pwquality &>/dev/null; then
  apt-get update -y
  apt-get install -y libpam-pwquality
  log "INFO" "libpam-pwquality installed"
else
  log "INFO" "libpam-pwquality already present"
fi

# --- 5. Backup PAM config ---
if [[ ! -f "$BACKUP" ]]; then
  log "INFO" "Backing up $PAM_COMMON → $BACKUP"
  cp "$PAM_COMMON" "$BACKUP"
else
  log "INFO" "Backup already exists at $BACKUP"
fi

# --- 6. Insert pam_pwquality if missing ---
if ! grep -q 'pam_pwquality.so' "$PAM_COMMON"; then
  log "INFO" "Inserting pam_pwquality line into $PAM_COMMON"
  sed -ri '/^password\s+requisite\s+pam_unix.so/i \
    password requisite pam_pwquality.so retry=3' \
    "$PAM_COMMON"
else
  log "INFO" "pam_pwquality already configured"
fi

# --- 7. Apply complexity parameters ---
log "INFO" "Applying password complexity requirements"
sed -ri \
  's|^(password\s+requisite\s+pam_pwquality.so).*|\1 retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 enforce_for_root|' \
  "$PAM_COMMON"

log "INFO" "Password complexity parameters set"

# --- 8. Optional: set a new root password ---
if ask_yes_no "Set a new root password now?" "Y"; then
  log "INFO" "Prompting for new root password"
  passwd root
  log "INFO" "Root password updated"
else
  log "INFO" "Root password change skipped"
fi

# --- 9. Cleanup ---
rm -f "$LOCKFILE"
log "INFO" "Password hardening completed successfully."
