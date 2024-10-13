#!/bin/bash

#SBATCH --job-name=glusterfs_setup

#SBATCH --output=glusterfs_setup_%j.log

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

# Step 1: Install GlusterFS on all nodes
for node in $MANAGER_NODE "${WORKER_NODES[@]}"; do
    run_on_node $node sudo apt update
    run_on_node $node sudo apt install -y glusterfs-server
    run_on_node $node sudo systemctl enable --now glusterd
    run_on_node $node sudo mkdir -p $GLUSTERFS_DIR
done


# Step 2: Peer all nodes (from manager node)
for node in "${WORKER_NODES[@]}"; do
    run_on_node $MANAGER_NODE gluster peer probe $node
done

 
# Step 3: Create Gluster volume (on manager node)
VOLUME_CREATE_CMD="sudo gluster volume create $VOLUME_NAME replica $REPLICA_COUNT "
VOLUME_CREATE_CMD+="$MANAGER_NODE:$GLUSTERFS_DIR "
for node in "${WORKER_NODES[@]}"; do
    VOLUME_CREATE_CMD+="$node:$GLUSTERFS_DIR "
done

VOLUME_CREATE_CMD+="force"

run_on_node $MANAGER_NODE $VOLUME_CREATE_CMD

# Step 4: Start the Gluster volume (on manager node)
run_on_node $MANAGER_NODE sudo gluster volume start $VOLUME_NAME

# Step 5: Auto start GlusterFS mount on reboot (on manager node)
run_on_node $MANAGER_NODE sudo bash -c "echo 'localhost:/$VOLUME_NAME /mnt glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab"
run_on_node $MANAGER_NODE sudo mount.glusterfs localhost:/$VOLUME_NAME /mnt
run_on_node $MANAGER_NODE sudo chown -R root:docker /mnt

# Step 6: Verify GlusterFS mount (on manager node)
run_on_node $MANAGER_NODE df -h
run_on_node $MANAGER_NODE sudo mount.glusterfs localhost:/$VOLUME_NAME /mnt

echo "GlusterFS setup completed successfully!"
