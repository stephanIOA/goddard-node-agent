#!/bin/bash

# mark as executable
chmod a+x scripts/setup.sh

# delete a lock file older than 60 minutes, delete it
if test `find /var/goddard -name boot.lock -mmin +15`
then

	# debug
	echo "Kill all running instaces ..."

	# kill the app
	pkill -9 -f boot.sh

	# delete the lock file if any
	rm /var/goddard/boot.lock || true
	
fi

# check for a lock
if [ ! -f /var/goddard/boot.lock ]
then

	# stop any commands already running ...
	# pkill -9 -f boot.sh

	# write the lock
	echo date > /var/goddard/boot.lock

	# echo now
	echo "attempting provision"

	# handle done
	done=0

	# continues while loop
	while :
	do

		# debug
		echo "kill all previous runs that are still active"

		# kill the running instance
		pkill -9 -f setup.sh

		# debug
		echo "Delete setup lock"

		# deletes the setup lock if any
		rm /var/goddard/setup.lock || true

		# debug
		echo "Running setup script"

		# execute command and update status code for done
		sh scripts/setup.sh

		# get the code
		ret_code=$?

		# debug
		echo "Setup script is done"

		# check if the exit code was a 1, so 0 ...
		if [ "$ret_code" -lt 1 ]; then
			break
		fi

		# output debugging
		echo "Sleeping for 1 minute"

		# sleep for 1 minutes
		sleep 1m

	done

	# delete the lock file
	rm /var/goddard/boot.lock || true

fi
