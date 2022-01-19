#!/bin/bash
# disable the auto update
systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service

# wait until `apt` has been killed and locks released
while ! (systemctl list-units --all apt-daily.service | egrep -q '(dead|failed)')
do
  sleep 1;
done

# update package refs and install proxy
apt-get update
# apt-get upgrade -y
apt-get install -y squid

### update squid configuration to allow VPC connection from clusters

###** Uncomment following entry "#acl localnet src 10.0.0.0/8" ###
sed -i "s/^#acl localnet src 10.0.0.0\/8/acl localnet src 10.0.0.0\/8/" /etc/squid/squid.conf

###** Uncomment following entry "#http_access allow localnet" ###
sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid/squid.conf

# wait for 5s, then enable proxy on reboot and restart it
sleep 5
systemctl enable squid
systemctl restart squid


##
## Add "motd" script
##

cat > /tmp/motd.txt << EOL
echo "##### IBM Cloud Financial Services Systems.  Authorized access only!!! #####"
echo "##### All actions Will be monitored and recorded.  #####"
echo "##### Users are accessing a financial services information system.  #####"
echo "##### Information system usage may be monitored, recorded, and subject to audit.  #####"
echo "##### Unauthorized use of the information system is prohibited and subject to criminal and civil penalties.  #####"
echo "##### Use of the information system indicates consent to monitoring and recording.  #####"
echo " "
EOL

#Append MOTD

cat /tmp/motd.txt > /etc/profile.d/motd.sh

rm -rf /tmp/motd.txt

### End ###