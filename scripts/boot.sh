#!/bin/bash

# mark as executable
chmod a+x scripts/setup.sh

# handle done
done=0

# continues while loop
while : ; do

	# execute command and update status code for done
	done=$(./scripts/setup.sh)

	# delete the lock file if any
	rm /var/goddard/setup.lock || true

	# check if the exit code was a 1, so 0 ...
	if [ "$done" -lt 1 ]; then
		break
	fi

	# sleep for 5 minutes
	sleep 5m

done