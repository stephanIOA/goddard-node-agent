#!/bin/bash
set -e

# get the current timestamp
current_timestamp=$(date +%Y%m%d%H%M%S)

# delete any older logs
mkdir -p /var/log/staging/

# sync up the logs for the node's nginx
cp /var/log/nginx/*.log /var/log/staging/

# get the logs for the clients
wget http://goddard.com/log -O /var/log/staging/clients.log

# set the id

# tar the folder
tar -czf $(current_timestamp).tar.gz /var/log/staging/

# sync up all the logs for the node
rsync -avr -R /var/log/staging/ node@goddard.io.co.za:/var/log/$(cat /var/goddard/node.json | jq -r '.uid')/$(date +%Y)/$(date +%m)/

# do curl against delete endpoint
curl -X DELETE http://goddard.com/log

# delete all the old logs now
rm /var/log/nginx/*.log

# build a "staging" folder for the logs
rm -R /var/log/staging/*