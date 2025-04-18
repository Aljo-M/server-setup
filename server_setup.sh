#!/usr/bin/env bash
# This script updates packages, creates any user, hardens SSH and configures the UFW firewall.
# Run as root. chmod +x setup_server.sh

set -euo pipefail

# 1. Ensure root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Must run as root."
  exit 1
fi

# 2. Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_USER_SCRIPT="$SCRIPT_DIR/create_user.sh"
LOCKFILE="/var/run/setup_server.lock"
SSH_PORT=48222  
UFW_PORTS=("80/tcp" "443/tcp" "$SSH_PORT/tcp")

# 3. Prevent multiple runs
if [[ -e "$LOCKFILE" ]]; then
  echo "✅ Setup already completed; exiting."
  exit 0
fi

echo "=== Starting full system upgrade ==="
export DEBIAN_FRONTEND=noninteractive
apt update && \
apt full-upgrade -y && \
apt dist-upgrade -y
apt install -y unattended-upgrades && \
dpkg-reconfigure --priority=low unattended-upgrades
apt autoremove --purge -y
unset DEBIAN_FRONTEND
echo "=== Full system upgrade finished ==="

# Ask the user if they want to create a new user
while true; do
  read -p "Do you want to create a new user? (Y/n)" CREATE_USER

  if [[ "$CREATE_USER" =~ ^([yY])?$ ]]; then
    bash "$CREATE_USER_SCRIPT"
  else
    break
  fi
done

# 6. SSH Hardening
echo "=== Configuring SSH for key-based authentication only ==="
# Backup current SSH configuration file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable password authentication, root login, SSH port and PAM.
sed -ri "
  s/^#?Port .*/Port $SSH_PORT/;
  s/^#?Protocol .*/Protocol 2/;
  s/^#?PermitRootLogin .*/PermitRootLogin no/;
  s/^#?PasswordAuthentication .*/PasswordAuthentication no/;
  s/^#?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/;
  s/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/;
  s/^#?X11Forwarding .*/X11Forwarding no/;
  s/^#?ClientAliveInterval .*/ClientAliveInterval 300/;
  s/^#?ClientAliveCountMax .*/ClientAliveCountMax 1/;
  s/^#?UsePAM .*/UsePAM yes/
" /etc/ssh/sshd_config

echo "=== Reloading SSH service... ==="
systemctl reload ssh

# 7. UFW Setup
echo "=== Setting up UFW Firewall ==="
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

for port in "${UFW_PORTS[@]}"; do
  ufw allow "$port"
done

# Rate limiting for SSH
ufw limit $SSH_PORT/tcp

# Enable UFW without prompting
ufw --force enable
systemctl restart ssh

echo "=== UFW enabled, SSH restarted ==="

# 8. Install Fail2Ban & AppArmor
echo "=== Installing Fail2Ban & AppArmor ==="
apt install -y fail2ban apparmor-utils
aa-enforce /etc/apparmor.d/usr.bin.sshd
systemctl enable --now fail2ban
systemctl start fail2ban

# 9. Disable unnecessary services
echo "=== Disabling unnecessary services ==="
for svc in rpcbind avahi-daemon; do
  systemctl disable --now "$svc" || true
done

# 10. Time sync
echo "=== Installing chrony for time sync ==="
apt-get install -y chrony
systemctl enable --now chrony


# 11. Enable automatic upgrades
echo "=== Enableing automatic upgrades ==="
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# 12. Mark done
touch "$LOCKFILE"
echo "=== Production server setup complete. ==="
