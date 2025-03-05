#!/bin/bash
# setup_server.sh
# This script updates packages, creates any user, hardens SSH and configures the UFW firewall.
# Run as root. chmod +x setup_server.sh

set -e  # Exit on any error

echo "=== Updating packages ==="
apt update && apt upgrade -y

# Ask the user if they want to create a new user
while true; do
  read -p "Do you want to create a new user? (Y/n)" CREATE_USER

  if [[ "$CREATE_USER" =~ ^([yY])?$ ]]; then
    chmod +x create_user.sh
    ./create_user.sh
  else
    break
  fi
done

# . /path/to/another_script.sh

echo "Main script continues..."

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
