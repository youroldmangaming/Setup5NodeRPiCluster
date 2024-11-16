#!/bin/bash

# Script to format and mount NVMe drive

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

MOUNT_POINT="/mnt/bigbird"

# Create the mount point
mkdir -p $MOUNT_POINT


# Add entry to /etc/fstab for persistent mounting
if ! grep -q $MOUNT_POINT /etc/fstab; then
    echo "192.168.188.25:/mnt/bigbird /mnt/bigbird nfs defaults 0 0" >> /etc/fstab
    echo "Added entry to /etc/fstab"
else
    echo "Entry already exists in /etc/fstab"
fi

# Set appropriate permissions
chown -R $SUDO_USER:$SUDO_USER $MOUNT_POINT
chmod 755 $MOUNT_POINT

echo "bigbird drive mounted at $MOUNT_POINT"
echo "Please reboot to ensure everything is working correctly"


