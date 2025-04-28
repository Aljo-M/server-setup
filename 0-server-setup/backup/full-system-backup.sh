#!/usr/bin/env bash
# full_system_backup.sh
# Backs up system, Docker, and Kubernetes data, then copies to remote server via SCP

set -euo pipefail

# === CONFIGURATION ===
BACKUP_SRC=(
  "/etc"
  "/home"
  "/root"
  "/opt"
  "/var/backups/docker"   # Directory where your docker_backup.sh stores its backups
  "/var/backups/k8s"      # Directory where your k8s_backup.sh stores its backups
)
BACKUP_TMP="/tmp"
DATE="$(date +%F_%H-%M-%S)"
HOSTNAME="$(hostname -s)"
BACKUP_NAME="full_backup_${HOSTNAME}_$DATE.tar.gz"
BACKUP_FILE="$BACKUP_TMP/$BACKUP_NAME"

REMOTE_USER="backupuser"
REMOTE_HOST="backup.example.com"
REMOTE_DIR="/remote/backups/$HOSTNAME"

RETENTION_DAYS=14

# Check if Docker is installed and run docker_backup.sh
if command -v docker &> /dev/null; then
  echo "=== Docker found, running docker_backup.sh ==="
  ./docker_backup.sh
else
  echo "=== Docker not found, skipping docker_backup.sh ==="
fi

# Check if Kubernetes is installed and run k8s_backup.sh
if command -v kubectl &> /dev/null; then
  echo "=== Kubernetes found, running k8s_backup.sh ==="
  ./k8s_backup.sh
else
  echo "=== Kubernetes not found, skipping k8s_backup.sh ==="
fi

# === CREATE ARCHIVE ===
echo "=== Creating system backup archive ==="
tar czpf "$BACKUP_FILE" "${BACKUP_SRC[@]}"

# === COPY TO REMOTE SERVER ===
echo "=== Copying backup to remote server ==="
ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$REMOTE_DIR'"
scp "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"

# === CLEANUP LOCAL BACKUPS ===
echo "=== Cleaning up local backups older than $RETENTION_DAYS days ==="
find "$BACKUP_TMP" -name "full_backup_${HOSTNAME}_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "✅ Full system backup complete: $BACKUP_FILE copied to $REMOTE_HOST:$REMOTE_DIR"
