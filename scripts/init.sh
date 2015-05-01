#! /bin/sh

##
# This script does the base setup for the node on startup. 
# Including:
# -> Base Network Setup (Alias eth0:0)
# -> Setup Base Cron Jobs
# -> Configure router
# -> Run provision script to do the handshake with server
##

# make sure we are in the goddard folder
cd /var/goddard/agent

# make sure all our default folders exist
mkdir -p /var/goddard/apps
mkdir -p /usr/share/nginx/html/

# run only if cron is not locked yet
if [ ! -f /var/goddard/lock.cron ]
	then

	# overwrite the nginx default with our one
	cat /var/goddard/agent/templates/default.html > /usr/share/nginx/html/index.html
	cat /var/goddard/agent/templates/nginx.conf > /etc/nginx/nginx.conf

	fi

# restart nginx
service nginx restart

# run only if cron is not locked yet
if [ ! -f /var/goddard/app.json ]
	then

	# write to the file
	echo "[]" > /var/goddard/apps.json
	echo "{}" > /var/goddard/build.json
	echo "{}" > /var/goddard/status.json

	fi

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
	echo "0 2 * * * cd /var/goddard/agent && chmod a+x scripts/logs.sh && ./scripts/logs.sh" >> mycron

	#echo new cron into cron file
	echo "0 4 * * * cd /var/goddard/agent && chmod a+x scripts/playbook.sh && ./scripts/playbook.sh" >> mycron

	#echo new cron into cron file
	echo "*/1 * * * * cd /var/goddard/agent && node index.js --action metrics --save --server goddard.io.co.za" >> mycron

	#echo new cron into cron file
	echo "*/15 * * * * cd /var/goddard/agent && node index.js --action metrics --server goddard.io.co.za" >> mycron
	
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
    	node index.js --action configure --server http://goddard.io.co.za

	fi

# run the provision script
chmod a+x scripts/provision.sh
./scripts/provision.sh