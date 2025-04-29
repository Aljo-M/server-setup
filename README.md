# Server Setup Automation

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [0-server-setup (Backup Server)](#0-server-setup-backup-server)
   - [Setup Instructions](#setup-instructions)
   - [SSH Key Configuration](#ssh-key-configuration)
3. [1-client-setup (Primary Server)](#1-client-setup-primary-server)
   - [Interactive Installation](#interactive-installation)
   - [Configuration Variables](#configuration-variables)
   - [Backup Schedule](#backup-schedule)
4. [Post-Installation](#post-installation)
5. [Restore Procedures](#restore-procedures)

## Repository Structure

server-setup/
├── 0-server-setup/ # Backup server configuration
│ └── server_setup.sh
├── 1-client-setup/ # Primary server configuration
│ ├── interactive_install_and_cron_setup.sh
│ ├── docker_backup.sh
│ ├── k8s_backup.sh
│ ├── full_system_backup.sh
│ └── .backup_env.example
└── README.md

## 0-server-setup (Backup Server)

### Setup Instructions
```bash
apt install git -y
git clone https://github.com/Aljo-M/server-setup.git
cd server-setup
bash 0-server-setup/server-setup.sh
```

### server-setup.sh Analysis

The `server-setup.sh` script automates the process of setting up and hardening a server. It performs the following actions:

#### Initial Setup

- Ensures the script is run as root.
- Sources configuration files and functions.
- Defines script directories.
- Prevents multiple runs using a lock file.

#### System Upgrade

- Updates and upgrades the system packages.
- Installs `unattended-upgrades` for automatic upgrades.

#### Security Hardening

- Runs password, kernel, filesystem, and audit logging hardening scripts.
- Sets up UFW firewall with predefined ports and rate limiting for SSH.
- Installs and enables Fail2Ban and AppArmor.
- Disables unnecessary services.

#### Time Synchronization

- Installs and enables Chrony for time synchronization.

#### Automatic Upgrades

- Enables automatic upgrades using `unattended-upgrades`.

#### Monitoring

- Installs Netdata for server monitoring.

#### Finalization

- Creates a lock file to prevent multiple runs.

### SSH Key Configuration

1. Generate SSH Key on Client: `ssh-keygen -t rsa -b 4096`
2. Paste public key into backup server's `authorized_keys`

## 1-client-setup (Primary Server)

### Interactive Installation

1. Run `interactive_install_and_cron_setup.sh`
2. Follow prompts for Docker/Kubernetes installation

### Configuration Variables

Create `.backup_env` to override defaults:

```bash
BACKUP_SRC="/etc /home /root /opt /var/backups/docker /var/backups/k8s"
BACKUP_TMP="/tmp"
REMOTE_USER="backupuser"
REMOTE_HOST="backup.example.com"
REMOTE_DIR="/remote/backups/$(hostname)"
RETENTION_DAYS="14"
```

### Backup Schedule

| Schedule     | Task               | Script                  |
| ------------ | ------------------ | ----------------------- |
| `30 2 * * *` | Docker Backup      | `docker_backup.sh`      |
| `0 3 * * *`  | Kubernetes Backup  | `k8s_backup.sh`         |
| `0 4 * * *`  | Full System Backup | `full_system_backup.sh` |

## Post-Installation

1. Configure firewall: `ufw allow 22/tcp`, `ufw allow 80/tcp`, `ufw allow 443/tcp`
2. Verify backup user login: `ssh backupuser@backup-server`

## Restore Procedures

1. Docker: Restore volumes and recreate containers
2. Kubernetes: Restore etcd snapshot and reinitialize cluster
3. Full System: Extract backup archive and reconfigure services
