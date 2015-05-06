#! /bin/sh

##
# This script does the base setup for the node on startup. 
# Including:
# -> Base Network Setup (Alias eth0:0)
# -> Setup Base Cron Jobs
# -> Configure router
# -> Run provision script to do the handshake with server
##

# load in all our certs
update-ca-certificates || true

# make sure we are in the goddard folder
cd /var/goddard/agent

# make sure all our default folders exist
mkdir -p /var/goddard/apps
mkdir -p /usr/share/nginx/html/

# run only if cron is not locked yet
if [ ! -f /var/goddard/lock.cron ]
	then

	# overwrite the nginx default with our one
	cat /var/goddard/agent/templates/default.html > /var/goddard/index.html
	cat /var/goddard/agent/templates/nginx.conf > /etc/nginx/nginx.conf
	cat /var/goddard/agent/templates/nginx.default.conf > /etc/nginx/sites-enabled/default

	fi

# restart nginx
service nginx restart || true

# write out a blank build JSON file
echo "{}" > /var/goddard/build.json

##
# Setup the base networking config
##

ifconfig eth0 192.168.88.50 netmask 255.255.255.0
route add default gw 192.168.88.5
echo "nameserver 192.168.88.5" >> /etc/resolv.conf
ifconfig eth0:1 192.168.1.50 netmask 255.255.255.0


# bring up the new interface
ifdown eth0 && ifup eth0

# up and down the new virtual interface
ifdown eth0:1
ifup eth0:1

##
# Write out the cron jobs required for the system
##

# run only if cron is not locked yet
if [ ! -f /var/goddard/lock.cron ]
	then

	#write out current crontab
	crontab -l > mycron

	#echo new cron into cron file
	echo "*/60 * * * * cd /var/goddard/agent && chmod a+x scripts/logs.sh && ./scripts/logs.sh" >> mycron

	#echo new cron into cron file
	echo "*/1 * * * * cd /var/goddard/agent && node index.js --action metrics --save --server hub.goddard.unicore.io" >> mycron

	#echo new cron into cron file
	echo "*/15 * * * * cd /var/goddard/agent && node index.js --action metrics --server hub.goddard.unicore.io" >> mycron
	
	#install new cron file
	crontab mycron
	rm mycron

	# lock the cron
	date > /var/goddard/lock.cron

	fi

# ping router and only run if something is unconfigured
ping -c 3 192.168.88.1 >/dev/null 2>&1
if [ $? -eq 0 ]
	then

    	# run the configure script
    	echo "RUNNING CONFIG SCRIPT:"
    	node index.js --action configure --server http://hub.goddard.unicore.io

	fi

# run the provision script
chmod a+x scripts/provision.sh
./scripts/provision.sh