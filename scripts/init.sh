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

# overwrite the nginx default with our one
cat /var/goddard/agent/templates/default.html > /usr/share/nginx/html/index.html

# run only if cron is not locked yet
if [ ! -f /var/goddard/app.json ]
	then

	# write to the file
	echo "[]" > /var/goddard/apps.json

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
	echo "*/60 * * * * cd /var/goddard/agent && chmod a+x scripts/log.sh && ./scripts/logs.sh" >> mycron

	#echo new cron into cron file
	echo "*/90 * * * * cd /var/goddard/agent && chmod a+x scripts/playbook.sh && ./scripts/playbook.sh" >> mycron

	#echo new cron into cron file
	echo "*/1 * * * * cd /var/goddard/agent && node index.js --action metrics --save --server goddard.io.co.za" >> mycron

	#echo new cron into cron file
	echo "*/10 * * * * cd /var/goddard/agent && node index.js --action metrics --server goddard.io.co.za" >> mycron
	
	#install new cron file
	crontab mycron
	rm mycron

	# lock the cron
	date > /var/goddard/lock.cron

	fi

# run the configure script
node index.js --action configure --server http://goddard.io.co.za

# run the provision script
chmod a+x scripts/provision.sh
./scripts/provision.sh