#!/bin/bash
set -euo pipefail

# Prompt the user to enter the username on the same line
read -p "Please enter the username: " USERNAME

# If user exists, exit early
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists."
  exit 1
fi

# Create the user without a password
adduser --disabled-password --gecos "" $USERNAME

USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Prompt the user to enter the public key on the same line
read -p "Please enter the public key: " PUBLIC_KEY

# Create .ssh directory and set permissions
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR

# Add the public key to authorized_keys
echo "$PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS" >/dev/null

# Set correct permissions for authorized_keys
chmod 600 $AUTHORIZED_KEYS
chown -R $USERNAME:$USERNAME $SSH_DIR

echo "SSH key setup completed for user $USERNAME."

# Ask if the user should be added to the sudo group on the same line
read -p "Do you want to add $USERNAME to the sudo group? (Y/n) " ADD_TO_SUDO

if [[ "$ADD_TO_SUDO" =~ ^([yY]|)$ ]]; then
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USERNAME" >/dev/null
  chmod 0440 "/etc/sudoers.d/$USERNAME"
  echo "Passwordless sudo configured for user $USERNAME."
fi

# Ask if the user should be added to the docker group on the same line
read -p "Do you want to add $USERNAME to the docker group? (Y/n) " ADD_TO_DOCKER

if [[ "$ADD_TO_DOCKER" =~ ^([yY]|)$ ]]; then
  usermod -aG docker "$USERNAME"
  echo "$USERNAME added to the docker group."
fi

echo "Setup completed."
