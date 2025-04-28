#!/bin/bash
# generate_ssh_key.sh
# This script interactively generates an SSH key.
# Run this script on your local machine. Ensure it has execute permissions: chmod +x generate_ssh_key.sh

read -p "Enter the name of server for your SSH key (default: server_name}): " SERVERNAME
SERVERNAME=${SERVERNAME:-server_name}

read -p "Enter the name of user accessing this server (default: username}): " USERNAME
USERNAME=${USERNAME:-username}

FILENAME=${SERVERNAME}_${USERNAME}

# Prompt for the directory to save the key (default: ~/.ssh)
read -p "Enter the location to save the key (default: \$HOME/.ssh): " LOCATION
LOCATION=${LOCATION:-$HOME/.ssh}

# Ensure the directory exists; if not, create it.
if [ ! -d "$LOCATION" ]; then
  mkdir -p "$LOCATION"
fi

# Full key path
KEY_PATH="${LOCATION}/${FILENAME}"

# Prompt for the passphrase (input is hidden)
read -sp "Enter passphrase (leave empty for no passphrase): " PASSPHRASE
echo ""  # Newline after hidden input
read -sp "Confirm passphrase: " PASSPHRASE_CONFIRM
echo ""

if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
  echo "Error: Passphrases do not match. Exiting."
  exit 1x
fi

# Generate the SSH key pair
ssh-keygen -t "rsa" -b 4096 -C "$FILENAME" -f "$KEY_PATH" -N "$PASSPHRASE"

echo "SSH key pair generated successfully:"
echo "Private key: $KEY_PATH"
echo "Public key: ${KEY_PATH}.pub"
