sudo su
cd /etc
mv /etc/hosts /etc/hosts.bak
ln -s /clusterfs/hosts hosts
