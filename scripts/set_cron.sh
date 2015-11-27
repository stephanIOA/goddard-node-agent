#!/usr/bin/env bash

##
# Write out the cron jobs required for the system
##

echo "*/60 * * * * cd /var/goddard/agent && chmod a+x scripts/logs.sh && ./scripts/logs.sh" > mycron
echo "*/1 * * * * cd /var/goddard/agent && node index.js --action metrics --save --server hub.goddard.unicore.io" >> mycron
echo "*/15 * * * * cd /var/goddard/agent && node index.js --action metrics --server hub.goddard.unicore.io" >> mycron
echo "0 0 * * * cd /var/goddard/agent && pkill -15 -f update.sh || true && chmod a+x scripts/update.sh && ./scripts/update.sh" >> mycron
echo "0 * * * * cd /var/goddard/agent && pkill -15 -f sync.sh || true && chmod a+x scripts/sync.sh && ./scripts/sync.sh" >> mycron

crontab mycron
rm mycron

exit 0
