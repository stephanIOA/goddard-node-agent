#!/bin/bash
set -e

# get the current timestamp
current_timestamp=$(date +%Y%m%d%H%M%S)

# delete any older logs
mkdir -p /var/log/staging/
mkdir -p /var/log/output/

# build a "staging" folder for the logs
rm -R /var/log/staging/* || true

# build a "staging" folder for the logs
rm -R /var/log/output/* || true

# sync up the logs for the node's nginx
cp /var/log/nginx/*.log /var/log/staging/ || true

# get the logs for the clients
# wget http://goddard.com/log -O /var/log/staging/clients.log || true

# tar the folder
cd /var/log/staging && tar -czf logs.tar.gz .

# create the missing folder
ssh node@goddard.io.co.za mkdir -p /var/log/node/$(cat /var/goddard/node.json | jq -r '.uid')/$(date +%Y)/$(date +%m)/

# sync up all the logs for the node
rsync -azr /var/log/staging/logs.tar.gz node@goddard.io.co.za:/var/log/node/$(cat /var/goddard/node.json | jq -r '.uid')/$(date +%Y)/$(date +%m)/$(echo $current_timestamp).tar.gz

# do curl against delete endpoint
# curl -X DELETE http://goddard.com/log || true

# delete all the old logs now
rm /var/log/nginx/*.log

# build a "staging" folder for the logs
rm -R /var/log/staging/*

# build a "staging" folder for the logs
rm -R /var/log/output/*