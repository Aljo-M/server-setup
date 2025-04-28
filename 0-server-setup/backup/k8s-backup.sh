#!/usr/bin/env bash
# k8s_backup.sh: Backs up Kubernetes cluster using Velero, outputs to local directory

set -euo pipefail

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl is not installed. Exiting."
  exit 1
fi

BACKUP_NAME="k8s-backup-$(date +%F-%H-%M-%S)"
BACKUP_DIR="/var/backups/k8s"
EXPORT_DIR="$BACKUP_DIR/$BACKUP_NAME"

mkdir -p "$EXPORT_DIR"

# Create Velero backup (must be installed/configured)
velero backup create "$BACKUP_NAME" --snapshot-volumes --include-cluster-resources

# Wait for backup to complete
while true; do
  STATUS=$(velero backup get "$BACKUP_NAME" -o json | grep -o '"phase": *"[^"]*"' | awk -F'"' '{print $4}')
  [[ "$STATUS" == "Completed" ]] && break
  [[ "$STATUS" == "Failed" ]] && { echo "Backup failed!"; exit 1; }
  sleep 10
done

# Download backup metadata and manifests to local directory
velero backup download "$BACKUP_NAME" --output "$EXPORT_DIR/$BACKUP_NAME.tar.gz"

# Optionally, extract for easier system-level backup
tar -xzf "$EXPORT_DIR/$BACKUP_NAME.tar.gz" -C "$EXPORT_DIR"

echo "Kubernetes backup complete: $EXPORT_DIR"
