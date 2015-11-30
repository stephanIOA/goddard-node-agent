#!/usr/bin/env bash

##
# Write out the cron jobs required for the system
##

echo '# Pull the logs from the containers every 15 minute.' > mycron
echo '*/15 * * * * cd /var/goddard/agent && chmod a+x scripts/logs.sh && ./scripts/logs.sh > /dev/null' >> mycron
echo '' >> mycron
echo '# Store the metrics every minute.' >> mycron
echo '* * * * * cd /var/goddard/agent && /usr/bin/node index.js --action metrics --save --server hub.goddard.unicore.io > /dev/null' >> mycron
echo '' >> mycron
echo '# Every 15 minutes, send the logs to the server, which is also our regular check in.' >> mycron
echo '*/15 * * * * cd /var/goddard/agent && /usr/bin/node index.js --action metrics --server hub.goddard.unicore.io > /dev/null' >> mycron
echo '' >> mycron
echo '# Once a day run the Node Agent source code update script, killing it first in case it is still running.' >> mycron
echo '# Run at 1pm, maximising the chance of solar power meaning we are running.' >> mycron
echo '00 13 * * * UPDATE_PID=$(pgrep update.sh) ; if [ ! -z "$UPDATE_PID" ] ; then pkill -P $UPDATE_PID ; fi' >> mycron
echo '05 13 * * * cd /var/goddard/agent; chmod a+x scripts/update.sh && ./scripts/update.sh >> /tmp/update_out.log' >> mycron
echo '' >> mycron
echo '# Every hour run media sync script, killing it first in case it is still running.' >> mycron
echo '00 * * * * SYNC_PID=$(pgrep sync.sh) ; if [ ! -z "$SYNC_PID" ] ; then pkill -P $SYNC_PID ; fi' >> mycron
echo '05 * * * * date >> /tmp/sync_out.log; cd /var/goddard/agent; chmod a+x scripts/sync.sh && ./scripts/sync.sh >> /tmp/sync_out.log' >> mycron

crontab mycron
rm mycron

exit 0
