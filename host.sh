#!/bin/bash

# Check if two arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <device_ip> <device_name>"
    exit 1
fi

# Assign arguments to variables
device_ip=$1
device_name=$2

# Example action: Print the device info
echo "Device Name: $device_name"
echo "Device IP: $device_ip"

echo "Start Setup"
echo "Updating /etc/hosts"

# Run the script as root to modify /etc/hosts
sudo bash -c "

# Add entries to /etc/hosts if they do not already exist
if ! grep -q '$device_ip $device_name' /etc/hosts; then
    echo '$device_ip $device_name' >> /etc/hosts
    echo 'Added $device_ip $device_name to /etc/hosts'
else
    echo '$device_ip $device_name already exists in /etc/hosts'
fi

# Check and add predefined entries
[ -z \"\$(grep '192.168.188.27 rpi51' /etc/hosts)\" ] && echo '192.168.188.27 rpi51' >> /etc/hosts
[ -z \"\$(grep '192.168.188.39 rpi52' /etc/hosts)\" ] && echo '192.168.188.39 rpi52' >> /etc/hosts
[ -z \"\$(grep '192.168.188.26 rpi53' /etc/hosts)\" ] && echo '192.168.188.26 rpi53' >> /etc/hosts
[ -z \"\$(grep '192.168.188.32 rpi54' /etc/hosts)\" ] && echo '192.168.188.32 rpi54' >> /etc/hosts
[ -z \"\$(grep '192.168.188.25 mini' /etc/hosts)\" ] && echo '192.168.188.25 mini' >> /etc/hosts
"

echo "Setup complete."







