#!/bin/bash

# Script to format and mount NVMe drive

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Define variables
DRIVE="/dev/nvme0n1"
PARTITION="${DRIVE}p1"
MOUNT_POINT="/mnt/nvme"

# Create the mount point
mkdir -p $MOUNT_POINT

# Get the UUID of the new partition
UUID=$(blkid -s UUID -o value $PARTITION)

# Mount the new partition
mount $PARTITION $MOUNT_POINT

# Add entry to /etc/fstab for persistent mounting
if ! grep -q $UUID /etc/fstab; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
    echo "Added entry to /etc/fstab"
else
    echo "Entry already exists in /etc/fstab"
fi

# Set appropriate permissions
chown -R $SUDO_USER:$SUDO_USER $MOUNT_POINT
chmod 755 $MOUNT_POINT

echo "NVMe drive mounted at $MOUNT_POINT"
echo "Please reboot to ensure everything is working correctly"








