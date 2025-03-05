#!/bin/bash


# Prompt the user to enter the username to be removed
read -p "Please enter the username to remove: " USERNAME

# Check if the user exists
if ! id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' does not exist. Exiting."
  exit 1
fi

# Remove the user and their home directory
if userdel -r "$USERNAME"; then
  echo "User '$USERNAME' and their home directory removed."
else
  echo "Failed to remove user '$USERNAME'. Exiting."
  exit 1
fi

# Remove the user's sudoers configuration file if it exists
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
if [[ -f "$SUDOERS_FILE" ]]; then
  if rm "$SUDOERS_FILE"; then
    echo "Removed sudoers configuration for '$USERNAME'."
  else
    echo "Failed to remove sudoers configuration for '$USERNAME'."
  fi
fi

# Remove the user from all groups
for GROUP in $(id -nG "$USERNAME"); do
  if gpasswd -d "$USERNAME" "$GROUP"; then
    echo "Removed '$USERNAME' from group '$GROUP'."
  else
    echo "Failed to remove '$USERNAME' from group '$GROUP' or user is not a member."
  fi
done

# Remove the user's cron jobs if they exist
CRON_FILE="/var/spool/cron/crontabs/$USERNAME"
if [[ -f "$CRON_FILE" ]]; then
  if rm "$CRON_FILE"; then
    echo "Removed cron jobs for '$USERNAME'."
  else
    echo "Failed to remove cron jobs for '$USERNAME'."
  fi
fi

# Remove the user's mail spool if it exists
MAIL_SPOOL="/var/mail/$USERNAME"
if [[ -f "$MAIL_SPOOL" ]]; then
  if rm "$MAIL_SPOOL"; then
    echo "Removed mail spool for '$USERNAME'."
  else
    echo "Failed to remove mail spool for '$USERNAME'."
  fi
fi

echo "User '$USERNAME' and all associated configurations have been removed."
