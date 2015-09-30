#!/bin/bash
set -e

# get the current timestamp
current_timestamp=$(date +%Y%m%d%H%M%S)

# delete any older logs
if [ -d /var/log/staging ]
    then
        rm -R /var/log/staging || true
fi

# build a "staging" folder for the logs
mkdir -p /var/log/staging/

# sync up the logs for the node's nginx
cp /var/log/nginx/*.log /var/log/staging/ || true

# get the logs for the clients
# wget http://goddard.com/log -O /var/log/staging/clients.log || true

# tar the folder
cd /var/log/ && tar -czf logs.tar.gz ./staging
mv /var/log/logs.tar.gz ./staging/

# create the missing folder
ssh node@hub.goddard.unicore.io mkdir -p /var/log/node/$(cat /var/goddard/node.json | jq -r '.uid')/$(date +%Y)/$(date +%m)/

# sync up all the logs for the node
rsync -azr /var/log/staging/logs.tar.gz node@hub.goddard.unicore.io:/var/log/node/$(cat /var/goddard/node.json | jq -r '.uid')/$(date +%Y)/$(date +%m)/$(echo $current_timestamp).tar.gz

# do curl against delete endpoint
# curl -X DELETE http://goddard.com/log || true

# delete all the old logs now
rm /var/log/nginx/*.log

# Manually tell Nginx to rotate the logs to ensure new ones are created after removal.
kill -USR1 `cat /var/run/nginx.pid`

# build a "staging" folder for the logs
rm -R /var/log/staging/*
