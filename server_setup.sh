#!/bin/bash
# setup_server.sh
# This script updates packages, creates a non-root user 'admin', hardens SSH,
# and configures the UFW firewall.
# Run as root.

set -e  # Exit on any error

echo "=== Updating packages ==="
apt update && apt upgrade -y

echo "=== Creating non-root user 'admin' ==="
# Create user 'admin' without a password (password login will be disabled)
adduser --disabled-password --gecos "" admin
# Add 'admin' to the sudo group
usermod -aG sudo admin

echo "=== Configuring passwordless sudo for 'admin' ==="
# Create a sudoers file for admin so that no password is required for sudo commands.
echo "admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/admin
chmod 0440 /etc/sudoers.d/admin


echo "=== Configuring SSH for key-based authentication only ==="
# Backup current SSH configuration file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable password authentication, root login, and PAM.
# (These sed commands will uncomment and change the directives as needed.)
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config

echo "Reloading SSH service..."
systemctl reload ssh

echo "=== Setting up UFW Firewall ==="
ufw default deny incoming
ufw default allow outgoing

ufw allow ssh
ufw allow http
ufw allow https

ufw limit ssh

# Enable UFW without prompting
ufw --force enable

echo "=== Setup complete ==="
echo "IMPORTANT: On your client machine, generate an SSH key pair (if you haven't already) with:"
echo "    ssh-keygen -t rsa -b 4096"
echo "Then copy your public key to the server using one of these commands:"
echo "    ssh-copy-id -i ~/.ssh/your_key.pub admin@YOUR_SERVER_IP"
echo "Replace 'your_key.pub' with the name of your public key file and YOUR_SERVER_IP with your server's IP."
