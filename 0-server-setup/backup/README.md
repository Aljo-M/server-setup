# Backup Directory Overview

This directory contains scripts for creating backups of various systems.

## Available Backup Scripts

- `full_system_backup.sh`: Creates a compressed backup archive of important directories.
- `docker_backup.sh`: Handles Docker container backups.
- `k8s_backup.sh`: Manages Kubernetes cluster backups.

## Backup Process

1. These scripts create backup archives in a format suitable for their respective systems.
2. The backups are intended to be transferred to a backup server using `scp`.
3. The backup server is configured to receive these backups securely using SSH key-based authentication.

## Security Considerations

- Ensure proper SSH key management for secure backup transfer.
- Regularly review backup contents and retention policies.

## Related Documentation

For information on setting up the backup server, see the main README.md file in the project root.
