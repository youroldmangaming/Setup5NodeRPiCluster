#!/bin/bash

#SBATCH --job-name=glusterfs_setup
#SBATCH --output=glusterfs_setup_%j.log

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'sudo' or switch to root user."
    exit 1
fi

# Load environment variables from .env file
set -a
source .env
set +a

# Convert comma-separated WORKER_NODES to an array
IFS=',' read -ra WORKER_NODES <<< "$WORKER_NODES"

# Calculate total number of nodes and set as replica count
REPLICA_COUNT=$((${#WORKER_NODES[@]} + 1))

# Update SBATCH --nodes based on total number of nodes
sed -i "s/^#SBATCH --nodes=.*/#SBATCH --nodes=$REPLICA_COUNT/" "$0"

# Function to run commands on a specific node
run_on_node() {
    local node=$1
    shift
    srun --nodes=1 --nodelist=$node "$@"
}

# Function to check node status and restart if necessary
check_and_restart_node() {
    local node=$1
    while sinfo -N -n $node | grep -qE '(down|drain)'; do
        echo "Node $node is down or drained. Rebooting..."
        scontrol reboot $node
        sleep 60  # Allow time for the node to come back online
    done
}

# Step 1: Ensure all nodes are ready and install GlusterFS on all nodes
for node in $MANAGER_NODE "${WORKER_NODES[@]}"; do
    check_and_restart_node $node
    run_on_node $node apt update
    run_on_node $node apt install -y glusterfs-server
    run_on_node $node systemctl enable --now glusterd
    run_on_node $node mkdir -p $GLUSTERFS_DIR
done

# Step 2: Peer all nodes (from manager node)
for node in "${WORKER_NODES[@]}"; do
    if ! gluster peer status | grep -q $node; then
        run_on_node $MANAGER_NODE gluster peer probe $node || {
            echo "Failed to probe $node" >&2
            exit 1
        }
    else
        echo "$node is already a peer, skipping..."
    fi
done

# Step 3: Create Gluster volume (on manager node) if it doesn't exist
if ! gluster volume info $VOLUME_NAME > /dev/null 2>&1; then
    VOLUME_CREATE_CMD="gluster volume create $VOLUME_NAME replica $REPLICA_COUNT "
    VOLUME_CREATE_CMD+="$MANAGER_NODE:$GLUSTERFS_DIR "

    for node in "${WORKER_NODES[@]}"; do
        VOLUME_CREATE_CMD+="$node:$GLUSTERFS_DIR "
    done

    VOLUME_CREATE_CMD+="force"

    run_on_node $MANAGER_NODE $VOLUME_CREATE_CMD || {
        echo "Failed to create Gluster volume" >&2
        exit 1
    }
else
    echo "Volume $VOLUME_NAME already exists, skipping creation..."
fi

# Step 4: Start the Gluster volume (on manager node)
run_on_node $MANAGER_NODE gluster volume start $VOLUME_NAME || {
    echo "Failed to start Gluster volume" >&2
    exit 1
}

# Step 5: Auto start GlusterFS mount on reboot (on manager node)
run_on_node $MANAGER_NODE bash -c "echo '$MANAGER_NODE:/$VOLUME_NAME /mnt glusterfs defaults,_netdev,backupvolfile-server=$MANAGER_NODE 0 0' >> /etc/fstab"
run_on_node $MANAGER_NODE mount.glusterfs $MANAGER_NODE:/$VOLUME_NAME /mnt
run_on_node $MANAGER_NODE chown -R root:docker /mnt

# Step 6: Verify GlusterFS mount (on manager node)
run_on_node $MANAGER_NODE df -h
run_on_node $MANAGER_NODE mount.glusterfs $MANAGER_NODE:/$VOLUME_NAME /mnt || {
    echo "Failed to mount Gluster volume" >&2
    exit 1
}

