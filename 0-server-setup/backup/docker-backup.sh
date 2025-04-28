#!/usr/bin/env bash
# docker_backup.sh: Full Docker backup to local directory

set -euo pipefail

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed. Exiting."
  exit 1
fi

BACKUP_DIR="/var/backups/docker"
DATE="$(date +%F-%H-%M-%S)"
ARCHIVE_DIR="$BACKUP_DIR/$DATE"
mkdir -p "$ARCHIVE_DIR"

# Backup container configs
docker ps -aq | while read cid; do
  docker inspect "$cid" > "$ARCHIVE_DIR/container_${cid}.json"
done

# Backup Docker volumes
for volume in $(docker volume ls -q); do
  docker run --rm -v "$volume":/volume -v "$ARCHIVE_DIR":/backup alpine \
    tar czf "/backup/volume_${volume}.tar.gz" -C /volume .
done

# Backup Docker image list
docker images --digests --no-trunc > "$ARCHIVE_DIR/docker_images_list.txt"

echo "Docker backup complete: $ARCHIVE_DIR"

