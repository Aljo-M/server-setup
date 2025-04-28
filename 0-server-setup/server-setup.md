# Server Setup Script Documentation

## Overview

## Related Files and Scripts

The `server_setup.sh` script sources and executes several other scripts and configuration files located in the same directory. These include:

- `variables.conf`: Contains configuration variables used by the script.
- `functions/ask_yes_no.sh` and `functions/input_utils.sh`: Provide utility functions for user input handling.
- `hardening/*.sh`: Scripts for hardening various aspects of the system (kernel, filesystem, audit logging).
- `users/create_user.sh`: Script to create a new user.
- `backup/*.sh`: Scripts related to system backup.

These files are crucial for the proper functioning of `server_setup.sh` and are located in subdirectories within `0-server-setup/`.

The `server_setup.sh` script is designed to securely configure and harden a Linux server. It performs various tasks including strengthening password policies, configuring SSH, setting up the UFW firewall, and installing security tools like Fail2Ban and AppArmor.

## 1. Initialization and Configuration

The script begins by ensuring it's run as root and sourcing necessary configuration files and utility functions. It sets up variables for script directories and important paths.

## 2. Password Policy Strengthening

This section installs `libpam-pwquality` to enforce strong password policies. It backs up the original `/etc/pam.d/common-password` configuration and modifies it to require complex passwords.

## 3. Root Password Setting and System Upgrade

The script prompts for a new root password, performs a full system upgrade, installs `unattended-upgrades`, and cleans up unnecessary packages.

## 4. Hardening Scripts Execution

The script executes three hardening scripts:

- `kernel_hardening.sh`
- `filesystem_hardening.sh`
- `audit_logging_hardening.sh`

## 5. User Creation

The script offers the option to create a new user by running `create_user.sh`. This process can be repeated.

## 6. SSH Hardening

SSH is configured for key-based authentication only. The script backs up the original SSH configuration, modifies it to disable password authentication and root login, and changes the SSH port.

## 7. UFW Setup

The UFW firewall is configured to allow incoming traffic on ports 80, 443, and the specified SSH port. It also rate limits SSH connections to prevent brute-force attacks.

## 8. Fail2Ban and AppArmor Installation

Fail2Ban is installed to monitor and block suspicious login attempts. AppArmor is enabled for the SSH service to provide additional security.

## 9. Disabling Unnecessary Services

The script disables unnecessary services like `rpcbind` and `avahi-daemon`.

## 10. Time Synchronization

`chrony` is installed to ensure accurate time synchronization.

## 11. Enabling Automatic Upgrades

`unattended-upgrades` is configured to automatically apply security updates.

## 12. Completion

The script creates a lockfile to prevent repeated runs and indicates completion.

## Usage

To use this script, ensure you have root privileges and make it executable with `chmod +x server_setup.sh`. Then, run it with `./server_setup.sh`.
