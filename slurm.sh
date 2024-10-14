#!/bin/bash

./slurmReboot.sh

echo "Setting up Slurm, Munge, and OpenMPI"

# Update package list and install necessary packages
apt update && apt-get install -y \
    slurm-wlm \
    openmpi-bin \
    libopenmpi-dev \
    python3 \
    python3-pip \
    munge \
    libmunge-dev \
    nano \
    less \
    build-essential \
    autoconf \
    automake \
    libtool \
    tar \
    wget \
    chrony \
    dbus \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PMIx v4.2.2 from source
echo "Downloading and installing PMIx v4.2.2"
wget https://github.com/openpmix/openpmix/releases/download/v4.2.2/pmix-4.2.2.tar.gz \
    && tar -xzf pmix-4.2.2.tar.gz \
    && cd pmix-4.2.2 \
    && ./autogen.pl \
    && ./configure --prefix=/usr/local \
    && make -j4 \
    && make install \
    && cd .. \
    && rm -rf pmix-4.2.2 pmix-4.2.2.tar.gz

# Copy configuration files from /clusterfs
echo "Copying configuration files"
cp ./slurm.conf /etc/slurm/slurm.conf || { echo "Failed to copy slurm.conf"; exit 1; }
cp ./munge.key /etc/munge/munge.key || { echo "Failed to copy munge.key"; exit 1; }
cp ./cgroup.conf /etc/slurm/cgroup.conf || { echo "Failed to copy cgroup.conf"; exit 1; }

# Ensure proper permissions for Slurm and Munge directories
echo "Ensuring proper permissions for Slurm and Munge directories"
chown -R slurm:slurm /etc/slurm
chown -R munge:munge /etc/munge
chmod 700 /etc/munge/munge.key

# Restart Munge and Slurm services to apply the changes
echo "Restarting Munge and Slurm services"
systemctl restart munge
systemctl restart slurmctld
systemctl restart slurmd

echo "Setup complete."





