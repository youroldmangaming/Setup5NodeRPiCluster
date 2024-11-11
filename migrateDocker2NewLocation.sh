#!/bin/bash

# Script to migrate Docker volumes to new location
# Requires root privileges

# New docker volume location
NEW_DOCKER_PATH="/mnt/bigbird/docker"
NEW_VOLUME_PATH="${NEW_DOCKER_PATH}/volumes"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Create backup timestamp
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Starting Docker volume migration..."

# Stop Docker service
echo "Stopping Docker service..."
systemctl stop docker
if [ $? -ne 0 ]; then
    echo "Failed to stop Docker service. Exiting..."
    exit 1
fi

# Create new directory structure
echo "Creating new directory structure..."
mkdir -p "${NEW_VOLUME_PATH}"
if [ $? -ne 0 ]; then
    echo "Failed to create new directory. Exiting..."
    systemctl start docker
    exit 1
fi

# Backup existing daemon.json
if [ -f /etc/docker/daemon.json ]; then
    echo "Backing up existing daemon.json..."
    cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.${BACKUP_TIMESTAMP}"
fi

# Create or update daemon.json
echo "Updating Docker daemon configuration..."
cat > /etc/docker/daemon.json << EOF
{
    "data-root": "${NEW_DOCKER_PATH}"
}
EOF

# Check if old volumes exist and copy them
if [ -d "/var/lib/docker/volumes/" ]; then
    echo "Copying existing volumes to new location..."
    rsync -av "/var/lib/docker/volumes/" "${NEW_VOLUME_PATH}/"
    if [ $? -ne 0 ]; then
        echo "Failed to copy volumes. Reverting changes..."
        if [ -f "/etc/docker/daemon.json.backup.${BACKUP_TIMESTAMP}" ]; then
            mv "/etc/docker/daemon.json.backup.${BACKUP_TIMESTAMP}" /etc/docker/daemon.json
        fi
        systemctl start docker
        exit 1
    fi
    
    # Backup old volume directory
    echo "Creating backup of old volume directory..."
    mv "/var/lib/docker/volumes" "/var/lib/docker/volumes.backup.${BACKUP_TIMESTAMP}"
fi

# Start Docker service
echo "Starting Docker service..."
systemctl start docker
if [ $? -ne 0 ]; then
    echo "Failed to start Docker service. Please check logs with 'journalctl -xe'"
    exit 1
fi

# Verify new location
echo "Verifying new Docker root location..."
CURRENT_LOCATION=$(docker info --format '{{.DockerRootDir}}')
if [ "${CURRENT_LOCATION}" = "${NEW_DOCKER_PATH}" ]; then
    echo "Success! Docker is now using ${NEW_DOCKER_PATH}"
    echo "Old volume backup is at: /var/lib/docker/volumes.backup.${BACKUP_TIMESTAMP}"
    echo "Daemon config backup is at: /etc/docker/daemon.json.backup.${BACKUP_TIMESTAMP}"
else
    echo "Warning: Docker root directory doesn't match expected location"
    echo "Current location: ${CURRENT_LOCATION}"
    echo "Expected location: ${NEW_DOCKER_PATH}"
fi

echo "Migration complete!"










