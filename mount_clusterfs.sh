#!/bin/bash

echo "Setting Up Share"

# Create directory for NFS mount point
mkdir -p /clusterfs

# Install NFS client tools
apt install nfs-common -y

echo "Adding NFS server to /etc/fstab to mount on startup"

# Add NFS entry to /etc/fstab if it doesn't already exist
if ! grep -q "mini:/clusterfs /clusterfs nfs" /etc/fstab; then
    echo "mini:/clusterfs /clusterfs nfs defaults 0 0" >> /etc/fstab
    echo "NFS entry added to /etc/fstab"
else
    echo "NFS entry already exists in /etc/fstab"
fi

# Reload systemd to apply the updated fstab
echo "Reloading systemd to apply updated fstab..."
systemctl daemon-reload

# Attempt to mount the NFS share manually
echo "Mounting NFS share..."
mount -t nfs -o nolock 192.168.188.25:/clusterfs /clusterfs || { echo "Failed to mount NFS share"; exit 1; }

# Mount all filesystems defined in /etc/fstab
echo "Mounting all filesystems..."
mount -a || { echo "Failed to mount filesystems"; exit 1; }

echo "Setup complete."
