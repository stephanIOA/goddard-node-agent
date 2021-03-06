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
		target="hub.goddard.unicore.io"
	else
		target=$2
	fi

# ensure the .ssh folder exists
mkdir -p /home/goddard/.ssh/
mkdir -p /root/.ssh/

# check if ssh key exists
if [ ! -f /home/goddard/.ssh/id_rsa.pub ]
	then
		ssh-keygen -t rsa -f /home/goddard/.ssh/id_rsa -N "" -q
	fi

echo "Checking if $target is alive"

# ping it to make sure we can reach it
count=$( ping -c 3 $target | grep icmp* | wc -l )
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
		publickey=`cat /home/goddard/.ssh/id_rsa.pub`

		# send HTTP POST - including tunnel info
		curl -d "{\"mac\": \"${mac}\", \"key\": \"${publickey}\"}" -H "Content-Type: application/json" -X POST http://$target/setup.json > /var/goddard/node.raw.json

		# check if the returned json was valid
		eval cat /var/goddard/node.raw.json | jq -r '.'

		# register the return code
		ret_code=$?

		# check the code, must be 0
		if [ $ret_code = 0 ]; then

			# move the json to live node details
			mv /var/goddard/node.raw.json /var/goddard/node.json

			# remove the lock if any
			rm /var/goddard/lock

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

mkdir -p /home/goddard/.ssh/
mkdir -p /root/.ssh/

# write out the service file
sudo cat <<-EOF > /home/goddard/.ssh/config

	Host hub.goddard.unicore.io
		HostName hub.goddard.unicore.io
		Port 22
		User root
		StrictHostKeyChecking no
		IdentityFile /home/goddard/.ssh/id_rsa

EOF

# write out the service file
sudo cat <<-EOF > /root/.ssh/config

	Host hub.goddard.unicore.io
		HostName hub.goddard.unicore.io
		Port 22
		User root
		IdentityFile /home/goddard/.ssh/id_rsa
		KeepAlive yes
		StrictHostKeyChecking no
		ServerAliveInterval 20

EOF

if [ -f /var/goddard/node.json ]
	then

		# set the running hostname
		hostname $(cat /var/goddard/node.json | jq -r '.serial')

		# set the hostname
		echo $(cat /var/goddard/node.json | jq -r '.serial') > /etc/hostname

		# run only if cron is not locked yet
		if [ ! -f /var/goddard/lock ]
			then

			# write the initial hosts
			echo "127.0.0.1		$(cat /var/goddard/node.json | jq -r '.serial')" >> /etc/hosts

		fi

	fi

# check if auth file was already added
if [ ! -f /var/goddard/lock ]
	then

		if [ -f /var/goddard/node.json ]
		then
			# done
			mkdir -p /root/.ssh/

			# use it
			cat /var/goddard/node.json | jq -r .publickey > /home/goddard/.ssh/authorized_keys
			cat /var/goddard/node.json | jq -r .publickey > /root/.ssh/authorized_keys
		fi

	fi

# send metrics
node index.js --action metrics --server http://hub.goddard.unicore.io &

if [ -f /var/goddard/node.json ]
	then
		# write the lock file, to signal we are
		date > /var/goddard/lock
	fi
