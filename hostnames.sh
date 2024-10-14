#!/bin/bash

# Check if two arguments are provided
if [ -z "$1" ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <device_name>"
    exit 1
fi

# Assign arguments to variables
device_name=$1

# Example action: Print the device info
echo "Device Name: $device_name"


echo "Start Setup"
echo "Updating /etc/hosts"
cp ./hosts /etc/hosts
