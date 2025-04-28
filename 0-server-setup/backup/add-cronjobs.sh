#!/usr/bin/env bash
# add_all_cronjobs.sh
# Adds three scripts to the root crontab: docker-backup.sh, k8s_backup.sh, and full_system_backup.sh

set -euo pipefail

# Define absolute paths to your scripts
DOCKER_BACKUP="/docker-backup.sh"
K8S_BACKUP="/k8s-backup.sh"
FULL_SYSTEM_BACKUP="/full-system-backup.sh"

# Define cron schedules (edit as needed)
DOCKER_CRON="30 2 * * * $DOCKER_BACKUP"
K8S_CRON="0 3 * * * $K8S_BACKUP"
FULL_SYSTEM_CRON="0 4 * * * $FULL_SYSTEM_BACKUP"

# Add jobs to root's crontab, avoiding duplicates
(
  crontab -l 2>/dev/null | grep -v -F "$DOCKER_BACKUP" | grep -v -F "$K8S_BACKUP" | grep -v -F "$FULL_SYSTEM_BACKUP"
  echo "$DOCKER_CRON"
  echo "$K8S_CRON"
  echo "$FULL_SYSTEM_CRON"
) | crontab -

echo "✅ All three cron jobs added."
