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
mkdir -p /var/goddard
mkdir -p /var/goddard/media

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

# ensure upstart for boot is written
cat scripts/boot.upstart.conf > /etc/init/goddardboot.conf

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

# run only if cron is not locked yet
if [ ! -f /var/goddard/lock.media.cron ]
	then

	#write out current crontab
	crontab -l > mycron

	#echo new cron into cron file
	echo "0 */6 * * * cd /var/goddard/agent && pkill -15 -f sync.sh || true && chmod a+x scripts/sync.sh && ./scripts/sync.sh" >> mycron
	echo "* */24 * * * cd /var/goddard/agent && pkill -15 -f update.sh || true && chmod a+x scripts/update.sh && ./scripts/update.sh" >> mycron

	#install new cron file
	crontab mycron
	rm mycron

	# lock the cron
	date > /var/goddard/lock.media.cron

	fi

# ping router and only run if something is unconfigured
ping -c 3 192.168.88.1 >/dev/null 2>&1
if [ $? -eq 0 ]
	then

    	# run the configure script
    	echo "RUNNING CONFIG SCRIPT:"
    	node index.js --action configure --server http://hub.goddard.unicore.io

	fi

# try and ping the google dns server after which it will try and provision
while :
do

	# debug
	echo "Perform a ping to 8.8.8.8 to check if the internet is active"

	# do the actual ping
	ping -c 3 8.8.8.8 >/dev/null 2>&1
	if [ $? -eq 0 ]
		then

			# debug
			echo "Was able to ping 8.8.8.8, so assuming internet is fine ..."

			# kill it
			break

		fi

	# debugging
	echo "Waiting for 1 minute before trying 8.8.8.8 again to check for internet"

	# wait for 1 minutes
	sleep 1m

done

# run the provision script
chmod a+x scripts/provision.sh
./scripts/provision.sh

# ensure the service is started
service goddardboot start

# create the tunnel if not present
if [ -f /var/goddard/node.json ]
then

	# get the details to write out
	tunnel_server=$(cat /var/goddard/node.json | jq -r '.server')
	tunnel_port=$(cat /var/goddard/node.json | jq -r '.port.tunnel')
	tunnel_monitor_port=$(cat /var/goddard/node.json | jq -r '.port.monitor')

	# write out the service file
	sudo cat <<-EOF > /etc/init/goddardtunnel.conf

		description "Keeps the Goddard Tunnel Always up"

		start on (net-device-up IFACE=${1})
		stop on runlevel[016]

		respawn

		env DISPLAY=:0.0

		exec autossh -nNT -o StrictHostKeyChecking=no -o "ServerAliveInterval 15" -o "ServerAliveCountMax 3" -R ${tunnel_port}:localhost:22 -M ${tunnel_monitor_port} node@${tunnel_server}

	EOF

fi

# try to start or just ignore error if already started
service goddardtunnel start || true
