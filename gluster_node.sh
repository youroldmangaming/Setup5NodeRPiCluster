apt install glusterfs-server -y

sudo systemctl start glusterd

sudo systemctl enable glusterd

gluster peer probe rpi41; gluster peer probe rpi51;gluster peer probe rpi52; gluster peer probe rpi53;gluster peer probe rpi54;gluster peer probe mini;

mkdir -p /glusterfs /mnt/glusterfs

nano /etc/fstab
     localhost:/fs /mnt/glusterfs glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0

mount.glusterfs localhost:/fs /mnt/glusterfs

chown -R root:docker /mnt
