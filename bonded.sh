#!/bin/bash

# Function to check if command succeeded
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to check if IP is available
check_ip_available() {
    local ip=$1
    if arping -c 2 -w 3 -I eth0 $ip > /dev/null 2>&1; then
        echo "Error: IP $ip is already in use"
        exit 1
    fi
}

# Check if 192.168.188.100 is available
echo "Checking if 192.168.188.100 is available..."
check_ip_available 192.168.188.100

# Update package list and install ifenslave
echo "Updating package list and installing ifenslave..."
apt update
check_command "apt update"
apt install -y ifenslave arping
check_command "ifenslave and arping installation"

# Load bonding kernel module
echo "Loading bonding module..."
modprobe bonding
check_command "loading bonding module"

# Ensure bonding module is loaded on boot
echo "Adding bonding module to /etc/modules..."
if ! grep -q "^bonding" /etc/modules; then
    echo "bonding" >> /etc/modules
    check_command "adding bonding to /etc/modules"
fi

# Backup existing interfaces file
cp /etc/network/interfaces /etc/network/interfaces.bak
check_command "backing up interfaces file"

# Configure bond0 interface in /etc/network/interfaces
echo "Configuring network bonding in /etc/network/interfaces..."

cat <<EOF > /etc/network/interfaces
# /etc/network/interfaces file for bonding setup
auto bond0
iface bond0 inet static
    address 192.168.188.100
    netmask 255.255.255.0
    gateway 192.168.188.1
    bond-slaves eth0 wlan0
    bond-mode active-backup
    bond-miimon 100
    bond-downdelay 200
    bond-updelay 200
    bond-primary eth0
# Source additional interface configurations
#source /etc/network/interfaces.d/*

auto eth0
iface eth0 inet manual
   bonfd-master bond0

auto wlan0
iface wlan0 inet manual
   bond-master bond0
   wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

EOF
check_command "writing to interfaces file"

# Check if eth0 and wlan0 exist
if ! ip link show eth0 > /dev/null 2>&1 || ! ip link show wlan0 > /dev/null 2>&1; then
    echo "Error: eth0 or wlan0 interface not found"
    exit 1
fi

# Restart networking service
echo "Restarting networking service..."
systemctl restart networking
check_command "restarting networking service"

# Wait for bond0 to come up
echo "Waiting for bond0 to come up..."
timeout 30 bash -c 'until ip link show bond0 up > /dev/null 2>&1; do sleep 1; done'
if [ $? -ne 0 ]; then
    echo "Error: bond0 did not come up within 30 seconds"
    exit 1
fi

# Verify bonding status
echo "Checking bonding status..."
if [ -f /proc/net/bonding/bond0 ]; then
    cat /proc/net/bonding/bond0
else
    echo "Error: bond0 not found in /proc/net/bonding/"
    exit 1
fi

echo "Bonding setup completed successfully!"
