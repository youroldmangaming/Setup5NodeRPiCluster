#!/bin/bash

#SBATCH --job-name=glusterfs_setup
#SBATCH --output=glusterfs_setup_%j.log

echo "# Check if the script is run as root"
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'sudo' or switch to root user."
    exit 1
fi

echo "# Load environment variables from .env file"
set -a
source .env
set +a

echo "# Convert comma-separated WORKER_NODES to an array"
IFS=',' read -ra WORKER_NODES <<< "$WORKER_NODES"

echo "# Calculate total number of nodes and set as replica count"
REPLICA_COUNT=$((${#WORKER_NODES[@]} + 1))

echo "# Update SBATCH --nodes based on total number of nodes"
sed -i "s/^#SBATCH --nodes=.*/#SBATCH --nodes=$REPLICA_COUNT/" "$0"

echo "# Function to run commands on a specific node"
run_on_node() {
    local node=$1
    shift
    srun --nodes=1 --nodelist=$node "$@"
}

echo "# Function to check node status and restart if necessary"
check_and_restart_node() {
    local node=$1
    while sinfo -N -n $node | grep -qE '(down|drain)'; do
        echo "Node $node is down or drained. Rebooting..."
        scontrol reboot $node
        sleep 60  # Allow time for the node to come back online
    done
}

echo "# Step 1: Ensure all nodes are ready and install GlusterFS on all nodes"
for node in $MANAGER_NODE "${WORKER_NODES[@]}"; do
    echo $node
    check_and_restart_node $node
    run_on_node $node apt update
    run_on_node $node apt install -y glusterfs-server
    run_on_node $node systemctl enable --now glusterd
    run_on_node $node mkdir -p $GLUSTERFS_DIR
done

echo "# Step 2: Peer all nodes (from manager node)"
for node in "${WORKER_NODES[@]}"; do
    run_on_node $MANAGER_NODE gluster peer probe $node || {
        echo "Failed to probe $node" >&2
        exit 1
    }
done

echo "# Step 3: Create Gluster volume (on manager node)"
if ! run_on_node $MANAGER_NODE gluster volume info $VOLUME_NAME; then
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
fi

echo "# Step 4: Start the Gluster volume (on manager node)"
if run_on_node $MANAGER_NODE gluster volume info $VOLUME_NAME | grep -q 'Status: Started'; then
    echo "Gluster volume $VOLUME_NAME is already started."
else
    run_on_node $MANAGER_NODE gluster volume start $VOLUME_NAME || {
        echo "Failed to start Gluster volume" >&2
        exit 1
    }
fi

echo "# Step 5: Auto start GlusterFS mount on reboot (on all nodes)"
for node in $MANAGER_NODE "${WORKER_NODES[@]}"; do

    echo "fstab for ${WORKER_NODES[@]}"

    run_on_node $node bash -c "echo '$MANAGER_NODE:/$VOLUME_NAME $GLUSTERFS_DIR glusterfs defaults,_netdev,backupvolfile-server=$MANAGER_NODE 0 0' >> /etc/fstab"
    
    run_on_node $node systemctl daemon-reload
    run_on_node $node mount -a
 
    run_on_node $node mount.glusterfs $MANAGER_NODE:/$VOLUME_NAME $GLUSTERFS_DIR
    run_on_node $node chown -R root:docker $GLUSTERFS_DIR
done

echo "# Step 6: Verify GlusterFS mount (on all nodes)"
for node in $MANAGER_NODE "${WORKER_NODES[@]}"; do
    run_on_node $node df -h
done

echo "finished"
