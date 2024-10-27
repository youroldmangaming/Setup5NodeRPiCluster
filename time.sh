#this connects to the central GPS time server

sudo apt-get install chrony

echo "confdir /etc/chrony/conf.d
sourcedir /etc/chrony/sources.d
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
makestep 1 3
leapsectz right/UTC
server 192.168.188.141 iburst" >/etc/chrony/chrony.conf

sudo systemctl enable chrony
sudo systemctl start chrony

chronyc sources
chronyc tracking
