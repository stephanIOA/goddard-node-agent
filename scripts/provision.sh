#! /bin/sh

###
# This script will be added to cron and is meant to run once off every minute and then exit
# It will send an HTTP to the hub containing the mac address of teh configured interface
###

# check if any arguments are passed
if [ $# -eq 0 ]
	then
    	echo "No arguments supplied - fallback to defaults\r\nUsage: provision.sh <iface> <target>\r\n\r\n"
	fi

# the interface we'll be using - default to eth0
if [ -z "$1" ]
	then
		iface="eth0"
	else
		iface=$1
	fi

# the target (goddard-hub) - default to the satellite detault IP
if [ -z "$2" ]
	then 
		target="goddard.io.co.za"
	else
		target=$2
	fi

# check if ssh key exists
if [ ! -f ~/.ssh/id_rsa.pub ]
	then
		ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" -q
	fi

echo "Checking if $target is alive"

# ping it to make sure we can reach it
#count=$( ping -c 3 $target | grep icmp* | wc -l )
count=1
if [ $count -gt 0 ]
	
	then

		# get mac addres of network interface
		read -r mac < /sys/class/net/$iface/address

		# create the goddard folder if it doesn't exist
		sudo mkdir -p /var/goddard/

		# global permissions as this is quite open
		sudo chmod -R 0777 /var/goddard/

		###
		# need to send:
		# mac addres of eth0
		# public ssh key
		###
		publickey=`cat ~/.ssh/id_rsa.pub`

		# send HTTP POST - including tunnel info
		curl -d "{\"mac\": \"${mac}\", \"key\": \"${publickey}\"}" -H "Content-Type: application/json" -X POST http://$target/setup.json > /var/goddard/node.raw.json

		# check if the returned json was valid
		eval cat /var/goddard/node.raw.json | jq -r '.port'

		# register the return code
		ret_code=$?

		# check the code, must be 0
		if [ $ret_code = 0 ]; then

			# move the json to live node details
			mv /var/goddard/node.raw.json /var/goddard/node.json

		else

			# remove the test
			# rm /var/goddard/node.raw.json				

			# debugging to tell us why
			echo "The json parsing test failed, server returned invalid JSON, the test was done on /var/goddard/node.raw.json"

			# stop the process
			exit 1

		fi

		###
		# response contains:
		# port for SSH tunnel
		###
		echo "Details for $(cat /var/goddard/node.json | jq '.serial') was received and saved !"

	fi

# write the configured upstart service
if [ ! -f /var/goddard/lock ]
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

			exec autossh -nNT -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -R ${tunnel_port}:localhost:22 -M ${tunnel_monitor_port} root@${tunnel_server}

		EOF

		# start / restart the tunnel service
		service goddardtunnel restart

	fi

# check if auth file was already added
if [ ! -f /var/goddard/lock ]
	then
		
		# use it
		cat /var/goddard/node.json | jq -r .publickey >> ~/.ssh/authorized_keys

	fi

# write the lock file, to signal we are
date > /var/goddard/lock
