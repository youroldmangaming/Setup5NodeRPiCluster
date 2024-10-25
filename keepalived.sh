#!/bin/bash

# Step 1: Install Keepalived
echo "Installing Keepalived..."
sudo apt-get update -y
sudo apt-get install -y keepalived

# For RHEL/CentOS-based systems:
# sudo yum install -y keepalived

# Step 2: Backup existing Keepalived configuration
echo "Backing up existing configuration..."
sudo cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak

# Step 3: Define new Keepalived configuration
echo "Configuring Keepalived..."

# Example configuration file
cat <<EOT | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state BACKUP                # Set this node as BACKUP
    interface eth0              # Network interface
    virtual_router_id 51        # Same as the master
    priority 95                 # Lower priority than the master
    advert_int 1                # Same advertisement interval as the master
    
    authentication {
        auth_type PASS          # Same authentication method
        auth_pass securepass123 # Same password as the master
    }
    
    virtual_ipaddress {
        192.168.188.2           # The same virtual IP
    }
}
# You can add more VRRP instances for different services or failover setups.
EOT

# Step 4: Enable and start Keepalived service
echo "Enabling and starting Keepalived service..."
sudo systemctl enable keepalived
sudo systemctl start keepalived

# Step 5: Verify Keepalived status
echo "Checking Keepalived status..."
sudo systemctl status keepalived

# Print a final message
echo "Keepalived installation and configuration completed."
